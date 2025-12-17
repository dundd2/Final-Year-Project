class_name BuildSecrets
extends RefCounted
const GEMINI_API_KEY = ""

static func get_gemini_api_key() -> String:
	var key := String(GEMINI_API_KEY).strip_edges()
	if not key.is_empty():
		return key
	if not _is_web_runtime():
		var env_key := String(OS.get_environment("GEMINI_API_KEY")).strip_edges()
		if not env_key.is_empty():
			return env_key
	return ""

static func _is_web_runtime() -> bool:
	var normalized_name := OS.get_name().to_lower()
	if normalized_name == "html5":
		return true
	for feature in ["web", "html5", "emscripten", "javascript"]:
		if OS.has_feature(feature):
			return true
	return false
