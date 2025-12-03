class_name UIStyleManager
extends RefCounted
const COLOR_PRIMARY = Color(0.2, 0.2, 0.25, 0.95)
const COLOR_PRIMARY_HOVER = Color(0.3, 0.3, 0.4, 1.0)
const COLOR_PRIMARY_PRESSED = Color(0.15, 0.15, 0.2, 1.0)
const COLOR_ACCENT = Color(0.4, 0.6, 0.9, 1.0)
const COLOR_ACCENT_HOVER = Color(0.5, 0.7, 1.0, 1.0)
const COLOR_ACCENT_PRESSED = Color(0.3, 0.5, 0.8, 1.0)
const COLOR_SUCCESS = Color(0.3, 0.8, 0.4, 1.0)
const COLOR_WARNING = Color(0.9, 0.7, 0.2, 1.0)
const COLOR_DANGER = Color(0.9, 0.3, 0.3, 1.0)
const COLOR_TEXT = Color(0.9, 0.9, 1.0)
const COLOR_TEXT_HOVER = Color(1.0, 1.0, 1.0)
const COLOR_TEXT_PRESSED = Color(0.8, 0.8, 0.9)
const COLOR_TEXT_DISABLED = Color(0.5, 0.5, 0.6)
const COLOR_BORDER = Color(0.4, 0.4, 0.5, 0.8)
const COLOR_BORDER_HOVER = Color(0.6, 0.6, 0.8, 1.0)
const COLOR_BORDER_PRESSED = Color(0.3, 0.3, 0.4, 1.0)
const COLOR_PANEL_BG = Color(0.08, 0.1, 0.16, 1.0)
const COLOR_PANEL_BORDER = Color(0.3, 0.4, 0.55, 0.9)
const CORNER_RADIUS_SMALL = 6
const CORNER_RADIUS_MEDIUM = 10
const CORNER_RADIUS_LARGE = 15
const PADDING_SMALL = Vector4(8, 6, 8, 6) 
const PADDING_MEDIUM = Vector4(12, 8, 12, 8)
const PADDING_LARGE = Vector4(20, 12, 20, 12)
const FONT_SIZE_SMALL = 14
const FONT_SIZE_MEDIUM = 16
const FONT_SIZE_LARGE = 20
const FONT_SIZE_XLARGE = 24
const FONT_SIZE_TITLE = 32
static func create_button_style(color_scheme: String = "primary", size: String = "medium") -> Dictionary:
	var colors = _get_color_scheme(color_scheme)
	var padding = _get_padding(size)
	var corner_radius = _get_corner_radius(size)
	var style_normal = _create_stylebox(colors.normal, COLOR_BORDER, corner_radius, padding)
	var style_hover = _create_stylebox(colors.hover, COLOR_BORDER_HOVER, corner_radius, padding)
	var style_pressed = _create_stylebox(colors.pressed, COLOR_BORDER_PRESSED, corner_radius, padding)
	return {
		"normal": style_normal,
		"hover": style_hover,
		"pressed": style_pressed,
		"font_color": COLOR_TEXT,
		"font_hover_color": COLOR_TEXT_HOVER,
		"font_pressed_color": COLOR_TEXT_PRESSED,
		"font_disabled_color": COLOR_TEXT_DISABLED,
		"font_size": _get_font_size(size),
	}
static func apply_button_style(button: Button, color_scheme: String = "primary", size: String = "medium") -> void:
	var style = create_button_style(color_scheme, size)
	button.add_theme_stylebox_override("normal", style.normal)
	button.add_theme_stylebox_override("hover", style.hover)
	button.add_theme_stylebox_override("pressed", style.pressed)
	button.add_theme_color_override("font_color", style.font_color)
	button.add_theme_color_override("font_hover_color", style.font_hover_color)
	button.add_theme_color_override("font_pressed_color", style.font_pressed_color)
	button.add_theme_color_override("font_disabled_color", style.font_disabled_color)
	button.add_theme_font_size_override("font_size", style.font_size)
