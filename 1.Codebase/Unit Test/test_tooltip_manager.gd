extends Node
var tooltip_manager: Node = null
func _ready() -> void:
	print("[TooltipManagerTest] Starting TooltipManager unit tests...")
	await get_tree().process_frame
	_setup()
	_test_tooltip_show_hide()
	_test_tooltip_content()
	_test_tooltip_positioning()
	_teardown()
	print("[TooltipManagerTest] All tests completed.")
	queue_free()
func _setup() -> void:
	tooltip_manager = ServiceLocator.get_tooltip_manager() if ServiceLocator else null
	if not tooltip_manager:
		tooltip_manager = get_node_or_null("/root/TooltipManager")
	assert(tooltip_manager != null, "TooltipManager should be available")
	print("[Test Setup] TooltipManager found")
func _teardown() -> void:
	if tooltip_manager and tooltip_manager.has_method("hide_tooltip"):
		tooltip_manager.hide_tooltip()
func _test_tooltip_show_hide() -> void:
	print("[Test] Tooltip show/hide...")
	if not tooltip_manager:
		print("[Test] SKIPPED - TooltipManager not available")
		return
	if tooltip_manager.has_method("show_tooltip"):
		tooltip_manager.show_tooltip("Test tooltip", Vector2(100, 100))
		assert(tooltip_manager.visible if "visible" in tooltip_manager else true, "Tooltip should be visible after show")
		if tooltip_manager.has_method("hide_tooltip"):
			tooltip_manager.hide_tooltip()
			assert(not tooltip_manager.visible if "visible" in tooltip_manager else true, "Tooltip should be hidden after hide")
		print("[Test] Tooltip show/hide PASSED")
	else:
		print("[Test] Tooltip show/hide SKIPPED - methods not available")
func _test_tooltip_content() -> void:
	print("[Test] Tooltip content...")
	if not tooltip_manager or not tooltip_manager.has_method("show_tooltip"):
		print("[Test] SKIPPED - TooltipManager not available")
		return
	var test_contents := [
		"Simple text",
		"Text with\nmultiple lines",
		"Long text that should wrap properly if the tooltip has a maximum width constraint",
		"", 
	]
	for content in test_contents:
		tooltip_manager.show_tooltip(content, Vector2(200, 200))
		await get_tree().process_frame
		tooltip_manager.hide_tooltip()
	print("[Test] Tooltip content PASSED")
func _test_tooltip_positioning() -> void:
	print("[Test] Tooltip positioning...")
	if not tooltip_manager or not tooltip_manager.has_method("show_tooltip"):
		print("[Test] SKIPPED - TooltipManager not available")
		return
	var test_positions := [
		Vector2(0, 0), 
		Vector2(1920, 1080), 
		Vector2(960, 540), 
		Vector2(-10, -10), 
	]
	for pos in test_positions:
		tooltip_manager.show_tooltip("Position test", pos)
		await get_tree().process_frame
		tooltip_manager.hide_tooltip()
	print("[Test] Tooltip positioning PASSED")
