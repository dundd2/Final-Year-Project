extends Node
const TUTORIAL_POPUP_SCENE: PackedScene = preload("res://1.Codebase/src/scenes/ui/tutorial_popup.tscn")
const ERROR_CONTEXT := "TutorialSystem"
var game_state: Node = null 
var achievement_system: Node = null 
var notification_system: Node = null 
var tutorial_steps: Array[Dictionary] = [
	{
		"id": "first_choice",
		"trigger": "first_choice",
		"highlight": "choice_buttons",
		"priority": 1,
	},
	{
		"id": "first_stat_change",
		"trigger": "first_stat_change",
		"highlight": "reality_stat",
		"priority": 2,
	},
	{
		"id": "first_prayer",
		"trigger": "first_prayer",
		"highlight": "prayer_button",
		"priority": 3,
	},
	{
		"id": "first_mission",
		"trigger": "first_mission_complete",
		"highlight": "journal_button",
		"priority": 4,
	},
	{
		"id": "first_skill_check",
		"trigger": "first_skill_check",
		"highlight": "skills_display",
		"priority": 5,
	},
	{
		"id": "first_gloria_intervention",
		"trigger": "first_gloria_intervention",
		"highlight": "complaint_counter",
		"priority": 6,
	},
	{
		"id": "first_entropy_surge",
		"trigger": "first_entropy_surge",
		"highlight": "entropy_stat",
		"priority": 7,
	},
	{
		"id": "first_night_cycle",
		"trigger": "first_night_cycle",
		"highlight": "night_overlay",
		"priority": 8,
	},
]
var completed_tutorials: Dictionary = { }
var tutorial_enabled: bool = true
var current_tutorial_popup: Control = null
const SAVE_KEY: String = "tutorial_progress"
signal tutorial_triggered(step: Dictionary)
signal tutorial_completed(step_id: String)
signal all_tutorials_completed
func _ready() -> void:
	_initialize_dependencies()
	load_tutorial_progress()
	_connect_game_state_signals()
func _initialize_dependencies() -> void:
	if ServiceLocator:
		game_state = ServiceLocator.get_game_state()
		achievement_system = ServiceLocator.get_achievement_system()
		notification_system = ServiceLocator.get_notification_system()
	else:
		ErrorReporterBridge.report_error(ERROR_CONTEXT, "ServiceLocator not available - tutorial system will not function")
func check_tutorial_trigger(event: String) -> void:
	if not tutorial_enabled:
		return
	for step in tutorial_steps:
		if step.get("trigger", "") == event and not completed_tutorials.get(step["id"], false):
			show_tutorial_popup(step)
			completed_tutorials[step["id"]] = true
			tutorial_triggered.emit(step)
			tutorial_completed.emit(step["id"])
			save_tutorial_progress()
			check_all_tutorials_complete()
			break
func show_tutorial_popup(step: Dictionary) -> void:
	if current_tutorial_popup != null:
		return
	var language: String = _get_current_language()
	var step_id: String = step.get("id", "")
	var text: String = ""
	if LocalizationManager:
		var translation_key := "TUTORIAL_" + step_id
		text = LocalizationManager.get_translation(translation_key, language)
	if text.is_empty():
		text = "Tutorial: " + step_id.replace("_", " ").capitalize()
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Missing translation for: TUTORIAL_%s" % step_id, { "step_id": step_id })
	var highlight: String = step.get("highlight", "")
	_create_tutorial_popup(text, highlight, step_id)
func _create_tutorial_popup(text: String, highlight_element: String, step_id: String) -> void:
	if TUTORIAL_POPUP_SCENE == null:
		_emit_notification_fallback(text)
		return
	var instance: Node = TUTORIAL_POPUP_SCENE.instantiate()
	var popup_instance: Control = instance as Control
	if popup_instance == null:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Failed to instantiate tutorial popup scene")
		_emit_notification_fallback(text)
		return
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "SceneTree unavailable; cannot display tutorial popup")
		_emit_notification_fallback(text)
		return
	current_tutorial_popup = popup_instance
	tree.root.add_child(current_tutorial_popup)
	if current_tutorial_popup.has_method("setup"):
		current_tutorial_popup.call("setup", text, highlight_element, step_id)
	if current_tutorial_popup.has_signal("popup_closed") and not current_tutorial_popup.popup_closed.is_connected(_on_tutorial_popup_closed):
		current_tutorial_popup.popup_closed.connect(_on_tutorial_popup_closed)
