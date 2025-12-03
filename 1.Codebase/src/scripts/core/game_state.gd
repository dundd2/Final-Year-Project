extends Node
signal reality_score_changed(new_value: int)
signal positive_energy_changed(new_value: int)
signal entropy_level_changed(new_value: int)
signal stats_changed()
signal event_logged(event: Dictionary)
const PlayerStatsScript = preload("res://1.Codebase/src/scripts/core/player_stats.gd")
const AIEventChannels = preload("res://1.Codebase/src/scripts/core/ai/ai_event_channels.gd")
var _player_stats: RefCounted = null
const SaveLoadSystemScript = preload("res://1.Codebase/src/scripts/core/save_load_system.gd")
var _save_load_system: RefCounted = null
const EventLogSystemScript = preload("res://1.Codebase/src/scripts/core/event_log_system.gd")
var _event_log_system: RefCounted = null
const DebuffSystemScript = preload("res://1.Codebase/src/scripts/core/debuff_system.gd")
var _debuff_system: RefCounted = null
var reality_score: int:
	get:
		return _player_stats.reality_score if _player_stats else 50
	set(value):
		if _player_stats: _player_stats.reality_score = value
var positive_energy: int:
	get:
		return _player_stats.positive_energy if _player_stats else 50
	set(value):
		if _player_stats: _player_stats.positive_energy = value
var entropy_level: int:
	get:
		return _player_stats.entropy_level if _player_stats else 0
	set(value):
		if _player_stats: _player_stats.entropy_level = value
var player_stats: Dictionary:
	get:
		return _player_stats.skills if _player_stats else { }
	set(value):
		if _player_stats: _player_stats.skills = value
var current_mission: int = 0
var current_mission_title: String = "" 
var mission_turn_count: int = 0 
var complaint_counter: int = 0 
var missions_completed: int = 0
var game_phase: String = GameConstants.GamePhase.HONEYMOON
var honeymoon_charges: int = 0
var is_session_active: bool = false 
var just_loaded_from_save: bool = false 
var is_honeymoon_phase: bool:
	get:
		return game_phase == GameConstants.GamePhase.HONEYMOON
	set(value):
		if value:
			game_phase = GameConstants.GamePhase.HONEYMOON
		elif game_phase == GameConstants.GamePhase.HONEYMOON:
			game_phase = GameConstants.GamePhase.NORMAL
var active_debuffs: Array:
	get:
		return _debuff_system.active_debuffs if _debuff_system else []
	set(value):
		if _debuff_system: _debuff_system.active_debuffs = value
var cognitive_dissonance_active: bool:
	get:
		return _debuff_system.cognitive_dissonance_active if _debuff_system else false
	set(value):
		if _debuff_system: _debuff_system.cognitive_dissonance_active = value
var cognitive_dissonance_choices_left: int:
	get:
		return _debuff_system.cognitive_dissonance_choices_left if _debuff_system else 0
	set(value):
		if _debuff_system: _debuff_system.cognitive_dissonance_choices_left = value
var recent_events: Array:
	get:
		return _event_log_system.recent_events if _event_log_system else []
	set(value):
		if _event_log_system: _event_log_system.recent_events = value
var event_log: Array:
	get:
		return _event_log_system.event_log if _event_log_system else []
	set(value):
		if _event_log_system: _event_log_system.event_log = value
const MAX_EVENTS: int = GameConstants.Events.MAX_RECENT_EVENTS
const MAX_EVENT_LOG_SIZE: int = GameConstants.Events.MAX_EVENT_LOG_SIZE
var metadata: Dictionary = { }
const ButterflyEffectTrackerScript = preload("res://1.Codebase/src/scripts/core/butterfly_effect_tracker.gd")
var butterfly_tracker: Node = null
var _event_bus: Variant = null
var _error_reporter: Variant = null
var _localization_manager: Variant = null
var _ai_manager: Variant = null
var _audio_manager: Variant = null
var _achievement_system: Variant = null
var _teammate_system: Variant = null
var _tutorial_system: Variant = null
var _cached_stats_payload: Dictionary = { }
var _stats_cache_dirty: bool = true
enum Language { EN, ZH }
var current_language: String = "en" 
var autosave_enabled: bool = true
var autosave_interval: float = 300.0 
var _autosave_timer: float = 0.0
var settings: Dictionary = {
	"text_speed": 1.0, 
	"screen_shake_enabled": true,
	"high_contrast_mode": false,
	"auto_advance_enabled": false,
}
var debug_force_mission_complete: bool = false
var debug_force_trolley_next_turn: bool = false
var current_save_slot: int:
	get:
		return _save_load_system.current_save_slot if _save_load_system else 1
	set(value):
		if _save_load_system: _save_load_system.current_save_slot = value
