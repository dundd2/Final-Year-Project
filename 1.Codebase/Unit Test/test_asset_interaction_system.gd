extends Node
var test_system: Node = null
var tests_passed: int = 0
var tests_failed: int = 0
func _ready() -> void:
	print("\n" + "=".repeat(80))
	print("  🧪 TESTING ASSET INTERACTION SYSTEM")
	print("=".repeat(80) + "\n")
	await get_tree().process_frame
	await _test_system_initialization()
	await _test_action_types()
	await _test_set_asset_context()
	await _test_get_available_actions()
	await _test_perform_action_success()
	await _test_perform_action_failure()
	await _test_condition_evaluation()
	await _test_stat_value_comparison()
	await _test_interaction_history()
	await _test_clear_asset_rules()
	await _test_puzzle_generation_request()
	await _test_invalid_asset_handling()
	await _test_invalid_action_handling()
	_print_summary()
	await get_tree().create_timer(0.5).timeout
	queue_free()
func _test_system_initialization() -> void:
	print("\n[Test] AssetInteractionSystem initialization...")
	test_system = get_node_or_null("/root/AssetInteractionSystem")
	if test_system == null:
		var AssetInteractionScript = load("res://1.Codebase/src/scripts/core/asset_interaction_system.gd")
		test_system = AssetInteractionScript.new()
		add_child(test_system)
	_assert(test_system != null, "AssetInteractionSystem should exist")
	_assert(test_system.current_asset_rules is Dictionary, "Should have asset rules dictionary")
	_assert(test_system.available_actions is Array, "Should have available actions array")
	_assert(test_system.interaction_history is Array, "Should have interaction history array")
	print("   ✅ PASS: System initialization")
func _test_action_types() -> void:
	print("\n[Test] Action types...")
	_assert(test_system.ACTION_TYPES.has("USE"), "Should have USE action")
	_assert(test_system.ACTION_TYPES.has("SPEAK"), "Should have SPEAK action")
	_assert(test_system.ACTION_TYPES.has("EXAMINE"), "Should have EXAMINE action")
	_assert(test_system.ACTION_TYPES.has("GIVE"), "Should have GIVE action")
	_assert(test_system.ACTION_TYPES.has("ACTIVATE"), "Should have ACTIVATE action")
	_assert(test_system.ACTION_TYPES.has("PACIFY"), "Should have PACIFY action")
	_assert(test_system.ACTION_TYPES.has("CHALLENGE"), "Should have CHALLENGE action")
	_assert(test_system.ACTION_TYPES.has("EMPATHIZE"), "Should have EMPATHIZE action")
	_assert(test_system.ACTION_TYPES.has("IGNORE"), "Should have IGNORE action")
	_assert(test_system.ACTION_TYPES.has("PRAY"), "Should have PRAY action")
	var use_action = test_system.ACTION_TYPES["USE"]
	_assert(use_action.has("name"), "Action should have name")
	_assert(use_action.has("icon"), "Action should have icon")
	_assert(use_action["name"] == "Use", "USE action name should be 'Use'")
	print("   ✅ PASS: Action types")
func _test_set_asset_context() -> void:
	print("\n[Test] Set asset context...")
	test_system.clear_asset_rules()
	var test_rules = {
		"description": "A mysterious glowing plant",
		"ai_lore": "The plant whispers secrets",
		"available_actions": ["EXAMINE", "USE", "PRAY"],
		"success_conditions": {
			"USE": {
				"type": "always",
				"success_text": "You harvest the plant's essence",
				"stat_changes": {"positive_energy": 10}
			}
		},
		"failure_outcomes": {},
		"required_assets": [],
		"puzzle_solution": ""
	}
	test_system.set_asset_context("Glowing_Plant", test_rules)
	_assert(test_system.current_asset_rules.has("Glowing_Plant"),
		"Should store asset rules")
	_assert(test_system.current_asset_rules["Glowing_Plant"]["description"] == "A mysterious glowing plant",
		"Should store description")
	_assert(test_system.current_asset_rules["Glowing_Plant"]["available_actions"].size() == 3,
		"Should store available actions")
	_assert("EXAMINE" in test_system.current_asset_rules["Glowing_Plant"]["available_actions"],
		"Should include EXAMINE action")
	print("   ✅ PASS: Set asset context")
func _test_get_available_actions() -> void:
	print("\n[Test] Get available actions...")
	test_system.set_asset_context("Test_Monster", {
		"available_actions": ["SPEAK", "CHALLENGE", "PACIFY"]
	})
	var actions = test_system.get_available_actions_for_asset("Test_Monster")
	_assert(actions.size() == 3, "Should return 3 actions")
	_assert(actions[0].has("id"), "Action should have id")
	_assert(actions[0].has("name"), "Action should have name")
	_assert(actions[0].has("icon"), "Action should have icon")
	_assert(actions[0].has("asset_id"), "Action should have asset_id")
	_assert(actions[0]["asset_id"] == "Test_Monster", "Asset ID should match")
	var no_actions = test_system.get_available_actions_for_asset("NonExistent")
	_assert(no_actions.size() == 0, "Non-existent asset should return empty array")
	print("   ✅ PASS: Get available actions")
