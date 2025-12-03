extends Control
const ERROR_CONTEXT := "StoryScene"
const DIRECTIVE_SNIPPET_LIMIT := 240
var ui: StorySceneUIBindings = null
var event_handlers: StorySceneEventHandlers = null
var stat_display: StorySceneStatDisplay = null
const StoryStateControllerScript = preload("res://1.Codebase/src/scripts/ui/story_state_controller.gd")
const StoryFlowControllerScript = preload("res://1.Codebase/src/scripts/ui/story_flow_controller.gd")
const StoryNarrativeControllerScript = preload("res://1.Codebase/src/scripts/ui/story_narrative_controller.gd")
const StoryChoiceControllerScript = preload("res://1.Codebase/src/scripts/ui/story_choice_controller.gd")
const StoryUIControllerScript = preload("res://1.Codebase/src/scripts/ui/story_ui_controller.gd")
const StoryAssetControllerScript = preload("res://1.Codebase/src/scripts/ui/story_asset_controller.gd")
const StoryOverlayControllerScript = preload("res://1.Codebase/src/scripts/ui/story_overlay_controller.gd")
const LoadingDisplay = preload("res://1.Codebase/src/scripts/ui/loading_display.gd")
const ICON_PAUSE = preload("res://1.Codebase/src/assets/ui/icon_pause.svg")
const ICON_SETTINGS = preload("res://1.Codebase/src/assets/ui/icon_settings.svg")
const ICON_JOURNAL = preload("res://1.Codebase/src/assets/ui/icon_journal.svg")
const ICON_OPTIONS = preload("res://1.Codebase/src/assets/ui/icon_options.svg")
const ICON_NEXT = preload("res://1.Codebase/src/assets/ui/icon_next.svg")
var state_controller: StoryStateController = null
var flow_controller: StoryFlowController = null
var narrative_controller: StoryNarrativeController = null
var choice_controller: StoryChoiceController = null
var ui_controller: StoryUIController = null
var asset_controller: StoryAssetController = null
var overlay_controller: StoryOverlayController = null
var _is_initialized := false
var awaiting_ai_response := false
var in_night_cycle := false
var current_mission: Dictionary = { }
var current_choices: Array = []
var _last_loading_message: String = "Loading..."
var _last_loading_context: String = "default"
var _last_progress_timestamp: float = 0.0
var _progress_updates_seen: int = 0
var _progress_lag_logged: bool = false
var _is_mock_override_active: bool = false
var _system_back_supported: bool = false
var is_mission_complete_state: bool = false
var mission_complete_container: PanelContainer = null
var mission_complete_label: Label = null
var mission_complete_timer_label: Label = null
var _mission_complete_tween: Tween = null
var _exit_confirmation_dialog: ConfirmationDialog = null
const STORY_IRRELEVANT_PURPOSE_PREFIXES := ["journal", "note", "test"]
const STORY_IRRELEVANT_PURPOSES := {
	"journal_prompt": true,
	"journal_summary": true,
	"concert_lyrics": true,
	"ai_settings": true,
	"ai_settings_test": true,
}
func _ready() -> void:
	print("\n========== Story Scene Starting ==========")
	_system_back_supported = _detect_system_back_support()
	if get_tree():
		get_tree().set_auto_accept_quit(false)
	if not _initialize_new_modules():
		_report_error("Failed to initialize modules")
		return
	_initialize_legacy_controllers()
	_create_exit_confirmation_dialog()
	_create_mission_complete_ui()
	_subscribe_to_coordination_events()
	_initialize_scene()
	_setup_mission_info_display()
	_is_initialized = true
	print("[StoryScene] Initialization complete")
	print("==================================================\n")
func _exit_tree() -> void:
	print("[StoryScene] Shutting down...")
	if get_tree():
		get_tree().set_auto_accept_quit(true)
	_cleanup()
func _process(delta: float) -> void:
	if ui_controller:
		ui_controller.process_loading_animation(delta)
	if awaiting_ai_response and _last_progress_timestamp > 0.0:
		var elapsed: float = (Time.get_ticks_msec() / 1000.0) - _last_progress_timestamp
		if elapsed > 2.0 and not _progress_lag_logged:
			print("[StoryScene][Loading] No AI progress update for %.2fs (updates seen: %d)" % [elapsed, _progress_updates_seen])
			_progress_lag_logged = true
func _notification(what: int) -> void:
	const NOTIFICATION_WM_GO_BACK_REQUESTED := 1002
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			_on_close_request()
		NOTIFICATION_WM_GO_BACK_REQUESTED:
			_handle_back_navigation()
		NOTIFICATION_APPLICATION_PAUSED:
			_on_application_paused()
		NOTIFICATION_APPLICATION_RESUMED:
			_on_application_resumed()
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			_on_window_focus_lost()
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			_on_window_focus_gained()
func _handle_back_navigation() -> void:
	if not _should_process_system_back():
		print("[StoryScene] System back request ignored (unsupported platform)")
		return
	if EventBus:
		EventBus.publish(
			"return_to_menu_requested",
			{
				"confirm": true,
				"source": "system_back",
			},
		)
		return
	if _exit_confirmation_dialog:
		_exit_confirmation_dialog.popup_centered()
	else:
		_perform_exit_to_menu()
func _should_process_system_back() -> bool:
	return _system_back_supported
func _detect_system_back_support() -> bool:
	if OS.has_feature("mobile"):
		return true
	var platform := OS.get_name().to_lower()
	return platform == "android" or platform == "ios"
func _on_application_paused() -> void:
	print("[StoryScene] Application paused during gameplay")
func _on_application_resumed() -> void:
	print("[StoryScene] Application resumed during gameplay")
func _on_window_focus_lost() -> void:
	print("[StoryScene] Window focus lost - game will auto-save")
