extends RefCounted
class_name AIMemoryStore
const LONG_TERM_SUMMARY_LIMIT := 16
const MAX_NOTES := 32
const MAX_NOTES_PER_PROMPT := 8
const SHORT_TERM_WINDOW := 5
var memory_summary_threshold: int = 24
var memory_full_entries: int = 6
var max_memory_items: int = 120
var story_memory: Array = []
var long_term_summaries: Array = []
var notes_register: Array = []
func add_entry(role: String, content: String, extra_data: Dictionary = {}) -> void:
	var entry := {
		"role": role,
		"content": content,
		"timestamp": Time.get_unix_time_from_system(),
	}
	if extra_data.has("thought_signature"):
		entry["thought_signature"] = extra_data["thought_signature"]
	print("[AIMemoryStore] Adding entry. Role: ", role, ", Content length: ", content.length())
	story_memory.append(entry)
	_update_long_term_memory()
	apply_settings()
func apply_settings() -> void:
	max_memory_items = clamp(max_memory_items, 10, 2000)
	memory_full_entries = clamp(memory_full_entries, 1, min(50, max_memory_items))
	memory_summary_threshold = clamp(memory_summary_threshold, memory_full_entries, max_memory_items)
	while story_memory.size() > max_memory_items:
		story_memory.remove_at(0)
func clear_all() -> void:
	story_memory.clear()
	long_term_summaries.clear()
	notes_register.clear()
func clear_notes() -> void:
	notes_register.clear()
func get_short_term_memory() -> Array:
	if story_memory.is_empty():
		return []
	var keep: int = max(SHORT_TERM_WINDOW, memory_full_entries * 2)
	keep = min(keep, story_memory.size())
	return story_memory.slice(story_memory.size() - keep, story_memory.size())
func get_long_term_context(language: String) -> Array:
	if long_term_summaries.is_empty():
		return []
	var lines: Array = []
	var long_term_header := "長期連續性備忘（由舊到新）："
	if language == "en":
		long_term_header = "Long-term continuity notes (oldest to newest):"
	lines.append(long_term_header)
	var start_index = max(0, long_term_summaries.size() - LONG_TERM_SUMMARY_LIMIT)
	for i in range(start_index, long_term_summaries.size()):
		var entry: Dictionary = long_term_summaries[i]
		var localized = _localize_generic(entry, language)
		if localized.is_empty():
			continue
		lines.append("- " + localized)
	return [{ "role": "system", "content": "\n".join(lines) }]
func get_notes_context(language: String) -> Array:
	if notes_register.is_empty():
		return []
	var sorted_notes: Array = notes_register.duplicate()
	sorted_notes.sort_custom(Callable(self, "_compare_notes"))
	var limit: int = min(MAX_NOTES_PER_PROMPT, sorted_notes.size())
	var lines: Array = []
	var notes_header := "持久備忘與限制："
	if language == "en":
		notes_header = "Persistent facts & constraints:"
	lines.append(notes_header)
	for i in range(limit):
		var note: Dictionary = sorted_notes[i]
		var localized = _localize_note(note, language)
		if localized.is_empty():
			continue
		lines.append("- " + localized)
	return [{ "role": "system", "content": "\n".join(lines) }]
func get_long_term_lines(language: String, limit: int = LONG_TERM_SUMMARY_LIMIT) -> Array:
	var lines: Array = []
	if long_term_summaries.is_empty():
		return lines
	var start_index = max(0, long_term_summaries.size() - limit)
	for i in range(start_index, long_term_summaries.size()):
		var entry: Dictionary = long_term_summaries[i]
		var localized = _localize_generic(entry, language)
		if localized.is_empty():
			continue
		lines.append(localized)
	return lines
func get_notes_lines(language: String, limit: int = MAX_NOTES) -> Array:
	var sorted: Array = notes_register.duplicate(true)
	sorted.sort_custom(Callable(self, "_compare_notes"))
	var take: int = min(limit, sorted.size())
	var lines: Array = []
	for i in range(take):
		var localized = _localize_note(sorted[i], language)
		if localized.is_empty():
			continue
		lines.append(localized)
	return lines
