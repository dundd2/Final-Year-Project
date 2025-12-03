extends RefCounted
const COLOR_TITLE := Color(0.94, 0.96, 1.0) 
const COLOR_TITLE_GOLD := Color(1.0, 0.9, 0.3) 
const COLOR_TITLE_MUTED := Color(0.5, 0.5, 0.5) 
const COLOR_TEXT_PRIMARY := Color(0.8, 0.9, 1.0) 
const COLOR_TEXT_SECONDARY := Color(0.7, 0.7, 0.7) 
const COLOR_TEXT_HIGHLIGHT := Color(1.0, 0.9, 0.4) 
const COLOR_ACCENT_BLUE := Color(0.4, 0.7, 1.0) 
const COLOR_ACCENT_ORANGE := Color(1.0, 0.5, 0.3) 
const COLOR_LINE := Color(0.6, 0.6, 0.8, 0.5) 
const COLOR_SUCCESS := Color(0.3, 0.8, 0.3) 
const COLOR_WARNING := Color(1.0, 0.9, 0.4) 
const COLOR_ERROR := Color(0.8, 0.3, 0.3) 
const COLOR_LOCKED := Color(0.3, 0.3, 0.3) 
const COLOR_BG_PANEL := Color(0.15, 0.15, 0.15, 0.8) 
const COLOR_BG_UNLOCKED := Color(0.2, 0.3, 0.2, 0.5) 
const COLOR_BG_LOCKED := Color(0.15, 0.15, 0.15, 0.6) 
const COLOR_BG_HIDDEN := Color(0.3, 0.15, 0.15, 0.8) 
const COLOR_BORDER_DEFAULT := Color(0.5, 0.5, 0.5, 0.8) 
const COLOR_BORDER_SUCCESS := Color(0.3, 0.8, 0.3, 1.0) 
const COLOR_BORDER_LOCKED := Color(0.5, 0.4, 0.2, 1.0) 
const COLOR_BORDER_ERROR := Color(0.8, 0.3, 0.3, 1.0) 
const FONT_SIZE_TITLE := 24
const FONT_SIZE_SUBTITLE := 20
const FONT_SIZE_BODY := 16
const FONT_SIZE_SMALL := 14
const FONT_SIZE_TINY := 12
const BUTTON_HEIGHT := 40
const BUTTON_WIDTH_SMALL := 100
const BUTTON_WIDTH_MEDIUM := 150
const BUTTON_WIDTH_LARGE := 200
const ICON_SIZE_SMALL := 24
const ICON_SIZE_MEDIUM := 32
const ICON_SIZE_LARGE := 48
const ICON_SIZE_XLARGE := 64
const PANEL_MIN_WIDTH := 300
const PANEL_MIN_HEIGHT := 200
const PANEL_PADDING := 20
const SCROLLBAR_WIDTH := 12
const BORDER_WIDTH := 2
const CORNER_RADIUS := 8
const CORNER_RADIUS_SMALL := 4
const CORNER_RADIUS_LARGE := 12
const SPACING_TINY := 4
const SPACING_SMALL := 8
const SPACING_MEDIUM := 16
const SPACING_LARGE := 24
const SPACING_XLARGE := 32
const MARGIN_SMALL := 8
const MARGIN_MEDIUM := 16
const MARGIN_LARGE := 24
const DURATION_INSTANT := 0.0
const DURATION_VERY_FAST := 0.1
const DURATION_FAST := 0.2
const DURATION_NORMAL := 0.3
const DURATION_SLOW := 0.5
const DURATION_VERY_SLOW := 1.0
const FADE_IN_DURATION := 0.3
const FADE_OUT_DURATION := 0.2
const FADE_CROSSFADE_DURATION := 0.4
const DELAY_SHORT := 0.1
const DELAY_MEDIUM := 0.5
const DELAY_LONG := 1.0
const NOTIFICATION_DURATION_SHORT := 2.0
const NOTIFICATION_DURATION_NORMAL := 3.0
const NOTIFICATION_DURATION_LONG := 5.0
const TOOLTIP_SHOW_DELAY := 0.5
const TOOLTIP_HIDE_DELAY := 0.1
const OPACITY_INVISIBLE := 0.0
const OPACITY_FAINT := 0.3
const OPACITY_TRANSLUCENT := 0.5
const OPACITY_SEMI_OPAQUE := 0.7
const OPACITY_OPAQUE := 1.0
const OPACITY_DISABLED := 0.5
const OPACITY_HOVER := 0.8
const Z_BACKGROUND := -10
const Z_NORMAL := 0
const Z_OVERLAY := 10
const Z_POPUP := 20
const Z_TOOLTIP := 30
const Z_MODAL := 40
const Z_DEBUG := 100
const EASE_LINEAR := Tween.EASE_IN_OUT
const EASE_SMOOTH := Tween.EASE_OUT
const EASE_BOUNCE := Tween.EASE_OUT
const EASE_ELASTIC := Tween.EASE_OUT
static func create_panel_style(
		bg_color: Color = COLOR_BG_PANEL,
		border_color: Color = COLOR_BORDER_DEFAULT,
		border_width: int = BORDER_WIDTH,
		corner_radius: int = CORNER_RADIUS,
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	return style
static func create_success_panel_style() -> StyleBoxFlat:
	return create_panel_style(COLOR_BG_UNLOCKED, COLOR_BORDER_SUCCESS)
static func create_locked_panel_style() -> StyleBoxFlat:
	return create_panel_style(COLOR_BG_LOCKED, COLOR_BORDER_LOCKED)
static func create_error_panel_style() -> StyleBoxFlat:
	return create_panel_style(COLOR_BG_HIDDEN, COLOR_BORDER_ERROR)
static func apply_title_style(label: Label, color: Color = COLOR_TITLE) -> void:
	if not label:
		return
	label.add_theme_font_size_override("font_size", FONT_SIZE_TITLE)
	label.add_theme_color_override("font_color", color)
static func apply_body_style(label: Label, color: Color = COLOR_TEXT_PRIMARY) -> void:
	if not label:
		return
	label.add_theme_font_size_override("font_size", FONT_SIZE_BODY)
	label.add_theme_color_override("font_color", color)
static func apply_muted_style(label: Label) -> void:
	if not label:
		return
	label.add_theme_font_size_override("font_size", FONT_SIZE_SMALL)
	label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
static func create_fade_in_tween(node: Control, duration: float = FADE_IN_DURATION) -> Tween:
	if not node:
		return null
	node.modulate.a = OPACITY_INVISIBLE
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", OPACITY_OPAQUE, duration)
	return tween
static func create_fade_out_tween(node: Control, duration: float = FADE_OUT_DURATION) -> Tween:
	if not node:
		return null
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", OPACITY_INVISIBLE, duration)
	return tween
static func animate_color_transition(
		label: Label,
		target_color: Color,
		duration: float = DURATION_NORMAL,
) -> Tween:
	if not label:
		return null
	var tween := label.create_tween()
	var current_color: Color = label.get_theme_color("font_color", "Label") if label.has_theme_color_override("font_color") else Color.WHITE
	tween.tween_method(
		func(color: Color): label.add_theme_color_override("font_color", color),
		current_color,
		target_color,
		duration,
	)
	return tween
