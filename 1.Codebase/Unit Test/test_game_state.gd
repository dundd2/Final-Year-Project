extends Node
const TOL := 0.05
var initial_reality: int
var initial_positive: int
var initial_entropy: int
func _ready() -> void:
	print("[GameStateTest] Starting GameState unit tests...")
	await get_tree().process_frame
	_test_stat_modifications()
	await _test_save_load_system()
	await _test_event_logging()
	_test_skill_checks()
	_test_phase_management()
	print("[GameStateTest] All tests completed.")
	queue_free()
func _test_stat_modifications() -> void:
	print("[Test] Stat modifications...")
	initial_reality = GameState.reality_score
	initial_positive = GameState.positive_energy
	initial_entropy = GameState.entropy_level
	GameState.modify_reality_score(10, "Test increase")
	assert(GameState.reality_score == initial_reality + 10, "Reality score should increase by 10")
	GameState.reality_score = 95
	GameState.modify_reality_score(10, "Test clamping")
	assert(GameState.reality_score == 100, "Reality score should clamp at 100")
	GameState.reality_score = 5
	GameState.modify_reality_score(-10, "Test clamping min")
	assert(GameState.reality_score == 0, "Reality score should clamp at 0")
	GameState.reality_score = initial_reality
	GameState.positive_energy = 50
	GameState.modify_positive_energy(20, "Test positive energy")
	assert(GameState.positive_energy == 70, "Positive energy should be 70")
	var entropy_before = GameState.entropy_level
	GameState.positive_energy = 50
	GameState.modify_positive_energy(10, "Test entropy cascade")
	var entropy_after = GameState.entropy_level
	assert(entropy_after > entropy_before, "Entropy should increase when positive energy increases")
	GameState.reality_score = initial_reality
	GameState.positive_energy = initial_positive
	GameState.entropy_level = initial_entropy
	print("[Test] Stat modifications PASSED")
func _test_save_load_system() -> void:
	print("[Test] Save/Load system...")
	GameState.reality_score = 42
	GameState.positive_energy = 67
	GameState.entropy_level = 15
	GameState.current_mission = 3
	GameState.missions_completed = 2
	GameState.game_phase = GameConstants.GamePhase.CRISIS
	GameState.player_stats["logic"] = 7
	GameState.player_stats["perception"] = 6
	GameState.add_event("Test event EN", "測試事件 ZH")
	var test_slot = 1
	var save_success = GameState.save_game_to_slot(test_slot)
	assert(save_success, "Save should succeed")
	await get_tree().create_timer(0.1).timeout
	GameState.reality_score = 99
	GameState.positive_energy = 11
	GameState.entropy_level = 999
	GameState.current_mission = 0
	GameState.missions_completed = 0
	GameState.game_phase = GameConstants.GamePhase.HONEYMOON
	GameState.player_stats["logic"] = 1
	GameState.player_stats["perception"] = 1
	GameState.recent_events.clear()
	var load_success = GameState.load_game_from_slot(test_slot)
	assert(load_success, "Load should succeed")
	await get_tree().create_timer(0.1).timeout
	assert(GameState.reality_score == 42, "Reality score should be restored to 42")
	assert(GameState.positive_energy == 67, "Positive energy should be restored to 67")
	assert(GameState.entropy_level == 15, "Entropy level should be restored to 15")
	assert(GameState.current_mission == 3, "Current mission should be restored to 3")
	assert(GameState.missions_completed == 2, "Missions completed should be restored to 2")
	assert(GameState.game_phase == GameConstants.GamePhase.CRISIS, "Game phase should be restored to crisis")
	assert(GameState.player_stats["logic"] == 7, "Logic stat should be restored to 7")
	assert(GameState.player_stats["perception"] == 6, "Perception stat should be restored to 6")
	assert(GameState.recent_events.size() > 0, "Events should be restored")
	var slot_info = GameState.get_save_slot_info(test_slot)
	assert(slot_info.get("exists", false), "Slot info should show slot exists")
	assert(slot_info.get("reality_score", -1) == 42, "Slot info should show correct reality score")
	GameState.delete_save_slot(test_slot)
	print("[Test] Save/Load system PASSED")
