extends RefCounted
class_name AIVoiceManager
const VoiceSessionManagerScript = preload("res://1.Codebase/src/scripts/core/ai/voice_session_manager.gd")
const AIVoiceBridgeScript = preload("res://1.Codebase/src/scripts/core/ai/voice_bridge.gd")
const ERROR_CONTEXT := "AIVoiceManager"
const GEMINI_NATIVE_AUDIO_MODELS := [
	"gemini-2.5-flash-native-audio-preview-12-2025",
]
const DEFAULT_INPUT_SAMPLE_RATE := GameConstants.AI.DEFAULT_INPUT_SAMPLE_RATE
const DEFAULT_OUTPUT_SAMPLE_RATE := GameConstants.AI.DEFAULT_OUTPUT_SAMPLE_RATE
enum AIProvider {
	GEMINI = 0,
	OPENROUTER = 1,
	OLLAMA = 2,
}
var _voice_bridge: Node = null
var voice_session: Node = null
var _config_manager: AIConfigManager = null
var _provider_manager = null 
signal voice_capability_changed(supported: bool)
signal voice_input_buffer_ready(pcm: PackedByteArray, sample_rate: int, metadata: Dictionary)
signal voice_transcription_ready(text: String, metadata: Dictionary)
signal voice_transcription_failed(reason: String)
signal voice_audio_received(payload: Dictionary)
func set_config_manager(config_mgr: AIConfigManager) -> void:
	_config_manager = config_mgr
func set_provider_manager(provider_mgr) -> void:
	_provider_manager = provider_mgr
func initialize_voice_system(parent_node: Node) -> void:
	_voice_bridge = AIVoiceBridgeScript.new()
	parent_node.add_child(_voice_bridge)
	_voice_bridge.setup(
		[0, 1], 
		0, 
		DEFAULT_INPUT_SAMPLE_RATE,
		DEFAULT_OUTPUT_SAMPLE_RATE,
	)
	if not _voice_bridge.capability_changed.is_connected(_on_voice_session_capability_changed):
		_voice_bridge.capability_changed.connect(_on_voice_session_capability_changed)
	if not _voice_bridge.input_ready.is_connected(_on_voice_session_input_ready):
		_voice_bridge.input_ready.connect(_on_voice_session_input_ready)
	if not _voice_bridge.transcription_ready.is_connected(_on_voice_session_transcription_ready):
		_voice_bridge.transcription_ready.connect(_on_voice_session_transcription_ready)
	if not _voice_bridge.transcription_failed.is_connected(_on_voice_session_transcription_failed):
		_voice_bridge.transcription_failed.connect(_on_voice_session_transcription_failed)
	if not _voice_bridge.audio_received.is_connected(_on_voice_session_audio_received):
		_voice_bridge.audio_received.connect(_on_voice_session_audio_received)
	voice_session = _voice_bridge.get_session()
	print("[AIVoiceManager] Voice system initialized")
func get_voice_session() -> Node:
	return voice_session
func refresh_capabilities() -> void:
	if _voice_bridge == null:
		return
	_voice_bridge.refresh_capabilities(Callable(self, "_evaluate_native_voice_support"))
func _evaluate_native_voice_support() -> bool:
	if not _provider_manager or not _config_manager:
		return false
	var current_provider = _config_manager.current_provider
	match current_provider:
		AIProvider.GEMINI:
			var normalized := _config_manager.gemini_model.strip_edges().to_lower()
			if normalized.is_empty():
				return false
			if GEMINI_NATIVE_AUDIO_MODELS.has(normalized):
				return true
			if normalized.find("native-audio") != -1:
				return true
			if normalized.find("native") != -1 and normalized.find("live") != -1:
				return true
			return false
		AIProvider.OPENROUTER:
			return false
		AIProvider.OLLAMA:
			return false
	return false
func is_native_voice_supported() -> bool:
	if _voice_bridge == null:
		return false
	return _voice_bridge.is_native_voice_supported()
