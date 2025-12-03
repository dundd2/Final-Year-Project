extends Control
class_name StorySceneCoordinator
const ERROR_CONTEXT := "StorySceneCoordinator"
const MENU_SCENE_PATH := "res://1.Codebase/menu_main.tscn"
const StoryStateControllerScript := preload("res://1.Codebase/src/scripts/ui/story_state_controller.gd")
const StoryFlowControllerScript := preload("res://1.Codebase/src/scripts/ui/story_flow_controller.gd")
const StoryNarrativeControllerScript := preload("res://1.Codebase/src/scripts/ui/story_narrative_controller.gd")
const StoryChoiceControllerScript := preload("res://1.Codebase/src/scripts/ui/story_choice_controller.gd")
const StoryUIControllerScript := preload("res://1.Codebase/src/scripts/ui/story_ui_controller.gd")
const StoryAssetControllerScript := preload("res://1.Codebase/src/scripts/ui/story_asset_controller.gd")
const StoryOverlayControllerScript := preload("res://1.Codebase/src/scripts/ui/story_overlay_controller.gd")
const WELCOME_COPY := {
	"en": "Welcome to Glorious Deliverance Agency 1.\n\nYour mission: hold reality together while weaponised optimism tears it apart.\nEvery choice pushes entropy higher.\n\nPress any option to begin.",
	"zh": "歡迎來到 Glorious Deliverance Agency 1。\n\n你的任務：在武器化的正能量撕裂現實時維持清醒。\n每個抉擇都會拉高熵值。\n\n按任一選項開始。",
}
var ui: StorySceneUIBindings = null
var event_handlers: StorySceneEventHandlers = null
var stat_display: StorySceneStatDisplay = null
var state_controller: StoryStateController = null
var flow_controller: StoryFlowController = null
var narrative_controller: StoryNarrativeController = null
var choice_controller: StoryChoiceController = null
var ui_controller: StoryUIController = null
var asset_controller: StoryAssetController = null
var overlay_controller: StoryOverlayController = null
var _is_initialized: bool = false
var _subscribed_to_events: bool = false
func _ready() -> void:
	if not _run_initialization_pipeline():
		return
	_is_initialized = true
	_log_info("Story scene coordinator ready")
func _exit_tree() -> void:
	_log_info("Story scene coordinator shutting down")
	_cleanup()
func _process(_delta: float) -> void:
	pass
func _run_initialization_pipeline() -> bool:
	var steps: Array[Dictionary] = [
		{ "name": "ui_bindings", "fn": Callable(self, "_initialize_ui_bindings") },
		{ "name": "event_handlers", "fn": Callable(self, "_initialize_event_handlers") },
		{ "name": "stat_display", "fn": Callable(self, "_initialize_stat_display") },
		{ "name": "controllers", "fn": Callable(self, "_initialize_controllers") },
		{ "name": "event_subscriptions", "fn": Callable(self, "_subscribe_to_events") },
		{ "name": "scene_bootstrap", "fn": Callable(self, "_initialize_scene") },
	]
	for step in steps:
		var success: bool = bool(step["fn"].call())
		if not success:
			_report_error("Initialization step failed", { "step": step["name"] })
			return false
	return true
func _initialize_ui_bindings() -> bool:
	ui = StorySceneUIBindings.new()
	if not ui.bind_to_scene(self):
		_report_error("UI binding failed")
		return false
	ui.setup_voice_input_button(self)
	ui.setup_butterfly_button(self)
	ui.setup_loading_debug_label()
	_log_info("UI bindings established", { "button_count": ui.get_all_buttons().size() })
	return true
func _initialize_event_handlers() -> bool:
	if ui == null:
		_report_error("Cannot initialize event handlers without UI bindings")
		return false
	event_handlers = StorySceneEventHandlers.new(ui, self)
	event_handlers.connect_all_signals()
	return true
