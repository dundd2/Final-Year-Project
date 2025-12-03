extends Node
const ERROR_CONTEXT := "OllamaClient"
signal server_ready()
signal request_started(task_id: int)
signal token(task_id: int, text: String)
signal completed(task_id: int, ok: bool, data: Dictionary)
signal error(task_id: int, reason: String)
const StreamRequest = preload("res://1.Codebase/src/scripts/core/ollama_stream_request.gd")
const DEFAULT_MODEL = "gemma3:1b"
const BASE_DEFAULT_OPTIONS := {
	"temperature": 0.7,
	"top_p": 0.9,
	"num_ctx": 2048,
	"seed": 42,
	"num_predict": 192,
}
enum LogLevel { ERROR, WARN, INFO, DEBUG }
const _LOG_LABELS: Array[String] = ["ERROR", "WARN", "INFO", "DEBUG"]
var log_level: LogLevel = LogLevel.INFO
var host: String = "127.0.0.1"
var port: int = 11434
var model: String = DEFAULT_MODEL
var use_chat: bool = true
var default_options: Dictionary = BASE_DEFAULT_OPTIONS.duplicate(true)
var max_concurrent: int = 1
var request_timeout_sec: float = 60.0
var health_cache_msec: int = 5000
var _next_task_id: int = 1
var _active: Dictionary = { }
var _queue: Array[Dictionary] = []
var _last_health_ok: bool = false
var _last_health_check_msec: int = 0
var _last_tags_result: Dictionary = { }
func _log(level: LogLevel, message: String, details: Dictionary = { }) -> void:
	if level > log_level:
		return
	var index: int = clamp(int(level), 0, _LOG_LABELS.size() - 1)
	var suffix: String = ""
	if not details.is_empty():
		var json_text: String = JSON.stringify(details)
		if not json_text.is_empty():
			suffix = " | " + json_text
	print("[OllamaClient][%s] %s%s" % [_LOG_LABELS[index], message, suffix])
func _log_error(message: String, details: Dictionary = { }) -> void:
	_log(LogLevel.ERROR, message, details)
func _log_warn(message: String, details: Dictionary = { }) -> void:
	_log(LogLevel.WARN, message, details)
func _log_info(message: String, details: Dictionary = { }) -> void:
	_log(LogLevel.INFO, message, details)
func _log_debug(message: String, details: Dictionary = { }) -> void:
	_log(LogLevel.DEBUG, message, details)
func configure(host: String = "127.0.0.1", port: int = 11434, model: String = "", use_chat: bool = true, options: Dictionary = { }) -> void:
	self.host = host.strip_edges()
	self.port = port
	if not model.is_empty():
		self.model = model.strip_edges()
	self.use_chat = use_chat
	if not options.is_empty():
		default_options = BASE_DEFAULT_OPTIONS.duplicate(true)
		for key in options.keys():
			default_options[key] = options[key]
	_last_health_ok = false
	_last_health_check_msec = 0
	_last_tags_result = { }
func set_default_options(options: Dictionary) -> void:
	default_options = options.duplicate(true)
func set_max_concurrent(limit: int) -> void:
	max_concurrent = max(1, limit)
	_process_queue()
func ask_prompt(prompt: String, opts: Dictionary = { }, stream: bool = true) -> int:
	var safe_prompt: String = prompt
	if safe_prompt.strip_edges().is_empty():
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "ask_prompt called with empty prompt")
	var payload: Dictionary = {
		"model": model,
		"prompt": safe_prompt,
		"stream": stream,
		"options": _merge_options(opts),
	}
	return _enqueue_job("/api/generate", payload)
func ask_chat(messages: Array, opts: Dictionary = { }, stream: bool = true) -> int:
	var normalized_messages: Array = _normalize_chat_messages(messages)
	var payload: Dictionary = {
		"model": model,
		"messages": normalized_messages,
		"stream": stream,
		"options": _merge_options(opts),
	}
	return _enqueue_job("/api/chat", payload)
