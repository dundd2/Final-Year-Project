extends Node
class_name LiveAPIClient
signal connection_established()
signal connection_closed(code: int, reason: String)
signal connection_error()
signal setup_response_received(response: Dictionary)
signal server_message_received(message: Dictionary)
signal error_received(error_message: String)
signal session_updated(session_handle: String)
const SERVICE_URL = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent"
const ERROR_CONTEXT := "LiveAPIClient"
var websocket: WebSocketPeer = WebSocketPeer.new()
var is_connected: bool = false
var _is_session_setup: bool = false
var _queued_user_turn_parts: Array = []
var _model_name: String
var _generation_config: Dictionary
var _api_key: String
var _session_handle: String = ""
var _system_instruction: String = ""
var _speech_config: Dictionary = { }
func _process(_delta: float) -> void:
	if not is_connected:
		return
	websocket.poll()
	var state := websocket.get_ready_state()
	match state:
		WebSocketPeer.STATE_OPEN:
			if not _is_session_setup:
				_setup_session()
				_is_session_setup = true
				_on_setup_message_sent()
			while websocket.get_available_packet_count() > 0:
				_on_data_received()
		WebSocketPeer.STATE_CLOSING:
			pass
		WebSocketPeer.STATE_CLOSED:
			var code := websocket.get_close_code()
			var reason := websocket.get_close_reason()
			_on_connection_closed(code, reason)
func connect_to_server(
		model_name: String,
		api_key: String,
		config: Dictionary,
		session_handle: String = "",
		system_instruction: String = "",
		speech_config: Dictionary = { },
):
	_model_name = model_name
	_generation_config = config
	_api_key = api_key
	_session_handle = session_handle
	_system_instruction = system_instruction
	_speech_config = speech_config
	_queued_user_turn_parts.clear()
	if is_connected or websocket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		close_connection()
	var headers: PackedStringArray = [
		"x-goog-api-key: " + _api_key,
	]
	var url := SERVICE_URL + "?key=%s" % _api_key.uri_encode()
	if OS.get_name() != "Web":
		websocket.set_handshake_headers(headers)
	var err := websocket.connect_to_url(url)
	if err != OK:
		_on_connection_failed()
		return
	is_connected = true
	_is_session_setup = false
func close_connection(code: int = 1000, reason: String = "Client requested disconnect") -> void:
	if is_connected or websocket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		websocket.close(code, reason)
		is_connected = false
		_is_session_setup = false
		_queued_user_turn_parts.clear()
func send_user_turn(parts: Array) -> void:
	if not is_connected or websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Attempted to send message while not connected")
		return
	if parts.is_empty():
		ErrorReporterBridge.report_error(ERROR_CONTEXT, "send_user_turn called with empty parts array")
		return
	if not _is_session_setup:
		_queued_user_turn_parts = parts.duplicate(true)
		return
	var message := {
		"clientContent": {
			"turns": [{ "role": "user", "parts": parts }],
			"turnComplete": true,
		},
	}
	var err := websocket.send_text(JSON.stringify(message))
	if err != OK:
		ErrorReporterBridge.report_error(
			ERROR_CONTEXT,
			"Failed to send user turn message. Error: %s" % str(err),
			err,
			false,
			{ "error_code": err },
		)
func _on_connection_failed() -> void:
	ErrorReporterBridge.report_error(
		ERROR_CONTEXT,
		"Connection to %s failed" % SERVICE_URL,
		ErrorCodes.AI.NETWORK_ERROR,
		false,
		{ "service_url": SERVICE_URL },
	)
	is_connected = false
	_is_session_setup = false
	connection_error.emit()
func _on_connection_closed(code: int, reason: String) -> void:
	if is_connected:
		is_connected = false
		_is_session_setup = false
		connection_closed.emit(code, reason)
func _on_data_received() -> void:
	var packet := websocket.get_packet()
	if websocket.was_string_packet():
		var json := JSON.new()
		var text := packet.get_string_from_utf8()
		var err := json.parse(text)
		if err == OK:
			var data: Variant = json.data
			if data is Dictionary:
				_process_server_message(data)
			else:
				error_received.emit("Received non-dictionary JSON from server: " + text)
		else:
			error_received.emit("Failed to parse JSON from server: " + text)
	else:
		pass
func _process_server_message(data: Dictionary) -> void:
	if data.has("error"):
		var error_dict: Dictionary = data["error"]
		var error_msg := str(error_dict.get("message", "Unknown Live API error"))
		ErrorReporterBridge.report_error(
			ERROR_CONTEXT,
			"Received error from server: %s" % error_msg,
			ErrorCodes.AI.REQUEST_FAILED,
			false,
			{ "error_message": error_msg },
		)
		error_received.emit(error_msg)
		return
	if data.has("sessionResumptionUpdate") or data.has("session_resumption_update"):
		var update: Dictionary = data.get("sessionResumptionUpdate", data.get("session_resumption_update", { }))
		var handle: String = str(update.get("newHandle", update.get("new_handle", "")))
		var resumable: bool = bool(update.get("resumable", update.get("resumable", false)))
		if not handle.is_empty() and resumable:
			session_updated.emit(handle)
	elif data.has("serverContent") or data.has("server_content"):
		server_message_received.emit(data)
	else:
		setup_response_received.emit(data)
		_flush_queued_user_turn()

func _flush_queued_user_turn() -> void:
	if _queued_user_turn_parts.is_empty():
		return
	if not is_connected or websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	var parts := _queued_user_turn_parts.duplicate(true)
	_queued_user_turn_parts.clear()
	send_user_turn(parts)
func _setup_session() -> void:
	var setup_config: Dictionary = {
		"model": "models/" + _model_name,
		"generationConfig": _generation_config.duplicate(true),
		"sessionResumption": { },
	}
	if not _session_handle.is_empty():
		setup_config["sessionResumption"]["handle"] = _session_handle
	if not _system_instruction.is_empty():
		setup_config["systemInstruction"] = {
			"parts": [{ "text": _system_instruction }],
		}
	if not _speech_config.is_empty():
		setup_config["speechConfig"] = _speech_config
	setup_config["responseModalities"] = ["TEXT", "AUDIO"] if not _speech_config.is_empty() else ["TEXT"]
	var setup_message := { "setup": setup_config }
	var err := websocket.send_text(JSON.stringify(setup_message))
	if err != OK:
		ErrorReporterBridge.report_error(
			ERROR_CONTEXT,
			"Failed to send setup message. Error: %s" % str(err),
			err,
			false,
			{ "error_code": err },
		)
		close_connection(1011, "Setup message failed")
func _on_setup_message_sent() -> void:
	print("[Live API Client] Session setup message sent. Connection established.")
	connection_established.emit()
	_flush_queued_user_turn()