const MAX_SAVE_SLOTS: int = GameConstants.SaveSystem.MAX_SAVE_SLOTS
func _ready():
	set_process(true)
	_refresh_service_cache()
	call_deferred("_refresh_service_cache")
	_player_stats = PlayerStatsScript.new()
	_player_stats.reality_score_changed.connect(_on_reality_score_changed)
	_player_stats.positive_energy_changed.connect(_on_positive_energy_changed)
	_player_stats.entropy_level_changed.connect(_on_entropy_level_changed)
	_player_stats.stats_changed.connect(_on_stats_changed)
	_save_load_system = SaveLoadSystemScript.new()
	_save_load_system.set_game_state(self)
	_event_log_system = EventLogSystemScript.new()
	_event_log_system.set_game_state(self)
	_event_log_system.event_logged.connect(_on_event_logged)
	_debuff_system = DebuffSystemScript.new()
	butterfly_tracker = ButterflyEffectTrackerScript.new()
	add_child(butterfly_tracker)
	_subscribe_to_eventbus()
func _subscribe_to_eventbus() -> void:
	var event_bus = _get_event_bus()
	if not event_bus:
		_report_warning("Unable to subscribe to EventBus; EventBus service missing")
		return
	event_bus.subscribe("get_reality_score", self, "_handle_get_reality_score")
	event_bus.subscribe("get_positive_energy", self, "_handle_get_positive_energy")
	event_bus.subscribe("get_entropy_level", self, "_handle_get_entropy_level")
	event_bus.subscribe("get_all_stats", self, "_handle_get_all_stats")
	event_bus.subscribe("modify_reality_score", self, "_handle_modify_reality_score")
	event_bus.subscribe("modify_positive_energy", self, "_handle_modify_positive_energy")
	event_bus.subscribe(AIEventChannels.CURRENT_LANGUAGE_REQUEST, self, "_handle_ai_language_request")
	event_bus.subscribe(AIEventChannels.RECENT_ASSETS_REQUEST, self, "_handle_recent_assets_request")
func _handle_get_reality_score(_data: Variant = null) -> int:
	return reality_score
func _handle_get_positive_energy(_data: Variant = null) -> int:
	return positive_energy
func _handle_get_entropy_level(_data: Variant = null) -> int:
	return entropy_level
func _handle_get_all_stats(_data: Variant = null) -> Dictionary:
	return _get_cached_stats_payload().duplicate(false)
func _get_cached_stats_payload() -> Dictionary:
	if _stats_cache_dirty or _cached_stats_payload.is_empty():
		_cached_stats_payload = {
			"reality_score": reality_score,
			"positive_energy": positive_energy,
			"entropy_level": entropy_level,
			"skills": player_stats.duplicate(true) if player_stats else { },
		}
		_stats_cache_dirty = false
	return _cached_stats_payload
func _mark_stats_cache_dirty() -> void:
	_stats_cache_dirty = true
func _handle_ai_language_request(_data: Variant = null) -> String:
	return current_language
func _handle_recent_assets_request(_data: Variant = null):
	return get_metadata("recent_assets_data", [])
func _handle_modify_reality_score(data: Dictionary) -> void:
	var amount = data.get("amount", 0)
	var reason = data.get("reason", "")
	modify_reality_score(amount, reason)
func _handle_modify_positive_energy(data: Dictionary) -> void:
	var amount = data.get("amount", 0)
	var reason = data.get("reason", "")
	modify_positive_energy(amount, reason)
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			_on_application_paused()
		NOTIFICATION_APPLICATION_RESUMED:
			_on_application_resumed()
		NOTIFICATION_WM_CLOSE_REQUEST:
			_on_application_closing()
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			_on_window_focus_lost()
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			_on_window_focus_gained()
func _on_application_paused() -> void:
	if autosave_enabled:
		print("[GameState] Application paused - saving game state...")
		var success = autosave()
		if success:
			print("[GameState] Game state saved successfully on pause")
		else:
			_report_error("Failed to save game state on application pause")
func _on_application_resumed() -> void:
	print("[GameState] Application resumed")
func _on_application_closing() -> void:
	if autosave_enabled:
		print("[GameState] Application closing - final save...")
		autosave()
func _on_window_focus_lost() -> void:
	if autosave_enabled:
		print("[GameState] Window focus lost - saving game state...")
		var success = autosave()
		if success:
			print("[GameState] Game state saved successfully on focus loss")
		else:
			_report_error("Failed to save game state on window focus loss")
func _on_window_focus_gained() -> void:
	print("[GameState] Window focus gained - game resumed")
func _exit_tree():
	set_process(false)
	if _debuff_system:
		_debuff_system.clear_all()
	if _event_log_system:
		_event_log_system.clear_events()
	metadata.clear()
	if butterfly_tracker:
		butterfly_tracker.queue_free()
		butterfly_tracker = null
func _process(delta: float):
	if autosave_enabled:
		_autosave_timer += delta
		if _autosave_timer >= autosave_interval:
			_autosave_timer = 0.0
			autosave()
