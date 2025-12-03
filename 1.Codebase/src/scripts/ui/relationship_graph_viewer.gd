extends Control
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var description_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/DescriptionLabel
@onready var graph_container: Control = $Panel/MarginContainer/VBoxContainer/ScrollContainer/GraphContainer
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/CloseButton
@onready var refresh_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/RefreshButton
@onready var scroll_container: ScrollContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer
var node_positions: Dictionary = { }
var node_size: Vector2 = Vector2(180, 80)
var node_spacing: Vector2 = Vector2(250, 150)
var connection_lines: Array[Dictionary] = []
var current_mode: String = "butterfly" 
var toggle_button: Button = null
signal close_requested
var choice_color := Color(0.4, 0.7, 1.0)
var consequence_color := Color(1.0, 0.5, 0.3)
var line_color := Color(0.6, 0.6, 0.8, 0.5)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_toggle_button()
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if refresh_button:
		refresh_button.pressed.connect(_on_refresh_pressed)
	_localize_ui()
	var teammate_system = ServiceLocator.get_teammate_system() if ServiceLocator else null
	if teammate_system and teammate_system.has_signal("relationship_updated"):
		if not teammate_system.relationship_updated.is_connected(_on_relationship_updated):
			teammate_system.relationship_updated.connect(_on_relationship_updated)
	_render_current_mode()
func _on_relationship_updated(_source_id: String, _target_id: String) -> void:
	if is_visible_in_tree() and current_mode == "team":
		_render_team_graph()
func _create_toggle_button() -> void:
	var button_container = $Panel/MarginContainer/VBoxContainer/ButtonContainer
	if not button_container: return
	toggle_button = Button.new()
	toggle_button.name = "ToggleButton"
	toggle_button.custom_minimum_size = Vector2(200, 40)
	button_container.add_child(toggle_button)
	button_container.move_child(toggle_button, 0) 
	toggle_button.pressed.connect(_on_toggle_mode_pressed)
func _localize_ui() -> void:
	var lang = GameState.current_language if GameState else "en"
	if lang == "zh":
		if title_label:
			title_label.text = "🌀 關係與社交圖譜" if current_mode == "team" else "🦋 蝴蝶效應追蹤"
		if description_label:
			description_label.text = "[center]小隊成員之間的動態關係[/center]" if current_mode == "team" else "[center]你的選擇如何影響世界的可視化呈現[/center]"
		if close_button:
			close_button.text = "關閉"
		if refresh_button:
			refresh_button.text = "刷新"
		if toggle_button:
			toggle_button.text = "查看蝴蝶效應" if current_mode == "team" else "查看小隊關係"
	else:
		if title_label:
			title_label.text = "🌀 Team Relationships" if current_mode == "team" else "🦋 Butterfly Effect"
		if description_label:
			description_label.text = "[center]Dynamic relationships between squad members[/center]" if current_mode == "team" else "[center]Visualizing how your choices affected the world[/center]"
		if close_button:
			close_button.text = "Close"
		if refresh_button:
			refresh_button.text = "Refresh"
		if toggle_button:
			toggle_button.text = "View Butterfly Effect" if current_mode == "team" else "View Team Relations"
func _on_toggle_mode_pressed() -> void:
	current_mode = "team" if current_mode == "butterfly" else "butterfly"
	_localize_ui()
	_render_current_mode()
func _render_current_mode() -> void:
	if not graph_container: return
	for child in graph_container.get_children():
		child.queue_free()
	connection_lines.clear()
	if current_mode == "team":
		_render_team_graph()
	else:
		_render_butterfly_graph()
func _render_team_graph() -> void:
	var teammate_system = ServiceLocator.get_teammate_system() if ServiceLocator else null
	if not teammate_system:
		_show_empty_state("Teammate system not found")
		return
	var relationships = teammate_system.get_all_relationships()
	if relationships.is_empty():
		_show_empty_state("No relationship data available")
		return
	var center = Vector2(400, 300)
	var radius = 220.0
	var members = ["player", "gloria", "donkey", "ark", "one", "teacher_chan"]
	var angle_step = TAU / members.size()
	node_positions.clear()
	for i in range(members.size()):
		var member_id = members[i]
		var angle = i * angle_step - PI/2 
		var pos = center + Vector2(cos(angle), sin(angle)) * radius - (node_size / 2)
		node_positions[member_id] = pos
		var name_text = member_id.capitalize()
		var color = Color(0.5, 0.5, 0.5)
		if member_id == "player":
			name_text = "YOU (Player)"
			color = Color(0.3, 0.8, 0.3)
		else:
			var info = teammate_system.get_teammate_info(member_id)
			if info:
				name_text = info.get("name", name_text)
				color = info.get("color", color)
				if name_text.contains("・"):
					name_text = name_text.split("・")[1]
		_create_node(pos, name_text, color, member_id, "teammate")
	for source_id in relationships:
		if not node_positions.has(source_id): continue
		var targets = relationships[source_id]
		for target_id in targets:
			if not node_positions.has(target_id): continue
			var rel_data = targets[target_id]
			var status = rel_data.get("status", "")
			var value = rel_data.get("value", 0)
			var start = node_positions[source_id]
			var end = node_positions[target_id]
			_create_connection_line(start, end, source_id, target_id, status)
	_draw_connections()
func _render_butterfly_graph() -> void:
	if not graph_container:
		return
	var choices = _get_butterfly_choices()
	var consequences = _get_butterfly_consequences()
	if choices.is_empty():
		_show_empty_state()
		return
	_calculate_layout(choices, consequences)
	_draw_graph(choices, consequences)
