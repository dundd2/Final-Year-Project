extends Control
const ERROR_CONTEXT := "StartMenu"
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const ICON_JOURNAL = preload("res://1.Codebase/src/assets/ui/icon_journal.svg")
const ICON_ACHIEVEMENTS = preload("res://1.Codebase/src/assets/ui/icon_achievements.svg")
const ICON_SETTINGS = preload("res://1.Codebase/src/assets/ui/icon_settings.svg")
const ICON_PLAY = preload("res://1.Codebase/src/assets/ui/icon_play.svg")
const ICON_SAVE = preload("res://1.Codebase/src/assets/ui/icon_save.svg")
const ICON_INFO = preload("res://1.Codebase/src/assets/ui/icon_info.svg")
const ICON_QUIT = preload("res://1.Codebase/src/assets/ui/icon_quit.svg")
const ICON_CREATIVE = preload("res://1.Codebase/src/assets/ui/icon_creative.svg")
const ICON_TERMS = preload("res://1.Codebase/src/assets/ui/icon_terms.svg")
const ICON_YOUTUBE = preload("res://1.Codebase/src/assets/ui/icon_youtube.svg")
const ICON_GITHUB = preload("res://1.Codebase/src/assets/ui/icon_github.svg")
const GITHUB_URL = "https://github.com/dundd2/Final-Year-Project"
const YOUTUBE_URL = "https://www.youtube.com/watch?v=dQw4w9WgXcQ/"
const GAME_VERSION = "v0.9 Beta"
const _GEMINI_KEY_MISSING_MESSAGE := "Gemini is selected, but no Gemini API key is configured. Open Settings → AI Settings to enter your key, or switch to OpenRouter/Ollama."
var current_language: String = "en"
var audio_manager: Node = null
var game_state: Node = null
var error_reporter: Node = null
var font_manager: Node = null
var github_button: TextureButton
var youtube_button: TextureButton
var version_label: Label
@onready var menu_container: CenterContainer = $MenuContainer
@onready var panel: Panel = $MenuContainer/Panel
@onready var content_container: VBoxContainer = $MenuContainer/Panel/VBoxContainer
@onready var spacer: Control = $MenuContainer/Panel/VBoxContainer/Spacer
@onready var logo_texture: TextureRect = $MenuContainer/Panel/VBoxContainer/LogoContainer/Logo
@onready var background_overlay: ColorRect = $BackgroundOverlay
@onready var scroll_container: ScrollContainer = $MenuContainer/Panel/VBoxContainer/ScrollContainer
@onready var buttons_container: VBoxContainer = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer
@onready var primary_buttons_grid: GridContainer = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/PrimaryButtonsGrid
@onready var start_button: Button = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/PrimaryButtonsGrid/StartButton
@onready var continue_button: Button = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/PrimaryButtonsGrid/ContinueButton
@onready var continue_info_label: Label = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/ContinueInfo
@onready var save_load_button: Button = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/PrimaryButtonsGrid/SaveLoadButton
@onready var journal_button: Button = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/PrimaryButtonsGrid/JournalButton
@onready var achievements_button: Button = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/PrimaryButtonsGrid/AchievementsButton
@onready var settings_button: Button = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/PrimaryButtonsGrid/SettingsButton
@onready var intro_button: Button = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/PrimaryButtonsGrid/IntroButton
@onready var quit_button: Button = $MenuContainer/Panel/VBoxContainer/ScrollContainer/ButtonsContainer/PrimaryButtonsGrid/QuitButton
@onready var creative_statement_button: Button = $MenuContainer/Panel/VBoxContainer/FooterButtons/CreativeStatementButton
@onready var terms_button: Button = $MenuContainer/Panel/VBoxContainer/FooterButtons/TermsButton
@onready var all_buttons: Array = [
	start_button,
	continue_button,
	save_load_button,
	journal_button,
	achievements_button,
	settings_button,
	intro_button,
	quit_button,
	creative_statement_button,
	terms_button,
]
func _ready():
	_refresh_services()
	_load_language_from_settings()
	if font_manager and font_manager.has_method("load_font_settings"):
		font_manager.load_font_settings()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	content_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_social_buttons()
	var state := _get_game_state()
	current_language = state.current_language if state else "en"
	update_ui_text()
	_apply_styles()
	update_ui_text()
	_apply_styles()
	_set_creative_statement_text()
	_assign_icons()
	_refresh_continue_state()
	await get_tree().process_frame
	_update_layout()
	if not resized.is_connected(_on_control_resized):
		resized.connect(_on_control_resized)
	if _should_auto_resume():
		print("[StartMenu] Auto-resuming interrupted game session...")
		_auto_resume_game()
		return
	_animate_menu_entrance()
	_animate_social_buttons()
	if start_button:
		start_button.grab_focus()
	var audio := _get_audio_manager()
	if audio and not audio.is_music_playing():
		audio.play_music("background_music", true)
	_connect_button_sounds()
