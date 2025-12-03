extends Control
const ERROR_CONTEXT := "AchievementViewer"
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const UIConstants = preload("res://1.Codebase/src/scripts/ui/ui_constants.gd")
const ICON_ACHIEVEMENTS = preload("res://1.Codebase/src/assets/ui/icon_achievements.svg")
@onready var achievement_list: VBoxContainer = $CenterContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/AchievementList
@onready var progress_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/Header/ProgressLabel
@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/Header/TitleContainer/TitleLabel
@onready var close_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/Footer/CloseButton
var _audio_manager: Node = null
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_modern_styling()
	refresh_achievements()
	update_ui_language()
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	var panel = $CenterContainer/Panel
	if panel:
		UIStyleManager.fade_in(panel, 0.4)
		UIStyleManager.slide_in_from_bottom(panel, 0.5, 30.0)
	_enforce_fullscreen()
func _enforce_fullscreen() -> void:
	var center_container = $CenterContainer
	var panel = $CenterContainer/Panel
	if center_container:
		center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	if panel:
		var viewport_size = get_viewport_rect().size
		var target_size = viewport_size * 0.9
		panel.custom_minimum_size = target_size
func _apply_modern_styling():
	var panel = $CenterContainer/Panel
	if panel:
		UIStyleManager.apply_panel_style(panel, 0.95, UIStyleManager.CORNER_RADIUS_LARGE)
	if close_button:
		UIStyleManager.apply_button_style(close_button, "primary", "large")
		UIStyleManager.add_hover_scale_effect(close_button, 1.06)
		UIStyleManager.add_press_feedback(close_button)
		close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if title_label:
		UIConstants.apply_title_style(title_label)
func _tr_key(key: String, lang: String = "") -> String:
	if LocalizationManager:
		var resolved_lang = lang if not lang.is_empty() else _get_current_language()
		return LocalizationManager.get_translation(key, resolved_lang)
	return key
func update_ui_language():
	var lang = _get_current_language()
	if title_label:
		title_label.text = _tr_key("ACHIEVEMENT_VIEWER_TITLE", lang)
		if title_label is Label:
			pass
	if close_button:
		close_button.text = _tr_key("UI_CLOSE_BUTTON", lang)
func refresh_achievements():
	var achievement_system = ServiceLocator.get_achievement_system() if ServiceLocator else null
	if not achievement_system:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "AchievementSystem not found! Please add it as an autoload in Project Settings.")
		_show_setup_instructions()
		return
	for child in achievement_list.get_children():
		child.queue_free()
	var unlocked_count = achievement_system.get_unlocked_count()
	var total_count = achievement_system.get_total_count()
	var progress_pct = achievement_system.get_progress_percentage()
	var lang = _get_current_language()
	var progress_format := _tr_key("ACHIEVEMENT_PROGRESS_SUMMARY", lang)
	progress_label.text = progress_format % [unlocked_count, total_count, progress_pct]
	var achievements = achievement_system.get_achievement_list()
	achievements.sort_custom(
		func(a, b):
		if a["unlocked"] != b["unlocked"]:
			return a["unlocked"]
		return a["id"] < b["id"]
	)
	for achievement in achievements:
		var progress_hint = get_progress_hint(achievement["id"], achievement_system)
		var achievement_item = create_achievement_item(achievement, progress_hint)
		achievement_list.add_child(achievement_item)
func create_achievement_item(achievement: Dictionary, progress_hint: String = "") -> Control:
	var item = PanelContainer.new()
	if achievement["unlocked"]:
		item.add_theme_stylebox_override("panel", UIConstants.create_success_panel_style())
	else:
		item.add_theme_stylebox_override("panel", UIConstants.create_locked_panel_style())
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	item.add_child(margin)
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	margin.add_child(hbox)
	if achievement.has("icon") and achievement["icon"] != "":
		var icon_path = achievement["icon"]
		if ResourceLoader.exists(icon_path):
			var texture_rect = TextureRect.new()
			texture_rect.texture = load(icon_path)
			texture_rect.custom_minimum_size = Vector2(48, 48)
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			if not achievement["unlocked"]:
				texture_rect.modulate = UIConstants.COLOR_LOCKED
			hbox.add_child(texture_rect)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	var title_label = Label.new()
	var title_text = achievement.get("title", "Achievement")
	if achievement["unlocked"]:
		title_label.text = title_text
	else:
		title_label.text = title_text
	title_label.add_theme_font_size_override("font_size", 18)
	if achievement["unlocked"]:
		title_label.add_theme_color_override("font_color", UIConstants.COLOR_TITLE_GOLD)
	else:
		title_label.add_theme_color_override("font_color", UIConstants.COLOR_TITLE_MUTED)
	vbox.add_child(title_label)
	var desc_label = Label.new()
	desc_label.text = achievement.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_font_size_override("font_size", 14)
	if not achievement["unlocked"]:
		desc_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_SECONDARY)
	vbox.add_child(desc_label)
	if not achievement["unlocked"] and progress_hint != "":
		var progress_label = Label.new()
		progress_label.text = "⏳ " + progress_hint
		progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		progress_label.add_theme_font_size_override("font_size", 13)
		progress_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_HIGHLIGHT)
		vbox.add_child(progress_label)
	if achievement["unlocked"] and achievement.has("unlocked_at"):
		var time_label = Label.new()
		var timestamp = achievement["unlocked_at"]
		var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
		var lang = _get_current_language()
		var unlocked_text = _tr_key("ACHIEVEMENT_UNLOCKED_AT_LABEL", lang)
		time_label.text = unlocked_text + "%04d-%02d-%02d %02d:%02d" % [
			datetime["year"],
			datetime["month"],
			datetime["day"],
			datetime["hour"],
			datetime["minute"],
		]
		time_label.add_theme_font_size_override("font_size", 12)
		time_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_SECONDARY)
		vbox.add_child(time_label)
	return item
