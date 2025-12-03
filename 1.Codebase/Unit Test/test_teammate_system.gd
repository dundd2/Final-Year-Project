extends Node
var test_system: Node = null
var tests_passed: int = 0
var tests_failed: int = 0
func _ready() -> void:
	print("\n" + "=".repeat(80))
	print("  🧪 TESTING TEAMMATE SYSTEM")
	print("=".repeat(80) + "\n")
	await get_tree().process_frame
	await _test_system_initialization()
	await _test_teammate_data_structure()
	await _test_behavior_library()
	await _test_get_teammate_info()
	await _test_list_teammates()
	await _test_get_behavior_details()
	await _test_trigger_conditions_keywords()
	await _test_trigger_conditions_stat_rules()
	await _test_trigger_conditions_probability()
	await _test_generate_interference_prompt()
	await _test_behavior_description()
	await _test_stat_extraction()
	await _test_meter_descriptions()
	await _test_entropy_descriptions()
	_print_summary()
	await get_tree().create_timer(0.5).timeout
	queue_free()
func _test_system_initialization() -> void:
	print("\n[Test] TeammateSystem initialization...")
	test_system = get_node_or_null("/root/TeammateSystem")
	if test_system == null:
		var TeammateSystemScript = load("res://1.Codebase/src/scripts/core/teammate_system.gd")
		test_system = TeammateSystemScript.new()
		add_child(test_system)
	_assert(test_system != null, "TeammateSystem should exist")
	_assert(test_system.TEAMMATES is Dictionary, "Should have TEAMMATES dictionary")
	_assert(test_system.BEHAVIOR_LIBRARY is Dictionary, "Should have BEHAVIOR_LIBRARY dictionary")
	print("   ✅ PASS: System initialization")
func _test_teammate_data_structure() -> void:
	print("\n[Test] Teammate data structure...")
	_assert(test_system.TEAMMATES.has("gloria"), "Should have Gloria")
	_assert(test_system.TEAMMATES.has("donkey"), "Should have Donkey")
	_assert(test_system.TEAMMATES.has("ark"), "Should have ARK")
	_assert(test_system.TEAMMATES.has("one"), "Should have One")
	var gloria = test_system.TEAMMATES["gloria"]
	_assert(gloria.has("name"), "Gloria should have name")
	_assert(gloria.has("title"), "Gloria should have title")
	_assert(gloria.has("persona"), "Gloria should have persona")
	_assert(gloria.has("color"), "Gloria should have color")
	_assert(gloria.has("base_chance"), "Gloria should have base_chance")
	_assert(gloria.has("trigger_keywords"), "Gloria should have trigger_keywords")
	_assert(gloria.has("trigger_rules"), "Gloria should have trigger_rules")
	_assert(gloria.has("behaviors"), "Gloria should have behaviors")
	_assert(gloria.has("interference_goal"), "Gloria should have interference_goal")
	_assert(gloria.has("tone"), "Gloria should have tone")
	_assert(gloria.has("signature_lines"), "Gloria should have signature_lines")
	_assert(gloria["color"] is Color, "Color should be Color type")
	_assert(gloria["base_chance"] is float, "base_chance should be float")
	_assert(gloria["trigger_keywords"] is Array, "trigger_keywords should be Array")
	_assert(gloria["behaviors"] is Array, "behaviors should be Array")
	_assert(gloria["signature_lines"] is Array, "signature_lines should be Array")
	print("   ✅ PASS: Teammate data structure")
func _test_behavior_library() -> void:
	print("\n[Test] Behavior library...")
	_assert(test_system.BEHAVIOR_LIBRARY.has("moral_blackmail"), "Should have moral_blackmail")
	_assert(test_system.BEHAVIOR_LIBRARY.has("issue_replacement"), "Should have issue_replacement")
	_assert(test_system.BEHAVIOR_LIBRARY.has("divine_protection"), "Should have divine_protection")
	_assert(test_system.BEHAVIOR_LIBRARY.has("heroic_nonsense"), "Should have heroic_nonsense")
	var moral_blackmail = test_system.BEHAVIOR_LIBRARY["moral_blackmail"]
	_assert(moral_blackmail.has("label"), "Behavior should have label")
	_assert(moral_blackmail.has("summary"), "Behavior should have summary")
	_assert(moral_blackmail.has("impact"), "Behavior should have impact")
	_assert(moral_blackmail.has("style"), "Behavior should have style")
	var impact = moral_blackmail["impact"]
	_assert(impact.has("reality"), "Impact should have reality")
	_assert(impact.has("positive"), "Impact should have positive")
	_assert(impact.has("entropy"), "Impact should have entropy")
	print("   ✅ PASS: Behavior library")
