extends Control
signal transition_completed
@onready var background: ColorRect = $Background
@onready var content_container: Control = $CenterContainer
@onready var mission_title: Label = $CenterContainer/VBoxContainer/MissionTitle
@onready var stats_label: Label = $CenterContainer/VBoxContainer/StatsLabel
const FADE_IN_DURATION := 1.0
const HOLD_DURATION := 2.5
const FADE_OUT_DURATION := 1.0
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100 
	modulate.a = 0.0
	content_container.modulate.a = 0.0
func setup(mission_number: int, previous_turns: int) -> void:
	var lang = GameState.current_language if GameState else "en"
	if lang == "en":
		mission_title.text = "Mission %d" % mission_number
		if previous_turns > 0:
			stats_label.text = "Previous mission resolved in %d turns" % previous_turns
		else:
			stats_label.text = "The journey begins..."
	else:
		mission_title.text = "第 %d 章" % mission_number
		if previous_turns > 0:
			stats_label.text = "上一章節耗時 %d 回合" % previous_turns
		else:
			stats_label.text = "旅程開始..."
func play_transition() -> void:
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(content_container, "modulate:a", 1.0, FADE_IN_DURATION * 0.8).set_delay(FADE_IN_DURATION * 0.2)
	tween.tween_interval(HOLD_DURATION)
	tween.tween_callback(_on_hold_finished)
func _on_hold_finished() -> void:
	if not _is_finishing:
		_show_loading_state()
func _show_loading_state() -> void:
	var lang = GameState.current_language if GameState else "en"
	stats_label.text = "Generating story..." if lang == "en" else "正在生成故事..."
var _is_finishing: bool = false
func play_transition_in() -> void:
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(content_container, "modulate:a", 1.0, FADE_IN_DURATION * 0.8).set_delay(FADE_IN_DURATION * 0.2)
	tween.tween_interval(HOLD_DURATION)
	tween.tween_callback(_on_hold_finished)
func finish_transition() -> void:
	_is_finishing = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