func _initialize_stat_display() -> bool:
	if ui == null:
		_report_error("Cannot initialize stat display without UI bindings")
		return false
	stat_display = StorySceneStatDisplay.new(
		ui.reality_bar,
		ui.reality_value,
		ui.positive_bar,
		ui.positive_value,
		ui.entropy_value,
	)
	stat_display.subscribe_to_events()
	return true
func _initialize_controllers() -> bool:
	state_controller = StoryStateControllerScript.new(self)
	narrative_controller = StoryNarrativeControllerScript.new(self)
	ui_controller = StoryUIControllerScript.new(self)
	asset_controller = StoryAssetControllerScript.new(self)
	choice_controller = StoryChoiceControllerScript.new(self)
	overlay_controller = StoryOverlayControllerScript.new(self)
	flow_controller = StoryFlowControllerScript.new(self)
	flow_controller.set_controllers(
		state_controller,
		narrative_controller,
		ui_controller,
		choice_controller,
		overlay_controller,
	)
	return true
func _subscribe_to_events() -> bool:
	var bus: Node = _get_event_bus()
	if bus == null:
		return false
	var subscriptions: Array[Dictionary] = [
		{ "name": "pause_requested", "method": "_on_pause_requested" },
		{ "name": "settings_menu_requested", "method": "_on_settings_requested" },
		{ "name": "journal_requested", "method": "_on_journal_requested" },
		{ "name": "return_to_menu_requested", "method": "_on_return_to_menu" },
		{ "name": "choice_selected", "method": "_on_choice_selected" },
		{ "name": "next_step_requested", "method": "_on_next_step" },
		{ "name": "show_loading_overlay", "method": "_on_show_loading" },
		{ "name": "hide_loading_overlay", "method": "_on_hide_loading" },
		{ "name": "update_loading_display", "method": "_on_update_loading" },
		{ "name": "start_mission", "method": "_on_start_mission" },
		{ "name": "mission_completed", "method": "_on_mission_completed" },
	]
	for entry in subscriptions:
		bus.subscribe(entry["name"], self, entry["method"])
	_subscribed_to_events = true
	return true
func _initialize_scene() -> bool:
	_apply_visual_styles()
	_show_welcome_message()
	_publish_event(
		"start_mission",
		{
			"mission_id": 1,
			"context": "game_start",
		},
	)
	return true
func _on_pause_requested(_data: Dictionary) -> void:
	if overlay_controller:
		overlay_controller.open_pause_menu()
	else:
		_report_warning("Pause requested but overlay controller is unavailable")
func _on_settings_requested(_data: Dictionary) -> void:
	if overlay_controller:
		overlay_controller.open_settings_menu()
	else:
		_report_warning("Settings requested but overlay controller is unavailable")
func _on_journal_requested(_data: Dictionary) -> void:
	if overlay_controller:
		overlay_controller.open_journal_panel()
	else:
		_report_warning("Journal requested but overlay controller is unavailable")
func _on_return_to_menu(data: Dictionary) -> void:
	var should_confirm: bool = data.get("require_confirmation", true)
	if should_confirm:
		_publish_event(
			"show_confirmation",
			{
				"title": "Return to Menu?",
				"message": "Unsaved progress will be lost. Continue?",
				"confirm_action": "return_to_menu_confirmed",
			},
		)
	else:
		_return_to_main_menu()
func _on_choice_selected(data: Dictionary) -> void:
	var choice_index: int = data.get("choice_index", -1)
	if not choice_controller:
		_report_warning("Choice selected but controller is unavailable", { "choice_index": choice_index })
		return
	var choices := choice_controller.current_choices
	if choice_index < 0 or choice_index >= choices.size():
		_report_warning(
			"Choice index out of range",
			{
				"choice_index": choice_index,
				"choice_count": choices.size(),
			},
		)
		return
	var selected_choice := choices[choice_index]
	if selected_choice is Dictionary:
		choice_controller.process_choice(selected_choice)
	else:
		_report_warning(
			"Choice payload is not a dictionary",
			{
				"choice_index": choice_index,
				"type": typeof(selected_choice),
			},
		)