static func create_panel_style(opacity: float = 0.95, corner_radius: int = CORNER_RADIUS_MEDIUM, border_tint: Color = COLOR_PANEL_BORDER, bg_tint: Color = COLOR_PANEL_BG) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(bg_tint.r, bg_tint.g, bg_tint.b, opacity)
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border_tint
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	return style
static func apply_panel_style(control: Control, opacity: float = 0.95, corner_radius: int = CORNER_RADIUS_MEDIUM, border_tint: Color = COLOR_PANEL_BORDER, bg_tint: Color = COLOR_PANEL_BG, style_name: String = "panel") -> void:
	if not control:
		return
	var style = create_panel_style(opacity, corner_radius, border_tint, bg_tint)
	control.add_theme_stylebox_override(style_name, style)
static func create_progress_style(color_scheme: String = "accent") -> Dictionary:
	var colors = _get_color_scheme(color_scheme)
	var background = StyleBoxFlat.new()
	background.bg_color = COLOR_PANEL_BG.darkened(0.4)
	background.corner_radius_top_left = CORNER_RADIUS_SMALL
	background.corner_radius_top_right = CORNER_RADIUS_SMALL
	background.corner_radius_bottom_left = CORNER_RADIUS_SMALL
	background.corner_radius_bottom_right = CORNER_RADIUS_SMALL
	background.border_width_left = 2
	background.border_width_top = 2
	background.border_width_right = 2
	background.border_width_bottom = 2
	background.border_color = COLOR_BORDER.darkened(0.2)
	var foreground = StyleBoxFlat.new()
	foreground.bg_color = colors.normal
	foreground.corner_radius_top_left = CORNER_RADIUS_SMALL
	foreground.corner_radius_top_right = CORNER_RADIUS_SMALL
	foreground.corner_radius_bottom_left = CORNER_RADIUS_SMALL
	foreground.corner_radius_bottom_right = CORNER_RADIUS_SMALL
	foreground.border_width_left = 0
	foreground.border_width_top = 0
	foreground.border_width_right = 0
	foreground.border_width_bottom = 0
	return {
		"background": background,
		"foreground": foreground,
		"font_color": COLOR_TEXT,
	}
static func apply_progress_style(bar: ProgressBar, color_scheme: String = "accent") -> void:
	if not bar:
		return
	var style = create_progress_style(color_scheme)
	bar.add_theme_stylebox_override("bg", style.background)
	bar.add_theme_stylebox_override("fg", style.foreground)
	bar.add_theme_color_override("font_color", style.font_color)
	bar.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	bar.add_theme_constant_override("font_outline_size", 1)
static func create_input_style() -> Dictionary:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.1, 0.1, 0.15, 1.0)
	style_normal.corner_radius_top_left = CORNER_RADIUS_SMALL
	style_normal.corner_radius_top_right = CORNER_RADIUS_SMALL
	style_normal.corner_radius_bottom_left = CORNER_RADIUS_SMALL
	style_normal.corner_radius_bottom_right = CORNER_RADIUS_SMALL
	style_normal.border_width_left = 2
	style_normal.border_width_top = 2
	style_normal.border_width_right = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = COLOR_BORDER
	style_normal.content_margin_left = 10
	style_normal.content_margin_right = 10
	style_normal.content_margin_top = 8
	style_normal.content_margin_bottom = 8
	var style_focus = StyleBoxFlat.new()
	style_focus.bg_color = Color(0.15, 0.15, 0.2, 1.0)
	style_focus.corner_radius_top_left = CORNER_RADIUS_SMALL
	style_focus.corner_radius_top_right = CORNER_RADIUS_SMALL
	style_focus.corner_radius_bottom_left = CORNER_RADIUS_SMALL
	style_focus.corner_radius_bottom_right = CORNER_RADIUS_SMALL
	style_focus.border_width_left = 2
	style_focus.border_width_top = 2
	style_focus.border_width_right = 2
	style_focus.border_width_bottom = 2
	style_focus.border_color = COLOR_ACCENT
	style_focus.content_margin_left = 10
	style_focus.content_margin_right = 10
	style_focus.content_margin_top = 8
	style_focus.content_margin_bottom = 8
	return {
		"normal": style_normal,
		"focus": style_focus,
		"font_color": COLOR_TEXT,
		"font_size": FONT_SIZE_MEDIUM,
	}
