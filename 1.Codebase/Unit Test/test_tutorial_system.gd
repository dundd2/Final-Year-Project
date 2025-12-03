extends Node
var initial_completed: Dictionary = {}
var initial_enabled: bool = true
func _ready() -> void:
	print("[TutorialSystemTest] Starting TutorialSystem unit tests...")
	await get_tree().process_frame
	if not TutorialSystem:
		print("[TutorialSystemTest] ❌ FAIL: TutorialSystem autoload not found")
		queue_free()
		get_tree().quit(1)
		return
	initial_completed = TutorialSystem.completed_tutorials.duplicate(true)
	initial_enabled = TutorialSystem.tutorial_enabled
	_test_initialization()
	_test_tutorial_steps_definition()
	_test_tutorial_enabled_toggle()
	_test_check_tutorial_trigger()
	_test_is_tutorial_completed()
	_test_get_tutorial_progress()
	_test_get_all_tutorial_steps()
	_test_get_completed_tutorials()
	await _test_signal_emission()
	await _test_save_load_persistence()
	_test_reset_tutorials()
	_test_all_tutorials_complete_check()
	TutorialSystem.completed_tutorials = initial_completed.duplicate(true)
	TutorialSystem.tutorial_enabled = initial_enabled
	print("[TutorialSystemTest] All tests completed.")
	queue_free()
	get_tree().quit()
func _test_initialization() -> void:
	print("[Test] Initialization...")
	assert(TutorialSystem != null, "TutorialSystem should exist as autoload")
	assert(TutorialSystem.tutorial_steps is Array, "tutorial_steps should be Array")
	assert(TutorialSystem.completed_tutorials is Dictionary, "completed_tutorials should be Dictionary")
	assert(TutorialSystem.tutorial_enabled is bool, "tutorial_enabled should be bool")
	assert(TutorialSystem.tutorial_steps.size() > 0, "Should have tutorial steps defined")
	print("   ℹ️  TutorialSystem has %d tutorial steps" % TutorialSystem.tutorial_steps.size())
	print("[Test] Initialization PASSED ✅")
func _test_tutorial_steps_definition() -> void:
	print("[Test] Tutorial steps definition...")
	for step in TutorialSystem.tutorial_steps:
		assert(step.has("id"), "Tutorial step should have ID")
		assert(step.has("trigger"), "Tutorial step should have trigger")
		assert(step.has("priority"), "Tutorial step should have priority")
		assert(step["id"] is String, "Tutorial ID should be String")
		assert(step["trigger"] is String, "Tutorial trigger should be String")
		assert(step["priority"] is int, "Tutorial priority should be int")
	var tutorial_ids = []
	for step in TutorialSystem.tutorial_steps:
		tutorial_ids.append(step["id"])
	assert("first_choice" in tutorial_ids, "Should have first_choice tutorial")
	assert("first_stat_change" in tutorial_ids, "Should have first_stat_change tutorial")
	print("[Test] Tutorial steps definition PASSED ✅")
func _test_tutorial_enabled_toggle() -> void:
	print("[Test] Tutorial enabled toggle...")
	TutorialSystem.set_tutorial_enabled(true)
	assert(TutorialSystem.tutorial_enabled == true, "Should enable tutorials")
	TutorialSystem.set_tutorial_enabled(false)
	assert(TutorialSystem.tutorial_enabled == false, "Should disable tutorials")
	TutorialSystem.set_tutorial_enabled(true)
	print("[Test] Tutorial enabled toggle PASSED ✅")
func _test_check_tutorial_trigger() -> void:
	print("[Test] Check tutorial trigger...")
	TutorialSystem.reset_tutorials()
	TutorialSystem.set_tutorial_enabled(true)
	var initial_completed_count = TutorialSystem.completed_tutorials.size()
	TutorialSystem.check_tutorial_trigger("first_choice")
	await get_tree().create_timer(0.1).timeout
	assert(TutorialSystem.is_tutorial_completed("first_choice"), "first_choice should be marked completed")
	TutorialSystem.check_tutorial_trigger("first_choice")
	await get_tree().create_timer(0.05).timeout
	assert(TutorialSystem.completed_tutorials["first_choice"] == true, "Should not duplicate completion")
	print("[Test] Check tutorial trigger PASSED ✅")