func _test_event_logging() -> void:
	print("[Test] Event logging...")
	GameState.clear_events()
	assert(GameState.recent_events.is_empty(), "Events should be cleared")
	for i in range(5):
		GameState.add_event("Event %d EN" % i, "事件 %d ZH" % i)
	assert(GameState.recent_events.size() == 5, "Should have 5 events")
	for i in range(20):
		GameState.add_event("Overflow event %d" % i, "溢出事件 %d" % i)
	assert(GameState.recent_events.size() <= GameState.max_events, "Events should be capped at max_events")
	GameState.clear_event_log()
	var entry = GameState.record_event("test_event", { "detail": "test_value" })
	assert(entry.has("type"), "Event should have type")
	assert(entry.has("timestamp"), "Event should have timestamp")
	assert(GameState.event_log.size() == 1, "Event log should have 1 entry")
	for i in range(3):
		GameState.record_event("event_%d" % i, { "index": i })
	var recent = GameState.get_recent_records(2)
	assert(recent.size() == 2, "Should return 2 most recent events")
	print("[Test] Event logging PASSED")
func _test_skill_checks() -> void:
	print("[Test] Skill checks...")
	GameState.player_stats["logic"] = 5
	var successes = 0
	var failures = 0
	for i in range(20):
		var result = GameState.skill_check("logic", 10) 
		if result["success"]:
			successes += 1
		else:
			failures += 1
		assert(result.has("success"), "Result should have success flag")
		assert(result.has("roll"), "Result should have roll value")
		assert(result.has("stat_value"), "Result should have stat_value")
		assert(result.has("total"), "Result should have total")
		assert(result.has("difficulty"), "Result should have difficulty")
	assert(successes > 0, "Should have at least some successes in 20 rolls")
	assert(failures > 0, "Should have at least some failures in 20 rolls")
	GameState.player_stats["perception"] = 10
	var easy_result = GameState.skill_check("perception", 5) 
	assert(easy_result["total"] >= 10, "With perception=10, total should be at least 10")
	print("[Test] Skill checks PASSED")
func _test_phase_management() -> void:
	print("[Test] Phase management...")
	GameState.set_game_phase(GameConstants.GamePhase.HONEYMOON)
	assert(GameState.game_phase == GameConstants.GamePhase.HONEYMOON, "Phase should be honeymoon")
	GameState.set_game_phase(GameConstants.GamePhase.NORMAL)
	assert(GameState.game_phase == GameConstants.GamePhase.NORMAL, "Phase should be normal")
	GameState.set_game_phase(GameConstants.GamePhase.CRISIS)
	assert(GameState.game_phase == GameConstants.GamePhase.CRISIS, "Phase should be crisis")
	GameState.enter_honeymoon_phase()
	assert(GameState.game_phase == GameConstants.GamePhase.HONEYMOON, "Should enter honeymoon phase")
	assert(GameState.honeymoon_charges == 5, "Honeymoon charges should be 5")
	GameState.consume_honeymoon_charge("Test reason")
	assert(GameState.honeymoon_charges == 4, "Honeymoon charges should decrease to 4")
	for i in range(4):
		GameState.consume_honeymoon_charge("Test %d" % i)
	assert(GameState.honeymoon_charges == 0, "Honeymoon charges should be 0")
	assert(GameState.game_phase == GameConstants.GamePhase.NORMAL, "Phase should transition to normal when charges depleted")
	GameState.positive_energy = 100
	GameState.reality_score = 0
	var high_entropy = GameState.calculate_void_entropy()
	assert(high_entropy > 0.5, "High positive energy + low reality should give high entropy")
	GameState.positive_energy = 0
	GameState.reality_score = 100
	var low_entropy = GameState.calculate_void_entropy()
	assert(low_entropy < 0.5, "Low positive energy + high reality should give low entropy")
	GameState.reality_score = initial_reality
	GameState.positive_energy = initial_positive
	GameState.game_phase = GameConstants.GamePhase.NORMAL
	print("[Test] Phase management PASSED")
