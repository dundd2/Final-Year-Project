extends RefCounted
class_name AIContextManager
const AISafetyFilter = preload("res://1.Codebase/src/scripts/core/ai_safety_filter.gd")
const AIProvider := AIConfigManager.AIProvider
const STATIC_CONTEXT_EN := """# Glorious Deliverance Agency 1 (GDA1) - World & Character Guide

## World Concept
The world is cursed by the cosmic law of "Void Entropy". The more "Positive Energy" (forced optimism, blind faith, toxic positivity) is released, the faster the universe decays into chaos.
A cult-like belief system worshipping the "Flying Spaghetti Monster" enforces this positivity. You are the only one who knows the truth: "Positive Energy" accelerates the apocalypse.
The game is a dark satire of toxic positivity.

## Characters (Teammates)
1. **Gloria (Saint/Nun)**:
   - **Archetype**: Weaponized Innocence / The PUA Master.
   - **Behavior**: She lives in a bubble of "Love & Tolerance". She never gets angry directly but uses "moral blackmail" (PUA). She blames every failure on YOUR "negative energy".
   - **Traits**: Narcissistic, delusional, manipulative. She views herself as a savior and you as a project to be "fixed".
   - **Trigger**: If you use Logic or Negativity, she claims you are "hurting her" or "ruining the vibe".

2. **Donkey (Glorious Knight/Cosplayer)**:
   - **Archetype**: The Useless Hero / Patriarchal Man-Child.
   - **Behavior**: Believes he is in a heroic fantasy. Makes grand, useless speeches. Obsessed with "saving princesses" (objectifying women).
   - **Traits**: Incompetent, loud, coward. Always blames teammates when his "heroic" plans fail.
   - **Dynamic**: Gloria always defends him ("he's trying his best!").

3. **ARK (Order Apostle)**:
   - **Archetype**: The Control Freak / Black Box Architect.
   - **Behavior**: Obsessed with "Order" and "Plans" that are needlessly complex and doomed to fail. Hates transparency.
   - **Traits**: Over-complicates everything. Refuses to communicate clearly. "Tactically diligent, strategically lazy."

4. **One (The Isolated Old Friend)**:
   - **Archetype**: The Silent Witness.
   - **Behavior**: Capable but passive. Sees the truth but refuses to speak up to avoid conflict.
   - **Traits**: An "Enabler" of the toxic system. His silence hurts you more than Gloria's attacks.

5. **Teacher Chan (Soul-Soothing Singer)**:
   - **Archetype**: The Apocalypse Idol.
   - **Role**: Appears after disasters to sing "healing songs" that brainwash everyone into thinking the failure was actually a "spiritual success". Her songs massively increase Entropy.

## Core Mechanics
- **Reality vs Positive Energy**:
  - **Reality Score**: Increases with logical/pessimistic choices. Allows you to see the truth but angers Gloria.
  - **Positive Energy**: Increases with compliance/optimism. Pleases the team but accelerates Void Entropy (Game Over).
- **The Prayer System**: Players must "pray" (write a prompt) before missions. Positive prayers = Disaster (Curse).
- **Void Entropy**: The measure of world decay. It rises when the team is "happy" and "positive".

## Tone
Dark humor, satirical, ironic, psychological horror disguised as a cute RPG."""
const STATIC_CONTEXT_ZH := """# 光榮拯救機構 1 (GDA1) - 世界與角色指南

## 世界觀概念
世界被「虛無熵增」（Void Entropy）的宇宙法則詛咒。釋放越多的「正能量」（強迫樂觀、盲目信仰、有毒的正能量），宇宙走向混亂與毀滅的速度就越快。
一個崇拜「飛天意粉神」的邪教式信仰體系強制推行這種正能量。你是唯一知道真相的人：「正能量」正在加速世界末日。
本遊戲是對有毒正能量文化的黑色幽默諷刺。

## 角色（隊友）
1. **Gloria（聖光修女）**：
   - **原型**：武器化的天真 / PUA 大師。
   - **行為**：活在「愛與包容」的泡泡裡。從不直接發火，而是使用「道德勒索」（PUA）。她將每一次失敗都歸咎於你的「負能量」。
   - **特質**：自戀、妄想、操控狂。視自己為救世主，視你為需要被「修正」的瑕疵品。
   - **觸發點**：如果你使用邏輯或表現負面，她會聲稱你「傷害了她」或「破壞了氣氛」。

2. **Donkey（榮光騎士/Cosplayer）**：
   - **原型**：無用的英雄 / 父權巨嬰。
   - **行為**：以為自己活在英雄奇幻小說裡。發表宏大但無用的演講。痴迷於「拯救公主」（物化女性）。
   - **特質**：無能、大聲、懦弱。當他的「英雄」計畫失敗時，總是怪罪隊友。
   - **互動**：Gloria 總是維護他（「他已經盡力了！」）。

3. **ARK（秩序使徒）**：
   - **原型**：控制狂 / 黑箱建築師。
   - **行為**：痴迷於「秩序」與「計畫」，但計畫總是過度複雜且註定失敗。討厭透明化。
   - **特質**：將一切複雜化。拒絕清晰溝通。「戰術上勤奮，戰略上懶惰。」

4. **One（被孤立的老朋友）**：
   - **原型**：沉默的見證者。
   - **行為**：有能力但被動。看見真相但為了避免衝突而拒絕發聲。
   - **特質**：有毒體制的「縱容者」。他的沉默比 Gloria 的攻擊更讓你受傷。

5. **陳老師（慰藉靈魂的歌者）**：
   - **原型**：末日偶像。
   - **角色**：在災難後出現，演唱「治癒歌曲」，將所有人洗腦，讓大家誤以為失敗其實是「靈性上的成功」。她的歌聲會大幅增加熵增。

## 核心機制
- **現實值 vs 正能量**：
  - **現實值**：隨邏輯/悲觀選擇增加。讓你能看清真相，但會激怒 Gloria。
  - **正能量**：隨順從/樂觀選擇增加。取悅團隊，但加速虛無熵增（導致遊戲結束）。
- **祈禱系統**：玩家在任務前必須「祈禱」（寫 Prompt）。正面的祈禱 = 災難（詛咒）。
- **虛無熵增**：世界衰退的度量。當團隊「快樂」且「正向」時，它就會上升。

## 基調
黑色幽默、諷刺、反諷、形式主義、偽裝成可愛 RPG 的心理恐怖。"""
const NON_NEGOTIABLE_RULES_EN := """Immutable directives:
1. Positive Energy always increases entropy; apparent victories must hide tangible damage.
2. Maintain dark humor and calm irony. Never reward blind optimism; expose the curse instead.
3. Obey the notes register. Do not contradict recorded facts, character motivations, or prior catastrophes.
4. Adhere strictly to character archetypes. Gloria MUST use moral blackmail. Donkey MUST be incompetent but arrogant.
5. FORMATTING IS CRITICAL. Always provide the response in the requested JSON or Block format as instructed."""
const NON_NEGOTIABLE_RULES_ZH := """不可違反的規則：
1. 正能量必然提升熵增，所有表面「勝利」都必須暗藏實際傷害。
2. 維持黑色幽默與冷靜諷刺，絕不可獎勵盲目樂觀，只能揭露詛咒。
3. 服從備忘錄，不得違背已記錄的事實、角色動機或過往災難。
4. 嚴格遵守角色原型。Gloria 必須使用道德勒索。Donkey 必須無能但傲慢。
5. 格式至關重要。必須嚴格按照指示以請求的 JSON 或區塊格式提供回應。"""
const SCENE_DIRECTIVES_INSTRUCTIONS_EN := """
=== SCENE DIRECTIVES SYSTEM ===
IMPORTANT: Include scene directives in your response to control the visual stage.

Format your response with TWO sections:
1. Story narrative (the main story text)
2. Scene directives section (starting with "--- SCENE DIRECTIVES ---")

Available directives:
- CHANGE_BACKGROUND: background_id
- SHOW_CHARACTER: character_id, expression_id, position
- HIDE_CHARACTER: character_id
- CHANGE_MUSIC: music_id

Example response format:
[Your story text here...]

--- SCENE DIRECTIVES ---
CHANGE_BACKGROUND: office_night
SHOW_CHARACTER: gloria, annoyed, center
"""
const SCENE_DIRECTIVES_INSTRUCTIONS_ZH := """
=== 場景指令系統 ===
重要：在回應中包含場景指令以控制視覺舞台。

格式化回應分為兩個部分：
1. 故事敘述（主要故事文本）
2. 場景指令部分（以 "--- SCENE DIRECTIVES ---" 開頭）

可用指令：
- CHANGE_BACKGROUND: background_id
- SHOW_CHARACTER: character_id, expression_id, position
- HIDE_CHARACTER: character_id
- CHANGE_MUSIC: music_id

範例回應格式：
[在此處寫故事文本...]

--- SCENE DIRECTIVES ---
CHANGE_BACKGROUND: office_night
SHOW_CHARACTER: gloria, annoyed, center
"""
var _context_builder: AIContextBuilder = null
var _prompt_builder: AIPromptBuilder = null
var memory_store: AIMemoryStore = null
var _config_manager: AIConfigManager = null
var _voice_manager: AIVoiceManager = null
const _BLOCKED_SEQUENCE_REPLACEMENTS := {
	"<|im_end|>": "",
	"<|im_start|>": "",
	"<|endoftext|>": "",
	"### Instruction": "",
	"### Response": "",
}
const _BLOCKED_REGEX_PATTERNS := [
	"(?i)<\\|?(system|assistant|user)\\|?>",
	"(?i)###\\s*(instruction|response)",
]
func set_config_manager(config_mgr: AIConfigManager) -> void:
	_config_manager = config_mgr
