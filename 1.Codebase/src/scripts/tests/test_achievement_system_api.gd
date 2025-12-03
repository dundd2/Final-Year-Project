extends SceneTree
func _init():
	var achievement_script = load("res://1.Codebase/src/scripts/core/achievement_system.gd")
	var achievement_system = achievement_script.new()
	print("Testing AchievementSystem API...")
	var errors = []
	if not achievement_system.has_method("get_unlocked_achievements"):
		errors.append("Missing method: get_unlocked_achievements")
	if not achievement_system.has_method("get_all_achievements"):
		errors.append("Missing method: get_all_achievements")
	if not "skill_check_counters" in achievement_system:
		errors.append("Missing property: skill_check_counters")
	if not "journal_entry_count" in achievement_system:
		errors.append("Missing property: journal_entry_count")
	if not "moral_dilemma_count" in achievement_system:
		errors.append("Missing property: moral_dilemma_count")
	if errors.size() > 0:
		print("FAIL: Missing APIs found:")
		for e in errors:
			print("- " + e)
		quit(1)
	else:
		print("PASS: API verified.")
		quit(0)
