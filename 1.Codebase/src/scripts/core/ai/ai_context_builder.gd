extends RefCounted
class_name AIContextBuilder
const STATIC_CONTEXT_EN := """Glorious Deliverance Agency 1 (GDA1) operates in a world cursed by compulsory "Positive Energy".
- The propaganda is a satire of forced optimism; every forced smile feeds the cosmic Void Entropy.
- Gloria leads the agency; Donkey, ARK, and One are unreliable teammates whose optimism accelerates collapse.
- The player is the lone rational agent. They must surface contradictions and treat "success" as failure in disguise."""
const STATIC_CONTEXT_ZH := """榮耀虛無機構 1（GDA1）運作於被強制「正能量」詛咒的世界。
- 這種宣傳是對強迫樂觀的諷刺；每一個被迫的笑容都在餵養宇宙虛空熵。
- Gloria 領導機構；Donkey、ARK 和 One 是不可靠的隊友，他們的樂觀加速了崩潰。
- 玩家是唯一理性的行動者。他們必須揭露矛盾，並將「成功」視為偽裝的失敗。"""
const NON_NEGOTIABLE_RULES_EN := """
Immutable directives:
1. Positive Energy always increases entropy - apparent victories must hide tangible damage.
2. Maintain dark humor and calm irony. Never reward blind optimism - expose the curse instead.
3. Obey the notes register. Do not contradict recorded facts, character motivations, or prior catastrophes."""
const NON_NEGOTIABLE_RULES_ZH := """
不可更改的指令：
1. 正能量總是增加熵 - 表面上的勝利必定隱藏實質傷害。
2. 保持黑色幽默與冷靜諷刺。絕不獎勵盲目樂觀 - 揭露詛咒。
3. 遵守記錄。不得與已記錄的事實、角色動機或先前災難矛盾。"""
const SCENE_DIRECTIVES_INSTRUCTIONS_EN := """
=== SCENE DIRECTIVES SYSTEM ===
IMPORTANT: Include scene directives in your response to control the visual stage.

Format your response with TWO sections:
1. Story narrative (the main story text)
2. Scene directives (structured JSON for visual updates)

Scene Directives Format:
[SCENE_DIRECTIVES]
{
  "scene": {
	"background": "background_id",
	"atmosphere": "dark|mysterious|bright|tense",
	"lighting": "dim|bright|normal"
  },
  "characters": {
	"protagonist": {"expression": "neutral|happy|sad|angry|confused|shocked|thinking|embarrassed", "visible": true},
	"gloria": {"expression": "angry", "visible": true},
	"donkey": {"expression": "confused", "visible": true},
	"ark": {"expression": "thinking", "visible": false},
	"one": {"expression": "neutral", "visible": false},
	"teacher_chan": {"expression": "happy", "visible": false}
  },
  "assets": [
	{"id": "Generic_Lever", "contextual_name": "Rusty Control Lever", "description": "A suspicious lever"},
	{"category": "npc", "id": "generic_guard", "slot": 1, "contextual_name": "Guard posted by the door"}
  ]
}
[/SCENE_DIRECTIVES]

Available Backgrounds: default, prayer, forest, cave, temple, ruins, laboratory, throne_room, bridge, portal_area, water, fire, garden, dungeon, crystal_cavern, library, safe_zone, battlefield

Available Expressions: neutral, happy, sad, angry, confused, shocked, thinking, embarrassed

Available NPC Portraits: generic_villager_male, generic_villager_female, generic_guard, generic_merchant, generic_elder, generic_child, generic_priest, generic_scientist

Guidelines:
- Always include scene directives after the story narrative
- Update character expressions to match the emotional tone
- Change backgrounds when entering new locations
- Use atmosphere and lighting to enhance mood
- Only show characters that are present in the scene
- Include assets from the mission in the assets array with contextual names
- To place supporting NPCs, add up to three assets entries with category "npc" and optional slot (1-3) matching the available portraits
"""
const SCENE_DIRECTIVES_INSTRUCTIONS_ZH := """
=== 場景指令系統 ===
重要：在你的回應中包含場景指令以控制視覺舞台。

[格式請參考英文版說明，使用相同的JSON結構]
"""
const SHORT_TERM_WINDOW := 6
var memory_store 
var game_state 
var asset_registry 
var background_loader 
var ai_system_persona: String = "You are the story director for Glorious Deliverance Agency 1 (GDA1)."
var voice_bridge 
func _init(mem_store, gs = null, ar = null, bl = null):
	memory_store = mem_store
	game_state = gs
	asset_registry = ar
	background_loader = bl