func _setup_social_buttons():
	var social_layer = MarginContainer.new()
	social_layer.name = "SocialLayer"
	social_layer.layout_mode = 1 
	social_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	social_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(social_layer)
	var main_vbox = VBoxContainer.new()
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.alignment = BoxContainer.ALIGNMENT_END
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	social_layer.add_child(main_vbox)
	var bottom_row = HBoxContainer.new()
	bottom_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(bottom_row)
	var social_margin = MarginContainer.new()
	social_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	social_margin.size_flags_vertical = Control.SIZE_SHRINK_END 
	social_margin.add_theme_constant_override("margin_left", 30)
	social_margin.add_theme_constant_override("margin_bottom", 30)
	bottom_row.add_child(social_margin)
	var social_buttons_box = HBoxContainer.new()
	social_buttons_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	social_buttons_box.add_theme_constant_override("separation", 12)
	social_buttons_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	social_margin.add_child(social_buttons_box)
	youtube_button = TextureButton.new()
	youtube_button.name = "YouTubeButton"
	youtube_button.texture_normal = ICON_YOUTUBE
	youtube_button.ignore_texture_size = true
	youtube_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	youtube_button.custom_minimum_size = Vector2(48, 48)
	youtube_button.size = Vector2(48, 48)
	social_buttons_box.add_child(youtube_button)
	youtube_button.pressed.connect(_on_youtube_button_pressed)
	_add_hover_scale(youtube_button)
	github_button = TextureButton.new()
	github_button.name = "GitHubButton"
	github_button.texture_normal = ICON_GITHUB
	github_button.ignore_texture_size = true
	github_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	github_button.custom_minimum_size = Vector2(48, 48)
	github_button.size = Vector2(48, 48)
	social_buttons_box.add_child(github_button)
	github_button.pressed.connect(_on_github_button_pressed)
	_add_hover_scale(github_button)
	var spacer = Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(spacer)
	var version_margin = MarginContainer.new()
	version_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	version_margin.size_flags_vertical = Control.SIZE_SHRINK_END 
	version_margin.add_theme_constant_override("margin_right", 24)
	version_margin.add_theme_constant_override("margin_bottom", 24)
	bottom_row.add_child(version_margin)
	version_label = Label.new()
	var version_format: String = _tr("UI_VERSION")
	if version_format.find("%s") >= 0:
		version_label.text = version_format % GAME_VERSION
	else:
		version_label.text = "Version " + GAME_VERSION
	version_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	version_margin.add_child(version_label)
func _load_texture_safe(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var tex = load(path)
		if tex is Texture2D:
			return tex
	var file_path = path
	if path.begins_with("res://"):
		file_path = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(file_path):
		file_path = path.replace("res://", "")
	if FileAccess.file_exists(file_path):
		var image = Image.load_from_file(file_path)
		if image:
			return ImageTexture.create_from_image(image)
	print("[StartMenu] ERROR: Failed to load texture: ", path)
	return null
func _add_hover_scale(btn: TextureButton):
	btn.pivot_offset = btn.size / 2
	btn.mouse_entered.connect(func():
		var t = create_tween()
		t.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1)
		_on_button_hover()
	)
	btn.mouse_exited.connect(func():
		var t = create_tween()
		t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	)
