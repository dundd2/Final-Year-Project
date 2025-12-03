extends Node
var initial_achievements: Dictionary = {}
var initial_progress: Dictionary = {}
var signal_received: bool = false
var signal_achievement_id: String = ""
func _ready() -> void:
	print("[AchievementSystemTest] Starting AchievementSystem unit tests...")
	await get_tree().process_frame
	if not AchievementSystem:
		print("[AchievementSystemTest] ❌ FAIL: AchievementSystem autoload not found")
		queue_free()
		return
	_backup_state()
	_test_system_initialization()
	_test_unlock_achievement()
	_test_duplicate_unlock_prevention()
	_test_invalid_achievement()
	_test_progress_counters()
	_test_mission_achievements()
	_test_stat_based_achievements()
	_test_skill_check_achievements()
	_test_dilemma_achievements()
	await _test_signal_emission()
	await _test_save_load_persistence()
	_test_state_snapshot()
	_test_achievement_queries()
	_test_reset_functionality()
	_restore_state()
	print("[AchievementSystemTest] All tests completed.")
	queue_free()
	get_tree().quit()
func _backup_state() -> void:
	initial_achievements = AchievementSystem.unlocked_achievements.duplicate(true)
	initial_progress = AchievementSystem._progress_counters.duplicate(true)
	AchievementSystem.reset_achievements()
func _restore_state() -> void:
	AchievementSystem.unlocked_achievements = initial_achievements.duplicate(true)
	AchievementSystem._progress_counters = initial_progress.duplicate(true)
	AchievementSystem.save_achievements()
func _test_system_initialization() -> void:
	print("[Test] System initialization...")
	assert(AchievementSystem != null, "AchievementSystem should exist as autoload")
	assert(AchievementSystem.ACHIEVEMENTS is Dictionary, "ACHIEVEMENTS constant should be Dictionary")
	assert(AchievementSystem.ACHIEVEMENTS.size() > 0, "ACHIEVEMENTS should contain achievement definitions")
	assert(AchievementSystem.unlocked_achievements is Dictionary, "unlocked_achievements should be Dictionary")
	assert(AchievementSystem._progress_counters is Dictionary, "Progress counters should exist")
	assert(AchievementSystem.ACHIEVEMENTS.has("first_mission"), "Should have 'first_mission' achievement")
	assert(AchievementSystem.ACHIEVEMENTS.has("reality_seeker"), "Should have 'reality_seeker' achievement")
	assert(AchievementSystem.ACHIEVEMENTS.has("skill_master"), "Should have 'skill_master' achievement")
	print("[Test] System initialization PASSED ✅")
func _test_unlock_achievement() -> void:
	print("[Test] Unlock achievement...")
	var initial_count = AchievementSystem.get_unlocked_count()
	AchievementSystem.unlock_achievement("first_mission")
	assert(AchievementSystem.is_unlocked("first_mission"), "Achievement should be unlocked")
	assert(AchievementSystem.get_unlocked_count() == initial_count + 1, "Unlocked count should increase by 1")
	assert(AchievementSystem.unlocked_achievements.has("first_mission"), "Achievement should be in unlocked dict")
	var timestamp = AchievementSystem.unlocked_achievements["first_mission"]
	assert(timestamp > 0, "Timestamp should be positive")
	print("[Test] Unlock achievement PASSED ✅")
func _test_duplicate_unlock_prevention() -> void:
	print("[Test] Duplicate unlock prevention...")
	AchievementSystem.unlock_achievement("survivor")
	var count_after_first = AchievementSystem.get_unlocked_count()
	var timestamp_first = AchievementSystem.unlocked_achievements["survivor"]
	await get_tree().create_timer(0.01).timeout
	AchievementSystem.unlock_achievement("survivor")
	var count_after_second = AchievementSystem.get_unlocked_count()
	var timestamp_second = AchievementSystem.unlocked_achievements["survivor"]
	assert(count_after_second == count_after_first, "Count should not increase on duplicate unlock")
	assert(timestamp_second == timestamp_first, "Timestamp should not change on duplicate unlock")
	print("[Test] Duplicate unlock prevention PASSED ✅")
