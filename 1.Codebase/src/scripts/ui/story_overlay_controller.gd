extends BaseController
class_name StoryOverlayController
var pause_menu_instance: Control = null
var settings_menu_instance: Control = null
var journal_menu_instance: Control = null
var characters_page_instance: Control = null
var night_overlay_instance: Control = null
var gloria_overlay_instance: Control = null
var overlay_pause_requests: int = 0
var overlay_paused_tree: bool = false
var pause_menu_scene: PackedScene
var settings_menu_scene: PackedScene
var journal_menu_scene: PackedScene
var characters_page_scene: PackedScene
var relationship_graph_scene: PackedScene
var night_overlay_scene: PackedScene
var gloria_overlay_scene: PackedScene
var trolley_problem_overlay_scene: PackedScene
var trolley_problem_overlay_instance: Control = null
const GLORIA_BASE_LINE := "永远记住：全能神灵是为了你好，而你的痛苦只是你思想不够正面的证据。"
func _init(p_story_scene: Control) -> void:
	super(p_story_scene)  
	pause_menu_scene = load("res://1.Codebase/src/scenes/ui/pause_menu.tscn")
	settings_menu_scene = load("res://1.Codebase/src/scenes/ui/settings_menu.tscn")
	journal_menu_scene = load("res://1.Codebase/src/scenes/ui/journal_system.tscn")
	relationship_graph_scene = load("res://1.Codebase/src/scenes/ui/relationship_graph_viewer.tscn")
	characters_page_scene = load("res://1.Codebase/src/scenes/ui/characters_page.tscn")
	night_overlay_scene = load("res://1.Codebase/src/scenes/ui/night_cycle_overlay.tscn")
	gloria_overlay_scene = load("res://1.Codebase/src/scenes/ui/gloria_intervention_overlay.tscn")
func push_overlay_pause() -> bool:
	overlay_pause_requests += 1
	var tree := story_scene.get_tree()
	if tree.paused:
		return false
	tree.paused = true
	overlay_paused_tree = true
	return true
func pop_overlay_pause(paused_here: bool) -> void:
	if overlay_pause_requests == 0:
		return
	overlay_pause_requests -= 1
	if overlay_pause_requests == 0:
		if overlay_paused_tree and paused_here and not pause_menu_instance:
			if story_scene.is_inside_tree():
				story_scene.get_tree().paused = false
		overlay_paused_tree = false
func _prepare_overlay_node(node: Node) -> void:
	if not node:
		return
	node.process_mode = Node.PROCESS_MODE_ALWAYS
func open_pause_menu() -> void:
	if pause_menu_instance:
		return 
		if not pause_menu_scene:
				_report_error("Pause menu scene not loaded")
				return
	var paused_here: bool = push_overlay_pause()
	pause_menu_instance = pause_menu_scene.instantiate()
	_prepare_overlay_node(pause_menu_instance)
	story_scene.add_child(pause_menu_instance)
	if pause_menu_instance is Control:
		pause_menu_instance.z_index = 200
	if pause_menu_instance.has_signal("resume_requested"):
		pause_menu_instance.resume_requested.connect(_on_pause_resume.bind(paused_here))
	if pause_menu_instance.has_signal("settings_requested"):
		pause_menu_instance.settings_requested.connect(_on_pause_settings)
	if pause_menu_instance.has_signal("journal_requested"):
		pause_menu_instance.journal_requested.connect(_on_pause_journal)
	if pause_menu_instance.has_signal("achievements_requested"):
		pause_menu_instance.achievements_requested.connect(_on_pause_achievements)
	if pause_menu_instance.has_signal("characters_requested"):
		pause_menu_instance.characters_requested.connect(_on_pause_characters)
	if pause_menu_instance.has_signal("relationship_requested"):
		pause_menu_instance.relationship_requested.connect(_on_pause_relationship)
	if pause_menu_instance.has_signal("home_requested"):
		pause_menu_instance.home_requested.connect(_on_pause_home)
	var audio_manager = get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("menu_click")
func _on_pause_resume(paused_here: bool) -> void:
	if pause_menu_instance:
		pause_menu_instance.queue_free()
		pause_menu_instance = null
	pop_overlay_pause(paused_here)
	var audio_manager = get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("menu_click")
func _on_pause_settings() -> void:
	open_settings_menu(false)
func _on_pause_journal() -> void:
	open_journal_panel(false)
