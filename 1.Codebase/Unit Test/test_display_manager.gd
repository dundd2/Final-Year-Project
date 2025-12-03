extends Node
var initial_window_size: Vector2i
func _ready() -> void:
	print("[DisplayManagerTest] Starting DisplayManager unit tests...")
	await get_tree().process_frame
	if not DisplayManager:
		print("[DisplayManagerTest] ❌ FAIL: DisplayManager autoload not found")
		queue_free()
		get_tree().quit(1)
		return
	initial_window_size = DisplayManager.current_window_size
	_test_initialization()
	_test_current_window_size()
	_test_base_resolution()
	_test_get_scale_factor()
	_test_get_uniform_scale_factor()
	_test_scale_factor_calculations()
	await _test_signal_emission()
	_test_fullscreen_toggle()
	print("[DisplayManagerTest] All tests completed.")
	queue_free()
	get_tree().quit()
func _test_initialization() -> void:
	print("[Test] Initialization...")
	assert(DisplayManager != null, "DisplayManager should exist as autoload")
	assert(DisplayManager.current_window_size is Vector2i, "current_window_size should be Vector2i")
	assert(DisplayManager.base_resolution is Vector2i, "base_resolution should be Vector2i")
	assert(DisplayManager.base_resolution.x > 0, "base_resolution.x should be positive")
	assert(DisplayManager.base_resolution.y > 0, "base_resolution.y should be positive")
	assert(DisplayManager.base_resolution == Vector2i(1920, 1080), "Default base resolution should be 1920x1080")
	print("[Test] Initialization PASSED ✅")
func _test_current_window_size() -> void:
	print("[Test] Current window size...")
	var window_size = DisplayManager.current_window_size
	assert(window_size is Vector2i, "Should return Vector2i")
	assert(window_size.x > 0, "Window width should be positive")
	assert(window_size.y > 0, "Window height should be positive")
	print("[Test] Current window size PASSED ✅")
func _test_base_resolution() -> void:
	print("[Test] Base resolution...")
	var base = DisplayManager.base_resolution
	assert(base is Vector2i, "Base resolution should be Vector2i")
	assert(base.x == 1920, "Base width should be 1920")
	assert(base.y == 1080, "Base height should be 1080")
	print("[Test] Base resolution PASSED ✅")
func _test_get_scale_factor() -> void:
	print("[Test] Get scale factor...")
	var scale = DisplayManager.get_scale_factor()
	assert(scale is Vector2, "Scale factor should be Vector2")
	assert(scale.x > 0.0, "Scale X should be positive")
	assert(scale.y > 0.0, "Scale Y should be positive")
	var viewport_size = DisplayManager.get_viewport().size
	var expected_scale_x = float(viewport_size.x) / 1920.0
	var expected_scale_y = float(viewport_size.y) / 1080.0
	assert(abs(scale.x - expected_scale_x) < 0.01, "Scale X should match calculation")
	assert(abs(scale.y - expected_scale_y) < 0.01, "Scale Y should match calculation")
	print("[Test] Get scale factor PASSED ✅")
func _test_get_uniform_scale_factor() -> void:
	print("[Test] Get uniform scale factor...")
	var uniform_scale = DisplayManager.get_uniform_scale_factor()
	assert(uniform_scale is float, "Uniform scale should be float")
	assert(uniform_scale > 0.0, "Uniform scale should be positive")
	var scale = DisplayManager.get_scale_factor()
	var expected_uniform = min(scale.x, scale.y)
	assert(abs(uniform_scale - expected_uniform) < 0.01, "Uniform scale should be min of x/y scales")
	print("[Test] Get uniform scale factor PASSED ✅")
func _test_scale_factor_calculations() -> void:
	print("[Test] Scale factor calculations...")
	var scale1 = DisplayManager.get_scale_factor()
	await get_tree().process_frame
	var scale2 = DisplayManager.get_scale_factor()
	assert(scale1.x == scale2.x, "Scale X should be consistent")
	assert(scale1.y == scale2.y, "Scale Y should be consistent")
	var scale = DisplayManager.get_scale_factor()
	var uniform = DisplayManager.get_uniform_scale_factor()
	assert(uniform <= scale.x or abs(uniform - scale.x) < 0.01, "Uniform scale should be <= scale.x")
	assert(uniform <= scale.y or abs(uniform - scale.y) < 0.01, "Uniform scale should be <= scale.y")
	print("[Test] Scale factor calculations PASSED ✅")
func _test_signal_emission() -> void:
	print("[Test] Signal emission...")
	var signal_received = false
	var signal_size = Vector2i.ZERO
	var signal_handler = func(new_size: Vector2i):
		signal_received = true
		signal_size = new_size
	if not DisplayManager.window_size_changed.is_connected(signal_handler):
		DisplayManager.window_size_changed.connect(signal_handler)
	assert(DisplayManager.has_signal("window_size_changed"), "Should have window_size_changed signal")
	if DisplayManager.window_size_changed.is_connected(signal_handler):
		DisplayManager.window_size_changed.disconnect(signal_handler)
	print("[Test] Signal emission PASSED ✅")
func _test_fullscreen_toggle() -> void:
	print("[Test] Fullscreen toggle...")
	var initial_mode = DisplayServer.window_get_mode()
	assert(DisplayManager.has_method("toggle_fullscreen"), "Should have toggle_fullscreen method")
	if DisplayServer.get_name() != "headless":
		DisplayManager.toggle_fullscreen()
		await get_tree().create_timer(0.1).timeout
		var new_mode = DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(initial_mode)
	print("[Test] Fullscreen toggle PASSED ✅")