func _test_invalid_achievement() -> void:
	print("[Test] Invalid achievement handling...")
	var count_before = AchievementSystem.get_unlocked_count()
	AchievementSystem.unlock_achievement("nonexistent_achievement_xyz")
	var count_after = AchievementSystem.get_unlocked_count()
	assert(count_after == count_before, "Invalid achievement should not be unlocked")
	assert(not AchievementSystem.is_unlocked("nonexistent_achievement_xyz"), "Invalid achievement should return false")
	print("[Test] Invalid achievement handling PASSED ✅")
func _test_progress_counters() -> void:
	print("[Test] Progress counters...")
	AchievementSystem._progress_counters["missions_completed"] = 0
	AchievementSystem._progress_counters["journal_entries"] = 0
	AchievementSystem._progress_counters["gloria_triggers"] = 0
	assert(AchievementSystem._progress_counters.has("missions_completed"), "Should have missions counter")
	assert(AchievementSystem._progress_counters.has("journal_entries"), "Should have journal counter")
	assert(AchievementSystem._progress_counters.has("gloria_triggers"), "Should have gloria counter")
	assert(AchievementSystem._progress_counters.has("prayers_made"), "Should have prayers counter")
	assert(AchievementSystem._progress_counters.has("logic_successes"), "Should have logic counter")
	assert(AchievementSystem._progress_counters.has("perception_successes"), "Should have perception counter")
	print("[Test] Progress counters PASSED ✅")
func _test_mission_achievements() -> void:
	print("[Test] Mission achievements...")
	AchievementSystem._progress_counters["missions_completed"] = 0
	AchievementSystem.unlocked_achievements.erase("first_mission")
	AchievementSystem.unlocked_achievements.erase("survivor")
	AchievementSystem.unlocked_achievements.erase("veteran")
	AchievementSystem.check_mission_complete()
	assert(AchievementSystem._progress_counters["missions_completed"] == 1, "Missions counter should be 1")
	assert(AchievementSystem.is_unlocked("first_mission"), "Should unlock first_mission achievement")
	AchievementSystem._progress_counters["missions_completed"] = 9
	AchievementSystem.check_mission_complete()
	assert(AchievementSystem._progress_counters["missions_completed"] == 10, "Missions counter should be 10")
	assert(AchievementSystem.is_unlocked("survivor"), "Should unlock survivor achievement")
	AchievementSystem._progress_counters["missions_completed"] = 49
	AchievementSystem.check_mission_complete()
	assert(AchievementSystem._progress_counters["missions_completed"] == 50, "Missions counter should be 50")
	assert(AchievementSystem.is_unlocked("veteran"), "Should unlock veteran achievement")
	print("[Test] Mission achievements PASSED ✅")
func _test_stat_based_achievements() -> void:
	print("[Test] Stat-based achievements...")
	AchievementSystem.unlocked_achievements.erase("reality_seeker")
	AchievementSystem.unlocked_achievements.erase("reality_crisis")
	AchievementSystem.unlocked_achievements.erase("positive_resistance")
	AchievementSystem.unlocked_achievements.erase("positive_victim")
	AchievementSystem.unlocked_achievements.erase("entropy_witness")
	AchievementSystem._check_reality_achievements(85)
	assert(AchievementSystem.is_unlocked("reality_seeker"), "Should unlock reality_seeker at high reality")
	AchievementSystem.unlocked_achievements.erase("reality_seeker")
	AchievementSystem._check_reality_achievements(15)
	assert(AchievementSystem.is_unlocked("reality_crisis"), "Should unlock reality_crisis at low reality")
	AchievementSystem._check_positive_achievements(25)
	assert(AchievementSystem.is_unlocked("positive_resistance"), "Should unlock positive_resistance at low positive")
	AchievementSystem.unlocked_achievements.erase("positive_resistance")
	AchievementSystem._check_positive_achievements(95)
	assert(AchievementSystem.is_unlocked("positive_victim"), "Should unlock positive_victim at high positive")
	AchievementSystem._check_entropy_achievements(105)
	assert(AchievementSystem.is_unlocked("entropy_witness"), "Should unlock entropy_witness at high entropy")
	print("[Test] Stat-based achievements PASSED ✅")
