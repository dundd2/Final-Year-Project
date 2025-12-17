extends RefCounted
class_name AIRequestManager
const AIRequestRateLimiterScript = preload("res://1.Codebase/src/scripts/core/ai/request_rate_limiter.gd")
const AIRequestQueueScript = preload("res://1.Codebase/src/scripts/core/ai/request_queue.gd")
const MockAIGeneratorScript = preload("res://1.Codebase/src/scripts/core/mock_ai_generator.gd")
const AISafetyFilter = preload("res://1.Codebase/src/scripts/core/ai_safety_filter.gd")
const AIEventChannels = preload("res://1.Codebase/src/scripts/core/ai/ai_event_channels.gd")
const ERROR_CONTEXT := "AIRequestManager"
const DEFAULT_REQUEST_TIMEOUT := GameConstants.AI.DEFAULT_REQUEST_TIMEOUT
const LIVE_NATIVE_AUDIO_TIMEOUT := 60.0
const DEFAULT_MAX_RETRIES := GameConstants.AI.DEFAULT_MAX_RETRIES
const MIN_REQUEST_INTERVAL_MSEC := GameConstants.AI.MIN_REQUEST_INTERVAL_MSEC
const MAX_REQUESTS_PER_MINUTE := GameConstants.AI.MAX_REQUESTS_PER_MINUTE
const RATE_LIMIT_COOLDOWN_MSEC := GameConstants.AI.RATE_LIMIT_COOLDOWN_MSEC
const MAX_HISTORY_SIZE := GameConstants.AI.MAX_HISTORY_SIZE
const AIProvider := AIConfigManager.AIProvider
var _is_requesting: bool = false
var _request_timeout: float = DEFAULT_REQUEST_TIMEOUT
var _max_retries: int = DEFAULT_MAX_RETRIES
var _retry_count: int = 0
var _last_sent_messages: Array[Dictionary] = []
var pending_callback: Callable = Callable()
var _active_request_payload: Dictionary = { }
var _active_provider_name: String = ""
var _timeout_timer: Timer = null
var _rate_limiter: RefCounted = null
var _request_queue: RefCounted = null
var http_request: HTTPRequest = null
var last_prompt_metrics: Dictionary = { }
var _total_api_calls: int = 0
var _total_tokens_consumed: int = 0
var _last_response_time: float = 0.0
var _last_input_tokens: int = 0
var _last_output_tokens: int = 0
var _response_time_history: Array[float] = []
var _token_usage_history: Array[int] = []
var _prompt_guard_regex: RegEx = null
var _config_manager: AIConfigManager = null
var _provider_manager: AIProviderManager = null
var _context_manager: AIContextManager = null
var _voice_manager: AIVoiceManager = null
var _mock_override_enabled: bool = false
var _mock_override_reason: String = ""
signal request_started()
signal request_progress(update: Dictionary)
signal request_completed(success: bool)
signal request_error(message: String)
signal response_received(response: Dictionary)
func set_config_manager(config_mgr: AIConfigManager) -> void:
	_config_manager = config_mgr
func set_provider_manager(provider_mgr) -> void:
	_provider_manager = provider_mgr
func set_context_manager(context_mgr) -> void:
	_context_manager = context_mgr
func set_voice_manager(voice_mgr) -> void:
	_voice_manager = voice_mgr
func initialize_request_system(parent_node: Node, http_req: HTTPRequest) -> void:
	http_request = http_req
	if not http_request.request_completed.is_connected(_on_request_completed):
		http_request.request_completed.connect(_on_request_completed)
	_timeout_timer = Timer.new()
	_timeout_timer.one_shot = true
	_timeout_timer.wait_time = _request_timeout
	parent_node.add_child(_timeout_timer)
	if not _timeout_timer.timeout.is_connected(_on_request_timeout):
		_timeout_timer.timeout.connect(_on_request_timeout)
	_rate_limiter = AIRequestRateLimiterScript.new()
	_rate_limiter.configure(MIN_REQUEST_INTERVAL_MSEC, MAX_REQUESTS_PER_MINUTE, RATE_LIMIT_COOLDOWN_MSEC)
	_request_queue = AIRequestQueueScript.new()
	_request_queue.configure(Callable(self, "_debug_request_stage"))
	print("[AIRequestManager] Request system initialized")