func _on_window_focus_gained() -> void:
	print("[StoryScene] Window focus regained - resuming gameplay")
func _on_close_request() -> void:
	print("[StoryScene] Window close requested - quitting game...")
	get_tree().quit()
func _initialize_new_modules() -> bool:
	print("[StoryScene] Initializing Phase 2 modules...")
	ui = StorySceneUIBindings.new()
	if not ui.bind_to_scene(self):
		_report_error("UI binding failed")
		return false
	ui.setup_voice_input_button(self)
	ui.setup_butterfly_button(self)
	ui.setup_loading_debug_label()
	print("[StoryScene] ??UI bindings: %d buttons" % ui.get_all_buttons().size())
	event_handlers = StorySceneEventHandlers.new(ui, self)
	event_handlers.connect_all_signals()
	print("[StoryScene] ??Event handlers connected")
	stat_display = StorySceneStatDisplay.new(
		ui.reality_bar,
		ui.reality_value,
		ui.positive_bar,
		ui.positive_value,
		ui.entropy_value,
		self
	)
	stat_display.subscribe_to_events()
	print("[StoryScene] ??Stat display subscribed to events")
	return true
func _initialize_legacy_controllers() -> void:
	print("[StoryScene] Initializing controllers...")
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
	if ServiceLocator:
		ServiceLocator.register_service("StoryFlowController", flow_controller)
	print("[StoryScene] Controllers initialized")
	if ServiceLocator:
		var trolley_gen = ServiceLocator.get_trolley_problem_generator()
		if trolley_gen:
			if not trolley_gen.is_connected("dilemma_generated", _on_dilemma_generated):
				trolley_gen.dilemma_generated.connect(_on_dilemma_generated)
			print("[StoryScene] Trolley Problem Generator connected")
func _on_dilemma_generated(dilemma_data: Dictionary) -> void:
	print("[StoryScene] Dilemma generated, showing overlay")
	if overlay_controller:
		overlay_controller.show_trolley_problem(dilemma_data)
func _create_exit_confirmation_dialog() -> void:
	_exit_confirmation_dialog = ConfirmationDialog.new()
	add_child(_exit_confirmation_dialog)
	var lang := LocalizationManager.get_language()
	_exit_confirmation_dialog.dialog_text = LocalizationManager.get_translation("STORY_EXIT_CONFIRM_TEXT", lang)
	_exit_confirmation_dialog.title = LocalizationManager.get_translation("STORY_EXIT_CONFIRM_TITLE", lang)
	_exit_confirmation_dialog.ok_button_text = LocalizationManager.get_translation("STORY_EXIT_CONFIRM_OK", lang)
	_exit_confirmation_dialog.cancel_button_text = LocalizationManager.get_translation("STORY_EXIT_CONFIRM_CANCEL", lang)
	_exit_confirmation_dialog.confirmed.connect(_on_exit_confirmed)
	print("[StoryScene] ??Exit confirmation dialog created")
func _create_mission_complete_ui() -> void:
	mission_complete_container = PanelContainer.new()
	mission_complete_container.visible = false
	mission_complete_container.name = "MissionCompleteUI"
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style_box.set_corner_radius_all(10)
	style_box.set_border_width_all(2)
	style_box.border_color = Color(0.6, 0.4, 0.8, 0.8) 
	mission_complete_container.add_theme_stylebox_override("panel", style_box)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	mission_complete_container.add_child(vbox)
	mission_complete_label = Label.new()
	mission_complete_label.add_theme_font_size_override("font_size", 20)
	mission_complete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_complete_label.text = "Mission Complete"
	vbox.add_child(mission_complete_label)
	mission_complete_timer_label = Label.new()
	mission_complete_timer_label.add_theme_font_size_override("font_size", 16)
	mission_complete_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_complete_timer_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4)) 
	mission_complete_timer_label.text = "Preparing Night Cycle..."
	vbox.add_child(mission_complete_timer_label)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_child(mission_complete_container)
	margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	margin.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	margin.offset_left = -20
	margin.offset_top = -120
	margin.offset_right = -20
	margin.offset_bottom = -120
	add_child(margin)
func show_mission_complete_countdown(duration: float = 30.0) -> void:
	print("[StoryScene] Showing Mission Complete UI")
	if not mission_complete_container:
		return
	is_mission_complete_state = true
	mission_complete_container.visible = true
	if ui.next_step_button:
		ui.next_step_button.visible = false
	var lang = "en"
	if GameState:
		lang = GameState.current_language
	if lang == "zh":
		mission_complete_label.text = "任務完成"
	else:
		mission_complete_label.text = "Mission Complete"
	if _mission_complete_tween:
		_mission_complete_tween.kill()
	_mission_complete_tween = create_tween()
	_mission_complete_tween.tween_method(
		func(val): _update_countdown_label(val, lang),
		duration,
		0.0,
		duration
	)
func _update_countdown_label(time_left: float, lang: String) -> void:
	if not mission_complete_timer_label:
		return
	var seconds = ceil(time_left)
	if lang == "zh":
		mission_complete_timer_label.text = "夜間模式準備中... %d秒" % seconds
	else:
		mission_complete_timer_label.text = "Night Cycle approaching... %ds" % seconds
func hide_mission_complete_countdown() -> void:
	is_mission_complete_state = false
	if mission_complete_container:
		mission_complete_container.visible = false
	if _mission_complete_tween:
		_mission_complete_tween.kill()
		_mission_complete_tween = null
