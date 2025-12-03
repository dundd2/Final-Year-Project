extends Node
signal ai_request_started()
signal ai_request_progress(update: Dictionary)
signal ai_request_completed(success: bool)
signal ai_response_received(response: Dictionary)
signal ai_error(message: String)
signal ai_system_message(message: String)
signal voice_capability_changed(supported: bool)
signal voice_input_buffer_ready(pcm: PackedByteArray, sample_rate: int, metadata: Dictionary)
signal voice_transcription_ready(text: String, metadata: Dictionary)
signal voice_transcription_failed(reason: String)
signal voice_audio_received(payload: Dictionary)
const AIProvider := AIConfigManager.AIProvider
enum VoiceInputMode {
	PUSH_TO_TALK,
	CONTINUOUS,
}
const SceneDirectivesParser = preload("res://1.Codebase/src/scripts/core/ai/scene_directives_parser.gd")
const LiveAPIClient = preload("res://1.Codebase/src/scripts/core/live_api_client.gd")
const AIEventChannels = preload("res://1.Codebase/src/scripts/core/ai/ai_event_channels.gd")
var _config_manager: AIConfigManager = null
var _provider_manager: AIProviderManager = null
var _voice_manager: AIVoiceManager = null
var _context_manager: AIContextManager = null
var _request_manager: AIRequestManager = null
var http_request: HTTPRequest = null
var live_api_client: Node = null
var _scene_directives_parser: SceneDirectivesParser = null
var current_provider:
	get:
		return _config_manager.current_provider if _config_manager else AIProvider.GEMINI
	set(value):
		if _config_manager: _config_manager.current_provider = value
var gemini_api_key: String:
	get:
		return _config_manager.gemini_api_key if _config_manager else ""
	set(value):
		if _config_manager: _config_manager.gemini_api_key = value
var gemini_access_token: String:
	get:
		return _config_manager.gemini_access_token if _config_manager else ""
	set(value):
		if _config_manager: _config_manager.gemini_access_token = value
var gemini_project_id: String:
	get:
		return _config_manager.gemini_project_id if _config_manager else ""
	set(value):
		if _config_manager: _config_manager.gemini_project_id = value
var gemini_location: String:
	get:
		return _config_manager.gemini_location if _config_manager else ""
	set(value):
		if _config_manager: _config_manager.gemini_location = value
var gemini_model: String:
	get:
		return _config_manager.gemini_model if _config_manager else "gemini-2.5-flash"
	set(value):
		if _config_manager: _config_manager.gemini_model = value
var gemini_allow_web_requests: bool:
	get:
		return _config_manager.gemini_allow_web_requests if _config_manager else true
	set(value):
		if _config_manager: _config_manager.gemini_allow_web_requests = value
var gemini_safety_settings: String:
	get:
		return _config_manager.gemini_safety_settings if _config_manager else "BLOCK_NONE"
	set(value):
		if _config_manager: _config_manager.gemini_safety_settings = value
var openrouter_api_key: String:
	get:
		return _config_manager.openrouter_api_key if _config_manager else ""
	set(value):
		if _config_manager: _config_manager.openrouter_api_key = value
var openrouter_model: String:
	get:
		return _config_manager.openrouter_model if _config_manager else "google/gemini-pro"
	set(value):
		if _config_manager: _config_manager.openrouter_model = value
var ollama_host: String:
	get:
		return _config_manager.ollama_host if _config_manager else "127.0.0.1"
	set(value):
		if _config_manager: _config_manager.ollama_host = value
var ollama_port: int:
	get:
		return _config_manager.ollama_port if _config_manager else 11434
	set(value):
		if _config_manager: _config_manager.ollama_port = value
var ollama_model: String:
	get:
		return _config_manager.ollama_model if _config_manager else "gemma3:1b"
	set(value):
		if _config_manager: _config_manager.ollama_model = value
var ollama_use_chat: bool:
	get:
		return _config_manager.ollama_use_chat if _config_manager else true
	set(value):
		if _config_manager: _config_manager.ollama_use_chat = value
var ollama_options: Dictionary:
	get:
		return _config_manager.ollama_options if _config_manager else { }
	set(value):
		if _config_manager: _config_manager.ollama_options = value
var custom_ai_tone_style: String:
	get:
		return _config_manager.custom_ai_tone_style if _config_manager else ""
	set(value):
		if _config_manager: _config_manager.custom_ai_tone_style = value
