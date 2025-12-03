extends RefCounted
class_name ErrorReporterBridge
const DEFAULT_CONTEXT := "General"
static func report_error(
		context: String,
		message: String,
		error_code: int = -1,
		notify_user: bool = false,
		details: Dictionary = { },
) -> void:
	var reporter: Variant = _get_reporter()
	if reporter:
		reporter.report_error(context, message, error_code, notify_user, details)
		return
	_push_error(context, message)
static func report_warning(
		context: String,
		message: String,
		details: Dictionary = { },
) -> void:
	var reporter: Variant = _get_reporter()
	if reporter:
		reporter.report_warning(context, message, details)
		return
	_push_warning(context, message)
static func report_info(
		context: String,
		message: String,
		details: Dictionary = { },
) -> void:
	var reporter: Variant = _get_reporter()
	if reporter:
		reporter.report_info(context, message, details)
		return
	print("[%s] %s" % [context, message])
static func report_critical(
		context: String,
		message: String,
		error_code: int = -1,
		details: Dictionary = { },
) -> void:
	var reporter: Variant = _get_reporter()
	if reporter:
		reporter.report_critical(context, message, error_code, details)
		return
	_push_error(context, message)
static func report_raw_error(message: String) -> void:
	var reporter: Variant = _get_reporter()
	if reporter:
		reporter.report_error(DEFAULT_CONTEXT, message)
		return
	push_error(message)
static func _get_reporter() -> Variant:
	var main_loop = Engine.get_main_loop()
	if not main_loop:
		return null
	if main_loop is SceneTree:
		var root = main_loop.root
		if root.has_node("ErrorReporter"):
			return root.get_node("ErrorReporter")
		if root.has_node("ServiceLocator"):
			var sl = root.get_node("ServiceLocator")
			if sl.has_method("get_error_reporter"):
				return sl.call("get_error_reporter")
	return null
static func _push_error(context: String, message: String) -> void:
	push_error("[%s] %s" % [context, message])
static func _push_warning(context: String, message: String) -> void:
	push_warning("[%s] %s" % [context, message])
