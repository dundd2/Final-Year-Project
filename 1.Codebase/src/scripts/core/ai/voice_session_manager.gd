extends Node
class_name VoiceSessionManager
const ERROR_CONTEXT := "VoiceSessionManager"
const VoiceInteractionControllerScript = preload("res://1.Codebase/src/scripts/core/voice_interaction_controller.gd")
signal capability_changed(supported: bool)
signal input_buffer_ready(pcm: PackedByteArray, sample_rate: int, metadata: Dictionary)
signal transcription_ready(text: String, metadata: Dictionary)
signal transcription_failed(reason: String)
signal audio_received(payload: Dictionary)
var prefer_native_audio: bool = false
var voice_output_enabled: bool = false
var voice_input_enabled: bool = false
var preferred_voice_name: String = ""
var voice_input_mode: int = 0
var proactive_audio_enabled: bool = false
var affective_dialog_enabled: bool = false
var native_voice_supported: bool = false
var _valid_voice_modes: Array = []
var _default_voice_mode: int = 0
var _voice_controller: VoiceInteractionController
var _queued_voice_input: Dictionary = { }
var _voice_request_context: Dictionary = { }
var _last_voice_payload: Dictionary = { }
var _last_voice_transcript: String = ""
var _last_voice_transcript_confidence: float = 0.0
func _ready() -> void:
	_voice_controller = VoiceInteractionControllerScript.new()
	add_child(_voice_controller)
	if _voice_controller.capture_completed.is_connected(_on_voice_capture_completed):
		_voice_controller.capture_completed.disconnect(_on_voice_capture_completed)
	_voice_controller.capture_completed.connect(_on_voice_capture_completed)
	if _voice_controller.capture_failed.is_connected(_on_voice_capture_failed):
		_voice_controller.capture_failed.disconnect(_on_voice_capture_failed)
	_voice_controller.capture_failed.connect(_on_voice_capture_failed)
	if _voice_controller.capture_cancelled.is_connected(_on_voice_capture_cancelled):
		_voice_controller.capture_cancelled.disconnect(_on_voice_capture_cancelled)
	_voice_controller.capture_cancelled.connect(_on_voice_capture_cancelled)
func configure(valid_modes: Array, default_mode: int) -> void:
	_valid_voice_modes = valid_modes.duplicate()
	_default_voice_mode = default_mode
	if not _valid_voice_modes.is_empty() and not _valid_voice_modes.has(default_mode):
		_default_voice_mode = _valid_voice_modes[0]
	_enforce_voice_mode()
func get_settings_payload() -> Dictionary:
	return {
		"prefer_native_audio": prefer_native_audio,
		"voice_output_enabled": voice_output_enabled,
		"voice_input_enabled": voice_input_enabled,
		"preferred_voice_name": preferred_voice_name,
		"voice_input_mode": voice_input_mode,
		"proactive_audio_enabled": proactive_audio_enabled,
		"affective_dialog_enabled": affective_dialog_enabled,
		"native_voice_supported": native_voice_supported,
	}
func apply_settings_payload(settings: Dictionary) -> void:
	prefer_native_audio = bool(settings.get("prefer_native_audio", prefer_native_audio))
	voice_output_enabled = bool(settings.get("voice_output_enabled", voice_output_enabled))
	voice_input_enabled = bool(settings.get("voice_input_enabled", voice_input_enabled))
	preferred_voice_name = str(settings.get("preferred_voice_name", preferred_voice_name))
	voice_input_mode = int(settings.get("voice_input_mode", voice_input_mode))
	proactive_audio_enabled = bool(settings.get("proactive_audio_enabled", proactive_audio_enabled))
	affective_dialog_enabled = bool(settings.get("affective_dialog_enabled", affective_dialog_enabled))
	_enforce_voice_mode()
	_apply_voice_support_lockouts()