func _on_pause_achievements() -> void:
	print("[OverlayController] Opening achievements...")
func _on_pause_characters() -> void:
	open_characters_page(true) 
func _on_pause_relationship() -> void:
	open_characters_page(true)
func _on_pause_home() -> void:
	var audio_manager = get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("menu_click")
	if story_scene.is_inside_tree():
		story_scene.get_tree().paused = false
	story_scene.get_tree().change_scene_to_file("res://1.Codebase/menu_main.tscn")
func open_settings_menu(opened_from_topbar: bool = false) -> void:
	if settings_menu_instance:
		return
	if not settings_menu_scene:
		_report_error("Settings menu scene not loaded")
		return
	var paused_here: bool = push_overlay_pause()
	settings_menu_instance = settings_menu_scene.instantiate()
	_prepare_overlay_node(settings_menu_instance)
	if settings_menu_instance.has_method("set_exit_mode"):
		settings_menu_instance.set_exit_mode(settings_menu_instance.EXIT_MODE_OVERLAY)
	story_scene.add_child(settings_menu_instance)
	if settings_menu_instance is Control:
		settings_menu_instance.z_index = 200
	if settings_menu_instance.has_signal("close_requested"):
		settings_menu_instance.close_requested.connect(_on_settings_closed.bind(paused_here))
	var audio_manager = get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("menu_click")
func _on_settings_closed(paused_here: bool) -> void:
	if settings_menu_instance:
		settings_menu_instance.queue_free()
		settings_menu_instance = null
	pop_overlay_pause(paused_here)
	var audio_manager = get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("menu_click")
func open_journal_panel(opened_from_topbar: bool = false) -> void:
	if journal_menu_instance:
		return
		if not journal_menu_scene:
				_report_error("Journal menu scene not loaded")
				return
	var paused_here: bool = push_overlay_pause()
	journal_menu_instance = journal_menu_scene.instantiate()
	_prepare_overlay_node(journal_menu_instance)
	story_scene.add_child(journal_menu_instance)
	if journal_menu_instance is Control:
		journal_menu_instance.z_index = 200
	if journal_menu_instance.has_signal("close_requested"):
		journal_menu_instance.close_requested.connect(_on_journal_closed.bind(paused_here))
	var audio_manager = get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("menu_click")
func _on_journal_closed(paused_here: bool) -> void:
	if journal_menu_instance:
		journal_menu_instance.queue_free()
		journal_menu_instance = null
	pop_overlay_pause(paused_here)
	var audio_manager = get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("menu_click")
func open_characters_page(start_in_graph_mode: bool = false) -> void:
	if characters_page_instance:
		return
	if not characters_page_scene:
		_report_error("Characters page scene not loaded")
		return
	var paused_here: bool = push_overlay_pause()
	characters_page_instance = characters_page_scene.instantiate()
	_prepare_overlay_node(characters_page_instance)
	story_scene.add_child(characters_page_instance)
	if characters_page_instance is Control:
		characters_page_instance.z_index = 200
	if start_in_graph_mode and characters_page_instance.has_method("_toggle_graph_view"):
		characters_page_instance._toggle_graph_view()
	characters_page_instance.tree_exiting.connect(_on_characters_page_closed.bind(paused_here))
	var audio_manager = get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("menu_click")
func _on_characters_page_closed(paused_here: bool) -> void:
	characters_page_instance = null
	pop_overlay_pause(paused_here)
	var audio_manager = get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("menu_click")
func open_relationship_graph(opened_from_topbar: bool = false) -> void:
	if not relationship_graph_scene:
		_report_error("Relationship graph scene not loaded")
		return
	var paused_here: bool = push_overlay_pause()
	var graph_instance = relationship_graph_scene.instantiate()
	_prepare_overlay_node(graph_instance)
	story_scene.add_child(graph_instance)
	if graph_instance is Control:
		graph_instance.z_index = 200
	if graph_instance.has_signal("close_requested"):
		graph_instance.close_requested.connect(_on_relationship_graph_closed.bind(paused_here, graph_instance))
	elif graph_instance.has_signal("hidden"): 
		graph_instance.hidden.connect(_on_relationship_graph_closed.bind(paused_here, graph_instance))
	var audio_manager = get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("menu_click")
func _on_relationship_graph_closed(paused_here: bool, instance: Node) -> void:
	if instance and is_instance_valid(instance):
		instance.queue_free()
	pop_overlay_pause(paused_here)
	var audio_manager = get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("menu_click")