func _subscribe_to_coordination_events() -> void:
	print("[StoryScene] Subscribing to coordination events...")
	EventBus.subscribe("pause_requested", self, "_on_pause_requested")
	EventBus.subscribe("settings_menu_requested", self, "_on_settings_requested")
	EventBus.subscribe("journal_requested", self, "_on_journal_requested")
	EventBus.subscribe("return_to_menu_requested", self, "_on_return_to_menu_requested")
	EventBus.subscribe("butterfly_effects_requested", self, "_on_butterfly_requested")
	EventBus.subscribe("choice_selected", self, "_on_choice_selected_event")
	EventBus.subscribe("show_choice_options_requested", self, "_on_show_options")
	EventBus.subscribe("next_step_requested", self, "_on_next_step")
	EventBus.subscribe("show_loading_overlay", self, "_show_loading")
	EventBus.subscribe("hide_loading_overlay", self, "_hide_loading")
	EventBus.subscribe("ai_request_started", self, "_on_ai_request_started")
	EventBus.subscribe("ai_request_progress", self, "_on_ai_request_progress")
	EventBus.subscribe("start_mission", self, "_on_start_mission_event")
	EventBus.subscribe("ai_response_received", self, "_on_ai_response_event")
	EventBus.subscribe("ai_error", self, "_on_ai_error_event")
	EventBus.subscribe("ai_retry_requested", self, "_on_ai_retry_requested")
	EventBus.subscribe("ai_use_offline_requested", self, "_on_ai_use_offline_requested")
	EventBus.subscribe("show_gloria_overlay", self, "_show_gloria_overlay")
	EventBus.subscribe("gloria_overlay_dismissed", self, "_on_gloria_dismissed")
	print("[StoryScene] ??Subscribed to EventBus")
func _initialize_scene() -> void:
	print("[StoryScene] Initializing scene...")
	_apply_visual_styles()
	if ui and ui.has_enhanced_scene():
		pass
	UIStyleManager.fade_in(self, 1.0)
	if ui and ui.story_text:
		ui.story_text.text = _get_welcome_message()
	var start_context = "game_start"
	var mission_id = 1
	if GameState:
		if GameState.just_loaded_from_save:
			start_context = "game_resume"
			mission_id = GameState.current_mission
			GameState.just_loaded_from_save = false 
			print("[StoryScene] Resuming game from SAVE (mission %d)" % mission_id)
		elif GameState.current_mission > 0:
			start_context = "game_resume"
			mission_id = GameState.current_mission
			print("[StoryScene] Resuming game from STATE (mission %d)" % mission_id)
		else:
			print("[StoryScene] Starting NEW game (mission 1)")
			mission_id = 1
	EventBus.publish(
		"start_mission",
		{
			"mission_id": mission_id,
			"context": start_context,
		},
	)
	if choice_controller and start_context != "game_resume":
		choice_controller.generate_choices()
	print("[StoryScene] 🚀Scene initialized, first mission starting")
func _setup_mission_info_display() -> void:
	if not ui or not ui.stats_panel:
		return
	var hbox = ui.stats_panel.get_node_or_null("MarginContainer/HBoxContainer")
	if not hbox:
		return
	var label = Label.new()
	label.name = "MissionInfoLabel"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 4) 
	margin.add_child(label)
	var menu_buttons = hbox.get_node_or_null("MenuButtons")
	var idx = 1
	if menu_buttons:
		idx = menu_buttons.get_index() + 1
	hbox.add_child(margin)
	hbox.move_child(margin, idx)
	ui.mission_info_label = label
	_update_mission_info()
func _update_mission_info() -> void:
	if not ui or not ui.mission_info_label:
		return
	if not GameState:
		return
	var title = GameState.current_mission_title
	if title.length() > 20:
		title = title.substr(0, 18) + "..."
	if title.is_empty():
		title = "Mission %d" % GameState.current_mission
	var lang = GameState.current_language
	if lang == "zh":
		ui.mission_info_label.text = "第 %d 章：%s | 回合 %d" % [GameState.current_mission, title, GameState.mission_turn_count]
	else:
		ui.mission_info_label.text = "Mission %d: %s | Turn %d" % [GameState.current_mission, title, GameState.mission_turn_count]
func _apply_visual_styles() -> void:
	var all_buttons = ui.get_all_buttons()
	for button in all_buttons:
		if not button: continue
		UIStyleManager.apply_button_style(button, "primary", "medium")
		UIStyleManager.add_hover_scale_effect(button)
		UIStyleManager.add_press_feedback(button)
	if ui.pause_button:
		UIStyleManager.apply_button_style(ui.pause_button, "primary", "medium")
		ui.pause_button.icon = ICON_PAUSE
		ui.pause_button.text = ""
		ui.pause_button.expand_icon = true
	if ui.settings_button:
		UIStyleManager.apply_button_style(ui.settings_button, "primary", "medium")
		ui.settings_button.icon = ICON_SETTINGS
		ui.settings_button.text = ""
		ui.settings_button.expand_icon = true
	if ui.journal_button:
		UIStyleManager.apply_button_style(ui.journal_button, "primary", "medium")
		ui.journal_button.icon = ICON_JOURNAL
		ui.journal_button.text = ""
		ui.journal_button.expand_icon = true
	if ui.butterfly_button:
		UIStyleManager.apply_button_style(ui.butterfly_button, "accent", "medium")
	if ui.show_options_button:
		UIStyleManager.apply_button_style(ui.show_options_button, "success", "large")
		ui.show_options_button.icon = ICON_OPTIONS
		ui.show_options_button.text = "Show Options"
		ui.show_options_button.expand_icon = true
	if ui.next_step_button:
		UIStyleManager.apply_button_style(ui.next_step_button, "success", "large")
		ui.next_step_button.icon = ICON_NEXT
		ui.next_step_button.text = "Next Step"
		ui.next_step_button.expand_icon = true
		ui.next_step_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		UIStyleManager.pulse_effect(ui.next_step_button, 0.05, 2.0) 
	if ui.stats_panel:
		UIStyleManager.apply_panel_style(ui.stats_panel, 0.95, 0) 
	if ui.assets_panel:
		UIStyleManager.apply_panel_style(ui.assets_panel)
	if FontManager:
		for button in all_buttons:
			if button:
				var font_size = FontManager.get_font_size()
				if font_size > 0:
					button.add_theme_font_size_override("font_size", font_size)
	if ui and ui.background_deco:
		ui.background_deco.color = Color(0.1, 0.1, 0.15, 0.8)