func request_ai(prompt: String, callback: Callable = Callable(), context_or_callback = null) -> void:
	print("[AIRequestManager] Received new AI request. Prompt: ", prompt.left(80), "...")
	var provider_name = _provider_manager.get_current_provider_name() if _provider_manager else "UNKNOWN"
	_debug_request_stage(
		"request_received",
		{
			"provider": provider_name,
			"prompt_chars": prompt.length(),
		},
	)
	var params := _parse_request_parameters(callback, context_or_callback)
	var base_context: Dictionary = params["context"]
	var request_context: Dictionary = base_context.duplicate(true)
	var callback_to_use: Callable = params["callback"]
	var force_mock: bool = params["force_mock"]
	var normalized_prompt := prompt.strip_edges()
	var validation_issue := _validate_prompt(normalized_prompt)
	if not validation_issue.is_empty():
		var debug_payload: Dictionary = {
			"provider": provider_name,
			"reason": "invalid_prompt",
		}
		var validation_details = validation_issue.get("details", { })
		if validation_details is Dictionary and not (validation_details as Dictionary).is_empty():
			debug_payload["details"] = validation_details
		_debug_request_stage("request_blocked", debug_payload)
		_handle_invalid_prompt(validation_issue, callback_to_use)
		return
	prompt = normalized_prompt
	if _should_queue_request():
		_queue_request(prompt, callback_to_use, request_context.duplicate(true), force_mock)
		return
	_active_provider_name = provider_name
	if _is_rate_limited(force_mock):
		_debug_request_stage(
			"request_blocked",
			{
				"provider": provider_name,
				"reason": "rate_limited",
			},
		)
		return
	pending_callback = callback_to_use if not callback_to_use.is_null() else Callable()
	_last_sent_messages.clear()
	AISafetyFilter.reset_session()
	var full_messages := _prepare_request_messages(prompt, request_context, force_mock)
	if _should_use_mock(force_mock):
		_handle_mock_request(prompt, request_context, force_mock)
		_clear_active_request_payload()
		return
	_active_request_payload = {
		"prompt": prompt,
		"context": request_context.duplicate(true),
		"force_mock": force_mock,
	}
	var current_provider = _config_manager.current_provider if _config_manager else AIProvider.GEMINI
	last_prompt_metrics["mode"] = "local" if current_provider == AIProvider.OLLAMA else "live"
	last_prompt_metrics["provider"] = current_provider
	last_prompt_metrics["response_chars"] = 0
	last_prompt_metrics["response_tokens_est"] = 0
	last_prompt_metrics["start_time_msec"] = Time.get_ticks_msec()
	var dispatch_details := {
		"provider": provider_name,
		"messages": full_messages.size(),
	}
	if _config_manager:
		match current_provider:
			AIProvider.GEMINI:
				dispatch_details["model"] = _config_manager.gemini_model
			AIProvider.OPENROUTER:
				dispatch_details["model"] = _config_manager.openrouter_model
			AIProvider.OLLAMA:
				dispatch_details["model"] = _config_manager.ollama_model
	_debug_request_stage("request_dispatch", dispatch_details)
	print("[AIRequestManager] Sending AI request to provider: ", provider_name)
	_dispatch_to_provider(full_messages)
func _parse_request_parameters(callback: Callable, context_or_callback) -> Dictionary:
	var result := {
		"context": { },
		"callback": Callable(),
		"force_mock": false,
	}
	if not callback.is_null():
		result["callback"] = callback
	if context_or_callback is Callable:
		result["callback"] = context_or_callback
	elif context_or_callback is Dictionary:
		var opts: Dictionary = (context_or_callback as Dictionary).duplicate(true)
		var context_payload: Dictionary = { }
		if opts.has("force_mock"):
			result["force_mock"] = bool(opts.get("force_mock", false))
			opts.erase("force_mock")
		if opts.has("context") and opts["context"] is Dictionary:
			context_payload = (opts["context"] as Dictionary).duplicate(true)
		elif not opts.is_empty():
			context_payload = opts
		if not context_payload.is_empty():
			result["context"] = context_payload
	elif context_or_callback != null:
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Invalid context_or_callback parameter type",
			{ "type": typeof(context_or_callback) },
		)
	if result["callback"].is_null() and not callback.is_null():
		result["callback"] = callback
	return result
func _should_queue_request() -> bool:
	return _is_requesting
func _prepare_request_messages(prompt: String, context: Dictionary, force_mock: bool) -> Array[Dictionary]:
	var full_messages: Array[Dictionary] = []
	if _context_manager:
		full_messages = _context_manager.build_request_messages(prompt, context)
	else:
		full_messages = [{ "role": "user", "content": prompt }]
	_record_prompt_metrics(full_messages, prompt, context, force_mock)
	var input_redactions: Array = AISafetyFilter.consume_redactions()
	if input_redactions.size() > 0:
		last_prompt_metrics["input_redactions"] = input_redactions.duplicate()
		print("[AI Safety] Redacted sensitive user content tokens:", input_redactions)
	var last_message = full_messages.back()
	if last_message is Dictionary:
		var role = str(last_message.get("role", "user"))
		var content = str(last_message.get("content", ""))
		if _context_manager:
			_context_manager.add_to_memory(role, content)
	return full_messages
