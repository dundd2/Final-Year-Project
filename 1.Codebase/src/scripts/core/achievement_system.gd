extends Node
signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)
const ACHIEVEMENTS = {
	"first_mission": {
		"icon": "res://1.Codebase/src/assets/icons/scroll.png",
	},
	"reality_seeker": {
		"icon": "res://1.Codebase/src/assets/icons/crystal.png",
	},
	"reality_crisis": {
		"icon": "res://1.Codebase/src/assets/icons/abyss.png",
	},
	"positive_resistance": {
		"icon": "res://1.Codebase/src/assets/icons/guardian.png",
	},
	"positive_victim": {
		"icon": "res://1.Codebase/src/assets/icons/fire.png",
	},
	"entropy_witness": {
		"icon": "res://1.Codebase/src/assets/icons/portal.png",
	},
	"diary_keeper": {
		"icon": "res://1.Codebase/src/assets/icons/scroll.png",
	},
	"master_complainer": {
		"icon": "res://1.Codebase/src/assets/icons/spirit.png",
	},
	"faithful_noodler": {
		"icon": "res://1.Codebase/src/assets/icons/altar.png",
	},
	"skill_master": {
		"icon": "res://1.Codebase/src/assets/icons/key.png",
	},
	"survivor": {
		"icon": "res://1.Codebase/src/assets/icons/chest.png",
	},
	"veteran": {
		"icon": "res://1.Codebase/src/assets/icons/statue.png",
	},
	"logic_master": {
		"icon": "res://1.Codebase/src/assets/icons/crystal.png",
	},
	"perception_expert": {
		"icon": "res://1.Codebase/src/assets/icons/orb.png",
	},
	"balanced_mind": {
		"icon": "res://1.Codebase/src/assets/icons/plant.png",
	},
	"moral_philosopher": {
		"icon": "res://1.Codebase/src/assets/icons/scroll.png",
	},
	"trolley_conductor": {
		"icon": "res://1.Codebase/src/assets/icons/key.png",
	},
	"complicit": {
		"icon": "res://1.Codebase/src/assets/icons/abyss.png",
	},
	"tutorial_master": {
		"icon": "res://1.Codebase/src/assets/icons/scroll.png",
	},
}
var unlocked_achievements: Dictionary = { }
var _progress_counters: Dictionary = {
	"missions_completed": 0,
	"journal_entries": 0,
	"gloria_triggers": 0,
	"prayers_made": 0,
	"logic_successes": 0,
	"perception_successes": 0,
	"balanced_turns": 0,
	"dilemmas_resolved": 0,
}
var skill_check_counters: Dictionary:
	get:
		return {
			"logic": _progress_counters.get("logic_successes", 0),
			"perception": _progress_counters.get("perception_successes", 0),
			"composure": _progress_counters.get("composure_successes", 0),
			"empathy": _progress_counters.get("empathy_successes", 0)
		}
var journal_entry_count: int:
	get:
		return _progress_counters.get("journal_entries", 0)
var moral_dilemma_count: int:
	get:
		return _progress_counters.get("dilemmas_resolved", 0)
var _event_bus: Variant = null
var _error_reporter: Variant = null
var _game_state: Variant = null
var _notification_system: Variant = null
var _audio_manager: Variant = null
var _localization_manager: Variant = null
func _ready():
	_refresh_dependencies()
	call_deferred("_refresh_dependencies")
	_subscribe_to_events()
	load_achievements()
	_apply_pending_state()
func _exit_tree():
	_unsubscribe_from_events()
	unlocked_achievements.clear()
	_progress_counters.clear()
func check_mission_complete():
	_progress_counters["missions_completed"] += 1
	if _progress_counters["missions_completed"] == 1:
		unlock_achievement("first_mission")
	elif _progress_counters["missions_completed"] == 10:
		unlock_achievement("survivor")
	elif _progress_counters["missions_completed"] == 50:
		unlock_achievement("veteran")
	save_achievements()
func check_journal_entry():
	_progress_counters["journal_entries"] += 1
	if _progress_counters["journal_entries"] >= 10:
		unlock_achievement("diary_keeper")
	save_achievements()
func check_gloria_trigger():
	_progress_counters["gloria_triggers"] += 1
	if _progress_counters["gloria_triggers"] >= 3:
		unlock_achievement("master_complainer")
	save_achievements()
func check_prayer():
	_progress_counters["prayers_made"] += 1
	if _progress_counters["prayers_made"] >= 10:
		unlock_achievement("faithful_noodler")
	save_achievements()