func _get_welcome_message() -> String:
	var msg = "[center][b]Glorious Deliverance Agency 1[/b][/center]\n\n"
	msg += "Welcome to your first day at the agency.\n\n"
	msg += "Your mission: Save the world with [color=yellow]positive energy[/color].\n"
	msg += "But be warned... toxic positivity has consequences.\n\n"
	msg += "[i]Reality Score[/i] drops to 0? Game over.\n"
	msg += "[i]Entropy[/i] rises too high? Catastrophe.\n\n"
	msg += "Choose wisely. Or don't. Gloria is watching.\n\n"
	msg += "[color=#ffcc66]Click the [b]NEXT STEP ►[/b] button in the bottom right corner to begin.[/color]"
	return msg
func _on_pause_requested(_data: Dictionary) -> void:
	print("[StoryScene] Pause requested")
	if overlay_controller:
		overlay_controller.open_pause_menu()
func _on_settings_requested(_data: Dictionary) -> void:
	print("[StoryScene] Settings requested")
	if overlay_controller:
		overlay_controller.open_settings_menu()
func _on_journal_requested(_data: Dictionary) -> void:
	print("[StoryScene] Journal requested")
	if overlay_controller:
		overlay_controller.open_journal_panel()
func _on_butterfly_requested(_data: Dictionary) -> void:
	print("[StoryScene] Butterfly effects requested")
	var scene: PackedScene = load("res://1.Codebase/src/scenes/ui/butterfly_effect_panel.tscn")
	if scene:
		var overlay: Control = scene.instantiate()
		add_child(overlay)
		var butterfly_data: Array = []
		if GameState and GameState.butterfly_tracker:
			butterfly_data = GameState.butterfly_tracker.recorded_choices
		if overlay.has_method("setup"):
			overlay.setup(butterfly_data)
		if overlay.has_signal("close_requested"):
			overlay.connect("close_requested", Callable(overlay, "queue_free"))
	else:
		EventBus.publish(
			"show_notification",
			{
				"message": "Butterfly effect UI missing",
				"type": "error",
			},
		)
func _on_return_to_menu_requested(data: Dictionary) -> void:
	var should_confirm = data.get("confirm", true)
	if should_confirm:
		if _exit_confirmation_dialog:
			_exit_confirmation_dialog.popup_centered()
			print("[StoryScene] Showing exit confirmation dialog")
		else:
			ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Exit confirmation dialog not available, exiting directly")
			_perform_exit_to_menu()
	else:
		_perform_exit_to_menu()
func _on_exit_confirmed() -> void:
	print("[StoryScene] Exit confirmed by user")
	_perform_exit_to_menu()
func _perform_exit_to_menu() -> void:
	if GameState:
		GameState.is_session_active = false
		GameState.autosave()
	get_tree().change_scene_to_file("res://1.Codebase/menu_main.tscn")
func _on_choice_selected_event(data: Dictionary) -> void:
	var choice_index = data.get("choice_index", -1)
	print("[StoryScene] Choice selected: %d" % choice_index)
	if choice_controller:
		choice_controller.process_choice(choice_index)
func _on_show_options(_data: Dictionary) -> void:
	print("[StoryScene] Show options overlay requested")
	if ui and ui.choices_container:
		ui.choices_container.visible = true
func _on_next_step(_data: Dictionary) -> void:
	print("[StoryScene] Next step requested")
	if is_mission_complete_state:
		print("[StoryScene] Next step ignored - mission complete")
		return
	if not choice_controller:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Choice controller not initialized; cannot open choices")
		return
	if choice_controller.current_choices.is_empty():
		choice_controller.generate_choices()
	_open_choice_selection_overlay()
func _on_ai_response_event(data: Dictionary) -> void:
	print("[StoryScene] AI response received")
	awaiting_ai_response = false
	var response_type = data.get("type", "unknown")
	if response_type == "unknown":
		if ui and ui.ai_error_overlay and ui.ai_error_overlay.visible:
			print("[StoryScene] Keeping error overlay visible for unknown response")
			_hide_loading({ }) 
			return
	_hide_loading({ })
	hide_ai_error_overlay()
	print("[StoryScene] Response type: %s" % response_type)
	_is_mock_override_active = false
	_set_global_mock_override(false, "story_scene_response")
	_update_mission_info()
	_log_turn_stats()
func _on_ai_error_event(data: Dictionary) -> void:
	if not should_process_ai_event(data):
		return
	var message = data.get("message", "Unknown error")
	print("[StoryScene] AI error: %s" % message)
	awaiting_ai_response = false
	_hide_loading({ })
	_is_mock_override_active = false
	_set_global_mock_override(false, "story_scene_response")
	var lang: String = LocalizationManager.get_language()
	var is_rate_limited := _is_rate_limit_error(data, message)
	var title_key := "STORY_AI_RATE_LIMIT_TITLE" if is_rate_limited else "STORY_AI_UNAVAILABLE_TITLE"
	var message_key := "STORY_AI_RATE_LIMIT_DESC" if is_rate_limited else "STORY_AI_UNAVAILABLE_DESC"
	var title := LocalizationManager.get_translation(title_key, lang)
	var overlay_message := LocalizationManager.get_translation(message_key, lang)
	var details := String(message)
	var provider_name := String(data.get("provider", ""))
	if not provider_name.is_empty():
		details = "%s (provider: %s)" % [details, provider_name]
	var offline_enabled := _should_offer_offline_retry() or is_rate_limited
	show_ai_error_overlay(title, overlay_message, details, offline_enabled)
	EventBus.publish(
		"show_notification",
		{
			"message": "AI Error: %s" % message,
			"type": "error",
			"duration": 5.0,
		},
	)