func _test_is_tutorial_completed() -> void:
	print("[Test] Is tutorial completed...")
	TutorialSystem.reset_tutorials()
	assert(not TutorialSystem.is_tutorial_completed("first_choice"), "Should not be completed initially")
	assert(not TutorialSystem.is_tutorial_completed("first_stat_change"), "Should not be completed initially")
	TutorialSystem.completed_tutorials["first_choice"] = true
	assert(TutorialSystem.is_tutorial_completed("first_choice"), "Should be completed")
	assert(not TutorialSystem.is_tutorial_completed("first_stat_change"), "Should still not be completed")
	assert(not TutorialSystem.is_tutorial_completed("nonexistent_tutorial"), "Non-existent should return false")
	print("[Test] Is tutorial completed PASSED ✅")
func _test_get_tutorial_progress() -> void:
	print("[Test] Get tutorial progress...")
	TutorialSystem.reset_tutorials()
	var progress_0 = TutorialSystem.get_tutorial_progress()
	assert(progress_0 == 0.0, "Progress should be 0% with no completions")
	var total_tutorials = TutorialSystem.tutorial_steps.size()
	if total_tutorials > 0:
		TutorialSystem.completed_tutorials["first_choice"] = true
		var progress_1 = TutorialSystem.get_tutorial_progress()
		var expected = (1.0 / total_tutorials) * 100.0
		assert(abs(progress_1 - expected) < 0.1, "Progress should be correct percentage")
	for step in TutorialSystem.tutorial_steps:
		TutorialSystem.completed_tutorials[step["id"]] = true
	var progress_100 = TutorialSystem.get_tutorial_progress()
	assert(abs(progress_100 - 100.0) < 0.1, "Progress should be 100% with all completed")
	print("[Test] Get tutorial progress PASSED ✅")
func _test_get_all_tutorial_steps() -> void:
	print("[Test] Get all tutorial steps...")
	var steps = TutorialSystem.get_all_tutorial_steps()
	assert(steps is Array, "Should return Array")
	assert(steps.size() == TutorialSystem.tutorial_steps.size(), "Should return all steps")
	if steps.size() > 0:
		var original_id = TutorialSystem.tutorial_steps[0]["id"]
		steps[0]["id"] = "modified_id_test"
		assert(TutorialSystem.tutorial_steps[0]["id"] == original_id, "Should be a copy, not reference")
	print("[Test] Get all tutorial steps PASSED ✅")
func _test_get_completed_tutorials() -> void:
	print("[Test] Get completed tutorials...")
	TutorialSystem.reset_tutorials()
	TutorialSystem.completed_tutorials["first_choice"] = true
	TutorialSystem.completed_tutorials["first_stat_change"] = true
	var completed = TutorialSystem.get_completed_tutorials()
	assert(completed is Array, "Should return Array")
	assert(completed.size() == 2, "Should return 2 completed tutorials")
	assert("first_choice" in completed, "Should include first_choice")
	assert("first_stat_change" in completed, "Should include first_stat_change")
	TutorialSystem.reset_tutorials()
	completed = TutorialSystem.get_completed_tutorials()
	assert(completed.size() == 0, "Should return empty array after reset")
	print("[Test] Get completed tutorials PASSED ✅")