func _test_get_teammate_info() -> void:
	print("\n[Test] Get teammate info...")
	var gloria_info = test_system.get_teammate_info("gloria")
	_assert(gloria_info.has("name"), "Should return Gloria's info")
	_assert(gloria_info["name"] == "聖光修女・Gloria", "Gloria name should match")
	var donkey_info = test_system.get_teammate_info("donkey")
	_assert(donkey_info.has("name"), "Should return Donkey's info")
	var empty_info = test_system.get_teammate_info("nonexistent")
	_assert(empty_info.is_empty(), "Should return empty dict for nonexistent teammate")
	print("   ✅ PASS: Get teammate info")
func _test_list_teammates() -> void:
	print("\n[Test] List teammates...")
	var teammate_ids = test_system.list_teammate_ids()
	_assert(teammate_ids is Array, "Should return array")
	_assert(teammate_ids.size() == 4, "Should have 4 teammates")
	_assert("gloria" in teammate_ids, "Should include gloria")
	_assert("donkey" in teammate_ids, "Should include donkey")
	_assert("ark" in teammate_ids, "Should include ark")
	_assert("one" in teammate_ids, "Should include one")
	print("   ✅ PASS: List teammates")
func _test_get_behavior_details() -> void:
	print("\n[Test] Get behavior details...")
	var details = test_system.get_behavior_details("moral_blackmail")
	_assert(details.has("label"), "Should return behavior details")
	_assert(details["label"] == "道德勒索", "Label should match")
	var empty_details = test_system.get_behavior_details("nonexistent_behavior")
	_assert(empty_details.is_empty(), "Should return empty dict for nonexistent behavior")
	print("   ✅ PASS: Get behavior details")
func _test_trigger_conditions_keywords() -> void:
	print("\n[Test] Trigger conditions (keywords)...")
	var mock_state = {
		"reality_score": 50,
		"positive_energy": 50,
		"complaint_counter": 0
	}
	var should_trigger_gloria_logic = test_system.should_trigger_interference(
		"gloria",
		"I have a logic problem with this plan",
		mock_state
	)
	_assert(should_trigger_gloria_logic == true, "Gloria should trigger on 'logic' keyword")
	var should_trigger_gloria_negative = test_system.should_trigger_interference(
		"gloria",
		"This is full of negative energy",
		mock_state
	)
	_assert(should_trigger_gloria_negative == true, "Gloria should trigger on '負能量' keyword")
	var should_trigger_donkey_hero = test_system.should_trigger_interference(
		"donkey",
		"We need a hero to save us",
		mock_state
	)
	_assert(should_trigger_donkey_hero == true, "Donkey should trigger on 'hero' keyword")
	print("   ✅ PASS: Trigger conditions (keywords)")
func _test_trigger_conditions_stat_rules() -> void:
	print("\n[Test] Trigger conditions (stat rules)...")
	var high_complaint_state = {
		"reality_score": 70,
		"positive_energy": 60,
		"complaint_counter": 3  
	}
	var should_trigger = test_system.should_trigger_interference(
		"gloria",
		"normal action",
		high_complaint_state
	)
	_assert(should_trigger == true, "Gloria should trigger when complaint_counter >= 2")
	var low_reality_state = {
		"reality_score": 60,  
		"positive_energy": 40,
		"complaint_counter": 0
	}
	should_trigger = test_system.should_trigger_interference(
		"gloria",
		"normal action",
		low_reality_state
	)
	_assert(should_trigger == true, "Gloria should trigger when reality_score <= 65")
	var ark_trigger_state = {
		"reality_score": 35,  
		"positive_energy": 25,  
		"complaint_counter": 0
	}
	should_trigger = test_system.should_trigger_interference(
		"ark",
		"normal action",
		ark_trigger_state
	)
	_assert(should_trigger == true, "ARK should trigger when reality_score >= 30")
	print("   ✅ PASS: Trigger conditions (stat rules)")
func _test_trigger_conditions_probability() -> void:
	print("\n[Test] Trigger conditions (probability)...")
	var neutral_state = {
		"reality_score": 90,
		"positive_energy": 50,
		"complaint_counter": 0
	}
	var trigger_count = 0
	var iterations = 100
	for i in range(iterations):
		if test_system.should_trigger_interference("gloria", "neutral action", neutral_state):
			trigger_count += 1
	_assert(trigger_count > 20 and trigger_count < 50,
		"Probabilistic triggering should be in expected range (got %d/%d)" % [trigger_count, iterations])
	print("   ✅ PASS: Trigger conditions (probability)")