func format_memory_section() -> String:
	if story_memory.is_empty():
		return "Recent story log: (no prior events yet.)"
	var total = story_memory.size()
	var lines: Array = []
	lines.append("Recent story log (total %d entries, limit %d)." % [total, max_memory_items])
	var full_entries = min(memory_full_entries, total)
	lines.append("Newest entries (most recent first):")
	for i in range(total - 1, total - full_entries - 1, -1):
		var ordinal = i + 1
		var relative = total - i
		var entry = story_memory[i]
		lines.append("- #%d (latest-%d) [%s]: %s" % [ordinal, relative, entry["role"], entry["content"]])
	var older_count = total - full_entries
	if older_count > 0:
		if older_count <= memory_summary_threshold:
			lines.append("Earlier entries (oldest first):")
			for j in range(older_count):
				var entry = story_memory[j]
				lines.append("- #%d [%s]: %s" % [j + 1, entry["role"], entry["content"]])
		else:
			lines.append("Historical summary (#1 to #%d):" % (total - full_entries))
			lines.append(_summarize_entries(story_memory.slice(0, total - full_entries), 1))
	return "\n".join(lines)
func summarize_memory() -> String:
	if story_memory.is_empty():
		return "Story just started"
	var summary = "Story summary (total %d events):\n" % story_memory.size()
	summary += _summarize_entries(story_memory, 1)
	return summary
func summarize_entries(entries: Array, start_index: int) -> String:
	return _summarize_entries(entries, start_index)
func register_note_pair(text_en: String, text_zh: String = "", tags: Array = [], importance: int = 1, source: String = "") -> void:
	var clean_en := text_en.strip_edges()
	var clean_zh := text_zh.strip_edges()
	if clean_en.is_empty() and clean_zh.is_empty():
		return
	var inferred_language := ""
	if clean_en.is_empty() and not clean_zh.is_empty():
		inferred_language = "zh"
	elif clean_zh.is_empty() and not clean_en.is_empty():
		inferred_language = "en"
	var entry := {
		"text_en": clean_en,
		"text_zh": clean_zh,
		"language": inferred_language,
		"tags": tags.duplicate(),
		"importance": clamp(importance, 1, 5),
		"source": source,
		"timestamp": Time.get_unix_time_from_system(),
	}
	for i in range(notes_register.size()):
		if _notes_match(notes_register[i], entry):
			notes_register[i] = _merge_notes(notes_register[i], entry)
			_enforce_note_limit()
			return
	notes_register.append(entry)
	_enforce_note_limit()
func build_state_payload() -> Dictionary:
	return {
		"story_memory": story_memory.duplicate(true),
		"long_term_summaries": long_term_summaries.duplicate(true),
		"notes_register": notes_register.duplicate(true),
		"memory_summary_threshold": memory_summary_threshold,
		"memory_full_entries": memory_full_entries,
		"max_memory_items": max_memory_items,
	}
func get_state() -> Dictionary:
	return build_state_payload()
func restore_from_payload(state: Dictionary) -> void:
	if state.is_empty():
		return
	story_memory = []
	var memory: Array = state.get("story_memory", [])
	for entry in memory:
		if entry is Dictionary and entry.has("role") and entry.has("content"):
			var restored_entry = {
				"role": str(entry.get("role", "user")),
				"content": str(entry.get("content", "")),
			}
			if entry.has("thought_signature"):
				restored_entry["thought_signature"] = str(entry["thought_signature"])
			story_memory.append(restored_entry)
	long_term_summaries = []
	var summaries: Array = state.get("long_term_summaries", [])
	for summary in summaries:
		if summary is Dictionary and summary.has("text"):
			long_term_summaries.append(
				{
					"text": str(summary.get("text", "")),
					"language": str(summary.get("language", "")),
					"count": int(summary.get("count", 0)),
					"timestamp": int(summary.get("timestamp", 0)),
				},
			)
	notes_register = []
	var saved_notes: Array = state.get("notes_register", [])
	for note in saved_notes:
		if note is Dictionary:
			notes_register.append(
				{
					"text_en": str(note.get("text_en", "")),
					"text_zh": str(note.get("text_zh", "")),
					"language": str(note.get("language", "")),
					"tags": note.get("tags", []),
					"importance": int(note.get("importance", 1)),
					"source": str(note.get("source", "")),
					"timestamp": int(note.get("timestamp", 0)),
				},
			)
	memory_summary_threshold = int(state.get("memory_summary_threshold", memory_summary_threshold))
	memory_full_entries = int(state.get("memory_full_entries", memory_full_entries))
	max_memory_items = int(state.get("max_memory_items", max_memory_items))
	_enforce_note_limit()
	apply_settings()
func set_state(state: Dictionary) -> void:
	restore_from_payload(state)
func get_note_count() -> int:
	return notes_register.size()
