extends RefCounted
const ERROR_CONTEXT := "StoryUIHelper"
static func sanitize_story_text(content: String) -> String:
	if content == null or content.is_empty():
		return ""
	var cleaned := content
	cleaned = cleaned.replace("\\n", "\n")
	cleaned = cleaned.replace("\\_", "_")
	cleaned = cleaned.replace("\\*", "*")
	var code_block_regex := RegEx.new()
	code_block_regex.compile("```[\\s\\S]*?```")
	cleaned = code_block_regex.sub(cleaned, "", true)
	var inline_code_regex := RegEx.new()
	inline_code_regex.compile("`([^`]+)`")
	cleaned = inline_code_regex.sub(cleaned, "$1", true)
	var json_regex := RegEx.new()
	json_regex.compile("\\{\\s*\"[^\"]+\"\\s*:\\s*[^}]+,\\s*\"[^\"]+\"\\s*:[^}]+\\}")
	cleaned = json_regex.sub(cleaned, "", true)
	var bold_regex := RegEx.new()
	bold_regex.compile("\\*\\*([^*]+)\\*\\*|__([^_]+)__")
	var bold_matches := bold_regex.search_all(cleaned)
	for match_result in bold_matches:
		var matched_text := match_result.get_string(1) if match_result.get_string(1) != "" else match_result.get_string(2)
		cleaned = cleaned.replace(match_result.get_string(), "[b]" + matched_text + "[/b]")
	var italic_regex := RegEx.new()
	italic_regex.compile("(?<!\\*)\\*([^*]+)\\*(?!\\*)|(?<!_)_([^_]+)_(?!_)")
	var italic_matches := italic_regex.search_all(cleaned)
	for match_result in italic_matches:
		var matched_text := match_result.get_string(1) if match_result.get_string(1) != "" else match_result.get_string(2)
		if matched_text != "":
			cleaned = cleaned.replace(match_result.get_string(), "[i]" + matched_text + "[/i]")
	var header_regex := RegEx.new()
	header_regex.compile("(?m)^##\\s+(.+)$")
	cleaned = header_regex.sub(cleaned, "[font_size=24]$1[/font_size]", true)
	var whitespace_regex := RegEx.new()
	whitespace_regex.compile("\\n{3,}")
	cleaned = whitespace_regex.sub(cleaned, "\n\n", true)
	cleaned = cleaned.strip_edges()
	cleaned = _balance_bbcode_tags(cleaned)
	return cleaned
static func _balance_bbcode_tags(text: String) -> String:
	if text.is_empty():
		return text
	var tag_pairs := {
		"b": 0,
		"i": 0,
		"u": 0,
		"s": 0,
		"code": 0,
		"center": 0,
		"right": 0,
		"font_size": 0,
	}
	var tag_regex := RegEx.new()
	if tag_regex.compile("\\[(/?)([a-z_]+)(?:=[^\\]]*)?\\]") == OK:
		var matches_raw = tag_regex.search_all(text)
		var matches: Array = matches_raw if matches_raw != null else []
		for match_result in matches:
			var is_closing: bool = match_result.get_string(1) == "/"
			var tag_name: String = match_result.get_string(2)
			if tag_pairs.has(tag_name):
				if is_closing:
					tag_pairs[tag_name] -= 1
				else:
					tag_pairs[tag_name] += 1
	var result := text
	for tag_name in tag_pairs.keys():
		var count: int = int(tag_pairs[tag_name])
		if count > 0:
			for i in range(count):
				result += "[/" + tag_name + "]"
			print("[Story UI Helper] Auto-closed %d unclosed [%s] tag(s)" % [count, tag_name])
		elif count < 0:
			ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Found %d excess closing [/%s] tag(s) - may cause rendering issues" % [-count, tag_name], { "count": -count, "tag": tag_name })
	return result
static func variant_to_bool(value) -> bool:
	if value is bool:
		return value
	elif value is String:
		return value.to_lower() in ["true", "1", "yes"]
	elif value is int or value is float:
		return value != 0
	return false
static func variant_to_string(value) -> String:
	if value == null:
		return ""
	return str(value)