func _get_butterfly_choices() -> Array:
	if not GameState or not GameState.butterfly_tracker:
		return []
	var tracker = GameState.butterfly_tracker
	if tracker.has_method("get_all_choices"):
		return tracker.get_all_choices()
	elif tracker.has("recorded_choices"):
		return tracker.recorded_choices
	return []
func _get_butterfly_consequences() -> Array:
	if not GameState or not GameState.butterfly_tracker:
		return []
	var tracker = GameState.butterfly_tracker
	if tracker.has_method("get_all_consequences"):
		return tracker.get_all_consequences()
	elif tracker.has("consequences"):
		return tracker.consequences
	return []
func _calculate_layout(choices: Array, consequences: Array) -> void:
	node_positions.clear()
	for i in range(choices.size()):
		var choice_id = "choice_%d" % i
		var x = 50
		var y = 50 + i * node_spacing.y
		node_positions[choice_id] = Vector2(x, y)
	for i in range(consequences.size()):
		var consequence_id = "consequence_%d" % i
		var x = 350
		var y = 50 + i * node_spacing.y
		node_positions[consequence_id] = Vector2(x, y)
	var max_y = max(choices.size(), consequences.size()) * node_spacing.y + 100
	if graph_container:
		graph_container.custom_minimum_size = Vector2(700, max_y)
func _draw_graph(choices: Array, consequences: Array) -> void:
	if not graph_container:
		return
	connection_lines.clear()
	for i in range(choices.size()):
		var choice = choices[i]
		var choice_id = "choice_%d" % i
		var pos = node_positions.get(choice_id, Vector2.ZERO)
		_create_node(pos, choice.get("text", "Unknown"), choice_color, choice_id, "choice")
	for i in range(consequences.size()):
		var consequence = consequences[i]
		var consequence_id = "consequence_%d" % i
		var pos = node_positions.get(consequence_id, Vector2.ZERO)
		var consequence_text = consequence.get("description", "Unknown effect")
		_create_node(pos, consequence_text, consequence_color, consequence_id, "consequence")
		var source_choice_index = consequence.get("source_choice_index", -1)
		if source_choice_index >= 0 and source_choice_index < choices.size():
			var source_id = "choice_%d" % source_choice_index
			var source_pos = node_positions.get(source_id, Vector2.ZERO)
			_create_connection_line(source_pos, pos, source_id, consequence_id)
func _create_node(position: Vector2, text: String, color: Color, node_id: String, node_type: String) -> void:
	var node = Panel.new()
	node.position = position
	node.custom_minimum_size = node_size
	node.name = node_id
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = color
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color.WHITE
	node.add_theme_stylebox_override("panel", style_box)
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.text = "[center]%s[/center]" % text.substr(0, 60) 
	label.custom_minimum_size = Vector2(node_size.x - 20, node_size.y - 20)
	label.position = Vector2(10, 10)
	node.add_child(label)
	graph_container.add_child(node)
	node.mouse_entered.connect(func(): _on_node_hover(node_id, node_type))
	node.mouse_exited.connect(func(): _on_node_unhover(node_id, node_type))
func _create_connection_line(from_pos: Vector2, to_pos: Vector2, from_id: String, to_id: String, label: String = "") -> void:
	var start = from_pos + node_size / 2
	var end = to_pos + node_size / 2
	if current_mode == "butterfly":
		start = from_pos + Vector2(node_size.x, node_size.y / 2)
		end = to_pos + Vector2(0, node_size.y / 2)
	connection_lines.append(
		{
			"from": start,
			"to": end,
			"from_id": from_id,
			"to_id": to_id,
			"label": label
		},
	)
	if graph_container:
		graph_container.queue_redraw()
func _draw_connections() -> void:
	if not graph_container:
		return
	for connection in connection_lines:
		var from_pos = connection["from"]
		var to_pos = connection["to"]
		var label_text = connection.get("label", "")
		var line = Line2D.new()
		line.add_point(from_pos)
		line.add_point(to_pos)
		line.width = 2
		line.default_color = line_color
		if current_mode == "team":
			line.default_color = Color(1, 1, 1, 0.3)
			line.width = 1.5
		graph_container.add_child(line)
		if not label_text.is_empty() and current_mode == "team":
			var label = Label.new()
			label.text = label_text
			label.position = (from_pos + to_pos) / 2 - Vector2(20, 10)
			label.add_theme_font_size_override("font_size", 12)
			label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.8))
			var bg = Panel.new()
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0.6)
			style.corner_radius_top_left = 4
			style.corner_radius_top_right = 4
			style.corner_radius_bottom_right = 4
			style.corner_radius_bottom_left = 4
			bg.add_theme_stylebox_override("panel", style)
			bg.show_behind_parent = true
			bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.add_child(bg)
			bg.set_anchors_preset(Control.PRESET_FULL_RECT)
			graph_container.add_child(label)
func _show_empty_state(msg_override: String = "") -> void:
	var lang = GameState.current_language if GameState else "en"
	var text = ""
	if not msg_override.is_empty():
		text = msg_override
	elif lang == "zh":
		text = "还没有选择记录。\n开始游戏后，你的选择将显示在这里。"
	else:
		text = "No choices recorded yet.\nYour choices will appear here as you play."
	var empty_label = Label.new()
	empty_label.text = text
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.custom_minimum_size = Vector2(400, 200)
	if graph_container:
		graph_container.add_child(empty_label)
func _on_node_hover(node_id: String, node_type: String) -> void:
	pass
func _on_node_unhover(node_id: String, node_type: String) -> void:
	pass
func _on_close_pressed() -> void:
	emit_signal("close_requested")
	hide()
func _on_refresh_pressed() -> void:
	_render_current_mode()
func show_graph() -> void:
	show()
	_render_current_mode()