func _stat_label(stat_id: String, lang: String) -> String:
	var localization_manager = _get_localization_manager()
	return localization_manager.tr_stat(stat_id, lang) if localization_manager else stat_id.capitalize()
func _skill_label(skill_id: String, lang: String) -> String:
	var localization_manager = _get_localization_manager()
	return localization_manager.tr_skill(skill_id, lang) if localization_manager else skill_id.capitalize()
func _teammate_label(teammate_id: String, lang: String) -> String:
	var localization_manager = _get_localization_manager()
	return localization_manager.tr_teammate(teammate_id, lang) if localization_manager else teammate_id.capitalize()
func _phase_label(phase_id: String, lang: String) -> String:
	var localization_manager = _get_localization_manager()
	return localization_manager.tr_phase(phase_id, lang) if localization_manager else phase_id.capitalize()
func _translate_reason(reason: String, lang: String) -> String:
	if reason.strip_edges().is_empty():
		return ""
	var localization_manager = _get_localization_manager()
	return localization_manager.tr_reason(reason, lang) if localization_manager else reason
func _on_reality_score_changed(new_value: int, old_value: int) -> void:
	_mark_stats_cache_dirty()
	reality_score_changed.emit(new_value)
	var event_bus = _get_event_bus()
	if event_bus:
		event_bus.publish(
			"reality_score_changed",
			{
				"new_value": new_value,
				"old_value": old_value,
				"delta": new_value - old_value,
				"timestamp": Time.get_ticks_msec(),
			},
		)
	check_reality_triggers()
func _on_positive_energy_changed(new_value: int, old_value: int) -> void:
	_mark_stats_cache_dirty()
	positive_energy_changed.emit(new_value)
	var event_bus = _get_event_bus()
	if event_bus:
		event_bus.publish(
			"positive_energy_changed",
			{
				"new_value": new_value,
				"old_value": old_value,
				"delta": new_value - old_value,
				"timestamp": Time.get_ticks_msec(),
			},
		)
func _on_entropy_level_changed(new_value: int, old_value: int) -> void:
	_mark_stats_cache_dirty()
	entropy_level_changed.emit(new_value)
	var event_bus = _get_event_bus()
	if event_bus:
		event_bus.publish(
			"entropy_level_changed",
			{
				"new_value": new_value,
				"old_value": old_value,
				"delta": new_value - old_value,
				"timestamp": Time.get_ticks_msec(),
			},
		)
func _on_stats_changed() -> void:
	_mark_stats_cache_dirty()
	_mark_stats_cache_dirty()
	stats_changed.emit()
	var event_bus = _get_event_bus()
	if event_bus:
		event_bus.publish(
			"stats_changed",
			{
				"reality_score": reality_score,
				"positive_energy": positive_energy,
				"entropy_level": entropy_level,
				"timestamp": Time.get_ticks_msec(),
			},
		)
func _on_event_logged(event: Dictionary) -> void:
	event_logged.emit(event)
	var event_bus = _get_event_bus()
	if event_bus:
		event_bus.publish("event_logged", event)
func _stat_change_importance(amount: int) -> int:
	var magnitude: int = abs(amount)
	var thresholds := GameConstants.Stats.STAT_CHANGE_IMPORTANCE_THRESHOLDS
	var base_importance := thresholds.size() + 1
	for i in range(thresholds.size()):
		if magnitude >= thresholds[i]:
			return base_importance - i
	return 1
func _notify_stat_change(stat_id: String, amount: int, reason: String) -> void:
	var event_bus = _get_event_bus()
	if not event_bus:
		return
	if amount == 0:
		return
	var note_en := "%s %+d" % [_stat_label(stat_id, "en"), amount]
	var note_zh := "%s %+d" % [_stat_label(stat_id, "zh"), amount]
	var reason_en := _translate_reason(reason, "en")
	var reason_zh := _translate_reason(reason, "zh")
	if not reason_en.is_empty():
		note_en += " (%s)" % reason_en
	if not reason_zh.is_empty():
		note_zh += " (%s)" % reason_zh
	var importance := _stat_change_importance(amount)
	event_bus.publish(
		AIEventChannels.REGISTER_NOTE_PAIR,
		{
			"text_en": note_en,
			"text_zh": note_zh,
			"tags": ["stat", stat_id],
			"importance": importance,
			"source": "stat_change",
		},
	)
func modify_reality_score(amount: int, reason: String = ""):
	if not _player_stats:
		_report_error(
			"modify_reality_score called without PlayerStats",
			ErrorCodes.GameState.INVALID_STAT_MODIFICATION,
			false,
			{ "amount": amount, "reason": reason },
		)
		return
	var old_score = reality_score
	_player_stats.modify_reality_score(amount, reason)
	var audio_manager = _get_audio_manager()
	if audio_manager and abs(amount) >= 3:
		if amount > 0:
			audio_manager.play_sfx("collect_money", 0.7)
		else:
			audio_manager.play_sfx("pay_money", 0.7)
	var reason_en := _translate_reason(reason, "en")
	var event_en := "Reality score change: %+d" % amount
	if not reason_en.is_empty():
		event_en += " (%s)" % reason_en
	add_event(event_en, event_en)
	_notify_stat_change("reality", amount, reason)