func open_prayer_system() -> void:
	var prayer_scene: PackedScene = load("res://1.Codebase/src/scenes/ui/prayer_system.tscn")
	if not prayer_scene:
		_report_error("Prayer system scene not loaded")
		return
	var paused_here: bool = push_overlay_pause()
	var prayer_instance: Control = prayer_scene.instantiate()
	_prepare_overlay_node(prayer_instance)
	story_scene.add_child(prayer_instance)
	if prayer_instance is Control:
		prayer_instance.z_index = 200
	var context = "mission" 
	if story_scene.has_method("get") and story_scene.get("state_controller"):
		var state_ctrl = story_scene.get("state_controller")
		if state_ctrl and is_instance_valid(state_ctrl):
			context = state_ctrl.get_prayer_context()
	if prayer_instance.has_method("set_context"):
		prayer_instance.set_context(context)
	if prayer_instance.has_signal("prayer_completed"):
		prayer_instance.prayer_completed.connect(_on_prayer_completed.bind(paused_here))
	if prayer_instance.has_signal("prayer_cancelled"):
		prayer_instance.prayer_cancelled.connect(_on_prayer_cancelled.bind(paused_here))
	var audio_manager = get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("prayer_start")
func _on_prayer_completed(result: Dictionary, paused_here: bool) -> void:
	pop_overlay_pause(paused_here)
	var game_state = get_game_state()
	if game_state:
		var lang: String = game_state.current_language
		var message: String = LocalizationManager.get_translation("STORY_PRAYER_RESPONSE", lang)
		if result.has("disaster"):
			message = String(result.get("disaster"))
		story_scene.ui_controller.display_story(message)
	var audio_manager = get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("prayer_complete")
	EventBus.publish("prayer_completed", { "result": result })
	var context = String(result.get("context", "default"))
	if context == "night" or story_scene.in_night_cycle:
		print("[OverlayController] Night prayer complete, advancing to new mission")
		if story_scene.state_controller:
			var night_overlay = story_scene.state_controller.get_night_overlay()
			if night_overlay and is_instance_valid(night_overlay):
				night_overlay.queue_free()
				story_scene.state_controller.unregister_night_overlay()
				pop_overlay_pause(true)
		story_scene.in_night_cycle = false
		if story_scene.flow_controller:
			story_scene.flow_controller.start_new_mission()
		elif story_scene.narrative_controller:
			story_scene.narrative_controller.start_new_mission()
	else:
		if story_scene.choice_controller:
			story_scene.choice_controller.generate_choices()
func _on_prayer_cancelled(paused_here: bool) -> void:
	pop_overlay_pause(paused_here)
	var context = "mission"
	if story_scene.state_controller:
		context = story_scene.state_controller.get_prayer_context()
	if context == "night":
		if story_scene.state_controller:
			var night_overlay = story_scene.state_controller.get_night_overlay()
			if night_overlay and is_instance_valid(night_overlay):
				print("[OverlayController] Prayer cancelled, restoring night overlay")
				night_overlay.visible = true
				return
	if story_scene.choice_controller:
		story_scene.choice_controller.generate_choices()
func enter_night_cycle(payload: Dictionary) -> void:
	story_scene.in_night_cycle = true
	story_scene.last_night_payload = payload
	story_scene.choice_controller.hide_choice_buttons()
	show_night_overlay()
func show_night_overlay() -> void:
	if night_overlay_instance:
		return
		if not night_overlay_scene:
				_report_error("Night overlay scene not loaded")
				return
	var paused_here: bool = push_overlay_pause()
	night_overlay_instance = night_overlay_scene.instantiate()
	_prepare_overlay_node(night_overlay_instance)
	story_scene.add_child(night_overlay_instance)
	if night_overlay_instance is Control:
		night_overlay_instance.z_index = 200
	if night_overlay_instance.has_method("set_content"):
		night_overlay_instance.set_content(story_scene.last_night_payload)
	if night_overlay_instance.has_signal("prayer_requested"):
		night_overlay_instance.prayer_requested.connect(_on_night_overlay_prayer_requested.bind(paused_here))
	if night_overlay_instance.has_signal("continue_requested"):
		night_overlay_instance.continue_requested.connect(_on_night_overlay_continue.bind(paused_here))
