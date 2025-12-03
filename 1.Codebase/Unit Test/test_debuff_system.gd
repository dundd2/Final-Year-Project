extends Node
var DebuffSystemScript = preload("res://1.Codebase/src/scripts/core/debuff_system.gd")
var GameConstants = preload("res://1.Codebase/src/scripts/core/game_constants.gd")
var _debuff_system = null
var _test_results = []
func _ready():
	print("\n" + "=".repeat(80))
	print("🧪 DEBUFF SYSTEM TEST SUITE")
	print("=".repeat(80) + "\n")
	await run_all_tests()
	print_summary()
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()
func run_all_tests():
	await run_test("Initialization", test_initialization)
	await run_test("Adding Debuffs", test_add_debuff)
	await run_test("Processing Debuff Expiration", test_process_debuffs)
	await run_test("Cognitive Dissonance Handling", test_cognitive_dissonance)
	await run_test("Debuff Queries", test_debuff_queries)
	await run_test("Save/Load Functionality", test_save_load)
	await run_test("Reset Functionality", test_reset)
func run_test(test_name: String, test_func: Callable):
	_debuff_system = DebuffSystemScript.new()
	var result = await test_func.call()
	_test_results.append({ "name": test_name, "passed": result })
	if result:
		print("  ✅ %s" % test_name)
	else:
		print("  ❌ %s FAILED" % test_name)