func check_reality_triggers():
	if reality_score >= GameConstants.Stats.HIGH_REALITY_THRESHOLD:
		set_metadata("high_reality_triggered", true)
		add_event(
			"Your heightened reality perception makes Gloria uncomfortable - she will attack more frequently.",
			"Your heightened reality perception makes Gloria uncomfortable - she will attack more frequently.",
		)
		if complaint_counter >= GameConstants.Gloria.HIGH_REALITY_COMPLAINT_THRESHOLD:
			set_metadata("gloria_attack_pending", true)
	elif reality_score <= GameConstants.Stats.LOW_REALITY_THRESHOLD:
		print("[DEBUG_STATE] ! LOW REALITY TRIGGERED ! Score: %d" % reality_score)
		set_metadata("low_reality_triggered", true)
		var audio_manager = _get_audio_manager()
		if audio_manager:
			audio_manager.play_sfx("bankruptcy", 0.9)
		add_event(
			"Your reality perception is dangerously low. The world feels increasingly unreal.",
			"Your reality perception is dangerously low. The world feels increasingly unreal.",
		)
		if not cognitive_dissonance_active:
			add_debuff(
				GameConstants.Debuffs.COGNITIVE_DISSONANCE_NAME,
				GameConstants.Debuffs.COGNITIVE_DISSONANCE_DURATION,
				"Cognitive dissonance triggered by low reality perception",
			)
			cognitive_dissonance_active = true
			cognitive_dissonance_choices_left = GameConstants.Debuffs.COGNITIVE_DISSONANCE_DURATION
func modify_positive_energy(amount: int, reason: String = ""):
	if not _player_stats:
		_report_error(
			"modify_positive_energy called without PlayerStats",
			ErrorCodes.GameState.INVALID_STAT_MODIFICATION,
			false,
			{ "amount": amount, "reason": reason },
		)
		return
	_player_stats.modify_positive_energy(amount, reason)
	var audio_manager = _get_audio_manager()
	if audio_manager and abs(amount) >= 5:
		if amount > 0:
			audio_manager.play_sfx("collect_money", 0.6)
		else:
			audio_manager.play_sfx("pay_money", 0.6)
	var reason_en := _translate_reason(reason, "en")
	var event_en := "Positive energy change: %+d" % amount
	if not reason_en.is_empty():
		event_en += " (%s)" % reason_en
	add_event(event_en, event_en)
	_notify_stat_change("positive", amount, reason)
func calculate_void_entropy() -> float:
	return _player_stats.calculate_void_entropy() if _player_stats else 0.0
func get_entropy_threshold() -> String:
	return _player_stats.get_entropy_threshold() if _player_stats else "low"
func get_entropy_level_label(lang: String = "en") -> String:
	return _player_stats.get_entropy_level_label(lang) if _player_stats else ("Unknown" if lang == "en" else "未知")
func modify_entropy(amount: int, reason: String = ""):
	if not _player_stats:
		_report_error(
			"modify_entropy called without PlayerStats",
			ErrorCodes.GameState.INVALID_STAT_MODIFICATION,
			false,
			{ "amount": amount, "reason": reason },
		)
		return
	_player_stats.modify_entropy(amount, reason)
	if amount > 0:
		var reason_en := _translate_reason(reason, "en")
		var event_en := "World entropy surge: +%d" % amount
		if not reason_en.is_empty():
			event_en += " (%s)" % reason_en
		add_event(event_en, event_en)
	_notify_stat_change("entropy", amount, reason)
func add_complaint():
	complaint_counter += 1
	if complaint_counter >= GameConstants.Gloria.MIN_COMPLAINTS_FOR_TRIGGER:
		complaint_counter = 0
		var achievement_system = _get_achievement_system()
		if achievement_system:
			achievement_system.check_gloria_trigger()
		return true
	return false
func reset_complaint_counter():
	complaint_counter = 0
func get_stat(stat_name: String) -> int:
	if not _player_stats:
		_report_error(
			"Stat not found",
			ErrorCodes.GameState.STAT_NOT_FOUND,
			false,
			{ "stat_name": stat_name, "reason": "PlayerStats not initialized" },
		)
		return 0
	return _player_stats.get_skill(stat_name)
func modify_stat(stat_name: String, amount: int):
	if not _player_stats:
		_report_error(
			"Invalid stat modification",
			ErrorCodes.GameState.INVALID_STAT_MODIFICATION,
			false,
			{ "stat_name": stat_name, "amount": amount, "reason": "PlayerStats not initialized" },
		)
		return
	_player_stats.modify_skill(stat_name, amount)
