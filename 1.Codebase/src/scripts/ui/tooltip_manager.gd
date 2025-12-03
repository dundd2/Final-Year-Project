extends Node
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
var tooltip_panel: PanelContainer = null
var tooltip_label: Label = null
var tooltip_timer: Timer = null
var current_target: Control = null
var is_showing: bool = false
const TOOLTIP_DELAY = 0.5 
const TOOLTIP_OFFSET = Vector2(10, -10) 
func _ready():
	_create_tooltip_ui()
func _create_tooltip_ui():
	tooltip_panel = PanelContainer.new()
	tooltip_panel.name = "TooltipPanel"
	tooltip_panel.visible = false
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.z_index = 1000 
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.95)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.5, 0.7, 0.8)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	tooltip_panel.add_theme_stylebox_override("panel", style)
	tooltip_label = Label.new()
	tooltip_label.name = "TooltipLabel"
	tooltip_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	tooltip_label.add_theme_font_size_override("font_size", 14)
	tooltip_panel.add_child(tooltip_label)
	tooltip_timer = Timer.new()
	tooltip_timer.name = "TooltipTimer"
	tooltip_timer.wait_time = TOOLTIP_DELAY
	tooltip_timer.one_shot = true
	tooltip_timer.timeout.connect(_on_timer_timeout)
	add_child(tooltip_timer)
	add_child(tooltip_panel)
func register_tooltip(control: Control, text: String, icon: String = "") -> void:
	if not control:
		return
	control.set_meta("tooltip_text", text)
	if icon:
		control.set_meta("tooltip_icon", icon)
	if not control.mouse_entered.is_connected(_on_control_mouse_entered):
		control.mouse_entered.connect(_on_control_mouse_entered.bind(control))
	if not control.mouse_exited.is_connected(_on_control_mouse_exited):
		control.mouse_exited.connect(_on_control_mouse_exited.bind(control))
func _on_control_mouse_entered(control: Control) -> void:
	current_target = control
	tooltip_timer.start()
func _on_control_mouse_exited(control: Control) -> void:
	if current_target == control:
		current_target = null
		tooltip_timer.stop()
		hide_tooltip()
func _on_timer_timeout() -> void:
	if current_target and current_target.is_inside_tree():
		show_tooltip()
func show_tooltip() -> void:
	if not current_target or is_showing:
		return
	var text = current_target.get_meta("tooltip_text", "")
	if text.is_empty():
		return
	var icon = current_target.get_meta("tooltip_icon", "")
	if not icon.is_empty():
		tooltip_label.text = icon + " " + text
	else:
		tooltip_label.text = text
	_update_tooltip_position()
	tooltip_panel.modulate.a = 0.0
	tooltip_panel.visible = true
	is_showing = true
	var tween = tooltip_panel.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(tooltip_panel, "modulate:a", 1.0, 0.2)
func hide_tooltip() -> void:
	if not is_showing:
		return
	is_showing = false
	var tween = tooltip_panel.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(tooltip_panel, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func(): tooltip_panel.visible = false)
func _update_tooltip_position() -> void:
	if not current_target or not current_target.is_inside_tree():
		return
	var viewport = current_target.get_viewport()
	if not viewport:
		return
	var mouse_pos = viewport.get_mouse_position()
	var tooltip_size = tooltip_panel.size
	var viewport_size = viewport.get_visible_rect().size
	var pos = mouse_pos + TOOLTIP_OFFSET
	if pos.x + tooltip_size.x > viewport_size.x:
		pos.x = mouse_pos.x - tooltip_size.x - abs(TOOLTIP_OFFSET.x)
	if pos.y + tooltip_size.y > viewport_size.y:
		pos.y = mouse_pos.y - tooltip_size.y - abs(TOOLTIP_OFFSET.y)
	tooltip_panel.position = pos
func _process(_delta):
	if is_showing and current_target:
		_update_tooltip_position()
