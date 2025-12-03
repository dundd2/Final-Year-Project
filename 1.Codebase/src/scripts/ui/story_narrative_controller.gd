extends BaseController
class_name StoryNarrativeController
signal mission_generation_complete
const MAX_CONTENT_PREVIEW_LENGTH := 100
const MIN_CONSEQUENCE_WORDS := 100
const MAX_CONSEQUENCE_WORDS := 150
const TEAMMATE_DESCRIPTION_WORDS := 100
const MAX_MISSION_ASSETS := 4
const REQUIRED_CHARACTER_IDS := ["protagonist", "gloria", "donkey", "ark", "one"]
const StoryUIHelper = preload("res://1.Codebase/src/scripts/ui/story_ui_helper.gd")
const ARCHETYPE_LABELS := {
	"en": {
		"cautious": "[Cautious]",
		"balanced": "[Balanced]",
		"reckless": "[Reckless]",
		"positive": "[Positive]",
		"complain": "[Complain]",
	},
	"zh": {
		"cautious": "[謹慎]",
		"balanced": "[權衡]",
		"reckless": "[瘋狂]",
		"positive": "[樂觀]",
		"complain": "[抱怨]",
	},
}
var _last_request: Dictionary = { }
var _last_story_text: String = ""
var _last_story_id: int = 0
var _pending_choice_followup: bool = false
var _choice_followup_story_id: int = -1
var _night_cycle_pending: bool = false
var _is_generating: bool = false
func is_generating() -> bool:
	return _is_generating
func _init(p_story_scene: Control) -> void:
	super(p_story_scene)  
func _store_last_request(request_type: String, prompt: String, context: Dictionary, callback: Callable) -> void:
	var context_copy: Variant = context
	if context is Dictionary:
		context_copy = (context as Dictionary).duplicate(true)
	_last_request = {
		"type": request_type,
		"prompt": prompt,
		"context": context_copy,
		"callback": callback,
	}
func has_retryable_request() -> bool:
	return not _last_request.is_empty()
func _get_retry_message(request_type: String, lang: String) -> String:
	var message := "Retrying AI request..." if lang == "en" else "正在重試 AI 請求..."
	match request_type:
		"mission":
			message = "Retrying mission generation..." if lang == "en" else "重新生成任務..."
		"consequence":
			message = "Retrying consequence generation..." if lang == "en" else "重新生成後果..."
		"teammate_interference":
			message = "Retrying teammate interference..." if lang == "en" else "重新生成隊友插手..."
		"gloria_intervention":
			message = "Retrying Gloria intervention..." if lang == "en" else "重新生成 Gloria 插手..."
		_:
			pass
	return message
func retry_last_request(force_mock: bool = false) -> bool:
	if _last_request.is_empty():
		return false
	if not story_scene:
		return false
	var ai_manager = get_ai_manager()
	if not ai_manager:
		return false
	var prompt_variant: Variant = _last_request.get("prompt", "")
	var prompt := String(prompt_variant)
	if prompt.is_empty():
		return false
	var callback_variant: Variant = _last_request.get("callback", Callable())
	if not (callback_variant is Callable):
		return false
	var callback_callable: Callable = callback_variant
	if not callback_callable.is_valid():
		return false
	var context_variant: Variant = _last_request.get("context", { })
	var context_payload: Dictionary = { }
	if context_variant is Dictionary:
		context_payload = (context_variant as Dictionary).duplicate(true)
	if force_mock:
		context_payload["force_mock"] = true
	var request_type := String(_last_request.get("type", "unknown"))
	var lang := "en"
	var game_state = get_game_state()
	if game_state:
		lang = String(game_state.current_language)
	var loading_message := _get_retry_message(request_type, lang)
	story_scene.show_loading(loading_message, "ai_retry")
	if story_scene.ui_controller:
		story_scene.ui_controller.set_status_text(loading_message)
	ai_manager.generate_story(prompt, context_payload, callback_callable)
	return true
func _get_asset_registry():
	if ServiceLocator and ServiceLocator.has_service("AssetRegistry"):
		return ServiceLocator.get_service("AssetRegistry")
	return null
func _update_story_display(new_content: String, replace_existing: bool = true) -> void:
	if not story_scene or not story_scene.ui_controller:
		return
	if replace_existing:
		story_scene.ui_controller.clear_story_text()
	story_scene.ui_controller.display_story(new_content)
func start_new_mission(prepared_assets: Dictionary = { }) -> void:
	print("\n[DEBUG_NARRATIVE] Requesting New Mission Generation...")
	var ai_manager = get_ai_manager()
	var game_state = get_game_state()
	if not ai_manager or not game_state:
		_report_error("AIManager or GameState not available")
		return
	if game_state:
		game_state.debug_force_mission_complete = false
	var asset_data: Dictionary = { }
	if prepared_assets is Dictionary and (prepared_assets as Dictionary).size() > 0:
		asset_data = (prepared_assets as Dictionary).duplicate(true)
	elif story_scene.asset_controller:
		var prepared_variant: Variant = story_scene.asset_controller.prepare_mission_assets(MAX_MISSION_ASSETS)
		if prepared_variant is Dictionary:
			asset_data = prepared_variant
	var selected_assets: Array = asset_data.get("asset_list", [])
	var selected_ids: Array = asset_data.get("asset_ids", [])
	if selected_assets.is_empty():
		_report_error("No assets available for mission")
		return
	if story_scene.asset_controller:
		story_scene.asset_controller.setup_asset_interactions(selected_ids)
		story_scene.update_asset_display()
	var prompt: String = build_mission_prompt(selected_assets)
	var context: Dictionary = {
		"purpose": "new_mission",
		"mission_number": game_state.current_mission + 1,
		"assets": selected_assets,
	}
	story_scene.show_loading("Generating mission...")
	_is_generating = true
	var mission_callback := Callable(self, "_on_mission_generated")
	_store_last_request("mission", prompt, context, mission_callback)
	ai_manager.generate_story(prompt, context, mission_callback)