func skill_check(stat_name: String, difficulty: int = 5) -> Dictionary:
	if not _player_stats:
		return { "success": false, "roll": 0, "skill_value": 0, "total": 0, "difficulty": difficulty }
	_player_stats.cognitive_dissonance_active = cognitive_dissonance_active
	var result = _player_stats.skill_check(stat_name, difficulty)
	if result["success"]:
		var achievement_system = _get_achievement_system()
		if achievement_system:
			achievement_system.check_skill_check_success(stat_name)
	return result
func add_debuff(debuff_name: String, duration: int, effect: String):
	if not _debuff_system:
		return
	var audio_manager = _get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("jail", 0.8)
	_debuff_system.add_debuff(debuff_name, duration, effect)
func process_debuffs():
	if not _debuff_system:
		return
	_debuff_system.process_debuffs()
func use_cognitive_dissonance_choice():
	if not _debuff_system:
		return
	_debuff_system.use_cognitive_dissonance_choice()
func set_game_phase(phase: String):
	var old_phase = game_phase
	game_phase = phase
	_report_info("Game phase changed", { "from": old_phase, "to": phase })
	var event_en := "Game phase changed: %s" % _phase_label(phase, "en")
	add_event(event_en, event_en)
func is_in_honeymoon() -> bool:
	return game_phase == GameConstants.GamePhase.HONEYMOON
func enter_honeymoon_phase():
	set_game_phase(GameConstants.GamePhase.HONEYMOON)
	honeymoon_charges = GameConstants.Honeymoon.INITIAL_CHARGES
	var audio_manager = _get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("free_parking", 0.8)
	add_event(
		"Honeymoon charges reset to %d" % GameConstants.Honeymoon.INITIAL_CHARGES,
		"Honeymoon charges reset to %d" % GameConstants.Honeymoon.INITIAL_CHARGES,
	)
func exit_honeymoon_phase():
	set_game_phase(GameConstants.GamePhase.NORMAL)
	honeymoon_charges = GameConstants.Honeymoon.MIN_CHARGES
func start_mission(mission_id: int):
	current_mission = mission_id
	current_mission_title = "Mission %d" % mission_id 
	mission_turn_count = 0
	var event_en := "Mission #%d started" % mission_id
	add_event(event_en, event_en)
	if game_phase == GameConstants.GamePhase.HONEYMOON and honeymoon_charges <= GameConstants.Honeymoon.MIN_CHARGES:
		set_game_phase(GameConstants.GamePhase.NORMAL)
	elif game_phase != GameConstants.GamePhase.HONEYMOON:
		set_game_phase(GameConstants.GamePhase.NORMAL)
	print("\n[DEBUG_STATE] Starting Mission #%d (Turn Count Reset)" % current_mission)
func complete_mission(success: bool):
	missions_completed += 1
	print("\n[DEBUG_STATE] Mission Completed! Success: %s, Total Completed: %d" % [success, missions_completed])
	var audio_manager = _get_audio_manager()
	if audio_manager:
		if success:
			audio_manager.play_sfx("buy_property", 0.8) 
		else:
			audio_manager.play_sfx("game_over", 0.7)
	var achievement_system = _get_achievement_system()
	if achievement_system:
		achievement_system.check_mission_complete()
	var tutorial_system = _get_tutorial_system()
	if tutorial_system:
		tutorial_system.check_tutorial_trigger("first_mission_complete")
	if success:
		modify_entropy(10, "Mission 'success' paradox")
	var success_text := "success" if success else "failed"
	var event_en := "Mission #%d completed (%s)" % [current_mission, success_text]
	add_event(event_en, event_en)
	record_event(
		"mission_complete",
		{
			"mission_number": current_mission,
			"success": success,
			"outcome": success_text,
		},
	)
func record_event(event_type: String, details: Dictionary = { }):
	if not _event_log_system:
		return { }
	return _event_log_system.record_event(event_type, details)
func consume_honeymoon_charge(reason: String = ""):
	if game_phase != GameConstants.GamePhase.HONEYMOON:
		return
	if honeymoon_charges <= GameConstants.Honeymoon.MIN_CHARGES:
		return
	honeymoon_charges = max(GameConstants.Honeymoon.MIN_CHARGES, honeymoon_charges - 1)
	var reason_en := _translate_reason(reason, "en")
	var note_en := "Honeymoon charge -1"
	if not reason_en.is_empty():
		note_en += " (%s)" % reason_en
	add_event(note_en, note_en)
	if honeymoon_charges == GameConstants.Honeymoon.MIN_CHARGES:
		add_event(
			"Honeymoon phase depleted; teammates reveal their true nature",
			"Honeymoon phase depleted; teammates reveal their true nature",
		)
		set_game_phase(GameConstants.GamePhase.NORMAL)
