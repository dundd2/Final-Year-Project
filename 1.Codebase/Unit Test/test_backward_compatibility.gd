extends Node
var PlayerStatsScript = preload("res://1.Codebase/src/scripts/core/player_stats.gd")
var EventLogSystemScript = preload("res://1.Codebase/src/scripts/core/event_log_system.gd")
var DebuffSystemScript = preload("res://1.Codebase/src/scripts/core/debuff_system.gd")
var _test_results = []
func _ready():
	print("\n" + "=".repeat(80))
	print("🔄 BACKWARD COMPATIBILITY TEST SUITE")
	print("=".repeat(80) + "\n")
	await run_all_tests()
	print_summary()
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()
func run_all_tests():
	await run_test("PlayerStats - Legacy Save Format", test_player_stats_legacy)
	await run_test("EventLogSystem - Legacy Save Format", test_event_log_legacy)
	await run_test("DebuffSystem - Legacy Save Format", test_debuff_system_legacy)
	await run_test("PlayerStats - New Save Format", test_player_stats_new_format)
	await run_test("EventLogSystem - New Save Format", test_event_log_new_format)
	await run_test("DebuffSystem - New Save Format", test_debuff_system_new_format)
	await run_test("Mixed Format Compatibility", test_mixed_format)
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
			print("    ⚠️  %s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
func assert_true(condition: bool, message: String = "") -> bool:
	if not condition:
		if message:
			print("    ⚠️  %s" % message)
		return false
	return true
func test_player_stats_legacy() -> bool:
	var success = true
	var legacy_save_data = {
		"reality_score": 75,
		"positive_energy": 30,
		"entropy_level": 25,
		"player_stats": {
			"logic": 8,
			"perception": 3,
			"composure": 6,
			"empathy": 7,
		},
	}
	var player_stats = PlayerStatsScript.new()
	var converted_data = {
		"reality_score": legacy_save_data.get("reality_score", 50),
		"positive_energy": legacy_save_data.get("positive_energy", 50),
		"entropy_level": legacy_save_data.get("entropy_level", 0),
		"skills": legacy_save_data.get("player_stats", { }),
	}
	player_stats.load_save_data(converted_data)
	success = assert_equal(player_stats.reality_score, 75, "Legacy reality score loaded") and success
	success = assert_equal(player_stats.positive_energy, 30, "Legacy positive energy loaded") and success
	success = assert_equal(player_stats.entropy_level, 25, "Legacy entropy level loaded") and success
	success = assert_equal(player_stats.get_skill("logic"), 8, "Legacy logic skill loaded") and success
	success = assert_equal(player_stats.get_skill("perception"), 3, "Legacy perception skill loaded") and success
	success = assert_equal(player_stats.get_skill("composure"), 6, "Legacy composure skill loaded") and success
	success = assert_equal(player_stats.get_skill("empathy"), 7, "Legacy empathy skill loaded") and success
	return success
func test_event_log_legacy() -> bool:
	var success = true
	var legacy_event_data = {
		"event_log": [
			{ "type": "skill_check_failed", "details": { "skill": "logic" }, "timestamp": 1234567890 },
			{ "type": "prayer_made", "details": { "prayer": "Test prayer" }, "timestamp": 1234567900 },
		],
		"recent_events": [
			"Event 1 happened",
			"Event 2 occurred",
		],
	}
	var event_system = EventLogSystemScript.new()
	event_system.load_save_data(legacy_event_data)
	success = assert_equal(event_system.event_log.size(), 2, "Legacy event log loaded") and success
	success = assert_equal(event_system.recent_events.size(), 2, "Legacy recent events loaded") and success
	success = assert_equal(event_system.event_log[0]["type"], "skill_check_failed", "Event type preserved") and success
	success = assert_equal(event_system.recent_events[0], "Event 1 happened", "Recent event text preserved") and success
	return success
func test_debuff_system_legacy() -> bool:
	var success = true
	var legacy_debuff_data = {
		"active_debuffs": [
			{ "name": "疲勞", "duration": 3, "effect": "Logic -2" },
			{ "name": "認知失調", "duration": 5, "effect": "Logic -3" },
		],
		"cognitive_dissonance_active": true,
		"cognitive_dissonance_choices_left": 5,
	}
	var debuff_system = DebuffSystemScript.new()
	debuff_system.load_save_data(legacy_debuff_data)
	success = assert_equal(debuff_system.active_debuffs.size(), 2, "Legacy debuffs loaded") and success
	success = assert_equal(debuff_system.cognitive_dissonance_active, true, "Legacy CD active loaded") and success
	success = assert_equal(debuff_system.cognitive_dissonance_choices_left, 5, "Legacy CD choices loaded") and success
	success = assert_equal(debuff_system.active_debuffs[0]["name"], "疲勞", "Debuff name preserved") and success
	return success
func test_player_stats_new_format() -> bool:
	var success = true
	var new_save_data = {
		"player_stats_data": {
			"reality_score": 60,
			"positive_energy": 80,
			"entropy_level": 15,
			"skills": {
				"logic": 9,
				"perception": 4,
				"composure": 7,
				"empathy": 6,
			},
			"cognitive_dissonance_active": true,
		},
	}
	var player_stats = PlayerStatsScript.new()
	player_stats.load_save_data(new_save_data["player_stats_data"])
	success = assert_equal(player_stats.reality_score, 60, "New reality score loaded") and success
	success = assert_equal(player_stats.positive_energy, 80, "New positive energy loaded") and success
	success = assert_equal(player_stats.cognitive_dissonance_active, true, "New CD state loaded") and success
	return success
func test_event_log_new_format() -> bool:
	var success = true
	var event_system = EventLogSystemScript.new()
	event_system.add_event("Test event", "測試事件")
	event_system.record_event("test_type", { "key": "value" })
	var save_data = event_system.get_save_data()
	var new_system = EventLogSystemScript.new()
	new_system.load_save_data(save_data)
	success = assert_equal(new_system.event_log.size(), 1, "New event log size") and success
	success = assert_equal(new_system.recent_events.size(), 1, "New recent events size") and success
	return success
func test_debuff_system_new_format() -> bool:
	var success = true
	var debuff_system = DebuffSystemScript.new()
	debuff_system.add_debuff("Test Debuff", 3, "Effect")
	var save_data = debuff_system.get_save_data()
	var new_system = DebuffSystemScript.new()
	new_system.load_save_data(save_data)
	success = assert_equal(new_system.active_debuffs.size(), 1, "New debuff loaded") and success
	return success
func test_mixed_format() -> bool:
	var success = true
	var mixed_save = {
		"player_stats_data": {
			"reality_score": 70,
			"positive_energy": 40,
			"entropy_level": 20,
			"skills": { "logic": 7, "perception": 5, "composure": 6, "empathy": 5 },
		},
		"active_debuffs": [
			{ "name": "Old Debuff", "duration": 2, "effect": "Test" },
		],
		"event_log": [{ "type": "old_event", "details": { }, "timestamp": 123 }],
		"recent_events": ["Old text event"],
	}
	var player_stats = PlayerStatsScript.new()
	player_stats.load_save_data(mixed_save["player_stats_data"])
	success = assert_equal(player_stats.reality_score, 70, "Mixed: PlayerStats loaded") and success
	var debuff_system = DebuffSystemScript.new()
	var debuff_data = {
		"active_debuffs": mixed_save["active_debuffs"],
		"cognitive_dissonance_active": false,
		"cognitive_dissonance_choices_left": 0,
	}
	debuff_system.load_save_data(debuff_data)
	success = assert_equal(debuff_system.active_debuffs.size(), 1, "Mixed: DebuffSystem loaded") and success
	var event_system = EventLogSystemScript.new()
	var event_data = {
		"event_log": mixed_save["event_log"],
		"recent_events": mixed_save["recent_events"],
	}
	event_system.load_save_data(event_data)
	success = assert_equal(event_system.event_log.size(), 1, "Mixed: EventLogSystem loaded") and success
	return success
func print_summary():
	print("\n" + "=".repeat(80))
	var passed = _test_results.filter(func(r): return r.passed).size()
	var total = _test_results.size()
	if passed == total:
		print("✅ ALL BACKWARD COMPATIBILITY TESTS PASSED (%d/%d)" % [passed, total])
		print("\n🎉 100% backward compatibility maintained!")
	else:
		print("❌ SOME COMPATIBILITY TESTS FAILED (%d/%d passed)" % [passed, total])
		print("\n⚠️  WARNING: Backward compatibility issues detected!")
		print("\nFailed tests:")
		for result in _test_results:
			if not result.passed:
				print("  • %s" % result.name)
	print("=".repeat(80) + "\n")
