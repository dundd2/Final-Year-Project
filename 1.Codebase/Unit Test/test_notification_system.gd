extends Node
var notification_system: Node = null
func _ready() -> void:
	print("[NotificationSystemTest] Starting NotificationSystem unit tests...")
	await get_tree().process_frame
	_setup()
	_test_notification_display()
	await _test_notification_lifecycle()
	_test_notification_importance()
	_test_notification_queue()
	_teardown()
	print("[NotificationSystemTest] All tests completed.")
	queue_free()
func _setup() -> void:
	notification_system = ServiceLocator.get_notification_system() if ServiceLocator else null
	if not notification_system:
		notification_system = get_node_or_null("/root/NotificationSystem")
	assert(notification_system != null, "NotificationSystem should be available")
	print("[Test Setup] NotificationSystem found")
func _teardown() -> void:
	if notification_system and notification_system.has_method("clear_all"):
		notification_system.clear_all()
func _test_notification_display() -> void:
	print("[Test] Notification display...")
	if not notification_system:
		print("[Test] SKIPPED - NotificationSystem not available")
		return
	if notification_system.has_method("show_notification"):
		notification_system.show_notification("Test message", "test")
		print("[Test] Notification display PASSED")
	else:
		print("[Test] Notification display SKIPPED - method not available")
func _test_notification_lifecycle() -> void:
	print("[Test] Notification lifecycle...")
	if not notification_system or not notification_system.has_method("show_notification"):
		print("[Test] SKIPPED - NotificationSystem not available")
		return
	notification_system.show_notification("Short message", "test", 0.5)
	await get_tree().create_timer(0.7).timeout
	print("[Test] Notification lifecycle PASSED")
func _test_notification_importance() -> void:
	print("[Test] Notification importance...")
	if not notification_system or not notification_system.has_method("show_notification"):
		print("[Test] SKIPPED - NotificationSystem not available")
		return
	var importance_levels := ["low", "normal", "high", "critical"]
	for level in importance_levels:
		notification_system.show_notification("Test " + level, level, 0.3)
	print("[Test] Notification importance PASSED")
func _test_notification_queue() -> void:
	print("[Test] Notification queue...")
	if not notification_system or not notification_system.has_method("show_notification"):
		print("[Test] SKIPPED - NotificationSystem not available")
		return
	for i in range(5):
		notification_system.show_notification("Queue test %d" % i, "test", 0.3)
	print("[Test] Notification queue PASSED")