func check_skill_check_success(skill_name: String):
	match skill_name:
		"logic":
			_progress_counters["logic_successes"] += 1
			if _progress_counters["logic_successes"] >= 10:
				unlock_achievement("logic_master")
		"perception":
			_progress_counters["perception_successes"] += 1
			if _progress_counters["perception_successes"] >= 10:
				unlock_achievement("perception_expert")
	save_achievements()
func check_dilemma_resolved():
	_progress_counters["dilemmas_resolved"] += 1
	match _progress_counters["dilemmas_resolved"]:
		1:
			unlock_achievement("moral_philosopher")
		5:
			unlock_achievement("trolley_conductor")
		10:
			unlock_achievement("complicit")
	save_achievements()
func _on_reality_score_event(payload: Dictionary) -> void:
	var new_value := int(payload.get("new_value", 0))
	_check_reality_achievements(new_value)
func _on_positive_energy_event(payload: Dictionary) -> void:
	var new_value := int(payload.get("new_value", 0))
	_check_positive_achievements(new_value)
func _on_entropy_level_event(payload: Dictionary) -> void:
	var new_value := int(payload.get("new_value", 0))
	_check_entropy_achievements(new_value)
func _on_stats_changed_event(_payload: Dictionary) -> void:
	_check_stat_achievements()
func _check_reality_achievements(new_value: int) -> void:
	if new_value >= 80:
		unlock_achievement("reality_seeker")
	elif new_value <= 20:
		unlock_achievement("reality_crisis")
	_check_balanced_mind()
func _check_positive_achievements(new_value: int) -> void:
	if new_value <= 30:
		unlock_achievement("positive_resistance")
	elif new_value >= 90:
		unlock_achievement("positive_victim")
	_check_balanced_mind()
func _check_entropy_achievements(new_value: int) -> void:
	if new_value >= 100:
		unlock_achievement("entropy_witness")
func _check_stat_achievements() -> void:
	var stats: Dictionary = _get_all_stats()
	if stats.is_empty():
		return
	var skills_variant: Variant = stats.get("skills", Dictionary())
	if skills_variant is Dictionary:
		var skills: Dictionary = skills_variant as Dictionary
		for stat_name in skills.keys():
			if int(skills[stat_name]) >= 10:
				unlock_achievement("skill_master")
				break
func _check_balanced_mind() -> void:
	var stats: Dictionary = _get_all_stats()
	if stats.is_empty():
		return
	var reality: int = int(stats.get("reality_score", 0))
	var positive: int = int(stats.get("positive_energy", 0))
	if reality >= 40 and reality <= 60 and positive >= 40 and positive <= 60:
		_progress_counters["balanced_turns"] += 1
		if _progress_counters["balanced_turns"] >= 5:
			unlock_achievement("balanced_mind")
	else:
		_progress_counters["balanced_turns"] = 0
	save_achievements()
func unlock_achievement(achievement_id: String) -> void:
	if unlocked_achievements.has(achievement_id):
		return
	if not ACHIEVEMENTS.has(achievement_id):
		_report_warning("Unknown achievement requested", { "achievement_id": achievement_id })
		return
	var timestamp: int = int(Time.get_unix_time_from_system())
	unlocked_achievements[achievement_id] = timestamp
	var achievement_data: Dictionary = ACHIEVEMENTS[achievement_id].duplicate()
	achievement_data["id"] = achievement_id
	achievement_data["unlocked_at"] = timestamp
	achievement_unlocked.emit(achievement_id, achievement_data)
	_show_achievement_notification(achievement_data)
	var audio_manager: Variant = _get_audio_manager()
	if audio_manager and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx("group_present")
func _show_achievement_notification(achievement_data: Dictionary) -> void:
	var lang: String = _get_current_language()
	var achievement_id: String = String(achievement_data.get("id", ""))
	var localization_manager: Variant = _get_localization_manager()
	var title: String = ""
	var description: String = ""
	if localization_manager and not achievement_id.is_empty():
		var title_key: String = "ACHIEVEMENT_" + achievement_id + "_TITLE"
		var desc_key: String = "ACHIEVEMENT_" + achievement_id + "_DESC"
		title = localization_manager.get_translation(title_key, lang)
		description = localization_manager.get_translation(desc_key, lang)
		if title == title_key:
			title = ""
		if description == desc_key:
			description = ""
	if title.is_empty():
		var title_field: String = "title_" + lang
		title = String(achievement_data.get(title_field, achievement_data.get("title_zh", achievement_data.get("title_en", "Achievement"))))
	if description.is_empty():
		var desc_field: String = "description_" + lang
		description = String(achievement_data.get(desc_field, achievement_data.get("description_zh", achievement_data.get("description_en", ""))))
	var prefix: String = "[Achievement] " if lang == "en" else "[成就] "
	var notification_title: String = prefix + title
	var notification_system: Variant = _get_notification_system()
	if notification_system and notification_system.has_method("show_success"):
		notification_system.show_success(notification_title, description)
	else:
		_report_info("Achievement unlocked", { "title": title })