func _handle_mock_request(prompt: String, context: Dictionary, force_mock: bool) -> void:
	var provider_name = _provider_manager.get_current_provider_name() if _provider_manager else "UNKNOWN"
	_debug_request_stage(
		"request_mock_response",
		{
			"reason": "force_mock" if force_mock else "mock_enabled",
			"provider": "MOCK",
		},
	)
	last_prompt_metrics["mode"] = "mock"
	var mock_text: String = MockAIGeneratorScript.generate_response(prompt, context)
	last_prompt_metrics["response_chars"] = mock_text.length()
	last_prompt_metrics["response_tokens_est"] = _estimate_tokens(mock_text.length())
	if _context_manager:
		_context_manager.add_to_memory("assistant", mock_text)
		last_prompt_metrics["memory_entries_after"] = _context_manager.memory_store.story_memory.size()
	var response = {
		"success": true,
		"content": mock_text,
		"error": "",
	}
	var response_context: Dictionary = { }
	if context is Dictionary and not context.is_empty():
		response_context = (context as Dictionary).duplicate(true)
	if not response_context.is_empty():
		response["context"] = response_context
		var derived_type := _derive_response_type_from_context(response_context)
		if not derived_type.is_empty():
			response["type"] = derived_type
	var metadata: Dictionary = {
		"mode": "mock",
		"force_mock": force_mock,
	}
	if response.has("type"):
		metadata["response_type"] = String(response["type"])
	response["metadata"] = metadata
	_emit_safety_checked_response(response)
func _dispatch_to_provider(full_messages: Array[Dictionary]) -> void:
	if not _provider_manager or not _config_manager:
		_emit_error("Provider or config manager not initialized")
		_notify_callback_of_failure("Provider or config manager not initialized")
		return
	var current_provider = _config_manager.current_provider
	_provider_manager.sync_provider(current_provider)
	if _voice_manager:
		_voice_manager.refresh_capabilities()
	var provider = _provider_manager.get_current_provider()
	if provider and provider.has_method("apply_configuration") and _config_manager:
		var provider_config := _config_manager.get_provider_config(current_provider)
		if not provider_config.is_empty():
			provider.apply_configuration(provider_config)
	if provider == null:
		last_prompt_metrics["mode"] = "error"
		last_prompt_metrics["error"] = "No provider available"
		var provider_name = _provider_manager.get_current_provider_name()
		_debug_request_stage(
			"request_blocked",
			{
				"provider": provider_name,
				"reason": "provider_missing",
			},
		)
		_emit_error("AI provider is not available. Check configuration in settings.")
		_notify_callback_of_failure("AI provider is not available. Check configuration in settings.")
		return
	if not provider.is_configured():
		var reason := _get_provider_not_configured_message()
		last_prompt_metrics["mode"] = "error"
		last_prompt_metrics["error"] = "provider_not_configured"
		var provider_name = _provider_manager.get_current_provider_name()
		_debug_request_stage(
			"request_blocked",
			{
				"provider": provider_name,
				"reason": "provider_not_configured",
			},
		)
		_emit_error(reason)
		_notify_callback_of_failure(reason)
		return
	_is_requesting = true
	var timeout_seconds := _request_timeout
	if _config_manager and _config_manager.current_provider == AIProvider.GEMINI:
		var normalized_model := String(_config_manager.gemini_model).strip_edges().to_lower()
		if normalized_model.find("native-audio") != -1:
			timeout_seconds = max(timeout_seconds, LIVE_NATIVE_AUDIO_TIMEOUT)
	_timeout_timer.start(timeout_seconds)
	request_started.emit()
	_last_sent_messages = full_messages.duplicate(true)
	var provider_options := _build_provider_options()
	provider.send_request(
		full_messages,
		func(response):
			_handle_provider_response(response),
		provider_options,
	)
func _build_provider_options() -> Dictionary:
	if _active_request_payload.is_empty():
		return { }
	var options: Dictionary = { }
	var ctx_variant = _active_request_payload.get("context", null)
	if ctx_variant is Dictionary:
		var context: Dictionary = ctx_variant
		if context.has("structured_output") and context["structured_output"] is Dictionary:
			options["structured_output"] = (context["structured_output"] as Dictionary).duplicate(true)
		if context.has("response_mime_type") and not String(context["response_mime_type"]).strip_edges().is_empty():
			options["response_mime_type"] = String(context["response_mime_type"]).strip_edges()
		if context.has("response_schema") and context["response_schema"] is Dictionary:
			options["response_schema"] = (context["response_schema"] as Dictionary).duplicate(true)
	return options
func _get_provider_not_configured_message() -> String:
	if not _config_manager:
		return "The selected AI provider is not configured."
	match _config_manager.current_provider:
		AIProvider.GEMINI:
			return "Please set a Gemini API key in settings or enable mock mode."
		AIProvider.OPENROUTER:
			return "Please provide an OpenRouter API key in settings or enable mock mode."
		AIProvider.OLLAMA:
			return "Local Ollama provider is unavailable. Ensure the Ollama daemon and model are ready."
		_:
			return "The selected AI provider is not configured. Update API keys or connection settings."
func _should_use_mock(force_mock: bool) -> bool:
	if force_mock or _mock_override_enabled:
		return true
	if not _config_manager:
		return true
	match _config_manager.current_provider:
		AIProvider.GEMINI:
			if _config_manager.gemini_api_key.is_empty():
				return true
		AIProvider.OPENROUTER:
			if _config_manager.openrouter_api_key.is_empty():
				return true
	if _config_manager.gemini_api_key.is_empty() and _config_manager.openrouter_api_key.is_empty():
		return true
	return false
