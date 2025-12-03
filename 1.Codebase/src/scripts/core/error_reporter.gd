extends Node
signal error_reported(level: ErrorLevel, context: String, message: String, details: Dictionary)
enum ErrorLevel {
	INFO, 
	WARNING, 
	ERROR, 
	CRITICAL, 
}
var enable_console_logs: bool = true
var enable_user_notifications: bool = true
var log_to_file: bool = false
var log_file_path: String = "user://gda1_error_log.txt"
var error_count: int = 0
var warning_count: int = 0
var critical_count: int = 0
func report_error(context: String, message: String, error_code: int = -1, notify_user: bool = false, details: Dictionary = { }) -> void:
	_report(ErrorLevel.ERROR, context, message, error_code, notify_user, details)
	error_count += 1
func report_warning(context: String, message: String, details: Dictionary = { }) -> void:
	_report(ErrorLevel.WARNING, context, message, -1, false, details)
	warning_count += 1
func report_info(context: String, message: String, details: Dictionary = { }) -> void:
	_report(ErrorLevel.INFO, context, message, -1, false, details)
func report_critical(context: String, message: String, error_code: int = -1, details: Dictionary = { }) -> void:
	_report(ErrorLevel.CRITICAL, context, message, error_code, true, details)
	critical_count += 1
func _report(level: ErrorLevel, context: String, message: String, error_code: int, notify_user: bool, details: Dictionary) -> void:
	var level_str = _get_level_string(level)
	var level_icon = _get_level_icon(level)
	var formatted_msg = "[%s] %s: %s" % [context, level_str, message]
	if error_code >= 0:
		formatted_msg += " (Error code: %d)" % error_code
	if not details.is_empty():
		formatted_msg += " | Details: %s" % JSON.stringify(details)
	if enable_console_logs:
		match level:
			ErrorLevel.INFO:
				print(formatted_msg)
			ErrorLevel.WARNING:
				push_warning(formatted_msg)
			ErrorLevel.ERROR, ErrorLevel.CRITICAL:
				push_error(formatted_msg)
	if log_to_file:
		_log_to_file(level, context, message, error_code, details)
	if enable_user_notifications and (notify_user or level == ErrorLevel.CRITICAL):
		_notify_user(level_icon, context, message)
	error_reported.emit(level, context, message, details)
func _get_level_string(level: ErrorLevel) -> String:
	match level:
		ErrorLevel.INFO:
			return "INFO"
		ErrorLevel.WARNING:
			return "WARNING"
		ErrorLevel.ERROR:
			return "ERROR"
		ErrorLevel.CRITICAL:
			return "CRITICAL"
	return "UNKNOWN"
func _get_level_icon(level: ErrorLevel) -> String:
	match level:
		ErrorLevel.INFO:
			return "[i]"
		ErrorLevel.WARNING:
			return "[!]"
		ErrorLevel.ERROR:
			return "[x]"
		ErrorLevel.CRITICAL:
			return "[!!]"
	return "[?]"
func _get_service_locator() -> Node:
	if has_node("/root/ServiceLocator"):
		return get_node("/root/ServiceLocator")
	return null
func _notify_user(icon: String, context: String, message: String) -> void:
	var sl = _get_service_locator()
	var notification_system = null
	if sl and sl.has_method("get_notification_system"):
		notification_system = sl.call("get_notification_system")
	if notification_system:
		var user_message = "%s %s: %s" % [icon, context, message]
		var lang: String = "en"
		var game_state = null
		if sl and sl.has_method("get_game_state"):
			game_state = sl.call("get_game_state")
		if game_state:
			var resolved_lang = game_state.get("current_language")
			if typeof(resolved_lang) == TYPE_STRING and not resolved_lang.is_empty():
				lang = resolved_lang
		if lang == "zh":
			user_message = _translate_to_chinese(icon, context, message)
		if notification_system.has_method("show_error"):
			notification_system.show_error(user_message)
		elif notification_system.has_method("show_notification"):
			notification_system.show_notification(user_message, "error")
func _translate_to_chinese(icon: String, context: String, message: String) -> String:
	var sl = _get_service_locator()
	var localization_manager = null
	if sl and sl.has_method("get_localization_manager"):
		localization_manager = sl.call("get_localization_manager")
	if not localization_manager:
		return "%s %s: %s" % [icon, context, message]
	var context_key := "ERROR_CONTEXT_" + context.replace(" ", "")
	var translated_context: String = localization_manager.get_translation(context_key, "zh")
	if translated_context.is_empty():
		translated_context = context
	return "%s %s: %s" % [icon, translated_context, message]
func _log_to_file(level: ErrorLevel, context: String, message: String, error_code: int, details: Dictionary) -> void:
	var file = FileAccess.open(log_file_path, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		var timestamp = Time.get_datetime_string_from_system()
		var level_str = _get_level_string(level)
		var log_entry = "[%s] [%s] %s: %s" % [timestamp, level_str, context, message]
		if error_code >= 0:
			log_entry += " (Error code: %d)" % error_code
		if not details.is_empty():
			log_entry += " | Details: %s" % JSON.stringify(details)
		file.store_line(log_entry)
		file.close()
func get_statistics() -> Dictionary:
	return {
		"errors": error_count,
		"warnings": warning_count,
		"critical": critical_count,
		"total": error_count + warning_count + critical_count,
	}
func reset_statistics() -> void:
	error_count = 0
	warning_count = 0
	critical_count = 0
func clear_log_file() -> bool:
	if FileAccess.file_exists(log_file_path):
		var dir = DirAccess.open("user://")
		if dir:
			return dir.remove(log_file_path.get_file()) == OK
	return true
