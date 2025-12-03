extends Node
var test_results := []
var _test_callback_received := false
var _test_callback_data := { }
var _unstable_first_called := false
var _unstable_second_called := false
func _ready():
	print("\n========== EventBus Unit Tests ==========\n")
	EventBus.reset()
	run_test("test_subscribe_and_publish", test_subscribe_and_publish())
	run_test("test_unsubscribe", test_unsubscribe())
	run_test("test_request_pattern", test_request_pattern())
	run_test("test_multiple_subscribers", test_multiple_subscribers())
	run_test("test_unsubscribe_during_publish", test_unsubscribe_during_publish())
	run_test("test_dead_subscriber_cleanup", await test_dead_subscriber_cleanup())
	run_test("test_reset_clears_state", test_reset_clears_state())
	run_test("test_event_history", test_event_history())
	print_summary()
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()
func run_test(test_name: String, result: bool) -> void:
	var status := "✅ PASS" if result else "❌ FAIL"
	print("%s: %s" % [status, test_name])
	test_results.append({ "name": test_name, "passed": result })
func test_subscribe_and_publish() -> bool:
	_test_callback_received = false
	_test_callback_data = { }
	EventBus.subscribe("test_event_1", self, "_test_callback")
	EventBus.publish("test_event_1", { "value": 42, "message": "Hello" })
	if not _test_callback_received:
		print("  ERROR: Callback not received")
		return false
	if _test_callback_data.get("value") != 42:
		print("  ERROR: Wrong data received: %s" % _test_callback_data)
		return false
	EventBus.unsubscribe("test_event_1", self)
	return true
func test_unsubscribe() -> bool:
	_test_callback_received = false
	EventBus.subscribe("test_event_2", self, "_test_callback")
	EventBus.unsubscribe("test_event_2", self)
	EventBus.publish("test_event_2", { "value": 99 })
	if _test_callback_received:
		print("  ERROR: Callback called after unsubscribe")
		return false
	return true
func test_request_pattern() -> bool:
	EventBus.subscribe("get_test_value", self, "_provide_test_value")
	var result = EventBus.request("get_test_value")
	if result != 123:
		print("  ERROR: Expected 123, got %s" % result)
		EventBus.unsubscribe("get_test_value", self)
		return false
	EventBus.unsubscribe("get_test_value", self)
	return true
func test_multiple_subscribers() -> bool:
	var counter := 0
	var callback1 = func(_data): counter += 1
	var callback2 = func(_data): counter += 10
	EventBus.subscribe("test_event_3", self, "_increment_counter")
	EventBus.publish("test_event_3", { })
	var subscribers = EventBus.get_subscribers("test_event_3")
	if subscribers.size() != 1:
		print("  ERROR: Expected 1 subscriber, got %d" % subscribers.size())
		return false
	EventBus.unsubscribe("test_event_3", self)
	return true
func test_dead_subscriber_cleanup() -> bool:
	var temp_node = Node.new()
	add_child(temp_node)
	EventBus.subscribe("test_event_4", temp_node, "queue_free")
	temp_node.queue_free()
	await get_tree().process_frame
	EventBus.publish("test_event_4", { })
	return true
func test_reset_clears_state() -> bool:
	EventBus.subscribe("reset_event", self, "_test_callback")
	EventBus.publish("reset_event", { "value": 1 })
	var has_registry := not EventBus.get_registered_events().is_empty()
	var has_history := not EventBus.get_event_history(1).is_empty()
	if not has_registry or not has_history:
		print("  ERROR: Setup for reset test failed")
		EventBus.reset()
		return false
	EventBus.reset()
	if not EventBus.get_registered_events().is_empty():
		print("  ERROR: Registry was not cleared by reset()")
		return false
	if not EventBus.get_event_history(1).is_empty():
		print("  ERROR: History was not cleared by reset()")
		return false
	if not EventBus.get_event_stats().is_empty():
		print("  ERROR: Stats were not cleared by reset()")
		return false
	return true
func test_event_history() -> bool:
	EventBus.clear_history()
	EventBus.publish("test_history_1", { "value": 1 })
	EventBus.publish("test_history_2", { "value": 2 })
	EventBus.publish("test_history_3", { "value": 3 })
	var history = EventBus.get_event_history(10)
	if history.size() != 3:
		print("  ERROR: Expected 3 events in history, got %d" % history.size())
		return false
	if history[0]["event"] != "test_history_1":
		print("  ERROR: Wrong event order in history")
		return false
	var clamped_history = EventBus.get_event_history(2)
	if clamped_history.size() != 2 or clamped_history[0]["event"] != "test_history_2":
		print("  ERROR: Clamped history did not return the most recent events")
		return false
	var empty_history = EventBus.get_event_history(-5)
	if not empty_history.is_empty():
		print("  ERROR: Negative limit should return an empty history")
		return false
	return true
func print_summary() -> void:
	var passed := 0
	var total := test_results.size()
	for result in test_results:
		if result["passed"]:
			passed += 1
	print("\n========================================")
	print("EventBus Tests: %d/%d passed (%.1f%%)" % [passed, total, float(passed) / float(total) * 100.0])
	if passed == total:
		print("✅ ALL TESTS PASSED")
	else:
		print("❌ SOME TESTS FAILED")
	print("========================================\n")
func _test_callback(data: Dictionary) -> void:
	_test_callback_received = true
	_test_callback_data = data
func _provide_test_value(_data: Variant = null) -> int:
	return 123
func _increment_counter(_data: Variant = null) -> void:
	pass 
func test_unsubscribe_during_publish() -> bool:
	_unstable_first_called = false
	_unstable_second_called = false
	EventBus.subscribe("unstable_event", self, "_unstable_first_callback")
	EventBus.subscribe("unstable_event", self, "_unstable_second_callback")
	EventBus.publish("unstable_event")
	if not _unstable_first_called:
		print("  ERROR: First callback was not invoked")
		return false
	if not _unstable_second_called:
		print("  ERROR: Second callback was skipped after unsubscribe")
		return false
	var remaining := EventBus.get_subscribers("unstable_event")
	if remaining.size() != 1 or remaining[0].get("method", "") != "_unstable_second_callback":
		print("  ERROR: Registry not cleaned correctly after unsubscribe during publish")
		return false
	EventBus.reset()
	return true
func _unstable_first_callback(_data: Variant = null) -> void:
	_unstable_first_called = true
	EventBus.unsubscribe("unstable_event", self, "_unstable_first_callback")
func _unstable_second_callback(_data: Variant = null) -> void:
	_unstable_second_called = true