func _on_next_step(_data: Dictionary) -> void:
	if flow_controller:
		flow_controller.advance_story()
	else:
		_report_warning("Next step requested but flow controller is unavailable")
func _on_show_loading(_data: Dictionary) -> void:
	if ui and ui.loading_overlay:
		ui.loading_overlay.visible = true
func _on_hide_loading(_data: Dictionary) -> void:
	if ui and ui.loading_overlay:
		ui.loading_overlay.visible = false
func _on_update_loading(data: Dictionary) -> void:
	if ui:
		if ui.loading_label:
			ui.loading_label.text = data.get("status", "")
		if ui.loading_sublabel:
			var progress: float = clampf(float(data.get("progress", 0.0)), 0.0, 1.0)
			ui.loading_sublabel.text = "%.0f%%" % (progress * 100.0)
func _on_start_mission(data: Dictionary) -> void:
	if flow_controller:
		var mission_id: int = data.get("mission_id", 1)
		flow_controller.start_mission(mission_id)
	else:
		_report_warning("Start mission requested but flow controller is unavailable", data)
func _on_mission_completed(_data: Dictionary) -> void:
	pass
func _apply_visual_styles() -> void:
	if not ui:
		return
	var font_manager: Node = ServiceLocator.get_font_manager() if ServiceLocator else null
	if font_manager and font_manager.has_method("get_font_size"):
		for button in ui.get_all_buttons():
			if button:
				var font_size: int = int(font_manager.get_font_size())
				if font_size > 0:
					button.add_theme_font_size_override("font_size", font_size)
	if ui.background_deco:
		ui.background_deco.color = Color(0.1, 0.1, 0.15, 0.8)
func _show_welcome_message() -> void:
	if not ui or not ui.story_text:
		return
	var lang: String = _get_current_language()
	var message: String = WELCOME_COPY.get(lang, WELCOME_COPY["en"])
	ui.story_text.text = message
func _return_to_main_menu() -> void:
	_log_info("Returning to main menu")
	var tree: SceneTree = get_tree()
	if tree:
		tree.change_scene_to_file(MENU_SCENE_PATH)
func _cleanup() -> void:
	if _subscribed_to_events:
		var bus: Node = _get_event_bus()
		if bus:
			bus.unsubscribe_all(self)
		_subscribed_to_events = false
	if stat_display:
		stat_display.unsubscribe()
	if event_handlers:
		event_handlers.disconnect_all()
func is_ready() -> bool:
	return _is_initialized
func get_ui() -> StorySceneUIBindings:
	return ui
func get_event_handlers() -> StorySceneEventHandlers:
	return event_handlers
func get_stat_display() -> StorySceneStatDisplay:
	return stat_display
func _get_event_bus() -> Node:
	if not ServiceLocator:
		_report_error("ServiceLocator unavailable while resolving EventBus")
		return null
	var bus: Node = ServiceLocator.get_event_bus()
	if bus == null:
		_report_error("EventBus service not registered")
	return bus
func _publish_event(event_name: String, payload: Dictionary = { }) -> void:
	var bus: Node = _get_event_bus()
	if bus:
		bus.publish(event_name, payload)
func _get_current_language() -> String:
	const DEFAULT_LANG := "en"
	if not ServiceLocator:
		return DEFAULT_LANG
	var game_state: Node = ServiceLocator.get_game_state()
	if game_state == null:
		return DEFAULT_LANG
	var lang_value: Variant = game_state.get("current_language") if game_state.has_method("get") else game_state.current_language
	if typeof(lang_value) == TYPE_STRING:
		var lang: String = String(lang_value)
		return lang if not lang.is_empty() else DEFAULT_LANG
	return DEFAULT_LANG
func _log_info(message: String, details: Dictionary = { }) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = { }) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = { }) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
