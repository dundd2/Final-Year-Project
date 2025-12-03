extends Node
var _services: Dictionary = { }
func _ready() -> void:
	_auto_register_service("EventBus")
	_auto_register_service("ErrorReporter")
	_auto_register_service("ServiceLocator")
	_auto_register_service("DisplayManager")
	_auto_register_service("FontManager")
	_auto_register_service("AIManager")
	_auto_register_service("OllamaClient")
	_auto_register_service("LocalizationManager")
	_auto_register_service("GameState")
	_auto_register_service("AssetRegistry")
	_auto_register_service("AssetInteractionSystem")
	_auto_register_service("BackgroundLoader")
	_auto_register_service("CharacterExpressionLoader")
	_auto_register_service("AudioManager")
	_auto_register_service("AchievementSystem")
	_auto_register_service("TeammateSystem")
	_auto_register_service("TutorialSystem")
	_auto_register_service("TrolleyProblemGenerator")
	_auto_register_service("NotificationSystem")
	_auto_register_service("TooltipManager")
	_auto_register_service("MissionSummaryLogger")
	_auto_register_service("StoryFlowController")
func _auto_register_service(service_name: String) -> void:
	var root := get_tree().root
	if root == null:
		return
	var service := root.get_node_or_null(service_name)
	if service != null:
		register_service(service_name, service)
func register_service(name: String, service: Variant) -> void:
	if service == null:
		_report_warning("Attempted to register null service '%s'" % name)
		return
	_services[name] = service
func unregister_service(name: String) -> void:
	if _services.has(name):
		_services.erase(name)
func get_service(name: String) -> Variant:
	if not _services.has(name):
		return null
	var service = _services[name]
	if is_instance_valid(service):
		return service
	_services.erase(name)
	_report_warning("Service '%s' was freed, removing from registry" % name)
	return null
func has_service(name: String) -> bool:
	return _services.has(name) and is_instance_valid(_services[name])
func list_services() -> Array:
	return _services.keys()
func get_localization_manager():
	return get_service("LocalizationManager")
func get_game_state():
	return get_service("GameState")
func get_ai_manager():
	return get_service("AIManager")
func get_asset_registry():
	return get_service("AssetRegistry")
func get_background_loader():
	return get_service("BackgroundLoader")
func get_tutorial_system():
	return get_service("TutorialSystem")
func get_achievement_system():
	return get_service("AchievementSystem")
func get_teammate_system():
	return get_service("TeammateSystem")
func get_notification_system():
	return get_service("NotificationSystem")
func get_tooltip_manager():
	return get_service("TooltipManager")
func get_audio_manager():
	return get_service("AudioManager")
func get_display_manager():
	return get_service("DisplayManager")
func get_font_manager():
	return get_service("FontManager")
func get_event_bus():
	return get_service("EventBus")
func get_error_reporter():
	return get_service("ErrorReporter")
func get_asset_interaction_system():
	return get_service("AssetInteractionSystem")
func get_character_expression_loader():
	return get_service("CharacterExpressionLoader")
func get_trolley_problem_generator():
	return get_service("TrolleyProblemGenerator")
func get_mission_summary_logger():
	return get_service("MissionSummaryLogger")
func get_story_flow_controller():
	return get_service("StoryFlowController")
func get_ollama_client():
	return get_service("OllamaClient")
func _report_warning(message: String, details: Dictionary = { }) -> void:
	var reporter = _services.get("ErrorReporter", null)
	if reporter != null and is_instance_valid(reporter):
		reporter.report_warning("ServiceLocator", message, details)
