class_name StorySceneEventHandlers
extends RefCounted
var ui: StorySceneUIBindings
var scene: Control
const ERROR_CONTEXT := "StorySceneEventHandlers"
var _subscribed_to_eventbus := false
func _init(p_ui: StorySceneUIBindings, p_scene: Control):
	ui = p_ui
	scene = p_scene
func connect_all_signals() -> void:
	if not ui or not scene:
		_report_error("Cannot connect signals without UI and scene")
		return
	_connect_button_signals()
	_subscribe_to_eventbus_events()
func _connect_button_signals() -> void:
	if ui.pause_button and not ui.pause_button.pressed.is_connected(_on_pause_button_pressed):
		ui.pause_button.pressed.connect(_on_pause_button_pressed)
	if ui.settings_button and not ui.settings_button.pressed.is_connected(_on_settings_button_pressed):
		ui.settings_button.pressed.connect(_on_settings_button_pressed)
	if ui.journal_button and not ui.journal_button.pressed.is_connected(_on_journal_button_pressed):
		ui.journal_button.pressed.connect(_on_journal_button_pressed)
	if ui.butterfly_button and not ui.butterfly_button.pressed.is_connected(_on_butterfly_button_pressed):
		ui.butterfly_button.pressed.connect(_on_butterfly_button_pressed)
	for i in range(ui.choice_buttons.size()):
		var button = ui.choice_buttons[i]
		if button and not button.pressed.is_connected(_on_choice_button_pressed.bind(i)):
			button.pressed.connect(_on_choice_button_pressed.bind(i))
	if ui.show_options_button and not ui.show_options_button.pressed.is_connected(_on_show_options_pressed):
		ui.show_options_button.pressed.connect(_on_show_options_pressed)
	if ui.next_step_button and not ui.next_step_button.pressed.is_connected(_on_next_step_pressed):
		ui.next_step_button.pressed.connect(_on_next_step_pressed)
	if ui.voice_input_button and not ui.voice_input_button.pressed.is_connected(_on_voice_input_pressed):
		ui.voice_input_button.pressed.connect(_on_voice_input_pressed)
	if ui.ai_error_offline_button and not ui.ai_error_offline_button.pressed.is_connected(_on_ai_error_offline_pressed):
		ui.ai_error_offline_button.pressed.connect(_on_ai_error_offline_pressed)
	if ui.ai_error_retry_button and not ui.ai_error_retry_button.pressed.is_connected(_on_ai_error_retry_pressed):
		ui.ai_error_retry_button.pressed.connect(_on_ai_error_retry_pressed)
	if ui.ai_error_home_button and not ui.ai_error_home_button.pressed.is_connected(_on_ai_error_home_pressed):
		ui.ai_error_home_button.pressed.connect(_on_ai_error_home_pressed)
	print("[EventHandlers] All button signals connected")
func _subscribe_to_eventbus_events() -> void:
	if _subscribed_to_eventbus:
		return
	EventBus.subscribe("ai_error", self, "_on_ai_error")
	EventBus.subscribe("ai_request_progress", self, "_on_ai_progress")
	EventBus.subscribe("ai_response_received", self, "_on_ai_response")
	EventBus.subscribe("mission_generated", self, "_on_mission_generated")
	EventBus.subscribe("consequence_generated", self, "_on_consequence_generated")
	EventBus.subscribe("trolley_problem_generated", self, "_on_trolley_problem_generated")
	EventBus.subscribe("teammate_interference", self, "_on_teammate_interference")
	EventBus.subscribe("gloria_intervention", self, "_on_gloria_intervention")
	EventBus.subscribe("prayer_completed", self, "_on_prayer_completed")
	EventBus.subscribe("prayer_cancelled", self, "_on_prayer_cancelled")
	EventBus.subscribe("night_overlay_prayer_requested", self, "_on_night_prayer_requested")
	EventBus.subscribe("voice_transcription_ready", self, "_on_voice_transcription")
	_subscribed_to_eventbus = true
	print("[EventHandlers] Subscribed to EventBus events")
func disconnect_all() -> void:
	EventBus.unsubscribe_all(self)
	_subscribed_to_eventbus = false
func _report_error(message: String, details: Dictionary = { }) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func _on_pause_button_pressed() -> void:
	EventBus.publish(
		"pause_requested",
		{
			"timestamp": Time.get_ticks_msec(),
		},
	)
	print("[EventHandlers] Pause requested")