func load_from_config(config: ConfigFile) -> void:
	prefer_native_audio = bool(config.get_value("voice", "prefer_native_audio", prefer_native_audio))
	voice_output_enabled = bool(config.get_value("voice", "voice_output_enabled", voice_output_enabled))
	voice_input_enabled = bool(config.get_value("voice", "voice_input_enabled", voice_input_enabled))
	preferred_voice_name = str(config.get_value("voice", "preferred_voice_name", preferred_voice_name))
	voice_input_mode = int(config.get_value("voice", "voice_input_mode", voice_input_mode))
	proactive_audio_enabled = bool(config.get_value("voice", "proactive_audio_enabled", proactive_audio_enabled))
	affective_dialog_enabled = bool(config.get_value("voice", "affective_dialog_enabled", affective_dialog_enabled))
	_enforce_voice_mode()
	_apply_voice_support_lockouts()
func write_to_config(config: ConfigFile) -> void:
	config.set_value("voice", "prefer_native_audio", prefer_native_audio)
	config.set_value("voice", "voice_output_enabled", voice_output_enabled)
	config.set_value("voice", "voice_input_enabled", voice_input_enabled)
	config.set_value("voice", "preferred_voice_name", preferred_voice_name)
	config.set_value("voice", "voice_input_mode", voice_input_mode)
	config.set_value("voice", "proactive_audio_enabled", proactive_audio_enabled)
	config.set_value("voice", "affective_dialog_enabled", affective_dialog_enabled)
func update_native_voice_support(supported: bool) -> void:
	var previous := native_voice_supported
	native_voice_supported = supported
	_apply_voice_support_lockouts()
	if previous != native_voice_supported:
		capability_changed.emit(native_voice_supported)
func prefers_native_audio() -> bool:
	return prefer_native_audio and native_voice_supported
func wants_voice_output() -> bool:
	return prefers_native_audio() and voice_output_enabled
func wants_voice_input() -> bool:
	return prefers_native_audio() and voice_input_enabled
func get_preferred_voice_name() -> String:
	return preferred_voice_name
func get_voice_input_mode() -> int:
	return voice_input_mode
func is_proactive_audio_enabled() -> bool:
	return proactive_audio_enabled
func is_affective_dialog_enabled() -> bool:
	return affective_dialog_enabled
func queue_voice_input(pcm_bytes: PackedByteArray, sample_rate: int, mime_type: String, default_rate: int) -> void:
	if pcm_bytes.is_empty():
		return
	var resolved_rate := sample_rate if sample_rate > 0 else default_rate
	var resolved_mime := mime_type if not mime_type.is_empty() else "audio/pcm;rate=%d" % resolved_rate
	_queued_voice_input = {
		"bytes": pcm_bytes.duplicate(),
		"sample_rate": resolved_rate,
		"mime_type": resolved_mime,
		"timestamp": Time.get_datetime_string_from_system(),
	}
func has_pending_voice_input() -> bool:
	return not _queued_voice_input.is_empty()
func clear_pending_voice_input() -> void:
	_queued_voice_input.clear()
func build_inline_part(default_rate: int) -> Dictionary:
	if _queued_voice_input.is_empty():
		return { }
	var bytes: PackedByteArray = _queued_voice_input.get("bytes", PackedByteArray())
	if bytes.is_empty():
		_queued_voice_input.clear()
		return { }
	var sample_rate := int(_queued_voice_input.get("sample_rate", default_rate))
	var mime_type := str(_queued_voice_input.get("mime_type", "audio/pcm;rate=%d" % sample_rate))
	var inline_part := {
		"inlineData": {
			"mimeType": mime_type,
			"data": Marshalls.raw_to_base64(bytes),
		},
	}
	_voice_request_context = {
		"sample_rate": sample_rate,
		"mime_type": mime_type,
		"bytes_length": bytes.size(),
		"submitted_at": Time.get_ticks_msec(),
	}
	_queued_voice_input.clear()
	return inline_part
func get_request_context() -> Dictionary:
	return _voice_request_context.duplicate(true)
func reset_request_context() -> void:
	_voice_request_context.clear()
func request_voice_capture(duration_seconds: float) -> void:
	if not prefers_native_audio() or not voice_input_enabled:
		return
	if _voice_controller:
		_voice_controller.start_capture(duration_seconds)
func cancel_voice_capture() -> void:
	if _voice_controller:
		_voice_controller.cancel_capture()