static func parse_ai_payload(raw_text: String) -> Dictionary:
	var structured: Dictionary = {
		"raw": raw_text,
		"story": "",
		"choices": [],
		"metadata": { },
		"scene_directives": { },
		"data": { },
	}
	if raw_text == null:
		return structured
	var candidates := _collect_json_segments(raw_text)
	for candidate_text in candidates:
		var parser := JSON.new()
		var parse_error := parser.parse(candidate_text)
		if parse_error != OK:
			continue
		var data = parser.get_data()
		if not data is Dictionary:
			continue
		var dict_data: Dictionary = data
		structured["data"] = dict_data.duplicate(true)
		_populate_structured_payload(structured, dict_data)
		return structured
	structured["story"] = raw_text.strip_edges()
	return structured
static func _collect_json_segments(raw_text: String) -> Array:
	var segments: Array = []
	if raw_text == null:
		return segments
	var trimmed := raw_text.strip_edges()
	if trimmed.is_empty():
		return segments
	segments.append(trimmed)
	var code_regex := RegEx.new()
	if code_regex.compile("```(?:json)?\\s*([\\s\\S]+?)```") == OK:
		var code_matches := code_regex.search_all(raw_text)
		for match in code_matches:
			var block := match.get_string(1).strip_edges()
			if not block.is_empty():
				segments.append(block)
	var marker_regex := RegEx.new()
	if marker_regex.compile("\\[SCENE_DIRECTIVES\\]([\\s\\S]+?)\\[/SCENE_DIRECTIVES\\]") == OK:
		var marker_matches := marker_regex.search_all(raw_text)
		for match in marker_matches:
			var marker_block := match.get_string(1).strip_edges()
			if not marker_block.is_empty():
				segments.append(marker_block)
	var first_brace := raw_text.find("{")
	var last_brace := raw_text.rfind("}")
	if first_brace != -1 and last_brace != -1 and last_brace > first_brace:
		var brace_block := raw_text.substr(first_brace, last_brace - first_brace + 1).strip_edges()
		if not brace_block.is_empty():
			segments.append(brace_block)
	var unique_segments: Array = []
	var seen := { }
	for entry in segments:
		if seen.has(entry):
			continue
		seen[entry] = true
		unique_segments.append(entry)
	return unique_segments
static func _populate_structured_payload(structured: Dictionary, data: Dictionary) -> void:
	var story_text := _coerce_story_value_to_string(data)
	if story_text.is_empty():
		var story_keys := ["story", "story_text", "main_text", "narrative", "body", "text"]
		for key in story_keys:
			if not data.has(key):
				continue
			story_text = _coerce_story_value_to_string(data[key])
			if not story_text.is_empty():
				break
	structured["story"] = story_text
	var metadata := { }
	if data.has("metadata") and data["metadata"] is Dictionary:
		metadata = (data["metadata"] as Dictionary).duplicate(true)
	structured["metadata"] = metadata
	var directives := _extract_scene_directives(data)
	if directives.is_empty() and metadata is Dictionary:
		directives = _extract_scene_directives(metadata)
	structured["scene_directives"] = directives
	var choices := _extract_choices_from_data(data)
	if choices.is_empty() and metadata is Dictionary:
		choices = _extract_choices_from_data(metadata)
	structured["choices"] = choices
	if metadata is Dictionary:
		var location_keys := ["location", "current_location", "scene_location", "locale"]
		for key in location_keys:
			if data.has(key):
				var location_value := _coerce_story_value_to_string(data[key])
				if not location_value.is_empty():
					metadata["location"] = location_value
					break
		if not metadata.has("background") and data.has("background"):
			metadata["background"] = _coerce_story_value_to_string(data["background"])
static func _coerce_story_value_to_string(value) -> String:
	if value == null:
		return ""
	if value is String:
		return String(value).strip_edges()
	if value is Array:
		var parts: Array = []
		for entry in value:
			var piece := _coerce_story_value_to_string(entry)
			if not piece.is_empty():
				parts.append(piece)
		return "\n\n".join(parts) if parts.size() > 0 else ""
	if value is Dictionary:
		var dict_value: Dictionary = value
		var preferred_keys := ["story", "text", "content", "body", "main", "narrative", "paragraph"]
		for key in preferred_keys:
			if dict_value.has(key):
				var inner := _coerce_story_value_to_string(dict_value[key])
				if not inner.is_empty():
					return inner
	return ""
