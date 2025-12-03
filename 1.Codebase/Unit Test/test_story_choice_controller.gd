extends Node
const StoryChoiceControllerScript = preload("res://1.Codebase/src/scripts/ui/story_choice_controller.gd")
var controller
var mock_scene
func _ready():
	print("Starting StoryChoiceController Tests")
	mock_scene = Control.new()
	var mock_script = GDScript.new()
	mock_script.source_code = """
extends Control
var in_night_cycle: bool = false
var awaiting_ai_response: bool = false
var ui_controller = null
var narrative_controller = null
var overlay_controller = null
var ui = null
"""
	mock_script.reload()
	mock_scene.set_script(mock_script)
	add_child(mock_scene)
	var choices_area = Control.new()
	choices_area.name = "ChoicesArea"
	mock_scene.add_child(choices_area)
	var choices_container = VBoxContainer.new()
	choices_container.name = "ChoicesContainer"
	choices_area.add_child(choices_container)
	for i in range(1, 4):
		var btn = Button.new()
		btn.name = "Choice%d" % i
		choices_container.add_child(btn)
	var show_btn = Button.new()
	show_btn.name = "ShowOptionsBtn"
	choices_area.add_child(show_btn)
	controller = StoryChoiceControllerScript.new(mock_scene)
	await _test_choice_generation()
	await _test_choice_processing()
	mock_scene.queue_free()
	queue_free()
func _test_choice_generation():
	print("Testing Choice Generation...")
	if GameState:
		var old_stats = GameState.player_stats
		GameState.player_stats = {"logic": 5, "perception": 1, "composure": 1, "empathy": 1}
		controller.generate_choices()
		var choices = controller.current_choices
		if choices.size() > 0:
			print("PASS: Choices generated")
			var types = []
			for c in choices: types.append(c["type"])
			if "logic" in types:
				print("PASS: Logic skill choice generated")
			else:
				print("FAIL: Logic skill choice missing")
			if "positive" in types and "complain" in types:
				print("PASS: Default choices present")
			else:
				print("FAIL: Default choices missing")
		else:
			print("FAIL: No choices generated")
		GameState.player_stats = old_stats
	await get_tree().process_frame
func _test_choice_processing():
	print("Testing Choice Processing...")
	var mock_ui = Node.new()
	var ui_script = GDScript.new()
	ui_script.source_code = """
extends Node
func set_status_text(txt): pass
func display_story(txt): pass
"""
	ui_script.reload()
	mock_ui.set_script(ui_script)
	mock_scene.ui_controller = mock_ui
	mock_scene.add_child(mock_ui) 
	if controller.current_choices.size() > 0:
		var choice = controller.current_choices[0]
		controller.process_choice(choice)
		print("PASS: process_choice executed without error")
	await get_tree().process_frame