func _on_start_mission_event(data: Dictionary) -> void:
	var mission_id: int = int(data.get("mission_id", 0))
	var context: String = String(data.get("context", "unknown"))
	print("[StoryScene] Start mission event received (mission_id=%d, context=%s)" % [mission_id, context])
	if flow_controller:
		if context == "game_resume":
			flow_controller.resume_current_mission()
		else:
			flow_controller.start_new_mission()
	else:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Flow controller not initialized; cannot start mission")
	_update_mission_info()
func _on_ai_request_started(_data: Dictionary) -> void:
	if not should_process_ai_event(_data):
		return
	hide_ai_error_overlay()
	_ensure_loading_overlay_visible()
	_last_progress_timestamp = Time.get_ticks_msec() / 1000.0
	_progress_updates_seen = 0
	_progress_lag_logged = false
	print("[StoryScene][Loading] AI request started")
func _on_ai_request_progress(data: Dictionary) -> void:
	if not should_process_ai_event(data):
		return
	_ensure_loading_overlay_visible()
	var percent: float = float(data.get("progress", data.get("percent", 0.0)))
	if percent > 1.0:
		percent /= 100.0
	percent = clamp(percent, 0.0, 1.0)
	_last_progress_timestamp = Time.get_ticks_msec() / 1000.0
	_progress_updates_seen += 1
	_progress_lag_logged = false
	print(
		"[StoryScene][Loading] Progress update #%d | stage=%s | percent=%.1f | message=%s" % [
			_progress_updates_seen,
			String(data.get("stage", data.get("status", "processing"))),
			percent * 100.0,
			String(data.get("message", data.get("status", ""))),
		],
	)
	var progress_info: Dictionary = {
		"stage": data.get("stage", data.get("status", "processing")),
		"message": data.get("message", data.get("status", "")),
		"percent": percent,
		"model": data.get("model", ""),
	}
	if ui_controller:
		ui_controller.update_loading_progress(progress_info)
	else:
		var lang: String = "en"
		if GameState != null:
			lang = String(GameState.current_language)
		var text: String = LoadingDisplay.get_progress_display_text(progress_info, lang)
		if ui.loading_label:
			ui.loading_label.text = text
		if ui.loading_sublabel:
			if percent > 0.0:
				ui.loading_sublabel.text = "%.0f%%" % (percent * 100.0)
			else:
				ui.loading_sublabel.text = ""
func _show_gloria_overlay(data: Dictionary) -> void:
	print("[StoryScene] Showing Gloria overlay")
	if overlay_controller:
		var message = data.get("message", "")
		overlay_controller.show_gloria_overlay(message)
func _on_gloria_dismissed(_data: Dictionary) -> void:
	print("[StoryScene] Gloria overlay dismissed")
	if flow_controller:
		flow_controller.resume_after_gloria()
func _ensure_loading_overlay_visible() -> void:
	if not ui or not ui.loading_overlay:
		return
	if ui_controller:
		if not ui.loading_overlay.visible:
			ui_controller.show_loading(true, _last_loading_context)
		var base_progress: Dictionary = {
			"stage": "starting",
			"message": _last_loading_message,
			"percent": 0.0,
		}
		ui_controller.update_loading_progress(base_progress)
	else:
		if not ui.loading_overlay.visible:
			ui.loading_overlay.visible = true
		if ui.loading_label:
			ui.loading_label.text = _last_loading_message
	awaiting_ai_response = true
	if _last_progress_timestamp == 0.0:
		_last_progress_timestamp = Time.get_ticks_msec() / 1000.0
	print("[StoryScene][Loading] Overlay ensured (context=%s, message=%s)" % [_last_loading_context, _last_loading_message])
func _show_loading(data: Dictionary) -> void:
	if not ui or not ui.loading_overlay:
		return
	hide_ai_error_overlay()
	var message: String = String(data.get("message", "Loading..."))
	var context: String = String(data.get("context", "default"))
	_last_loading_message = message
	_last_loading_context = context
	_last_progress_timestamp = Time.get_ticks_msec() / 1000.0
	_progress_updates_seen = 0
	_progress_lag_logged = false
	print("[StoryScene][Loading] Show requested (context=%s, message=%s)" % [context, message])
	if ui_controller:
		ui_controller.show_loading(true, context)
		if not message.is_empty():
			var progress_info: Dictionary = {
				"stage": "starting",
				"message": message,
				"percent": 0.0,
			}
			ui_controller.update_loading_progress(progress_info)
	else:
		ui.loading_overlay.visible = true
		if ui.loading_label:
			ui.loading_label.text = message
		if ui.loading_sublabel:
			ui.loading_sublabel.text = ""
	awaiting_ai_response = true
func _hide_loading(_data: Dictionary) -> void:
	awaiting_ai_response = false
	_last_progress_timestamp = 0.0
	_progress_updates_seen = 0
	_progress_lag_logged = false
	if not ui or not ui.loading_overlay:
		return
	if ui_controller:
		ui_controller.show_loading(false)
	else:
		ui.loading_overlay.visible = false
	print("[StoryScene][Loading] Overlay hidden")
func _log_turn_stats() -> void:
	if not EventBus:
		return
	var stats_variant: Variant = EventBus.request("get_all_stats")
	if not (stats_variant is Dictionary):
		return
	var stats: Dictionary = stats_variant
	var negative_energy: int = int(stats.get("positive_energy", 0))
	var reality_score: int = int(stats.get("reality_score", 0))
	var entropy_level: int = int(stats.get("entropy_level", 0))
	var turn_label := "Turn %d" % (GameState.mission_turn_count if GameState else 0)
	print(
		"[StoryScene][TurnStats] %s | 負能量值=%d | 現實值=%d | 熵值=%d" % [
			turn_label,
			negative_energy,
			reality_score,
			entropy_level,
		],
	)
