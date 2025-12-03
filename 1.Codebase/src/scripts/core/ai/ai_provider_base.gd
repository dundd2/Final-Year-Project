extends RefCounted
class_name AIProviderBase
signal request_started()
signal request_completed(success: bool)
signal request_progress(update: Dictionary)
signal request_error(message: String)
var provider_name: String = "BaseProvider"
var is_requesting: bool = false
const ERROR_CONTEXT := "AIProviderBase"
func send_request(_messages: Array, _callback: Callable, _options: Dictionary = { }) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, "send_request must be implemented by subclass")
func cancel_request() -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, "cancel_request must be implemented by subclass")
func is_configured() -> bool:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, "is_configured must be implemented by subclass")
	return false
func get_configuration() -> Dictionary:
	return { }
func apply_configuration(_config: Dictionary) -> void:
	pass
func _emit_error(message: String) -> void:
	request_error.emit(message)
func _emit_progress(update: Dictionary) -> void:
	var progress_data := update.duplicate(true)
	progress_data["provider"] = provider_name
	request_progress.emit(progress_data)