func set_voice_bridge(vb) -> void:
	voice_bridge = vb
func set_system_persona(persona: String) -> void:
	ai_system_persona = persona
func build_context_prompt(prompt: String, context: Dictionary) -> Array:
	var messages: Array = []
	var language = game_state.current_language if game_state else "en"
	messages.append_array(_get_static_context_messages(language))
	messages.append({ "role": "system", "content": ai_system_persona })
	messages.append({ "role": "assistant", "content": "Acknowledged. I will maintain ironic, pessimistic storytelling for GDA1 while enforcing the recorded facts." })
	messages.append_array(_get_entropy_modifier_message(language))
	if memory_store:
		messages.append_array(memory_store.get_long_term_context(language))
		messages.append_array(memory_store.get_notes_context(language))
		for entry in memory_store.get_short_term_memory():
			messages.append(entry.duplicate(true))
	var user_message_content = _build_user_message(prompt, context, language)
	var user_message := { "role": "user", "content": user_message_content }
	var parts_array: Array = [{ "text": user_message_content }]
	var voice_part := _build_voice_inline_part()
	if not voice_part.is_empty():
		parts_array.append(voice_part)
		user_message["voice_inline_attached"] = true
	user_message["parts"] = parts_array
	messages.append(user_message)
	return messages
func _build_user_message(prompt: String, context: Dictionary, language: String) -> String:
	var content := ""
	var language_instruction := ""
	if language == "en":
		language_instruction = "IMPORTANT: Respond in English. All narrative, dialogue, and descriptions must be in English.\n"
	else:
		language_instruction = "重要：請用繁體中文回應。所有敘事、對話和描述必須使用繁體中文。\n"
	content += "=== SESSION DATA ===\n"
	content += language_instruction
	content += _build_meta_context(context)
	content += _build_recent_events(language)
	content += _build_butterfly_context(language)
	content += _build_player_reflections(language)
	content += _build_asset_context(context)
	content += _build_stats_context(context)
	content += "\n=== PROMPT ===\n"
	content += prompt.strip_edges()
	return content
func _get_static_context_messages(language: String) -> Array:
	var static_text = STATIC_CONTEXT_ZH if language != "en" else STATIC_CONTEXT_EN
	var rules_text = NON_NEGOTIABLE_RULES_ZH if language != "en" else NON_NEGOTIABLE_RULES_EN
	var directives_text = SCENE_DIRECTIVES_INSTRUCTIONS_ZH if language != "en" else SCENE_DIRECTIVES_INSTRUCTIONS_EN
	var messages := [
		{ "role": "system", "content": static_text },
		{ "role": "system", "content": rules_text },
		{ "role": "system", "content": directives_text },
	]
	if background_loader and background_loader.has_method("get_backgrounds_for_ai_prompt"):
		var backgrounds_text = background_loader.get_backgrounds_for_ai_prompt()
		messages.append({ "role": "system", "content": backgrounds_text })
	return messages