func _animate_menu_entrance():
	panel.modulate.a = 0.0
	UIStyleManager.fade_in(panel, 0.5)
	for i in range(all_buttons.size()):
		var button = all_buttons[i]
		if button:
			button.modulate.a = 0.0
			await get_tree().create_timer(0.05).timeout
			UIStyleManager.fade_in(button, 0.3)
			button.pivot_offset = button.size / 2
			button.scale = Vector2(0.9, 0.9)
			var scale_tween = button.create_tween()
			scale_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			scale_tween.tween_property(button, "scale", Vector2.ONE, 0.4)
	await get_tree().create_timer(0.8).timeout
	if start_button and start_button.is_inside_tree():
		UIStyleManager.pulse_effect(start_button, 1.08, 1.5)
func _animate_social_buttons():
	if youtube_button:
		youtube_button.modulate.a = 0.0
		UIStyleManager.fade_in(youtube_button, 0.5)
	if github_button:
		github_button.modulate.a = 0.0
		UIStyleManager.fade_in(github_button, 0.5)
	if version_label:
		version_label.modulate.a = 0.0
		UIStyleManager.fade_in(version_label, 0.5)
func update_ui_text():
	start_button.text = _tr("MENU_NEW_GAME")
	continue_button.text = _tr("MENU_CONTINUE")
	save_load_button.text = _tr("MENU_SAVE_LOAD")
	journal_button.text = _tr("MENU_JOURNAL")
	achievements_button.text = _tr("MENU_ACHIEVEMENTS")
	intro_button.text = _tr("MENU_HOW_TO_PLAY")
	terms_button.text = _tr("MENU_TERMS")
	settings_button.text = _tr("MENU_SETTINGS")
	quit_button.text = _tr("MENU_QUIT")
	_refresh_continue_state()
	if logo_texture:
		logo_texture.visible = true
func _apply_styles():
	if background_overlay:
		background_overlay.visible = true
		background_overlay.color = Color(0.03, 0.05, 0.1, 0.30)
		background_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = panel.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		style.bg_color = Color(0.05, 0.08, 0.15, 0.40) 
		style.border_width_left = 0
		style.border_width_top = 0
		style.border_width_right = 0
		style.border_width_bottom = 0
		style.corner_radius_top_left = 24
		style.corner_radius_top_right = 24
		style.corner_radius_bottom_right = 24
		style.corner_radius_bottom_left = 24
		style.shadow_size = 20
		style.shadow_color = Color(0, 0, 0, 0.5)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if logo_texture:
		logo_texture.modulate = Color(1, 1, 1, 0.95)
	if scroll_container:
		scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_apply_button_styles()
func _apply_button_styles():
	if start_button:
		UIStyleManager.apply_button_style(start_button, "accent", "large")
		UIStyleManager.add_hover_scale_effect(start_button, 1.08)
		UIStyleManager.add_press_feedback(start_button)
	for button in [continue_button, save_load_button, journal_button, achievements_button, settings_button, quit_button]:
		if button:
			UIStyleManager.apply_button_style(button, "primary", "large")
			UIStyleManager.add_hover_scale_effect(button, 1.05)
			UIStyleManager.add_press_feedback(button)
	if intro_button:
		UIStyleManager.apply_button_style(intro_button, "accent", "medium")
		UIStyleManager.add_hover_scale_effect(intro_button, 1.06)
		UIStyleManager.add_press_feedback(intro_button)
	for button in [creative_statement_button, terms_button]:
		if button:
			UIStyleManager.apply_button_style(button, "primary", "small")
			UIStyleManager.add_hover_scale_effect(button, 1.04)
			UIStyleManager.add_press_feedback(button)
	for button in all_buttons:
		if button:
			button.focus_mode = Control.FOCUS_ALL
			button.mouse_filter = Control.MOUSE_FILTER_PASS
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
func _set_creative_statement_text():
	if not creative_statement_button:
		return
	creative_statement_button.text = _tr("MENU_CREATIVE_STATEMENT")