func process_voice_payloads(payloads: Array, default_rate: int) -> void:
	if payloads.is_empty():
		return
	_last_voice_payload = payloads[0] if payloads.size() > 0 else { }
	var has_played := false
	for payload in payloads:
		var mime := str(payload.get("mime_type", ""))
		var data_base64 := str(payload.get("data_base64", ""))
		if data_base64.is_empty():
			continue
		var sample_rate := int(payload.get("sample_rate", resolve_sample_rate(payload, default_rate)))
		payload["sample_rate"] = sample_rate
		payload["timestamp"] = Time.get_datetime_string_from_system()
		audio_received.emit(payload)
		if AudioManager == null or has_played:
			continue
		if mime.begins_with("audio/pcm"):
			AudioManager.play_voice_from_base64(data_base64, sample_rate)
			has_played = true
		elif mime.find("mp3") != -1 or mime.find("mpeg") != -1:
			var stream := AudioStreamMP3.new()
			stream.data = Marshalls.base64_to_raw(data_base64)
			stream.loop = false
			AudioManager.play_voice_stream(stream)
			has_played = true
		else:
			ErrorReporterBridge.report_warning(
				ERROR_CONTEXT,
				"Unsupported voice mime type received: %s" % mime,
				{ "mime": mime },
			)
func resolve_sample_rate(payload_dict: Dictionary, fallback: int) -> int:
	if payload_dict.has("sampleRate"):
		return int(payload_dict["sampleRate"])
	if payload_dict.has("sample_rate"):
		return int(payload_dict["sample_rate"])
	if payload_dict.has("sampleRateHertz"):
		return int(payload_dict["sampleRateHertz"])
	if payload_dict.has("sample_rate_hz"):
		return int(payload_dict["sample_rate_hz"])
	if payload_dict.has("mimeType"):
		return _sample_rate_from_mime(str(payload_dict["mimeType"]), fallback)
	if payload_dict.has("mime_type"):
		return _sample_rate_from_mime(str(payload_dict["mime_type"]), fallback)
	return fallback
func get_last_voice_payload() -> Dictionary:
	return _last_voice_payload.duplicate(true)
func get_last_transcript() -> String:
	return _last_voice_transcript
func get_last_transcript_confidence() -> float:
	return _last_voice_transcript_confidence
func process_transcription_entry(entry: Variant, direction: String) -> void:
	var items: Array = []
	if entry is Array:
		items = entry
	elif entry is Dictionary:
		items = [entry]
	else:
		return
	for item in items:
		if not (item is Dictionary):
			continue
		var text_value := ""
		if item.has("text"):
			text_value = str(item["text"])
		elif item.has("transcript"):
			text_value = str(item["transcript"])
		if text_value.is_empty():
			continue
		_last_voice_transcript = text_value
		_last_voice_transcript_confidence = float(item.get("confidence", _last_voice_transcript_confidence))
		var metadata := {
			"confidence": _last_voice_transcript_confidence,
			"direction": direction,
			"timestamp": Time.get_datetime_string_from_system(),
			"language": item.get("languageCode", item.get("language", "")),
		}
		transcription_ready.emit(text_value, metadata)
func _on_voice_capture_completed(pcm: PackedByteArray, sample_rate: int, metadata: Dictionary) -> void:
	queue_voice_input(pcm, sample_rate, "", metadata.get("sample_rate", sample_rate))
	input_buffer_ready.emit(pcm, sample_rate, metadata)
func _on_voice_capture_failed(reason: String) -> void:
	transcription_failed.emit(reason)
func _on_voice_capture_cancelled() -> void:
	clear_pending_voice_input()
func _apply_voice_support_lockouts() -> void:
	if not native_voice_supported:
		prefer_native_audio = false
		voice_output_enabled = false
		voice_input_enabled = false
		return
	if not prefer_native_audio:
		voice_output_enabled = false
		voice_input_enabled = false
func _enforce_voice_mode() -> void:
	if _valid_voice_modes.is_empty():
		return
	if not _valid_voice_modes.has(voice_input_mode):
		voice_input_mode = _default_voice_mode
func _sample_rate_from_mime(mime: String, fallback: int) -> int:
	var parts := mime.split(";")
	for fragment in parts:
		var trimmed := fragment.strip_edges()
		if trimmed.begins_with("rate="):
			var rate_value := int(trimmed.substr(5, trimmed.length()))
			if rate_value > 0:
				return rate_value
	return fallback
