extends Control
@onready var all_assets_grid = $MarginContainer/VBoxContainer/TabContainer/AllAssets/GridContainer
@onready var icons_grid = $MarginContainer/VBoxContainer/TabContainer/Icons/GridContainer
@onready var characters_container = $MarginContainer/VBoxContainer/TabContainer/Characters/HBoxContainer
@onready var backgrounds_container = $MarginContainer/VBoxContainer/TabContainer/Backgrounds/VBoxContainer
@onready var ui_icons_grid = $"MarginContainer/VBoxContainer/TabContainer/UI Icons/GridContainer"
@onready var back_button = $MarginContainer/VBoxContainer/BottomPanel/BackButton
@onready var refresh_button = $MarginContainer/VBoxContainer/BottomPanel/RefreshButton
const AssetCardScene = preload("res://1.Codebase/src/scenes/ui/asset_card.tscn")
const ERROR_CONTEXT := "AssetViewer"
var current_language: String = "en"
func _ready():
	current_language = GameState.current_language if GameState else "en"
	back_button.pressed.connect(_on_back_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	back_button.text = _tr("ASSET_BACK")
	refresh_button.text = _tr("ASSET_REFRESH")
	var tab_container = $MarginContainer/VBoxContainer/TabContainer
	if tab_container:
		set_tab_title_by_name(tab_container, "AllAssets", _tr("ASSET_GALLERY") + " (All)") 
		set_tab_title_by_name(tab_container, "Characters", _tr("INTRO_BUTTON_CHARACTERS")) 
		set_tab_title_by_name(tab_container, "Backgrounds", "Backgrounds") 
	load_all_assets()
func set_tab_title_by_name(tabs: TabContainer, child_name: String, title: String):
	var child = tabs.get_node_or_null(child_name)
	if child:
		tabs.set_tab_title(child.get_index(), title)
func load_all_assets():
	clear_all_containers()
	load_game_icons()
	load_character_portraits()
	load_backgrounds()
	load_ui_icons()
func clear_all_containers():
	for child in all_assets_grid.get_children():
		child.queue_free()
	for child in icons_grid.get_children():
		child.queue_free()
	for child in characters_container.get_children():
		child.queue_free()
	for child in backgrounds_container.get_children():
		child.queue_free()
	for child in ui_icons_grid.get_children():
		child.queue_free()
func load_game_icons():
	if not AssetRegistry:
		ErrorReporterBridge.report_error(ERROR_CONTEXT, "AssetRegistry not found! Make sure it's in autoload")
		return
	var asset_ids = AssetRegistry.get_asset_ids()
	for asset_id in asset_ids:
		var asset_data = AssetRegistry.get_asset(asset_id)
		var card_all = create_asset_card(asset_data)
		if card_all:
			all_assets_grid.add_child(card_all)
		var card_icons = create_asset_card(asset_data)
		if card_icons:
			icons_grid.add_child(card_icons)
func load_character_portraits():
	var character_files = [
		{
			"name_key": "ASSET_CHAR_PROTAGONIST",
			"path": "res://1.Codebase/src/assets/characters/portrait_protagonist.png",
		},
		{
			"name_key": "ASSET_CHAR_GLORIA",
			"path": "res://1.Codebase/src/assets/characters/portrait_gloria.png",
		},
		{
			"name_key": "ASSET_CHAR_DONKEY",
			"path": "res://1.Codebase/src/assets/characters/portrait_donkey.png",
		},
		{
			"name_key": "ASSET_CHAR_ARK",
			"path": "res://1.Codebase/src/assets/characters/portrait_ark.png",
		},
		{
			"name_key": "ASSET_CHAR_ONE",
			"path": "res://1.Codebase/src/assets/characters/portrait_one.png",
		},
		{
			"name_key": "ASSET_CHAR_TEACHER",
			"path": "res://1.Codebase/src/assets/characters/portrait_teacher_chan.png",
		},
	]
	for character in character_files:
		var portrait_panel = create_portrait_display(_tr(character.name_key), character.path)
		if portrait_panel:
			characters_container.add_child(portrait_panel)
func load_backgrounds():
	var background_files = [
		{
			"name_key": "ASSET_BG_MENU",
			"path": "res://1.Codebase/src/assets/backgrounds/menu_background_dark.png",
		},
		{
			"name_key": "ASSET_BG_STORY",
			"path": "res://1.Codebase/src/assets/backgrounds/story_scene_background.png",
		},
		{
			"name_key": "ASSET_BG_JOURNAL",
			"path": "res://1.Codebase/src/assets/backgrounds/journal_background.png",
		},
	]
	for bg in background_files:
		var bg_panel = create_background_display(_tr(bg.name_key), bg.path)
		if bg_panel:
			backgrounds_container.add_child(bg_panel)
func load_ui_icons():
	var ui_icon_files = [
		{
			"name_key": "ASSET_UI_HOME",
			"path": "res://1.Codebase/src/assets/ui/icon_home.png",
		},
		{
			"name_key": "ASSET_UI_JOURNAL",
			"path": "res://1.Codebase/src/assets/ui/icon_journal.png",
		},
		{
			"name_key": "ASSET_UI_PAUSE",
			"path": "res://1.Codebase/src/assets/ui/icon_pause.png",
		},
		{
			"name_key": "ASSET_UI_SETTINGS",
			"path": "res://1.Codebase/src/assets/ui/icon_settings.png",
		},
		{
			"name_key": "ASSET_UI_SOUND_ON",
			"path": "res://1.Codebase/src/assets/ui/icon_sound_on.png",
		},
		{
			"name_key": "ASSET_UI_SOUND_OFF",
			"path": "res://1.Codebase/src/assets/ui/icon_sound_off.png",
		},
	]
	for icon in ui_icon_files:
		var icon_card = create_simple_icon_card(_tr(icon.name_key), icon.path)
		if icon_card:
			ui_icons_grid.add_child(icon_card)
func create_asset_card(asset_data: Dictionary) -> Control:
	var card = AssetCardScene.instantiate()
	var icon_path = asset_data.get("icon", "")
	var texture = load_texture_safe(icon_path)
	card.set_asset(asset_data, texture)
	return card
func create_portrait_display(character_name: String, portrait_path: String) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(200, 300)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.2, 0.3, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.6, 0.8, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", style)
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(180, 240)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture = load_texture_safe(portrait_path)
	vbox.add_child(texture_rect)
	var label = Label.new()
	label.text = character_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(label)
	return panel
func create_background_display(bg_name: String, bg_path: String) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(600, 200)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.2, 0.3, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.6, 0.8, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", style)
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	var label = Label.new()
	label.text = bg_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(label)
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(580, 160)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture = load_texture_safe(bg_path)
	vbox.add_child(texture_rect)
	return panel
func create_simple_icon_card(icon_name: String, icon_path: String) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(120, 140)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.2, 0.3, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.6, 0.8, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", style)
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(100, 100)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture = load_texture_safe(icon_path)
	vbox.add_child(texture_rect)
	var label = Label.new()
	label.text = icon_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(label)
	return panel
func load_texture_safe(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var texture = load(path)
		if texture is Texture2D:
			return texture
		else:
			ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Resource at %s is not a Texture2D" % path, {"path": path})
	else:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Texture not found at path: %s" % path, {"path": path})
	return null
func _on_back_pressed():
	queue_free()
func _on_refresh_pressed():
	load_all_assets()
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key, current_language)
	return key