func _test_skill_check_achievements() -> void:
	print("[Test] Skill check achievements...")
	AchievementSystem._progress_counters["logic_successes"] = 0
	AchievementSystem._progress_counters["perception_successes"] = 0
	AchievementSystem.unlocked_achievements.erase("logic_master")
	AchievementSystem.unlocked_achievements.erase("perception_expert")
	for i in range(10):
		AchievementSystem.check_skill_check_success("logic")
	assert(AchievementSystem._progress_counters["logic_successes"] == 10, "Logic counter should be 10")
	assert(AchievementSystem.is_unlocked("logic_master"), "Should unlock logic_master after 10 successes")
	for i in range(10):
		AchievementSystem.check_skill_check_success("perception")
	assert(AchievementSystem._progress_counters["perception_successes"] == 10, "Perception counter should be 10")
	assert(AchievementSystem.is_unlocked("perception_expert"), "Should unlock perception_expert after 10 successes")
	print("[Test] Skill check achievements PASSED ✅")
func _test_dilemma_achievements() -> void:
	print("[Test] Dilemma achievements...")
	AchievementSystem._progress_counters["dilemmas_resolved"] = 0
	AchievementSystem.unlocked_achievements.erase("moral_philosopher")
	AchievementSystem.unlocked_achievements.erase("trolley_conductor")
	AchievementSystem.unlocked_achievements.erase("complicit")
	AchievementSystem.check_dilemma_resolved()
	assert(AchievementSystem._progress_counters["dilemmas_resolved"] == 1, "Dilemma counter should be 1")
	assert(AchievementSystem.is_unlocked("moral_philosopher"), "Should unlock moral_philosopher on first dilemma")
	AchievementSystem._progress_counters["dilemmas_resolved"] = 4
	AchievementSystem.check_dilemma_resolved()
	assert(AchievementSystem._progress_counters["dilemmas_resolved"] == 5, "Dilemma counter should be 5")
	assert(AchievementSystem.is_unlocked("trolley_conductor"), "Should unlock trolley_conductor on 5th dilemma")
	AchievementSystem._progress_counters["dilemmas_resolved"] = 9
	AchievementSystem.check_dilemma_resolved()
	assert(AchievementSystem._progress_counters["dilemmas_resolved"] == 10, "Dilemma counter should be 10")
	assert(AchievementSystem.is_unlocked("complicit"), "Should unlock complicit on 10th dilemma")
	print("[Test] Dilemma achievements PASSED ✅")
func _test_signal_emission() -> void:
	print("[Test] Signal emission...")
	signal_received = false
	signal_achievement_id = ""
	if not AchievementSystem.achievement_unlocked.is_connected(_on_achievement_unlocked):
		AchievementSystem.achievement_unlocked.connect(_on_achievement_unlocked)
	AchievementSystem.unlocked_achievements.erase("diary_keeper")
	AchievementSystem.unlock_achievement("diary_keeper")
	await get_tree().create_timer(0.05).timeout
	assert(signal_received, "achievement_unlocked signal should be emitted")
	assert(signal_achievement_id == "diary_keeper", "Signal should contain correct achievement ID")
	if AchievementSystem.achievement_unlocked.is_connected(_on_achievement_unlocked):
		AchievementSystem.achievement_unlocked.disconnect(_on_achievement_unlocked)
	print("[Test] Signal emission PASSED ✅")
func _on_achievement_unlocked(achievement_id: String, _achievement_data: Dictionary) -> void:
	signal_received = true
	signal_achievement_id = achievement_id
func _test_save_load_persistence() -> void:
	print("[Test] Save/load persistence...")
	AchievementSystem.reset_achievements()
	AchievementSystem.unlock_achievement("first_mission")
	AchievementSystem.unlock_achievement("reality_seeker")
	AchievementSystem._progress_counters["missions_completed"] = 5
	AchievementSystem._progress_counters["journal_entries"] = 3
	AchievementSystem.save_achievements()
	await get_tree().create_timer(0.1).timeout
	var saved_achievements = AchievementSystem.unlocked_achievements.duplicate(true)
	var saved_progress = AchievementSystem._progress_counters.duplicate(true)
	AchievementSystem.unlocked_achievements.clear()
	AchievementSystem._progress_counters["missions_completed"] = 0
	AchievementSystem._progress_counters["journal_entries"] = 0
	AchievementSystem.load_achievements()
	await get_tree().create_timer(0.1).timeout
	assert(AchievementSystem.is_unlocked("first_mission"), "Should restore first_mission achievement")
	assert(AchievementSystem.is_unlocked("reality_seeker"), "Should restore reality_seeker achievement")
	assert(AchievementSystem._progress_counters["missions_completed"] == saved_progress["missions_completed"],
		"Should restore missions counter")
	assert(AchievementSystem._progress_counters["journal_entries"] == saved_progress["journal_entries"],
		"Should restore journal counter")
	print("[Test] Save/load persistence PASSED ✅")
