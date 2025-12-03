extends Node
var test_controller: Node = null
var tests_passed: int = 0
var tests_failed: int = 0
func _ready() -> void:
	print("\n" + "=".repeat(80))
	print("  🧪 TESTING VOICE INTERACTION CONTROLLER")
	print("=".repeat(80) + "\n")
	await get_tree().process_frame
	await _test_controller_initialization()
	await _test_constants()
	await _test_signal_definitions()
	await _test_prepare_microphone_pipeline()
	await _test_capture_lifecycle()
	await _test_capture_cancellation()
	await _test_capture_failure_handling()
	await _test_metadata_generation()
	await _test_cleanup_on_exit()
	_print_summary()
	await get_tree().create_timer(0.5).timeout
	queue_free()
func _test_controller_initialization() -> void:
	print("\n[Test] VoiceInteractionController initialization...")
	var VoiceControllerScript = load("res://1.Codebase/src/scripts/core/voice_interaction_controller.gd")
	test_controller = VoiceControllerScript.new()
	add_child(test_controller)
	_assert(test_controller != null, "VoiceInteractionController should instantiate")
	_assert(test_controller.is_prepared == false, "Should not be prepared initially")
	_assert(test_controller.microphone_player == null, "microphone_player should be null initially")
	_assert(test_controller.microphone_stream == null, "microphone_stream should be null initially")
	_assert(test_controller.record_effect == null, "record_effect should be null initially")
	_assert(test_controller.capture_timer == null, "capture_timer should be null initially")
	print("   ✅ PASS: Controller initialization")
func _test_constants() -> void:
	print("\n[Test] Constants...")
	_assert(test_controller.VOICE_INPUT_BUS_NAME == "VoiceInput",
		"VOICE_INPUT_BUS_NAME should be 'VoiceInput'")
	_assert(test_controller.DEFAULT_CAPTURE_SECONDS == 4.0,
		"DEFAULT_CAPTURE_SECONDS should be 4.0")
	_assert(test_controller.DEFAULT_SAMPLE_RATE == 16000,
		"DEFAULT_SAMPLE_RATE should be 16000")
	print("   ✅ PASS: Constants")
func _test_signal_definitions() -> void:
	print("\n[Test] Signal definitions...")
	var signal_list = test_controller.get_signal_list()
	var signal_names = []
	for sig in signal_list:
		signal_names.append(sig["name"])
	_assert("capture_started" in signal_names, "Should have capture_started signal")
	_assert("capture_completed" in signal_names, "Should have capture_completed signal")
	_assert("capture_failed" in signal_names, "Should have capture_failed signal")
	_assert("capture_cancelled" in signal_names, "Should have capture_cancelled signal")
	print("   ✅ PASS: Signal definitions")
func _test_prepare_microphone_pipeline() -> void:
	print("\n[Test] Prepare microphone pipeline...")
	test_controller._prepare_microphone_pipeline()
	var has_audio_input = not AudioServer.get_input_device_list().is_empty()
	if has_audio_input:
		_assert(test_controller.is_prepared or not has_audio_input,
			"Should prepare pipeline if audio input available")
		if test_controller.is_prepared:
			_assert(test_controller.microphone_stream != null,
				"microphone_stream should be created when prepared")
			_assert(test_controller.microphone_player != null,
				"microphone_player should be created when prepared")
			_assert(test_controller.record_effect != null,
				"record_effect should be created when prepared")
			_assert(test_controller.capture_timer != null,
				"capture_timer should be created when prepared")
	else:
		_assert(test_controller.is_prepared == false,
			"Should not prepare if no audio input available")
	var was_prepared = test_controller.is_prepared
	test_controller._prepare_microphone_pipeline()
	_assert(test_controller.is_prepared == was_prepared,
		"Calling prepare again should be idempotent")
	print("   ✅ PASS: Prepare microphone pipeline")
