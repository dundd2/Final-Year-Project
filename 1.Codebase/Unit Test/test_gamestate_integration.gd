extends Node
var _test_results = []
var _initial_state = { }
func _ready():
	print("\n" + "=".repeat(80))
	print("🧪 GAMESTATE INTEGRATION TEST SUITE")
	print("=".repeat(80) + "\n")
	save_initial_state()
	await run_all_tests()
	print_summary()
	restore_initial_state()
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()
func save_initial_state():
	if GameState:
		_initial_state = {
			"reality_score": GameState.reality_score,
			"positive_energy": GameState.positive_energy,
			"entropy_level": GameState.entropy_level,
			"current_mission": GameState.current_mission,
		}
func restore_initial_state():
	if GameState and not _initial_state.is_empty():
		GameState._player_stats.reality_score = _initial_state.get("reality_score", 50)
		GameState._player_stats.positive_energy = _initial_state.get("positive_energy", 50)
		GameState._player_stats.entropy_level = _initial_state.get("entropy_level", 0)
		GameState.current_mission = _initial_state.get("current_mission", 0)
		GameState._debuff_system.clear_all()
		GameState._event_log_system.clear_events()
		print("\n🔄 GameState restored to initial state")
func run_all_tests():
	await run_test("GameState Exists", test_gamestate_exists)
	await run_test("Subsystems Initialized", test_subsystems_initialized)
	await run_test("PlayerStats Property Accessors", test_player_stats_accessors)
	await run_test("EventLog Property Accessors", test_event_log_accessors)
	await run_test("Debuff Property Accessors", test_debuff_accessors)
	await run_test("Stat Modification Integration", test_stat_modification)
	await run_test("Event Recording Integration", test_event_recording)
	await run_test("Debuff Integration", test_debuff_integration)
	await run_test("Signal Propagation", test_signal_propagation)
	await run_test("Save/Load Round-trip", test_save_load_roundtrip)
	await run_test("New Game Reset", test_new_game_reset)
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
func assert_not_null(value, message: String = "") -> bool:
	if value == null:
		if message:
			print("    ⚠️  %s: got null" % message)
		return false
	return true
func test_gamestate_exists() -> bool:
	var success = true
	success = assert_true(has_node("/root/GameState"), "GameState autoload exists") and success
	success = assert_not_null(GameState, "GameState reference not null") and success
	return success
func test_subsystems_initialized() -> bool:
	var success = true
	if not GameState:
		return false
	success = assert_not_null(GameState._player_stats, "PlayerStats initialized") and success
	success = assert_not_null(GameState._save_load_system, "SaveLoadSystem initialized") and success
	success = assert_not_null(GameState._event_log_system, "EventLogSystem initialized") and success
	success = assert_not_null(GameState._debuff_system, "DebuffSystem initialized") and success
	success = assert_not_null(GameState.butterfly_tracker, "ButterflyTracker initialized") and success
	return success
func test_player_stats_accessors() -> bool:
	var success = true
	if not GameState:
		return false
	var original_reality = GameState.reality_score
	GameState.reality_score = 60
	success = assert_equal(GameState.reality_score, 60, "Reality score accessor set") and success
	success = assert_equal(GameState._player_stats.reality_score, 60, "PlayerStats value updated") and success
	GameState.reality_score = original_reality
	var logic_skill = GameState.player_stats.get("logic", 0)
	success = assert_true(logic_skill > 0, "Skills accessible through property") and success
	return success
func test_event_log_accessors() -> bool:
	var success = true
	if not GameState:
		return false
	var initial_count = GameState.event_log.size()
	GameState.record_event("test_event", { "data": "test" })
	success = assert_equal(GameState.event_log.size(), initial_count + 1, "Event added to log") and success
	success = assert_equal(
		GameState._event_log_system.event_log.size(),
		initial_count + 1,
		"EventLogSystem updated",
	) and success
	return success
func test_debuff_accessors() -> bool:
	var success = true
	if not GameState:
		return false
	GameState._debuff_system.clear_all()
	success = assert_equal(GameState.active_debuffs.size(), 0, "No debuffs initially") and success
	GameState.add_debuff("測試Debuff", 3, "測試效果")
	success = assert_equal(GameState.active_debuffs.size(), 1, "Debuff added") and success
	success = assert_equal(GameState._debuff_system.active_debuffs.size(), 1, "DebuffSystem updated") and success
	GameState._debuff_system.clear_all()
	return success
func test_stat_modification() -> bool:
	var success = true
	if not GameState:
		return false
	var original_reality = GameState.reality_score
	GameState.modify_reality_score(10, "測試")
	success = assert_equal(GameState.reality_score, original_reality + 10, "Reality score modified") and success
	success = assert_equal(
		GameState._player_stats.reality_score,
		original_reality + 10,
		"PlayerStats value matches",
	) and success
	GameState.modify_reality_score(-(original_reality + 10 - _initial_state.get("reality_score", 50)))
	return success