func assert_equal(actual, expected, message: String = "") -> bool:
	if actual != expected:
		if message:
			print("    ⚠️  %s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
func assert_true(condition: bool, message: String = "") -> bool:
	if not condition:
		if message:
			print("    ⚠️  %s" % message)
		return false
	return true
func test_initialization() -> bool:
	var success = true
	success = assert_equal(_debuff_system.active_debuffs.size(), 0, "No initial debuffs") and success
	success = assert_equal(_debuff_system.cognitive_dissonance_active, false, "CD inactive initially") and success
	success = assert_equal(_debuff_system.cognitive_dissonance_choices_left, 0, "No CD choices initially") and success
	return success
func test_add_debuff() -> bool:
	var success = true
	_debuff_system.add_debuff("疲勞", 3, "Logic checks -2")
	success = assert_equal(_debuff_system.active_debuffs.size(), 1, "One debuff added") and success
	success = assert_equal(_debuff_system.active_debuffs[0]["name"], "疲勞", "Debuff name correct") and success
	success = assert_equal(_debuff_system.active_debuffs[0]["duration"], 3, "Debuff duration correct") and success
	success = assert_equal(_debuff_system.active_debuffs[0]["effect"], "Logic checks -2", "Debuff effect correct") and success
	_debuff_system.add_debuff("焦慮", 2, "Composure -1")
	success = assert_equal(_debuff_system.active_debuffs.size(), 2, "Two debuffs active") and success
	_debuff_system.add_debuff(
		GameConstants.Debuffs.COGNITIVE_DISSONANCE_NAME,
		5,
		"Logic checks -3"
	)
	success = assert_equal(_debuff_system.active_debuffs.size(), 3, "Three debuffs active") and success
	success = assert_equal(_debuff_system.cognitive_dissonance_active, true, "CD activated") and success
	success = assert_equal(_debuff_system.cognitive_dissonance_choices_left, 5, "CD choices set") and success
	return success
func test_process_debuffs() -> bool:
	var success = true
	_debuff_system.add_debuff("短期", 1, "Effect A")
	_debuff_system.add_debuff("中期", 3, "Effect B")
	_debuff_system.add_debuff("長期", 5, "Effect C")
	_debuff_system.process_debuffs()
	success = assert_equal(_debuff_system.active_debuffs.size(), 2, "One debuff expired") and success
	success = assert_equal(_debuff_system.active_debuffs[0]["duration"], 2, "中期 duration decreased") and success
	success = assert_equal(_debuff_system.active_debuffs[1]["duration"], 4, "長期 duration decreased") and success
	_debuff_system.process_debuffs()
	success = assert_equal(_debuff_system.active_debuffs.size(), 2, "No more expired yet") and success
	_debuff_system.process_debuffs() 
	success = assert_equal(_debuff_system.active_debuffs.size(), 1, "中期 expired") and success
	_debuff_system.process_debuffs() 
	_debuff_system.process_debuffs() 
	success = assert_equal(_debuff_system.active_debuffs.size(), 0, "All debuffs expired") and success
	return success
func test_cognitive_dissonance() -> bool:
	var success = true
	_debuff_system.add_debuff(
		GameConstants.Debuffs.COGNITIVE_DISSONANCE_NAME,
		3,
		"Logic -3"
	)
	success = assert_equal(_debuff_system.cognitive_dissonance_active, true, "CD active") and success
	success = assert_equal(_debuff_system.cognitive_dissonance_choices_left, 3, "CD choices = 3") and success
	_debuff_system.use_cognitive_dissonance_choice()
	success = assert_equal(_debuff_system.cognitive_dissonance_choices_left, 2, "CD choices = 2") and success
	success = assert_equal(_debuff_system.cognitive_dissonance_active, true, "CD still active") and success
	_debuff_system.use_cognitive_dissonance_choice()
	_debuff_system.use_cognitive_dissonance_choice()
	success = assert_equal(_debuff_system.cognitive_dissonance_choices_left, 0, "CD choices = 0") and success
	success = assert_equal(_debuff_system.cognitive_dissonance_active, false, "CD deactivated") and success
	_debuff_system.add_debuff(
		GameConstants.Debuffs.COGNITIVE_DISSONANCE_NAME,
		2,
		"Logic -3"
	)
	success = assert_equal(_debuff_system.cognitive_dissonance_active, true, "CD re-activated") and success
	_debuff_system.process_debuffs() 
	success = assert_equal(_debuff_system.cognitive_dissonance_active, true, "CD still active after 1 process") and success
	_debuff_system.process_debuffs() 
	success = assert_equal(_debuff_system.cognitive_dissonance_active, false, "CD deactivated on expiration") and success
	success = assert_equal(_debuff_system.active_debuffs.size(), 0, "CD debuff removed") and success
	return success
func test_debuff_queries() -> bool:
	var success = true
	_debuff_system.add_debuff("疲勞", 3, "Effect A")
	_debuff_system.add_debuff("焦慮", 2, "Effect B")
	_debuff_system.add_debuff(
		GameConstants.Debuffs.COGNITIVE_DISSONANCE_NAME,
		5,
		"Effect C"
	)
	success = assert_equal(_debuff_system.has_debuff("疲勞"), true, "Has 疲勞") and success
	success = assert_equal(_debuff_system.has_debuff("焦慮"), true, "Has 焦慮") and success
	success = assert_equal(_debuff_system.has_debuff("不存在"), false, "Doesn't have 不存在") and success
	var debuffs = _debuff_system.get_active_debuffs()
	success = assert_equal(debuffs.size(), 3, "Get all 3 debuffs") and success
	success = assert_true(debuffs is Array, "Returns array") and success
	var fatigue = _debuff_system.get_debuff("疲勞")
	success = assert_equal(fatigue["name"], "疲勞", "Get specific debuff name") and success
	success = assert_equal(fatigue["duration"], 3, "Get specific debuff duration") and success
	var nonexistent = _debuff_system.get_debuff("不存在")
	success = assert_equal(nonexistent.is_empty(), true, "Non-existent debuff returns empty") and success
	return success
func test_save_load() -> bool:
	var success = true
	_debuff_system.add_debuff("疲勞", 3, "Effect A")
	_debuff_system.add_debuff(
		GameConstants.Debuffs.COGNITIVE_DISSONANCE_NAME,
		5,
		"Logic -3"
	)
	_debuff_system.use_cognitive_dissonance_choice()
	var save_data = _debuff_system.get_save_data()
	success = assert_true(save_data.has("active_debuffs"), "Save has active_debuffs") and success
	success = assert_true(save_data.has("cognitive_dissonance_active"), "Save has CD active") and success
	success = assert_true(save_data.has("cognitive_dissonance_choices_left"), "Save has CD choices") and success
	var new_system = DebuffSystemScript.new()
	new_system.load_save_data(save_data)
	success = assert_equal(new_system.active_debuffs.size(), 2, "Loaded 2 debuffs") and success
	success = assert_equal(new_system.cognitive_dissonance_active, true, "Loaded CD active") and success
	success = assert_equal(new_system.cognitive_dissonance_choices_left, 4, "Loaded CD choices") and success
	success = assert_equal(new_system.has_debuff("疲勞"), true, "Loaded 疲勞 debuff") and success
	success = assert_equal(
		new_system.has_debuff(GameConstants.Debuffs.COGNITIVE_DISSONANCE_NAME),
		true,
		"Loaded CD debuff"
	) and success
	return success
func test_reset() -> bool:
	var success = true
	_debuff_system.add_debuff("疲勞", 3, "Effect A")
	_debuff_system.add_debuff(
		GameConstants.Debuffs.COGNITIVE_DISSONANCE_NAME,
		5,
		"Logic -3"
	)
	_debuff_system.reset()
	success = assert_equal(_debuff_system.active_debuffs.size(), 0, "All debuffs cleared") and success
	success = assert_equal(_debuff_system.cognitive_dissonance_active, false, "CD deactivated") and success
	success = assert_equal(_debuff_system.cognitive_dissonance_choices_left, 0, "CD choices reset") and success
	return success
func print_summary():
	print("\n" + "=".repeat(80))
	var passed = _test_results.filter(func(r): return r.passed).size()
	var total = _test_results.size()
	if passed == total:
		print("✅ ALL TESTS PASSED (%d/%d)" % [passed, total])
	else:
		print("❌ SOME TESTS FAILED (%d/%d passed)" % [passed, total])
		print("\nFailed tests:")
		for result in _test_results:
			if not result.passed:
				print("  • %s" % result.name)
	print("=".repeat(80) + "\n")
