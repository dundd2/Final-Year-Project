extends Node
const TEST_NOTIFICATION_SYSTEM = preload("res://1.Codebase/Unit Test/test_notification_system.gd")
const TEST_TOOLTIP_MANAGER = preload("res://1.Codebase/Unit Test/test_tooltip_manager.gd")
const TEST_AI_PROMPT_BUILDER = preload("res://1.Codebase/Unit Test/test_ai_prompt_builder.gd")
const TEST_SCENE_DIRECTIVES_PARSER = preload("res://1.Codebase/Unit Test/test_scene_directives_parser.gd")
func _ready() -> void:
	print("=".repeat(60))
	print("UI COMPONENT TESTS")
	print("=".repeat(60))
	await get_tree().process_frame
	await _run_test("NotificationSystem", TEST_NOTIFICATION_SYSTEM)
	await _run_test("TooltipManager", TEST_TOOLTIP_MANAGER)
	await _run_test("AIPromptBuilder", TEST_AI_PROMPT_BUILDER)
	await _run_test("SceneDirectivesParser", TEST_SCENE_DIRECTIVES_PARSER)
	print("=".repeat(60))
	print("ALL TESTS COMPLETED")
	print("=".repeat(60))
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()
func _run_test(test_name: String, test_script: GDScript) -> void:
	print("\n--- Running %s Tests ---" % test_name)
	var test_instance = test_script.new()
	add_child(test_instance)
	while is_instance_valid(test_instance):
		await get_tree().process_frame
	print("--- %s Tests Completed ---\n" % test_name)