func _handle_provider_response(response: Dictionary) -> void:
	_is_requesting = false
	_timeout_timer.stop()
	var end_time_msec = Time.get_ticks_msec()
	if last_prompt_metrics.has("start_time_msec"):
		_last_response_time = (end_time_msec - last_prompt_metrics["start_time_msec"]) / 1000.0
		last_prompt_metrics["response_time_sec"] = _last_response_time
	if not response.get("success", false):
		var failure_message := str(response.get("error", "AI request failed"))
		if failure_message.strip_edges().is_empty():
			failure_message = "AI request failed"
		last_prompt_metrics["mode"] = "error"
		last_prompt_metrics["error"] = failure_message
		if _attempt_emergency_mock_fallback(failure_message, response):
			return
		_emit_error(failure_message)
		if not pending_callback.is_null():
			if pending_callback.is_valid():
				pending_callback.call({
					"success": false,
					"error": failure_message,
					"content": "",
					"status_code": response.get("status_code", 0)
				})
			pending_callback = Callable()
		request_completed.emit(false)
		_last_sent_messages.clear()
		_process_next_request()
		_clear_active_request_payload()
		return
	var ai_text := str(response.get("content", ""))
	if ai_text.is_empty():
		last_prompt_metrics["mode"] = "error"
		last_prompt_metrics["error"] = "Empty response"
		if _attempt_emergency_mock_fallback("AI Response Error: Empty response received", response):
			return
		_emit_error("AI Response Error: Empty response received")
		if not pending_callback.is_null():
			if pending_callback.is_valid():
				pending_callback.call({
					"success": false,
					"error": "Empty response",
					"content": "",
					"status_code": response.get("status_code", 200)
				})
			pending_callback = Callable()
		request_completed.emit(false)
		_last_sent_messages.clear()
		_process_next_request()
		_clear_active_request_payload()
		return
	last_prompt_metrics["response_chars"] = ai_text.length()
	last_prompt_metrics["response_tokens_est"] = _estimate_tokens(ai_text.length())
	last_prompt_metrics["response_preview"] = ai_text.left(1200)
	last_prompt_metrics["response_received_at"] = Time.get_datetime_string_from_system()
	var input_tokens = 0
	var output_tokens = 0
	var is_estimated = true
	if response.has("input_tokens") and response.has("output_tokens"):
		input_tokens = int(response["input_tokens"])
		output_tokens = int(response["output_tokens"])
		is_estimated = false
	elif response.has("input_tokens"): 
		input_tokens = int(response["input_tokens"])
		output_tokens = int(response.get("output_tokens", 0))
		is_estimated = false
	else:
		input_tokens = int(last_prompt_metrics.get("prompt_tokens_est", 0))
		output_tokens = _estimate_tokens(ai_text.length())
	var tps: float = 0.0
	if _last_response_time > 0:
		tps = float(output_tokens) / _last_response_time
	last_prompt_metrics["input_tokens"] = input_tokens
	last_prompt_metrics["output_tokens"] = output_tokens
	last_prompt_metrics["total_tokens"] = input_tokens + output_tokens
	last_prompt_metrics["is_estimated"] = is_estimated
	last_prompt_metrics["tps"] = tps
	_last_input_tokens = input_tokens
	_last_output_tokens = output_tokens
	_total_tokens_consumed += input_tokens + output_tokens
	_response_time_history.append(_last_response_time)
	_token_usage_history.append(input_tokens + output_tokens)
	_enforce_history_size()
	_total_api_calls += 1
	if _context_manager:
		var extra_data = {}
		if response.has("thought_signature"):
			extra_data["thought_signature"] = response["thought_signature"]
		_context_manager.add_to_memory("assistant", ai_text, extra_data)
		last_prompt_metrics["memory_entries_after"] = _context_manager.memory_store.story_memory.size()
	if response.has("audio_payloads") and response["audio_payloads"].size() > 0:
		if _voice_manager:
			_voice_manager.process_voice_payloads(response["audio_payloads"])
	var final_response = {
		"success": true,
		"content": ai_text,
		"error": "",
	}
	var response_context: Dictionary = { }
	if not _active_request_payload.is_empty():
		var ctx_variant = _active_request_payload.get("context", null)
		if ctx_variant is Dictionary:
			response_context = (ctx_variant as Dictionary).duplicate(true)
			if not response_context.is_empty():
				final_response["context"] = response_context
				var derived_type := _derive_response_type_from_context(response_context)
				if not derived_type.is_empty():
					final_response["type"] = derived_type
	else:
		if not response.get("fallback_used", false):
			print("[AIRequestManager] Warning: Active request payload empty during response handling. Context may be lost.")
	if response.has("metadata") and response["metadata"] is Dictionary:
		final_response["metadata"] = (response["metadata"] as Dictionary).duplicate(true)
	_retry_count = 0
	_clear_active_request_payload()
	_emit_safety_checked_response(final_response)
	request_completed.emit(true)
	if not _is_requesting:
		_last_sent_messages.clear()
	print("[AIRequestManager] AI request successfully completed. Response length: ", ai_text.length())
	_process_next_request()
