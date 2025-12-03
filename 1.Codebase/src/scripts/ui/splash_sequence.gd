extends Control
const NEXT_SCENE_PATH = "res://1.Codebase/menu_main.tscn"
@onready var engine_logo_layer: Control = $EngineLogoLayer
@onready var author_logo_layer: Control = $AuthorLogoLayer
@onready var warning_layer: Control = $WarningLayer
@onready var metaphysics_warning_layer: Control = $MetaphysicsWarningLayer
const FADE_DURATION: float = 0.5
const HOLD_DURATION: float = 1.0
const WARNING_HOLD_DURATION: float = 2.0
var _is_skipping: bool = false
func _ready() -> void:
	engine_logo_layer.modulate.a = 0.0
	author_logo_layer.modulate.a = 0.0
	warning_layer.modulate.a = 0.0
	_play_splash_sequence()
func _play_splash_sequence() -> void:
	var tween = create_tween()
	tween.tween_callback(engine_logo_layer.show)
	tween.tween_callback(AudioManager.play_sfx.bind("card_draw"))
	tween.tween_property(engine_logo_layer, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_interval(HOLD_DURATION)
	tween.tween_property(engine_logo_layer, "modulate:a", 0.0, FADE_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(engine_logo_layer.hide)
	tween.tween_callback(author_logo_layer.show)
	tween.tween_callback(AudioManager.play_sfx.bind("card_draw"))
	tween.tween_property(author_logo_layer, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_interval(HOLD_DURATION)
	tween.tween_property(author_logo_layer, "modulate:a", 0.0, FADE_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(author_logo_layer.hide)
	tween.tween_callback(warning_layer.show)
	tween.tween_callback(AudioManager.play_sfx.bind("angry_click"))
	tween.tween_property(warning_layer, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_interval(WARNING_HOLD_DURATION)
	tween.tween_property(warning_layer, "modulate:a", 0.0, FADE_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(warning_layer.hide)
	tween.tween_callback(metaphysics_warning_layer.show)
	tween.tween_callback(AudioManager.play_sfx.bind("game_start"))
	tween.tween_property(metaphysics_warning_layer, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_interval(WARNING_HOLD_DURATION)
	tween.tween_property(metaphysics_warning_layer, "modulate:a", 0.0, FADE_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(metaphysics_warning_layer.hide)
	tween.tween_callback(_load_next_scene)
func _load_next_scene() -> void:
	if _is_skipping: return 
	_is_skipping = true
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_load_next_scene()
	elif event is InputEventMouseButton and event.pressed:
		_load_next_scene()