func _on_settings_button_pressed() -> void:
	EventBus.publish(
		"settings_menu_requested",
		{
			"context": "story_scene",
			"timestamp": Time.get_ticks_msec(),
		},
	)
	print("[EventHandlers] Settings menu requested")
func _on_journal_button_pressed() -> void:
	EventBus.publish(
		"journal_requested",
		{
			"context": "story_scene",
			"timestamp": Time.get_ticks_msec(),
		},
	)
	print("[EventHandlers] Journal requested")
func _on_butterfly_button_pressed() -> void:
	EventBus.publish(
		"butterfly_effects_requested",
		{
			"timestamp": Time.get_ticks_msec(),
		},
	)
	print("[EventHandlers] Butterfly effects requested")
func _on_choice_button_pressed(choice_index: int) -> void:
	EventBus.publish(
		"choice_selected",
		{
			"choice_index": choice_index,
			"timestamp": Time.get_ticks_msec(),
		},
	)
	print("[EventHandlers] Choice selected: %d" % choice_index)
func _on_show_options_pressed() -> void:
	EventBus.publish(
		"show_choice_options_requested",
		{
			"timestamp": Time.get_ticks_msec(),
		},
	)
	print("[EventHandlers] Show options requested")
func _on_next_step_pressed() -> void:
	EventBus.publish(
		"next_step_requested",
		{
			"timestamp": Time.get_ticks_msec(),
		},
	)
	print("[EventHandlers] Next step requested")
func _on_voice_input_pressed() -> void:
	EventBus.publish(
		"voice_input_requested",
		{
			"timestamp": Time.get_ticks_msec(),
		},
	)
	print("[EventHandlers] Voice input requested")
func _on_ai_error_retry_pressed() -> void:
	EventBus.publish(
		"ai_retry_requested",
		{
			"timestamp": Time.get_ticks_msec(),
			"source": "ai_error_overlay",
		},
	)
	print("[EventHandlers] AI retry requested")
func _on_ai_error_offline_pressed() -> void:
	EventBus.publish(
		"ai_use_offline_requested",
		{
			"timestamp": Time.get_ticks_msec(),
			"source": "ai_error_overlay",
		},
	)
	print("[EventHandlers] Offline mock mode requested")
func _on_ai_error_home_pressed() -> void:
	EventBus.publish(
		"return_to_menu_requested",
		{
			"confirm": true,
			"timestamp": Time.get_ticks_msec(),
			"source": "ai_error_overlay",
		},
	)
	print("[EventHandlers] Return to menu requested from AI error overlay")
func _on_ai_error(data: Dictionary) -> void:
	if scene and scene.has_method("should_process_ai_event") and not scene.should_process_ai_event(data):
		return
	var message = data.get("message", "Unknown AI error")
	print("[EventHandlers] AI error: %s" % message)
	EventBus.publish(
		"show_notification",
		{
			"message": message,
			"type": "error",
			"duration": 5.0,
		},
	)
func _on_ai_progress(data: Dictionary) -> void:
	if scene and scene.has_method("should_process_ai_event") and not scene.should_process_ai_event(data):
		return
	var status = data.get("status", "")
	var progress = data.get("progress", 0.0)
	print("[EventHandlers] AI progress: %s (%.1f%%)" % [status, progress * 100])
	if ui.loading_overlay and ui.loading_overlay.visible:
		EventBus.publish(
			"update_loading_display",
			{
				"status": status,
				"progress": progress,
			},
		)
func _on_ai_response(data: Dictionary) -> void:
	var response_type := String(data.get("type", "unknown"))
	if response_type.is_empty() or response_type == "unknown":
		response_type = _infer_response_type(data)
	print("[EventHandlers] AI response received: %s" % response_type)
	match response_type:
		"mission":
			_on_mission_generated(data)
		"consequence":
			_on_consequence_generated(data)
		"gloria_intervention":
			_on_gloria_intervention(data)
		"teammate_interference":
			_on_teammate_interference(data)
		"prayer_consequence":
			_on_consequence_generated(data)
		"trolley_problem":
			_on_trolley_problem_generated(data)
func _on_mission_generated(data: Dictionary) -> void:
	print("[EventHandlers] Mission generated")
	EventBus.publish("hide_loading_overlay", { })
func _on_consequence_generated(data: Dictionary) -> void:
	print("[EventHandlers] Consequence generated")
	EventBus.publish("hide_loading_overlay", { })
