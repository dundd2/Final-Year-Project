extends Control
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
var backdrop: ColorRect
var panel: Panel
var title_label: Label
var subtitle_label: Label
var timeline_container: VBoxContainer
var close_button: Button
var no_effects_label: Label
var _lang: String = "en"
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_lang = GameState.current_language if GameState else "en"
	_cache_nodes()
	_apply_styles()
	_connect_signals()
	_populate_timeline()
	if panel:
		UIStyleManager.fade_in(panel, 0.25)
	if close_button:
		close_button.grab_focus()
func _find_node(node_name: String) -> Node:
	return find_child(node_name, true, false)
func _cache_nodes():
	backdrop = get_node_or_null("Backdrop") as ColorRect
	panel = get_node_or_null("CenterContainer/Panel") as Panel
	title_label = _find_node("TitleLabel") as Label
	subtitle_label = _find_node("SubtitleLabel") as Label
	timeline_container = _find_node("TimelineContainer") as VBoxContainer
	close_button = _find_node("CloseButton") as Button
	no_effects_label = _find_node("NoEffectsLabel") as Label
func _apply_styles():
	if backdrop:
		backdrop.color = Color(0, 0, 0, 0.7)
		backdrop.mouse_filter = Control.MOUSE_FILTER_PASS
	if panel:
		UIStyleManager.apply_panel_style(panel, 0.95, UIStyleManager.CORNER_RADIUS_LARGE)
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if title_label:
		title_label.text = "Butterfly Effect Timeline" if _lang == "en" else "蝴蝶效應時間線"
		title_label.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	if subtitle_label:
		subtitle_label.text = "Your choices ripple through the story..." if _lang == "en" else "你的選擇在故事中迴盪..."
		subtitle_label.add_theme_color_override("font_color", Color(0.78, 0.83, 0.95))
	if close_button:
		UIStyleManager.apply_button_style(close_button, "accent", "medium")
		UIStyleManager.add_hover_scale_effect(close_button, 1.05)
		UIStyleManager.add_press_feedback(close_button)
		close_button.text = "Close" if _lang == "en" else "關閉"
		close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
func _connect_signals():
	if close_button and not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
func _populate_timeline():
	if not timeline_container:
		return
	for child in timeline_container.get_children():
		child.queue_free()
	if not GameState or not GameState.butterfly_tracker:
		_show_no_effects()
		return
	var summary = GameState.butterfly_tracker.get_butterfly_effect_summary(_lang)
	if summary.is_empty():
		_show_no_effects()
		return
	if no_effects_label:
		no_effects_label.visible = false
	for entry in summary:
		var timeline_entry = _create_timeline_entry(entry)
		timeline_container.add_child(timeline_entry)
func _show_no_effects():
	if no_effects_label:
		no_effects_label.visible = true
		no_effects_label.text = "No butterfly effects yet. Your major choices will echo through the story..." if _lang == "en" else "尚未有蝴蝶效應。你的重大選擇將在故事中產生迴響..."
func _create_timeline_entry(entry: Dictionary) -> Control:
	var container = PanelContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	var choice_type = entry.get("choice_type", "major")
	match choice_type:
		"milestone": 
			style.bg_color = Color(0.25, 0.2, 0.35, 0.95) 
			style.border_color = Color(0.9, 0.8, 0.4, 1.0)
			style.border_width_left = 4
			style.border_width_right = 4
		"critical":
			style.bg_color = Color(0.4, 0.2, 0.25, 0.9) 
			style.border_color = Color(0.9, 0.3, 0.4, 1.0)
		"major":
			style.bg_color = Color(0.22, 0.3, 0.38, 0.9) 
			style.border_color = Color(0.4, 0.7, 0.95, 1.0)
		"minor":
			style.bg_color = Color(0.18, 0.26, 0.22, 0.85) 
			style.border_color = Color(0.3, 0.7, 0.5, 0.9)
		_:
			style.bg_color = Color(0.18, 0.26, 0.32, 0.9)
			style.border_color = Color(0.35, 0.7, 0.9, 0.9)
	style.border_width_left = 3
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	container.add_theme_stylebox_override("panel", style)
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	container.add_child(margin)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	var header_box = HBoxContainer.new()
	header_box.add_theme_constant_override("separation", 12)
	vbox.add_child(header_box)
	var time_label = Label.new()
	var scenes_ago = entry.get("scenes_ago", 0)
	if _lang == "en":
		time_label.text = "%d scenes ago" % scenes_ago if scenes_ago > 1 else "Last scene"
	else:
		time_label.text = "%d場景前" % scenes_ago if scenes_ago > 1 else "上一場景"
	time_label.add_theme_font_size_override("font_size", 18)
	time_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 0.8))
	header_box.add_child(time_label)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_box.add_child(spacer)
	var type_badge = Label.new()
	match choice_type:
		"milestone":
			type_badge.text = "♦ MILESTONE" if _lang == "en" else "♦ 里程碑"
			type_badge.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
			type_badge.add_theme_font_size_override("font_size", 16)
			type_badge.push_bold() 
		"critical":
			type_badge.text = "CRITICAL" if _lang == "en" else "關鍵"
			type_badge.add_theme_color_override("font_color", Color(1.0, 0.4, 0.5))
		"major":
			type_badge.text = "MAJOR" if _lang == "en" else "重要"
			type_badge.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		"minor":
			type_badge.text = "MINOR" if _lang == "en" else "次要"
			type_badge.add_theme_color_override("font_color", Color(0.5, 0.9, 0.7))
	if choice_type != "milestone":
		type_badge.add_theme_font_size_override("font_size", 16)
	header_box.add_child(type_badge)
	var choice_label = Label.new()
	choice_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_label.text = "▸ " + entry.get("choice_text", "Unknown choice")
	choice_label.add_theme_font_size_override("font_size", 20)
	choice_label.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	choice_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(choice_label)
	var consequence_info = Label.new()
	consequence_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var triggered = entry.get("consequences_triggered", 0)
	var total = entry.get("consequences_total", 0)
	if _lang == "en":
		consequence_info.text = "↳ Consequences triggered: %d / %d" % [triggered, total]
	else:
		consequence_info.text = "↳ 已觸發後果：%d / %d" % [triggered, total]
	consequence_info.add_theme_font_size_override("font_size", 18)
	consequence_info.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9))
	vbox.add_child(consequence_info)
	var recent_consequences = entry.get("recent_consequences", [])
	if not recent_consequences.is_empty():
		var divider = HSeparator.new()
		divider.add_theme_constant_override("separation", 8)
		vbox.add_child(divider)
		var recent_label = Label.new()
		recent_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		recent_label.text = "Recent ripples:" if _lang == "en" else "最近的影響："
		recent_label.add_theme_font_size_override("font_size", 17)
		recent_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
		vbox.add_child(recent_label)
		for consequence in recent_consequences:
			var cons_label = Label.new()
			cons_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cons_label.text = "  • " + consequence.get("description", "Unknown")
			cons_label.add_theme_font_size_override("font_size", 17)
			match consequence.get("severity", "medium"):
				"low":
					cons_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
				"medium":
					cons_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6))
				"high":
					cons_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.5))
				_:
					cons_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
			cons_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			vbox.add_child(cons_label)
	return container
func _on_close_pressed():
	if AudioManager:
		AudioManager.play_sfx("menu_click", 0.7)
	queue_free()
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
