extends Control
signal menu_closed()
@onready var menu_panel: Panel = $MenuPanel
@onready var buttons_container: VBoxContainer = $MenuPanel/MarginContainer/VBoxContainer/ButtonsContainer
var is_menu_open: bool = false
const ICON_SAVE = preload("res://1.Codebase/src/assets/ui/icon_save.svg")
const ICON_PLAY = preload("res://1.Codebase/src/assets/ui/icon_play.svg")
const ICON_ACHIEVEMENTS = preload("res://1.Codebase/src/assets/ui/icon_achievements.svg")
const ICON_JOURNAL = preload("res://1.Codebase/src/assets/ui/icon_journal.svg")
const ICON_SETTINGS = preload("res://1.Codebase/src/assets/ui/icon_settings.svg")
const ICON_CREATIVE = preload("res://1.Codebase/src/assets/ui/icon_creative.svg")
const ICON_HOME = preload("res://1.Codebase/src/assets/ui/icon_home.svg")
const ICON_QUIT = preload("res://1.Codebase/src/assets/ui/icon_quit.svg")
func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buttons()
func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			toggle_menu()
			get_viewport().set_input_as_handled()
func toggle_menu():
	is_menu_open = !is_menu_open
	visible = is_menu_open
	if is_menu_open:
		if not get_tree().paused:
			get_tree().paused = true
		if buttons_container.get_child_count() > 0:
			var first_button = buttons_container.get_child(0)
			if first_button is Button:
				first_button.grab_focus()
	else:
		get_tree().paused = false
		menu_closed.emit()
func _setup_buttons():
	var lang = GameState.current_language if GameState else "en"
	for child in buttons_container.get_children():
		child.queue_free()
	var save_btn = _create_button(
		"Quick Save" if lang == "en" else "快速存檔",
		_on_quick_save,
		ICON_SAVE
	)
	buttons_container.add_child(save_btn)
	var load_btn = _create_button(
		"Quick Load" if lang == "en" else "快速讀檔",
		_on_quick_load,
		ICON_PLAY
	)
	buttons_container.add_child(load_btn)
	var separator1 = HSeparator.new()
	buttons_container.add_child(separator1)
	var achievements_btn = _create_button(
		"Achievements" if lang == "en" else "成就",
		_on_achievements,
		ICON_ACHIEVEMENTS
	)
	buttons_container.add_child(achievements_btn)
	var journal_btn = _create_button(
		"Journal" if lang == "en" else "日記",
		_on_journal,
		ICON_JOURNAL
	)
	buttons_container.add_child(journal_btn)
	var separator2 = HSeparator.new()
	buttons_container.add_child(separator2)
	var settings_btn = _create_button(
		"Settings" if lang == "en" else "設定",
		_on_settings,
		ICON_SETTINGS
	)
	buttons_container.add_child(settings_btn)
	var ai_settings_btn = _create_button(
		"AI Settings" if lang == "en" else "AI 設定",
		_on_ai_settings,
		ICON_CREATIVE
	)
	buttons_container.add_child(ai_settings_btn)
	var separator3 = HSeparator.new()
	buttons_container.add_child(separator3)
	var menu_btn = _create_button(
		"Main Menu" if lang == "en" else "主選單",
		_on_main_menu,
		ICON_HOME
	)
	buttons_container.add_child(menu_btn)
	var close_btn = _create_button(
		"Close (Tab)" if lang == "en" else "關閉 (Tab)",
		_on_close,
		ICON_QUIT
	)
	close_btn.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	buttons_container.add_child(close_btn)
func _create_button(text: String, callback: Callable, icon: Texture2D = null) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(250, 40)
	button.pressed.connect(callback)
	if icon:
		button.icon = icon
		button.expand_icon = true
	if FontManager:
		FontManager.apply_to_button(button, 16)
	return button
func _on_quick_save():
	var lang = GameState.current_language if GameState else "en"
	if GameState.save_game_to_slot():
		_show_notification("✓ Saved!" if lang == "en" else "✓ 已存檔！")
		if AudioManager:
			AudioManager.play_sfx("happy_click")
	else:
		_show_notification("✗ Save Failed!" if lang == "en" else "✗ 存檔失敗！")
		if AudioManager:
			AudioManager.play_sfx("angry_click")
func _on_quick_load():
	var lang = GameState.current_language if GameState else "en"
	if GameState.load_game_from_slot():
		_show_notification("✓ Loaded!" if lang == "en" else "✓ 已讀檔！")
		if AudioManager:
			AudioManager.play_sfx("happy_click")
		toggle_menu()
		get_tree().reload_current_scene()
	else:
		_show_notification("✗ Load Failed!" if lang == "en" else "✗ 讀檔失敗！")
		if AudioManager:
			AudioManager.play_sfx("angry_click")
func _on_achievements():
	if AudioManager:
		AudioManager.play_sfx("menu_click")
	var achievement_viewer_script = load("res://1.Codebase/src/scripts/ui/achievement_viewer.gd")
	if achievement_viewer_script:
		var viewer = Control.new()
		viewer.set_script(achievement_viewer_script)
		viewer.process_mode = Node.PROCESS_MODE_ALWAYS
		get_parent().add_child(viewer)
		toggle_menu()
func _on_journal():
	if AudioManager:
		AudioManager.play_sfx("menu_click")
	var journal_scene = load("res://1.Codebase/src/scenes/ui/journal_system.tscn")
	if journal_scene:
		var journal = journal_scene.instantiate()
		journal.process_mode = Node.PROCESS_MODE_ALWAYS
		get_parent().add_child(journal)
		toggle_menu()
func _on_settings():
	if AudioManager:
		AudioManager.play_sfx("menu_click")
	var settings_scene = load("res://1.Codebase/src/scenes/ui/settings_menu.tscn")
	if settings_scene:
		var settings = settings_scene.instantiate()
		settings.process_mode = Node.PROCESS_MODE_ALWAYS
		get_parent().add_child(settings)
		toggle_menu()
func _on_ai_settings():
	if AudioManager:
		AudioManager.play_sfx("menu_click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://1.Codebase/src/scenes/ui/ai_settings_menu.tscn")
func _on_main_menu():
	if AudioManager:
		AudioManager.play_sfx("menu_click")
	var lang = GameState.current_language if GameState else "en"
	var confirm_text = "Return to main menu? Unsaved progress will be lost." if lang == "en" else "返回主選單？未存檔的進度將會遺失。"
	get_tree().paused = false
	get_tree().change_scene_to_file("res://1.Codebase/menu_main.tscn")
func _on_close():
	if AudioManager:
		AudioManager.play_sfx("menu_click")
	toggle_menu()
func _show_notification(message: String):
	var notification_system = ServiceLocator.get_notification_system() if ServiceLocator else null
	if notification_system:
		notification_system.show_info(message)
	else:
		var label = Label.new()
		label.text = message
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
		label.position = Vector2(get_viewport_rect().size.x / 2 - 100, 50)
		add_child(label)
		await get_tree().create_timer(2.0).timeout
		if is_instance_valid(label):
			label.queue_free()