var pending_callback: Callable:
	get:
		return _request_manager.pending_callback if _request_manager else Callable()
	set(value):
		if _request_manager: _request_manager.pending_callback = value
var last_prompt_metrics: Dictionary:
	get:
		return _request_manager.last_prompt_metrics if _request_manager else { }
	set(value):
		if _request_manager: _request_manager.last_prompt_metrics = value
var memory_store: RefCounted:
	get:
		return _context_manager.memory_store if _context_manager else null
var voice_session: Node:
	get:
		return _voice_manager.voice_session if _voice_manager else null
func _ready() -> void:
	print("[AIManager] Initializing AI Manager Facade...")
	process_mode = Node.PROCESS_MODE_ALWAYS
	http_request = HTTPRequest.new()
	http_request.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(http_request)
	live_api_client = LiveAPIClient.new()
	live_api_client.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(live_api_client)
	_scene_directives_parser = SceneDirectivesParser.new()
	_initialize_managers()
	load_ai_settings()
	apply_memory_settings()
	refresh_voice_capabilities()
	_subscribe_to_event_bus_contracts()
	print("[AIManager] AI Manager Facade initialized successfully")
func _initialize_managers() -> void:
	_config_manager = AIConfigManager.new()
	var AIProviderManagerScript = preload("res://1.Codebase/src/scripts/core/ai/managers/ai_provider_manager.gd")
	_provider_manager = AIProviderManagerScript.new()
	_provider_manager.set_config_manager(_config_manager)
	var ollama_client = ServiceLocator.get_service("OllamaClient") if ServiceLocator else null
	_provider_manager.initialize_providers(http_request, live_api_client, null, ollama_client)
	_provider_manager.provider_request_completed.connect(_on_provider_request_completed)
	_provider_manager.provider_request_error.connect(_on_provider_request_error)
	_provider_manager.provider_request_progress.connect(_on_provider_request_progress)
	var AIVoiceManagerScript = preload("res://1.Codebase/src/scripts/core/ai/managers/ai_voice_manager.gd")
	_voice_manager = AIVoiceManagerScript.new()
	_voice_manager.set_config_manager(_config_manager)
	_voice_manager.set_provider_manager(_provider_manager)
	_voice_manager.initialize_voice_system(self)
	var voice_session_instance = _voice_manager.get_voice_session()
	var gemini_provider = _provider_manager.get_provider_instance(AIProvider.GEMINI)
	if gemini_provider:
		gemini_provider.voice_session = voice_session_instance
	_voice_manager.voice_capability_changed.connect(func(supported): voice_capability_changed.emit(supported))
	_voice_manager.voice_input_buffer_ready.connect(func(pcm, sr, meta): voice_input_buffer_ready.emit(pcm, sr, meta))
	_voice_manager.voice_transcription_ready.connect(func(text, meta): voice_transcription_ready.emit(text, meta))
	_voice_manager.voice_transcription_failed.connect(func(reason): voice_transcription_failed.emit(reason))
	_voice_manager.voice_audio_received.connect(func(payload): voice_audio_received.emit(payload))
	var AIContextManagerScript = preload("res://1.Codebase/src/scripts/core/ai/managers/ai_context_manager.gd")
	_context_manager = AIContextManagerScript.new()
	_context_manager.set_config_manager(_config_manager)
	_context_manager.set_voice_manager(_voice_manager)
	_context_manager.initialize_context_system(ServiceLocator)
	_context_manager.set_system_persona(_config_manager.get_ai_system_persona())
	var AIRequestManagerScript = preload("res://1.Codebase/src/scripts/core/ai/managers/ai_request_manager.gd")
	_request_manager = AIRequestManagerScript.new()
	_request_manager.set_config_manager(_config_manager)
	_request_manager.set_provider_manager(_provider_manager)
	_request_manager.set_context_manager(_context_manager)
	_request_manager.set_voice_manager(_voice_manager)
	_request_manager.initialize_request_system(self, http_request)
	_request_manager.request_started.connect(
		func():
			ai_request_started.emit()
			var payload := {
				"timestamp": Time.get_ticks_msec(),
			}
			_attach_request_metadata(payload)
			EventBus.publish("ai_request_started", payload)
	)
	_request_manager.request_progress.connect(
		func(update):
			var enriched: Dictionary = update.duplicate(true)
			_attach_request_metadata(enriched)
			ai_request_progress.emit(enriched)
			EventBus.publish("ai_request_progress", enriched)
	)
	_request_manager.request_completed.connect(
		func(success):
			ai_request_completed.emit(success)
			var payload := {
				"success": success,
				"timestamp": Time.get_ticks_msec(),
			}
			_attach_request_metadata(payload)
			EventBus.publish("ai_request_completed", payload)
	)
	_request_manager.request_error.connect(
		func(message):
			ai_error.emit(message)
			var payload := {
				"message": message,
				"timestamp": Time.get_ticks_msec(),
			}
			_attach_request_metadata(payload)
			EventBus.publish("ai_error", payload)
	)
	_request_manager.response_received.connect(
		func(response):
			ai_response_received.emit(response)
			EventBus.publish("ai_response_received", response)
	)
	print("[AIManager] All sub-managers initialized and wired")
