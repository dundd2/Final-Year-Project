extends Node
const AIPromptBuilderScript = preload("res://1.Codebase/src/scripts/core/ai/ai_prompt_builder.gd")
var prompt_builder: RefCounted = null
var mock_game_state: Dictionary = { }
var mock_asset_registry: Dictionary = { }
var mock_memory_store: Dictionary = { }
func _ready() -> void:
	print("[AIPromptBuilderTest] Starting AIPromptBuilder unit tests...")
	await get_tree().process_frame
	_setup()
	_test_initialization()
	_test_build_basic_prompt()
	_test_language_handling()
	_test_metadata_lines()
	_test_stat_snapshot()
	_test_constants()
	_teardown()
	print("[AIPromptBuilderTest] All tests completed.")
	queue_free()
func _setup() -> void:
	print("[Test Setup] Creating AIPromptBuilder...")
	mock_game_state = {
		"current_language": "en",
		"reality_score": 75,
		"positive_energy": 50,
		"entropy_level": 10,
		"get_recent_event_notes": func(limit, lang): return [],
		"get_recent_journal_entries": func(limit): return [],
		"set_metadata": func(key, value): pass,
		"butterfly_tracker": null,
	}
	mock_asset_registry = {
		"get_assets_for_context": func(context): return [],
		"format_assets_for_prompt": func(assets): return "",
		"get_asset_icons": func(assets): return [],
	}
	mock_memory_store = {
		"get_long_term_context": func(lang): return [],
		"get_notes_context": func(lang): return [],
		"get_short_term_memory": func(): return [],
	}
	prompt_builder = AIPromptBuilderScript.new()
func _teardown() -> void:
	if prompt_builder:
		prompt_builder = null
	mock_game_state.clear()
	mock_asset_registry.clear()
	mock_memory_store.clear()
func _test_initialization() -> void:
	print("[Test] Prompt builder initialization...")
	assert(prompt_builder != null, "Prompt builder should be created")
	assert(prompt_builder.has_method("setup"), "Should have setup method")
	assert(prompt_builder.has_method("build_prompt"), "Should have build_prompt method")
	assert(prompt_builder.has_method("set_system_persona"), "Should have set_system_persona method")
	print("[Test] Initialization PASSED")
func _test_build_basic_prompt() -> void:
	print("[Test] Basic prompt building...")
	if not prompt_builder:
		print("[Test] SKIPPED - Prompt builder not available")
		return
	prompt_builder.setup(null, null, null, null)
	prompt_builder.set_system_persona("Test persona")
	var context := {
		"purpose": "test",
		"reality_score": 75,
		"positive_energy": 50,
		"entropy_level": 10,
	}
	var messages: Array = prompt_builder.build_prompt("Test prompt", context)
	assert(messages is Array, "Should return an Array")
	assert(messages.size() > 0, "Should have at least one message")
	var has_user_message := false
	for msg in messages:
		if msg is Dictionary and msg.get("role") == "user":
			has_user_message = true
			var content: String = str(msg.get("content", ""))
			assert(content.contains("Test prompt"), "Should contain the prompt text")
			break
	assert(has_user_message, "Should have a user message")
	print("[Test] Basic prompt building PASSED")
func _test_language_handling() -> void:
	print("[Test] Language handling...")
	if not prompt_builder:
		print("[Test] SKIPPED - Prompt builder not available")
		return
	var context_en := {
		"purpose": "test_english",
		"reality_score": 50,
	}
	var messages_en: Array = prompt_builder.build_prompt("English test", context_en)
	var user_content_en := _extract_user_content(messages_en)
	assert(user_content_en.contains("English test"), "Should contain English prompt")
	print("[Test] Language handling PASSED")
func _test_metadata_lines() -> void:
	print("[Test] Metadata lines...")
	if not prompt_builder:
		print("[Test] SKIPPED - Prompt builder not available")
		return
	var context := {
		"purpose": "test_purpose",
		"choice_text": "Test choice",
		"success": true,
		"player_action": "Testing",
		"teammate": "TestTeammate",
	}
	var messages: Array = prompt_builder.build_prompt("Test", context)
	var user_content := _extract_user_content(messages)
	assert(user_content.contains("Purpose:") or user_content.contains("Purpose"), "Should include purpose")
	print("[Test] Metadata lines PASSED")
func _test_stat_snapshot() -> void:
	print("[Test] Stat snapshot...")
	if not prompt_builder:
		print("[Test] SKIPPED - Prompt builder not available")
		return
	var context := {
		"reality_score": 75,
		"positive_energy": 60,
		"entropy_level": 25,
	}
	var messages: Array = prompt_builder.build_prompt("Stats test", context)
	var user_content := _extract_user_content(messages)
	assert(user_content.contains("75") or user_content.contains("Reality"), "Should include reality score")
	assert(user_content.contains("60") or user_content.contains("Positive"), "Should include positive energy")
	assert(user_content.contains("25") or user_content.contains("Entropy"), "Should include entropy")
	print("[Test] Stat snapshot PASSED")
func _test_constants() -> void:
	print("[Test] Constants...")
	if not prompt_builder:
		print("[Test] SKIPPED - Prompt builder not available")
		return
	var builder_script = AIPromptBuilderScript
	assert(builder_script.has("MAX_PRAYER_LENGTH"), "Should have MAX_PRAYER_LENGTH constant")
	assert(builder_script.has("MAX_CHOICE_TEXT_PREVIEW"), "Should have MAX_CHOICE_TEXT_PREVIEW constant")
	assert(builder_script.has("MAX_JOURNAL_ENTRIES"), "Should have MAX_JOURNAL_ENTRIES constant")
	assert(builder_script.has("REALITY_SCORE_MAX"), "Should have REALITY_SCORE_MAX constant")
	assert(builder_script.has("POSITIVE_ENERGY_MAX"), "Should have POSITIVE_ENERGY_MAX constant")
	assert(builder_script.MAX_PRAYER_LENGTH == 320, "MAX_PRAYER_LENGTH should be 320")
	assert(builder_script.MAX_CHOICE_TEXT_PREVIEW == 60, "MAX_CHOICE_TEXT_PREVIEW should be 60")
	assert(builder_script.MAX_JOURNAL_ENTRIES == 3, "MAX_JOURNAL_ENTRIES should be 3")
	assert(builder_script.REALITY_SCORE_MAX == 100, "REALITY_SCORE_MAX should be 100")
	assert(builder_script.POSITIVE_ENERGY_MAX == 100, "POSITIVE_ENERGY_MAX should be 100")
	print("[Test] Constants PASSED")
func _extract_user_content(messages: Array) -> String:
	for msg in messages:
		if msg is Dictionary and msg.get("role") == "user":
			return str(msg.get("content", ""))
	return ""
