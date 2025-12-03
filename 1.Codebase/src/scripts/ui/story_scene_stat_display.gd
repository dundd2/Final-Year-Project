extends RefCounted
class_name StorySceneStatDisplay
var reality_bar: ProgressBar
var reality_label: Label
var positive_bar: ProgressBar
var positive_label: Label
var entropy_label: Label
var parent_control: Control 
var _cached_reality: int = 50
var _cached_positive: int = 50
var _cached_entropy: int = 0
const LOW_THRESHOLD := 0.3
const MEDIUM_THRESHOLD := 0.6
func _init(
		p_reality_bar: ProgressBar = null,
		p_reality_label: Label = null,
		p_positive_bar: ProgressBar = null,
		p_positive_label: Label = null,
		p_entropy_label: Label = null,
		p_parent_control: Control = null
):
	reality_bar = p_reality_bar
	reality_label = p_reality_label
	positive_bar = p_positive_bar
	positive_label = p_positive_label
	entropy_label = p_entropy_label
	parent_control = p_parent_control
func subscribe_to_events() -> void:
	EventBus.subscribe("reality_score_changed", self, "_on_reality_changed")
	EventBus.subscribe("positive_energy_changed", self, "_on_positive_changed")
	EventBus.subscribe("entropy_level_changed", self, "_on_entropy_changed")
	EventBus.subscribe("stats_changed", self, "_on_all_stats_changed")
	_request_initial_stats()
func unsubscribe() -> void:
	EventBus.unsubscribe_all(self)
func _request_initial_stats() -> void:
	var stats = EventBus.request("get_all_stats")
	if stats and stats is Dictionary:
		_cached_reality = stats.get("reality_score", 50)
		_cached_positive = stats.get("positive_energy", 50)
		_cached_entropy = stats.get("entropy_level", 0)
		_update_all_displays(true) 
func _on_reality_changed(data: Dictionary) -> void:
	var new_value = data.get("new_value", _cached_reality)
	var old_value = data.get("old_value", _cached_reality)
	_cached_reality = new_value
	_update_reality_display(new_value, new_value - old_value)
func _on_positive_changed(data: Dictionary) -> void:
	var new_value = data.get("new_value", _cached_positive)
	var old_value = data.get("old_value", _cached_positive)
	_cached_positive = new_value
	_update_positive_display(new_value, new_value - old_value)
func _on_entropy_changed(data: Dictionary) -> void:
	var new_value = data.get("new_value", _cached_entropy)
	var old_value = data.get("old_value", _cached_entropy)
	_cached_entropy = new_value
	_update_entropy_display(new_value, new_value - old_value)
func _on_all_stats_changed(data: Dictionary) -> void:
	_cached_reality = data.get("reality_score", _cached_reality)
	_cached_positive = data.get("positive_energy", _cached_positive)
	_cached_entropy = data.get("entropy_level", _cached_entropy)
	_update_all_displays()
func _update_reality_display(value: int, delta: int = 0) -> void:
	var color = _get_stat_color(value, 100)
	if reality_bar:
		if abs(delta) > 0 and reality_bar.is_inside_tree():
			var tween = reality_bar.create_tween()
			tween.tween_property(reality_bar, "value", float(value), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			reality_bar.value = value
		reality_bar.modulate = color
	if reality_label:
		UIStyleManager.smooth_value_change(reality_label, float(reality_label.text.to_int()), float(value))
		reality_label.modulate = color
	if abs(delta) >= 5 and reality_bar:
		UIStyleManager.pulse_effect(reality_bar, 0.05, 0.3)
	if delta != 0:
		_spawn_floating_text(delta, reality_bar if reality_bar else reality_label, color)
func _update_positive_display(value: int, delta: int = 0) -> void:
	var color = _get_stat_color(value, 100)
	if positive_bar:
		if abs(delta) > 0 and positive_bar.is_inside_tree():
			var tween = positive_bar.create_tween()
			tween.tween_property(positive_bar, "value", float(value), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			positive_bar.value = value
		positive_bar.modulate = color
	if positive_label:
		UIStyleManager.smooth_value_change(positive_label, float(positive_label.text.to_int()), float(value))
	if abs(delta) >= 5 and positive_bar:
		UIStyleManager.pulse_effect(positive_bar, 0.05, 0.3)
	if delta != 0:
		_spawn_floating_text(delta, positive_bar if positive_bar else positive_label, color)
func _update_entropy_display(value: int, delta: int = 0) -> void:
	var danger_ratio = clampf(float(value) / 50.0, 0.0, 1.0)
	var color = Color(0.5, 1.0, 0.5) 
	if danger_ratio >= 0.6:
		color = Color(1.0, 0.3, 0.3) 
	elif danger_ratio >= 0.3:
		color = Color(1.0, 0.8, 0.3) 
	if entropy_label:
		entropy_label.text = str(value)
		entropy_label.modulate = color
	if delta != 0:
		_spawn_floating_text(delta, entropy_label, color)
func _update_all_displays(immediate: bool = false) -> void:
	if immediate:
		if reality_bar: reality_bar.value = _cached_reality
		if reality_label: reality_label.text = str(_cached_reality)
		if positive_bar: positive_bar.value = _cached_positive
		if positive_label: positive_label.text = str(_cached_positive)
		if entropy_label: entropy_label.text = str(_cached_entropy)
	else:
		_update_reality_display(_cached_reality)
		_update_positive_display(_cached_positive)
		_update_entropy_display(_cached_entropy)
func _spawn_floating_text(delta: int, anchor_node: Control, color: Color) -> void:
	if not parent_control or not anchor_node or not parent_control.is_inside_tree():
		return
	var label = Label.new()
	var prefix = "+" if delta > 0 else ""
	label.text = prefix + str(delta)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color(0,0,0,0.5))
	parent_control.add_child(label)
	var global_start = anchor_node.global_position + Vector2(anchor_node.size.x / 2, -10)
	label.global_position = global_start
	var tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", global_start.y - 40, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)
func _get_stat_color(value: int, max_value: int) -> Color:
	var ratio = clampf(float(value) / float(max_value), 0.0, 1.0)
	if ratio < LOW_THRESHOLD:
		return Color(1.0, 0.3, 0.3) 
	elif ratio < MEDIUM_THRESHOLD:
		return Color(1.0, 0.8, 0.3) 
	else:
		return Color(0.5, 1.0, 0.5) 
func get_formatted_reality_text() -> String:
	var color = _get_stat_color(_cached_reality, 100)
	return "[color=#%s]%d[/color]" % [color.to_html(false), _cached_reality]
func is_reality_critical() -> bool:
	return _cached_reality < 20
func is_positive_energy_low() -> bool:
	return _cached_positive < 30
func is_entropy_critical() -> bool:
	return _cached_entropy > 30
