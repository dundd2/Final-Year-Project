extends RefCounted
signal event_logged(event: Dictionary)
const MAX_EVENTS: int = GameConstants.Events.MAX_RECENT_EVENTS 
const MAX_EVENT_LOG_SIZE: int = GameConstants.Events.MAX_EVENT_LOG_SIZE 
var _game_state: Node = null
var event_log: Array = [] 
var recent_events: Array = [] 
var current_language: String = "en"
func set_game_state(game_state: Node) -> void:
	_game_state = game_state
	if _game_state:
		current_language = _game_state.current_language
func record_event(event_type: String, details: Dictionary = { }) -> Dictionary:
	print("[DEBUG] EventLogSystem: Recording event type='%s'" % event_type)
	var entry = {
		"type": event_type,
		"details": details,
		"timestamp": Time.get_unix_time_from_system(),
	}
	event_log.append(entry)
	if event_log.size() > MAX_EVENT_LOG_SIZE:
		event_log.remove_at(0)
	var summary_data = _summarize_event(entry)
	var note_data = _build_event_note(event_type, details, summary_data)
	var summary_en := ""
	var summary_zh := ""
	if summary_data is Dictionary:
		summary_en = str(summary_data.get("en", ""))
		summary_zh = str(summary_data.get("zh", summary_en))
	else:
		var summary_str := str(summary_data)
		summary_en = summary_str
		summary_zh = summary_str
	var summary_en_trim := summary_en.strip_edges()
	var summary_zh_trim := summary_zh.strip_edges()
	if not summary_en_trim.is_empty() or not summary_zh_trim.is_empty():
		add_event(summary_en_trim, summary_zh_trim)
	elif not note_data.is_empty():
		var fallback_en := str(note_data.get("en", ""))
		var fallback_zh := str(note_data.get("zh", fallback_en))
		if not fallback_en.strip_edges().is_empty() or not fallback_zh.strip_edges().is_empty():
			add_event(fallback_en, fallback_zh)
	_register_event_note(event_type, details, summary_data, note_data)
	event_logged.emit(entry)
	return entry
func get_recent_records(limit: int = 10) -> Array:
	limit = clamp(limit, 0, event_log.size())
	var start = max(0, event_log.size() - limit)
	return event_log.slice(start, event_log.size())
func clear_event_log() -> void:
	event_log.clear()
func add_event(event_en: String, event_zh: String = "") -> void:
	var en_text := str(event_en)
	var zh_text := str(event_zh) if not event_zh.is_empty() else en_text
	if zh_text.strip_edges().is_empty():
		zh_text = en_text
	if en_text.strip_edges().is_empty():
		en_text = zh_text
	var chosen := en_text if current_language == "en" else zh_text
	if chosen.strip_edges().is_empty():
		return
	recent_events.append(chosen)
	if recent_events.size() > MAX_EVENTS:
		recent_events.remove_at(0)
func get_events_summary() -> String:
	var summary = ""
	for event in recent_events:
		summary += "- " + event + "\n"
	return summary
func clear_events() -> void:
	recent_events.clear()
	clear_event_log()
	if AIManager:
		AIManager.clear_notes()
func get_recent_event_notes(limit: int = 6, lang: String = "en") -> Array:
	if event_log.is_empty():
		return []
	var start: int = max(0, event_log.size() - limit)
	var result: Array = []
	for i in range(start, event_log.size()):
		var entry: Dictionary = event_log[i]
		var entry_type := str(entry.get("type", ""))
		var details: Dictionary = entry.get("details", { })
		var summary_data = _summarize_event(entry)
		var note_data := _build_event_note(entry_type, details, summary_data)
		if note_data.is_empty():
			continue
		var text := ""
		if lang == "en":
			text = str(note_data.get("en", ""))
		else:
			text = str(note_data.get("zh", ""))
		if text.is_empty():
			text = str(note_data.get("en", note_data.get("zh", "")))
		if text.is_empty():
			continue
		result.append(text)
	return result
func _summarize_event(entry: Dictionary) -> Variant:
	if not _game_state:
		return { }
	var event_type = entry.get("type", "unknown")
	var details: Dictionary = entry.get("details", { })
	match event_type:
		"skill_check_failed":
			var skill = str(details.get("skill", "???"))
			var diff = int(details.get("difficulty", 0))
			var roll = int(details.get("roll", 0))
			var total = int(details.get("total", roll))
			var skill_label_en = _game_state._skill_label(skill, "en")
			var skill_label_zh = _game_state._skill_label(skill, "zh")
			var msg_en = LocalizationManager.get_translation("EVENT_SKILL_CHECK_FAILED", "en") % [skill_label_en, diff, roll, total]
			var msg_zh = LocalizationManager.get_translation("EVENT_SKILL_CHECK_FAILED", "zh") % [skill_label_zh, diff, roll, total]
			return {
				"en": msg_en,
				"zh": msg_zh,
			}
		"prayer_made":
			var prayer_text: String = str(details.get("prayer", ""))
			var snippet = prayer_text.substr(0, min(20, prayer_text.length()))
			var ellipsis := "..." if prayer_text.length() > 20 else ""
			var key_en = LocalizationManager.get_translation("EVENT_PRAYER_RECORDED", "en")
			var key_zh = LocalizationManager.get_translation("EVENT_PRAYER_RECORDED", "zh")
			var msg_en = key_en
			var msg_zh = key_zh
			if "%s" in key_en:
				msg_en = key_en % [snippet, ellipsis]
			else:
				print("[DEBUG] Invalid format string for EVENT_PRAYER_RECORDED (en): '%s'" % key_en)
				msg_en = key_en + " " + snippet + ellipsis
			if "%s" in key_zh:
				msg_zh = key_zh % [snippet, ellipsis]
			else:
				print("[DEBUG] Invalid format string for EVENT_PRAYER_RECORDED (zh): '%s'" % key_zh)
				msg_zh = key_zh + " " + snippet + ellipsis
			return {
				"en": msg_en,
				"zh": msg_zh,
			}
		"teammate_interference":
			var teammate = str(details.get("teammate", "unknown"))
			var teammate_label_en = _game_state._teammate_label(teammate, "en")
			var teammate_label_zh = _game_state._teammate_label(teammate, "zh")
			var msg_en = LocalizationManager.get_translation("EVENT_TEAMMATE_INTERFERENCE_WORSE", "en") % teammate_label_en
			var msg_zh = LocalizationManager.get_translation("EVENT_TEAMMATE_INTERFERENCE_WORSE", "zh") % teammate_label_zh
			return {
				"en": msg_en,
				"zh": msg_zh,
			}
		_:
			return { }