func _on_generate_prayer_consequence(data: Dictionary) -> void:
	print("[EventHandlers] Generate prayer consequence requested")
	if scene and scene.narrative_controller:
		scene.narrative_controller.handle_prayer_consequence(data)
func _on_trolley_problem_generated(data: Dictionary) -> void:
	print("[EventHandlers] Trolley problem generated")
	var dilemma = data.get("dilemma", { })
	EventBus.publish(
		"display_trolley_problem",
		{
			"dilemma": dilemma,
		},
	)
func _on_teammate_interference(data: Dictionary) -> void:
	print("[EventHandlers] Teammate interference")
	EventBus.publish("hide_loading_overlay", { })
func _on_gloria_intervention(data: Dictionary) -> void:
	print("[EventHandlers] Gloria intervention triggered")
	var content = data.get("content", "")
	if content.is_empty():
		content = "Gloria glares at you..."
	EventBus.publish("show_gloria_overlay", { "message": content })
func _on_prayer_completed(data: Dictionary) -> void:
	var result = data.get("result", { })
	print("[EventHandlers] Prayer completed: %s" % result)
	EventBus.publish(
		"generate_prayer_consequence",
		{
			"prayer_text": result.get("prayer", ""),
			"disaster": result.get("disaster", ""),
			"context": result.get("context", ""),
		},
	)
func _on_prayer_cancelled(_data: Dictionary) -> void:
	print("[EventHandlers] Prayer cancelled")
	EventBus.publish("hide_prayer_overlay", { })
func _on_night_prayer_requested(_data: Dictionary) -> void:
	print("[EventHandlers] Night cycle prayer requested")
	EventBus.publish(
		"show_prayer_overlay",
		{
			"context": "night",
		},
	)
func _on_voice_transcription(data: Dictionary) -> void:
	var text = data.get("text", "")
	print("[EventHandlers] Voice transcription: %s" % text)
	if text.is_empty():
		return
	EventBus.publish(
		"voice_text_received",
		{
			"text": text,
			"metadata": data.get("metadata", { }),
		},
	)
func _infer_response_type(data: Dictionary) -> String:
	var ctx_variant = data.get("context", null)
	if ctx_variant is Dictionary:
		var ctx: Dictionary = ctx_variant
		var purpose := String(ctx.get("purpose", ctx.get("type", ""))).to_lower()
		match purpose:
			"mission", "new_mission", "story":
				return "mission"
			"consequence":
				return "consequence"
			"teammate_interference", "interference":
				return "teammate_interference"
			"gloria_intervention":
				return "gloria_intervention"
			"prayer_consequence", "prayer_result":
				return "prayer_consequence"
	var metadata_variant = data.get("metadata", null)
	if metadata_variant is Dictionary:
		var meta: Dictionary = metadata_variant
		if meta.has("response_type"):
			return String(meta.get("response_type", "")).to_lower()
	return "unknown"
func _on_pause_resume() -> void:
	EventBus.publish("pause_resume_requested", { })
	print("[EventHandlers] Resume requested")
func _on_pause_settings() -> void:
	EventBus.publish(
		"settings_menu_requested",
		{
			"context": "pause_menu",
		},
	)
func _on_pause_journal() -> void:
	EventBus.publish(
		"journal_requested",
		{
			"context": "pause_menu",
		},
	)
func _on_pause_achievements() -> void:
	EventBus.publish(
		"achievements_requested",
		{
			"context": "pause_menu",
		},
	)
func _on_pause_home() -> void:
	EventBus.publish(
		"return_to_menu_requested",
		{
			"confirm": true, 
		},
	)
func _on_gloria_overlay_continue() -> void:
	EventBus.publish("gloria_overlay_dismissed", { })
	print("[EventHandlers] Gloria overlay dismissed")
func _on_overlay_choice_selected(choice_index: int) -> void:
	EventBus.publish(
		"overlay_choice_selected",
		{
			"choice_index": choice_index,
		},
	)
	print("[EventHandlers] Overlay choice selected: %d" % choice_index)
func _on_overlay_closed() -> void:
	EventBus.publish("choice_overlay_closed", { })
	print("[EventHandlers] Choice overlay closed")
func are_signals_connected() -> bool:
	if not ui or not ui.pause_button:
		return false
	return ui.pause_button.pressed.is_connected(_on_pause_button_pressed)
func get_event_stats() -> Dictionary:
	return {
		"subscribed_to_eventbus": _subscribed_to_eventbus,
		"button_signals_connected": are_signals_connected(),
		"ui_valid": ui != null,
		"scene_valid": scene != null,
	}