func get_recent_records(limit: int = 10) -> Array:
	if not _event_log_system:
		return []
	return _event_log_system.get_recent_records(limit)
func clear_event_log():
	if not _event_log_system:
		return
	_event_log_system.clear_event_log()
func get_recent_event_notes(limit: int = 6, lang: String = "en") -> Array:
	if not _event_log_system:
		return []
	return _event_log_system.get_recent_event_notes(limit, lang)
func add_event(event_en: String, event_zh: String = ""):
	if not _event_log_system:
		return
	_event_log_system.current_language = current_language
	_event_log_system.add_event(event_en, event_zh)
func get_events_summary() -> String:
	if not _event_log_system:
		return ""
	return _event_log_system.get_events_summary()
func clear_events():
	if not _event_log_system:
		return
	_event_log_system.clear_events()
func set_metadata(key: String, value) -> void:
	metadata[key] = value
func get_metadata(key: String, default_value = null):
	if metadata.has(key):
		return metadata[key]
	return default_value
func delete_local_logs() -> Dictionary:
	var result := {
		"event_log_cleared": false,
		"metadata_keys_removed": [],
		"files_deleted": 0,
	}
	clear_event_log()
	result["event_log_cleared"] = true
	var metadata_keys_removed: Array[String] = []
	var metadata_log_keys: Array[String] = [
		"latest_story_text",
		"latest_story_timestamp",
		"recent_assets_data",
		"recent_asset_icons",
		"current_asset_ids",
	]
	for key in metadata_log_keys:
		if metadata.has(key):
			metadata.erase(key)
			metadata_keys_removed.append(key)
	result["metadata_keys_removed"] = metadata_keys_removed
	result["files_deleted"] = _delete_log_files()
	return result
func _delete_log_files() -> int:
	var removed := 0
	var root := DirAccess.open("user://")
	if root == null:
		return removed
	var log_dirs: Array[String] = ["logs", "gda1_logs", "gda1_debug_logs", "gda1_prayer_logs"]
	for dir_name in log_dirs:
		if root.dir_exists(dir_name):
			removed += _delete_directory_contents("user://%s" % dir_name)
	var removable_files: Array[String] = []
	root.list_dir_begin()
	while true:
		var name := root.get_next()
		if name == "":
			break
		if name == "." or name == "..":
			continue
		if root.current_is_dir():
			continue
		var lower := name.to_lower()
		if lower.ends_with(".log") or lower.ends_with(".jsonl") or (lower.ends_with(".txt") and lower.find("_log") != -1):
			removable_files.append(name)
	root.list_dir_end()
	var remover := DirAccess.open("user://")
	if remover:
		for file_name in removable_files:
			if remover.file_exists(file_name):
				if remover.remove(file_name) == OK:
					removed += 1
	return removed
func _delete_directory_contents(path: String) -> int:
	var removed := 0
	var dir := DirAccess.open(path)
	if dir == null:
		return removed
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name == "":
			break
		if name == "." or name == "..":
			continue
		if dir.current_is_dir():
			removed += _delete_directory_contents("%s/%s" % [path, name])
		else:
			if dir.remove(name) == OK:
				removed += 1
	dir.list_dir_end()
	return removed
func set_latest_story_text(text: String) -> void:
	metadata["latest_story_text"] = text
	metadata["latest_story_timestamp"] = Time.get_datetime_string_from_system()
func get_latest_story_text(default_value: String = "") -> String:
	var text_value = get_metadata("latest_story_text", default_value)
	return str(text_value)
func get_journal_entries() -> Array:
	var stored = get_metadata("journal_entries", [])
	if stored is Array:
		return (stored as Array).duplicate(false)
	return []
func set_journal_entries(entries: Array) -> void:
	metadata["journal_entries"] = entries
func append_journal_entry(entry: Dictionary) -> void:
	var entries = get_journal_entries()
	entries.append(entry.duplicate(true))
	set_journal_entries(entries)
func get_recent_journal_entries(limit: int = 3) -> Array:
	var entries = get_journal_entries()
	if entries.is_empty():
		return []
	var count: int = min(limit, entries.size())
	var start: int = max(0, entries.size() - count)
	return entries.slice(start, entries.size())