func is_unlocked(achievement_id: String) -> bool:
	return unlocked_achievements.has(achievement_id)
func get_unlocked_achievements() -> Dictionary:
	return unlocked_achievements
func get_all_achievements() -> Dictionary:
	return ACHIEVEMENTS
func get_unlocked_count() -> int:
	return unlocked_achievements.size()
func get_total_count() -> int:
	return ACHIEVEMENTS.size()
func get_progress_percentage() -> float:
	if ACHIEVEMENTS.is_empty():
		return 0.0
	return (float(unlocked_achievements.size()) / float(ACHIEVEMENTS.size())) * 100.0
func get_achievement_list() -> Array:
	var achievements: Array = []
	var lang: String = _get_current_language()
	var localization_manager: Variant = _get_localization_manager()
	for achievement_id in ACHIEVEMENTS.keys():
		var achievement: Dictionary = ACHIEVEMENTS[achievement_id].duplicate()
		achievement["id"] = achievement_id
		achievement["unlocked"] = is_unlocked(achievement_id)
		if localization_manager:
			var title_key: String = "ACHIEVEMENT_" + achievement_id + "_TITLE"
			var desc_key: String = "ACHIEVEMENT_" + achievement_id + "_DESC"
			var title: String = localization_manager.get_translation(title_key, lang)
			var description: String = localization_manager.get_translation(desc_key, lang)
			achievement["title"] = title if not title.is_empty() else achievement_id.replace("_", " ").capitalize()
			achievement["description"] = description if not description.is_empty() else "Achievement description not available"
		else:
			achievement["title"] = achievement_id.replace("_", " ").capitalize()
			achievement["description"] = "Localization system unavailable"
		if achievement["unlocked"]:
			achievement["unlocked_at"] = unlocked_achievements[achievement_id]
		achievements.append(achievement)
	return achievements
func save_achievements() -> void:
	var game_state: Variant = _get_game_state()
	if not game_state:
		_report_warning("Unable to save achievements because GameState is unavailable")
		return
	game_state.set_metadata("achievements", unlocked_achievements)
	game_state.set_metadata("achievement_progress", _progress_counters)
	game_state.save_game()
func load_achievements() -> void:
	var game_state: Variant = _get_game_state()
	if not game_state:
		return
	var saved_achievements_variant: Variant = game_state.get_metadata("achievements", Dictionary())
	if saved_achievements_variant is Dictionary:
		var saved_achievements: Dictionary = saved_achievements_variant as Dictionary
		unlocked_achievements = saved_achievements.duplicate(true)
	var saved_progress_variant: Variant = game_state.get_metadata("achievement_progress", Dictionary())
	if saved_progress_variant is Dictionary:
		var saved_progress: Dictionary = saved_progress_variant as Dictionary
		for key in saved_progress.keys():
			_progress_counters[key] = saved_progress[key]
func reset_achievements() -> void:
	unlocked_achievements.clear()
	_progress_counters = {
		"missions_completed": 0,
		"journal_entries": 0,
		"gloria_triggers": 0,
		"prayers_made": 0,
		"logic_successes": 0,
		"perception_successes": 0,
		"balanced_turns": 0,
		"dilemmas_resolved": 0,
	}
	save_achievements()
func get_state_snapshot() -> Dictionary:
	return {
		"unlocked": unlocked_achievements.duplicate(true),
		"progress": _progress_counters.duplicate(true),
	}
