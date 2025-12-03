extends BaseController
class_name StoryStateController
const ERROR_CONTEXT := "StoryStateController"
const PRAYER_CONTEXT_MISSION := "mission"
const PRAYER_CONTEXT_NIGHT := "night"
const FLAG_NIGHT := &"night_cycle"
const FLAG_HONEYMOON := &"honeymoon_phase"
const FLAG_FORCE_PRAYER_ONLY := &"force_prayer_only"
const _VALID_PRAYER_CONTEXTS: Array[String] = [
	PRAYER_CONTEXT_MISSION,
	PRAYER_CONTEXT_NIGHT,
]
enum OverlaySlot {
	PAUSE,
	SETTINGS,
	JOURNAL,
	NIGHT,
	GLORIA,
}
class MissionState:
	var data: Dictionary = { }
	var counter: int = 0
	func set_mission(mission_data: Dictionary) -> void:
		data = mission_data.duplicate(true)
		counter += 1
	func clear_current() -> void:
		data.clear()
	func reset() -> void:
		clear_current()
		counter = 0
class LoadingState:
	var awaiting: bool = false
	var started_at: float = 0.0
	var elapsed: float = 0.0
	var current_model: String = ""
	var pending_interference: String = ""
	func begin_wait() -> void:
		awaiting = true
		started_at = Time.get_ticks_msec() / 1000.0
		elapsed = 0.0
	func end_wait() -> void:
		elapsed = get_elapsed_time()
		awaiting = false
	func get_elapsed_time() -> float:
		if awaiting:
			var now: float = Time.get_ticks_msec() / 1000.0
			elapsed = maxf(0.0, now - started_at)
		return elapsed
	func reset() -> void:
		awaiting = false
		started_at = 0.0
		elapsed = 0.0
		current_model = ""
		pending_interference = ""
class OverlayRegistry:
	var instances: Dictionary = { }
	var pause_requests: int = 0
	var paused_tree: bool = false
	func register(slot: int, overlay: Control) -> void:
		if overlay != null:
			instances[slot] = overlay
		else:
			instances.erase(slot)
	func unregister(slot: int) -> void:
		if instances.has(slot):
			instances.erase(slot)
	func get_overlay(slot: int) -> Control:
		var overlay: Control = instances.get(slot, null)
		if overlay == null:
			return null
		if not is_instance_valid(overlay):
			instances.erase(slot)
			return null
		return overlay
	func has_active_overlay() -> bool:
		for overlay in instances.values():
			if overlay != null and is_instance_valid(overlay):
				return true
		return false
	func clear_all() -> void:
		for overlay in instances.values():
			if overlay != null and is_instance_valid(overlay):
				overlay.queue_free()
		instances.clear()
		pause_requests = 0
		paused_tree = false
class CycleState:
	var prayer_context: String = PRAYER_CONTEXT_MISSION
	var night_payload: Dictionary = { }
	var flags: Dictionary = {
		FLAG_NIGHT: false,
		FLAG_HONEYMOON: false,
		FLAG_FORCE_PRAYER_ONLY: false,
	}
	func set_flag(flag: StringName, active: bool) -> void:
		flags[flag] = active
	func is_flag_enabled(flag: StringName) -> bool:
		return flags.get(flag, false)
	func set_night(active: bool) -> void:
		set_flag(FLAG_NIGHT, active)
		prayer_context = PRAYER_CONTEXT_NIGHT if active else PRAYER_CONTEXT_MISSION
		if not active:
			night_payload.clear()
	func set_prayer_context(context: String) -> void:
		prayer_context = context
var _mission_state: MissionState = MissionState.new()
var _loading_state: LoadingState = LoadingState.new()
var _overlay_registry: OverlayRegistry = OverlayRegistry.new()
var _cycle_state: CycleState = CycleState.new()
func _init(p_story_scene: Control) -> void:
	super(p_story_scene)
func is_awaiting_ai() -> bool:
	return _loading_state.awaiting
func is_in_night_cycle() -> bool:
	return _cycle_state.is_flag_enabled(FLAG_NIGHT)
func is_in_honeymoon() -> bool:
	return _cycle_state.is_flag_enabled(FLAG_HONEYMOON)
func is_force_prayer_only() -> bool:
	return _cycle_state.is_flag_enabled(FLAG_FORCE_PRAYER_ONLY)
func has_active_overlay() -> bool:
	return _overlay_registry.has_active_overlay()
func get_current_mission() -> Dictionary:
	return _mission_state.data
func get_mission_number() -> int:
	return _mission_state.counter
func get_prayer_context() -> String:
	return _cycle_state.prayer_context
func get_last_night_payload() -> Dictionary:
	return _cycle_state.night_payload
func set_awaiting_ai(waiting: bool) -> void:
	if waiting:
		_loading_state.begin_wait()
	else:
		_loading_state.end_wait()