func _on_provider_request_completed(success: bool) -> void:
	ai_request_completed.emit(success)
func _on_provider_request_error(message: String) -> void:
	ai_error.emit(message)
func _on_provider_request_progress(update: Dictionary) -> void:
	var payload: Dictionary = update.duplicate(true)
	_attach_request_metadata(payload)
	ai_request_progress.emit(payload)
	EventBus.publish("ai_request_progress", payload)
func _attach_request_metadata(payload: Dictionary) -> void:
	if not _request_manager:
		return
	var metadata: Dictionary = _request_manager.get_active_request_metadata()
	if metadata.is_empty():
		return
	for key in metadata.keys():
		payload[key] = metadata[key]
func _subscribe_to_event_bus_contracts() -> void:
	if not EventBus:
		ErrorReporterBridge.report_warning("AIManager", "EventBus unavailable; AI contracts not registered")
		return
	EventBus.subscribe(AIEventChannels.REGISTER_NOTE_PAIR, self, "_on_event_ai_register_note_pair")
	EventBus.subscribe(AIEventChannels.STATE_SNAPSHOT_REQUEST, self, "_on_event_ai_state_snapshot_request")
	EventBus.subscribe(AIEventChannels.LOAD_STATE_SNAPSHOT, self, "_on_event_ai_load_state_snapshot")
	EventBus.subscribe(AIEventChannels.CLEAR_MEMORY, self, "_on_event_ai_clear_memory")
func request_ai(prompt: String, callback: Callable = Callable(), context_or_callback = null) -> void:
	if not _request_manager:
		ErrorReporterBridge.report_error("AIManager", "Request manager not initialized; cannot process AI request")
		return
	_request_manager.request_ai(prompt, callback, context_or_callback)
func generate_story(prompt: String, context_or_callback = null, callback: Callable = Callable()) -> void:
	if callback is Callable:
		request_ai(prompt, callback, context_or_callback)
	else:
		if context_or_callback is Callable:
			request_ai(prompt, context_or_callback)
		else:
			request_ai(prompt, Callable(), context_or_callback)
func set_mock_override(enabled: bool, reason: String = "") -> void:
	if _request_manager:
		_request_manager.set_mock_override(enabled, reason)
func is_mock_override_enabled() -> bool:
	if _request_manager:
		return _request_manager.is_mock_override_enabled()
	return false
func save_ai_settings() -> void:
	if _config_manager:
		_config_manager.save_settings()
func load_ai_settings() -> void:
	if _config_manager:
		_config_manager.load_settings()
	if _provider_manager:
		_provider_manager.sync_all_providers()
	if _voice_manager:
		_voice_manager.sync_voice_flags_from_settings_file()
func refresh_voice_capabilities() -> void:
	if _voice_manager:
		_voice_manager.refresh_capabilities()
func is_native_voice_supported() -> bool:
	if _voice_manager:
		return _voice_manager.is_native_voice_supported()
	return false
func get_voice_settings() -> Dictionary:
	if _voice_manager:
		return _voice_manager.get_voice_settings()
	return { }
func apply_voice_settings(settings: Dictionary) -> void:
	if _voice_manager:
		_voice_manager.apply_voice_settings(settings)
func queue_voice_input(pcm_bytes: PackedByteArray, sample_rate: int = GameConstants.AI.DEFAULT_INPUT_SAMPLE_RATE, mime_type: String = "") -> void:
	if _voice_manager:
		_voice_manager.queue_voice_input(pcm_bytes, sample_rate, mime_type)
func has_pending_voice_input() -> bool:
	if _voice_manager:
		return _voice_manager.has_pending_voice_input()
	return false
func clear_pending_voice_input() -> void:
	if _voice_manager:
		_voice_manager.clear_pending_voice_input()
func request_voice_capture(duration_seconds: float = 4.0) -> void:
	if _voice_manager:
		_voice_manager.request_voice_capture(duration_seconds)