func _attempt_emergency_mock_fallback(error_message: String, response: Dictionary) -> bool:
	if _active_request_payload.is_empty():
		return false
	if not _should_trigger_fallback(error_message, response):
		return false
	var prompt: String = str(_active_request_payload.get("prompt", ""))
	if prompt.is_empty():
		return false
	var context: Dictionary = {}
	if _active_request_payload.has("context") and _active_request_payload["context"] is Dictionary:
		context = (_active_request_payload["context"] as Dictionary).duplicate(true)
	var fallback_text: String = MockAIGeneratorScript.generate_response(prompt, context)
	if fallback_text.is_empty():
		return false
	var status_code := int(response.get("status_code", 0))
	var notice := _format_fallback_notice(error_message, status_code)
	last_prompt_metrics["mode"] = "mock_fallback"
	last_prompt_metrics["fallback_reason"] = notice
	last_prompt_metrics["response_chars"] = fallback_text.length()
	last_prompt_metrics["response_tokens_est"] = _estimate_tokens(fallback_text.length())
	if _context_manager:
		_context_manager.add_to_memory("assistant", fallback_text)
		last_prompt_metrics["memory_entries_after"] = _context_manager.memory_store.story_memory.size()
	var fallback_response := {
		"success": true,
		"content": fallback_text,
		"error": "",
		"fallback_used": true,
		"fallback_notice": notice,
		"original_error": error_message,
	}
	_emit_error(notice)
	_emit_safety_checked_response(fallback_response)
	request_completed.emit(true)
	_last_sent_messages.clear()
	_clear_active_request_payload()
	print("[AIRequestManager] Fallback mock response emitted after provider failure: %s" % notice)
	return true
func _should_trigger_fallback(error_message: String, response: Dictionary) -> bool:
	if _active_request_payload.get("force_mock", false):
		return false
	var status_code := int(response.get("status_code", 0))
	if bool(response.get("recoverable", status_code >= 500 or status_code == 429)):
		return true
	if status_code >= 500 or status_code == 429:
		return true
	var lowered := error_message.to_lower()
	if lowered.find("network error") != -1:
		return true
	if lowered.find("http 5") != -1:
		return true
	if lowered.find("timeout") != -1:
		return true
	return false
func _format_fallback_notice(error_message: String, status_code: int) -> String:
	var lang := _resolve_current_language()
	var status_label := ""
	if status_code > 0:
		status_label = "HTTP %d" % status_code
	var base_message := error_message
	if not status_label.is_empty() and base_message.find(status_label) == -1:
		base_message += " (%s)" % status_label
	if lang == "zh":
		return "%s。改用離線劇情產生器。" % base_message
	return "%s. Using offline story generator." % base_message
func _clear_active_request_payload() -> void:
	_active_request_payload = { }
	_active_provider_name = ""
func _derive_response_type_from_context(context: Dictionary) -> String:
	if context.is_empty():
		return ""
	var purpose := String(context.get("purpose", context.get("type", ""))).to_lower()
	match purpose:
		"mission", "new_mission", "story":
			return "mission"
		"consequence":
			return "consequence"
		"teammate_interference", "interference":
			return "teammate_interference"
		"gloria_intervention":
			return "gloria_intervention"
		"prayer_consequence", "prayer_result":
			return "prayer_consequence"
		"trolley_problem":
			return "trolley_problem"
		"night_cycle":
			return "night_cycle"
		_:
			return ""
func get_active_request_metadata() -> Dictionary:
	return _build_active_request_metadata()
func _build_active_request_metadata() -> Dictionary:
	var metadata := {
		"mock_override_enabled": _mock_override_enabled,
	}
	if not _mock_override_reason.is_empty():
		metadata["mock_override_reason"] = _mock_override_reason
	if _active_request_payload.is_empty():
		return metadata
	metadata["force_mock"] = bool(_active_request_payload.get("force_mock", false))
	if not _active_provider_name.is_empty():
		metadata["provider"] = _active_provider_name
	var ctx_variant = _active_request_payload.get("context", null)
	if ctx_variant is Dictionary:
		var ctx_copy: Dictionary = (ctx_variant as Dictionary).duplicate(true)
		metadata["context"] = ctx_copy
		var purpose := _extract_purpose_from_context(ctx_copy)
		if not purpose.is_empty():
			metadata["purpose"] = purpose
	return metadata
func set_mock_override(enabled: bool, reason: String = "") -> void:
	_mock_override_enabled = enabled
	_mock_override_reason = reason if enabled else ""
	var state_label := "enabled" if enabled else "cleared"
	var details := ""
	if enabled and not _mock_override_reason.is_empty():
		details = " (%s)" % _mock_override_reason
	print("[AIRequestManager] Mock override %s%s" % [state_label, details])