func cancel(task_id: int) -> void:
	if _active.has(task_id):
		var request: Node = _active[task_id]["node"]
		if request and request.has_method("cancel"):
			request.cancel()
		_active.erase(task_id)
		_process_queue()
	else:
		for i in range(_queue.size()):
			if _queue[i]["task_id"] == task_id:
				_queue.remove_at(i)
				break
func cancel_all() -> void:
	for task_id in _active.keys():
		cancel(task_id)
	_queue.clear()
	_active.clear()
func _perform_simple_get(path: String, timeout_sec: float) -> Dictionary:
	_log_debug(
		"Starting simple GET",
		{
			"path": path,
			"timeout_sec": timeout_sec,
		},
	)
	var result: Dictionary = {
		"ok": false,
		"status_code": 0,
		"body_bytes": PackedByteArray(),
		"body_text": "",
	}
	var client: HTTPClient = HTTPClient.new()
	client.set_blocking_mode(true)
	var connect_err: Error = client.connect_to_host(host, port)
	if connect_err != OK:
		_log_error(
			"Failed to connect to host",
			{
				"code": connect_err,
				"message": error_string(connect_err),
				"host": host,
				"port": port,
			},
		)
		result["error"] = "connect_error=%s" % error_string(connect_err)
		return result
	var connect_deadline: int = Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while true:
		var status := client.get_status()
		if status == HTTPClient.STATUS_CONNECTED:
			break
		if status == HTTPClient.STATUS_CONNECTION_ERROR or status == HTTPClient.STATUS_CANT_CONNECT or status == HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
			_log_error("Connection failed during GET (pre-request)", { "status": status, "path": path })
			result["error"] = "connection_error"
			client.close()
			return result
		if Time.get_ticks_msec() > connect_deadline:
			_log_error("Timed out waiting for connection", { "path": path })
			result["error"] = "connect_timeout"
			client.close()
			return result
		var wait_err := client.poll()
		if wait_err != OK:
			_log_error(
				"HTTP poll failed while waiting for connection",
				{
					"code": wait_err,
					"message": error_string(wait_err),
				},
			)
			result["error"] = "poll_error=%s" % error_string(wait_err)
			client.close()
			return result
		OS.delay_usec(1000)
	var request_err: Error = client.request(HTTPClient.METHOD_GET, path, PackedStringArray(), "")
	if request_err != OK:
		_log_error(
			"Failed to send GET request",
			{
				"code": request_err,
				"message": error_string(request_err),
				"path": path,
			},
		)
		result["error"] = "request_error=%s" % error_string(request_err)
		client.close()
		return result
	var deadline: int = Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	var body: PackedByteArray = PackedByteArray()
	while Time.get_ticks_msec() < deadline:
		var poll_err: Error = client.poll()
		if poll_err != OK:
			_log_error(
				"HTTP poll failed",
				{
					"code": poll_err,
					"message": error_string(poll_err),
				},
			)
			result["error"] = "poll_error=%s" % error_string(poll_err)
			client.close()
			return result
		var status: int = client.get_status()
		match status:
			HTTPClient.STATUS_BODY:
				var chunk: PackedByteArray = client.read_response_body_chunk()
				if chunk.is_empty():
					continue
				body.append_array(chunk)
			HTTPClient.STATUS_CONNECTED:
				if not client.has_response():
					continue
			HTTPClient.STATUS_DISCONNECTED:
				break
			HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_CANT_RESOLVE, HTTPClient.STATUS_CANT_CONNECT, HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
				_log_error("Connection failed during GET", { "status": status })
				result["error"] = "connection_error"
				client.close()
				return result
			_:
				pass
	var status_code: int = client.get_response_code()
	client.close()
	result["status_code"] = status_code
	result["body_bytes"] = body
	result["body_text"] = body.get_string_from_utf8()
	result["ok"] = status_code >= 200 and status_code < 300
	if not result["ok"]:
		_log_warn(
			"GET completed with non-success status",
			{
				"status_code": status_code,
				"path": path,
			},
		)
	else:
		_log_info(
			"GET completed",
			{
				"status_code": status_code,
				"bytes": body.size(),
			},
		)
	return result