func _cleanup() -> void:
	_set_global_mock_override(false, "story_scene_cleanup")
	var tree := get_tree()
	if tree:
		tree.paused = false
	EventBus.unsubscribe_all(self)
	if ServiceLocator:
		ServiceLocator.unregister_service("StoryFlowController")
	if stat_display:
		stat_display.unsubscribe()
	if event_handlers:
		event_handlers.disconnect_all()
	if _exit_confirmation_dialog:
		if _exit_confirmation_dialog.confirmed.is_connected(_on_exit_confirmed):
			_exit_confirmation_dialog.confirmed.disconnect(_on_exit_confirmed)
		_exit_confirmation_dialog.queue_free()
		_exit_confirmation_dialog = null
	if _mission_complete_tween:
		_mission_complete_tween.kill()
	print("[StoryScene] Cleanup complete")
func is_initialized() -> bool:
	return _is_initialized
func get_ui_bindings() -> StorySceneUIBindings:
	return ui
func get_event_handlers() -> StorySceneEventHandlers:
	return event_handlers
func get_stat_display() -> StorySceneStatDisplay:
	return stat_display
func update_stats_display() -> void:
	pass
func update_asset_display() -> void:
	if asset_controller:
		asset_controller.update_asset_display()
	else:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Asset controller not initialized; cannot update asset display")
func apply_scene_directives(directives: Dictionary) -> void:
	if directives.is_empty():
		return
	print("[StoryScene] Applying scene directives:", directives.keys())
	var scene_data: Variant = directives.get("scene")
	if scene_data is Dictionary:
		_apply_scene_settings(scene_data)
	elif scene_data != null:
		_report_directive_issue(
			"scene",
			"Scene directives must be a dictionary",
			{ "scene": scene_data },
		)
	var characters_data: Variant = directives.get("characters")
	if characters_data is Dictionary:
		_apply_character_directives(characters_data)
	elif characters_data != null:
		_report_directive_issue(
			"characters",
			"Character directives must be a dictionary",
			{ "characters": characters_data },
		)
	var assets_data: Variant = directives.get("assets")
	if assets_data is Array:
		_apply_asset_directives(assets_data)
	elif assets_data != null:
		_report_directive_issue(
			"assets",
			"Asset directives must be an array",
			{ "assets": assets_data },
		)
func show_loading(message: String = "Loading...", context: String = "default") -> void:
	hide_ai_error_overlay()
	EventBus.publish(
		"show_loading_overlay",
		{
			"message": message,
			"context": context,
		},
	)
func hide_loading() -> void:
	EventBus.publish("hide_loading_overlay", { })
func show_ai_error_overlay(title: String, message: String, details: String = "", offline_enabled: bool = true) -> void:
	if ui_controller:
		ui_controller.show_ai_error_overlay(title, message, details, offline_enabled)
		return
	if not ui or not ui.ai_error_overlay:
		return
	var lang := LocalizationManager.get_language()
	var retry_text := LocalizationManager.get_translation("STORY_RETRY_BUTTON", lang)
	var offline_text := LocalizationManager.get_translation("STORY_OFFLINE_BUTTON", lang)
	var home_text := LocalizationManager.get_translation("STORY_HOME_BUTTON", lang)
	ui.ai_error_overlay.visible = true
	if ui.ai_error_title_label:
		ui.ai_error_title_label.text = title
	if ui.ai_error_message_label:
		ui.ai_error_message_label.text = message
	if ui.ai_error_details_label:
		ui.ai_error_details_label.text = details
		ui.ai_error_details_label.visible = not details.strip_edges().is_empty()
	if ui.ai_error_retry_button:
		ui.ai_error_retry_button.visible = true
		ui.ai_error_retry_button.disabled = false
		ui.ai_error_retry_button.text = retry_text
	if ui.ai_error_offline_button:
		ui.ai_error_offline_button.visible = offline_enabled
		ui.ai_error_offline_button.disabled = not offline_enabled
		ui.ai_error_offline_button.text = offline_text
	if ui.ai_error_home_button:
		ui.ai_error_home_button.visible = true
		ui.ai_error_home_button.disabled = false
		ui.ai_error_home_button.text = home_text
	if offline_enabled and ui.ai_error_offline_button:
		ui.ai_error_offline_button.grab_focus()
	elif ui.ai_error_retry_button:
		ui.ai_error_retry_button.grab_focus()
	elif ui.ai_error_home_button:
		ui.ai_error_home_button.grab_focus()
func hide_ai_error_overlay() -> void:
	if ui_controller:
		ui_controller.hide_ai_error_overlay()
	elif ui and ui.ai_error_overlay:
		ui.ai_error_overlay.visible = false
		if ui.ai_error_details_label:
			ui.ai_error_details_label.text = ""
			ui.ai_error_details_label.visible = false
		if ui.ai_error_message_label:
			ui.ai_error_message_label.text = ""
func _should_offer_offline_retry() -> bool:
	if _is_mock_override_active:
		return false
	if not narrative_controller:
		return false
	if not narrative_controller.has_retryable_request():
		return false
	return true
func _is_rate_limit_error(event_data: Dictionary, message: String) -> bool:
	var lowered_message := String(message).to_lower()
	if lowered_message.find("rate limit") != -1 or lowered_message.find("too many ai requests") != -1 or lowered_message.find("rate_limited") != -1:
		return true
	var reason := String(event_data.get("error", event_data.get("reason", ""))).to_lower()
	if reason.find("rate") != -1:
		return true
	var ctx_variant = event_data.get("context", null)
	if ctx_variant is Dictionary:
		var ctx: Dictionary = ctx_variant
		var ctx_reason := String(ctx.get("error", ctx.get("reason", ""))).to_lower()
		if ctx_reason.find("rate") != -1:
			return true
	return false