func is_mock_override_enabled() -> bool:
	return _mock_override_enabled
func _extract_purpose_from_context(context: Dictionary) -> String:
	return String(context.get("purpose", context.get("type", ""))).to_lower()
func _resolve_current_language() -> String:
	if EventBus:
		var response = EventBus.request(AIEventChannels.CURRENT_LANGUAGE_REQUEST)
		if response is String:
			var lang: String = response
			if not lang.is_empty():
				return lang
	return "en"
func _fetch_recent_assets_metadata() -> Array:
	if EventBus:
		var response = EventBus.request(AIEventChannels.RECENT_ASSETS_REQUEST)
		if response is Array:
			return (response as Array).duplicate(true)
	return []
func _validate_prompt(normalized_prompt: String) -> Dictionary:
	var prompt_length := normalized_prompt.length()
	if prompt_length < GameConstants.AI.PROMPT_MIN_LENGTH:
		return {
			"message": "AI prompt cannot be empty.",
			"code": "prompt_empty",
			"details": { "length": prompt_length },
		}
	if prompt_length > GameConstants.AI.PROMPT_MAX_LENGTH:
		return {
			"message": "AI prompt exceeds %d characters." % GameConstants.AI.PROMPT_MAX_LENGTH,
			"code": "prompt_too_long",
			"details": {
				"length": prompt_length,
				"max_length": GameConstants.AI.PROMPT_MAX_LENGTH,
			},
		}
	if _contains_forbidden_prompt_chars(normalized_prompt):
		return {
			"message": "AI prompt contains unsupported control characters.",
			"code": "prompt_illegal_characters",
		}
	return { }
func _contains_forbidden_prompt_chars(text: String) -> bool:
	if _prompt_guard_regex == null:
		_prompt_guard_regex = RegEx.new()
		var compile_result := _prompt_guard_regex.compile(GameConstants.AI.PROMPT_FORBIDDEN_PATTERN)
		if compile_result != OK:
			return false
	return _prompt_guard_regex.search(text) != null
func _handle_invalid_prompt(validation_issue: Dictionary, callback: Callable) -> void:
	if last_prompt_metrics.is_empty():
		last_prompt_metrics = { }
	last_prompt_metrics["mode"] = "error"
	last_prompt_metrics["error"] = validation_issue.get("code", "invalid_prompt")
	var error_message: String = validation_issue.get("message", "Invalid AI prompt.")
	var issue_details: Dictionary = { }
	var details_variant: Variant = validation_issue.get("details", { })
	if details_variant is Dictionary:
		issue_details = details_variant
	ErrorReporterBridge.report_error(
		ERROR_CONTEXT,
		error_message,
		ErrorCodes.AI.INVALID_PROMPT,
		false,
		issue_details,
	)
	_emit_error(error_message)
	request_completed.emit(false)
	if not callback.is_null():
		if callback.is_valid():
			callback.call(
				{
					"success": false,
					"content": "",
					"error": "invalid_prompt",
					"message": error_message,
				},
			)
func _on_request_timeout() -> void:
	if not _is_requesting:
		return
	var provider_name = _provider_manager.get_current_provider_name() if _provider_manager else "UNKNOWN"
	_debug_request_stage(
		"request_timeout",
		{
			"provider": provider_name,
			"retry": _retry_count + 1,
			"retry_cap": _max_retries,
		},
	)
	_is_requesting = false
	var provider = _provider_manager.get_current_provider() if _provider_manager else null
	if provider and provider.has_method("cancel_request"):
		provider.cancel_request()
	else:
		http_request.cancel_request()
	if _retry_count < _max_retries and not _last_sent_messages.is_empty():
		_retry_count += 1
		var retry_msg = "Request timeout. Retrying... (%d/%d)"
		_emit_error(retry_msg % [_retry_count, _max_retries])
		_retry_last_request()
		return
	var error_msg = "Request failed after %d/%d retries. Please check your connection."
	if last_prompt_metrics.is_empty():
		last_prompt_metrics = { }
	last_prompt_metrics["mode"] = "error"
	last_prompt_metrics["error"] = "timeout"
	_emit_error(error_msg % [max(1, _retry_count), _max_retries])
	if not pending_callback.is_null():
		if pending_callback.is_valid():
			pending_callback.call({
				"success": false,
				"error": "Request timed out after %d retries" % max(1, _retry_count),
				"content": "",
			})
		pending_callback = Callable()
	request_completed.emit(false)
	_last_sent_messages.clear()
	_process_next_request()
	_clear_active_request_payload()
	_retry_count = 0
func _retry_last_request() -> void:
	if _last_sent_messages.is_empty():
		_process_next_request()
		return
	var provider = _provider_manager.get_current_provider() if _provider_manager else null
	if provider == null or not provider.is_configured():
		_process_next_request()
		return
	_timeout_timer.start(_request_timeout)
	_is_requesting = true
	var provider_options := _build_provider_options()
	provider.send_request(
		_last_sent_messages,
		func(response):
			_handle_provider_response(response),
		provider_options,
	)