func build_mission_prompt(selected_assets: Array) -> String:
	var game_state = get_game_state()
	var lang: String = game_state.current_language if game_state else "en"
	var prompt_parts: Array[String] = []
	prompt_parts.append("=== Mission Generation ===" if lang == "en" else "=== 任務生成 ===")
	prompt_parts.append(LocalizationManager.get_translation("STORY_MISSION_GENERATION_INSTRUCTION", lang))
	var asset_registry = _get_asset_registry()
	if asset_registry and not selected_assets.is_empty():
		var asset_prompt: String = asset_registry.format_assets_for_prompt(selected_assets)
		prompt_parts.append("\n" + asset_prompt)
	if game_state:
		var stats_info: String = ""
		if lang == "zh":
			stats_info = "\n當前狀態：\n- 現實值：%d\n- 正能量：%d\n- 熵值：%d" % [
				game_state.reality_score,
				game_state.positive_energy,
				game_state.entropy_level,
			]
		else:
			stats_info = "\nCurrent Stats:\n- Reality Score: %d\n- Positive Energy: %d\n- Entropy: %d" % [
				game_state.reality_score,
				game_state.positive_energy,
				game_state.entropy_level,
			]
		prompt_parts.append(stats_info)
		if game_state.is_in_honeymoon():
			if lang == "zh":
				prompt_parts.append("\n[重要狀態：蜜月期]")
				prompt_parts.append("目前處於「蜜月期」。隊友們表現得異常合作、體貼且樂於助人（甚至有點令人發毛）。")
				prompt_parts.append("請不要讓他們搞砸任務，而是讓他們「過度完美」地執行指令，營造一種暴風雨前的寧靜。")
			else:
				prompt_parts.append("\n[IMPORTANT STATE: HONEYMOON PHASE]")
				prompt_parts.append("We are in the 'Honeymoon Phase'. Teammates are acting suspiciously cooperative, helpful, and kind.")
				prompt_parts.append("Do NOT generate sabotage. Instead, make them execute orders 'too perfectly', creating an eerie sense of calm before the storm.")
	if lang == "zh":
		prompt_parts.append("\n請生成：")
		prompt_parts.append("1. 場景描述（200-300字）")
		prompt_parts.append("2. 任務目標")
		prompt_parts.append("3. 潛在困境或挑戰")
		prompt_parts.append("\n請在黑色幽默的基調下生成內容。")
		prompt_parts.append("\nstory_text 內文最後必須加入「選項預告」段落：包含 3 到 5 行，分別以 [謹慎]、[權衡]、[瘋狂]、[樂觀] 或 [抱怨] 開頭，每行 10-20 字描述該選項的後續走向。")
		prompt_parts.append("這些預告文字必須存在且與 JSON choices 陣列的 summary 完全對應。")
	else:
		prompt_parts.append("\nPlease generate:")
		prompt_parts.append("1. Scene description (200-300 words)")
		prompt_parts.append("2. Mission objective")
		prompt_parts.append("3. Potential dilemmas or challenges")
		prompt_parts.append("\nMaintain dark humor and satirical tone.")
		prompt_parts.append("\nInside the story_text, finish with a short \"Choice Preview\" block that contains 3 to 5 lines labeled with [Cautious], [Balanced], [Reckless], [Positive], or [Complain]. Each line must be 10-20 words describing the consequence of choosing that route.")
		prompt_parts.append("All preview lines must be present and mirror the JSON choices summaries.")
	if lang == "zh":
		prompt_parts.append("\n請生成以下內容：")
		prompt_parts.append("1. 場景描述（200-300 字）")
		prompt_parts.append("2. 任務目標")
		prompt_parts.append("3. 可能的兩難或挑戰")
		prompt_parts.append("\n維持黑色幽默與諷刺的語調。")
		prompt_parts.append("\n\n**重要：回應必須是有效 JSON 物件，且不可包含額外文字或 Markdown。**")
		prompt_parts.append("輸出結構如下（保留小寫鍵名）：")
		prompt_parts.append("{")
		prompt_parts.append("  \"mission_title\": \"<章節標題>\",")
		prompt_parts.append("  \"scene\": {\"background\": \"<背景ID>\", \"atmosphere\": \"<氛圍簡述>\", \"lighting\": \"<燈光描述>\"},")
		prompt_parts.append("  \"characters\": {")
		prompt_parts.append("    \"protagonist\": {\"expression\": \"<表情>\"},")
		prompt_parts.append("    \"gloria\": {\"expression\": \"<表情>\"},")
		prompt_parts.append("    \"donkey\": {\"expression\": \"<表情>\"},")
		prompt_parts.append("    \"ark\": {\"expression\": \"<表情>\"},")
		prompt_parts.append("    \"one\": {\"expression\": \"<表情>\"}")
		prompt_parts.append("  },")
		prompt_parts.append("  \"relationships\": [")
		prompt_parts.append("    {\"source\": \"gloria\", \"target\": \"player\", \"status\": \"失望\", \"value_change\": -5},")
		prompt_parts.append("    {\"source\": \"donkey\", \"target\": \"ark\", \"status\": \"爭吵\", \"value_change\": 0}")
		prompt_parts.append("  ],")
		prompt_parts.append("  \"story_text\": \"<200-300 字的黑色幽默正文>\",")
		prompt_parts.append("  \"choices\": [")
		prompt_parts.append("    {\"archetype\": \"cautious\", \"summary\": \"<10-20 字描述選擇後走向>\"},")
		prompt_parts.append("    {\"archetype\": \"balanced\", \"summary\": \"<10-20 字描述選擇後走向>\"},")
		prompt_parts.append("    {\"archetype\": \"reckless\", \"summary\": \"<10-20 字描述選擇後走向>\"},")
		prompt_parts.append("    {\"archetype\": \"positive\", \"summary\": \"<10-20 字描述選擇後走向>\"},")
		prompt_parts.append("    {\"archetype\": \"complain\", \"summary\": \"<10-20 字描述選擇後走向>\"}")
		prompt_parts.append("  ]")
		prompt_parts.append("}")
		prompt_parts.append("背景必須選自：ruins, cave, dungeon, forest, temple, laboratory, library, throne_room, battlefield, crystal_cavern, bridge, garden, portal_area, safe_zone, water, fire_area")
		prompt_parts.append("表情必須選自：neutral, happy, sad, angry, confused, shocked, thinking, embarrassed")
		prompt_parts.append("所有五位主要角色皆需設定表情，即使未說話。背景請與劇情氛圍相符，並使用提供的 ID。")
		prompt_parts.append("relationships 為可選欄位，若情節導致角色間的狀態改變（如：失望、崇拜、敵視），請在此列出。")
		prompt_parts.append("mission_title 必須是該章節的標題，充滿黑色幽默或諷刺意味。")
		prompt_parts.append("同時輸出 \"choices\" 陣列：請提供 3 到 5 個選項，可混合使用 cautious、balanced、reckless、positive（樂觀）、complain（抱怨）這些類型。summary 需以與正文相同語言、10-20 字預告該選擇的走向。")
		prompt_parts.append("story_text 中的 [謹慎]/[權衡]/[瘋狂]/[樂觀]/[抱怨] 預告行必須與 choices 陣列的 summary 一一對應，缺少任何一項都視為無效結果。")
	else:
		prompt_parts.append("\n\n**IMPORTANT: Respond with EXACTLY one valid JSON object. Do not add prose outside the JSON.**")
		prompt_parts.append("Use this schema (keep lowercase keys):")
		prompt_parts.append("{")
		prompt_parts.append("  \"mission_title\": \"<Creative Chapter Title>\",")
		prompt_parts.append("  \"scene\": {\"background\": \"<background_id>\", \"atmosphere\": \"<tone>\", \"lighting\": \"<lighting_note>\"},")
		prompt_parts.append("  \"characters\": {")
		prompt_parts.append("    \"protagonist\": {\"expression\": \"<expression>\"},")
		prompt_parts.append("    \"gloria\": {\"expression\": \"<expression>\"},")
		prompt_parts.append("    \"donkey\": {\"expression\": \"<expression>\"},")
		prompt_parts.append("    \"ark\": {\"expression\": \"<expression>\"},")
		prompt_parts.append("    \"one\": {\"expression\": \"<expression>\"}")
		prompt_parts.append("  },")
		prompt_parts.append("  \"relationships\": [")
		prompt_parts.append("    {\"source\": \"gloria\", \"target\": \"player\", \"status\": \"Disappointed\", \"value_change\": -5},")
		prompt_parts.append("    {\"source\": \"donkey\", \"target\": \"ark\", \"status\": \"Fighting\", \"value_change\": 0}")
		prompt_parts.append("  ],")
		prompt_parts.append("  \"story_text\": \"<200-300 word darkly comic scene>\",")
		prompt_parts.append("  \"choices\": [")
		prompt_parts.append("    {\"archetype\": \"cautious\", \"summary\": \"<10-20 word consequence preview>\"},")
		prompt_parts.append("    {\"archetype\": \"balanced\", \"summary\": \"<10-20 word consequence preview>\"},")
		prompt_parts.append("    {\"archetype\": \"reckless\", \"summary\": \"<10-20 word consequence preview>\"},")
		prompt_parts.append("    {\"archetype\": \"positive\", \"summary\": \"<10-20 word consequence preview>\"},")
		prompt_parts.append("    {\"archetype\": \"complain\", \"summary\": \"<10-20 word consequence preview>\"}")
		prompt_parts.append("  ]")
		prompt_parts.append("}")
		prompt_parts.append("All five main characters are always on screen. Provide an expression for each, even if silent.")
		prompt_parts.append("Background must be chosen from: ruins, cave, dungeon, forest, temple, laboratory, library, throne_room, battlefield, crystal_cavern, bridge, garden, portal_area, safe_zone, water, fire_area")
		prompt_parts.append("Expressions must be one of: neutral, happy, sad, angry, confused, shocked, thinking, embarrassed")
		prompt_parts.append("relationships is optional. If the story shifts how characters see each other (e.g., Disappointed, Worships, Hates), list them here.")
		prompt_parts.append("mission_title must be a short, darkly humorous title for this chapter.")
		prompt_parts.append("Match the background and expressions to the mission tone. Use the exact IDs from the list (e.g., fire_area).")
		prompt_parts.append("")
		prompt_parts.append("CHOICE OUTPUT RULES:")
		prompt_parts.append("- Provide 3 to 5 choices using any mix of archetype IDs: cautious, balanced, reckless, positive, complain.")
		prompt_parts.append("- Summaries must preview how the story shifts if the player picks that option (10-20 words).")
		prompt_parts.append("- Keep the summary in the same language as the story_text.")
		prompt_parts.append("- The story_text must repeat these summaries as [ArchetypeLabel] preview lines so the UI can fall back; missing JSON choices or preview lines makes the mission invalid.")
	return "\n".join(prompt_parts)
