extends RefCounted
var _marker_regex: RegEx = null
var _code_block_regex: RegEx = null
const ERROR_CONTEXT := "SceneDirectivesParser"
const SCENE_DIRECTIVE_PATTERN := "\\[SCENE_DIRECTIVES\\]([\\s\\S]+?)\\[/SCENE_DIRECTIVES\\]"
const CODE_BLOCK_PATTERN := "```(?:json)?\\s*([\\s\\S]+?)```"
const STORY_TEXT_PRIORITY_KEYS := [
	"story",
	"story_text",
	"main_text",
	"narrative",
	"text",
	"body",
	"content",
	"message",
]
func _init() -> void:
	_marker_regex = RegEx.new()
	if _marker_regex.compile(SCENE_DIRECTIVE_PATTERN) != OK:
		ErrorReporterBridge.report_error(ERROR_CONTEXT, "Failed to compile marker regex")
		_marker_regex = null
	_code_block_regex = RegEx.new()
	if _code_block_regex.compile(CODE_BLOCK_PATTERN) != OK:
		ErrorReporterBridge.report_error(ERROR_CONTEXT, "Failed to compile code block regex")
		_code_block_regex = null
func parse_scene_directives(response_text: String) -> Dictionary:
	var directives: Dictionary = { }
	if _marker_regex:
		var marker_matches := _marker_regex.search_all(response_text)
		if marker_matches:
			for m in marker_matches:
				var block: String = String(m.get_string(1)).strip_edges()
				if block.is_empty():
					continue
				directives = _parse_json_block(block)
				if not directives.is_empty():
					print("[SceneDirectivesParser] Parsed directives from marker block")
					return _canonicalize_scene_directives(directives)
	if _code_block_regex:
		var code_matches := _code_block_regex.search_all(response_text)
		if code_matches:
			for cm in code_matches:
				var code_block: String = String(cm.get_string(1)).strip_edges()
				if code_block.is_empty():
					continue
				directives = _parse_json_block(code_block)
				if not directives.is_empty():
					print("[SceneDirectivesParser] Parsed directives from code block")
					return _canonicalize_scene_directives(directives)
	var trimmed := response_text.strip_edges()
	if trimmed.begins_with("{") or trimmed.begins_with("["):
		directives = _parse_json_block(trimmed)
		if directives.is_empty():
			var full_json := JSON.new()
			if full_json.parse(trimmed) == OK and full_json.get_data() is Dictionary:
				var data: Dictionary = full_json.get_data()
				if data.has("metadata") and data["metadata"] is Dictionary:
					directives = _normalize_scene_directives_dict(data["metadata"])
		if not directives.is_empty():
			print("[SceneDirectivesParser] Parsed directives from full response")
			return _canonicalize_scene_directives(directives)
	return { }
func parse_directives(response_text: String) -> Dictionary:
	return parse_scene_directives(response_text)
func extract_story_content(response_text: String) -> String:
	var cleaned := response_text
	var trimmed := response_text.strip_edges()
	if trimmed.begins_with("{") or trimmed.begins_with("["):
		var json := JSON.new()
		if json.parse(trimmed) == OK and json.get_data() is Dictionary:
			var story_text := _extract_story_text_from_dict(json.get_data())
			if not story_text.is_empty():
				return story_text.strip_edges()
	cleaned = _remove_directive_blocks(cleaned, "[SCENE_DIRECTIVES]", "[/SCENE_DIRECTIVES]")
	cleaned = _remove_directive_blocks(cleaned, "```json", "```")
	cleaned = _remove_generic_code_blocks(cleaned)
	return cleaned.strip_edges()
func _parse_json_block(block: String) -> Dictionary:
	if block.is_empty():
		return { }
	var parser := JSON.new()
	if parser.parse(block) == OK and parser.get_data() is Dictionary:
		return _normalize_scene_directives_dict(parser.get_data())
	return { }
