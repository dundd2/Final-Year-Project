extends "res://1.Codebase/src/scripts/core/ai/ai_provider_base.gd"
class_name OpenRouterProvider
const OPENROUTER_ENDPOINT = "https://openrouter.ai/api/v1/chat/completions"
var api_key: String = ""
var model: String = "google/gemini-pro"
var http_request: HTTPRequest
var pending_callback: Callable
func _init():
	provider_name = "OpenRouter"
func setup(http_req: HTTPRequest) -> void:
	http_request = http_req
func is_configured() -> bool:
	return not api_key.is_empty()
func get_configuration() -> Dictionary:
	return {
		"api_key": api_key,
		"model": model,
	}
func apply_configuration(config: Dictionary) -> void:
	if config.has("api_key"):
		api_key = str(config["api_key"])
	if config.has("model"):
		model = str(config["model"])
func send_request(messages: Array, callback: Callable, _options: Dictionary = { }) -> void:
	if not is_configured():
		_emit_error("OpenRouter API key is not configured")
		_notify_callback_failure(callback, "OpenRouter API key is not configured")
		return
	is_requesting = true
	pending_callback = callback
	request_started.emit()
	var openai_messages = _messages_to_openai_format(messages)
	var body = {
		"model": model,
		"messages": openai_messages,
		"temperature": 0.9,
		"max_tokens": 2048,
	}
	if _options.has("response_mime_type") and _options["response_mime_type"] == "application/json":
		body["response_format"] = { "type": "json_object" }
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key,
		"HTTP-Referer: https://github.com/dundd2/Individual-Project",
		"X-Title: GDA1 Game",
	]
	var json_body = JSON.stringify(body)
	_emit_progress({ "status": "sending", "body_bytes": json_body.length() })
	var error = http_request.request(OPENROUTER_ENDPOINT, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		is_requesting = false
		var err_msg = "Failed to send OpenRouter request: " + str(error)
		_emit_error(err_msg)
		_notify_callback_failure(callback, err_msg)
		request_completed.emit(false)
func cancel_request() -> void:
	is_requesting = false
	if http_request:
		http_request.cancel_request()
func parse_response(result: int, response_code: int, body: PackedByteArray) -> Dictionary:
	if result != HTTPRequest.RESULT_SUCCESS:
		return { "success": false, "error": "Network error", "content": "" }
	if response_code != 200:
		var error_text = "HTTP %d" % response_code
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.data
			if data.has("error") and data["error"].has("message"):
				error_text += ": " + str(data["error"]["message"])
		return { "success": false, "error": error_text, "content": "" }
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return { "success": false, "error": "JSON parse error", "content": "" }
	var response_data = json.data
	var ai_text := ""
	if response_data.has("choices") and response_data["choices"].size() > 0:
		var choice = response_data["choices"][0]
		if choice.has("message") and choice["message"].has("content"):
			ai_text = str(choice["message"]["content"])
		elif choice.has("text"):
			ai_text = str(choice["text"])
	var response := {
		"success": not ai_text.is_empty(),
		"content": ai_text,
		"error": "",
		"audio_payloads": [],
	}
	if response_data.has("usage"):
		var usage = response_data["usage"]
		response["input_tokens"] = usage.get("prompt_tokens", 0)
		response["output_tokens"] = usage.get("completion_tokens", 0)
	return response
func _messages_to_openai_format(messages: Array) -> Array:
	var openai_messages: Array = []
	for msg in messages:
		if not msg is Dictionary:
			continue
		var role = str(msg.get("role", "user")).to_lower()
		if role == "model":
			role = "assistant"
		var content_text = ""
		if msg.has("parts") and msg["parts"] is Array:
			for part in msg["parts"]:
				if part is Dictionary:
					if part.has("text"):
						content_text += str(part["text"])
		elif msg.has("content"):
			content_text = str(msg["content"])
		if not content_text.is_empty():
			openai_messages.append({
				"role": role,
				"content": content_text
			})
	return openai_messages
func _notify_callback_failure(callback: Callable, message: String) -> void:
	if not callback.is_valid():
		return
	callback.call({
		"success": false,
		"error": message,
		"content": "",
	})