func get_save_data() -> Dictionary:
	var data := {
		"current_mission": current_mission,
		"current_mission_title": current_mission_title,
		"mission_turn_count": mission_turn_count,
		"complaint_counter": complaint_counter,
		"missions_completed": missions_completed,
		"game_phase": game_phase,
		"honeymoon_charges": honeymoon_charges,
		"metadata": metadata.duplicate(true),
		"current_language": current_language,
		"is_session_active": is_session_active,
	}
	if _player_stats:
		data["player_stats_data"] = _player_stats.get_save_data()
	else:
		data["player_stats_data"] = {
			"reality_score": 50,
			"positive_energy": 50,
			"entropy_level": 0,
			"skills": { "logic": 5, "perception": 5, "composure": 5, "empathy": 5 },
		}
	if _event_log_system:
		var event_data = _event_log_system.get_save_data()
		data["recent_events"] = event_data.get("recent_events", [])
		data["event_log"] = event_data.get("event_log", [])
	if _debuff_system:
		data["debuff_system_data"] = _debuff_system.get_save_data()
	var event_bus = _get_event_bus()
	if event_bus:
		var ai_state = event_bus.request(AIEventChannels.STATE_SNAPSHOT_REQUEST)
		if ai_state is Dictionary:
			data["ai_state"] = (ai_state as Dictionary).duplicate(true)
	var audio_manager = _get_audio_manager()
	if audio_manager:
		data["audio_settings"] = audio_manager.get_volume_settings()
	var achievement_system = _get_achievement_system()
	if achievement_system and achievement_system.has_method("get_state_snapshot"):
		var achievement_state: Dictionary = achievement_system.get_state_snapshot()
		data["achievement_state"] = achievement_state
		var meta_ref: Dictionary = data["metadata"]
		var unlocked_data = achievement_state.get("unlocked", { })
		meta_ref["achievements"] = unlocked_data if unlocked_data is Dictionary else { }
		var progress_data = achievement_state.get("progress", { })
		meta_ref["achievement_progress"] = progress_data if progress_data is Dictionary else { }
	var teammate_system = _get_teammate_system()
	if teammate_system and teammate_system.has_method("get_state_snapshot"):
		data["teammate_state"] = teammate_system.get_state_snapshot()
	if butterfly_tracker:
		data["butterfly_tracker"] = butterfly_tracker.get_save_data()
	return data
func load_save_data(data: Dictionary):
	if _player_stats:
		if data.has("player_stats_data"):
			_player_stats.load_save_data(data["player_stats_data"])
		else:
			var legacy_data = {
				"reality_score": data.get("reality_score", 50),
				"positive_energy": data.get("positive_energy", 50),
				"entropy_level": data.get("entropy_level", 0),
				"skills": data.get("player_stats", { "logic": 5, "perception": 5, "composure": 5, "empathy": 5 }),
			}
			_player_stats.load_save_data(legacy_data)
	if _event_log_system:
		if data.has("debuff_system_data"):
			var event_data = {
				"event_log": data.get("event_log", []),
				"recent_events": data.get("recent_events", []),
			}
			_event_log_system.load_save_data(event_data)
		else:
			var event_data = {
				"event_log": data.get("event_log", []),
				"recent_events": data.get("recent_events", []),
			}
			_event_log_system.load_save_data(event_data)
	if _debuff_system:
		if data.has("debuff_system_data"):
			_debuff_system.load_save_data(data["debuff_system_data"])
		else:
			var legacy_debuff_data = {
				"active_debuffs": data.get("active_debuffs", []),
				"cognitive_dissonance_active": data.get("cognitive_dissonance_active", false),
				"cognitive_dissonance_choices_left": data.get("cognitive_dissonance_choices_left", 0),
			}
			_debuff_system.load_save_data(legacy_debuff_data)
	current_mission = data.get("current_mission", 0)
	current_mission_title = data.get("current_mission_title", "Mission %d" % current_mission)
	mission_turn_count = data.get("mission_turn_count", 0)
	complaint_counter = data.get("complaint_counter", 0)
	missions_completed = data.get("missions_completed", 0)
	game_phase = data.get("game_phase", GameConstants.GamePhase.HONEYMOON)
	honeymoon_charges = data.get("honeymoon_charges", 0)
	is_session_active = data.get("is_session_active", false)
	var metadata_data = data.get("metadata", { })
	metadata = metadata_data.duplicate(true) if metadata_data is Dictionary else { }
	current_language = data.get("current_language", "en")
	if _event_log_system:
		_event_log_system.current_language = current_language
	_mark_stats_cache_dirty()
	stats_changed.emit()
	var audio_manager = _get_audio_manager()
	if data.has("audio_settings") and audio_manager:
		audio_manager.apply_volume_settings(data["audio_settings"])
	var event_bus = _get_event_bus()
	if data.has("ai_state") and event_bus:
		event_bus.publish(AIEventChannels.LOAD_STATE_SNAPSHOT, data["ai_state"])
	if data.has("achievement_state"):
		var achievement_system = _get_achievement_system()
		if achievement_system and achievement_system.has_method("load_state_snapshot"):
			achievement_system.load_state_snapshot(data["achievement_state"])
		else:
			metadata["pending_achievement_state"] = data["achievement_state"]
	if data.has("teammate_state"):
		var teammate_system = _get_teammate_system()
		if teammate_system and teammate_system.has_method("load_state_snapshot"):
			teammate_system.load_state_snapshot(data["teammate_state"])
		else:
			metadata["pending_teammate_state"] = data["teammate_state"]
	if data.has("butterfly_tracker") and butterfly_tracker:
		butterfly_tracker.load_save_data(data["butterfly_tracker"])
	just_loaded_from_save = true
