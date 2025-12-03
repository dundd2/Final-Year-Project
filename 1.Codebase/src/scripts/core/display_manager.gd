extends Node
signal window_size_changed(new_size: Vector2i)
var current_window_size: Vector2i
var base_resolution: Vector2i = Vector2i(1920, 1080)
func _ready():
	current_window_size = DisplayServer.window_get_size()
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	call_deferred("apply_settings_from_config")
	print("DisplayManager initialized. Current window size: ", current_window_size)
func _on_viewport_size_changed():
	var new_size = get_viewport().size
	if new_size != current_window_size:
		current_window_size = Vector2i(new_size)
		window_size_changed.emit(current_window_size)
		print("Window size changed to: ", current_window_size)
func get_scale_factor() -> Vector2:
	var viewport_size = get_viewport().size
	return Vector2(
		float(viewport_size.x) / float(base_resolution.x),
		float(viewport_size.y) / float(base_resolution.y),
	)
func get_uniform_scale_factor() -> float:
	var scale = get_scale_factor()
	return min(scale.x, scale.y)
func apply_settings_from_config():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		var font_size = config.get_value("display", "font_size", 2)
		var window_mode = config.get_value("display", "mode", 0)  
		var resolution = config.get_value("display", "resolution", Vector2i(1024, 600))
		if FontManager:
			FontManager.set_font_size(font_size)
		_apply_window_mode(window_mode, resolution)
		print("Display settings applied - Font: %d, Mode: %d" % [font_size, window_mode])
	else:
		_ensure_windowed_with_titlebar()
func _apply_window_mode(mode: int, resolution: Vector2i) -> void:
	var window := get_window()
	match mode:
		0:  
			if window:
				window.mode = Window.MODE_WINDOWED
				window.borderless = false
				window.size = resolution
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
				DisplayServer.window_set_size(resolution)
		1:  
			if window:
				window.borderless = false
				window.mode = Window.MODE_FULLSCREEN
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:  
			if window:
				window.mode = Window.MODE_WINDOWED
				window.borderless = true
				window.size = resolution
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
				DisplayServer.window_set_size(resolution)
func _ensure_windowed_with_titlebar() -> void:
	var window := get_window()
	if window:
		if window.borderless:
			window.borderless = false
			print("DisplayManager: Restored window title bar")
	else:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
func set_window_size(size: Vector2i):
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		get_viewport().size = size
		DisplayServer.window_set_size(size)
		current_window_size = size
func toggle_fullscreen():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