func _get_entropy_modifier_message(language: String) -> Array:
	if not game_state or not game_state.has_method("calculate_void_entropy"):
		return []
	var entropy: float = game_state.calculate_void_entropy()
	var threshold: String = game_state.get_entropy_threshold() if game_state.has_method("get_entropy_threshold") else "low"
	if threshold == "low":
		return []
	var modifier_text: String = ""
	if threshold == "high":
		if language == "en":
			modifier_text = """[ENTROPY: CRITICAL - Level %.2f]
The world is succumbing to chaos and absurdity. The Void Entropy has reached critical levels.

MANDATORY NARRATIVE DIRECTIVES:
- Generate surreal, darkly humorous, and deeply ironic events
- Directly subvert the player's recent positive actions with twisted consequences
- Embrace absurdist logic and nonsensical cause-and-effect
- Reality itself should feel unstable and dreamlike
- Mock optimism with grotesque exaggerations
- Create situations where "success" becomes indistinguishable from failure

The higher the Positive Energy, the more reality fractures. This is the curse of forced optimism.""" % entropy
		else:
			modifier_text = """[熵值：臨界 - 等級 %.2f]
世界正在陷入混亂與荒謬。虛空熵已達到臨界水平。

強制敘事指令：
- 生成超現實、黑暗幽默和深度諷刺的事件
- 直接顛覆玩家最近的積極行動，帶來扭曲的後果
- 擁抱荒誕邏輯和無邏輯的因果關係
- 現實本身應該感覺不穩定和夢幻
- 用怪誕的誇張嘲笑樂觀主義
- 創造「成功」與失敗難以區分的局面

正能量越高，現實就越破裂。這就是強制樂觀的詛咒。""" % entropy
	elif threshold == "medium":
		if language == "en":
			modifier_text = """[ENTROPY: ELEVATED - Level %.2f]
The world feels slightly unreal. The boundary between normal and absurd is blurring.

NARRATIVE GUIDANCE:
- Introduce strange or unexpected elements into otherwise normal situations
- Add subtle wrongness to familiar things
- Layer ironic twists into positive outcomes
- Let optimistic actions have peculiar side effects
- Reality should feel "off" but not yet chaotic
The Void Entropy is rising. Consequences are becoming unpredictable.""" % entropy
		else:
			modifier_text = """[熵值：提升 - 等級%.2f]
世界感覺有些不真實。正常與荒謬之間的界限正在模糊。

敘事指導：
- 將奇怪或意外的元素引入原本正常的情況
- 為熟悉的事物添加微妙的錯誤感
- 在積極結果中層疊諷刺的轉折
- 讓樂觀的行動產生奇異的副作用
- 現實應該感覺「不對」但還未陷入混亂
虛空熵正在上升。後果變得不可預測。""" % entropy
	if modifier_text.is_empty():
		return []
	return [{ "role": "system", "content": modifier_text }]
func _build_meta_context(context: Dictionary) -> String:
	var meta_lines: Array = []
	if context.has("purpose"):
		var safe_purpose := _sanitize_text(str(context["purpose"]))
		if not safe_purpose.is_empty():
			meta_lines.append("Purpose: %s" % safe_purpose)
	if context.has("choice_text"):
		var safe_choice := _sanitize_text(str(context["choice_text"]))
		if not safe_choice.is_empty():
			meta_lines.append("Player choice: %s" % safe_choice)
	if context.has("success"):
		meta_lines.append("Success check: %s" % ("true" if bool(context["success"]) else "false"))
	if context.has("prayer_text"):
		var safe_prayer := _sanitize_text(str(context["prayer_text"]), 320)
		if not safe_prayer.is_empty():
			meta_lines.append("Player prayer: %s" % safe_prayer)
	if context.has("player_action"):
		var safe_action := _sanitize_text(str(context["player_action"]))
		if not safe_action.is_empty():
			meta_lines.append("Player action: %s" % safe_action)
	if context.has("teammate"):
		var safe_teammate := _sanitize_text(str(context["teammate"]))
		if not safe_teammate.is_empty():
			meta_lines.append("Current teammate: %s" % safe_teammate)
	if meta_lines.size() > 0:
		return "\n".join(meta_lines) + "\n"
	return ""
func _build_recent_events(language: String) -> String:
	if not game_state or not game_state.has_method("get_recent_event_notes"):
		return ""
	var recent_event_lines = game_state.get_recent_event_notes(SHORT_TERM_WINDOW, language)
	if recent_event_lines.size() == 0:
		return ""
	var content := "\n=== RECENT EVENTS ===\n"
	for line in recent_event_lines:
		content += "- " + line + "\n"
	return content
