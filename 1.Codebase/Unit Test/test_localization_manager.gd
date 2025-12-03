extends Node
var _test_results = []
func _ready():
	print("\n" + "=".repeat(80))
	print("🧪 LOCALIZATION MANAGER TEST SUITE")
	print("=".repeat(80) + "\n")
	await run_all_tests()
	print_summary()
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()
func run_all_tests():
	await run_test("LocalizationManager Available", test_localization_manager_exists)
	await run_test("Basic Translation", test_basic_translation)
	await run_test("Stat Translation", test_stat_translation)
	await run_test("Skill Translation", test_skill_translation)
	await run_test("Teammate Translation", test_teammate_translation)
	await run_test("Phase Translation", test_phase_translation)
	await run_test("Reason Translation", test_reason_translation)
	await run_test("Language Switching", test_language_switching)
	await run_test("Missing Key Handling", test_missing_key)
	await run_test("Fallback Mechanism", test_fallback)
	await run_test("Empty String Handling", test_empty_string)
func run_test(test_name: String, test_func: Callable):
	var result = await test_func.call()
	_test_results.append({ "name": test_name, "passed": result })
	if result:
		print("  ✅ %s" % test_name)
	else:
		print("  ❌ %s FAILED" % test_name)
func assert_equal(actual, expected, message: String = "") -> bool:
	if actual != expected:
		if message:
			print("    ⚠️  %s: expected '%s', got '%s'" % [message, str(expected), str(actual)])
		return false
	return true
func assert_true(condition: bool, message: String = "") -> bool:
	if not condition:
		if message:
			print("    ⚠️  %s" % message)
		return false
	return true
func assert_not_empty(value: String, message: String = "") -> bool:
	if value.is_empty():
		if message:
			print("    ⚠️  %s: got empty string" % message)
		return false
	return true
func test_localization_manager_exists() -> bool:
	var success = true
	success = assert_true(has_node("/root/LocalizationManager"), "LocalizationManager autoload exists") and success
	if not success:
		print("    ℹ️  LocalizationManager may not be registered as autoload")
		print("    ℹ️  Remaining tests may fail")
	return success
func test_basic_translation() -> bool:
	var success = true
	if not LocalizationManager:
		print("    ⚠️  LocalizationManager not available, skipping")
		return false
	var en_text = LocalizationManager.get_translation("STAT_REALITY", "en")
	success = assert_not_empty(en_text, "English translation not empty") and success
	var zh_text = LocalizationManager.get_translation("STAT_REALITY", "zh")
	success = assert_not_empty(zh_text, "Chinese translation not empty") and success
	success = assert_true(en_text != zh_text, "EN and ZH translations differ") and success
	return success
func test_stat_translation() -> bool:
	var success = true
	if not LocalizationManager:
		return false
	var stats = ["reality", "positive", "entropy"]
	for stat in stats:
		var en = LocalizationManager.tr_stat(stat, "en")
		var zh = LocalizationManager.tr_stat(stat, "zh")
		success = assert_not_empty(en, "Stat '%s' EN not empty" % stat) and success
		success = assert_not_empty(zh, "Stat '%s' ZH not empty" % stat) and success
	return success
func test_skill_translation() -> bool:
	var success = true
	if not LocalizationManager:
		return false
	var skills = ["logic", "perception", "composure", "empathy"]
	for skill in skills:
		var en = LocalizationManager.tr_skill(skill, "en")
		var zh = LocalizationManager.tr_skill(skill, "zh")
		success = assert_not_empty(en, "Skill '%s' EN not empty" % skill) and success
		success = assert_not_empty(zh, "Skill '%s' ZH not empty" % skill) and success
	return success
func test_teammate_translation() -> bool:
	var success = true
	if not LocalizationManager:
		return false
	var teammates = ["gloria", "amber", "sage"]
	for teammate in teammates:
		var en = LocalizationManager.tr_teammate(teammate, "en")
		var zh = LocalizationManager.tr_teammate(teammate, "zh")
		success = assert_not_empty(en, "Teammate '%s' EN not empty" % teammate) and success
		success = assert_not_empty(zh, "Teammate '%s' ZH not empty" % teammate) and success
	return success
func test_phase_translation() -> bool:
	var success = true
	if not LocalizationManager:
		return false
	var phases = ["honeymoon", "normal", "crisis"]
	for phase in phases:
		var en = LocalizationManager.tr_phase(phase, "en")
		var zh = LocalizationManager.tr_phase(phase, "zh")
		success = assert_not_empty(en, "Phase '%s' EN not empty" % phase) and success
		success = assert_not_empty(zh, "Phase '%s' ZH not empty" % phase) and success
	return success
func test_reason_translation() -> bool:
	var success = true
	if not LocalizationManager:
		return false
	var reasons = ["solved_puzzle", "helped_npc", "mission_complete"]
	for reason in reasons:
		var en = LocalizationManager.tr_reason(reason, "en")
		var zh = LocalizationManager.tr_reason(reason, "zh")
		success = assert_true(en is String, "Reason '%s' EN is string" % reason) and success
		success = assert_true(zh is String, "Reason '%s' ZH is string" % reason) and success
	return success
func test_language_switching() -> bool:
	var success = true
	if not LocalizationManager:
		return false
	var original_lang = LocalizationManager._current_language
	LocalizationManager.set_language("en")
	var en_result = LocalizationManager.get_translation("STAT_REALITY") 
	success = assert_not_empty(en_result, "Translation after setting EN") and success
	LocalizationManager.set_language("zh")
	var zh_result = LocalizationManager.get_translation("STAT_REALITY") 
	success = assert_not_empty(zh_result, "Translation after setting ZH") and success
	success = assert_true(en_result != zh_result, "Language switch changes result") and success
	LocalizationManager.set_language(original_lang)
	return success
func test_missing_key() -> bool:
	var success = true
	if not LocalizationManager:
		return false
	var result = LocalizationManager.get_translation("NONEXISTENT_KEY_12345", "en")
	success = assert_equal(result, "NONEXISTENT_KEY_12345", "Missing key returns key itself") and success
	return success
func test_fallback() -> bool:
	var success = true
	if not LocalizationManager:
		return false
	var en_reality = LocalizationManager.get_translation("STAT_REALITY", "en")
	var zh_reality = LocalizationManager.get_translation("STAT_REALITY", "zh")
	success = assert_not_empty(en_reality, "Fallback EN works") and success
	success = assert_not_empty(zh_reality, "Fallback ZH works") and success
	success = assert_true(
		en_reality.contains("Reality") or en_reality.contains("現實"),
		"Fallback contains expected text",
	) and success
	return success
func test_empty_string() -> bool:
	var success = true
	if not LocalizationManager:
		return false
	var result = LocalizationManager.get_translation("", "en")
	success = assert_true(result is String, "Empty key returns string") and success
	return success
func print_summary():
	print("\n" + "=".repeat(80))
	var passed = _test_results.filter(func(r): return r.passed).size()
	var total = _test_results.size()
	if passed == total:
		print("✅ ALL TESTS PASSED (%d/%d)" % [passed, total])
		print("\n🌍 LocalizationManager is working correctly!")
	else:
		print("❌ SOME TESTS FAILED (%d/%d passed)" % [passed, total])
		print("\nFailed tests:")
		for result in _test_results:
			if not result.passed:
				print("  • %s" % result.name)
		print("\n⚠️  Note: Some failures may be due to LocalizationManager")
		print("   not being registered as an autoload in project.godot")
	print("=".repeat(80) + "\n")