func _show_setup_instructions():
	for child in achievement_list.get_children():
		child.queue_free()
	var lang = _get_current_language()
	if progress_label:
		progress_label.text = LocalizationManager.get_translation("UI_ACHIEVEMENT_SYSTEM_NOT_CONFIGURED", lang)
	var instruction_panel = PanelContainer.new()
	instruction_panel.add_theme_stylebox_override("panel", UIConstants.create_error_panel_style())
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	instruction_panel.add_child(margin)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	var title = Label.new()
	title.text = _tr_key("ACHIEVEMENT_SETUP_TITLE", lang)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", UIConstants.COLOR_WARNING)
	vbox.add_child(title)
	var instructions = RichTextLabel.new()
	instructions.bbcode_enabled = true
	instructions.fit_content = true
	instructions.custom_minimum_size = Vector2(600, 0)
	instructions.text = _tr_key("ACHIEVEMENT_SETUP_BODY", lang)
	vbox.add_child(instructions)
	achievement_list.add_child(instruction_panel)
func get_progress_hint(achievement_id: String, achievement_system) -> String:
	var lang := _get_current_language()
	if achievement_system == null:
		return ""
	var progress_source = null
	if achievement_system.has_method("get"):
		progress_source = achievement_system.get("_progress_counters")
	var progress: Dictionary = progress_source if progress_source is Dictionary else {}
	var game_state := _get_game_state()
	match achievement_id:
		"first_mission":
			return _tr_key("ACHIEVEMENT_HINT_FIRST_MISSION", lang)
		"survivor":
			var survivor_count := int(progress.get("missions_completed", 0))
			return _tr_key("ACHIEVEMENT_HINT_SURVIVOR", lang) % survivor_count
		"veteran":
			var veteran_count := int(progress.get("missions_completed", 0))
			return _tr_key("ACHIEVEMENT_HINT_VETERAN", lang) % veteran_count
		"diary_keeper":
			var diary_count := int(progress.get("journal_entries", 0))
			return _tr_key("ACHIEVEMENT_HINT_DIARY_KEEPER", lang) % diary_count
		"master_complainer":
			var complain_count := int(progress.get("gloria_triggers", 0))
			return _tr_key("ACHIEVEMENT_HINT_MASTER_COMPLAINER", lang) % complain_count
		"faithful_noodler":
			var prayer_count := int(progress.get("prayers_made", 0))
			return _tr_key("ACHIEVEMENT_HINT_FAITHFUL_NOODLER", lang) % prayer_count
		"logic_master":
			var logic_count := int(progress.get("logic_successes", 0))
			return _tr_key("ACHIEVEMENT_HINT_LOGIC_MASTER", lang) % logic_count
		"perception_expert":
			var perception_count := int(progress.get("perception_successes", 0))
			return _tr_key("ACHIEVEMENT_HINT_PERCEPTION_EXPERT", lang) % perception_count
		"reality_seeker":
			var reality_value: int = game_state.reality_score if game_state else 0
			return _tr_key("ACHIEVEMENT_HINT_REALITY_SEEKER", lang) % int(reality_value)
		"reality_crisis":
			var crisis_value: int = game_state.reality_score if game_state else 0
			return _tr_key("ACHIEVEMENT_HINT_REALITY_CRISIS", lang) % int(crisis_value)
		"positive_resistance":
			var positive_resist: int = game_state.positive_energy if game_state else 0
			return _tr_key("ACHIEVEMENT_HINT_POSITIVE_RESISTANCE", lang) % int(positive_resist)
		"positive_victim":
			var positive_victim: int = game_state.positive_energy if game_state else 0
			return _tr_key("ACHIEVEMENT_HINT_POSITIVE_VICTIM", lang) % int(positive_victim)
		"entropy_witness":
			var entropy_value: int = game_state.entropy_level if game_state else 0
			return _tr_key("ACHIEVEMENT_HINT_ENTROPY_WITNESS", lang) % int(entropy_value)
		"skill_master":
			var highest_skill := 0
			if game_state and game_state.player_stats is Dictionary:
				for stat in (game_state.player_stats as Dictionary).values():
					if stat is int or stat is float:
						highest_skill = max(highest_skill, int(stat))
			return _tr_key("ACHIEVEMENT_HINT_SKILL_MASTER", lang) % highest_skill
		"balanced_mind":
			var balanced_turns := int(progress.get("balanced_turns", 0))
			var balanced_reality: int = game_state.reality_score if game_state else 0
			var balanced_positive: int = game_state.positive_energy if game_state else 0
			return _tr_key("ACHIEVEMENT_HINT_BALANCED_MIND", lang) % [
				int(balanced_reality),
				int(balanced_positive),
				balanced_turns,
			]
		_:
			return ""
	return ""
func _on_close_pressed():
	var audio := _get_audio_manager()
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx("menu_click", 0.7)
	queue_free()
func _get_audio_manager() -> Node:
	if is_instance_valid(_audio_manager):
		return _audio_manager
	if ServiceLocator:
		_audio_manager = ServiceLocator.get_audio_manager()
	return _audio_manager
func _get_game_state() -> Node:
	return ServiceLocator.get_game_state() if ServiceLocator else null
func _get_current_language() -> String:
	var game_state := _get_game_state()
	if not game_state:
		return "en"
	var language = game_state.get("current_language")
	return language if typeof(language) == TYPE_STRING and language != "" else "en"