func _on_tutorial_popup_closed() -> void:
	current_tutorial_popup = null
func check_all_tutorials_complete() -> void:
	for step in tutorial_steps:
		if not completed_tutorials.get(step["id"], false):
			return
	all_tutorials_completed.emit()
	if achievement_system and achievement_system.has_method("unlock_achievement"):
		achievement_system.unlock_achievement("tutorial_master")
func is_tutorial_completed(step_id: String) -> bool:
	return completed_tutorials.get(step_id, false)
func reset_tutorials() -> void:
	completed_tutorials.clear()
	save_tutorial_progress()
func set_tutorial_enabled(enabled: bool) -> void:
	tutorial_enabled = enabled
func get_tutorial_progress() -> float:
	var completed_count: int = 0
	for step in tutorial_steps:
		if completed_tutorials.get(step["id"], false):
			completed_count += 1
	if tutorial_steps.is_empty():
		return 0.0
	return float(completed_count) / float(tutorial_steps.size()) * 100.0
func save_tutorial_progress() -> void:
	if game_state and game_state.has_method("set_metadata"):
		game_state.set_metadata(SAVE_KEY, completed_tutorials)
func load_tutorial_progress() -> void:
	if game_state and game_state.has_method("get_metadata"):
		var saved_progress: Variant = game_state.get_metadata(SAVE_KEY)
		if saved_progress is Dictionary:
			completed_tutorials = (saved_progress as Dictionary).duplicate(true)
func _on_reality_score_changed(_new_value: int) -> void:
	if not is_tutorial_completed("first_stat_change"):
		check_tutorial_trigger("first_stat_change")
func _on_positive_energy_changed(_new_value: int) -> void:
	if not is_tutorial_completed("first_stat_change"):
		check_tutorial_trigger("first_stat_change")
func _on_entropy_changed(new_value: int) -> void:
	if not is_tutorial_completed("first_stat_change"):
		check_tutorial_trigger("first_stat_change")
	if new_value >= 10 and not is_tutorial_completed("first_entropy_surge"):
		check_tutorial_trigger("first_entropy_surge")
func _on_stats_changed() -> void:
	if not is_tutorial_completed("first_stat_change"):
		check_tutorial_trigger("first_stat_change")
func get_all_tutorial_steps() -> Array:
	return tutorial_steps.duplicate(true)
func get_completed_tutorials() -> Array:
	var completed_ids: Array = []
	for step_id in completed_tutorials:
		if completed_tutorials[step_id]:
			completed_ids.append(step_id)
	return completed_ids
func trigger_tutorial(step_id: String) -> void:
	for step in tutorial_steps:
		if step.get("id", "") == step_id:
			show_tutorial_popup(step)
			break
func _connect_game_state_signals() -> void:
	if game_state == null:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "GameState not available; automatic triggers disabled")
		return
	if game_state.has_signal("reality_score_changed") and not game_state.reality_score_changed.is_connected(_on_reality_score_changed):
		game_state.reality_score_changed.connect(_on_reality_score_changed)
	if game_state.has_signal("positive_energy_changed") and not game_state.positive_energy_changed.is_connected(_on_positive_energy_changed):
		game_state.positive_energy_changed.connect(_on_positive_energy_changed)
	if game_state.has_signal("entropy_level_changed") and not game_state.entropy_level_changed.is_connected(_on_entropy_changed):
		game_state.entropy_level_changed.connect(_on_entropy_changed)
	if game_state.has_signal("stats_changed") and not game_state.stats_changed.is_connected(_on_stats_changed):
		game_state.stats_changed.connect(_on_stats_changed)
func _emit_notification_fallback(text: String) -> void:
	if notification_system and notification_system.has_method("show_notification"):
		notification_system.show_notification(text, "tutorial")
func _get_current_language() -> String:
	if game_state:
		var raw: Variant = game_state.get("current_language")
		if raw != null:
			return str(raw).strip_edges().to_lower()
		if game_state.has_method("get_language"):
			return str(game_state.get_language()).strip_edges().to_lower()
	return "en"