static func _extract_scene_directives(data: Dictionary) -> Dictionary:
	var result: Dictionary = { }
	if data.has("scene_directives") and data["scene_directives"] is Dictionary:
		return (data["scene_directives"] as Dictionary).duplicate(true)
	if data.has("sceneDirectives") and data["sceneDirectives"] is Dictionary:
		return (data["sceneDirectives"] as Dictionary).duplicate(true)
	if data.has("visuals") and data["visuals"] is Dictionary:
		var visuals: Dictionary = data["visuals"]
		if visuals.has("scene") and visuals["scene"] is Dictionary:
			result["scene"] = visuals["scene"]
		if visuals.has("characters") and visuals["characters"] is Dictionary:
			result["characters"] = visuals["characters"]
		if visuals.has("assets") and visuals["assets"] is Array:
			result["assets"] = visuals["assets"]
	var keys := ["scene", "characters", "assets"]
	for key in keys:
		if not data.has(key):
			continue
		var entry = data[key]
		if entry == null:
			continue
		if key == "assets" and entry is Array:
			result["assets"] = entry
		elif entry is Dictionary:
			result[key] = entry
	return result
static func _extract_choices_from_data(data: Dictionary) -> Array:
	var choice_keys := ["choices", "options", "player_choices", "decision_points", "decisionOptions"]
	for key in choice_keys:
		if not data.has(key):
			continue
		var choice_value = data[key]
		if not choice_value is Array:
			continue
		var normalised: Array = []
		for element in choice_value:
			if element is Dictionary:
				var choice_dict: Dictionary = element.duplicate(true)
				if not choice_dict.has("text"):
					var text := ""
					for text_key in ["label", "title", "description", "summary"]:
						if choice_dict.has(text_key):
							text = _coerce_story_value_to_string(choice_dict[text_key])
							if not text.is_empty():
								break
					if not text.is_empty():
						choice_dict["text"] = text
				if choice_dict.get("text", "").strip_edges().is_empty():
					continue
				normalised.append(choice_dict)
			elif element is String:
				var text_value := String(element).strip_edges()
				if text_value.is_empty():
					continue
				normalised.append({ "text": text_value })
		if normalised.size() > 0:
			return normalised
	return []
static func parse_progress_update(update: Dictionary) -> Dictionary:
	var normalized: Dictionary = {
		"phase": String(update.get("phase", "")),
		"message": String(update.get("message", "")),
		"percent": float(update.get("percent", -1.0)),
	}
	if update.has("progress") and update["progress"] is Dictionary:
		var nested: Dictionary = update["progress"]
		normalized["percent"] = float(nested.get("percent", normalized["percent"]))
		normalized["message"] = String(nested.get("message", normalized["message"]))
		normalized["phase"] = String(nested.get("phase", normalized["phase"]))
	normalized["percent"] = clamp(normalized["percent"], -1.0, 100.0)
	return normalized
static func compose_night_sequence(reflection_text: String, teacher_text: String, honeymoon_text: String) -> String:
	var parts := []
	if not reflection_text.is_empty():
		parts.append("## 瘛勗??n" + reflection_text.strip_edges())
	if not teacher_text.is_empty():
		parts.append("## ?葦??隤沔n" + teacher_text.strip_edges())
	if not honeymoon_text.is_empty():
		parts.append("## ????餈湧\n" + honeymoon_text.strip_edges())
	return "\n\n".join(parts)
static func get_template_label(template_type: String, lang: String) -> String:
	const LABELS := {
		"classic": {
			"en": "Classic Dilemma",
			"zh": "蝬?啣?",
		},
		"sacrifice": {
			"en": "Personal Sacrifice",
			"zh": "?犖?抒",
		},
		"deception": {
			"en": "Noble Deception",
			"zh": "??雓?",
		},
		"resource": {
			"en": "Resource Allocation",
			"zh": "鞈???",
		},
		"authority": {
			"en": "Authority Challenge",
			"zh": "甈??",
		},
	}
	if template_type in LABELS and lang in LABELS[template_type]:
		return LABELS[template_type][lang]
	return template_type.capitalize()
static func find_choice_by_keyword(choices: Array, text: String) -> int:
	var lower_text := text.to_lower()
	if "pray" in lower_text or "prayer" in lower_text or "蟡曲" in lower_text:
		return -2 
	for i in range(choices.size()):
		var choice_text: String = choices[i].get("text", "")
		if choice_text.is_empty():
			continue
		var choice_lower := choice_text.to_lower()
		var words := lower_text.split(" ")
		for word in words:
			if word.length() >= 3 and word in choice_lower:
				return i
	return -1 
static func create_gradient_panel(color_top: Color, color_bottom: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color_top
	style.set_border_width_all(0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	var gradient := Gradient.new()
	gradient.add_point(0.0, color_top)
	gradient.add_point(1.0, color_bottom)
	return style