func _refresh_continue_state():
	if not continue_button:
		return
	var has_save := false
	var latest_info: Dictionary = { }
	var state := _get_game_state()
	if state and state.has_method("get_latest_save_info"):
		var latest_variant: Variant = state.get_latest_save_info()
		if latest_variant is Dictionary:
			latest_info = latest_variant
			has_save = latest_info.get("exists", false)
	continue_button.disabled = not has_save
	continue_button.focus_mode = Control.FOCUS_ALL if has_save else Control.FOCUS_NONE
	if continue_info_label:
		continue_info_label.visible = true
		if has_save:
			continue_info_label.modulate = Color(1.0, 1.0, 1.0, 0.9)
			continue_info_label.text = _format_continue_info(latest_info)
		else:
			continue_info_label.modulate = Color(1.0, 1.0, 1.0, 0.6)
			continue_info_label.text = _tr("MENU_NO_SAVE_DATA")
func _format_continue_info(info: Dictionary) -> String:
	var reality := int(info.get("reality_score", 0))
	var missions := int(info.get("missions_completed", 0))
	var timestamp_text := _format_save_timestamp(int(info.get("timestamp", 0)))
	var source_text := _get_save_source_label(info)
	return _tr("MENU_LAST_SAVE_FMT") % [reality, missions, source_text, timestamp_text]
func _get_save_source_label(info: Dictionary) -> String:
	var is_autosave: bool = bool(info.get("is_autosave", false))
	if is_autosave:
		return _tr("MENU_AUTOSAVE")
	var slot := int(info.get("save_slot", 0))
	if slot <= 0:
		return _tr("MENU_MANUAL_SAVE")
	return _tr("MENU_SLOT_FMT") % slot
func _format_save_timestamp(timestamp: int) -> String:
	if timestamp <= 0:
		return _tr("MENU_UNKNOWN_TIME")
	var dt := Time.get_datetime_dict_from_unix_time(timestamp)
	if not (dt is Dictionary):
		return _tr("MENU_UNKNOWN_TIME")
	var year := int(dt.get("year", 0))
	var month := int(dt.get("month", 0))
	var day := int(dt.get("day", 0))
	var hour := int(dt.get("hour", 0))
	var minute := int(dt.get("minute", 0))
	return _tr("MENU_TIMESTAMP_FMT") % [year, month, day, hour, minute]
func _update_layout():
	var vp_size = get_viewport_rect().size
	size = vp_size
	menu_container.size = vp_size
	var panel_width = clamp(vp_size.x * 0.50, 600.0, 900.0)
	var panel_height = clamp(vp_size.y * 0.80, 580.0, 850.0) 
	panel.custom_minimum_size = Vector2(panel_width, panel_height)
	panel.size = panel.custom_minimum_size
	var social_layer = get_node_or_null("SocialLayer")
	if social_layer:
		social_layer.size = vp_size
	var button_width = clamp((panel_width - 80.0) / 2.0, 240.0, 320.0)
	var button_height = clamp(vp_size.y * 0.065, 50.0, 65.0)
	for button in all_buttons:
		if not button:
			continue
		if button == terms_button or button == creative_statement_button:
			var footer_width = clamp((panel_width - 60.0) / 2.0, 220.0, 280.0)
			button.custom_minimum_size = Vector2(footer_width, 32.0)
		else:
			button.custom_minimum_size = Vector2(button_width, button_height)
	if continue_info_label:
		continue_info_label.custom_minimum_size = Vector2(panel_width - 80.0, 24.0)
	if spacer:
		spacer.custom_minimum_size.y = clamp(vp_size.y * 0.02, 10.0, 20.0)
	var separation = int(clamp(vp_size.y * 0.015, 10.0, 16.0))
	content_container.add_theme_constant_override("separation", separation)
func _on_control_resized():
	_update_layout()
func _connect_button_sounds():
	for button in all_buttons:
		if button and not button.mouse_entered.is_connected(_on_button_hover):
			button.mouse_entered.connect(_on_button_hover)
func _on_button_hover():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("menu_click", 0.5)
func _on_start_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("happy_click")
	if not _can_start_game_with_current_ai_settings():
		return
	var state := _get_game_state()
	if state:
		state.new_game()
	get_tree().change_scene_to_file("res://1.Codebase/src/scenes/ui/story_scene_enhanced.tscn")
func _on_continue_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("menu_click")
	if not _can_start_game_with_current_ai_settings():
		return
	var state := _get_game_state()
	if state and state.load_game():
		get_tree().change_scene_to_file("res://1.Codebase/src/scenes/ui/story_scene_enhanced.tscn")
	else:
		_report_warning("Failed to load game for continue")

