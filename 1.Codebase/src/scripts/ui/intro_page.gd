extends Control
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const ICON_INFO = preload("res://1.Codebase/src/assets/ui/icon_info.svg")
const ICON_HOME = preload("res://1.Codebase/src/assets/ui/icon_home.svg")
const GODOT_LOGO = preload("res://1.Codebase/src/assets/Engine Logo.png")
const US_LOGO = preload("res://1.Codebase/src/assets/US_logo-1.png")
var current_language: String = "en"
var _audio_manager: Node = null
func _ready():
	current_language = GameState.current_language if GameState else "en"
	_create_stats_tab()
	_apply_modern_styling()
	_localize_content()
	var panel = $MenuContainer/Panel
	if panel:
		UIStyleManager.fade_in(panel, 0.4)
		UIStyleManager.slide_in_from_bottom(panel, 0.5, 30.0)
	_enforce_fullscreen()
func _enforce_fullscreen() -> void:
	var menu_container = $MenuContainer
	var panel = $MenuContainer/Panel
	if menu_container:
		menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	if panel:
		var viewport_size = get_viewport_rect().size
		var target_size = viewport_size * 0.9
		panel.custom_minimum_size = target_size
func _apply_modern_styling():
	var panel = $MenuContainer/Panel
	if panel:
		UIStyleManager.apply_panel_style(panel, 0.95, UIStyleManager.CORNER_RADIUS_LARGE)
	var characters_button = $MenuContainer/Panel/VBoxContainer/CharactersButton
	var close_button = $MenuContainer/Panel/VBoxContainer/CloseButton
	if characters_button:
		UIStyleManager.apply_button_style(characters_button, "accent", "large")
		characters_button.icon = ICON_INFO
		characters_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(characters_button, 1.06)
		UIStyleManager.add_press_feedback(characters_button)
		characters_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		characters_button.text = _tr("INTRO_BUTTON_CHARACTERS")
	if close_button:
		UIStyleManager.apply_button_style(close_button, "primary", "large")
		close_button.icon = ICON_HOME
		close_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(close_button, 1.06)
		UIStyleManager.add_press_feedback(close_button)
		close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		close_button.text = _tr("INTRO_BUTTON_CLOSE")
	var title_label = $MenuContainer/Panel/VBoxContainer/TitleLabel
	if title_label:
		title_label.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
func _localize_content():
	var title_label = $MenuContainer/Panel/VBoxContainer/TitleLabel
	if title_label:
		title_label.text = _tr("INTRO_TITLE")
	var tab_container = $MenuContainer/Panel/VBoxContainer/TabContainer
	if not tab_container:
		return
	tab_container.set_tab_title(0, _tr("INTRO_TAB_WORLD_TITLE"))
	tab_container.set_tab_title(1, _tr("INTRO_TAB_GAMEPLAY_TITLE"))
	tab_container.set_tab_title(2, _tr("INTRO_TAB_MECHANICS_TITLE"))
	tab_container.set_tab_title(3, _tr("INTRO_TAB_STATS_TITLE"))
	tab_container.set_tab_title(4, _tr("INTRO_TAB_CREDITS_TITLE"))
	var localize_tab_sections = func(tab_name: String):
		var tab = tab_container.get_node_or_null(tab_name)
		if not tab: return
		var vbox = tab.get_node_or_null("Margin/VBox")
		if not vbox: return
		for section in vbox.get_children():
			if not section is VBoxContainer: continue
			var sec_title = section.get_node_or_null("Title")
			var sec_content = section.get_node_or_null("Content")
			if sec_title and sec_title.text.begins_with("INTRO_"):
				sec_title.text = _tr(sec_title.text)
			if sec_content and sec_content.text.begins_with("INTRO_"):
				sec_content.text = _tr(sec_content.text)
	localize_tab_sections.call("World")
	localize_tab_sections.call("Gameplay")
	localize_tab_sections.call("Mechanics")
	localize_tab_sections.call("Stats")
	localize_tab_sections.call("Credits")
func _create_stats_tab():
	var tab_container = $MenuContainer/Panel/VBoxContainer/TabContainer
	if not tab_container:
		return
	if tab_container.has_node("Stats"):
		return
	var scroll = ScrollContainer.new()
	scroll.name = "Stats"
	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 24)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)
	scroll.add_child(margin)
	var sections = [
		{"title": "INTRO_TAB_STATS_REALITY_TITLE", "body": "INTRO_TAB_STATS_REALITY_BODY"},
		{"title": "INTRO_TAB_STATS_POSITIVE_TITLE", "body": "INTRO_TAB_STATS_POSITIVE_BODY"},
		{"title": "INTRO_TAB_STATS_ENTROPY_TITLE", "body": "INTRO_TAB_STATS_ENTROPY_BODY"}
	]
	for section_data in sections:
		var section_vbox = VBoxContainer.new()
		section_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title = Label.new()
		title.name = "Title"
		title.text = section_data["title"] 
		title.add_theme_font_size_override("font_size", 22)
		title.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0)) 
		var body = RichTextLabel.new()
		body.name = "Content"
		body.text = section_data["body"] 
		body.fit_content = true
		body.bbcode_enabled = true
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_theme_color_override("default_color", Color(0.9, 0.9, 0.9))
		section_vbox.add_child(title)
		section_vbox.add_child(body)
		vbox.add_child(section_vbox)
		if section_data != sections.back():
			var sep = HSeparator.new()
			sep.modulate = Color(1, 1, 1, 0.3)
			vbox.add_child(sep)
	tab_container.add_child(scroll)
	tab_container.move_child(scroll, 3)
	tab_container.set_tab_title(3, _tr("INTRO_TAB_STATS_TITLE"))
func _on_close_pressed():
	var audio := _get_audio_manager()
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx("menu_click")
	var parent = get_parent()
	var parent_script = parent.get_script()
	if parent and (parent.name == "StartMenu" or (parent_script and parent_script.resource_path.contains("start_menu"))):
		queue_free()
	else:
		get_tree().change_scene_to_file("res://1.Codebase/src/scenes/ui/start_menu.tscn")
func _on_characters_button_pressed():
	var audio := _get_audio_manager()
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx("menu_click")
	var characters_scene = load("res://1.Codebase/src/scenes/ui/characters_page.tscn")
	if characters_scene:
		var characters = characters_scene.instantiate()
		add_child(characters)
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key, current_language)
	return key
func _get_audio_manager() -> Node:
	if is_instance_valid(_audio_manager):
		return _audio_manager
	if ServiceLocator:
		_audio_manager = ServiceLocator.get_audio_manager()
	return _audio_manager
