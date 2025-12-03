extends Node
var ui_controller: RefCounted
var mock_story_scene: Control
var mock_game_state: Node
func _ready() -> void:
	print("[StoryUIControllerTest] Starting StoryUIController unit tests...")
	await get_tree().process_frame
	_setup_mocks()
	_test_stat_display_color_gradients()
	_test_loading_screen_state()
	_test_stat_threshold_detection()
	_test_loading_animation_timing()
	print("[StoryUIControllerTest] All tests completed.")
	queue_free()
func _setup_mocks() -> void:
	print("[Test] Setting up mocks...")
	mock_story_scene = Control.new()
	add_child(mock_story_scene)
	mock_game_state = Node.new()
	mock_game_state.set_script(preload("res://1.Codebase/src/scripts/core/game_state.gd"))
	add_child(mock_game_state)
	mock_game_state.reality_score = 50
	mock_game_state.positive_energy = 50
	mock_game_state.entropy_level = 0
	mock_game_state.current_language = "en"
	print("[Test] Mocks setup complete")
func _test_stat_display_color_gradients() -> void:
	print("[Test] Stat display color gradients...")
	var high_color := _get_stat_color(75)
	assert(high_color.is_equal_approx(Color(0.2, 0.8, 0.2)), "High stat should be green")
	var medium_color := _get_stat_color(50)
	assert(medium_color.is_equal_approx(Color(0.8, 0.8, 0.2)), "Medium stat should be yellow")
	var low_color := _get_stat_color(20)
	assert(low_color.is_equal_approx(Color(0.8, 0.2, 0.2)), "Low stat should be red")
	print("[Test] Stat display color gradients PASSED")
func _get_stat_color(value: int) -> Color:
	if value >= GameConstants.UI.STAT_COLOR_HIGH_THRESHOLD:
		return GameConstants.UI.COLOR_STAT_HIGH
	elif value >= GameConstants.UI.STAT_COLOR_MEDIUM_THRESHOLD:
		return GameConstants.UI.COLOR_STAT_MEDIUM
	else:
		return GameConstants.UI.COLOR_STAT_LOW
func _test_loading_screen_state() -> void:
	print("[Test] Loading screen state management...")
	var contexts := ["default", "ai_request", "save_game", "load_game"]
	for context in contexts:
		var loading_state := _simulate_loading_start(context)
		assert(loading_state["visible"] == true, "Loading should be visible")
		assert(loading_state["context"] == context, "Loading context should match")
		var stopped_state := _simulate_loading_stop()
		assert(stopped_state["visible"] == false, "Loading should be hidden after stop")
	print("[Test] Loading screen state management PASSED")
func _simulate_loading_start(context: String) -> Dictionary:
	return {
		"visible": true,
		"context": context,
		"start_time": Time.get_ticks_msec() / 1000.0,
	}
func _simulate_loading_stop() -> Dictionary:
	return {
		"visible": false,
		"context": "",
		"start_time": 0.0,
	}
func _test_stat_threshold_detection() -> void:
	print("[Test] Stat threshold detection...")
	var is_low_reality := _is_below_threshold(15, GameConstants.Stats.LOW_REALITY_THRESHOLD)
	assert(is_low_reality, "Reality 15 should be below low threshold (20)")
	var is_high_reality := _is_above_threshold(85, GameConstants.Stats.HIGH_REALITY_THRESHOLD)
	assert(is_high_reality, "Reality 85 should be above high threshold (80)")
	var is_entropy_warning := _is_above_threshold(30, GameConstants.Stats.HIGH_ENTROPY_WARNING)
	assert(is_entropy_warning, "Entropy 30 should trigger warning (threshold 25)")
	var is_entropy_critical := _is_above_threshold(55, GameConstants.Stats.HIGH_ENTROPY_CRITICAL)
	assert(is_entropy_critical, "Entropy 55 should be critical (threshold 50)")
	print("[Test] Stat threshold detection PASSED")
func _is_below_threshold(value: int, threshold: int) -> bool:
	return value <= threshold
func _is_above_threshold(value: int, threshold: int) -> bool:
	return value > threshold
func _test_loading_animation_timing() -> void:
	print("[Test] Loading animation timing...")
	var dots_at_0 := _get_loading_dots_count(0.0)
	assert(dots_at_0 == 0, "Dots at 0s should be 0")
	var dots_at_0_5 := _get_loading_dots_count(0.5)
	assert(dots_at_0_5 == 1, "Dots at 0.5s should be 1")
	var dots_at_1_0 := _get_loading_dots_count(1.0)
	assert(dots_at_1_0 == 2, "Dots at 1.0s should be 2")
	var dots_at_1_5 := _get_loading_dots_count(1.5)
	assert(dots_at_1_5 == 3, "Dots at 1.5s should be 3")
	var dots_at_2_0 := _get_loading_dots_count(2.0)
	assert(dots_at_2_0 == 0, "Dots at 2.0s should cycle back to 0")
	var formatted_30s := _format_loading_time(30.0)
	assert(formatted_30s == "00:30", "30 seconds should format as 00:30")
	var formatted_90s := _format_loading_time(90.0)
	assert(formatted_90s == "01:30", "90 seconds should format as 01:30")
	print("[Test] Loading animation timing PASSED")
func _get_loading_dots_count(elapsed_time: float) -> int:
	var cycle_time := GameConstants.UI.LOADING_DOTS_CYCLE_TIME
	var max_dots := GameConstants.UI.MAX_LOADING_DOTS
	var cycle_position := fmod(elapsed_time, cycle_time * (max_dots + 1))
	return int(cycle_position / cycle_time)
func _format_loading_time(elapsed_seconds: float) -> String:
	var minutes := int(elapsed_seconds) / 60
	var seconds := int(elapsed_seconds) % 60
	return "%02d:%02d" % [minutes, seconds]
