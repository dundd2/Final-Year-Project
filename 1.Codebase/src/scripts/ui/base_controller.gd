extends RefCounted
class_name BaseController
var story_scene: Control
var _game_state: Node = null
var _audio_manager: Node = null
var _achievement_system: Node = null
var _event_bus: Node = null
var _ai_manager: Node = null
var _font_manager: Node = null
var _display_manager: Node = null
func _init(p_story_scene: Control) -> void:
	assert(p_story_scene != null, "BaseController requires a valid story_scene reference")
	story_scene = p_story_scene
func get_game_state() -> Node:
	if not is_instance_valid(_game_state):
		_game_state = _resolve_service("GameState", "get_game_state", true)
	return _game_state
func get_audio_manager() -> Node:
	if not is_instance_valid(_audio_manager):
		_audio_manager = _resolve_service("AudioManager", "get_audio_manager")
	return _audio_manager
func get_achievement_system() -> Node:
	if not is_instance_valid(_achievement_system):
		_achievement_system = _resolve_service("AchievementSystem", "get_achievement_system")
	return _achievement_system
func get_event_bus() -> Node:
	if not is_instance_valid(_event_bus):
		_event_bus = _resolve_service("EventBus", "get_event_bus")
	return _event_bus
func get_ai_manager() -> Node:
	if not is_instance_valid(_ai_manager):
		_ai_manager = _resolve_service("AIManager", "get_ai_manager")
	return _ai_manager
func get_font_manager() -> Node:
	if not is_instance_valid(_font_manager):
		_font_manager = _resolve_service("FontManager", "get_font_manager")
	return _font_manager
func get_display_manager() -> Node:
	if not is_instance_valid(_display_manager):
		_display_manager = _resolve_service("DisplayManager", "get_display_manager")
	return _display_manager
func _resolve_service(service_name: String, method_name: String, is_required: bool = true) -> Node:
	if not ServiceLocator:
		var message := "ServiceLocator unavailable while resolving %s" % service_name
		if is_required:
			_report_error(message)
		else:
			_report_warning(message)
		return null
	var accessor := Callable(ServiceLocator, method_name)
	if not accessor.is_valid():
		_report_error("ServiceLocator missing accessor '%s' for %s" % [method_name, service_name])
		return null
	var service: Variant = accessor.call()
	if not is_instance_valid(service):
		var unavailable_msg := "%s not available via ServiceLocator" % service_name
		if is_required:
			_report_error(unavailable_msg)
		else:
			_report_warning(unavailable_msg)
		return null
	return service as Node
func get_controller_name() -> String:
	return get_script().get_path().get_file().get_basename().to_pascal_case()
func _report_warning(message: String) -> void:
	var context: String = get_controller_name()
	ErrorReporterBridge.report_warning(context, message)
func _report_error(message: String, details: Dictionary = { }) -> void:
	var context: String = get_controller_name()
	ErrorReporterBridge.report_error(context, message, -1, false, details)
func has_node_safe(path: String) -> bool:
	return story_scene != null and story_scene.has_node(path)
func get_node_safe(path: String) -> Node:
	if story_scene and story_scene.has_node(path):
		return story_scene.get_node(path)
	return null
func get_typed_node_safe(path: String, type: Variant) -> Variant:
	if story_scene and story_scene.has_node(path):
		var node = story_scene.get_node(path)
		if is_instance_of(node, type):
			return node
	return null