func _test_signal_emission() -> void:
	print("[Test] Signal emission...")
	var tutorial_triggered_received = false
	var tutorial_completed_received = false
	var triggered_step = {}
	var completed_id = ""
	var trigger_handler = func(step: Dictionary):
		tutorial_triggered_received = true
		triggered_step = step
	var complete_handler = func(step_id: String):
		tutorial_completed_received = true
		completed_id = step_id
	TutorialSystem.tutorial_triggered.connect(trigger_handler)
	TutorialSystem.tutorial_completed.connect(complete_handler)
	TutorialSystem.reset_tutorials()
	TutorialSystem.check_tutorial_trigger("first_prayer")
	await get_tree().create_timer(0.1).timeout
	assert(tutorial_triggered_received, "tutorial_triggered signal should be emitted")
	assert(tutorial_completed_received, "tutorial_completed signal should be emitted")
	assert(completed_id == "first_prayer", "Should emit correct tutorial ID")
	TutorialSystem.tutorial_triggered.disconnect(trigger_handler)
	TutorialSystem.tutorial_completed.disconnect(complete_handler)
	print("[Test] Signal emission PASSED ✅")
func _test_save_load_persistence() -> void:
	print("[Test] Save/load persistence...")
	TutorialSystem.reset_tutorials()
	TutorialSystem.completed_tutorials["first_choice"] = true
	TutorialSystem.completed_tutorials["first_mission"] = true
	TutorialSystem.save_tutorial_progress()
	await get_tree().create_timer(0.1).timeout
	var saved_completed = TutorialSystem.completed_tutorials.duplicate(true)
	TutorialSystem.completed_tutorials.clear()
	assert(TutorialSystem.completed_tutorials.size() == 0, "Should be cleared")
	TutorialSystem.load_tutorial_progress()
	await get_tree().create_timer(0.1).timeout
	assert(TutorialSystem.is_tutorial_completed("first_choice"), "Should restore first_choice")
	assert(TutorialSystem.is_tutorial_completed("first_mission"), "Should restore first_mission")
	print("[Test] Save/load persistence PASSED ✅")
func _test_reset_tutorials() -> void:
	print("[Test] Reset tutorials...")
	TutorialSystem.completed_tutorials["first_choice"] = true
	TutorialSystem.completed_tutorials["first_stat_change"] = true
	TutorialSystem.completed_tutorials["first_prayer"] = true
	assert(TutorialSystem.completed_tutorials.size() > 0, "Should have completed tutorials")
	TutorialSystem.reset_tutorials()
	assert(TutorialSystem.completed_tutorials.size() == 0, "All tutorials should be reset")
	assert(not TutorialSystem.is_tutorial_completed("first_choice"), "first_choice should not be completed")
	assert(not TutorialSystem.is_tutorial_completed("first_stat_change"), "first_stat_change should not be completed")
	print("[Test] Reset tutorials PASSED ✅")
func _test_all_tutorials_complete_check() -> void:
	print("[Test] All tutorials complete check...")
	var all_complete_received = false
	var complete_handler = func():
		all_complete_received = true
	TutorialSystem.all_tutorials_completed.connect(complete_handler)
	TutorialSystem.reset_tutorials()
	for step in TutorialSystem.tutorial_steps:
		TutorialSystem.completed_tutorials[step["id"]] = false
	for i in range(TutorialSystem.tutorial_steps.size() - 1):
		TutorialSystem.completed_tutorials[TutorialSystem.tutorial_steps[i]["id"]] = true
	TutorialSystem.check_all_tutorials_complete()
	await get_tree().create_timer(0.05).timeout
	assert(not all_complete_received, "Should not emit with incomplete tutorials")
	var last_step = TutorialSystem.tutorial_steps[TutorialSystem.tutorial_steps.size() - 1]
	TutorialSystem.completed_tutorials[last_step["id"]] = true
	TutorialSystem.check_all_tutorials_complete()
	await get_tree().create_timer(0.05).timeout
	assert(all_complete_received, "Should emit when all tutorials complete")
	TutorialSystem.all_tutorials_completed.disconnect(complete_handler)
	print("[Test] All tutorials complete check PASSED ✅")
