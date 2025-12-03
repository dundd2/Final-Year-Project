extends Control
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const TeammateSystem = preload("res://1.Codebase/src/scripts/core/teammate_system.gd")
const ICON_QUIT = preload("res://1.Codebase/src/assets/ui/icon_quit.svg")
var current_language: String = "en"
var selected_character_id: String = ""
var character_data: Dictionary = {}
var _content_title: Label
var _content_scroll: ScrollContainer
var _content_text: RichTextLabel
var _character_list: VBoxContainer
var _character_portrait: TextureRect 
var _graph_view_btn: Button
var _details_container: VBoxContainer
var _graph_container: Control
var _is_graph_mode: bool = false
var _graph_nodes: Dictionary = {}
func _ready():
	var game_state = ServiceLocator.get_game_state() if ServiceLocator else null
	current_language = game_state.current_language if game_state else "en"
	_init_character_data()
	var panel = $MenuContainer/Panel
	if panel:
		UIStyleManager.apply_panel_style(panel, 0.95, UIStyleManager.CORNER_RADIUS_LARGE)
		_rebuild_ui_layout(panel)
		UIStyleManager.fade_in(panel, 0.4)
		UIStyleManager.slide_in_from_bottom(panel, 0.5, 30.0)
	_select_character("protagonist")
func _init_character_data():
	character_data = {
		"protagonist": {
			"name_key": "CHAR_PROTAGONIST_NAME",
			"title_key": "CHAR_PROTAGONIST_TITLE",
			"icon_path": "res://1.Codebase/src/assets/characters/portrait_protagonist.png",
			"desc_key": "CHAR_PROTAGONIST_DESC"
		},
		"gloria": {
			"name_key": "CHAR_GLORIA_NAME",
			"title_key": "CHAR_GLORIA_TITLE",
			"icon_path": "res://1.Codebase/src/assets/characters/portrait_gloria.png",
			"desc_key": "CHAR_GLORIA_DESC"
		},
		"donkey": {
			"name_key": "CHAR_DONKEY_NAME",
			"title_key": "CHAR_DONKEY_TITLE",
			"icon_path": "res://1.Codebase/src/assets/characters/portrait_donkey.png",
			"desc_key": "CHAR_DONKEY_DESC"
		},
		"ark": {
			"name_key": "CHAR_ARK_NAME",
			"title_key": "CHAR_ARK_TITLE",
			"icon_path": "res://1.Codebase/src/assets/characters/portrait_ark.png",
			"desc_key": "CHAR_ARK_DESC"
		},
		"one": {
			"name_key": "CHAR_ONE_NAME",
			"title_key": "CHAR_ONE_TITLE",
			"icon_path": "res://1.Codebase/src/assets/characters/portrait_one.png",
			"desc_key": "CHAR_ONE_DESC"
		},
		"teacher_chan": {
			"name_key": "CHAR_TEACHER_NAME",
			"title_key": "CHAR_TEACHER_TITLE",
			"icon_path": "res://1.Codebase/src/assets/characters/portrait_teacher_chan.png",
			"desc_key": "CHAR_TEACHER_DESC"
		},
		"fsm": { 
			"name_key": "CHAR_FSM_NAME",
			"title_key": "CHAR_FSM_TITLE",
			"icon_path": "", 
			"desc_key": "CHAR_FSM_DESC"
		}
	}
