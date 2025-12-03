extends Node
var _completed: bool = false
var _timeout_timer: Timer
func _ready() -> void:
	print("[LLM Test] Starting local LLM smoke test.")
	if AIManager == null:
		print("[LLM Test] AIManager autoload unavailable.")
		_quit_with_code(1)
		return
	_timeout_timer = Timer.new()
	_timeout_timer.wait_time = 15.0
	_timeout_timer.one_shot = true
	add_child(_timeout_timer)
	_timeout_timer.timeout.connect(_on_timeout)
	_timeout_timer.start()
	var error_callable := Callable(self, "_on_ai_error")
	if AIManager.ai_error.is_connected(error_callable):
		AIManager.ai_error.disconnect(error_callable)
	AIManager.ai_error.connect(error_callable)
	var token_callable := Callable(self, "_on_token")
	if not OllamaClient.token.is_connected(token_callable):
		OllamaClient.token.connect(token_callable)
	AIManager.current_provider = AIManager.AIProvider.OLLAMA
	AIManager.ollama_use_chat = true
	if AIManager.has_method("_apply_ollama_configuration"):
		AIManager._apply_ollama_configuration()
	if not OllamaClient.health_check(1.0, true):
		print("[LLM Test] Ollama service unavailable. Ensure the local runtime is running.")
		_quit_with_code(1)
		return
	var prompt := "Provide a one sentence status update for Glorious Deliverance Agency."
	AIManager.request_ai(prompt, Callable(self, "_on_ai_response"), { "purpose": "test" })
func _on_ai_response(response) -> void:
	if _completed:
		return
	_completed = true
	_timeout_timer.stop()
	var text := ""
	if response is Dictionary:
		if not response.get("success", true):
			var error_text := str(response.get("error", "Unknown error"))
			print("[LLM Test] Local LLM reported failure: " + error_text)
			_quit_with_code(1)
			return
		text = str(response.get("content", ""))
	else:
		text = str(response)
	print("[LLM Test] Final response: " + text.strip_edges())
	_quit_with_code(0)
func _on_ai_error(message: String) -> void:
	if _completed:
		return
	_completed = true
	_timeout_timer.stop()
	print("[LLM Test] Error: " + message)
	_quit_with_code(1)
func _on_token(task_id: int, text: String) -> void:
	if _completed:
		return
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		return
	print("[LLM Test] token: " + trimmed)
func _on_timeout() -> void:
	if _completed:
		return
	_completed = true
	print("[LLM Test] Timed out waiting for local LLM response.")
	_quit_with_code(2)
func _quit_with_code(code: int) -> void:
	if get_tree():
		get_tree().quit(code)
func _exit_tree() -> void:
	var error_callable := Callable(self, "_on_ai_error")
	if AIManager.ai_error.is_connected(error_callable):
		AIManager.ai_error.disconnect(error_callable)
	var token_callable := Callable(self, "_on_token")
	if OllamaClient.token.is_connected(token_callable):
		OllamaClient.token.disconnect(token_callable)