func _build_event_note(event_type: String, details: Dictionary, summary_data) -> Dictionary:
	if not _game_state:
		return { }
	var summary_en := ""
	var summary_zh := ""
	if summary_data is Dictionary:
		summary_en = str(summary_data.get("en", ""))
		summary_zh = str(summary_data.get("zh", summary_en))
	else:
		var summary_str := str(summary_data)
		summary_en = summary_str
		summary_zh = summary_str
	match event_type:
		"prayer_made":
			var prayer_text := str(details.get("prayer", ""))
			var snippet_length := 48
			var snippet := prayer_text.substr(0, min(prayer_text.length(), snippet_length))
			if prayer_text.length() > snippet_length:
				snippet += "..."
			var reality := int(details.get("reality_score", _game_state.reality_score))
			var positive := int(details.get("positive_energy", _game_state.positive_energy))
			var key_en = LocalizationManager.get_translation("EVENT_PRAYER_LOGGED", "en")
			var key_zh = LocalizationManager.get_translation("EVENT_PRAYER_LOGGED", "zh")
			var msg_en = key_en
			var msg_zh = key_zh
			if "%s" in key_en or "%d" in key_en:
				msg_en = key_en % [snippet, reality, positive]
			else:
				print("[DEBUG] Invalid format string for EVENT_PRAYER_LOGGED (en): '%s'" % key_en)
				msg_en = key_en + " " + snippet
			if "%s" in key_zh or "%d" in key_zh:
				msg_zh = key_zh % [snippet, reality, positive]
			else:
				print("[DEBUG] Invalid format string for EVENT_PRAYER_LOGGED (zh): '%s'" % key_zh)
				msg_zh = key_zh + " " + snippet
			return {
				"en": msg_en,
				"zh": msg_zh,
				"tags": ["prayer"],
				"importance": 3,
			}
		"skill_check_failed":
			var skill := str(details.get("skill", ""))
			var difficulty := int(details.get("difficulty", 0))
			var roll := int(details.get("roll", 0))
			var total := int(details.get("total", roll))
			var skill_label_en = _game_state._skill_label(skill, "en")
			var skill_label_zh = _game_state._skill_label(skill, "zh")
			var msg_en = LocalizationManager.get_translation("EVENT_SKILL_CHECK_FAILED", "en") % [skill_label_en, difficulty, roll, total]
			var msg_zh = LocalizationManager.get_translation("EVENT_SKILL_CHECK_FAILED", "zh") % [skill_label_zh, difficulty, roll, total]
			return {
				"en": msg_en,
				"zh": msg_zh,
				"tags": ["skill", skill],
				"importance": 2,
			}
		"teammate_interference":
			var teammate_id := str(details.get("teammate", ""))
			var teammate_label_en = _game_state._teammate_label(teammate_id, "en")
			var teammate_label_zh = _game_state._teammate_label(teammate_id, "zh")
			var msg_en = LocalizationManager.get_translation("EVENT_TEAMMATE_INTERFERENCE_ESCALATED", "en") % teammate_label_en
			var msg_zh = LocalizationManager.get_translation("EVENT_TEAMMATE_INTERFERENCE_ESCALATED", "zh") % teammate_label_zh
			return {
				"en": msg_en,
				"zh": msg_zh,
				"tags": ["teammate", teammate_id],
				"importance": 4,
			}
		_:
			if summary_en.strip_edges().is_empty() and summary_zh.strip_edges().is_empty():
				return { }
			return {
				"en": summary_en,
				"zh": summary_zh,
				"tags": ["event"],
				"importance": 1,
			}
func _register_event_note(event_type: String, details: Dictionary, summary_data, note_data: Dictionary = { }) -> void:
	if not AIManager:
		return
	var prepared_data := note_data
	if prepared_data.is_empty():
		prepared_data = _build_event_note(event_type, details, summary_data)
	if prepared_data.is_empty():
		return
	var note_en := str(prepared_data.get("en", ""))
	var note_zh := str(prepared_data.get("zh", ""))
	var tags: Array = prepared_data.get("tags", [])
	var importance := int(prepared_data.get("importance", 2))
	AIManager.register_note_pair(note_en, note_zh, tags, importance, "event:%s" % event_type)
func get_save_data() -> Dictionary:
	return {
		"event_log": event_log.duplicate(true),
		"recent_events": recent_events.duplicate(true),
	}
func load_save_data(data: Dictionary) -> void:
	var log_data = data.get("event_log", [])
	event_log = log_data.duplicate(true) if log_data is Array else []
	var recent_data = data.get("recent_events", [])
	recent_events = recent_data.duplicate(true) if recent_data is Array else []
func reset() -> void:
	event_log.clear()
	recent_events.clear()