func _on_mission_generated(response: Dictionary) -> void:
	_is_generating = false
	story_scene.hide_loading()
	print("[DEBUG_NARRATIVE] Mission Generation Response Received. Success: %s" % response.get("success", false))
	if not response.get("success", false):
		var error_msg: String = String(response.get("error", "Unknown error"))
		_report_error(
			"Mission generation failed: %s" % error_msg,
			{"error": error_msg}
		)
		_update_story_display("Failed to generate mission. Please try again.")
		emit_signal("mission_generation_complete")
		return
	var ai_choice_payload: Array[Dictionary] = []
	var story_content: String = String(response.get("content", ""))
	if story_content.is_empty():
		story_content = String(response.get("text", ""))
	var json_parser := JSON.new()
	var directives: Dictionary = {}
	var clean_content: String = story_content
	var json_candidate := _extract_primary_json_block(story_content)
	var parse_source := json_candidate if not json_candidate.is_empty() else story_content
	if json_parser.parse(parse_source) == OK and json_parser.data is Dictionary:
		var json_data: Dictionary = json_parser.data
		if json_data.has("mission_title"):
			var title = String(json_data["mission_title"]).strip_edges()
			if not title.is_empty():
				var game_state = get_game_state()
				if game_state:
					game_state.current_mission_title = title
		if json_data.has("scene"):
			directives["scene"] = _normalize_scene_directives(json_data["scene"])
		if json_data.has("characters"):
			directives["characters"] = _normalize_character_directives(json_data["characters"])
		if json_data.has("assets"):
			directives["assets"] = _normalize_asset_directives(json_data["assets"])
		if json_data.has("story_text"):
			clean_content = String(json_data["story_text"])
		else:
			clean_content = story_content
		if json_data.has("choices"):
			ai_choice_payload = _normalize_ai_choice_payload(json_data.get("choices", []))
	else:
		var ai_manager = get_ai_manager()
		if ai_manager:
			directives = ai_manager.parse_scene_directives(story_content)
			if directives.has("scene"):
				directives["scene"] = _normalize_scene_directives(directives["scene"])
			if directives.has("characters"):
				directives["characters"] = _normalize_character_directives(directives["characters"])
			if directives.has("assets"):
				directives["assets"] = _normalize_asset_directives(directives["assets"])
			clean_content = ai_manager.extract_story_content(story_content)
	if clean_content.is_empty():
		var fallback_manager = get_ai_manager()
		if fallback_manager:
			clean_content = fallback_manager.extract_story_content(story_content)
	if clean_content.strip_edges().is_empty() or (clean_content.strip_edges().begins_with("{") and clean_content.strip_edges().ends_with("}")):
		print("[Narrative] Warning: clean_content empty or raw JSON. Using fallback raw text extraction.")
		var json_block_str = _extract_primary_json_block(story_content)
		if not json_block_str.is_empty():
			clean_content = story_content.replace(json_block_str, "").strip_edges()
		if clean_content.is_empty() and directives.has("story_text") and not String(directives["story_text"]).is_empty():
			clean_content = String(directives["story_text"])
		elif clean_content.is_empty():
			clean_content = story_content
	if not directives.is_empty():
		story_scene.apply_scene_directives(directives)
		if directives.has("relationships"):
			_process_relationship_updates(directives["relationships"])
	var sanitized: String = StoryUIHelper.sanitize_story_text(clean_content)
	_update_story_display(sanitized)
	_last_story_text = sanitized
	var game_state = get_game_state()
	if game_state:
		game_state.set_latest_story_text(sanitized)
	_last_story_id += 1
	if game_state:
		game_state.current_mission += 1
		game_state.mission_turn_count = 1
	_record_mission_start(sanitized)
	_update_story_choices(ai_choice_payload, sanitized)
	emit_signal("mission_generation_complete")
func _extract_primary_json_block(raw_text: String) -> String:
	var trimmed := raw_text.strip_edges()
	if trimmed.begins_with("{"):
		return trimmed
	var depth := 0
	var first_index := -1
	var in_string := false
	var escape_next := false
	for i in range(raw_text.length()):
		var ch := raw_text.substr(i, 1)
		if escape_next:
			escape_next = false
			continue
		if ch == "\\":
			escape_next = true
			continue
		if ch == "\"":
			in_string = not in_string
			continue
		if in_string:
			continue
		if ch == "{":
			if depth == 0:
				first_index = i
			depth += 1
		elif ch == "}":
			if depth > 0:
				depth -= 1
				if depth == 0 and first_index != -1:
					return raw_text.substr(first_index, i - first_index + 1).strip_edges()
	return ""
func _normalize_scene_directives(scene_variant) -> Dictionary:
	if not (scene_variant is Dictionary):
		return { }
	var scene_dict: Dictionary = (scene_variant as Dictionary).duplicate(true)
	var background := String(scene_dict.get("background", "")).strip_edges().to_lower()
	if background.is_empty():
		background = "default"
	if BackgroundLoader:
		var catalog = BackgroundLoader.get("backgrounds")
		if typeof(catalog) == TYPE_DICTIONARY and not catalog.has(background):
			if catalog.has(background + "_area"):
				background = background + "_area"
			elif background == "fire" and catalog.has("fire_area"):
				background = "fire_area"
			elif catalog.has("default"):
				background = "default"
	scene_dict["background"] = background
	scene_dict["atmosphere"] = String(scene_dict.get("atmosphere", "")).strip_edges()
	scene_dict["lighting"] = String(scene_dict.get("lighting", "")).strip_edges()
	return scene_dict