func fetch_tags(timeout_sec: float = 2.0, force_refresh: bool = false) -> Dictionary:
	if not force_refresh and not _last_tags_result.is_empty():
		var age: int = Time.get_ticks_msec() - int(_last_tags_result.get("timestamp", 0))
		if age >= 0 and age < health_cache_msec:
			return _last_tags_result.duplicate(true)
	var response: Dictionary = _perform_simple_get("/api/tags", timeout_sec)
	if response.get("ok", false):
		var json: JSON = JSON.new()
		var parse_err: Error = json.parse(response.get("body_text", ""))
		if parse_err == OK:
			var data: Variant = json.get_data()
			response["data"] = data
			if data is Dictionary and data.has("models") and data["models"] is Array:
				response["models"] = (data["models"] as Array).duplicate(true)
		else:
			response["ok"] = false
			response["error"] = "invalid_json"
			response["error_code"] = parse_err
	_last_tags_result = response.duplicate(true)
	_last_tags_result["timestamp"] = Time.get_ticks_msec()
	return response
func health_check(timeout_sec: float = 2.0, force_refresh: bool = false) -> bool:
	_log_debug("Performing health check", { "host": host, "port": port })
	var now: int = Time.get_ticks_msec()
	if not force_refresh and now - _last_health_check_msec < health_cache_msec:
		_log_debug("Health check result from cache", { "ok": _last_health_ok })
		return _last_health_ok
	var response: Dictionary = fetch_tags(timeout_sec, force_refresh)
	_last_health_ok = response.get("ok", false)
	_last_health_check_msec = Time.get_ticks_msec()
	_log_info("Health check completed", { "ok": _last_health_ok })
	if not _last_health_ok:
		_log_warn("Health check failed", { "response": response })
	else:
		server_ready.emit()
	return _last_health_ok
func _enqueue_job(path: String, payload: Dictionary) -> int:
	var task_id: int = _next_task_id
	_next_task_id += 1
	var job: Dictionary = {
		"task_id": task_id,
		"path": path,
		"payload": payload,
	}
	_queue.append(job)
	call_deferred("_process_queue")
	return task_id
func _process_queue() -> void:
	while _queue.size() > 0 and _active.size() < max_concurrent:
		var job: Dictionary = _queue.pop_front()
		_start_job(job)
func _start_job(job: Dictionary) -> void:
	var task_id: int = job["task_id"]
	var request: Node = StreamRequest.new()
	add_child(request)
	request.token.connect(_on_request_token)
	request.completed.connect(_on_request_completed)
	request.failed.connect(_on_request_failed)
	request.start(host, port, job["path"], job["payload"], task_id, request_timeout_sec)
	_active[task_id] = {
		"node": request,
		"path": job["path"],
		"payload": job["payload"],
	}
	request_started.emit(task_id)
func _on_request_token(task_id: int, text: String) -> void:
	token.emit(task_id, text)
func _on_request_completed(task_id: int, ok: bool, data: Dictionary) -> void:
	if _active.has(task_id):
		var request: Node = _active[task_id]["node"]
		if request:
			request.queue_free()
		_active.erase(task_id)
	completed.emit(task_id, ok, data)
	_process_queue()
func _on_request_failed(task_id: int, reason: String) -> void:
	if _active.has(task_id):
		var request: Node = _active[task_id]["node"]
		if request:
			request.queue_free()
		_active.erase(task_id)
	error.emit(task_id, reason)
	_process_queue()
func _merge_options(extra: Dictionary) -> Dictionary:
	var merged: Dictionary = default_options.duplicate(true)
	for key in extra.keys():
		merged[key] = extra[key]
	return merged
func _normalize_chat_messages(messages: Array) -> Array:
	var result: Array = []
	for entry in messages:
		if entry is Dictionary:
			var role: String = str(entry.get("role", "user")).to_lower()
			var content: Variant = entry.get("content", "")
			result.append(
				{
					"role": role,
					"content": content,
				}
			)
		elif entry is Array and entry.size() >= 2:
			result.append(
				{
					"role": str(entry[0]).to_lower(),
					"content": str(entry[1]),
				},
			)
	return result
