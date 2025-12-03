extends Node
func _ready() -> void:
	print("[AudioTestRunner] Spawning test_audio_manager…")
	var TestScript := preload("res://1.Codebase/Unit Test/test_audio_manager.gd")
	var t := TestScript.new()
	add_child(t)
	_auto_quit()
func _auto_quit() -> void:
	await get_tree().create_timer(1.5).timeout
	print("[AudioTestRunner] Tests complete. Quitting…")
	get_tree().quit()