func _normalize_character_directives(characters_variant) -> Dictionary:
	var normalized: Dictionary = { }
	if characters_variant is Dictionary:
		for key in (characters_variant as Dictionary).keys():
			var value = (characters_variant as Dictionary)[key]
			var entry: Dictionary = { }
			if value is Dictionary:
				entry = (value as Dictionary).duplicate(true)
			else:
				entry["expression"] = String(value)
			var expression := String(entry.get("expression", "neutral")).strip_edges().to_lower()
			if CharacterExpressionLoader and not CharacterExpressionLoader.EXPRESSIONS.has(expression):
				expression = "neutral"
			entry["expression"] = expression if not expression.is_empty() else "neutral"
			normalized[String(key)] = entry
	for required_id in REQUIRED_CHARACTER_IDS:
		if not normalized.has(required_id):
			normalized[required_id] = { "expression": "neutral" }
	return normalized
func _normalize_ai_choice_payload(payload) -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	if payload is Array:
		for entry in payload:
			if entry is Dictionary:
				var archetype := String(entry.get("archetype", "")).to_lower()
				var summary := String(entry.get("summary", "")).strip_edges()
				if archetype.is_empty() or summary.is_empty():
					continue
				normalized.append(
					{
						"archetype": archetype,
						"summary": summary,
					},
				)
	return normalized
func _extract_archetype_choices_from_text(story_text: String, lang: String) -> Array[Dictionary]:
	var normalized_lang := "zh" if lang == "zh" else "en"
	var label_map: Dictionary = ARCHETYPE_LABELS.get(normalized_lang, ARCHETYPE_LABELS.get("en", { }))
	var plain_text := String(story_text).replace("\r", "\n")
	var results: Array[Dictionary] = []
	for archetype in label_map.keys():
		var label: String = String(label_map[archetype])
		if label.is_empty():
			continue
		var search_index := plain_text.find(label)
		if search_index == -1:
			continue
		var summary := _extract_summary_after_label(plain_text, search_index + label.length())
		if summary.is_empty():
			continue
		results.append({
			"archetype": archetype,
			"summary": summary,
		})
	return results
func _extract_summary_after_label(text: String, start_idx: int) -> String:
	var end_idx := text.find("\n", start_idx)
	if end_idx == -1:
		end_idx = text.length()
	var summary := text.substr(start_idx, end_idx - start_idx).strip_edges()
	while not summary.is_empty() and (summary.begins_with(":") or summary.begins_with("：") or summary.begins_with("-") or summary.begins_with("—") or summary.begins_with("/")):
		summary = summary.substr(1).strip_edges()
	return summary
func _update_story_choices(ai_choices: Array[Dictionary], story_text: String, allow_followup: bool = true) -> void:
	if not story_scene or not story_scene.choice_controller:
		return
	var lang := _get_current_language()
	var final_choices := ai_choices
	print("[DEBUG_NARRATIVE] Updating Story Choices. AI Payload Size: %d" % ai_choices.size())
	print("[Narrative] Updating choices | lang=%s | ai_choices=%d" % [lang, final_choices.size()])
	if final_choices.is_empty():
		final_choices = _extract_archetype_choices_from_text(story_text, lang)
		print("[Narrative] Extracted choices from text | count=%d" % final_choices.size())
	if final_choices.is_empty():
		print("[Narrative] No AI choices, falling back to legacy generator")
		if allow_followup and not _pending_choice_followup:
			_request_story_choice_followup(story_text, lang)
		story_scene.choice_controller.generate_choices()
	else:
		print("[Narrative] Applying AI choices to controller")
		story_scene.choice_controller.apply_ai_choices(final_choices, lang)
func _request_story_choice_followup(story_text: String, lang: String) -> void:
	var ai_manager = get_ai_manager()
	var excerpt := story_text.strip_edges()
	if not ai_manager or excerpt.is_empty():
		return
	if _pending_choice_followup and _choice_followup_story_id == _last_story_id:
		return
	_pending_choice_followup = true
	_choice_followup_story_id = _last_story_id
	excerpt = excerpt.substr(0, min(excerpt.length(), 1200))
	var prompt := ""
	if lang == "zh":
		prompt = """=== 選項補完（強制要求）===\n以下是故事摘錄：\n%s\n\n請只輸出一個 JSON 物件：{\"choices\":[{\"archetype\":\"cautious\",\"summary\":\"...\"},...]}。\n- 請提供 3 到 5 個選項，可使用 cautious, balanced, reckless, positive, complain。\n- summary 必須為中文，10-20 字內、描述玩家選擇後的走向。\n- 不可回覆任何其他文字、格式或解說。若輸出無效，我們會視為任務失敗。""" % excerpt
	else:
		prompt = """=== Choice Summary Follow-up (STRICT) ===\nStory excerpt:\n%s\n\nOutput EXACTLY one JSON object: {\"choices\":[{\"archetype\":\"cautious\",\"summary\":\"...\"},...]}\n- Provide 3 to 5 choices using archetypes: cautious, balanced, reckless, positive, complain.\n- Summaries must be 10-20 words in the same language as the excerpt describing the consequence route.\n- DO NOT include prose, Markdown, or explanations outside the JSON. Invalid output will be rejected.""" % excerpt
	print("[Narrative] Requesting follow-up choice summaries")
	var context := {
		"purpose": "choice_followup",
	}
	var callback := Callable(self, "_on_choice_followup_generated")
	ai_manager.generate_story(prompt, context, callback)
func _on_choice_followup_generated(response: Dictionary) -> void:
	_pending_choice_followup = false
	if not response.get("success", false):
		return
	var content := String(response.get("content", response.get("text", "")))
	if content.is_empty():
		return
	var parser := JSON.new()
	if parser.parse(content) != OK or not (parser.data is Dictionary):
		return
	var json_data: Dictionary = parser.data
	if not json_data.has("choices"):
		return
	var ai_choices := _normalize_ai_choice_payload(json_data.get("choices", []))
	if ai_choices.is_empty():
		return
	if _choice_followup_story_id != _last_story_id:
		return
	print("[Narrative] Follow-up choices received: %d" % ai_choices.size())
	_update_story_choices(ai_choices, _last_story_text, false)
func _get_current_language() -> String:
	var game_state = get_game_state()
	if game_state:
		return game_state.current_language
	return "en"
func _normalize_asset_directives(assets_variant) -> Array:
	var normalized: Array = []
	if assets_variant is Array:
		for entry in assets_variant:
			if entry is Dictionary:
				normalized.append((entry as Dictionary).duplicate(true))
	return normalized
func _process_relationship_updates(updates_variant) -> void:
	if not (updates_variant is Array):
		return
	var teammate_system = ServiceLocator.get_teammate_system() if ServiceLocator else null
	if not teammate_system:
		return
	for update in (updates_variant as Array):
		if not (update is Dictionary):
			continue
		var source_id = String(update.get("source", "")).strip_edges().to_lower()
		var target_id = String(update.get("target", "")).strip_edges().to_lower()
		var status = String(update.get("status", "")).strip_edges()
		var value_change = int(update.get("value_change", 0))
		if source_id.is_empty() or target_id.is_empty() or status.is_empty():
			continue
		if source_id == "you" or source_id == "me": source_id = "player"
		if target_id == "you" or target_id == "me": target_id = "player"
		teammate_system.update_relationship(source_id, target_id, status, value_change)
		print("[Narrative] Updated relationship: %s -> %s (%s, %+d)" % [source_id, target_id, status, value_change])
