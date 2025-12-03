extends Node
const ERROR_CONTEXT := "OllamaStreamRequest"
signal token(task_id: int, text: String)
signal completed(task_id: int, ok: bool, data: Dictionary)
signal failed(task_id: int, reason: String)
var _http: HTTPClient = HTTPClient.new()
var _task_id: int = -1
var _host: String = ""
var _port: int = 0
var _path: String = ""
var _request_sent: bool = false
var _is_active: bool = false
var _timeout_msec: int = 30000
var _start_time_msec: int = 0
var _body: String = ""
var _leftover: String = ""
var _collected_text: String = ""
func start(host: String, port: int, path: String, payload: Dictionary, task_id: int, timeout_sec: float) -> void:
	if _is_active:
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Stream request already active, ignoring start()",
			{ "task_id": task_id },
		)
		return
	_host = host
	_port = port
	_path = path
	_task_id = task_id
	_timeout_msec = int(timeout_sec * 1000.0)
	_start_time_msec = Time.get_ticks_msec()
	_body = JSON.stringify(payload)
	_collected_text = ""
	_http = HTTPClient.new()
	_http.set_blocking_mode(false)
	var err := _http.connect_to_host(_host, _port)
	if err != OK:
		_emit_failure("connect_error=%s" % error_string(err))
		return
	_is_active = true
	set_process(true)
func cancel() -> void:
	if not _is_active:
		return
	_emit_failure("cancelled")
func _process(_delta: float) -> void:
	if not _is_active:
		return
	var elapsed := Time.get_ticks_msec() - _start_time_msec
	if _timeout_msec > 0 and elapsed > _timeout_msec:
		_emit_failure("timeout")
		return
	var poll_err := _http.poll()
	if poll_err != OK:
		_emit_failure("poll_error=%s" % error_string(poll_err))
		return
	match _http.get_status():
		HTTPClient.STATUS_CONNECTED:
			if not _request_sent:
				var headers := PackedStringArray(["Content-Type: application/json"])
				var req_err := _http.request(HTTPClient.METHOD_POST, _path, headers, _body)
				if req_err != OK:
					_emit_failure("request_error=%s" % error_string(req_err))
					return
				_request_sent = true
		HTTPClient.STATUS_BODY:
			_read_chunks()
		HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_CANT_RESOLVE, HTTPClient.STATUS_CANT_CONNECT:
			_emit_failure("connection_lost")
		HTTPClient.STATUS_DISCONNECTED:
			_flush_leftover()
			if _is_active:
				_finalize_success({ })
func _read_chunks() -> void:
	while _http.get_status() == HTTPClient.STATUS_BODY:
		var chunk := _http.read_response_body_chunk()
		if chunk.is_empty():
			break
		var text_chunk := chunk.get_string_from_utf8()
		if text_chunk.is_empty():
			continue
		_parse_stream_text(text_chunk)
func _parse_stream_text(incoming: String) -> void:
	var combined := _leftover + incoming
	var lines: Array = combined.split("\n")
	if lines.is_empty():
		return
	_leftover = lines.pop_back() if lines.size() > 0 else ""
	for line in lines:
		var trimmed: String = line.strip_edges()
		if trimmed.is_empty():
			continue
		var json := JSON.new()
		var parse_err: Error = json.parse(trimmed)
		if parse_err != OK:
			continue
		var data: Variant = json.get_data()
		if data is Dictionary:
			if _process_chunk(data):
				return
func _flush_leftover() -> void:
	var trimmed: String = _leftover.strip_edges()
	_leftover = ""
	if trimmed.is_empty():
		return
	var json := JSON.new()
	if json.parse(trimmed) != OK:
		return
	var data: Variant = json.get_data()
	if data is Dictionary:
		_process_chunk(data)
func _process_chunk(data: Dictionary) -> bool:
	if data.has("error"):
		_emit_failure(str(data.get("error")))
		return true
	if data.has("response"):
		var response_text: String = str(data.get("response", ""))
		if not response_text.is_empty():
			_collected_text += response_text
			token.emit(_task_id, response_text)
	elif data.has("message"):
		var msg: Variant = data.get("message")
		if msg is Dictionary and msg.has("content"):
			var content: Variant = msg["content"]
			if content is Array:
				for entry in content:
					if entry is Dictionary and entry.get("type", "") == "text":
						var chunk_text: String = str(entry.get("text", ""))
						if not chunk_text.is_empty():
							_collected_text += chunk_text
							token.emit(_task_id, chunk_text)
	if data.get("done", false):
		_finalize_success(data)
		return true
	return false
func _finalize_success(last_payload: Dictionary) -> void:
	if not _is_active:
		return
	var task_id := _task_id
	_http.close()
	var collected := _collected_text
	var payload := { "text": collected }
	if not last_payload.is_empty():
		payload["done_payload"] = last_payload.duplicate(true)
	_reset_state()
	completed.emit(task_id, true, payload)
func _emit_failure(reason: String) -> void:
	if _task_id == -1 and not _is_active:
		return
	var task_id := _task_id
	_http.close()
	_reset_state()
	if task_id != -1:
		failed.emit(task_id, reason)
func _reset_state() -> void:
	set_process(false)
	_is_active = false
	_request_sent = false
	_task_id = -1
	_path = ""
	_host = ""
	_port = 0
	_body = ""
	_leftover = ""
	_collected_text = ""
	_http = HTTPClient.new()