func _can_start_game_with_current_ai_settings() -> bool:
	if not ServiceLocator:
		return true
	var ai_manager = ServiceLocator.get_ai_manager()
	if not is_instance_valid(ai_manager):
		return true
	if ai_manager.has_method("load_ai_settings"):
		ai_manager.load_ai_settings()
	var provider := int(ai_manager.current_provider)
	if provider != AIConfigManager.AIProvider.GEMINI:
		return true
	var key := String(ai_manager.gemini_api_key).strip_edges()
	if not key.is_empty():
		return true
	var message := _GEMINI_KEY_MISSING_MESSAGE
	if _is_web_runtime():
		message += " (Note: GitHub Secrets are not readable by the browser at runtime. Keys must be embedded at build-time or entered by the player.)"
	_show_error_notification(message)
	return false

func _is_web_runtime() -> bool:
	var normalized_name := OS.get_name().to_lower()
	if normalized_name == "html5":
		return true
	for feature in ["web", "html5", "emscripten", "javascript"]:
		if OS.has_feature(feature):
			return true
	return false
func _on_save_load_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("menu_click")
	var save_menu_scene: PackedScene = load("res://1.Codebase/src/scenes/ui/save_load_menu.tscn") as PackedScene
	if save_menu_scene:
		var save_menu_instance: Node = save_menu_scene.instantiate()
		var save_menu_control: Control = save_menu_instance as Control
		if save_menu_control:
			add_child(save_menu_control)
func _on_achievements_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("menu_click")
	var achievement_scene: PackedScene = load("res://1.Codebase/src/scenes/ui/achievement_viewer.tscn") as PackedScene
	if achievement_scene:
		var achievement_instance: Node = achievement_scene.instantiate()
		var achievement_control: Control = achievement_instance as Control
		if achievement_control:
			add_child(achievement_control)
			print("[StartMenu] Achievement viewer opened successfully")
		else:
			print("[StartMenu] ERROR: Failed to cast achievement instance to Control")
			_show_error_notification("Failed to open achievements viewer")
	else:
		print("[StartMenu] ERROR: Failed to load achievement_viewer.tscn")
		_show_error_notification("Achievements viewer not available")
func _on_journal_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("menu_click")
	var journal_scene: PackedScene = load("res://1.Codebase/src/scenes/ui/journal_system.tscn") as PackedScene
	if journal_scene:
		var journal_instance: Node = journal_scene.instantiate()
		var journal_control: Control = journal_instance as Control
		if journal_control:
			add_child(journal_control)
			print("[StartMenu] Journal opened successfully")
		else:
			print("[StartMenu] ERROR: Failed to cast journal instance to Control")
			_show_error_notification("Failed to open journal")
	else:
		print("[StartMenu] ERROR: Failed to load journal_system.tscn")
		_show_error_notification("Journal not available")
func _on_settings_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("menu_click")
	get_tree().change_scene_to_file("res://1.Codebase/src/scenes/ui/settings_menu.tscn")
func _on_quit_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("angry_click")
		await get_tree().create_timer(0.3).timeout
	get_tree().quit()
func _on_intro_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("menu_click")
	var intro_scene: PackedScene = load("res://1.Codebase/src/scenes/ui/intro_page.tscn") as PackedScene
	if intro_scene:
		var intro_instance: Node = intro_scene.instantiate()
		var intro_control: Control = intro_instance as Control
		if intro_control:
			add_child(intro_control)
func _on_creative_statement_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("menu_click")
	var statement_scene: PackedScene = load("res://1.Codebase/src/scenes/ui/creative_statement.tscn") as PackedScene
	if statement_scene:
		var statement_instance: Node = statement_scene.instantiate()
		var statement_control: Control = statement_instance as Control
		if statement_control:
			add_child(statement_control)
func _on_terms_button_pressed():
	var audio := _get_audio_manager()
	if audio:
		audio.play_sfx("menu_click")
	var terms_scene: PackedScene = load("res://1.Codebase/src/scenes/ui/terms_page.tscn") as PackedScene
	if terms_scene:
		var terms_instance: Node = terms_scene.instantiate()
		var terms_control: Control = terms_instance as Control
		if terms_control:
			add_child(terms_control)