func _record_mission_start(content: String) -> void:
	var game_state = get_game_state()
	if not game_state:
		return
	var choice_data: Dictionary = {
		"type": "mission_start",
		"choice_type": "major",
		"text": "New mission started",
		"mission_number": game_state.current_mission,
		"content_preview": content.substr(0, MAX_CONTENT_PREVIEW_LENGTH) if content.length() > MAX_CONTENT_PREVIEW_LENGTH else content,
		"tags": ["mission", "system"],
	}
	if game_state.butterfly_tracker:
		game_state.butterfly_tracker.record_choice(choice_data)
func handle_prayer_consequence(data: Dictionary) -> void:
	var prayer_text: String = data.get("prayer_text", "")
	var disaster_text: String = data.get("disaster", "")
	if prayer_text.is_empty() or disaster_text.is_empty():
		return
	var combined_text = "[PLAYER PRAYER]\n%s\n\n[DIVINE RESPONSE]\n%s" % [prayer_text, disaster_text]
	_last_story_text = combined_text
	var game_state = get_game_state()
	if game_state:
		game_state.set_latest_story_text(combined_text)
		game_state.add_event(
			"Prayer Answered",
			"Prayer: %s\nResult: %s" % [prayer_text.substr(0, 50), disaster_text.substr(0, 50)]
		)
	print("[Narrative] Processed prayer consequence. Context updated.")
func request_consequence_generation(choice: Dictionary, success: bool) -> void:
	var ai_manager = get_ai_manager()
	var game_state = get_game_state()
	if not ai_manager or not game_state:
		return
	var lang: String = game_state.current_language
	var prompt: String = _build_consequence_prompt(choice, success, lang)
	var context: Dictionary = {
		"purpose": "consequence",
		"choice": choice,
		"success": success,
	}
	story_scene.show_loading("Generating consequence...")
	_is_generating = true
	var consequence_callback := Callable(self, "_on_consequence_generated")
	_store_last_request("consequence", prompt, context, consequence_callback)
	ai_manager.generate_story(prompt, context, consequence_callback)
func _build_consequence_prompt(choice: Dictionary, success: bool, lang: String) -> String:
	var prompt_parts: Array[String] = []
	if lang == "zh":
		prompt_parts.append("=== 後果生成 ===")
		prompt_parts.append("玩家選擇：%s" % choice.get("text", ""))
		prompt_parts.append("結果：%s" % ("成功" if success else "失敗"))
		prompt_parts.append("\n請用 %d-%d 字描述結果。" % [MIN_CONSEQUENCE_WORDS, MAX_CONSEQUENCE_WORDS])
		prompt_parts.append("需要涵蓋：")
		prompt_parts.append("1. 立刻發生的狀況")
		prompt_parts.append("2. NPC 或環境反應")
		prompt_parts.append("3. 長期後果或伏筆")
		prompt_parts.append("\n請在回應最後（場景指令之後）必定加上「選項預告」區塊，包含 3 到 5 行：")
		prompt_parts.append("每行以 [謹慎]、[權衡]、[瘋狂]、[樂觀] 或 [抱怨] 開頭，後接 <10-20 字預告>。")
		prompt_parts.append("這些預告是生成下一輪選項按鈕所必需的。")
	else:
		prompt_parts.append("=== Consequence Generation ===")
		prompt_parts.append("Player chose: " + choice.get("text", ""))
		prompt_parts.append("Outcome: " + ("Success" if success else "Failure"))
		prompt_parts.append("\nDescribe the immediate consequence (%d-%d words)." % [MIN_CONSEQUENCE_WORDS, MAX_CONSEQUENCE_WORDS])
		prompt_parts.append("Include:")
		prompt_parts.append("1. What happens right away")
		prompt_parts.append("2. NPC/environment reactions")
		prompt_parts.append("3. Foreshadowing of long-term impact")
		prompt_parts.append("\nCRITICAL: If the choice involved conflict or anger, you MUST downgrade relationships in the [SCENE_DIRECTIVES].")
		prompt_parts.append("\nAt the end of your response, you MUST include a 'Choice Preview' section with 3 to 5 lines:")
		prompt_parts.append("Each line must start with [Cautious], [Balanced], [Reckless], [Positive], or [Complain], followed by a <10-20 word preview>.")
		prompt_parts.append("These lines are required for the game to generate the next set of buttons.")
	if lang == "zh":
		prompt_parts.append("\n\n請在回應開頭附上場景指令 JSON：")
		prompt_parts.append("[SCENE_DIRECTIVES]")
		prompt_parts.append("{")
		prompt_parts.append("  \"mission_status\": \"ongoing\",")
		prompt_parts.append("  \"characters\": {")
		prompt_parts.append("    \"character_id\": {\"expression\": \"expression_type\"}")
		prompt_parts.append("  },")
		prompt_parts.append("  \"relationships\": [")
		prompt_parts.append("    {\"source\": \"gloria\", \"target\": \"player\", \"status\": \"失望\", \"value_change\": -10}")
		prompt_parts.append("  ]")
		prompt_parts.append("}")
		prompt_parts.append("[/SCENE_DIRECTIVES]")
		prompt_parts.append("\n角色代號：protagonist, gloria, donkey, ark, one, teacher_chan")
		prompt_parts.append("表情：neutral, happy, sad, angry, confused, shocked, thinking, embarrassed")
		prompt_parts.append("若此事件改變了角色關係，請在 relationships 中更新狀態與數值（-100 到 100）。")
		prompt_parts.append("\n**關鍵判斷**：如果這個後果代表當前單元故事的「結局」（無論是災難性的成功或徹底的失敗），請將 mission_status 設為 \"complete\"。這將會觸發故事的結算與進入下一章節。若故事仍在發展中，保持 \"ongoing\"。")
	else:
		prompt_parts.append("\n\nIMPORTANT: Include scene directives at the start of your response in this format:")
		prompt_parts.append("[SCENE_DIRECTIVES]")
		prompt_parts.append("{")
		prompt_parts.append("  \"mission_status\": \"ongoing\",")
		prompt_parts.append("  \"characters\": {")
		prompt_parts.append("    \"character_id\": {\"expression\": \"expression_type\"}")
		prompt_parts.append("  },")
		prompt_parts.append("  \"relationships\": [")
		prompt_parts.append("    {\"source\": \"gloria\", \"target\": \"player\", \"status\": \"Disappointed\", \"value_change\": -10}")
		prompt_parts.append("  ]")
		prompt_parts.append("}")
		prompt_parts.append("[/SCENE_DIRECTIVES]")
		prompt_parts.append("\nAvailable characters: protagonist, gloria, donkey, ark, one, teacher_chan")
		prompt_parts.append("Available expressions: neutral, happy, sad, angry, confused, shocked, thinking, embarrassed")
		prompt_parts.append("If relationships change, update them in relationships list with status string and value_change (-100 to 100).")
		prompt_parts.append("\n**CRITICAL**: If this consequence resolves the current narrative arc (either as a catastrophic success or a failure), set \"mission_status\" to \"complete\". This triggers the end-of-mission sequence. Otherwise, keep it \"ongoing\".")
	var game_state = get_game_state()
	if game_state and game_state.debug_force_mission_complete:
		if lang == "zh":
			prompt_parts.append("\n[SYSTEM: DEBUG MODE ACTIVE]")
			prompt_parts.append("無論故事進展如何，你必須強制結束當前章節。")
			prompt_parts.append("請在 SCENE_DIRECTIVES 中將 \"mission_status\" 設為 \"complete\"。")
			prompt_parts.append("請撰寫一個突如其來的結局或轉折來結束本章。")
		else:
			prompt_parts.append("\n[SYSTEM: DEBUG MODE ACTIVE]")
			prompt_parts.append("Regardless of story context, you MUST force the end of the current chapter.")
			prompt_parts.append("Set \"mission_status\" to \"complete\" in the SCENE_DIRECTIVES.")
			prompt_parts.append("Write an abrupt ending or twist to conclude the mission immediately.")
	return "\n".join(prompt_parts)