func _build_butterfly_context(language: String) -> String:
	if not game_state or not game_state.has_method("get") or game_state.get("butterfly_tracker") == null:
		return ""
	var butterfly_tracker = game_state.get("butterfly_tracker")
	if not butterfly_tracker or not butterfly_tracker.has_method("get_context_for_ai"):
		return ""
	var butterfly_context = butterfly_tracker.get_context_for_ai(language)
	if butterfly_context.is_empty():
		return ""
	var content := "\n=== BUTTERFLY EFFECT: PAST CHOICES ===\n"
	content += butterfly_context
	if language == "en":
		content += "Consider referencing one of these past choices in your response if narratively appropriate.\n"
	else:
		content += "考慮在您的回應中引用其中一個過去的選擇（如果敘事合理）。\n"
	if butterfly_tracker.has_method("suggest_choice_for_callback"):
		var suggested_choice = butterfly_tracker.suggest_choice_for_callback()
		if not suggested_choice.is_empty():
			var choice_id = suggested_choice.get("id", "")
			var choice_text = suggested_choice.get("choice_text", "")
			var scenes_ago = butterfly_tracker.current_scene_number - suggested_choice.get("scene_number", 0) if butterfly_tracker.has("current_scene_number") else 0
			if language == "en":
				content += "\n? SUGGESTED CALLBACK: Consider having \"%s\" (from %d scenes ago, ID: %s) affect the current situation.\n" % [choice_text.left(60), scenes_ago, choice_id]
			else:
				content += "\n? 建議回調：考慮讓 \"%s\" （來自 %d 幕前，ID: %s）影響當前情況。\n" % [choice_text.left(60), scenes_ago, choice_id]
	return content
func _build_player_reflections(language: String) -> String:
	if not game_state or not game_state.has_method("get_recent_journal_entries"):
		return ""
	var reflections: Array = game_state.get_recent_journal_entries(3)
	if reflections.size() == 0:
		return ""
	var content := "\n=== PLAYER REFLECTIONS ===\n"
	for entry in reflections:
		var timestamp = str(entry.get("timestamp", ""))
		var reflection_text = str(entry.get("text", "")).strip_edges()
		var summary_text = str(entry.get("ai_summary", "")).strip_edges()
		if language == "en":
			var line = ""
			if not timestamp.is_empty():
				line += "[" + timestamp + "] "
			line += reflection_text
			if not summary_text.is_empty():
				line += " | Insight: " + summary_text
			content += "- " + line + "\n"
		else:
			var zh_line = ""
			if not timestamp.is_empty():
				zh_line += "[" + timestamp + "] "
			zh_line += reflection_text
			if not summary_text.is_empty():
				zh_line += " | 洞察：" + summary_text
			content += " - " + zh_line + "\n"
	return content
func _build_asset_context(context: Dictionary) -> String:
	if not asset_registry or not asset_registry.has_method("get_assets_for_context"):
		return ""
	var assets_for_prompt: Array = asset_registry.get_assets_for_context(context)
	if assets_for_prompt.size() == 0:
		return ""
	if game_state and game_state.has_method("set_metadata"):
		var asset_ids: Array = []
		for asset in assets_for_prompt:
			asset_ids.append(asset.get("id", ""))
		game_state.set_metadata("recent_assets_data", assets_for_prompt)
		if asset_registry.has_method("get_asset_icons"):
			game_state.set_metadata("recent_asset_icons", asset_registry.get_asset_icons(assets_for_prompt))
		game_state.set_metadata("current_asset_ids", asset_ids)
	var content := "\n=== AVAILABLE ASSETS ===\n"
	if asset_registry.has_method("format_assets_for_prompt"):
		content += asset_registry.format_assets_for_prompt(assets_for_prompt) + "\n"
	content += "Newest asset IDs appear last; treat them as the freshest context.\n"
	return content
func _build_stats_context(context: Dictionary) -> String:
	var stat_parts: Array = []
	if context.has("reality_score"):
		stat_parts.append("Reality %d / 100" % int(context["reality_score"]))
	if context.has("positive_energy"):
		stat_parts.append("Positive %d / 100" % int(context["positive_energy"]))
	if context.has("entropy_level"):
		stat_parts.append("Entropy %d" % int(context["entropy_level"]))
	elif context.has("entropy"):
		stat_parts.append("Entropy %d" % int(context["entropy"]))
	if stat_parts.size() > 0:
		return "Stats: " + ", ".join(stat_parts) + "\n"
	return ""
func _build_voice_inline_part() -> Dictionary:
	if not voice_bridge or not voice_bridge.has_method("build_inline_audio_part"):
		return { }
	return voice_bridge.build_inline_audio_part()
func _sanitize_text(text: String, max_length: int = 256) -> String:
	var sanitized := text.strip_edges()
	if sanitized.length() > max_length and max_length > 0:
		sanitized = sanitized.substr(0, max_length)
	return sanitized
