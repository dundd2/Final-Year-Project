class_name VoiceInteractionController
extends Node
const ERROR_CONTEXT := "VoiceInteractionController"
const VOICE_INPUT_BUS_NAME := "VoiceInput"
const DEFAULT_CAPTURE_SECONDS := 4.0
const DEFAULT_SAMPLE_RATE := 16000
signal capture_started()
signal capture_completed(pcm: PackedByteArray, sample_rate: int, metadata: Dictionary)
signal capture_failed(reason: String)
signal capture_cancelled()
var microphone_player: AudioStreamPlayer
var microphone_stream: AudioStreamMicrophone
var record_effect: AudioEffectRecord
var capture_timer: Timer
var is_prepared: bool = false
func _prepare_microphone_pipeline() -> void:
	if is_prepared:
		return
	if AudioServer.get_input_device_list().is_empty():
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "No audio input devices found. Voice capture will be disabled")
		is_prepared = false
		return
	if ProjectSettings.has_setting("audio/driver/enable_input") and not bool(ProjectSettings.get_setting("audio/driver/enable_input")):
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Audio input is disabled in project settings")
		is_prepared = false
		return
	microphone_stream = AudioStreamMicrophone.new()
	microphone_player = AudioStreamPlayer.new()
	microphone_player.stream = microphone_stream
	microphone_player.bus = VOICE_INPUT_BUS_NAME if AudioServer.get_bus_index(VOICE_INPUT_BUS_NAME) != -1 else "Master"
	microphone_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(microphone_player)
	record_effect = AudioEffectRecord.new()
	record_effect.format = 16
	record_effect.set_recording_active(false)
	var bus_index := AudioServer.get_bus_index(VOICE_INPUT_BUS_NAME)
	if bus_index == -1:
		bus_index = AudioServer.get_bus_index("Master")
	AudioServer.add_bus_effect(bus_index, record_effect)
	capture_timer = Timer.new()
	capture_timer.one_shot = true
	capture_timer.timeout.connect(_on_capture_timeout)
	add_child(capture_timer)
	is_prepared = true
func start_capture(duration_seconds: float = DEFAULT_CAPTURE_SECONDS) -> void:
	_prepare_microphone_pipeline()
	if not is_prepared or record_effect == null:
		capture_failed.emit("record_effect_missing")
		return
	if not _ensure_microphone_active():
		capture_failed.emit("microphone_unavailable")
		return
	record_effect.set_recording_active(false)
	if record_effect.has_method("clear_buffer"):
		record_effect.clear_buffer()
	record_effect.set_recording_active(true)
	capture_started.emit()
	capture_timer.stop()
	capture_timer.wait_time = max(0.5, duration_seconds)
	capture_timer.start()
func stop_capture(submit: bool = true) -> void:
	if record_effect == null or not record_effect.is_recording_active():
		if submit:
			capture_failed.emit("not_recording")
		else:
			capture_cancelled.emit()
		return
	record_effect.set_recording_active(false)
	capture_timer.stop()
	if microphone_player != null and microphone_player.is_playing():
		microphone_player.stop()
	var recording: AudioStreamWAV = record_effect.get_recording()
	if recording == null:
		if submit:
			capture_failed.emit("empty_recording")
		else:
			capture_cancelled.emit()
		return
	var pcm_data := recording.data
	if pcm_data.is_empty():
		if submit:
			capture_failed.emit("empty_pcm")
		else:
			capture_cancelled.emit()
		return
	var metadata := {
		"stereo": recording.stereo,
		"mix_rate": recording.mix_rate,
		"length_seconds": float(pcm_data.size()) / float(recording.mix_rate * (4 if recording.stereo else 2)),
	}
	if submit:
		capture_completed.emit(pcm_data.duplicate(), recording.mix_rate, metadata)
	else:
		capture_cancelled.emit()
	if record_effect.has_method("clear_buffer"):
		record_effect.clear_buffer()
func cancel_capture() -> void:
	stop_capture(false)
func _on_capture_timeout() -> void:
	stop_capture(true)
func _exit_tree() -> void:
	if capture_timer != null and not capture_timer.is_stopped():
		capture_timer.stop()
	if record_effect != null:
		record_effect.set_recording_active(false)
		var bus_index := AudioServer.get_bus_index(VOICE_INPUT_BUS_NAME)
		if bus_index == -1:
			bus_index = AudioServer.get_bus_index("Master")
		for i in range(AudioServer.get_bus_effect_count(bus_index)):
			var effect = AudioServer.get_bus_effect(bus_index, i)
			if effect == record_effect:
				AudioServer.remove_bus_effect(bus_index, i)
				break
	if microphone_player != null:
		if microphone_player.is_playing():
			microphone_player.stop()
		microphone_player.queue_free()
	is_prepared = false
func _ensure_microphone_active() -> bool:
	if microphone_player == null:
		return false
	if microphone_player.is_playing():
		return true
	microphone_player.play()
	return microphone_player.is_playing()