func should_process_ai_event(data: Dictionary) -> bool:
	return not _is_irrelevant_ai_event(data)
func _is_irrelevant_ai_event(data: Dictionary) -> bool:
	var purpose := _extract_purpose_from_event(data)
	if purpose.is_empty():
		return false
	return _is_irrelevant_purpose(purpose)
func _extract_purpose_from_event(data: Dictionary) -> String:
	if data.is_empty():
		return ""
	if data.has("purpose"):
		var purpose_value := String(data.get("purpose", "")).to_lower()
		if not purpose_value.is_empty():
			return purpose_value
	var ctx_variant = data.get("context", null)
	if ctx_variant is Dictionary:
		var ctx: Dictionary = ctx_variant
		return String(ctx.get("purpose", ctx.get("type", ""))).to_lower()
	return ""
func _is_irrelevant_purpose(purpose: String) -> bool:
	if purpose.is_empty():
		return false
	var lowered := purpose.to_lower()
	if STORY_IRRELEVANT_PURPOSES.has(lowered):
		return true
	for prefix in STORY_IRRELEVANT_PURPOSE_PREFIXES:
		if lowered.begins_with(prefix):
			return true
	return false
func _set_global_mock_override(enabled: bool, reason: String) -> void:
	var manager: Variant = null
	if ServiceLocator:
		if ServiceLocator.has_method("get_ai_manager"):
			manager = ServiceLocator.get_ai_manager()
		elif ServiceLocator.has_method("has_service") and ServiceLocator.has_service("AIManager"):
			manager = ServiceLocator.get_service("AIManager")
	if manager == null and Engine.has_singleton("AIManager"):
		manager = Engine.get_singleton("AIManager")
	if manager == null:
		if typeof(AIManager) != TYPE_NIL:
			manager = AIManager
	if manager == null:
		return
	if manager.has_method("set_mock_override"):
		manager.set_mock_override(enabled, reason)
func _on_ai_retry_requested(_data: Dictionary) -> void:
	if not narrative_controller:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Narrative controller not initialized; cannot retry AI request")
		var lang := LocalizationManager.get_language()
		var retry_unavailable := LocalizationManager.get_translation("STORY_RETRY_UNAVAILABLE", lang)
		show_ai_error_overlay(
			LocalizationManager.get_translation("STORY_AI_UNAVAILABLE_TITLE", lang),
			retry_unavailable,
			"",
			false,
		)
		return
	hide_ai_error_overlay()
	_set_global_mock_override(false, "story_scene_retry_button")
	if narrative_controller.retry_last_request():
		awaiting_ai_response = true
	else:
		var lang := LocalizationManager.get_language()
		var fail_message := LocalizationManager.get_translation("STORY_RETRY_FAILED", lang)
		show_ai_error_overlay(
			LocalizationManager.get_translation("STORY_AI_UNAVAILABLE_TITLE", lang),
			fail_message,
			"",
			_should_offer_offline_retry(),
		)
func _on_ai_use_offline_requested(_data: Dictionary) -> void:
	if not narrative_controller:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Narrative controller not initialized; cannot switch to offline mock")
		var lang := LocalizationManager.get_language()
		var unavailable := LocalizationManager.get_translation("STORY_OFFLINE_UNAVAILABLE", lang)
		show_ai_error_overlay(
			LocalizationManager.get_translation("STORY_AI_UNAVAILABLE_TITLE", lang),
			unavailable,
			"",
			false,
		)
		return
	hide_ai_error_overlay()
	var started_offline := narrative_controller.retry_last_request(true)
	_is_mock_override_active = started_offline
	if started_offline:
		_set_global_mock_override(true, "story_scene_offline_button")
		awaiting_ai_response = true
	else:
		var lang := LocalizationManager.get_language()
		var fail_message := LocalizationManager.get_translation("STORY_OVERLAY_OFFLINE_FAILED", lang)
		show_ai_error_overlay(
			LocalizationManager.get_translation("STORY_AI_UNAVAILABLE_TITLE", lang),
			fail_message,
			"",
			_should_offer_offline_retry(),
		)
func _apply_scene_settings(scene_data: Dictionary) -> void:
	if not ui:
		return
	if ui.dynamic_background and BackgroundLoader:
		var bg_id := String(scene_data.get("background", "")).strip_edges()
		if not bg_id.is_empty():
			var texture: Texture2D = BackgroundLoader.get_background_texture(bg_id)
			if texture:
				ui.dynamic_background.texture = texture
			else:
				_report_directive_issue(
					"background",
					"Unknown background id",
					{
						"background": bg_id,
						"scene": scene_data.duplicate(true),
					},
				)
	if ui.atmosphere_overlay:
		var atmosphere := String(scene_data.get("atmosphere", ""))
		var lighting := String(scene_data.get("lighting", ""))
		ui.atmosphere_overlay.color = _get_atmosphere_overlay_color(atmosphere, lighting)