static func apply_input_style(line_edit: LineEdit) -> void:
	var style = create_input_style()
	line_edit.add_theme_stylebox_override("normal", style.normal)
	line_edit.add_theme_stylebox_override("focus", style.focus)
	line_edit.add_theme_color_override("font_color", style.font_color)
	line_edit.add_theme_font_size_override("font_size", style.font_size)
static func _get_color_scheme(scheme: String) -> Dictionary:
	match scheme:
		"primary":
			return {
				"normal": COLOR_PRIMARY,
				"hover": COLOR_PRIMARY_HOVER,
				"pressed": COLOR_PRIMARY_PRESSED,
			}
		"accent":
			return {
				"normal": COLOR_ACCENT,
				"hover": COLOR_ACCENT_HOVER,
				"pressed": COLOR_ACCENT_PRESSED,
			}
		"success":
			return {
				"normal": COLOR_SUCCESS,
				"hover": COLOR_SUCCESS.lightened(0.1),
				"pressed": COLOR_SUCCESS.darkened(0.1),
			}
		"warning":
			return {
				"normal": COLOR_WARNING,
				"hover": COLOR_WARNING.lightened(0.1),
				"pressed": COLOR_WARNING.darkened(0.1),
			}
		"danger":
			return {
				"normal": COLOR_DANGER,
				"hover": COLOR_DANGER.lightened(0.1),
				"pressed": COLOR_DANGER.darkened(0.1),
			}
		_:
			return {
				"normal": COLOR_PRIMARY,
				"hover": COLOR_PRIMARY_HOVER,
				"pressed": COLOR_PRIMARY_PRESSED,
			}
static func _get_padding(size: String) -> Vector4:
	match size:
		"small":
			return PADDING_SMALL
		"large":
			return PADDING_LARGE
		_:
			return PADDING_MEDIUM
static func _get_corner_radius(size: String) -> int:
	match size:
		"small":
			return CORNER_RADIUS_SMALL
		"large":
			return CORNER_RADIUS_LARGE
		_:
			return CORNER_RADIUS_MEDIUM
static func _get_font_size(size: String) -> int:
	match size:
		"small":
			return FONT_SIZE_SMALL
		"large":
			return FONT_SIZE_LARGE
		"xlarge":
			return FONT_SIZE_XLARGE
		_:
			return FONT_SIZE_MEDIUM
static func _create_stylebox(bg_color: Color, border_color: Color, corner_radius: int, padding: Vector4) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border_color
	style.content_margin_left = padding.x
	style.content_margin_top = padding.y
	style.content_margin_right = padding.z
	style.content_margin_bottom = padding.w
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style
static func add_hover_scale_effect(control: Control, scale_amount: float = 1.05, duration: float = 0.15) -> void:
	if not control:
		return
	var original_scale = control.scale
	var target_scale = original_scale * scale_amount
	if not control.mouse_entered.is_connected(_on_hover_enter.bind(control, target_scale, duration)):
		control.mouse_entered.connect(_on_hover_enter.bind(control, target_scale, duration))
	if not control.mouse_exited.is_connected(_on_hover_exit.bind(control, original_scale, duration)):
		control.mouse_exited.connect(_on_hover_exit.bind(control, original_scale, duration))
static func _on_hover_enter(control: Control, target_scale: Vector2, duration: float) -> void:
	if control and control.is_inside_tree():
		var tween = control.create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(control, "scale", target_scale, duration)
static func _on_hover_exit(control: Control, original_scale: Vector2, duration: float) -> void:
	if control and control.is_inside_tree():
		var tween = control.create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(control, "scale", original_scale, duration)
static func add_press_feedback(button: Button, scale_amount: float = 0.95, duration: float = 0.1) -> void:
	if not button:
		return
	if not button.button_down.is_connected(_on_button_press.bind(button, scale_amount, duration)):
		button.button_down.connect(_on_button_press.bind(button, scale_amount, duration))
	if not button.button_up.is_connected(_on_button_release.bind(button, duration)):
		button.button_up.connect(_on_button_release.bind(button, duration))
static func _on_button_press(button: Button, scale_amount: float, duration: float) -> void:
	if button and button.is_inside_tree():
		var tween = button.create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(button, "scale", Vector2(scale_amount, scale_amount), duration)