func _test_state_snapshot() -> void:
	print("[Test] State snapshot...")
	AchievementSystem.reset_achievements()
	AchievementSystem.unlock_achievement("survivor")
	AchievementSystem._progress_counters["missions_completed"] = 12
	var snapshot = AchievementSystem.get_state_snapshot()
	assert(snapshot.has("unlocked"), "Snapshot should have unlocked achievements")
	assert(snapshot.has("progress"), "Snapshot should have progress counters")
	assert(snapshot["unlocked"].has("survivor"), "Snapshot should contain unlocked achievements")
	assert(snapshot["progress"]["missions_completed"] == 12, "Snapshot should contain progress data")
	AchievementSystem.reset_achievements()
	assert(AchievementSystem.get_unlocked_count() == 0, "State should be cleared")
	AchievementSystem.load_state_snapshot(snapshot)
	assert(AchievementSystem.is_unlocked("survivor"), "Should restore from snapshot")
	assert(AchievementSystem._progress_counters["missions_completed"] == 12, "Should restore progress from snapshot")
	print("[Test] State snapshot PASSED ✅")
func _test_achievement_queries() -> void:
	print("[Test] Achievement queries...")
	AchievementSystem.reset_achievements()
	AchievementSystem.unlock_achievement("first_mission")
	AchievementSystem.unlock_achievement("reality_seeker")
	AchievementSystem.unlock_achievement("survivor")
	assert(AchievementSystem.get_unlocked_count() == 3, "Should return correct unlocked count")
	assert(AchievementSystem.get_total_count() == AchievementSystem.ACHIEVEMENTS.size(),
		"Should return total achievement count")
	var percentage = AchievementSystem.get_progress_percentage()
	var expected_percentage = (3.0 / AchievementSystem.ACHIEVEMENTS.size()) * 100.0
	assert(abs(percentage - expected_percentage) < 0.1, "Should calculate correct progress percentage")
	var achievement_list = AchievementSystem.get_achievement_list()
	assert(achievement_list is Array, "Should return array of achievements")
	assert(achievement_list.size() == AchievementSystem.ACHIEVEMENTS.size(),
		"Achievement list should contain all achievements")
	var found_first_mission = false
	for achievement in achievement_list:
		assert(achievement.has("id"), "Achievement should have ID")
		assert(achievement.has("unlocked"), "Achievement should have unlocked status")
		assert(achievement.has("title"), "Achievement should have title")
		if achievement["id"] == "first_mission":
			found_first_mission = true
			assert(achievement["unlocked"] == true, "first_mission should be marked as unlocked")
			assert(achievement.has("unlocked_at"), "Unlocked achievement should have timestamp")
	assert(found_first_mission, "Achievement list should contain first_mission")
	print("[Test] Achievement queries PASSED ✅")
func _test_reset_functionality() -> void:
	print("[Test] Reset functionality...")
	AchievementSystem.unlock_achievement("first_mission")
	AchievementSystem.unlock_achievement("survivor")
	AchievementSystem._progress_counters["missions_completed"] = 15
	AchievementSystem._progress_counters["journal_entries"] = 8
	assert(AchievementSystem.get_unlocked_count() > 0, "Should have unlocked achievements before reset")
	AchievementSystem.reset_achievements()
	assert(AchievementSystem.get_unlocked_count() == 0, "Should have no unlocked achievements after reset")
	assert(AchievementSystem._progress_counters["missions_completed"] == 0, "Missions counter should be 0")
	assert(AchievementSystem._progress_counters["journal_entries"] == 0, "Journal counter should be 0")
	assert(AchievementSystem._progress_counters["gloria_triggers"] == 0, "Gloria counter should be 0")
	assert(AchievementSystem._progress_counters["prayers_made"] == 0, "Prayers counter should be 0")
	print("[Test] Reset functionality PASSED ✅")