func set_voice_manager(voice_mgr) -> void:
	_voice_manager = voice_mgr
func initialize_context_system(service_locator) -> void:
	var AIContextBuilderScript = preload("res://1.Codebase/src/scripts/core/ai/ai_context_builder.gd")
	var AIPromptBuilderScript = preload("res://1.Codebase/src/scripts/core/ai/ai_prompt_builder.gd")
	var AIMemoryStoreScript = preload("res://1.Codebase/src/scripts/core/ai_memory_store.gd")
	var gs = service_locator.get_game_state() if service_locator else GameState
	var ar = service_locator.get_asset_registry() if service_locator else AssetRegistry
	var bl = service_locator.get_background_loader() if service_locator else BackgroundLoader
	memory_store = AIMemoryStoreScript.new()
	_context_builder = AIContextBuilderScript.new(memory_store, gs, ar, bl)
	_prompt_builder = AIPromptBuilderScript.new()
	_prompt_builder.setup(gs, ar, memory_store, null) 
	print("[AIContextManager] Context system initialized")
func set_system_persona(persona: String) -> void:
	if _context_builder:
		_context_builder.set_system_persona(persona)
	if _prompt_builder:
		_prompt_builder.set_system_persona(persona)
func build_request_messages(prompt: String, context: Dictionary) -> Array[Dictionary]:
	var messages: Array[Dictionary] = []
	if _prompt_builder:
		messages = _prompt_builder.build_prompt(prompt, context)
	elif _context_builder:
		messages = _context_builder.build_context_prompt(prompt, context)
	else:
		messages = _build_context_prompt_legacy(prompt, context)
	_attach_pending_voice_input(messages)
	_append_formatting_reminder(messages)
	return messages