func cancel_voice_capture() -> void:
	if _voice_manager:
		_voice_manager.cancel_voice_capture()
func add_to_memory(role: String, content: String) -> void:
	if _context_manager:
		_context_manager.add_to_memory(role, content)
func register_note_pair(text_en: String, text_zh: String = "", tags: Array = [], importance: int = 1, source: String = "") -> void:
	if _context_manager:
		_context_manager.register_note_pair(text_en, text_zh, tags, importance, source)
func clear_notes() -> void:
	if _context_manager:
		_context_manager.clear_notes()
func summarize_memory() -> String:
	if _context_manager:
		return _context_manager.summarize_memory()
	return ""
func clear_memory() -> void:
	if _context_manager:
		_context_manager.clear_memory()
	if _request_manager:
		_request_manager.last_prompt_metrics = { }
func apply_memory_settings() -> void:
	if _context_manager:
		_context_manager.apply_memory_settings()
func get_long_term_summary_count() -> int:
	if _context_manager:
		return _context_manager.get_long_term_summary_count()
	return 0
func get_note_count() -> int:
	if _context_manager:
		return _context_manager.get_note_count()
	return 0
func get_long_term_lines(language: String, limit: int = 10) -> Array:
	if _context_manager and _context_manager.memory_store:
		return _context_manager.memory_store.get_long_term_lines(language, limit)
	return []
func get_notes_lines(language: String, limit: int = 20) -> Array:
	if _context_manager and _context_manager.memory_store:
		return _context_manager.memory_store.get_notes_lines(language, limit)
	return []
func is_ollama_ready(timeout_sec: float = 0.5) -> bool:
	if _provider_manager:
		return _provider_manager.is_ollama_ready(timeout_sec)
	return false
func get_ai_metrics() -> Dictionary:
	if _request_manager:
		return _request_manager.get_ai_metrics()
	return { }
func get_prompt_metrics() -> Dictionary:
	if _request_manager:
		return _request_manager.get_prompt_metrics()
	return { }
func get_response_time_history() -> Array:
	if _request_manager:
		return _request_manager.get_response_time_history()
	return []
func get_token_usage_history() -> Array:
	if _request_manager:
		return _request_manager.get_token_usage_history()
	return []
func get_state_snapshot() -> Dictionary:
	var snapshot: Dictionary = { }
	if _context_manager:
		snapshot.merge(_context_manager.get_memory_state())
	if _config_manager:
		snapshot.merge(_config_manager.get_state_snapshot())
	if _request_manager:
		snapshot["last_prompt_metrics"] = _request_manager.get_prompt_metrics()
	return snapshot
func load_state_snapshot(state: Dictionary) -> void:
	if _context_manager and state.has("story_memory"):
		_context_manager.load_memory_state(state)
	if _config_manager:
		_config_manager.load_state_snapshot(state)
	if _provider_manager:
		_provider_manager.sync_all_providers()
	apply_memory_settings()
func _on_event_ai_register_note_pair(payload: Variant) -> void:
	if not (payload is Dictionary):
		return
	var note_data: Dictionary = (payload as Dictionary).duplicate()
	var text_en := str(note_data.get("text_en", ""))
	var text_zh := str(note_data.get("text_zh", ""))
	var tags_variant = note_data.get("tags", [])
	var tags: Array = []
	if tags_variant is Array:
		tags = (tags_variant as Array).duplicate(false)
	var importance := int(note_data.get("importance", 1))
	var source := str(note_data.get("source", ""))
	register_note_pair(text_en, text_zh, tags, importance, source)
func _on_event_ai_state_snapshot_request(_data: Variant = null) -> Dictionary:
	return get_state_snapshot()
func _on_event_ai_load_state_snapshot(state: Variant) -> void:
	if state is Dictionary:
		load_state_snapshot(state)
func _on_event_ai_clear_memory(_data: Variant = null) -> void:
	clear_memory()
func parse_scene_directives(response_text: String) -> Dictionary:
	if _scene_directives_parser:
		return _scene_directives_parser.parse_directives(response_text)
	return { "success": false, "directives": [] }
func extract_story_content(response_text: String) -> String:
	if _scene_directives_parser:
		return _scene_directives_parser.extract_story_content(response_text)
	return response_text.strip_edges()
static func sanitize_user_text(raw_text: String, max_length: int = 256) -> String:
	return AIContextManager.sanitize_user_text(raw_text, max_length)