func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_timeout_timer.stop()
	_is_requesting = false
	var provider_name = _provider_manager.get_current_provider_name() if _provider_manager else "UNKNOWN"
	_debug_request_stage(
		"http_request_completed",
		{
			"provider": provider_name,
			"result": result,
			"status": response_code,
			"bytes": body.size(),
		},
	)
	var end_time_msec := Time.get_ticks_msec()
	if last_prompt_metrics.has("start_time_msec"):
		_last_response_time = (end_time_msec - int(last_prompt_metrics["start_time_msec"])) / 1000.0
		last_prompt_metrics["response_time_sec"] = _last_response_time
	var provider = _provider_manager.get_current_provider() if _provider_manager else null
	if provider == null:
		_emit_error("No provider available to parse HTTP response.")
		request_completed.emit(false)
		_process_next_request()
		return
	var parsed_variant: Variant = provider.parse_response(result, response_code, body)
	if not parsed_variant is Dictionary:
		_emit_error("Provider returned unexpected response format.")
		request_completed.emit(false)
		_last_sent_messages.clear()
		_process_next_request()
		return
	var parsed: Dictionary = parsed_variant
	if not parsed.get("success", false):
		if last_prompt_metrics.is_empty():
			last_prompt_metrics = { }
		last_prompt_metrics["mode"] = "error"
		last_prompt_metrics["error"] = parsed.get("error", "HTTP error")
		_emit_error(parsed.get("error", "AI request failed"))
		request_completed.emit(false)
		_last_sent_messages.clear()
		_process_next_request()
		return
	_handle_provider_response(parsed)
func _queue_request(prompt: String, callback: Callable, context: Dictionary, force_mock: bool) -> void:
	if _request_queue == null:
		return
	var provider_name = _provider_manager.get_current_provider_name() if _provider_manager else "UNKNOWN"
	_request_queue.enqueue(
		prompt,
		callback,
		context,
		force_mock,
		provider_name,
	)
func _process_next_request() -> void:
	if _request_queue == null or _request_queue.is_empty():
		return
	if _is_requesting:
		return
	if http_request:
		var status := http_request.get_http_client_status()
		if status != HTTPClient.STATUS_DISCONNECTED:
			call_deferred("_process_next_request")
			return
	var provider_name = _provider_manager.get_current_provider_name() if _provider_manager else "UNKNOWN"
	var next_entry: Dictionary = _request_queue.take_next(provider_name)
	if next_entry.is_empty():
		return
	call_deferred("_execute_queued_request", next_entry)
func _execute_queued_request(entry: Dictionary) -> void:
	if entry.is_empty():
		_process_next_request()
		return
	var prompt: String = str(entry.get("prompt", ""))
	var callback: Callable = entry.get("callback", Callable())
	var context_dict: Dictionary = { }
	if entry.has("context") and entry["context"] is Dictionary:
		context_dict = (entry["context"] as Dictionary).duplicate(true)
	var force_mock := bool(entry.get("force_mock", false))
	var options: Dictionary = { }
	if not context_dict.is_empty():
		options["context"] = context_dict
	if force_mock:
		options["force_mock"] = true
	if options.is_empty():
		request_ai(prompt, callback)
	else:
		request_ai(prompt, callback, options)
func _is_rate_limited(_force_mock: bool) -> bool:
	if _rate_limiter == null:
		return false
	var attempt: Dictionary = _rate_limiter.attempt()
	if attempt.get("allowed", false):
		return false
	var retry_after := int(attempt.get("retry_after_msec", RATE_LIMIT_COOLDOWN_MSEC))
	_emit_rate_limit_error(retry_after)
	return true
func _emit_rate_limit_error(remaining_msec: int) -> void:
	var seconds := int(ceil(max(0.0, float(remaining_msec)) / 1000.0))
	if seconds <= 0:
		seconds = 1
	var message := "Too many AI requests. Please wait %d seconds before trying again." % seconds
	if last_prompt_metrics.is_empty():
		last_prompt_metrics = { }
	last_prompt_metrics["mode"] = "blocked"
	last_prompt_metrics["error"] = "rate_limited"
	last_prompt_metrics["rate_limit_retry_after_sec"] = seconds
	_emit_error(message)
	var response := {
		"success": false,
		"content": "",
		"error": "rate_limited",
		"retry_after_sec": seconds,
	}
	_emit_safety_checked_response(response, false)
func _emit_safety_checked_response(response: Dictionary, notify_callback: bool = true) -> void:
	var processed := _apply_safety_review(response)
	response_received.emit(processed)
	if notify_callback and not pending_callback.is_null():
		var callback_to_execute = pending_callback
		pending_callback = Callable()
		if callback_to_execute.is_valid():
			callback_to_execute.call(processed)
		else:
			ErrorReporterBridge.report_warning(
				ERROR_CONTEXT,
				"Skipping AI callback; target was freed before the response arrived",
			)
	elif not notify_callback:
		pending_callback = Callable()
		_process_next_request()
