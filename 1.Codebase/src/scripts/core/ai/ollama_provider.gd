extends "res://1.Codebase/src/scripts/core/ai/ai_provider_base.gd"
class_name OllamaProvider
const DEFAULT_OLLAMA_MODEL := "gemma3:1b"
var host: String = "127.0.0.1"
var port: int = 11434
var model: String = DEFAULT_OLLAMA_MODEL
var use_chat: bool = true
var options: Dictionary = {
	"temperature": 0.7,
	"top_p": 0.9,
	"num_ctx": 2048,
	"seed": 42,
	"num_predict": 192,
}
var ollama_client: Node 
var pending_tasks: Dictionary = { }
var active_task_id: int = -1
var partial_response: String = ""
var last_progress_emit_msec: int = 0
func _init():
	provider_name = "Ollama"
func setup(client: Node) -> void:
	ollama_client = client
	_connect_signals()
	_apply_configuration()
func is_configured() -> bool:
	return not host.is_empty() and not model.is_empty() and port > 0
func get_configuration() -> Dictionary:
	return {
		"host": host,
		"port": port,
		"model": model,
		"use_chat": use_chat,
		"options": options.duplicate(true),
	}
func apply_configuration(config: Dictionary) -> void:
	if config.has("host"):
		host = str(config["host"])
	if config.has("port"):
		port = int(config["port"])
	if config.has("model"):
		model = str(config["model"])
	if config.has("use_chat"):
		use_chat = bool(config["use_chat"])
	if config.has("options") and config["options"] is Dictionary:
		options = (config["options"] as Dictionary).duplicate(true)
	_apply_configuration()
func _apply_configuration() -> void:
	if ollama_client and ollama_client.has_method("configure"):
		ollama_client.configure(host, port, model, use_chat, options)
func _connect_signals() -> void:
	if not ollama_client:
		return
	if ollama_client.has_signal("token") and not ollama_client.token.is_connected(_on_token):
		ollama_client.token.connect(_on_token)
	if ollama_client.has_signal("completed") and not ollama_client.completed.is_connected(_on_completed):
		ollama_client.completed.connect(_on_completed)
	if ollama_client.has_signal("error") and not ollama_client.error.is_connected(_on_error):
		ollama_client.error.connect(_on_error)
	if ollama_client.has_signal("request_started") and not ollama_client.request_started.is_connected(_on_request_started):
		ollama_client.request_started.connect(_on_request_started)
func send_request(messages: Array, callback: Callable, _options: Dictionary = { }) -> void:
	if not is_configured():
		var not_configured_msg := "Ollama is not configured"
		_emit_error(not_configured_msg)
		_notify_callback_failure(callback, not_configured_msg)
		request_completed.emit(false)
		return
	if not _check_health():
		var health_msg := "Ollama service is unavailable"
		_emit_error(health_msg)
		_notify_callback_failure(callback, health_msg)
		request_completed.emit(false)
		return
	is_requesting = true
	partial_response = ""
	last_progress_emit_msec = 0
	request_started.emit()
	var task_id: int
	if use_chat:
		var chat_messages := _messages_to_chat(messages)
		task_id = ollama_client.ask_chat(chat_messages, options.duplicate(true))
	else:
		var prompt_text := _messages_to_prompt(messages)
		task_id = ollama_client.ask_prompt(prompt_text, options.duplicate(true))
	pending_tasks[task_id] = {
		"callback": callback,
		"enqueued_at": Time.get_ticks_msec(),
	}
	_emit_progress({ "status": "queued", "task_id": task_id })
func cancel_request() -> void:
	is_requesting = false
	if active_task_id != -1 and pending_tasks.has(active_task_id):
		pending_tasks.erase(active_task_id)
	if ollama_client and active_task_id != -1:
		ollama_client.cancel(active_task_id)
	active_task_id = -1
	partial_response = ""
func _check_health() -> bool:
	if not ollama_client or not ollama_client.has_method("health_check"):
		return false
	return ollama_client.health_check(1.0)
func _messages_to_chat(messages: Array) -> Array:
	var chat_payload: Array = []
	for entry in messages:
		if not (entry is Dictionary):
			continue
		var msg: Dictionary = entry
		var role := str(msg.get("role", "user")).to_lower()
		if role == "model":
			role = "assistant"
		var text := _message_to_plain_text(msg)
		if text.strip_edges().is_empty():
			continue
		chat_payload.append(
			{
				"role": role,
				"content": text
			}
		)
	return chat_payload
