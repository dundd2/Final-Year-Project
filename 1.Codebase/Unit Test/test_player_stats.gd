extends Node
var PlayerStatsScript = preload("res://1.Codebase/src/scripts/core/player_stats.gd")
var _player_stats = null
var _test_results = []
func _ready():
	print("\n" + "=".repeat(80))
	print("🧪 PLAYER STATS TEST SUITE")
	print("=".repeat(80) + "\n")
	await run_all_tests()
	print_summary()
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()
func run_all_tests():
	await run_test("Initialization", test_initialization)
	await run_test("Reality Score Modification", test_reality_score_modification)
	await run_test("Positive Energy Modification", test_positive_energy_modification)
	await run_test("Entropy Modification", test_entropy_modification)
	await run_test("Stat Clamping", test_stat_clamping)
	await run_test("Void Entropy Calculation", test_void_entropy_calculation)
	await run_test("Entropy Thresholds", test_entropy_thresholds)
	await run_test("Skill Management", test_skill_management)
	await run_test("Skill Checks", test_skill_checks)
	await run_test("Cognitive Dissonance", test_cognitive_dissonance)
	await run_test("Signal Emissions", test_signal_emissions)
	await run_test("Save/Load Functionality", test_save_load)
	await run_test("Reset Functionality", test_reset)
func run_test(test_name: String, test_func: Callable):
	_player_stats = PlayerStatsScript.new()
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
func assert_in_range(value: float, min_val: float, max_val: float, message: String = "") -> bool:
	if value < min_val or value > max_val:
		if message:
			print("    ⚠️  %s: expected in range [%f, %f], got %f" % [message, min_val, max_val, value])
		return false
	return true
func test_initialization() -> bool:
	var success = true
	success = assert_equal(_player_stats.reality_score, 50, "Initial reality score") and success
	success = assert_equal(_player_stats.positive_energy, 50, "Initial positive energy") and success
	success = assert_equal(_player_stats.entropy_level, 0, "Initial entropy level") and success
	success = assert_equal(_player_stats.skills["logic"], 5, "Initial logic skill") and success
	success = assert_equal(_player_stats.skills["perception"], 5, "Initial perception skill") and success
	success = assert_equal(_player_stats.skills["composure"], 5, "Initial composure skill") and success
	success = assert_equal(_player_stats.skills["empathy"], 5, "Initial empathy skill") and success
	success = assert_equal(_player_stats.cognitive_dissonance_active, false, "Cognitive dissonance inactive") and success
	return success
func test_reality_score_modification() -> bool:
	var success = true
	_player_stats.modify_reality_score(10)
	success = assert_equal(_player_stats.reality_score, 60, "Reality +10") and success
	_player_stats.modify_reality_score(-20)
	success = assert_equal(_player_stats.reality_score, 40, "Reality -20") and success
	return success
func test_positive_energy_modification() -> bool:
	var success = true
	var initial_entropy = _player_stats.entropy_level
	_player_stats.modify_positive_energy(10)
	success = assert_equal(_player_stats.positive_energy, 60, "Positive energy +10") and success
	success = assert_equal(_player_stats.entropy_level, initial_entropy + 20, "Entropy increased by 2x") and success
	_player_stats.modify_positive_energy(-5)
	success = assert_equal(_player_stats.positive_energy, 55, "Positive energy -5") and success
	return success
func test_entropy_modification() -> bool:
	var success = true
	_player_stats.modify_entropy(15)
	success = assert_equal(_player_stats.entropy_level, 15, "Entropy +15") and success
	_player_stats.modify_entropy(10)
	success = assert_equal(_player_stats.entropy_level, 25, "Entropy +10 more") and success
	_player_stats.modify_entropy(-30)
	success = assert_equal(_player_stats.entropy_level, 0, "Entropy clamped at 0") and success
	return success