func set_night_cycle(active: bool) -> void:
	_cycle_state.set_night(active)
func set_honeymoon_phase(active: bool) -> void:
	_cycle_state.set_flag(FLAG_HONEYMOON, active)
func set_force_prayer_only(force: bool) -> void:
	_cycle_state.set_flag(FLAG_FORCE_PRAYER_ONLY, force)
func set_current_mission(mission_data: Dictionary) -> void:
	_mission_state.set_mission(mission_data)
func set_prayer_context(context: String) -> void:
	if context in _VALID_PRAYER_CONTEXTS:
		_cycle_state.set_prayer_context(context)
	else:
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Attempted to set invalid prayer context",
			{ "context": context },
		)
func store_night_payload(payload: Dictionary) -> void:
	_cycle_state.night_payload = payload.duplicate(true)
func set_pending_interference(teammate_id: String) -> void:
	_loading_state.pending_interference = teammate_id
func clear_pending_interference() -> void:
	_loading_state.pending_interference = ""
func register_pause_menu(menu: Control) -> void:
	_overlay_registry.register(OverlaySlot.PAUSE, menu)
func unregister_pause_menu() -> void:
	_overlay_registry.unregister(OverlaySlot.PAUSE)
func register_settings_menu(menu: Control) -> void:
	_overlay_registry.register(OverlaySlot.SETTINGS, menu)
func unregister_settings_menu() -> void:
	_overlay_registry.unregister(OverlaySlot.SETTINGS)
func register_journal_menu(menu: Control) -> void:
	_overlay_registry.register(OverlaySlot.JOURNAL, menu)
func unregister_journal_menu() -> void:
	_overlay_registry.unregister(OverlaySlot.JOURNAL)
func register_night_overlay(overlay: Control) -> void:
	_overlay_registry.register(OverlaySlot.NIGHT, overlay)
func unregister_night_overlay() -> void:
	_overlay_registry.unregister(OverlaySlot.NIGHT)
func register_gloria_overlay(overlay: Control) -> void:
	_overlay_registry.register(OverlaySlot.GLORIA, overlay)
func unregister_gloria_overlay() -> void:
	_overlay_registry.unregister(OverlaySlot.GLORIA)
func get_night_overlay() -> Control:
	return _overlay_registry.get_overlay(OverlaySlot.NIGHT)
func push_overlay_pause() -> bool:
	_overlay_registry.pause_requests += 1
	var tree: SceneTree = story_scene.get_tree()
	if tree == null:
		return false
	if tree.paused:
		return false
	tree.paused = true
	_overlay_registry.paused_tree = true
	return true
func pop_overlay_pause(paused_here: bool) -> void:
	if _overlay_registry.pause_requests == 0:
		return
	_overlay_registry.pause_requests = max(0, _overlay_registry.pause_requests - 1)
	if _overlay_registry.pause_requests == 0:
		if _overlay_registry.paused_tree and paused_here and _overlay_registry.get_overlay(OverlaySlot.PAUSE) == null:
			if story_scene.is_inside_tree():
				var tree: SceneTree = story_scene.get_tree()
				if tree:
					tree.paused = false
		_overlay_registry.paused_tree = false
func update_loading_time(_delta: float) -> void:
	_loading_state.get_elapsed_time()
func get_loading_elapsed_time() -> float:
	return _loading_state.get_elapsed_time()
func set_current_ai_model(model: String) -> void:
	_loading_state.current_model = model
func get_current_ai_model() -> String:
	return _loading_state.current_model
func reset_mission_state() -> void:
	_mission_state.clear_current()
	clear_pending_interference()
	set_force_prayer_only(false)
	set_prayer_context(PRAYER_CONTEXT_MISSION)
func reset_all_overlays() -> void:
	_overlay_registry.clear_all()
	if story_scene and story_scene.is_inside_tree():
		var tree: SceneTree = story_scene.get_tree()
		if tree:
			tree.paused = false
func get_state_summary() -> Dictionary:
	return {
		"mission_number": _mission_state.counter,
		"awaiting_ai": _loading_state.awaiting,
		"loading_elapsed": _loading_state.get_elapsed_time(),
		"in_night_cycle": _cycle_state.is_flag_enabled(FLAG_NIGHT),
		"in_honeymoon": _cycle_state.is_flag_enabled(FLAG_HONEYMOON),
		"force_prayer_only": _cycle_state.is_flag_enabled(FLAG_FORCE_PRAYER_ONLY),
		"prayer_context": _cycle_state.prayer_context,
		"has_active_overlay": _overlay_registry.has_active_overlay(),
		"overlay_pause_requests": _overlay_registry.pause_requests,
		"pending_interference": _loading_state.pending_interference,
		"current_ai_model": _loading_state.current_model,
	}
func print_state_summary() -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, "State summary", get_state_summary())