func _normalize_scene_directives_dict(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return { }
	if data.has("scene_directives") and data["scene_directives"] is Dictionary:
		return (data["scene_directives"] as Dictionary).duplicate(true)
	if data.has("sceneDirectives") and data["sceneDirectives"] is Dictionary:
		return (data["sceneDirectives"] as Dictionary).duplicate(true)
	var result: Dictionary = { }
	if data.has("visuals") and data["visuals"] is Dictionary:
		var visuals: Dictionary = data["visuals"]
		if visuals.has("scene") and visuals["scene"] is Dictionary:
			result["scene"] = visuals["scene"]
		if visuals.has("characters") and visuals["characters"] is Dictionary:
			result["characters"] = visuals["characters"]
		if visuals.has("assets") and visuals["assets"] is Array:
			result["assets"] = visuals["assets"]
	var directive_keys := ["scene", "characters", "assets", "mission_status", "progression", "relationships"]
	for key in directive_keys:
		if not data.has(key):
			continue
		var entry = data[key]
		if entry == null:
			continue
		if key == "assets" and entry is Array:
			result["assets"] = entry
		elif key == "mission_status" or key == "progression":
			result[key] = str(entry)
		elif entry is Dictionary:
			result[key] = entry
	if result.is_empty() and data.has("metadata") and data["metadata"] is Dictionary:
		return _normalize_scene_directives_dict(data["metadata"])
	return result
func _canonicalize_scene_directives(directives: Dictionary) -> Dictionary:
	if directives.is_empty():
		return directives
	if directives.has("scene") and directives["scene"] is Dictionary:
		var scene_data: Dictionary = directives["scene"]
		if scene_data.has("background"):
			var bg_raw := String(scene_data["background"]).strip_edges()
			if not bg_raw.is_empty():
				scene_data["background"] = _canonicalize_background_id(bg_raw)
	if directives.has("assets") and directives["assets"] is Array:
		directives["assets"] = _canonicalize_assets_list(directives["assets"])
	return directives
func _canonicalize_background_id(bg_raw: String) -> String:
	var background_loader = _get_background_loader()
	if not background_loader:
		return bg_raw
	if background_loader.get_background_texture(bg_raw) != null:
		return bg_raw
	var candidates := [
		bg_raw,
		bg_raw.replace(" ", "_"),
		bg_raw.replace(" ", "").to_lower(),
		bg_raw.to_lower(),
	]
	for candidate in candidates:
		if background_loader.get_background_texture(candidate) != null:
			return candidate
	if background_loader.has_method("get_all_background_ids"):
		var all_bg: Array = background_loader.get_all_background_ids()
		for bg_id in all_bg:
			if String(bg_id).to_lower() == bg_raw.to_lower():
				return bg_id
	return "default"
func _canonicalize_assets_list(assets: Array) -> Array:
	var asset_registry = _get_asset_registry()
	if not asset_registry:
		return assets
	var all_ids: Array = []
	if asset_registry.has_method("get_asset_ids"):
		all_ids = asset_registry.get_asset_ids()
	var out_assets: Array = []
	for asset in assets:
		if not asset is Dictionary:
			continue
		var asset_copy: Dictionary = (asset as Dictionary).duplicate(true)
		var raw_id := String(asset_copy.get("id", "")).strip_edges()
		if not raw_id.is_empty():
			asset_copy["id"] = _canonicalize_asset_id(raw_id, all_ids, asset_registry)
		out_assets.append(asset_copy)
	return out_assets
func _canonicalize_asset_id(raw_id: String, all_ids: Array, asset_registry) -> String:
	if asset_registry.has_method("get_asset"):
		var existing = asset_registry.get_asset(raw_id)
		if existing is Dictionary and not (existing as Dictionary).is_empty():
			return raw_id
	var candidates := [
		raw_id,
		raw_id.replace(" ", "_"),
		raw_id.replace(" ", "").replace("-", "_"),
	]
	for candidate in candidates:
		if asset_registry.has_method("get_asset"):
			var candidate_data = asset_registry.get_asset(candidate)
			if candidate_data is Dictionary and not (candidate_data as Dictionary).is_empty():
				return candidate
	var normalized_raw := _normalize_id_for_matching(raw_id)
	for asset_id in all_ids:
		if _normalize_id_for_matching(String(asset_id)) == normalized_raw:
			return asset_id
	return raw_id
func _normalize_id_for_matching(s: String) -> String:
	var normalized := s.strip_edges().to_lower().replace("-", "_")
	var regex := RegEx.new()
	if regex.compile("[^a-z0-9_]") == OK:
		normalized = regex.sub(normalized, "", true)
	return normalized
func _extract_story_text_from_dict(data: Dictionary, visited: Array = []) -> String:
	if data.is_empty() or visited.has(data):
		return ""
	var new_visited := visited.duplicate()
	new_visited.append(data)
	for key in STORY_TEXT_PRIORITY_KEYS:
		if data.has(key):
			var candidate := _story_value_to_string(data[key], new_visited)
			if not candidate.is_empty():
				return candidate
	if data.has("parts") and data["parts"] is Array:
		var parts_text := _story_value_to_string(data["parts"], new_visited)
		if not parts_text.is_empty():
			return parts_text
	if data.has("metadata") and data["metadata"] is Dictionary:
		var nested := _extract_story_text_from_dict(data["metadata"], new_visited)
		if not nested.is_empty():
			return nested
	return ""
func _story_value_to_string(value, visited: Array) -> String:
	if value is String:
		return String(value)
	if value is Dictionary:
		return _extract_story_text_from_dict(value, visited)
	if value is Array:
		var parts: Array[String] = []
		for element in value:
			var piece := _story_value_to_string(element, visited)
			if not piece.is_empty():
				parts.append(piece)
		return "\n\n".join(parts) if not parts.is_empty() else ""
	return ""
func _remove_directive_blocks(text: String, start_marker: String, end_marker: String) -> String:
	var cleaned := text
	var start_pos := cleaned.find(start_marker)
	while start_pos != -1:
		var end_pos := cleaned.find(end_marker, start_pos)
		if end_pos == -1:
			break
		var block_end := end_pos + end_marker.length()
		cleaned = cleaned.substr(0, start_pos) + cleaned.substr(block_end)
		start_pos = cleaned.find(start_marker)
	return cleaned
func _remove_generic_code_blocks(text: String) -> String:
	var cleaned := text
	var start_marker := "```"
	var start_pos := cleaned.find(start_marker)
	while start_pos != -1:
		if start_pos == 0 or cleaned[start_pos - 1] in ['\n', '\r', ' ', '\t']:
			var end_pos := cleaned.find("\n```", start_pos + start_marker.length())
			if end_pos == -1:
				end_pos = cleaned.find(start_marker, start_pos + start_marker.length())
			if end_pos != -1:
				var block_end := end_pos + 4 
				cleaned = cleaned.substr(0, start_pos) + cleaned.substr(block_end)
				start_pos = cleaned.find(start_marker)
				continue
		start_pos = cleaned.find(start_marker, start_pos + 1)
	return cleaned
func _get_asset_registry():
	if ServiceLocator and ServiceLocator.has_service("AssetRegistry"):
		return ServiceLocator.get_service("AssetRegistry")
	if Engine.has_singleton("AssetRegistry"):
		return Engine.get_singleton("AssetRegistry")
	return null
func _get_background_loader():
	if ServiceLocator and ServiceLocator.has_service("BackgroundLoader"):
		return ServiceLocator.get_service("BackgroundLoader")
	if Engine.has_singleton("BackgroundLoader"):
		return Engine.get_singleton("BackgroundLoader")
	return null