func _on_night_overlay_prayer_requested(paused_here: bool) -> void:
	print("[OverlayController] Transitioning from Night Cycle to Prayer System")
	if night_overlay_instance:
		night_overlay_instance.queue_free()
		night_overlay_instance = null
	pop_overlay_pause(paused_here)
	story_scene.prayer_context = "night"
	open_prayer_system()
func _on_night_overlay_continue(paused_here: bool) -> void:
	if night_overlay_instance:
		night_overlay_instance.queue_free()
		night_overlay_instance = null
	pop_overlay_pause(paused_here)
	story_scene.in_night_cycle = false
	story_scene.narrative_controller.start_new_mission()
func show_gloria_overlay(argument_text: String) -> void:
	if gloria_overlay_instance:
		return
		if not gloria_overlay_scene:
				_report_error("Gloria overlay scene not loaded")
				return
	var paused_here: bool = push_overlay_pause()
	gloria_overlay_instance = gloria_overlay_scene.instantiate()
	_prepare_overlay_node(gloria_overlay_instance)
	story_scene.add_child(gloria_overlay_instance)
	if gloria_overlay_instance is Control:
		gloria_overlay_instance.z_index = 200
	if gloria_overlay_instance.has_method("set_argument_text"):
		gloria_overlay_instance.set_argument_text(argument_text)
	if gloria_overlay_instance.has_signal("continue_requested"):
		gloria_overlay_instance.continue_requested.connect(_on_gloria_overlay_continue.bind(paused_here))
	apply_gloria_penalties()
	var audio_manager = get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("gloria_appears")
func apply_gloria_penalties() -> void:
	var game_state = get_game_state()
	if not game_state:
		return
	game_state.modify_reality_score(-10, "Gloria intervention")
	game_state.modify_positive_energy(20, "Gloria's toxic positivity")
	game_state.modify_entropy(5, "Gloria's interference")
func _on_gloria_overlay_continue(paused_here: bool) -> void:
	if gloria_overlay_instance:
		gloria_overlay_instance.queue_free()
		gloria_overlay_instance = null
	pop_overlay_pause(paused_here)
	if story_scene.choice_controller:
		story_scene.choice_controller.generate_choices()
	var game_state = get_game_state()
	if game_state:
		game_state.reset_complaint_counter()
	var lang: String = game_state.current_language if game_state else "en"
	var msg: String = "Gloria has 'encouraged' you. Reality feels more distant..." if lang == "en" else "Gloria???萸€?雿€撖行?閬箸??鈭?.."
	story_scene.ui_controller.display_story(msg)
func show_trolley_problem(dilemma_data: Dictionary) -> void:
	if not trolley_problem_overlay_scene:
		trolley_problem_overlay_scene = load("res://1.Codebase/src/scenes/ui/trolley_problem_overlay.tscn")
	if not trolley_problem_overlay_scene:
		_report_error("Trolley problem overlay scene not loaded")
		return
	var paused_here: bool = push_overlay_pause()
	var instance = trolley_problem_overlay_scene.instantiate()
	_prepare_overlay_node(instance)
	story_scene.add_child(instance)
	trolley_problem_overlay_instance = instance
	if instance is Control:
		instance.z_index = 200
	if instance.has_method("setup"):
		instance.setup(dilemma_data)
	if instance.has_signal("choice_selected"):
		instance.choice_selected.connect(_on_trolley_choice_selected.bind(paused_here))
func _on_trolley_choice_selected(choice_id: String, paused_here: bool) -> void:
	if trolley_problem_overlay_instance:
		trolley_problem_overlay_instance.queue_free()
		trolley_problem_overlay_instance = null
	pop_overlay_pause(paused_here)
	var trolley_gen = ServiceLocator.get_trolley_problem_generator() if ServiceLocator else null
	if trolley_gen:
		var resolution = trolley_gen.resolve_dilemma(choice_id)
		var lang = GameState.current_language if GameState else "en"
		var msg = ""
		if lang == "zh":
			msg = "你做出了選擇... 但代價是什麼？"
		else:
			msg = "You made your choice... but at what cost?"
		if resolution.has("immediate_consequence"):
			msg += "\n\n" + resolution["immediate_consequence"]
		var game_state = get_game_state()
		if game_state:
			var previous_text = game_state.get_latest_story_text()
			if not previous_text.is_empty():
				msg = previous_text + "\n\n" + "------------------------------------------------" + "\n\n" + msg
		story_scene.ui_controller.display_story(msg)
