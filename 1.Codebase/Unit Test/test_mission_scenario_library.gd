extends Node
const Library = preload("res://1.Codebase/src/scripts/core/mission_scenario_library.gd")
func _ready() -> void:
	print("[MissionScenarioLibraryTest] Starting unit tests...")
	await get_tree().process_frame
	_test_has_scenarios()
	_test_get_random_scenario()
	_test_scenario_structure()
	_test_helper_functions()
	print("[MissionScenarioLibraryTest] All tests completed.")
	queue_free()
func _test_has_scenarios() -> void:
	print("[Test] Has scenarios...")
	assert(Library.has_scenarios(), "Library should have scenarios")
	print("[Test] Has scenarios PASSED")
func _test_get_random_scenario() -> void:
	print("[Test] Get random scenario...")
	for i in range(10):
		var scenario = Library.get_random_scenario()
		assert(not scenario.is_empty(), "Should return a non-empty scenario")
		assert(scenario.has("id"), "Scenario should have ID")
		assert(scenario.has("assets"), "Scenario should have assets")
		assert(scenario.has("fallback"), "Scenario should have fallback data")
	print("[Test] Get random scenario PASSED")
func _test_scenario_structure() -> void:
	print("[Test] Scenario structure validation...")
	for scenario in Library.SCENARIOS:
		assert(scenario.has("id") and scenario.id is String, "ID validation")
		assert(scenario.has("assets") and scenario.assets is Array, "Assets validation")
		assert(scenario.has("translation_keys") and scenario.translation_keys is Dictionary, "Translation keys validation")
		var fallback = scenario.get("fallback", {})
		assert(not fallback.is_empty(), "Fallback validation")
		assert(fallback.has("title"), "Fallback title")
		assert(fallback.has("description"), "Fallback description")
		assert(fallback.has("choices") and fallback.choices is Array, "Fallback choices")
		assert(fallback.choices.size() >= 2, "Should have at least 2 choices")
	print("[Test] Scenario structure validation PASSED")
func _test_helper_functions() -> void:
	print("[Test] Helper functions...")
	var context_en = {"language": "en"}
	var lang_en = Library._resolve_language(context_en)
	assert(lang_en == "en", "Should resolve en")
	var context_zh = {"language": "zh"}
	var lang_zh = Library._resolve_language(context_zh)
	assert(lang_zh == "zh", "Should resolve zh")
	var context_empty = {}
	var lang_default = Library._resolve_language(context_empty)
	assert(lang_default == "en", "Should default to en")
	print("[Test] Helper functions PASSED")
