extends Node
var test_results := []
func _ready():
	print("\n========== Story Scene Modules Tests ==========\n")
	run_test("test_ui_bindings_creation", test_ui_bindings_creation())
	run_test("test_ui_bindings_validation", test_ui_bindings_validation())
	run_test("test_event_handlers_creation", test_event_handlers_creation())
	run_test("test_event_handlers_eventbus_integration", await test_event_handlers_eventbus_integration())
	run_test("test_stat_display_creation", test_stat_display_creation())
	run_test("test_stat_display_event_handling", await test_stat_display_event_handling())
	run_test("test_coordinator_initialization", test_coordinator_initialization())
	print_summary()
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()
func run_test(test_name: String, result: bool) -> void:
	var status := "✅ PASS" if result else "❌ FAIL"
	print("%s: %s" % [status, test_name])
	test_results.append({ "name": test_name, "passed": result })
func test_ui_bindings_creation() -> bool:
	var ui = StorySceneUIBindings.new()
	if not ui:
		print("  ERROR: Failed to create UI bindings")
		return false
	if not ui.asset_card_scene:
		print("  ERROR: asset_card_scene not loaded")
		return false
	if not ui.pause_menu_scene:
		print("  ERROR: pause_menu_scene not loaded")
		return false
	return true
func test_ui_bindings_validation() -> bool:
	var ui = StorySceneUIBindings.new()
	if not ui:
		print("  ERROR: Failed to create UI bindings")
		return false
	var buttons = ui.get_all_buttons()
	if buttons == null:
		print("  ERROR: get_all_buttons() returned null")
		return false
	var stat_nodes = ui.get_stat_display_nodes()
	if stat_nodes == null or not stat_nodes is Dictionary:
		print("  ERROR: get_stat_display_nodes() failed")
		return false
	return true
func test_event_handlers_creation() -> bool:
	var ui = StorySceneUIBindings.new()
	var mock_scene = Control.new()
	add_child(mock_scene)
	var handlers = StorySceneEventHandlers.new(ui, mock_scene)
	if not handlers:
		print("  ERROR: Failed to create event handlers")
		mock_scene.queue_free()
		return false
	var stats = handlers.get_event_stats()
	if not stats is Dictionary:
		print("  ERROR: get_event_stats() failed")
		mock_scene.queue_free()
		return false
	mock_scene.queue_free()
	return true
func test_event_handlers_eventbus_integration() -> bool:
	var ui = StorySceneUIBindings.new()
	var mock_scene = Control.new()
	add_child(mock_scene)
	var test_button = Button.new()
	test_button.name = "TestButton"
	mock_scene.add_child(test_button)
	ui.pause_button = test_button
	var handlers = StorySceneEventHandlers.new(ui, mock_scene)
	var event_received := false
	var event_callback = func(_data):
		event_received = true
	EventBus.subscribe("pause_requested", self, "_test_pause_event")
	handlers.connect_all_signals()
	test_button.pressed.emit()
	await get_tree().process_frame
	EventBus.unsubscribe("pause_requested", self)
	mock_scene.queue_free()
	return true
func _test_pause_event(_data: Dictionary) -> void:
	pass
func test_stat_display_creation() -> bool:
	var mock_bar = ProgressBar.new()
	var mock_label = Label.new()
	var stat_display = StorySceneStatDisplay.new(
		mock_bar,
		mock_label,
		null,
		null,
		null,
	)
	if not stat_display:
		print("  ERROR: Failed to create stat display")
		mock_bar.queue_free()
		mock_label.queue_free()
		return false
	if not stat_display.has_method("is_reality_critical"):
		print("  ERROR: Missing method is_reality_critical")
		mock_bar.queue_free()
		mock_label.queue_free()
		return false
	mock_bar.queue_free()
	mock_label.queue_free()
	return true
func test_stat_display_event_handling() -> bool:
	var mock_bar = ProgressBar.new()
	mock_bar.max_value = 100
	mock_bar.value = 50
	var mock_label = Label.new()
	var stat_display = StorySceneStatDisplay.new(
		mock_bar,
		mock_label,
		null,
		null,
		null,
	)
	stat_display.subscribe_to_events()
	EventBus.publish(
		"reality_score_changed",
		{
			"new_value": 75,
			"timestamp": Time.get_ticks_msec(),
		},
	)
	await get_tree().process_frame
	stat_display.unsubscribe()
	mock_bar.queue_free()
	mock_label.queue_free()
	return true
func test_coordinator_initialization() -> bool:
	var CoordinatorScript = load("res://1.Codebase/src/scripts/ui/story_scene_coordinator.gd")
	if not CoordinatorScript:
		print("  ERROR: Failed to load coordinator script")
		return false
	if CoordinatorScript.get_global_name() != "StorySceneCoordinator":
		print("  ERROR: class_name not defined correctly")
		return false
	return true
func print_summary() -> void:
	var passed := 0
	var total := test_results.size()
	for result in test_results:
		if result["passed"]:
			passed += 1
	print("\n===============================================")
	print("Story Scene Modules Tests: %d/%d passed (%.1f%%)" % [passed, total, float(passed) / float(total) * 100.0])
	if passed == total:
		print("✅ ALL TESTS PASSED")
	else:
		print("❌ SOME TESTS FAILED")
	print("===============================================\n")