func get_voice_settings() -> Dictionary:
	if _voice_bridge:
		return _voice_bridge.get_settings()
	return { }
func apply_voice_settings(settings: Dictionary) -> void:
	if _voice_bridge == null:
		return
	_voice_bridge.apply_settings(settings)
	_voice_bridge.update_native_support(_evaluate_native_voice_support())
func queue_voice_input(pcm_bytes: PackedByteArray, sample_rate: int = DEFAULT_INPUT_SAMPLE_RATE, mime_type: String = "") -> void:
	if _voice_bridge == null:
		return
	_voice_bridge.queue_voice_input(pcm_bytes, sample_rate, mime_type, DEFAULT_INPUT_SAMPLE_RATE)
func has_pending_voice_input() -> bool:
	if _voice_bridge == null:
		return false
	return _voice_bridge.has_pending_voice_input()
func clear_pending_voice_input() -> void:
	if _voice_bridge:
		_voice_bridge.clear_pending_voice_input()
func build_voice_inline_part() -> Dictionary:
	if _voice_bridge == null:
		return { }
	return _voice_bridge.build_inline_part(DEFAULT_INPUT_SAMPLE_RATE)
func request_voice_capture(duration_seconds: float = 4.0) -> void:
	if _voice_bridge == null:
		return
	if voice_session and not voice_session.wants_voice_input():
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Voice capture requested while native voice input is disabled",
		)
		return
	_voice_bridge.request_voice_capture(duration_seconds)
func cancel_voice_capture() -> void:
	if _voice_bridge:
		_voice_bridge.cancel_voice_capture()
func save_voice_config(config: ConfigFile) -> void:
	if _voice_bridge:
		_voice_bridge.write_config(config)
func load_voice_config(config: ConfigFile) -> void:
	if _voice_bridge:
		_voice_bridge.load_config(config)
func sync_voice_flags_from_settings_file() -> void:
	if _voice_bridge == null or voice_session == null:
		return
	var config := ConfigFile.new()
	if config.load(AIConfigManager.CONFIG_FILE_PATH) != OK:
		refresh_capabilities()
		return
	var overrides := {
		"prefer_native_audio": config.get_value("voice", "prefer_native_audio", voice_session.prefer_native_audio),
		"voice_output_enabled": config.get_value("voice", "voice_output_enabled", voice_session.voice_output_enabled),
		"voice_input_enabled": config.get_value("voice", "voice_input_enabled", voice_session.voice_input_enabled),
		"preferred_voice_name": config.get_value("voice", "preferred_voice_name", voice_session.preferred_voice_name),
		"voice_input_mode": config.get_value("voice", "voice_input_mode", voice_session.voice_input_mode),
		"proactive_audio_enabled": config.get_value("voice", "proactive_audio_enabled", voice_session.proactive_audio_enabled),
		"affective_dialog_enabled": config.get_value("voice", "affective_dialog_enabled", voice_session.affective_dialog_enabled),
	}
	_voice_bridge.apply_settings(overrides)
	refresh_capabilities()
func process_voice_payloads(audio_payloads: Array) -> void:
	if voice_session and voice_session.has_method("process_voice_payloads"):
		voice_session.process_voice_payloads(audio_payloads, DEFAULT_OUTPUT_SAMPLE_RATE)
func is_initialized() -> bool:
	return _voice_bridge != null and voice_session != null
func _on_voice_session_capability_changed(supported: bool) -> void:
	voice_capability_changed.emit(supported)
func _on_voice_session_input_ready(pcm: PackedByteArray, sample_rate: int, metadata: Dictionary) -> void:
	if pcm.is_empty():
		return
	voice_input_buffer_ready.emit(pcm, sample_rate, metadata)
func _on_voice_session_transcription_ready(text: String, metadata: Dictionary) -> void:
	voice_transcription_ready.emit(text, metadata)
func _on_voice_session_transcription_failed(reason: String) -> void:
	voice_transcription_failed.emit(reason)
func _on_voice_session_audio_received(payload: Dictionary) -> void:
	voice_audio_received.emit(payload)
