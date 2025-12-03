extends Node
const TrolleyGeneratorScript = preload("res://1.Codebase/src/scripts/core/trolley_problem_generator.gd")
var generator: Node
var mock_teammate_system: MockTeammateSystem
var mock_achievement_system: MockAchievementSystem
func _ready() -> void:
	print("[TrolleyProblemGeneratorTest] Starting unit tests...")
	await get_tree().process_frame
	_setup()
	_test_initialization()
	_test_json_parsing_valid()
	_test_json_parsing_markdown()
	_test_json_parsing_invalid()
	_test_dilemma_resolution()
	_test_preset_generation()
	_teardown()
	print("[TrolleyProblemGeneratorTest] All tests completed.")
	queue_free()
func _setup() -> void:
	print("[Test Setup] Creating TrolleyProblemGenerator...")
	generator = TrolleyGeneratorScript.new()
	add_child(generator)
	mock_teammate_system = MockTeammateSystem.new()
	mock_achievement_system = MockAchievementSystem.new()
	if ServiceLocator:
		ServiceLocator.register_service("TeammateSystem", mock_teammate_system)
		ServiceLocator.register_service("AchievementSystem", mock_achievement_system)
func _teardown() -> void:
	if generator:
		generator.queue_free()
		generator = null
	if ServiceLocator:
		ServiceLocator.unregister_service("TeammateSystem")
		ServiceLocator.unregister_service("AchievementSystem")
func _test_initialization() -> void:
	print("[Test] Initialization...")
	assert(generator != null, "Generator should be created")
	assert(generator.has_signal("dilemma_generated"), "Should have signal dilemma_generated")
	assert(generator.has_signal("dilemma_resolved"), "Should have signal dilemma_resolved")
	print("[Test] Initialization PASSED")
func _test_json_parsing_valid() -> void:
	print("[Test] Valid JSON parsing...")
	var valid_json = """
	{
		"scenario": "Test scenario",
		"choices": [
			{
				"id": "c1",
				"text": "Choice 1",
				"framing": "honest",
				"immediate_consequence": "Bad things",
				"long_term_consequence": "Worse things",
				"stat_changes": {"reality": -5},
				"relationship_changes": [{"target": "gloria", "value": -10}]
			},
			{
				"id": "c2",
				"text": "Choice 2",
				"framing": "positive",
				"immediate_consequence": "Good things?",
				"long_term_consequence": "No.",
				"stat_changes": {"reality": 5}
			}
		],
		"thematic_point": "Life is hard"
	}
	"""
	var data = generator._parse_dilemma_json(valid_json)
	assert(data.has("scenario"), "Should parse scenario")
	assert(data.scenario == "Test scenario", "Scenario text match")
	assert(data.choices.size() == 2, "Should parse 2 choices")
	assert(data.choices[0].id == "c1", "Choice 1 ID match")
	assert(data.choices[0].relationship_changes[0].target == "gloria", "Relationship target match")
	assert(data.thematic_point == "Life is hard", "Theme match")
	print("[Test] Valid JSON parsing PASSED")
func _test_json_parsing_markdown() -> void:
	print("[Test] Markdown JSON parsing...")
	var markdown_json = """
	Here is the dilemma:
	```json
	{
		"scenario": "Markdown scenario",
		"choices": [
			{
				"id": "m1",
				"text": "Markdown Choice",
				"framing": "neutral",
				"immediate_consequence": "Markdown",
				"long_term_consequence": "Markdown",
				"stat_changes": {}
			},
            {
				"id": "m2",
				"text": "Markdown Choice 2",
				"framing": "neutral",
				"immediate_consequence": "Markdown",
				"long_term_consequence": "Markdown",
				"stat_changes": {}
			}
		],
		"thematic_point": "Code blocks work"
	}
	```
	End of text.
	"""
	var data = generator._parse_dilemma_json(markdown_json)
	assert(not data.is_empty(), "Should parse from markdown")
	assert(data.scenario == "Markdown scenario", "Scenario match")
	assert(data.choices.size() == 2, "Choices count match")
	print("[Test] Markdown JSON parsing PASSED")
func _test_json_parsing_invalid() -> void:
	print("[Test] Invalid JSON parsing...")
	var invalid_json = "{ broken json }"
	var data = generator._parse_dilemma_json(invalid_json)
	assert(data.is_empty(), "Should return empty dict for invalid JSON")
	var empty_str = ""
	data = generator._parse_dilemma_json(empty_str)
	assert(data.is_empty(), "Should return empty dict for empty string")
	print("[Test] Invalid JSON parsing PASSED")
func _test_dilemma_resolution() -> void:
	print("[Test] Dilemma resolution...")
	var dilemma = {
		"template_type": "test",
		"scenario": "Test",
		"choices": [
			{
				"id": "resolve_test",
				"text": "Resolve Me",
				"framing": "test",
				"immediate_consequence": "Done",
				"long_term_consequence": "Really done",
				"stat_changes": {"reality": -10},
				"relationship_changes": [
					{"target": "mock_char", "value": 5, "status": "Happy"}
				]
			}
		],
		"thematic_point": "Testing"
	}
	generator.current_dilemma = dilemma
	var signal_emitted = false
	var _on_resolved = func(id, res):
		signal_emitted = true
		assert(id == "resolve_test", "Signal ID match")
	generator.dilemma_resolved.connect(_on_resolved)
	var result = generator.resolve_dilemma("resolve_test")
	assert(not result.is_empty(), "Should return resolution result")
	assert(result.choice_id == "resolve_test", "Result ID match")
	assert(signal_emitted, "Signal should be emitted")
	assert(mock_teammate_system.last_update.target == "mock_char", "Teammate system updated")
	assert(mock_achievement_system.dilemma_resolved_called, "Achievement system called")
	var history = generator.get_dilemma_history()
	assert(history.size() > 0, "History updated")
	assert(history[0].choice_id == "resolve_test", "History content match")
	assert(generator.current_dilemma.is_empty(), "Current dilemma cleared")
	print("[Test] Dilemma resolution PASSED")
func _test_preset_generation() -> void:
	print("[Test] Preset generation...")
	var generated = false
	var _on_generated = func(dilemma):
		generated = true
		assert(dilemma.has("preset"), "Should be marked as preset")
	generator.dilemma_generated.connect(_on_generated)
	generator._generate_preset_dilemma("positive_energy_trap")
	assert(generated, "Should generate preset")
	assert(not generator.current_dilemma.is_empty(), "Current dilemma populated")
	assert(generator.current_dilemma.template_type == "positive_energy_trap", "Template type match")
	print("[Test] Preset generation PASSED")
class MockTeammateSystem extends RefCounted:
	var last_update = {}
	func update_relationship(source, target, status, value):
		if source == "player":
			last_update = {"target": target, "value": value}
class MockAchievementSystem extends RefCounted:
	var dilemma_resolved_called = false
	func check_dilemma_resolved():
		dilemma_resolved_called = true