func test_stat_clamping() -> bool:
	var success = true
	_player_stats.modify_reality_score(100)
	success = assert_equal(_player_stats.reality_score, 100, "Reality clamped at 100") and success
	_player_stats.modify_reality_score(-150)
	success = assert_equal(_player_stats.reality_score, 0, "Reality clamped at 0") and success
	_player_stats.modify_positive_energy(100)
	success = assert_equal(_player_stats.positive_energy, 100, "Positive energy clamped at 100") and success
	_player_stats.modify_positive_energy(-150)
	success = assert_equal(_player_stats.positive_energy, 0, "Positive energy clamped at 0") and success
	return success
func test_void_entropy_calculation() -> bool:
	var success = true
	var entropy = _player_stats.calculate_void_entropy()
	var expected = (50.0 / 100.0) * 0.7 + (1.0 - (50.0 / 200.0)) * 0.3
	success = assert_in_range(entropy, expected - 0.01, expected + 0.01, "Default entropy calculation") and success
	_player_stats.reality_score = 20
	_player_stats.positive_energy = 90
	entropy = _player_stats.calculate_void_entropy()
	success = assert_in_range(entropy, 0.85, 0.95, "High entropy scenario") and success
	_player_stats.reality_score = 90
	_player_stats.positive_energy = 10
	entropy = _player_stats.calculate_void_entropy()
	success = assert_in_range(entropy, 0.20, 0.30, "Low entropy scenario") and success
	return success
func test_entropy_thresholds() -> bool:
	var success = true
	_player_stats.reality_score = 80
	_player_stats.positive_energy = 20
	success = assert_equal(_player_stats.get_entropy_threshold(), "low", "Low entropy threshold") and success
	_player_stats.reality_score = 50
	_player_stats.positive_energy = 50
	success = assert_equal(_player_stats.get_entropy_threshold(), "medium", "Medium entropy threshold") and success
	_player_stats.reality_score = 20
	_player_stats.positive_energy = 90
	success = assert_equal(_player_stats.get_entropy_threshold(), "high", "High entropy threshold") and success
	success = assert_equal(_player_stats.get_entropy_level_label("en"), "Chaotic", "English label") and success
	success = assert_equal(_player_stats.get_entropy_level_label("zh"), "混亂", "Chinese label") and success
	return success
func test_skill_management() -> bool:
	var success = true
	success = assert_equal(_player_stats.get_skill("logic"), 5, "Get logic skill") and success
	_player_stats.modify_skill("logic", 2)
	success = assert_equal(_player_stats.get_skill("logic"), 7, "Logic +2") and success
	_player_stats.modify_skill("perception", 10)
	success = assert_equal(_player_stats.get_skill("perception"), 10, "Perception clamped at 10") and success
	_player_stats.modify_skill("composure", -10)
	success = assert_equal(_player_stats.get_skill("composure"), 0, "Composure clamped at 0") and success
	success = assert_equal(_player_stats.get_skill("nonexistent"), 0, "Non-existent skill returns 0") and success
	return success
func test_skill_checks() -> bool:
	var success = true
	_player_stats.modify_skill("logic", 3) 
	var successes = 0
	var failures = 0
	for i in range(20):
		var result = _player_stats.skill_check("logic", 10)
		success = assert_true(result.has("success"), "Result has success field") and success
		success = assert_true(result.has("roll"), "Result has roll field") and success
		success = assert_true(result.has("skill_value"), "Result has skill_value field") and success
		success = assert_true(result.has("total"), "Result has total field") and success
		success = assert_true(result.has("difficulty"), "Result has difficulty field") and success
		success = assert_equal(result["skill_value"], 8, "Skill value correct") and success
		success = assert_in_range(result["roll"], 1, 10, "Roll in range 1-10") and success
		if result["success"]:
			successes += 1
		else:
			failures += 1
	success = assert_true(successes > 10, "Should have some successes") and success
	success = assert_true(failures > 0, "Should have some failures") and success
	return success