func _apply_safety_review(response: Dictionary) -> Dictionary:
	var processed := response.duplicate(true)
	if not processed.has("content"):
		return processed
	var review: Dictionary = AISafetyFilter.review_response_content(processed.get("content", ""))
	if review.is_empty():
		return processed
	processed["content"] = review.get("content", processed.get("content", ""))
	if review.get("flagged", false):
		var issues: Array = review.get("issues", [])
		if issues.size() > 0:
			processed["safety_flagged"] = issues.duplicate()
			if last_prompt_metrics.is_empty():
				last_prompt_metrics = { }
			last_prompt_metrics["safety_flagged"] = issues.duplicate()
			ErrorReporterBridge.report_warning(
				"AI Safety",
				"Response flagged: %s" % issues,
				{ "issues": issues },
			)
	var redactions: Array = review.get("redactions", [])
	if redactions.size() > 0:
		processed["safety_redactions"] = redactions.duplicate()
		if last_prompt_metrics.is_empty():
			last_prompt_metrics = { }
		last_prompt_metrics["output_redactions"] = redactions.duplicate()
	if review.get("requires_block", false):
		processed["success"] = false
		processed["error"] = review.get("error_message", "Response blocked by safety filter.")
	return processed
func _emit_error(message: String) -> void:
	request_error.emit(message)
func _notify_callback_of_failure(error_message: String) -> void:
	if not pending_callback.is_null():
		if pending_callback.is_valid():
			pending_callback.call({
				"success": false,
				"error": error_message,
				"content": "",
			})
		pending_callback = Callable()
func _record_prompt_metrics(full_prompt_messages: Array, raw_prompt: String, context: Dictionary, force_mock: bool) -> void:
	var prompt_text: String = _serialize_prompt_messages(full_prompt_messages)
	var story_size: int = _context_manager.memory_store.story_memory.size() if _context_manager else 0
	var memory_full_entries = _context_manager.memory_store.memory_full_entries if _context_manager else 0
	var full_entries: int = min(memory_full_entries, story_size)
	var metrics: Dictionary = {
		"prompt_chars": prompt_text.length(),
		"prompt_tokens_est": _estimate_tokens(prompt_text.length()),
		"raw_prompt_chars": raw_prompt.length(),
		"memory_entries_before": story_size,
		"full_entries_used": full_entries,
		"summary_entries": max(0, story_size - full_entries),
		"memory_limit": _context_manager.memory_store.max_memory_items if _context_manager else 0,
		"summary_threshold": _context_manager.memory_store.memory_summary_threshold if _context_manager else 0,
		"context_keys": context.keys(),
		"timestamp": Time.get_datetime_string_from_system(),
		"force_mock_requested": force_mock,
		"mock_override_enabled": _mock_override_enabled,
		"assets": _fetch_recent_assets_metadata(),
	}
	last_prompt_metrics = metrics
func _serialize_prompt_messages(messages: Array) -> String:
	var parts: Array[String] = []
	for message in messages:
		if message is Dictionary:
			var msg: Dictionary = message
			var role = str(msg.get("role", ""))
			var content = str(msg.get("content", ""))
			parts.append("[%s] %s" % [role, content])
		else:
			parts.append(str(message))
	return "\n".join(parts)
static func _estimate_tokens(char_count: int) -> int:
	return int(ceil(float(char_count) / 4.0))
func _enforce_history_size():
	while _response_time_history.size() > MAX_HISTORY_SIZE:
		_response_time_history.remove_at(0)
	while _token_usage_history.size() > MAX_HISTORY_SIZE:
		_token_usage_history.remove_at(0)
func _debug_request_stage(stage: String, payload: Dictionary) -> void:
	var details := payload.duplicate(true)
	details["stage"] = stage
	details["timestamp"] = Time.get_datetime_string_from_system()
	print("[AIRequestManager] %s" % JSON.stringify(details))
func get_ai_metrics() -> Dictionary:
	return {
		"total_requests": _total_api_calls,
		"total_tokens": _total_tokens_consumed,
		"last_response_time": _last_response_time,
		"last_input_tokens": _last_input_tokens,
		"last_output_tokens": _last_output_tokens,
		"is_requesting": _is_requesting,
	}
func get_prompt_metrics() -> Dictionary:
	if last_prompt_metrics.is_empty():
		return { }
	return last_prompt_metrics.duplicate(true)
func get_response_time_history() -> Array:
	return _response_time_history.duplicate()
func get_token_usage_history() -> Array:
	return _token_usage_history.duplicate()
func is_requesting() -> bool:
	return _is_requesting
func reset_metrics() -> void:
	last_prompt_metrics = { }
	_total_api_calls = 0
	_total_tokens_consumed = 0
	_last_response_time = 0.0
	_last_input_tokens = 0
	_last_output_tokens = 0
	_response_time_history.clear()
	_token_usage_history.clear()