func _update_long_term_memory() -> void:
	var total: int = story_memory.size()
	if total <= memory_summary_threshold:
		return
	var preserve: int = max(2, memory_full_entries * 2)
	preserve = min(preserve, total)
	var historical_count: int = total - preserve
	if historical_count <= 0:
		return
	var historical_entries: Array = story_memory.slice(0, historical_count)
	var summary_text: String = _summarize_entries(historical_entries, 1)
	if summary_text.strip_edges().is_empty():
		summary_text = "Condensed earlier exchanges (#1 - #%d)." % historical_count
	var lang := "en"
	if GameState:
		lang = GameState.current_language
	long_term_summaries.append(
		{
			"text": summary_text,
			"language": lang,
			"count": historical_count,
			"timestamp": Time.get_unix_time_from_system(),
		},
	)
	while long_term_summaries.size() > LONG_TERM_SUMMARY_LIMIT:
		long_term_summaries.remove_at(0)
	story_memory = story_memory.slice(historical_count, total)
func _notes_match(existing: Dictionary, incoming: Dictionary) -> bool:
	var en_existing := str(existing.get("text_en", ""))
	var zh_existing := str(existing.get("text_zh", ""))
	var en_incoming := str(incoming.get("text_en", ""))
	var zh_incoming := str(incoming.get("text_zh", ""))
	if not en_existing.is_empty() and not en_incoming.is_empty():
		if en_existing == en_incoming:
			return true
	if not zh_existing.is_empty() and not zh_incoming.is_empty():
		if zh_existing == zh_incoming:
			return true
	return false
func _merge_notes(existing: Dictionary, incoming: Dictionary) -> Dictionary:
	var merged := existing.duplicate(true)
	if merged.get("text_en", "").strip_edges().is_empty() and not incoming.get("text_en", "").strip_edges().is_empty():
		merged["text_en"] = incoming["text_en"]
	if merged.get("text_zh", "").strip_edges().is_empty() and not incoming.get("text_zh", "").strip_edges().is_empty():
		merged["text_zh"] = incoming["text_zh"]
	merged["importance"] = max(int(existing.get("importance", 1)), int(incoming.get("importance", 1)))
	var tags_existing: Array = merged.get("tags", [])
	var tags_incoming: Array = incoming.get("tags", [])
	for tag in tags_incoming:
		if not tags_existing.has(tag):
			tags_existing.append(tag)
	merged["tags"] = tags_existing
	merged["timestamp"] = max(int(existing.get("timestamp", 0)), int(incoming.get("timestamp", 0)))
	if merged.get("source", "") == "":
		merged["source"] = incoming.get("source", "")
	return merged
func _enforce_note_limit() -> void:
	if notes_register.size() <= MAX_NOTES:
		return
	notes_register.sort_custom(Callable(self, "_compare_notes"))
	while notes_register.size() > MAX_NOTES:
		notes_register.pop_back()
func _compare_notes(a, b) -> bool:
	var importance_a := int(a.get("importance", 1))
	var importance_b := int(b.get("importance", 1))
	if importance_a == importance_b:
		return int(a.get("timestamp", 0)) > int(b.get("timestamp", 0))
	return importance_a > importance_b
func _localize_note(note: Dictionary, language: String) -> String:
	var text_en := str(note.get("text_en", ""))
	var text_zh := str(note.get("text_zh", ""))
	if language == "en":
		if not text_en.is_empty():
			return text_en
		if not text_zh.is_empty():
			return "[zh] " + text_zh
	else:
		if not text_zh.is_empty():
			return text_zh
		if not text_en.is_empty():
			return "[en] " + text_en
	return ""
func _localize_generic(entry: Dictionary, language: String) -> String:
	var lang := str(entry.get("language", language))
	var text := str(entry.get("text", ""))
	if text.is_empty():
		return ""
	if lang == language or lang == "":
		return text
	return "[%s] %s" % [lang, text]
func _summarize_entries(entries: Array, start_index: int) -> String:
	if entries.is_empty():
		return "- (no earlier events recorded)"
	var total = entries.size()
	var sample_indices: Array = [0, total - 1]
	if total > 2:
		sample_indices.append(total / 2)
	if total > 4:
		sample_indices.append(total / 4)
		sample_indices.append(total - max(1, total / 4) - 1)
	var unique: Array = []
	for idx in sample_indices:
		idx = clamp(int(idx), 0, total - 1)
		if idx not in unique:
			unique.append(idx)
	unique.sort()
	var lines: Array = []
	for idx in unique:
		var absolute_index = start_index + idx
		var tag = "Middle"
		if idx == 0:
			tag = "Earliest"
		elif idx == total - 1:
			tag = "Latest summary"
		elif idx < total / 2:
			tag = "Early"
		elif idx > total / 2:
			tag = "Late"
		var entry = entries[idx]
		lines.append("- #%d (%s) [%s]: %s" % [absolute_index, tag, entry["role"], entry["content"]])
	if total > unique.size():
		lines.append("- ... condensed %d early events." % total)
	return "\n".join(lines)