func _test_capture_lifecycle() -> void:
	print("\n[Test] Capture lifecycle...")
	var capture_started_fired = false
	var capture_completed_fired = false
	var capture_failed_fired = false
	test_controller.capture_started.connect(func(): capture_started_fired = true)
	test_controller.capture_completed.connect(func(_pcm, _rate, _meta): capture_completed_fired = true)
	test_controller.capture_failed.connect(func(_reason): capture_failed_fired = true)
	test_controller.start_capture(0.5)  
	if test_controller.is_prepared:
		_assert(capture_started_fired, "capture_started should fire when starting capture")
		await test_controller.capture_timer.timeout
		await get_tree().process_frame
		_assert(capture_completed_fired or capture_failed_fired,
			"Either capture_completed or capture_failed should fire")
	else:
		_assert(capture_failed_fired, "capture_failed should fire when no audio input")
	print("   ✅ PASS: Capture lifecycle")
func _test_capture_cancellation() -> void:
	print("\n[Test] Capture cancellation...")
	if not test_controller.is_prepared:
		print("   ℹ️  Skipped (no audio input available)")
		return
	var capture_cancelled_fired = false
	var cancel_connection = test_controller.capture_cancelled.connect(
		func(): capture_cancelled_fired = true
	)
	test_controller.start_capture(10.0)  
	await get_tree().process_frame
	test_controller.cancel_capture()
	_assert(capture_cancelled_fired, "capture_cancelled should fire when cancelled")
	if cancel_connection:
		test_controller.capture_cancelled.disconnect(cancel_connection)
	print("   ✅ PASS: Capture cancellation")
func _test_capture_failure_handling() -> void:
	print("\n[Test] Capture failure handling...")
	var last_failure_reason = ""
	var failure_connection = test_controller.capture_failed.connect(
		func(reason): last_failure_reason = reason
	)
	test_controller.stop_capture(true)
	_assert(last_failure_reason == "not_recording" or last_failure_reason == "record_effect_missing",
		"Should fail with appropriate reason when not recording")
	last_failure_reason = ""
	test_controller.cancel_capture()
	if failure_connection:
		test_controller.capture_failed.disconnect(failure_connection)
	print("   ✅ PASS: Capture failure handling")
func _test_metadata_generation() -> void:
	print("\n[Test] Metadata generation...")
	if not test_controller.is_prepared:
		print("   ℹ️  Skipped (no audio input available)")
		return
	var received_metadata: Dictionary = {}
	var metadata_connection = test_controller.capture_completed.connect(
		func(_pcm, _rate, meta): received_metadata = meta
	)
	test_controller.start_capture(0.3)
	await test_controller.capture_timer.timeout
	await get_tree().create_timer(0.2).timeout  
	if not received_metadata.is_empty():
		_assert(received_metadata.has("stereo"), "Metadata should have stereo field")
		_assert(received_metadata.has("mix_rate"), "Metadata should have mix_rate field")
		_assert(received_metadata.has("length_seconds"), "Metadata should have length_seconds field")
		_assert(received_metadata["mix_rate"] > 0, "mix_rate should be positive")
		_assert(received_metadata["length_seconds"] >= 0, "length_seconds should be non-negative")
	if metadata_connection:
		test_controller.capture_completed.disconnect(metadata_connection)
	print("   ✅ PASS: Metadata generation")
func _test_cleanup_on_exit() -> void:
	print("\n[Test] Cleanup on exit...")
	if test_controller.is_prepared:
		_assert(test_controller.microphone_player != null,
			"microphone_player should exist before cleanup")
		_assert(test_controller.record_effect != null,
			"record_effect should exist before cleanup")
		test_controller._exit_tree()
		_assert(test_controller.is_prepared == false,
			"Should mark as not prepared after cleanup")
	else:
		print("   ℹ️  Skipped detailed cleanup test (pipeline not prepared)")
	print("   ✅ PASS: Cleanup on exit")
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("   ❌ FAIL: %s" % message)
func _print_summary() -> void:
	print("\n" + "=".repeat(80))
	print("  TEST SUMMARY - VoiceInteractionController")
	print("=".repeat(80))
	print("  Total Tests:   %d" % (tests_passed + tests_failed))
	print("  ✅ Passed:     %d" % tests_passed)
	print("  ❌ Failed:     %d" % tests_failed)
	if tests_failed > 0:
		print("\n  ⚠️  Some tests failed!")
	else:
		print("\n  🎉 All tests passed!")
	print("=".repeat(80) + "\n")
	if test_controller and not test_controller.is_queued_for_deletion():
		test_controller.queue_free()
		test_controller = null