func _refresh_service_cache() -> void:
	if not ServiceLocator:
		return
	_event_bus = ServiceLocator.get_event_bus()
	_error_reporter = ServiceLocator.get_error_reporter()
	_localization_manager = ServiceLocator.get_localization_manager()
	_ai_manager = ServiceLocator.get_ai_manager()
	_audio_manager = ServiceLocator.get_audio_manager()
	_achievement_system = ServiceLocator.get_achievement_system()
	_teammate_system = ServiceLocator.get_teammate_system()
	_tutorial_system = ServiceLocator.get_tutorial_system()
func _get_event_bus() -> Variant:
	if not is_instance_valid(_event_bus):
		_refresh_service_cache()
	return _event_bus
func _get_error_reporter() -> Variant:
	if not is_instance_valid(_error_reporter):
		_refresh_service_cache()
	return _error_reporter
func _get_localization_manager() -> Variant:
	if not is_instance_valid(_localization_manager):
		_refresh_service_cache()
	return _localization_manager
func _get_ai_manager() -> Variant:
	if not is_instance_valid(_ai_manager):
		_refresh_service_cache()
	return _ai_manager
func _get_audio_manager() -> Variant:
	if not is_instance_valid(_audio_manager):
		_refresh_service_cache()
	return _audio_manager
func _get_achievement_system() -> Variant:
	if not is_instance_valid(_achievement_system):
		_refresh_service_cache()
	return _achievement_system
func _get_teammate_system() -> Variant:
	if not is_instance_valid(_teammate_system):
		_refresh_service_cache()
	return _teammate_system
func _get_tutorial_system() -> Variant:
	if not is_instance_valid(_tutorial_system):
		_refresh_service_cache()
	return _tutorial_system
func _report_info(message: String, details: Dictionary = { }) -> void:
	var reporter = _get_error_reporter()
	if reporter:
		reporter.report_info("GameState", message, details)
func _report_warning(message: String, details: Dictionary = { }) -> void:
	var reporter = _get_error_reporter()
	if reporter:
		reporter.report_warning("GameState", message, details)
func _report_error(message: String, error_code: int = -1, notify_user: bool = false, details: Dictionary = { }) -> void:
	var reporter = _get_error_reporter()
	if reporter:
		reporter.report_error("GameState", message, error_code, notify_user, details)
func autosave():
	if not _save_load_system:
		return false
	return _save_load_system.autosave()
func save_game_to_slot(slot: int = -1) -> bool:
	if not _save_load_system:
		return false
	return _save_load_system.save_to_slot(slot)
func save_game():
	return save_game_to_slot(current_save_slot)
func load_game_from_slot(slot: int = -1) -> bool:
	if not _save_load_system:
		return false
	return _save_load_system.load_from_slot(slot)
func load_game() -> bool:
	if not _save_load_system:
		return false
	return _save_load_system.load_game()
func get_autosave_info() -> Dictionary:
	if not _save_load_system:
		return { "exists": false }
	return _save_load_system.get_autosave_info()
func get_save_slot_info(slot: int) -> Dictionary:
	if not _save_load_system:
		return { "exists": false }
	return _save_load_system.get_save_slot_info(slot)
func get_latest_save_info() -> Dictionary:
	if not _save_load_system:
		return { "exists": false }
	return _save_load_system.get_latest_save_info()
func has_saved_game() -> bool:
	if not _save_load_system:
		return false
	return _save_load_system.has_saved_game()
func delete_save_slot(slot: int) -> bool:
	if not _save_load_system:
		return false
	return _save_load_system.delete_save_slot(slot)
func delete_autosave() -> bool:
	if not _save_load_system:
		return false
	return _save_load_system.delete_autosave()
func new_game():
	_report_info("Starting new game reset")
	if _player_stats:
		_player_stats.reset()
	if _debuff_system:
		_debuff_system.reset()
	if _event_log_system:
		_event_log_system.reset()
	current_mission = 0
	current_mission_title = ""
	mission_turn_count = 0
	complaint_counter = 0
	missions_completed = 0
	game_phase = GameConstants.GamePhase.HONEYMOON
	metadata.clear()
	_mark_stats_cache_dirty()
	stats_changed.emit()
	var event_bus = _get_event_bus()
	if event_bus:
		event_bus.publish(AIEventChannels.CLEAR_MEMORY)
	if butterfly_tracker:
		butterfly_tracker.clear_all()
	is_session_active = true
	_report_info("New game initialized")
	print("\n[DEBUG_STATE] === NEW GAME STARTED ===")
	print("[DEBUG_STATE] Stats Reset -> Reality: %d, Positive: %d, Entropy: %d" % [_player_stats.reality_score, _player_stats.positive_energy, _player_stats.entropy_level])
	print("[DEBUG_STATE] ========================\n")