func _apply_character_directives(characters_data: Dictionary) -> void:
	if not ui:
		return
	if ui.character_sprites.is_empty() and ui.character_containers.is_empty():
		_report_directive_issue(
			"character_layout",
			"No character slots available in UI bindings",
			{ "characters": characters_data.keys() },
		)
		return
	var active_ids: Dictionary = { }
	for raw_id in characters_data.keys():
		var entry_variant: Variant = characters_data[raw_id]
		if not (entry_variant is Dictionary):
			_report_directive_issue(
				"character_entry",
				"Character directive payload is not a dictionary",
				{
					"character": raw_id,
					"value": entry_variant,
				},
			)
			continue
		var canonical_id := _resolve_character_id(String(raw_id))
		if canonical_id == "":
			canonical_id = String(raw_id).to_lower()
		active_ids[canonical_id] = true
		var char_data: Dictionary = entry_variant
		var expression := String(char_data.get("expression", "neutral"))
		var sprite: TextureRect = ui.character_sprites.get(canonical_id, null)
		var container: Control = ui.character_containers.get(canonical_id, null)
		var name_label: Label = ui.character_name_labels.get(canonical_id, null)
		if sprite == null:
			_report_directive_issue(
				"character_slot",
				"No sprite slot available for character",
				{
					"raw_character": raw_id,
					"resolved_character": canonical_id,
					"known_characters": ui.character_sprites.keys(),
					"directive": char_data.duplicate(true),
				},
			)
			if container:
				container.visible = false
			continue
		if container:
			container.visible = true
		if sprite:
			var texture: Texture2D = null
			if CharacterExpressionLoader:
				texture = CharacterExpressionLoader.get_character_texture(canonical_id, expression)
			if texture:
				sprite.texture = texture
				sprite.visible = true
				sprite.modulate = Color(1, 1, 1, 1)
			elif CharacterExpressionLoader:
				_report_directive_issue(
					"character_expression",
					"Unknown character or expression; texture missing",
					{
						"raw_character": raw_id,
						"resolved_character": canonical_id,
						"expression": expression,
						"directive": char_data.duplicate(true),
					},
				)
			else:
				sprite.visible = true
				sprite.modulate = Color(1, 1, 1, 1)
		if name_label and CharacterExpressionLoader:
			var use_chinese := GameState != null and GameState.current_language == "zh"
			var display_name := CharacterExpressionLoader.get_character_name(canonical_id, use_chinese)
			if not display_name.is_empty():
				name_label.text = display_name
	for canonical_id in ui.character_containers.keys():
		if active_ids.has(canonical_id):
			continue
		var container: Control = ui.character_containers[canonical_id]
		if container:
			container.visible = false
	for canonical_id in ui.character_sprites.keys():
		if active_ids.has(canonical_id):
			continue
		var sprite: TextureRect = ui.character_sprites[canonical_id]
		if sprite:
			sprite.visible = false
func _apply_asset_directives(assets_data: Array) -> void:
	if assets_data.is_empty():
		return
	if not asset_controller:
		return
	var npc_entries: Array = []
	for entry in assets_data:
		if not (entry is Dictionary):
			continue
		var entry_dict: Dictionary = entry
		var has_character := entry_dict.has("character_id") or entry_dict.has("npc_id")
		if has_character:
			npc_entries.append(entry_dict)
	if not npc_entries.is_empty() and asset_controller.has_method("display_npc_entries"):
		asset_controller.display_npc_entries(npc_entries)
	if asset_controller.has_method("update_assets_from_directives"):
		asset_controller.update_assets_from_directives(assets_data)
	else:
		asset_controller.update_asset_display()
func _get_atmosphere_overlay_color(atmosphere: String, lighting: String) -> Color:
	var atmosphere_lc := atmosphere.to_lower()
	var lighting_lc := lighting.to_lower()
	if lighting_lc.find("bright") != -1 or atmosphere_lc.find("warm") != -1:
		return Color(1, 1, 1, 0.12)
	if lighting_lc.find("dim") != -1 or lighting_lc.find("dark") != -1:
		return Color(0, 0, 0, 0.45)
	if atmosphere_lc.find("oppressive") != -1 or atmosphere_lc.find("heavy") != -1:
		return Color(0, 0, 0, 0.4)
	if atmosphere_lc.find("electric") != -1:
		return Color(0.2, 0.4, 0.8, 0.25)
	return Color(0, 0, 0, 0.25)
func _resolve_character_id(raw_id: String) -> String:
	if CharacterExpressionLoader:
		var resolved := CharacterExpressionLoader.get_canonical_id(raw_id)
		if resolved != "":
			return resolved
	return raw_id.to_lower()
func _open_choice_selection_overlay() -> void:
	if not ui:
		return
	if not ui.choice_selection_overlay_scene:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Choice selection overlay scene missing")
		return
	if ui.next_step_button:
		ui.next_step_button.visible = false
	var overlay_instance: Control = ui.choice_selection_overlay_scene.instantiate()
	add_child(overlay_instance)
	if overlay_instance.has_signal("choice_selected"):
		overlay_instance.choice_selected.connect(_on_overlay_choice_selected)
	if overlay_instance.has_signal("overlay_closed"):
		overlay_instance.overlay_closed.connect(_on_overlay_closed)
	var choices: Array = []
	if choice_controller:
		choices = choice_controller.current_choices.duplicate(true)
	if overlay_instance.has_method("setup_choices"):
		overlay_instance.setup_choices(choices)
func _on_overlay_choice_selected(choice_index: int) -> void:
	if choice_controller:
		choice_controller.on_choice_selected(choice_index)
func _on_overlay_closed() -> void:
	if ui and ui.next_step_button:
		ui.next_step_button.visible = not is_mission_complete_state
func _report_error(message: String, details: Dictionary = { }) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func _report_directive_issue(component: String, reason: String, payload) -> void:
	var snippet := _directive_payload_to_snippet(payload)
	var details := {
		"component": component,
		"reason": reason,
		"ai_payload_snippet": snippet,
	}
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Invalid AI scene directive", details)
	print("[StoryScene][DirectiveError] %s | %s | %s" % [component, reason, snippet])
func _directive_payload_to_snippet(payload) -> String:
	var snippet := ""
	if payload is Dictionary or payload is Array:
		snippet = JSON.stringify(payload)
		if snippet.is_empty():
			snippet = var_to_str(payload)
	else:
		snippet = str(payload)
	if snippet.length() > DIRECTIVE_SNIPPET_LIMIT:
		snippet = snippet.substr(0, DIRECTIVE_SNIPPET_LIMIT) + "..."
	return snippet