func _on_consequence_generated(response: Dictionary) -> void:
	_is_generating = false
	story_scene.hide_loading()
	if not response.get("success", false):
		print("[Narrative] Gloria intervention failed: success=false")
		story_scene.overlay_controller.show_gloria_overlay("Gloria glares at you silently...")
		return
	var content: String = String(response.get("content", response.get("text", "")))
	if content.is_empty():
		print("[Narrative] Gloria intervention failed: content empty")
		story_scene.overlay_controller.show_gloria_overlay("Gloria glares at you silently...")
		return
	var ai_manager = get_ai_manager()
	if not ai_manager:
		print("[Narrative] Gloria intervention failed: AI manager missing")
		story_scene.overlay_controller.show_gloria_overlay(content if not content.is_empty() else "Gloria glares at you silently...")
		return
	var directives = ai_manager.parse_scene_directives(content)
	if not directives.is_empty():
		if directives.has("characters"):
			directives["characters"] = _normalize_character_directives(directives.get("characters", { }))
		if directives.has("scene"):
			directives["scene"] = _normalize_scene_directives(directives.get("scene", { }))
		story_scene.apply_scene_directives(directives)
		if directives.has("relationships"):
			_process_relationship_updates(directives["relationships"])
	var clean_content = ai_manager.extract_story_content(content)
	var sanitized: String = StoryUIHelper.sanitize_story_text(clean_content)
	_update_story_display(sanitized)
	_last_story_text = sanitized
	var directives_map: Dictionary = directives
	var mission_status: String = String(directives_map.get("mission_status", "ongoing")).to_lower()
	var game_state = get_game_state()
	if game_state and game_state.debug_force_mission_complete:
		print("[Narrative] Debug override: forcing mission completion.")
		mission_status = "complete"
	if mission_status == "complete":
		print("[Narrative] AI signaled mission completion.")
		_handle_mission_completion(sanitized)
	else:
		if game_state and game_state.positive_energy <= 30:
			var last_turn = game_state.get_metadata("last_gloria_auto_turn", -999)
			var current_turn = game_state.mission_turn_count
			if current_turn - last_turn >= 3:
				var last_choice = _last_request.get("context", {}).get("choice", {})
				if last_choice.is_empty():
					last_choice = {"text": "Unknown action"}
				game_state.set_metadata("last_gloria_auto_turn", current_turn)
				print("[Narrative] Triggering automatic Gloria intervention (Positive Energy <= 30)")
				request_gloria_intervention(last_choice)
				return
		_update_story_choices([], sanitized)
func _handle_mission_completion(last_text: String) -> void:
	if not story_scene or not story_scene.flow_controller:
		return
	if story_scene.has_method("show_mission_complete_countdown"):
		story_scene.show_mission_complete_countdown(30.0)
	if story_scene.choice_controller:
		story_scene.choice_controller.hide_choice_buttons()
		if story_scene.choice_controller.has_method("clear_and_hide"):
			story_scene.choice_controller.clear_and_hide()
	_night_cycle_pending = true
	request_night_cycle_generation(last_text, true)
	await story_scene.get_tree().create_timer(30.0).timeout
	if _night_cycle_pending:
		print("[Narrative] Night cycle generation timed out (30s). Forcing transition with fallback.")
		_night_cycle_pending = false
		var game_state = get_game_state()
		if game_state and game_state.debug_force_mission_complete:
			print("[Narrative] Clearing stuck debug_force_mission_complete flag on timeout.")
			game_state.debug_force_mission_complete = false
		var fallback_payload = {
			"reflection_text": last_text,
			"teacher_chan_text": "...",
			"concert_lyrics": ["(Lyrics unavailable due to timeout)"],
			"honeymoon_text": "...",
			"prayer_prompt": "Pray."
		}
		story_scene.hide_loading()
		story_scene.flow_controller.enter_night_cycle(fallback_payload)
func request_night_cycle_generation(last_text: String, is_background: bool = false) -> void:
	var ai_manager = get_ai_manager()
	var game_state = get_game_state()
	if not ai_manager or not game_state:
		return
	var lang: String = game_state.current_language
	var prompt: String = _build_night_cycle_prompt(last_text, lang)
	var context: Dictionary = {
		"purpose": "night_cycle",
		"last_text": last_text,
		"is_background": is_background
	}
	if not is_background:
		story_scene.show_loading("Generating night cycle content...")
	var callback := Callable(self, "_on_night_cycle_generated")
	_store_last_request("night_cycle", prompt, context, callback)
	ai_manager.generate_story(prompt, context, callback)
func _build_night_cycle_prompt(last_text: String, lang: String) -> String:
	var prompt_parts: Array[String] = []
	if lang == "zh":
		prompt_parts.append("=== 夜間循環生成 ===")
		prompt_parts.append("任務剛結束。請生成夜間結算的內容。")
		prompt_parts.append("上一段故事：%s" % last_text)
		prompt_parts.append("\n請生成一個 JSON 物件，包含以下欄位：")
		prompt_parts.append("- reflection_text: 針對上文的簡短反思 (50-100字)")
		prompt_parts.append("- teacher_chan_text: 陳老師的洗腦佈道 (100字)")
		prompt_parts.append("- song_title: 演唱會歌曲名稱")
		prompt_parts.append("- concert_lyrics: 字串陣列 (Array of Strings)，8-12句歌詞，每句 10-15 字，風格為毒性正能量/邪教崇拜")
		prompt_parts.append("- honeymoon_text: 描述短暫且虛假的蜜月期平靜 (50字)")
		prompt_parts.append("- prayer_prompt: 引導玩家進行下一輪祈禱的提示語")
	else:
		prompt_parts.append("=== Night Cycle Generation ===")
		prompt_parts.append("Mission just ended. Generate night cycle content.")
		prompt_parts.append("Last story text: %s" % last_text)
		prompt_parts.append("\nGenerate a JSON object with these fields:")
		prompt_parts.append("- reflection_text: Brief reflection on the above (50-100 words)")
		prompt_parts.append("- teacher_chan_text: Teacher Chan's brainwashing sermon (100 words)")
		prompt_parts.append("- song_title: Name of the concert song")
		prompt_parts.append("- concert_lyrics: Array of Strings, 8-12 lines, toxic positivity/cult vibe")
		prompt_parts.append("- honeymoon_text: Description of false honeymoon peace (50 words)")
		prompt_parts.append("- prayer_prompt: Prompt for the next prayer ritual")
	prompt_parts.append("\nOUTPUT MUST BE VALID JSON ONLY.")
	return "\n".join(prompt_parts)
