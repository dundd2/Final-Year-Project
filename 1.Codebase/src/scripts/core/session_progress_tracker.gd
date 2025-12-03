extends RefCounted
class_name SessionProgressTracker
var current_mission: int = 0
var complaint_counter: int = 0
var missions_completed: int = 0
var game_phase: String = GameConstants.GamePhase.HONEYMOON
var honeymoon_charges: int = 0
var metadata: Dictionary = { }
var current_language: String = "en"
var is_session_active: bool = false
func reset() -> void:
	current_mission = 0
	complaint_counter = 0
	missions_completed = 0
	game_phase = GameConstants.GamePhase.HONEYMOON
	honeymoon_charges = 0
	metadata.clear()
	is_session_active = false
func get_save_payload() -> Dictionary:
	return {
		"current_mission": current_mission,
		"complaint_counter": complaint_counter,
		"missions_completed": missions_completed,
		"game_phase": game_phase,
		"honeymoon_charges": honeymoon_charges,
		"metadata": metadata.duplicate(true),
		"current_language": current_language,
		"is_session_active": is_session_active,
	}
func apply_save_payload(data: Dictionary) -> void:
	current_mission = data.get("current_mission", current_mission)
	complaint_counter = data.get("complaint_counter", complaint_counter)
	missions_completed = data.get("missions_completed", missions_completed)
	game_phase = data.get("game_phase", game_phase)
	honeymoon_charges = data.get("honeymoon_charges", honeymoon_charges)
	is_session_active = data.get("is_session_active", is_session_active)
	var meta_data = data.get("metadata", { })
	metadata = meta_data.duplicate(true) if meta_data is Dictionary else { }
	current_language = data.get("current_language", current_language)
func mark_session_active(active: bool) -> void:
	is_session_active = active
func set_language(lang: String) -> void:
	current_language = lang if not lang.is_empty() else current_language
func delete_metadata_keys(keys: Array) -> Array:
	var removed: Array = []
	for key in keys:
		if metadata.has(key):
			metadata.erase(key)
			removed.append(key)
	return removed
