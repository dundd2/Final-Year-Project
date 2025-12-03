extends Control
var label: Label
const REFRESH_INTERVAL_SECONDS := 1.0
var _refresh_timer := 0.0
func _ready():
	label = Label.new()
	label.position = Vector2(10, 10)
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)
	_update_label()
	if DisplayManager:
		DisplayManager.window_size_changed.connect(_on_window_resized)
		print("ResponsiveScalingTest: Connected to DisplayManager")
	get_tree().root.size_changed.connect(_update_label)
func _update_label():
	var viewport_size = get_viewport().size
	var window_size = DisplayServer.window_get_size()
	var scale_factor = DisplayManager.get_scale_factor() if DisplayManager else Vector2.ONE
	var uniform_scale = DisplayManager.get_uniform_scale_factor() if DisplayManager else 1.0
	var info_text = ""
	info_text += "=== Responsive Scaling Info ===\n"
	info_text += "Viewport Size: %d x %d\n" % [viewport_size.x, viewport_size.y]
	info_text += "Window Size: %d x %d\n" % [window_size.x, window_size.y]
	info_text += "Scale Factor: %.2f x %.2f\n" % [scale_factor.x, scale_factor.y]
	info_text += "Uniform Scale: %.2f\n" % uniform_scale
	info_text += "Window Mode: %s\n" % _get_window_mode_name()
	info_text += "\nPress F11 to toggle fullscreen"
	if label:
		label.text = info_text
func _on_window_resized(new_size: Vector2i):
	_update_label()
	print("Window resized to: ", new_size)
func _get_window_mode_name() -> String:
	match DisplayServer.window_get_mode():
		DisplayServer.WINDOW_MODE_WINDOWED:
			return "Windowed"
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			return "Fullscreen"
		DisplayServer.WINDOW_MODE_MAXIMIZED:
			return "Maximized"
		_:
			return "Unknown"
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		if DisplayManager:
			DisplayManager.toggle_fullscreen()
		_update_label()
func _process(delta):
	_refresh_timer += delta
	while _refresh_timer >= REFRESH_INTERVAL_SECONDS:
		_refresh_timer -= REFRESH_INTERVAL_SECONDS
		_update_label()