func test_event_recording() -> bool:
	var success = true
	if not GameState:
		return false
	var initial_log_size = GameState.event_log.size()
	var initial_recent_size = GameState.recent_events.size()
	var event = GameState.record_event("integration_test", { "test": true })
	success = assert_true(event is Dictionary, "Event returned") and success
	success = assert_equal(event["type"], "integration_test", "Event type correct") and success
	success = assert_true(GameState.event_log.size() > initial_log_size, "Event added to log") and success
	return success
func test_debuff_integration() -> bool:
	var success = true
	if not GameState:
		return false
	GameState._debuff_system.clear_all()
	GameState.add_debuff("整合測試", 2, "測試效果")
	success = assert_equal(GameState.active_debuffs.size(), 1, "Debuff added") and success
	GameState.process_debuffs()
	var remaining_debuff = GameState.active_debuffs[0]
	success = assert_equal(remaining_debuff["duration"], 1, "Debuff duration decreased") and success
	GameState.process_debuffs()
	success = assert_equal(GameState.active_debuffs.size(), 0, "Debuff expired") and success
	return success
func test_signal_propagation() -> bool:
	var success = true
	if not GameState:
		return false
	var signal_received = false
	var received_value = 0
	var connection = func(new_value):
		signal_received = true
		received_value = new_value
	GameState.reality_score_changed.connect(connection)
	var original = GameState.reality_score
	GameState.modify_reality_score(5, "信號測試")
	await get_tree().process_frame 
	success = assert_true(signal_received, "Signal received") and success
	success = assert_equal(received_value, original + 5, "Signal value correct") and success
	GameState.reality_score_changed.disconnect(connection)
	GameState.modify_reality_score(-5)
	return success
func test_save_load_roundtrip() -> bool:
	var success = true
	if not GameState:
		return false
	GameState._player_stats.reality_score = 77
	GameState._player_stats.positive_energy = 33
	GameState._player_stats.entropy_level = 15
	GameState._player_stats.modify_skill("logic", 2) 
	GameState._debuff_system.add_debuff("存檔測試", 3, "測試")
	GameState.current_mission = 5
	var save_data = GameState.get_save_data()
	GameState._player_stats.reality_score = 20
	GameState._player_stats.positive_energy = 80
	GameState.current_mission = 10
	GameState.load_save_data(save_data)
	success = assert_equal(GameState.reality_score, 77, "Reality score restored") and success
	success = assert_equal(GameState.positive_energy, 33, "Positive energy restored") and success
	success = assert_equal(GameState.entropy_level, 15, "Entropy restored") and success
	success = assert_equal(GameState.get_stat("logic"), 7, "Logic skill restored") and success
	success = assert_equal(GameState.active_debuffs.size(), 1, "Debuffs restored") and success
	success = assert_equal(GameState.current_mission, 5, "Mission restored") and success
	return success
func test_new_game_reset() -> bool:
	var success = true
	if not GameState:
		return false
	GameState._player_stats.reality_score = 20
	GameState._player_stats.positive_energy = 80
	GameState._player_stats.modify_skill("logic", 3)
	GameState._debuff_system.add_debuff("重置測試", 5, "測試")
	GameState._event_log_system.add_event("測試事件", "Test Event")
	GameState.current_mission = 10
	GameState.new_game()
	success = assert_equal(GameState.reality_score, 50, "Reality reset to 50") and success
	success = assert_equal(GameState.positive_energy, 50, "Positive energy reset to 50") and success
	success = assert_equal(GameState.entropy_level, 0, "Entropy reset to 0") and success
	success = assert_equal(GameState.get_stat("logic"), 5, "Logic reset to 5") and success
	success = assert_equal(GameState.active_debuffs.size(), 0, "Debuffs cleared") and success
	success = assert_equal(GameState.event_log.size(), 0, "Event log cleared") and success
	success = assert_equal(GameState.recent_events.size(), 0, "Recent events cleared") and success
	success = assert_equal(GameState.current_mission, 0, "Mission reset to 0") and success
	return success
func print_summary():
	print("\n" + "=".repeat(80))
	var passed = _test_results.filter(func(r): return r.passed).size()
	var total = _test_results.size()
	if passed == total:
		print("✅ ALL INTEGRATION TESTS PASSED (%d/%d)" % [passed, total])
		print("\n🎉 All systems integrate correctly in GameState!")
	else:
		print("❌ SOME INTEGRATION TESTS FAILED (%d/%d passed)" % [passed, total])
		print("\nFailed tests:")
		for result in _test_results:
			if not result.passed:
				print("  • %s" % result.name)
	print("=".repeat(80) + "\n")