func _on_night_cycle_generated(response: Dictionary) -> void:
	var is_background: bool = false
	if _last_request.has("context") and _last_request["context"] is Dictionary:
		is_background = _last_request["context"].get("is_background", false)
	if not is_background:
		story_scene.hide_loading()
	if is_background:
		if _night_cycle_pending:
			_night_cycle_pending = false
		else:
			print("[Narrative] Ignoring late night cycle response (timeout triggered)")
			return
	print("[DEBUG] _on_night_cycle_generated: Received response from AI.")
	if not response.get("success", false):
		_report_error("Night cycle generation failed")
		print("[DEBUG] AI response 'success' is false. Generating fallback payload.")
		var game_state = get_game_state()
		var lang = game_state.current_language if game_state else "en"
		var payload = {
			"reflection_text": _last_story_text,
			"teacher_chan_text": "...",
			"honeymoon_text": "...",
			"prayer_prompt": "..."
		}
		story_scene.flow_controller.enter_night_cycle(payload)
		return
	var content: String = String(response.get("content", response.get("text", "")))
	var json_parser := JSON.new()
	var payload: Dictionary = {}
	var json_block = _extract_primary_json_block(content)
	if json_block.is_empty():
		json_block = content
	if json_parser.parse(json_block) == OK and json_parser.data is Dictionary:
		payload = json_parser.data
		print("[DEBUG] Successfully parsed AI response as JSON.")
		if payload.has("concert_lyrics"):
			print("[DEBUG] Payload contains 'concert_lyrics' with %d items." % payload["concert_lyrics"].size())
		else:
			print("[DEBUG] WARNING: Payload is valid JSON but is MISSING 'concert_lyrics' key.")
	else:
		print("[DEBUG] ERROR: Failed to parse AI response as JSON. Generating fallback payload.")
		payload = {
			"reflection_text": _last_story_text,
			"teacher_chan_text": content.substr(0, 100),
			"concert_lyrics": ["Error parsing lyrics"],
			"honeymoon_text": "...",
			"prayer_prompt": "Pray."
		}
	print("[DEBUG] Final payload being sent to FlowController: %s" % str(payload).substr(0, 500))
	var game_state = get_game_state()
	if game_state and game_state.debug_force_mission_complete:
		print("[Narrative] Night cycle entered. Disabling debug_force_mission_complete.")
		game_state.debug_force_mission_complete = false
	story_scene.flow_controller.enter_night_cycle(payload)
func request_teammate_interference(teammate_id: String, player_action: String) -> void:
	var ai_manager = get_ai_manager()
	var game_state = get_game_state()
	if not ai_manager or not game_state:
		return
	var lang: String = game_state.current_language
	var prompt: String = _build_interference_prompt(teammate_id, player_action, lang)
	var context: Dictionary = {
		"purpose": "teammate_interference",
		"teammate_id": teammate_id,
		"action": player_action,
	}
	story_scene.show_loading("Generating teammate interference...")
	var interference_callback := Callable(self, "_on_teammate_interference_generated")
	_store_last_request("teammate_interference", prompt, context, interference_callback)
	ai_manager.generate_story(prompt, context, interference_callback)
func _build_interference_prompt(teammate_id: String, action: String, lang: String) -> String:
	var game_state = get_game_state()
	var teammate_name: String = _get_teammate_name(teammate_id)
	var prompt_parts: Array[String] = []
	if lang == "zh":
		prompt_parts.append("=== 隊友插手 ===")
		if game_state and game_state.is_in_honeymoon():
			prompt_parts.append("【蜜月期生效中】")
			prompt_parts.append("隊友 %s 這次竟然真的想幫忙，而且表現得異常體貼。" % teammate_name)
			prompt_parts.append("玩家正在：%s" % action)
			prompt_parts.append("\n描述這位隊友如何以約 %d 字提供「完美的幫助」：" % TEAMMATE_DESCRIPTION_WORDS)
			prompt_parts.append("- 態度異常友善，甚至有點肉麻")
			prompt_parts.append("- 行動成功，但讓人感到不安（因為這不正常）")
			prompt_parts.append("- 營造一種「暴風雨前的寧靜」")
		else:
			prompt_parts.append("隊友 %s 正準備用奇怪的方法幫倒忙。" % teammate_name)
			prompt_parts.append("玩家正在：%s" % action)
			prompt_parts.append("\n描述這位隊友如何以約 %d 字製造混亂：" % TEAMMATE_DESCRIPTION_WORDS)
			prompt_parts.append("- 反應要符合角色個性")
			prompt_parts.append("- 看似在幫忙卻讓情勢更糟")
			prompt_parts.append("- 留下新的麻煩或伏筆")
	else:
		prompt_parts.append("=== Teammate Interference ===")
		if game_state and game_state.is_in_honeymoon():
			prompt_parts.append("[HONEYMOON PHASE ACTIVE]")
			prompt_parts.append("Teammate %s is actually trying to be helpful and kind for once." % teammate_name)
			prompt_parts.append("Player action: " + action)
			prompt_parts.append("\nDescribe their 'perfect' assistance (~%d words)." % TEAMMATE_DESCRIPTION_WORDS)
			prompt_parts.append("- They are suspiciously friendly and competent")
			prompt_parts.append("- The action succeeds, but it feels eerie/unsettling")
			prompt_parts.append("- Create a sense of 'calm before the storm'")
		else:
			prompt_parts.append("Teammate %s intervenes in the worst possible way." % teammate_name)
			prompt_parts.append("Player action: " + action)
			prompt_parts.append("\nDescribe their dysfunctional attempt to 'help' (~%d words)." % TEAMMATE_DESCRIPTION_WORDS)
			prompt_parts.append("Stay true to their personality and create unexpected complications.")
	if lang == "zh":
		prompt_parts.append("\n\n附上場景指令：")
		prompt_parts.append("[SCENE_DIRECTIVES]")
		prompt_parts.append("{")
		prompt_parts.append("  \"characters\": {")
		prompt_parts.append("    \"%s\": {\"expression\": \"expression_type\"}" % teammate_id)
		prompt_parts.append("  }")
		prompt_parts.append("}")
		prompt_parts.append("[/SCENE_DIRECTIVES]")
		prompt_parts.append("\n可用表情：neutral, happy, sad, angry, confused, shocked, thinking, embarrassed")
		prompt_parts.append("表情需符合隊友此刻的態度。")
	else:
		prompt_parts.append("\n\nIMPORTANT: Include scene directives in this format:")
		prompt_parts.append("[SCENE_DIRECTIVES]")
		prompt_parts.append("{")
		prompt_parts.append("  \"characters\": {")
		prompt_parts.append("    \"%s\": {\"expression\": \"expression_type\"}" % teammate_id)
		prompt_parts.append("  }")
		prompt_parts.append("}")
		prompt_parts.append("[/SCENE_DIRECTIVES]")
		prompt_parts.append("\nAvailable expressions: neutral, happy, sad, angry, confused, shocked, thinking, embarrassed")
		prompt_parts.append("Choose the expression that matches their meddling mood.")
	return "\n".join(prompt_parts)
func _get_teammate_name(teammate_id: String) -> String:
	const TEAMMATE_NAMES := {
		"logic_larry": "Logic Larry",
		"positive_gloria": "Gloria",
		"chaos_charlie": "Chaos Charlie",
	}
	return TEAMMATE_NAMES.get(teammate_id, teammate_id)
func _on_teammate_interference_generated(response: Dictionary) -> void:
	story_scene.hide_loading()
	if not response.get("success", false):
		return
	var content: String = String(response.get("content", response.get("text", "")))
	if content.is_empty():
		return
	var ai_manager = get_ai_manager()
	if not ai_manager:
		return
	var directives = ai_manager.parse_scene_directives(content)
	if not directives.is_empty():
		if directives.has("characters"):
			directives["characters"] = _normalize_character_directives(directives.get("characters", { }))
		if directives.has("scene"):
			directives["scene"] = _normalize_scene_directives(directives.get("scene", { }))
		story_scene.apply_scene_directives(directives)
	var clean_content = ai_manager.extract_story_content(content)
	var sanitized: String = StoryUIHelper.sanitize_story_text(clean_content)
	var game_state = get_game_state()
	var lang: String = game_state.current_language if game_state else "en"
	var prefix: String = "[TEAMMATE INTERFERENCE]\n\n"
	if lang == "zh":
		prefix = "【隊友插手】\n\n"
	var combined_text := prefix + sanitized
	_update_story_display(combined_text)
	_last_story_text = combined_text
	_last_story_id += 1
	_update_story_choices([], combined_text)