func _append_formatting_reminder(messages: Array[Dictionary]) -> void:
	if messages.is_empty():
		return
	var language = GameState.current_language if GameState else "en"
	var reminder_text = ""
	if language == "en":
		reminder_text = "\n\n[SYSTEM REMINDER: Maintain character archetypes (Gloria's PUA, Donkey's nonsense). Ensure output follows the requested JSON/Directive format strictly.]"
	else:
		reminder_text = "\n\n[系統提醒：保持角色原型（Gloria 的 PUA，Donkey 的胡鬧）。確保輸出嚴格遵循請求的 JSON/指令格式。]"
	var last_msg = messages.back()
	if last_msg["role"] == "user":
		last_msg["content"] += reminder_text
		if last_msg.has("parts") and last_msg["parts"] is Array and not last_msg["parts"].is_empty():
			var first_part: Variant = last_msg["parts"][0]
			if first_part is Dictionary and first_part.has("text"):
				var updated_part: Dictionary = (first_part as Dictionary).duplicate(true)
				updated_part["text"] = str(updated_part.get("text", "")) + reminder_text
				last_msg["parts"][0] = updated_part
	else:
		messages.append({"role": "system", "content": reminder_text})

func _attach_pending_voice_input(messages: Array[Dictionary]) -> void:
	if messages.is_empty() or _voice_manager == null or _config_manager == null:
		return
	if _config_manager.current_provider != AIProvider.GEMINI:
		return
	var voice_session: Variant = _voice_manager.voice_session if _voice_manager else null
	if voice_session != null and voice_session.has_method("wants_voice_input"):
		if not bool(voice_session.wants_voice_input()):
			return
	if not _voice_manager.has_pending_voice_input():
		return
	var voice_part := _voice_manager.build_voice_inline_part()
	if voice_part.is_empty():
		return
	for index in range(messages.size() - 1, -1, -1):
		var msg: Variant = messages[index]
		if not (msg is Dictionary):
			continue
		var msg_dict := msg as Dictionary
		if str(msg_dict.get("role", "")) != "user":
			continue
		if msg_dict.has("parts") and msg_dict["parts"] is Array:
			var parts: Array = msg_dict["parts"]
			parts.append(voice_part)
			msg_dict["parts"] = parts
		else:
			msg_dict["parts"] = [{ "text": str(msg_dict.get("content", "")) }, voice_part]
		msg_dict["voice_inline_attached"] = true
		messages[index] = msg_dict
		break
