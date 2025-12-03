extends Node
class_name AIVoiceBridge
const VoiceSessionManager = preload("res://1.Codebase/src/scripts/core/ai/voice_session_manager.gd")
signal capability_changed(supported: bool)
signal input_ready(pcm: PackedByteArray, sample_rate: int, metadata: Dictionary)
signal transcription_ready(text: String, metadata: Dictionary)
signal transcription_failed(reason: String)
signal audio_received(payload: Dictionary)
var default_input_sample_rate: int = 16000
var default_output_sample_rate: int = 24000
var voice_session: VoiceSessionManager = null
func setup(available_modes: Array, default_mode: int, input_rate: int, output_rate: int) -> void:
	default_input_sample_rate = input_rate
	default_output_sample_rate = output_rate
	if voice_session:
		voice_session.queue_free()
	voice_session = VoiceSessionManager.new()
	add_child(voice_session)
	voice_session.configure(available_modes, default_mode)
	_connect_session_signals()
func get_session() -> VoiceSessionManager:
	return voice_session
func refresh_capabilities(evaluator: Callable) -> void:
	if voice_session == null:
		return
	if evaluator.is_null():
		return
	var supported: bool = bool(evaluator.call())
	voice_session.update_native_voice_support(supported)
func update_native_support(supported: bool) -> void:
	if voice_session:
		voice_session.update_native_voice_support(supported)
func is_native_voice_supported() -> bool:
	if voice_session == null:
		return false
	return voice_session.native_voice_supported
func get_settings() -> Dictionary:
	if voice_session:
		return voice_session.get_settings_payload()
	return { }
func apply_settings(settings: Dictionary) -> void:
	if voice_session == null:
		return
	voice_session.apply_settings_payload(settings)
func queue_voice_input(pcm_bytes: PackedByteArray, sample_rate: int, mime_type: String, fallback_sample_rate: int) -> void:
	if voice_session == null:
		return
	voice_session.queue_voice_input(pcm_bytes, sample_rate, mime_type, fallback_sample_rate)
func has_pending_voice_input() -> bool:
	if voice_session == null:
		return false
	return voice_session.has_pending_voice_input()
func clear_pending_voice_input() -> void:
	if voice_session:
		voice_session.clear_pending_voice_input()
func build_inline_part(fallback_sample_rate: int) -> Dictionary:
	if voice_session == null:
		return { }
	return voice_session.build_inline_part(fallback_sample_rate)
func write_config(config: ConfigFile) -> void:
	if voice_session:
		voice_session.write_to_config(config)
func load_config(config: ConfigFile) -> void:
	if voice_session:
		voice_session.load_from_config(config)
func request_voice_capture(duration_seconds: float) -> void:
	if voice_session == null:
		return
	voice_session.request_voice_capture(duration_seconds)
func cancel_voice_capture() -> void:
	if voice_session:
		voice_session.cancel_voice_capture()
func reset_request_context() -> void:
	if voice_session:
		voice_session.reset_request_context()
func _connect_session_signals() -> void:
	if voice_session == null:
		return
	if not voice_session.capability_changed.is_connected(_on_capability_changed):
		voice_session.capability_changed.connect(_on_capability_changed)
	if not voice_session.input_buffer_ready.is_connected(_on_input_ready):
		voice_session.input_buffer_ready.connect(_on_input_ready)
	if not voice_session.transcription_ready.is_connected(_on_transcription_ready):
		voice_session.transcription_ready.connect(_on_transcription_ready)
	if not voice_session.transcription_failed.is_connected(_on_transcription_failed):
		voice_session.transcription_failed.connect(_on_transcription_failed)
	if not voice_session.audio_received.is_connected(_on_audio_received):
		voice_session.audio_received.connect(_on_audio_received)
func _on_capability_changed(supported: bool) -> void:
	capability_changed.emit(supported)
func _on_input_ready(pcm: PackedByteArray, sample_rate: int, metadata: Dictionary) -> void:
	input_ready.emit(pcm, sample_rate, metadata)
func _on_transcription_ready(text: String, metadata: Dictionary) -> void:
	transcription_ready.emit(text, metadata)
func _on_transcription_failed(reason: String) -> void:
	transcription_failed.emit(reason)
func _on_audio_received(payload: Dictionary) -> void:
	audio_received.emit(payload)