func request_gloria_intervention(choice: Dictionary) -> void:
	var ai_manager = get_ai_manager()
	var game_state = get_game_state()
	if not ai_manager or not game_state:
		return
	var lang: String = game_state.current_language
	var prompt: String = _build_gloria_prompt(choice, lang)
	var context: Dictionary = {
		"purpose": "gloria_intervention",
		"choice": choice,
	}
	game_state.set_metadata("last_gloria_auto_turn", game_state.mission_turn_count)
	story_scene.show_loading("Generating Gloria intervention...")
	_is_generating = true
	var gloria_callback := Callable(self, "_on_gloria_intervention_generated")
	_store_last_request("gloria_intervention", prompt, context, gloria_callback)
	ai_manager.generate_story(prompt, context, gloria_callback)
func _build_gloria_prompt(choice: Dictionary, lang: String) -> String:
	var prompt_parts: Array[String] = []
	if lang == "zh":
		prompt_parts.append("=== Gloria 正能量轟炸 ===")
		prompt_parts.append("玩家的正能量過低，Gloria 決定用超級雞湯逼迫他們振作。")
		prompt_parts.append("玩家剛剛選擇：%s" % choice.get("text", ""))
		prompt_parts.append("\n請寫出 80-120 字的簡短演說，充滿偽關懷與情緒勒索：")
		prompt_parts.append("1. 表面安慰、實際否定玩家感受")
		prompt_parts.append("2. 暗示問題在於玩家不夠正面")
		prompt_parts.append("3. 以荒謬的正能量目標施壓")
		prompt_parts.append("\n重要限制：")
		prompt_parts.append("- 這是獨立的介入事件，不是主線故事")
		prompt_parts.append("- 不要生成任何選項或選擇預覽")
		prompt_parts.append("- 不要包含 [Choice Preview] 或任何選擇列表")
		prompt_parts.append("- 只輸出 Gloria 的演講內容，保持簡短（80-120字）")
	else:
		prompt_parts.append("=== Gloria's Positive Energy Bombardment ===")
		prompt_parts.append("Player's positive energy is too low, so Gloria interferes.")
		prompt_parts.append("Player just chose: " + choice.get("text", ""))
		prompt_parts.append("\nWrite a SHORT 80-120 word speech dripping with toxic positivity:")
		prompt_parts.append("1. Pretend to care while gaslighting")
		prompt_parts.append("2. Blame the player for being 'negative'")
		prompt_parts.append("3. Demand absurd optimism and compliance")
		prompt_parts.append("\nCRITICAL CONSTRAINTS:")
		prompt_parts.append("- This is a standalone intervention, NOT the main story")
		prompt_parts.append("- Do NOT generate any choices or choice previews")
		prompt_parts.append("- Do NOT include [Choice Preview] or any choice lists")
		prompt_parts.append("- Output ONLY Gloria's speech, keep it SHORT (80-120 words max)")
	if lang == "zh":
		prompt_parts.append("\n\n附上場景指令：")
		prompt_parts.append("[SCENE_DIRECTIVES]")
		prompt_parts.append("{")
		prompt_parts.append("  \"characters\": {")
		prompt_parts.append("    \"gloria\": {\"expression\": \"expression_type\"}")
		prompt_parts.append("  }")
		prompt_parts.append("}")
		prompt_parts.append("[/SCENE_DIRECTIVES]")
		prompt_parts.append("\n建議表情：happy 或 thinking，視她的強迫氛圍調整。")
		prompt_parts.append("演講內容應放在 [SCENE_DIRECTIVES] 區塊「之後」。不要把演講放在 JSON 裡面。")
	else:
		prompt_parts.append("\n\nInclude this scene directive, then your SHORT speech:")
		prompt_parts.append("[SCENE_DIRECTIVES]")
		prompt_parts.append("{")
		prompt_parts.append("  \"characters\": {")
		prompt_parts.append("    \"gloria\": {\"expression\": \"expression_type\"}")
		prompt_parts.append("  }")
		prompt_parts.append("}")
		prompt_parts.append("[/SCENE_DIRECTIVES]")
		prompt_parts.append("\nAvailable expressions: neutral, happy, sad, angry, confused, shocked, thinking, embarrassed")
		prompt_parts.append("Pick one that matches her manipulative tone (usually happy or thinking).")
		prompt_parts.append("Place the speech content AFTER the [SCENE_DIRECTIVES] block. Do not put the speech inside the JSON.")
	return "\n".join(prompt_parts)
func _on_gloria_intervention_generated(response: Dictionary) -> void:
	_is_generating = false
	story_scene.hide_loading()
	if not response.get("success", false):
		return
	var content: String = String(response.get("content", response.get("text", "")))
	if content.is_empty():
		return
	var ai_manager = get_ai_manager()
	if not ai_manager:
		return
	var directives = ai_manager.parse_scene_directives(content)
	if not directives.is_empty():
		if directives.has("characters"):
			directives["characters"] = _normalize_character_directives(directives.get("characters", { }))
		if directives.has("scene"):
			directives["scene"] = _normalize_scene_directives(directives.get("scene", { }))
		story_scene.apply_scene_directives(directives)
	var clean_content = ai_manager.extract_story_content(content)
	if clean_content.strip_edges().begins_with("{"):
		var json_check = JSON.new()
		if json_check.parse(clean_content) == OK and json_check.data is Dictionary:
			var data = json_check.data
			if data.has("speech"):
				clean_content = String(data["speech"])
			elif data.has("text"):
				clean_content = String(data["text"])
			elif data.has("content"):
				clean_content = String(data["content"])
			elif data.has("gloria_text"):
				clean_content = String(data["gloria_text"])
			elif data.has("message"):
				clean_content = String(data["message"])
			elif data.has("story_text"):
				clean_content = String(data["story_text"])
	if clean_content.strip_edges().is_empty() and not content.strip_edges().is_empty():
		if not content.strip_edges().begins_with("[SCENE"):
			clean_content = content
	if clean_content.strip_edges().is_empty() or clean_content.strip_edges().begins_with("{"):
		print("[Narrative] Gloria intervention content invalid/empty. Using fallback.")
		clean_content = "Gloria glares at you silently..."
	print("[Narrative] Showing Gloria overlay with content length: %d" % clean_content.length())
	story_scene.overlay_controller.show_gloria_overlay(clean_content)
func on_ai_request_progress(update: Dictionary) -> void:
	var progress_info: Dictionary = StoryUIHelper.parse_progress_update(update)
	if story_scene.ui_controller:
		story_scene.ui_controller.update_loading_progress(progress_info)
func on_ai_error(error_message: String) -> void:
	_report_error(
		"AI Error: %s" % error_message,
		{"error_message": error_message}
	)
	if story_scene.ui_controller:
		story_scene.hide_loading()
	var game_state = get_game_state()
	var lang: String = game_state.current_language if game_state else "en"
	var error_display: String = ""
	if lang == "zh":
		error_display = "AI 生成失敗：" + error_message
	else:
		error_display = "AI generation failed: " + error_message
	_update_story_display(error_display)