func _rebuild_ui_layout(panel: Control):
	var children = panel.get_children()
	for child in children:
		if child.get_parent() == panel:
			panel.remove_child(child)
			child.queue_free()
	var main_hbox = HBoxContainer.new()
	main_hbox.name = "MainLayout"
	main_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin_container = MarginContainer.new()
	margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_container.add_theme_constant_override("margin_left", 30)
	margin_container.add_theme_constant_override("margin_right", 30)
	margin_container.add_theme_constant_override("margin_top", 30)
	margin_container.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin_container)
	margin_container.add_child(main_hbox)
	var sidebar = VBoxContainer.new()
	sidebar.name = "Sidebar"
	sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sidebar.size_flags_stretch_ratio = 0.3 
	sidebar.add_theme_constant_override("separation", 15)
	main_hbox.add_child(sidebar)
	var sidebar_title = Label.new()
	sidebar_title.text = _tr("CHARACTERS_TITLE")
	sidebar_title.add_theme_font_size_override("font_size", 24)
	sidebar_title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	sidebar.add_child(sidebar_title)
	_graph_view_btn = Button.new()
	_graph_view_btn.text = "🕸 " + _tr("GRAPH_VIEW_TITLE")
	_graph_view_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_graph_view_btn.connect("pressed", Callable(self, "_toggle_graph_view"))
	UIStyleManager.apply_button_style(_graph_view_btn, "secondary", "medium")
	sidebar.add_child(_graph_view_btn)
	var sep = HSeparator.new()
	sidebar.add_child(sep)
	var scroll_sidebar = ScrollContainer.new()
	scroll_sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(scroll_sidebar)
	_character_list = VBoxContainer.new()
	_character_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_character_list.add_theme_constant_override("separation", 10)
	scroll_sidebar.add_child(_character_list)
	for key in ["protagonist", "gloria", "donkey", "ark", "one", "teacher_chan", "fsm"]:
		if not character_data.has(key): continue
		var btn = Button.new()
		var char_name = _tr(character_data[key]["name_key"])
		btn.text = char_name
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.connect("pressed", Callable(self, "_select_character").bind(key))
		UIStyleManager.apply_button_style(btn, "secondary", "medium")
		_character_list.add_child(btn)
	var close_btn = Button.new()
	close_btn.text = _tr("CHAR_BUTTON_CLOSE")
	close_btn.icon = ICON_QUIT
	close_btn.expand_icon = true
	close_btn.connect("pressed", Callable(self, "_on_close_pressed"))
	UIStyleManager.apply_button_style(close_btn, "primary", "medium")
	sidebar.add_child(close_btn)
	var content_area = VBoxContainer.new()
	content_area.name = "ContentArea"
	content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_area.size_flags_stretch_ratio = 0.7 
	main_hbox.add_child(content_area)
	var spacer = VSeparator.new()
	spacer.add_theme_constant_override("separation", 40)
	main_hbox.add_child(spacer)
	main_hbox.move_child(spacer, 1) 
	_graph_container = Control.new()
	_graph_container.name = "GraphContainer"
	_graph_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph_container.visible = false
	content_area.add_child(_graph_container)
	_details_container = VBoxContainer.new()
	_details_container.name = "DetailsContainer"
	_details_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_area.add_child(_details_container)
	_character_portrait = TextureRect.new()
	_character_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_character_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_character_portrait.custom_minimum_size = Vector2(200, 200) 
	_details_container.add_child(_character_portrait)
	_content_title = Label.new()
	_content_title.text = ""
	_content_title.add_theme_font_size_override("font_size", 32)
	_content_title.add_theme_color_override("font_color", Color(1, 0.8, 0.2)) 
	_content_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details_container.add_child(_content_title)
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details_container.add_child(_content_scroll)
	_content_text = RichTextLabel.new()
	_content_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_text.fit_content = true
	_content_text.bbcode_enabled = true
	_content_text.add_theme_font_size_override("normal_font_size", 18)
	_content_text.add_theme_constant_override("line_separation", 6)
	_content_scroll.add_child(_content_text)
func _select_character(char_key: String):
	if char_key not in character_data:
		return
	_is_graph_mode = false
	if _graph_container: _graph_container.visible = false
	if _details_container: _details_container.visible = true
	if _graph_view_btn: UIStyleManager.apply_button_style(_graph_view_btn, "secondary", "medium")
	selected_character_id = char_key
	var data = character_data[char_key]
	var name_text = _tr(data["name_key"])
	var title_text = _tr(data["title_key"])
	var icon_path = data.get("icon_path", "")
	var portrait_tex = null
	if icon_path != "":
		portrait_tex = _load_texture_safe(icon_path)
	if portrait_tex:
		_character_portrait.texture = portrait_tex
		_character_portrait.visible = true
	else:
		_character_portrait.texture = null
		_character_portrait.visible = false
	_content_title.text = name_text + "\n" + title_text
	_content_title.add_theme_font_size_override("font_size", 32)
	var desc_text = _tr(data["desc_key"])
	_content_text.text = desc_text.replace("\\n", "\n")
	var child_idx = 0
	var keys = ["protagonist", "gloria", "donkey", "ark", "one", "teacher_chan", "fsm"]
	for btn in _character_list.get_children():
		if btn is Button:
			if child_idx < keys.size():
				if keys[child_idx] == char_key:
					UIStyleManager.apply_button_style(btn, "primary", "medium")
				else:
					UIStyleManager.apply_button_style(btn, "secondary", "medium")
			child_idx += 1
func _on_close_pressed():
	queue_free()
func _toggle_graph_view():
	_is_graph_mode = true
	if _details_container: _details_container.visible = false
	if _graph_container: _graph_container.visible = true
	if _graph_view_btn: UIStyleManager.apply_button_style(_graph_view_btn, "primary", "medium")
	for btn in _character_list.get_children():
		if btn is Button:
			UIStyleManager.apply_button_style(btn, "secondary", "medium")
	_render_graph()