func load_state_snapshot(state: Dictionary) -> void:
	if state.is_empty():
		return
	var unlocked_state_variant: Variant = state.get("unlocked", Dictionary())
	if unlocked_state_variant is Dictionary:
		var unlocked_state: Dictionary = unlocked_state_variant as Dictionary
		unlocked_achievements = unlocked_state.duplicate(true)
	var progress_state_variant: Variant = state.get("progress", Dictionary())
	if progress_state_variant is Dictionary:
		var progress_state: Dictionary = progress_state_variant as Dictionary
		for key in progress_state.keys():
			_progress_counters[key] = progress_state[key]
	var game_state: Variant = _get_game_state()
	if game_state:
		game_state.set_metadata("achievements", unlocked_achievements)
		game_state.set_metadata("achievement_progress", _progress_counters)
func _refresh_dependencies() -> void:
	if not ServiceLocator:
		return
	_event_bus = ServiceLocator.get_event_bus()
	_error_reporter = ServiceLocator.get_error_reporter()
	_game_state = ServiceLocator.get_game_state()
	_notification_system = ServiceLocator.get_notification_system()
	_audio_manager = ServiceLocator.get_audio_manager()
	_localization_manager = ServiceLocator.get_localization_manager()
func _subscribe_to_events() -> void:
	var event_bus: Variant = _get_event_bus()
	if not event_bus:
		_report_warning("EventBus unavailable; achievements will not auto-update")
		return
	event_bus.subscribe("stats_changed", self, "_on_stats_changed_event")
	event_bus.subscribe("reality_score_changed", self, "_on_reality_score_event")
	event_bus.subscribe("positive_energy_changed", self, "_on_positive_energy_event")
	event_bus.subscribe("entropy_level_changed", self, "_on_entropy_level_event")
func _unsubscribe_from_events() -> void:
	var event_bus: Variant = _get_event_bus()
	if not event_bus:
		return
	event_bus.unsubscribe("stats_changed", self, "_on_stats_changed_event")
	event_bus.unsubscribe("reality_score_changed", self, "_on_reality_score_event")
	event_bus.unsubscribe("positive_energy_changed", self, "_on_positive_energy_event")
	event_bus.unsubscribe("entropy_level_changed", self, "_on_entropy_level_event")
func _apply_pending_state() -> void:
	var game_state: Variant = _get_game_state()
	if not game_state:
		return
	var pending_state_variant: Variant = game_state.get_metadata("pending_achievement_state", null)
	if pending_state_variant is Dictionary:
		var pending_state: Dictionary = pending_state_variant as Dictionary
		if not pending_state.is_empty():
			load_state_snapshot(pending_state)
			game_state.set_metadata("pending_achievement_state", null)
func _get_event_bus() -> Variant:
	if not is_instance_valid(_event_bus):
		_refresh_dependencies()
	return _event_bus
func _get_error_reporter() -> Variant:
	if not is_instance_valid(_error_reporter):
		_refresh_dependencies()
	return _error_reporter
func _get_game_state() -> Variant:
	if not is_instance_valid(_game_state):
		_refresh_dependencies()
	return _game_state
func _get_notification_system() -> Variant:
	if not is_instance_valid(_notification_system):
		_refresh_dependencies()
	return _notification_system
func _get_audio_manager() -> Variant:
	if not is_instance_valid(_audio_manager):
		_refresh_dependencies()
	return _audio_manager
func _get_localization_manager() -> Variant:
	if not is_instance_valid(_localization_manager):
		_refresh_dependencies()
	return _localization_manager
func _get_all_stats() -> Dictionary:
	var event_bus: Variant = _get_event_bus()
	if event_bus:
		var response: Variant = event_bus.request("get_all_stats")
		if response is Dictionary:
			return response as Dictionary
	var game_state: Variant = _get_game_state()
	if not game_state:
		return Dictionary()
	return {
		"reality_score": game_state.reality_score,
		"positive_energy": game_state.positive_energy,
		"entropy_level": game_state.entropy_level,
		"skills": game_state.player_stats.duplicate() if game_state.player_stats else Dictionary(),
	}
func _get_current_language() -> String:
	var game_state: Variant = _get_game_state()
	if game_state:
		return String(game_state.current_language)
	return "en"
func _report_info(message: String, details: Dictionary = { }) -> void:
	var reporter: Variant = _get_error_reporter()
	if reporter:
		reporter.report_info("AchievementSystem", message, details)
func _report_warning(message: String, details: Dictionary = { }) -> void:
	var reporter: Variant = _get_error_reporter()
	if reporter:
		reporter.report_warning("AchievementSystem", message, details)
func _report_error(message: String, error_code: int = -1, details: Dictionary = { }) -> void:
	var reporter: Variant = _get_error_reporter()
	if reporter:
		reporter.report_error("AchievementSystem", message, error_code, false, details)