func test_cognitive_dissonance() -> bool:
	var success = true
	_player_stats.cognitive_dissonance_active = false
	_player_stats.modify_skill("logic", 2) 
	var normal_check = _player_stats.skill_check("logic", 10)
	var normal_total = normal_check["total"]
	_player_stats.cognitive_dissonance_active = true
	var debuffed_check = _player_stats.skill_check("logic", 10)
	var expected_debuffed = debuffed_check["skill_value"] + debuffed_check["roll"] - 3
	success = assert_equal(debuffed_check["total"], expected_debuffed, "Cognitive dissonance applies -3") and success
	var composure_check = _player_stats.skill_check("composure", 10)
	var expected_composure = composure_check["skill_value"] + composure_check["roll"]
	success = assert_equal(composure_check["total"], expected_composure, "Other skills unaffected") and success
	return success
func test_signal_emissions() -> bool:
	var success = true
	var reality_signal_count = 0
	var energy_signal_count = 0
	var entropy_signal_count = 0
	var stats_signal_count = 0
	_player_stats.reality_score_changed.connect(func(_v): reality_signal_count += 1)
	_player_stats.positive_energy_changed.connect(func(_v): energy_signal_count += 1)
	_player_stats.entropy_level_changed.connect(func(_v): entropy_signal_count += 1)
	_player_stats.stats_changed.connect(func(): stats_signal_count += 1)
	_player_stats.modify_reality_score(10)
	await get_tree().process_frame
	success = assert_equal(reality_signal_count, 1, "Reality signal emitted") and success
	_player_stats.modify_positive_energy(10)
	await get_tree().process_frame
	success = assert_equal(energy_signal_count, 1, "Energy signal emitted") and success
	success = assert_equal(entropy_signal_count, 1, "Entropy signal emitted (from PE increase)") and success
	_player_stats.modify_skill("logic", 1)
	await get_tree().process_frame
	success = assert_equal(stats_signal_count, 1, "Stats changed signal emitted") and success
	return success
func test_save_load() -> bool:
	var success = true
	_player_stats.reality_score = 75
	_player_stats.positive_energy = 30
	_player_stats.entropy_level = 25
	_player_stats.modify_skill("logic", 3) 
	_player_stats.modify_skill("perception", -2) 
	_player_stats.cognitive_dissonance_active = true
	var save_data = _player_stats.get_save_data()
	success = assert_true(save_data.has("reality_score"), "Save has reality_score") and success
	success = assert_true(save_data.has("positive_energy"), "Save has positive_energy") and success
	success = assert_true(save_data.has("entropy_level"), "Save has entropy_level") and success
	success = assert_true(save_data.has("skills"), "Save has skills") and success
	success = assert_true(save_data.has("cognitive_dissonance_active"), "Save has cognitive_dissonance") and success
	var new_stats = PlayerStatsScript.new()
	new_stats.load_save_data(save_data)
	success = assert_equal(new_stats.reality_score, 75, "Loaded reality score") and success
	success = assert_equal(new_stats.positive_energy, 30, "Loaded positive energy") and success
	success = assert_equal(new_stats.entropy_level, 25, "Loaded entropy level") and success
	success = assert_equal(new_stats.get_skill("logic"), 8, "Loaded logic skill") and success
	success = assert_equal(new_stats.get_skill("perception"), 3, "Loaded perception skill") and success
	success = assert_equal(new_stats.cognitive_dissonance_active, true, "Loaded cognitive dissonance") and success
	return success
func test_reset() -> bool:
	var success = true
	_player_stats.reality_score = 75
	_player_stats.positive_energy = 30
	_player_stats.entropy_level = 25
	_player_stats.modify_skill("logic", 3)
	_player_stats.cognitive_dissonance_active = true
	_player_stats.reset()
	success = assert_equal(_player_stats.reality_score, 50, "Reset reality score") and success
	success = assert_equal(_player_stats.positive_energy, 50, "Reset positive energy") and success
	success = assert_equal(_player_stats.entropy_level, 0, "Reset entropy level") and success
	success = assert_equal(_player_stats.get_skill("logic"), 5, "Reset logic skill") and success
	success = assert_equal(_player_stats.cognitive_dissonance_active, false, "Reset cognitive dissonance") and success
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