func _render_graph():
	if not _graph_container: return
	for child in _graph_container.get_children():
		child.queue_free()
	_graph_nodes.clear()
	var center = _graph_container.size / 2
	if center == Vector2.ZERO: center = Vector2(400, 300) 
	_create_graph_node("protagonist", center)
	var teammates = ["gloria", "donkey", "ark", "one"]
	var radius = 200.0
	var angle_step = TAU / teammates.size()
	for i in range(teammates.size()):
		var angle = i * angle_step - PI/2 
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		_create_graph_node(teammates[i], pos)
	_draw_relationship_lines()
	for node in _graph_nodes.values():
		node.move_to_front()
func _create_graph_node(char_key: String, position: Vector2):
	if not character_data.has(char_key): return
	var data = character_data[char_key]
	var node = VBoxContainer.new()
	node.position = position - Vector2(50, 50) 
	node.custom_minimum_size = Vector2(100, 120)
	var tex_rect = TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(80, 80)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var icon_path = data.get("icon_path", "")
	if icon_path != "":
		tex_rect.texture = _load_texture_safe(icon_path)
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.corner_radius_top_left = 40
	style.corner_radius_top_right = 40
	style.corner_radius_bottom_right = 40
	style.corner_radius_bottom_left = 40
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.5, 0.5)
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(tex_rect)
	node.add_child(panel)
	var label = Label.new()
	label.text = _tr(data["name_key"]).split("・")[0] 
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.add_child(label)
	_graph_container.add_child(node)
	_graph_nodes[char_key] = node
	panel.gui_input.connect(func(event): 
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_character(char_key)
	)
func _draw_relationship_lines():
	var player_node = _graph_nodes.get("protagonist")
	if not player_node: return
	var player_center = player_node.position + Vector2(50, 50)
	for key in _graph_nodes:
		if key == "protagonist": continue
		var target_node = _graph_nodes[key]
		var target_center = target_node.position + Vector2(50, 50)
		var status = _get_relationship_status(key)
		var color = status.color
		var width = status.width
		var line = Line2D.new()
		line.add_point(player_center)
		line.add_point(target_center)
		line.width = width
		line.default_color = color
		line.antialiased = true
		_graph_container.add_child(line)
		var mid_point = (player_center + target_center) / 2
		var status_label = Label.new()
		status_label.text = status.text
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.add_theme_color_override("font_color", color)
		status_label.add_theme_font_size_override("font_size", 14)
		var bg = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.7)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_right = 4
		style.corner_radius_bottom_left = 4
		bg.add_theme_stylebox_override("panel", style)
		bg.position = mid_point - Vector2(30, 10) 
		bg.add_child(status_label)
		_graph_container.add_child(bg)
func _get_relationship_status(char_key: String) -> Dictionary:
	var game_state = ServiceLocator.get_game_state() if ServiceLocator else null
	if not game_state: return {"color": Color.GRAY, "width": 2, "text": "?"}
	var reality = game_state.reality_score
	var positive = game_state.positive_energy
	var result = {"color": Color.GRAY, "width": 2, "text": "RELATIONSHIP_NEUTRAL"}
	match char_key:
		"gloria":
			if positive > 60 and reality < 40:
				result = {"color": Color.GREEN, "width": 4, "text": "RELATIONSHIP_DEVOTED"}
			elif reality > 60:
				result = {"color": Color.RED, "width": 3, "text": "RELATIONSHIP_HOSTILE"}
			elif positive < 30:
				result = {"color": Color.ORANGE, "width": 2, "text": "RELATIONSHIP_SUSPICIOUS"}
		"donkey":
			if positive > 60:
				result = {"color": Color.GREEN, "width": 4, "text": "RELATIONSHIP_LOYAL"}
			elif positive < 40:
				result = {"color": Color.ORANGE, "width": 2, "text": "RELATIONSHIP_DISAPPOINTED"}
		"ark":
			if reality > 40:
				result = {"color": Color.CYAN, "width": 3, "text": "RELATIONSHIP_ALIGNED"}
			elif reality < 30:
				result = {"color": Color.RED, "width": 3, "text": "RELATIONSHIP_CRITICAL"}
		"one":
			if reality < 55 and positive < 45:
				result = {"color": Color.PURPLE, "width": 3, "text": "RELATIONSHIP_SYMPATHETIC"}
			elif positive > 70:
				result = {"color": Color.GRAY, "width": 1, "text": "RELATIONSHIP_DISTANT"}
	result.text = _tr(result.text)
	return result
func _tr(key: String) -> String:
	if LocalizationManager:
		return LocalizationManager.get_translation(key, current_language)
	return tr(key)
func _load_texture_safe(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