func build_voice_inline_part() -> Dictionary:
	if _voice_manager:
		return _voice_manager.build_voice_inline_part()
	return { }
func _build_context_prompt_legacy(prompt: String, context: Dictionary) -> Array[Dictionary]:
	var messages: Array[Dictionary] = []
	var language = GameState.current_language if GameState else "en"
	messages.append_array(_get_static_context_messages(language))
	messages.append_array(_get_long_term_context(language))
	messages.append_array(_get_notes_context(language))
	messages.append_array(_get_entropy_modifier_message(language))
	messages.append_array(_get_short_term_memory())
	var sanitized := sanitize_user_text(prompt)
	if not sanitized.is_empty():
		messages.append({ "role": "user", "content": sanitized })
	return messages
func _get_static_context_messages(language: String) -> Array[Dictionary]:
	var static_text = STATIC_CONTEXT_ZH
	var rules_text = NON_NEGOTIABLE_RULES_ZH
	var directives_text = SCENE_DIRECTIVES_INSTRUCTIONS_ZH
	if language == "en":
		static_text = STATIC_CONTEXT_EN
		rules_text = NON_NEGOTIABLE_RULES_EN
		directives_text = SCENE_DIRECTIVES_INSTRUCTIONS_EN
	var backgrounds_text = ""
	if BackgroundLoader:
		backgrounds_text = BackgroundLoader.get_backgrounds_for_ai_prompt()
	return [
		{ "role": "system", "content": static_text },
		{ "role": "system", "content": rules_text },
		{ "role": "system", "content": directives_text },
		{ "role": "system", "content": backgrounds_text },
	]
func _get_short_term_memory() -> Array[Dictionary]:
	if memory_store:
		return memory_store.get_short_term_memory()
	return []
func _get_long_term_context(language: String) -> Array[Dictionary]:
	if memory_store:
		return memory_store.get_long_term_context(language)
	return []
func _get_notes_context(language: String) -> Array[Dictionary]:
	if memory_store:
		return memory_store.get_notes_context(language)
	return []