func _on_youtube_button_pressed():
	OS.shell_open(YOUTUBE_URL)
func _on_github_button_pressed():
	OS.shell_open(GITHUB_URL)
func _show_error_notification(message: String) -> void:
	print("[StartMenu] Showing error notification: ", message)
	var error_label := Label.new()
	error_label.text = message
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	error_label.add_theme_font_size_override("font_size", 18)
	error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	error_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	error_label.offset_top = -100
	error_label.offset_bottom = -50
	add_child(error_label)
	var tween := create_tween()
	tween.tween_property(error_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.5)
	tween.tween_property(error_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(error_label.queue_free)
func _should_auto_resume() -> bool:
	var state := _get_game_state()
	if not state:
		return false
	var autosave_path = "user://autosave.save"
	if not FileAccess.file_exists(autosave_path):
		return false
	var file = FileAccess.open(autosave_path, FileAccess.READ)
	if not file:
		return false
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()
	if parse_result != OK:
		return false
	var save_data = json.get_data()
	if not save_data is Dictionary:
		return false
	var was_session_active = save_data.get("is_session_active", false)
	return was_session_active
func _auto_resume_game() -> void:
	var state := _get_game_state()
	if not state:
		_report_warning("GameState not available for auto-resume")
		return
	var success = state.load_game()
	if success:
		print("[StartMenu] Game state loaded successfully, transitioning to story scene...")
		get_tree().change_scene_to_file("res://1.Codebase/src/scenes/ui/story_scene_enhanced.tscn")
	else:
		_report_warning("Failed to load autosave for auto-resume")
		_animate_menu_entrance()
func _refresh_services() -> void:
	if not ServiceLocator:
		return
	audio_manager = ServiceLocator.get_audio_manager()
	game_state = ServiceLocator.get_game_state()
	error_reporter = ServiceLocator.get_error_reporter()
	font_manager = ServiceLocator.get_font_manager()
func _get_audio_manager() -> Node:
	if is_instance_valid(audio_manager):
		return audio_manager
	if ServiceLocator:
		audio_manager = ServiceLocator.get_audio_manager()
	return audio_manager
func _get_game_state() -> Node:
	if is_instance_valid(game_state):
		return game_state
	if ServiceLocator:
		game_state = ServiceLocator.get_game_state()
	return game_state
func _report_warning(message: String, details: Dictionary = { }) -> void:
	if not is_instance_valid(error_reporter) and ServiceLocator:
		error_reporter = ServiceLocator.get_error_reporter()
	if error_reporter and error_reporter.has_method("report_warning"):
		error_reporter.report_warning(ERROR_CONTEXT, message, details)
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key, current_language)
	return key
func _load_language_from_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		var saved_language: String = config.get_value("game", "language", "en")
		if game_state:
			game_state.current_language = saved_language
			current_language = saved_language
		if LocalizationManager:
			LocalizationManager.set_language(saved_language)
func _assign_icons() -> void:
	if journal_button:
		journal_button.icon = ICON_JOURNAL
		journal_button.expand_icon = true
	if achievements_button:
		achievements_button.icon = ICON_ACHIEVEMENTS
		achievements_button.expand_icon = true
	if settings_button:
		settings_button.icon = ICON_SETTINGS
		settings_button.expand_icon = true
	if start_button:
		start_button.icon = ICON_PLAY
		start_button.expand_icon = true
	if continue_button:
		continue_button.icon = ICON_PLAY
		continue_button.expand_icon = true
	if save_load_button:
		save_load_button.icon = ICON_SAVE
		save_load_button.expand_icon = true
	if intro_button:
		intro_button.icon = ICON_INFO
		intro_button.expand_icon = true
	if quit_button:
		quit_button.icon = ICON_QUIT
		quit_button.expand_icon = true
	if creative_statement_button:
		creative_statement_button.icon = ICON_CREATIVE
		creative_statement_button.expand_icon = true
	if terms_button:
		terms_button.icon = ICON_TERMS
		terms_button.expand_icon = true