func _messages_to_prompt(messages: Array) -> String:
	var segments: Array = []
	for entry in messages:
		if not (entry is Dictionary):
			continue
		var msg: Dictionary = entry
		var role := str(msg.get("role", "user")).to_lower()
		if role == "model":
			role = "assistant"
		var text := _message_to_plain_text(msg)
		if text.strip_edges().is_empty():
			continue
		match role:
			"system":
				segments.append("# System\n%s" % text)
			"assistant":
				segments.append("Assistant:\n%s" % text)
			_:
				segments.append("User:\n%s" % text)
	return "\n\n".join(segments)
func _message_to_plain_text(message: Dictionary) -> String:
	if not message is Dictionary:
		return ""
	if message.has("parts") and message["parts"] is Array:
		var combined_text := ""
		for part in message["parts"]:
			if part is Dictionary:
				if part.has("text"):
					combined_text += str(part["text"])
		if not combined_text.is_empty():
			return combined_text
	return str(message.get("content", ""))
func _on_request_started(task_id: int) -> void:
	if not pending_tasks.has(task_id):
		return
	active_task_id = task_id
	last_progress_emit_msec = Time.get_ticks_msec()
	is_requesting = true
	_emit_progress({ "status": "started", "task_id": task_id })
func _on_token(task_id: int, text: String) -> void:
	if task_id != active_task_id:
		return
	partial_response += text
	var now_msec := Time.get_ticks_msec()
	if last_progress_emit_msec == 0 or now_msec - last_progress_emit_msec >= 150:
		last_progress_emit_msec = now_msec
		_emit_progress(
			{
				"status": "streaming",
				"task_id": task_id,
				"partial_chars": partial_response.length(),
				"chunk_chars": text.length(),
			},
		)
func _on_completed(task_id: int, ok: bool, data: Dictionary) -> void:
	if task_id != active_task_id:
		return
	is_requesting = false
	active_task_id = -1
	var response_text := str(data.get("text", partial_response)).strip_edges()
	if response_text.is_empty():
		_emit_error("Empty Ollama response")
		request_completed.emit(false)
		pending_tasks.erase(task_id)
		return
	var response := {
		"success": ok,
		"content": response_text,
		"error": "" if ok else "Ollama request failed",
	}
	if data.has("done_payload") and data["done_payload"] is Dictionary:
		var stats: Dictionary = data["done_payload"]
		response["input_tokens"] = int(stats.get("prompt_eval_count", 0))
		response["output_tokens"] = int(stats.get("eval_count", 0))
	if pending_tasks.has(task_id):
		var entry: Dictionary = pending_tasks[task_id]
		var cb: Callable = entry.get("callback", Callable())
		if cb is Callable and not cb.is_null():
			cb.call(response)
		pending_tasks.erase(task_id)
	_emit_progress({ "status": "completed", "task_id": task_id, "ok": ok })
	request_completed.emit(ok)
	partial_response = ""
func _on_error(task_id: int, reason: String) -> void:
	if task_id != active_task_id and active_task_id != -1:
		return
	is_requesting = false
	active_task_id = -1
	partial_response = ""
	if pending_tasks.has(task_id):
		var entry: Dictionary = pending_tasks[task_id]
		var cb: Callable = entry.get("callback", Callable())
		pending_tasks.erase(task_id)
		if reason != "cancelled":
			var error_msg := "Ollama error: %s" % reason
			_notify_callback_failure(cb, error_msg)
	_emit_error("Ollama error: " + reason)
	request_completed.emit(false)
func _notify_callback_failure(callback: Callable, message: String) -> void:
	if not callback.is_valid():
		return
	callback.call({
		"success": false,
		"error": message,
		"content": "",
	})
func parse_response(_result: int, _response_code: int, _body: PackedByteArray) -> Dictionary:
	ErrorReporterBridge.report_warning(
		"OllamaProvider",
		"parse_response() called unexpectedly. Ollama uses streaming callbacks, not HTTP parsing.",
	)
	return {
		"success": false,
		"error": "parse_response not applicable for Ollama (uses streaming callbacks)",
		"content": "",
	}