func _test_perform_action_success() -> void:
	print("\n[Test] Perform action (success)...")
	test_system.set_asset_context("Magic_Door", {
		"available_actions": ["ACTIVATE"],
		"success_conditions": {
			"ACTIVATE": {
				"type": "always",
				"success_text": "The door opens with a magical glow!",
				"stat_changes": {"reality": 5},
				"unlocks": ["Secret_Room"],
				"narrative": "You've discovered a hidden passage"
			}
		}
	})
	var result = test_system.perform_action("Magic_Door", "ACTIVATE")
	_assert(result.has("success"), "Result should have success field")
	_assert(result["success"] == true, "Action should succeed")
	_assert(result.has("outcome_text"), "Result should have outcome text")
	_assert(result["outcome_text"].contains("magical glow"), "Should use success text")
	_assert(result.has("stat_changes"), "Result should have stat changes")
	_assert(result["stat_changes"].has("reality"), "Should include reality stat change")
	_assert(result.has("new_assets_unlocked"), "Result should have unlocks")
	_assert("Secret_Room" in result["new_assets_unlocked"], "Should unlock Secret_Room")
	_assert(result["narrative_consequence"].length() > 0, "Should have narrative consequence")
	print("   ✅ PASS: Perform action (success)")
func _test_perform_action_failure() -> void:
	print("\n[Test] Perform action (failure)...")
	test_system.set_asset_context("Locked_Chest", {
		"available_actions": ["ACTIVATE"],
		"success_conditions": {
			"ACTIVATE": {
				"type": "has_item",
				"item": "Golden_Key",
				"success_text": "The chest opens!",
				"failure_text": "The chest remains locked"
			}
		},
		"failure_outcomes": {
			"ACTIVATE": {
				"failure_text": "You need a key to open this chest",
				"stat_changes": {"entropy": 2},
				"narrative": "Your frustration grows"
			}
		}
	})
	var result = test_system.perform_action("Locked_Chest", "ACTIVATE", {"has_items": []})
	_assert(result["success"] == false, "Action should fail without key")
	_assert(result["outcome_text"].contains("key"), "Should mention key requirement")
	print("   ✅ PASS: Perform action (failure)")
func _test_condition_evaluation() -> void:
	print("\n[Test] Condition evaluation...")
	var always_condition = {"type": "always"}
	var result_always = test_system._evaluate_condition(always_condition, {})
	_assert(result_always == true, "Always condition should return true")
	var has_item_condition = {"type": "has_item", "item": "Magic_Sword"}
	var result_with_item = test_system._evaluate_condition(has_item_condition,
		{"has_items": ["Magic_Sword", "Shield"]})
	_assert(result_with_item == true, "Should return true when item present")
	var result_without_item = test_system._evaluate_condition(has_item_condition,
		{"has_items": ["Shield"]})
	_assert(result_without_item == false, "Should return false when item missing")
	var nearby_condition = {"type": "nearby_asset", "asset": "Campfire"}
	var result_nearby = test_system._evaluate_condition(nearby_condition,
		{"nearby_assets": ["Campfire", "Tree"]})
	_assert(result_nearby == true, "Should return true when asset nearby")
	var result_not_nearby = test_system._evaluate_condition(nearby_condition,
		{"nearby_assets": ["Tree"]})
	_assert(result_not_nearby == false, "Should return false when asset not nearby")
	var unknown_condition = {"type": "unknown_type"}
	var result_unknown = test_system._evaluate_condition(unknown_condition, {})
	_assert(result_unknown == false, "Unknown condition type should return false")
	print("   ✅ PASS: Condition evaluation")
func _test_stat_value_comparison() -> void:
	print("\n[Test] Stat value comparison...")
	_assert(test_system._compare_values(50, 30, ">=") == true, ">= should work (50 >= 30)")
	_assert(test_system._compare_values(30, 50, ">=") == false, ">= should work (30 >= 50)")
	_assert(test_system._compare_values(50, 30, ">") == true, "> should work")
	_assert(test_system._compare_values(50, 50, ">") == false, "> should work (equal)")
	_assert(test_system._compare_values(30, 50, "<=") == true, "<= should work")
	_assert(test_system._compare_values(30, 50, "<") == true, "< should work")
	_assert(test_system._compare_values(50, 50, "==") == true, "== should work")
	_assert(test_system._compare_values(50, 30, "==") == false, "== should work (not equal)")
	_assert(test_system._compare_values(50, 30, "!=") == true, "!= should work")
	_assert(test_system._compare_values(50, 50, "!=") == false, "!= should work (equal)")
	_assert(test_system._compare_values(50, 30, "???") == false, "Invalid operator should return false")
	print("   ✅ PASS: Stat value comparison")