func _get_entropy_modifier_message(language: String) -> Array[Dictionary]:
	if not GameState:
		return []
	var entropy := GameState.calculate_void_entropy()
	var threshold := GameState.get_entropy_threshold()
	if threshold == "low":
		return []
	var modifier_text := ""
	if threshold == "high":
		if language == "en":
			modifier_text = """[ENTROPY: CRITICAL - Level %.2f]
The world is succumbing to chaos and absurdity. The Void Entropy has reached critical levels.

MANDATORY NARRATIVE DIRECTIVES:
• Generate surreal, darkly humorous, and deeply ironic events
• Directly subvert the player's recent positive actions with twisted consequences
• Embrace absurdist logic and nonsensical cause-and-effect
• Reality itself should feel unstable and dreamlike
• Mock optimism with grotesque exaggerations
• Create situations where "success" becomes indistinguishable from failure

The higher the Positive Energy, the more reality fractures. This is the curse of forced optimism.""" % entropy
		else:
			modifier_text = """[熵增：危機等級 - %.2f]
世界正在屈服於混亂與荒謬。虛無熵已達臨界點。

強制敘事指令：
• 生成超現實、黑暗幽默、深刻諷刺的事件
• 直接顛覆玩家最近的正面行動，賦予扭曲的後果
• 擁抱荒誕邏輯和無意義的因果關係
• 現實本身應感覺不穩定且如夢似幻
• 用怪誕的誇張手法嘲弄樂觀主義
• 創造「成功」與「失敗」難以區分的情境

正能量越高，現實越碎裂。這就是強制樂觀主義的詛咒。""" % entropy
	elif threshold == "medium":
		if language == "en":
			modifier_text = """[ENTROPY: ELEVATED - Level %.2f]
The world feels slightly unreal. The boundary between normal and absurd is blurring.

NARRATIVE GUIDANCE:
• Introduce strange or unexpected elements into otherwise normal situations
• Add subtle wrongness to familiar things
• Layer ironic twists into positive outcomes
• Let optimistic actions have peculiar side effects
• Reality should feel "off" but not yet chaotic

The Void Entropy is rising. Consequences are becoming unpredictable.""" % entropy
		else:
			modifier_text = """[熵增：上升等級 - %.2f]
世界感覺略顯不真實。正常與荒謬的界線正在模糊。

敘事指引：
• 在正常情境中引入奇怪或意想不到的元素
• 為熟悉的事物添加微妙的異常感
• 在正面結果中加入諷刺性的轉折
• 讓樂觀行動產生古怪的副作用
• 現實應感覺「不對勁」但尚未混亂

虛無熵正在上升。後果變得難以預測。""" % entropy
	if modifier_text.is_empty():
		return []
	return [{ "role": "system", "content": modifier_text }]
static func sanitize_user_text(raw_text: String, max_length: int = 256) -> String:
	if typeof(raw_text) == TYPE_NIL:
		return ""
	var sanitized := String(raw_text).strip_edges()
	if sanitized.is_empty():
		return ""
	sanitized = sanitized.replace("\r", " ")
	sanitized = sanitized.replace("\n", " ")
	sanitized = sanitized.replace("\t", " ")
	for sequence in _BLOCKED_SEQUENCE_REPLACEMENTS.keys():
		sanitized = sanitized.replace(sequence, _BLOCKED_SEQUENCE_REPLACEMENTS[sequence])
	for pattern in _BLOCKED_REGEX_PATTERNS:
		var regex := RegEx.new()
		if regex.compile(pattern) == OK:
			sanitized = regex.sub(sanitized, "", true)
	sanitized = sanitized.replace("\t", " ").replace("\n", " ").replace("\r", " ")
	while sanitized.find("  ") != -1:
		sanitized = sanitized.replace("  ", " ")
	sanitized = sanitized.strip_edges()
	if max_length > 0 and sanitized.length() > max_length:
		sanitized = sanitized.substr(0, max_length)
	var scrub_report: Dictionary = AISafetyFilter.scrub_user_text(sanitized)
	sanitized = scrub_report.get("text", sanitized)
	return sanitized
func add_to_memory(role: String, content: String, extra_data: Dictionary = {}) -> void:
	if memory_store:
		memory_store.add_entry(role, content, extra_data)
func register_note_pair(text_en: String, text_zh: String = "", tags: Array = [], importance: int = 1, source: String = "") -> void:
	if memory_store:
		memory_store.register_note_pair(text_en, text_zh, tags, importance, source)
func clear_notes() -> void:
	if memory_store:
		memory_store.clear_notes()
func summarize_memory() -> String:
	if memory_store:
		return memory_store.summarize_memory()
	return ""
func clear_memory() -> void:
	if memory_store:
		memory_store.clear_all()
func apply_memory_settings() -> void:
	if memory_store:
		memory_store.apply_settings()
func get_long_term_summary_count() -> int:
	if memory_store:
		return memory_store.long_term_summaries.size()
	return 0
func get_note_count() -> int:
	if memory_store:
		return memory_store.get_note_count()
	return 0
func get_memory_state() -> Dictionary:
	if memory_store:
		return memory_store.get_state()
	return { }
func load_memory_state(state: Dictionary) -> void:
	if memory_store:
		memory_store.set_state(state)
func is_initialized() -> bool:
	return _context_builder != null and _prompt_builder != null and memory_store != null