func _test_generate_interference_prompt() -> void:
	print("\n[Test] Generate interference prompt...")
	var context = {
		"player_action": "I tried to organize a logical plan",
		"reality_score": 55,
		"positive_energy": 40,
		"entropy_level": 15
	}
	var prompt_en = test_system.generate_interference_prompt("gloria", context)
	_assert(prompt_en.length() > 0, "Should generate English prompt")
	_assert(prompt_en.contains("Gloria"), "Prompt should mention Gloria")
	_assert(prompt_en.contains("moral_blackmail") or prompt_en.contains("道德勒索"),
		"Prompt should include behavior")
	_assert(prompt_en.contains("Reality Score"), "Prompt should include reality score")
	var prompt_fallback = test_system.generate_interference_prompt("nonexistent", context)
	_assert(prompt_fallback.length() > 0, "Should generate fallback prompt")
	print("   ✅ PASS: Generate interference prompt")
func _test_behavior_description() -> void:
	print("\n[Test] Behavior description...")
	var description = test_system.get_behavior_description("moral_blackmail")
	_assert(description.length() > 0, "Should return description")
	_assert(description.contains("勒索") or description.contains("blackmail"),
		"Should contain behavior label")
	_assert(description.contains("現實值") or description.contains("Reality"),
		"Should include impact info")
	var unknown_desc = test_system.get_behavior_description("nonexistent")
	_assert(unknown_desc == "Unknown Behavior", "Should return default for unknown behavior")
	print("   ✅ PASS: Behavior description")
func _test_stat_extraction() -> void:
	print("\n[Test] Stat extraction...")
	var dict_source = {"reality_score": 75, "positive_energy": 60}
	var reality = test_system._extract_stat(dict_source, "reality_score", 50)
	_assert(reality == 75, "Should extract from dictionary")
	var missing = test_system._extract_stat(dict_source, "missing_key", 99)
	_assert(missing == 99, "Should return default for missing key")
	var null_result = test_system._extract_stat(null, "any_key", 42)
	_assert(null_result == 42, "Should return default for null source")
	print("   ✅ PASS: Stat extraction")
func _test_meter_descriptions() -> void:
	print("\n[Test] Meter descriptions...")
	var desc_high = test_system._describe_meter(85, true, "en")
	_assert(desc_high.contains("lucid"), "High reality should be lucid")
	var desc_low = test_system._describe_meter(15, true, "en")
	_assert(desc_low.contains("truth") or desc_low.contains("see"), "Low reality should mention truth")
	var desc_overload = test_system._describe_meter(85, false, "en")
	_assert(desc_overload.contains("overload") or desc_overload.contains("toxic"),
		"High positive energy should be toxic")
	var desc_lucid = test_system._describe_meter(15, false, "en")
	_assert(desc_lucid.contains("lucid") or desc_lucid.contains("rational"),
		"Low positive energy should be rational")
	print("   ✅ PASS: Meter descriptions")
func _test_entropy_descriptions() -> void:
	print("\n[Test] Entropy descriptions...")
	var desc_high = test_system._describe_entropy_level(65, "en")
	_assert(desc_high.contains("collapse") or desc_high.contains("brink"),
		"High entropy should mention collapse")
	var desc_medium = test_system._describe_entropy_level(35, "en")
	_assert(desc_medium.contains("rising") or desc_medium.contains("steep"),
		"Medium entropy should mention rising")
	var desc_low = test_system._describe_entropy_level(5, "en")
	_assert(desc_low.contains("calm") or desc_low.contains("fermenting"),
		"Low entropy should mention calm/fermenting")
	print("   ✅ PASS: Entropy descriptions")
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("   ❌ FAIL: %s" % message)
func _print_summary() -> void:
	print("\n" + "=".repeat(80))
	print("  TEST SUMMARY - TeammateSystem")
	print("=".repeat(80))
	print("  Total Tests:   %d" % (tests_passed + tests_failed))
	print("  ✅ Passed:     %d" % tests_passed)
	print("  ❌ Failed:     %d" % tests_failed)
	if tests_failed > 0:
		print("\n  ⚠️  Some tests failed!")
	else:
		print("\n  🎉 All tests passed!")
	print("=".repeat(80) + "\n")