func _test_interaction_history() -> void:
	print("\n[Test] Interaction history...")
	test_system.interaction_history.clear()
	test_system.set_asset_context("History_Test", {
		"available_actions": ["USE"],
		"success_conditions": {"USE": {"type": "always"}}
	})
	var initial_count = test_system.interaction_history.size()
	test_system.perform_action("History_Test", "USE")
	_assert(test_system.interaction_history.size() == initial_count + 1,
		"History should record interaction")
	var last_interaction = test_system.interaction_history[test_system.interaction_history.size() - 1]
	_assert(last_interaction.has("timestamp"), "History entry should have timestamp")
	_assert(last_interaction.has("asset_id"), "History entry should have asset_id")
	_assert(last_interaction.has("action_id"), "History entry should have action_id")
	_assert(last_interaction.has("success"), "History entry should have success")
	_assert(last_interaction["asset_id"] == "History_Test", "Asset ID should match")
	_assert(last_interaction["action_id"] == "USE", "Action ID should match")
	var history_copy = test_system.get_interaction_history()
	_assert(history_copy.size() == test_system.interaction_history.size(),
		"get_interaction_history should return copy of history")
	print("   ✅ PASS: Interaction history")
func _test_clear_asset_rules() -> void:
	print("\n[Test] Clear asset rules...")
	test_system.set_asset_context("Asset1", {"available_actions": ["USE"]})
	test_system.set_asset_context("Asset2", {"available_actions": ["SPEAK"]})
	_assert(test_system.current_asset_rules.size() >= 2, "Should have at least 2 assets")
	test_system.clear_asset_rules()
	_assert(test_system.current_asset_rules.size() == 0, "Rules should be cleared")
	_assert(test_system.available_actions.size() == 0, "Available actions should be cleared")
	print("   ✅ PASS: Clear asset rules")
func _test_puzzle_generation_request() -> void:
	print("\n[Test] Puzzle generation request...")
	var puzzle_data = test_system.generate_puzzle_from_assets(
		["Magic_Stone", "Ancient_Tree", "Crystal_Pool"],
		"medium"
	)
	_assert(puzzle_data.has("assets"), "Puzzle data should have assets")
	_assert(puzzle_data.has("difficulty"), "Puzzle data should have difficulty")
	_assert(puzzle_data.has("generated"), "Puzzle data should have generated flag")
	_assert(puzzle_data["difficulty"] == "medium", "Difficulty should match")
	_assert(puzzle_data["assets"].size() == 3, "Should have 3 assets")
	var empty_puzzle = test_system.generate_puzzle_from_assets([], "easy")
	_assert(empty_puzzle["assets"].size() == 0, "Empty array should result in empty assets")
	var dedup_puzzle = test_system.generate_puzzle_from_assets(
		["Stone", "Stone", "Tree"],
		"hard"
	)
	_assert(dedup_puzzle["assets"].size() == 2, "Should deduplicate assets")
	print("   ✅ PASS: Puzzle generation request")
func _test_invalid_asset_handling() -> void:
	print("\n[Test] Invalid asset handling...")
	var result = test_system.perform_action("NonExistent_Asset", "USE")
	_assert(result.has("success"), "Result should have success field")
	_assert(result["success"] == false, "Should fail for non-existent asset")
	_assert(result.has("error"), "Result should have error field")
	_assert(result["error"] == "Asset not found", "Error should indicate asset not found")
	print("   ✅ PASS: Invalid asset handling")
func _test_invalid_action_handling() -> void:
	print("\n[Test] Invalid action handling...")
	test_system.set_asset_context("Limited_Asset", {
		"available_actions": ["EXAMINE"]
	})
	var result = test_system.perform_action("Limited_Asset", "CHALLENGE")
	_assert(result["success"] == false, "Should fail for unavailable action")
	_assert(result["outcome_text"].contains("cannot perform"), "Should explain action unavailable")
	print("   ✅ PASS: Invalid action handling")
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("   ❌ FAIL: %s" % message)
func _print_summary() -> void:
	print("\n" + "=".repeat(80))
	print("  TEST SUMMARY - AssetInteractionSystem")
	print("=".repeat(80))
	print("  Total Tests:   %d" % (tests_passed + tests_failed))
	print("  ✅ Passed:     %d" % tests_passed)
	print("  ❌ Failed:     %d" % tests_failed)
	if tests_failed > 0:
		print("\n  ⚠️  Some tests failed!")
	else:
		print("\n  🎉 All tests passed!")
	print("=".repeat(80) + "\n")