static func _on_button_release(button: Button, duration: float) -> void:
	if button and button.is_inside_tree():
		var tween = button.create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), duration * 2)
static func fade_in(control: Control, duration: float = 0.3) -> void:
	if not control:
		return
	control.modulate.a = 0.0
	var tween = control.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(control, "modulate:a", 1.0, duration)
static func fade_out(control: Control, duration: float = 0.3) -> void:
	if not control:
		return
	var tween = control.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(control, "modulate:a", 0.0, duration)
static func slide_in_from_bottom(control: Control, duration: float = 0.4, offset: float = 50.0) -> void:
	if not control:
		return
	var original_pos = control.position
	control.position.y += offset
	control.modulate.a = 0.0
	var tween = control.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)
	tween.tween_property(control, "position:y", original_pos.y, duration)
	tween.tween_property(control, "modulate:a", 1.0, duration * 0.7)
static func pulse_effect(control: Control, intensity: float = 0.1, duration: float = 0.5) -> void:
	if not control:
		return
	if control.size != Vector2.ZERO:
		control.pivot_offset = control.size / 2
	var original_scale = control.scale
	var target_scale = original_scale * (1.0 + intensity)
	var tween = control.create_tween()
	tween.set_loops()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(control, "scale", target_scale, duration / 2)
	tween.tween_property(control, "scale", original_scale, duration / 2)
static func shake_effect(control: Control, intensity: float = 10.0, duration: float = 0.3) -> void:
	if not control:
		return
	var original_pos = control.position
	var tween = control.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	for i in range(4):
		var offset_x = randf_range(-intensity, intensity)
		var offset_y = randf_range(-intensity, intensity)
		tween.tween_property(control, "position", original_pos + Vector2(offset_x, offset_y), duration / 8)
	tween.tween_property(control, "position", original_pos, duration / 8)
static func add_glow_effect(control: Control, glow_color: Color = COLOR_ACCENT, intensity: float = 0.3) -> void:
	if not control:
		return
	var shader_code = """
shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.4, 0.6, 0.9, 1.0);
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec4 glow = glow_color * glow_intensity;
	COLOR = color + glow * color.a;
}
"""
	var shader = Shader.new()
	shader.code = shader_code
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("glow_color", glow_color)
	material.set_shader_parameter("glow_intensity", intensity)
	control.material = material
static func create_depth_shadow_panel(opacity: float = 0.95, depth_layers: int = 3) -> StyleBoxFlat:
	var style = create_panel_style(opacity)
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 12 * depth_layers
	style.shadow_offset = Vector2(0, 4 * depth_layers)
	return style
static func add_parallax_hover_effect(control: Control, depth: float = 0.02) -> void:
	if not control:
		return
	var original_pos = control.position
	control.mouse_entered.connect(
		func():
			control.set_process(true)
	)
	control.mouse_exited.connect(
		func():
			control.set_process(false)
			var tween = control.create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(control, "position", original_pos, 0.3)
	)
static func create_location_badge_style() -> Dictionary:
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.12, 0.16, 0.22, 0.95)
	bg_style.corner_radius_top_left = 15
	bg_style.corner_radius_top_right = 15
	bg_style.corner_radius_bottom_left = 15
	bg_style.corner_radius_bottom_right = 15
	bg_style.border_width_left = 2
	bg_style.border_width_top = 2
	bg_style.border_width_right = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.4, 0.6, 0.9, 0.8)
	bg_style.shadow_color = Color(0.4, 0.6, 0.9, 0.4)
	bg_style.shadow_size = 10
	bg_style.shadow_offset = Vector2(0, 3)
	bg_style.content_margin_left = 20
	bg_style.content_margin_top = 10
	bg_style.content_margin_right = 20
	bg_style.content_margin_bottom = 10
	return {
		"panel": bg_style,
		"text_color": Color(0.9, 0.95, 1.0, 1.0),
		"icon_color": COLOR_ACCENT,
	}
static func smooth_value_change(control: Label, from_value: float, to_value: float, duration: float = 0.5, format_string: String = "%.0f") -> void:
	if not control or not control.is_inside_tree():
		return
	var tween = control.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	var temp_value = from_value
	tween.tween_method(
		func(value: float):
			control.text = format_string % value,
		from_value,
		to_value,
		duration,
	)
