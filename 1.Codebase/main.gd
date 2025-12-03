extends Node2D
const ERROR_CONTEXT := "Main"
@onready var world: Node2D = $World
const PLAYER_SCENE: PackedScene = preload("res://1.Codebase/player.tscn")
func _ready() -> void:
	_apply_font_settings()
	_start_background_music()
	_spawn_player()
func _apply_font_settings() -> void:
	var font_manager: Node = ServiceLocator.get_font_manager() if ServiceLocator else null
	if font_manager and font_manager.has_method("load_font_settings"):
		font_manager.load_font_settings()
	else:
		_report_warning("FontManager not available; skipping font setup")
func _start_background_music() -> void:
	var audio_manager: Node = ServiceLocator.get_audio_manager() if ServiceLocator else null
	if not audio_manager:
		_report_warning("AudioManager not available; cannot start background music")
		return
	if not audio_manager.has_method("is_music_playing") or not audio_manager.has_method("play_music"):
		_report_warning("AudioManager missing required music control methods")
		return
	if audio_manager.is_music_playing():
		return
	audio_manager.play_music("background_music", true)
func _spawn_player() -> void:
	if not is_instance_valid(world):
		_report_error("World node is missing or invalid; cannot spawn player")
		return
	if PLAYER_SCENE == null:
		_report_error("Player scene preload failed")
		return
	var player_instance: Node = PLAYER_SCENE.instantiate()
	if player_instance == null:
		_report_error("Failed to instantiate player scene")
		return
	var player: CharacterBody2D = player_instance as CharacterBody2D
	if player == null:
		_report_error("Player root must inherit CharacterBody2D")
		player_instance.queue_free()
		return
	world.add_child(player_instance)
	player.position = Vector2.ZERO
func _report_error(message: String, details: Dictionary = { }) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func _report_warning(message: String) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message)
