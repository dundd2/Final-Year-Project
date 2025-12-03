extends RefCounted
const LANGUAGE_INSTRUCTIONS := {
	"en": "IMPORTANT: Respond in English. All narrative, dialogue, and descriptions must be in English.",
	"zh": "重要：請使用繁體中文回答。所有敘事、對話與描述必須使用繁體中文。",
}
const SECTION_HEADERS := {
	"session_data": {
		"en": "=== SESSION DATA ===",
		"zh": "=== 會話數據 ===",
	},
	"recent_events": {
		"en": "=== RECENT EVENTS ===",
		"zh": "=== 最近事件 ===",
	},
	"butterfly_effect": {
		"en": "=== BUTTERFLY EFFECT: PAST CHOICES ===",
		"zh": "=== 蝴蝶效應：過往選擇 ===",
	},
	"player_reflections": {
		"en": "=== PLAYER REFLECTIONS ===",
		"zh": "=== 玩家反思 ===",
	},
	"available_assets": {
		"en": "=== AVAILABLE ASSETS ===",
		"zh": "=== 可用資產 ===",
	},
	"prompt": {
		"en": "=== PROMPT ===",
		"zh": "=== 提示 ===",
	},
	"mission_generation": {
		"en": "=== Mission Generation ===",
		"zh": "=== 任務生成 ===",
	},
	"consequence_generation": {
		"en": "=== Consequence Generation ===",
		"zh": "=== 後果生成 ===",
	},
	"teammate_interference": {
		"en": "=== Teammate Interference ===",
		"zh": "=== 隊友干擾 ===",
	},
}
const BUTTERFLY_EFFECT_INSTRUCTIONS := {
	"reference_past": {
		"en": "Consider referencing one of these past choices in your response if narratively appropriate.",
		"zh": "如果敘事上合適，考慮在回應中提及這些過往選擇之一。",
	},
	"trigger_callback": {
		"en": "Use butterfly_tracker.trigger_consequence_for_choice() when a past choice should echo forward.",
		"zh": "當過往選擇應該產生迴響時，使用butterfly_tracker.trigger_consequence_for_choice()。",
	},
	"suggested_callback": {
		"en": "\n💡 SUGGESTED CALLBACK: Consider having \"%s\" (from %d scenes ago, ID: %s) affect the current situation.",
		"zh": "\n💡 建議回調：考慮讓「%s」（%d場景前，ID: %s）影響當前情況。",
	},
}
const ASSET_CONTEXT_INSTRUCTIONS := {
	"freshest_context": {
		"en": "Newest asset IDs appear last; treat them as the freshest context.",
		"zh": "最新的資產ID出現在最後；將它們視為最新鮮的背景資訊。",
	},
}
const MISSION_PROMPT_INSTRUCTIONS := {
	"create_scenario": {
		"en": "Create a new mission scenario for the player.",
		"zh": "為玩家創建新的任務場景。",
	},
	"generate_list": {
		"en": "Please generate:",
		"zh": "請生成：",
	},
	"scene_description": {
		"en": "1. Scene description (200-300 words)",
		"zh": "1. 場景描述（200-300字）",
	},
	"mission_objective": {
		"en": "2. Mission objective",
		"zh": "2. 任務目標",
	},
	"challenges": {
		"en": "3. Potential dilemmas or challenges",
		"zh": "3. 潛在的困境或挑戰",
	},
	"tone": {
		"en": "Maintain dark humor and satirical tone.",
		"zh": "保持黑色幽默和諷刺風格。",
	},
}
const CONSEQUENCE_PROMPT_INSTRUCTIONS := {
	"player_chose": {
		"en": "Player chose: %s",
		"zh": "玩家選擇：%s",
	},
	"outcome_success": {
		"en": "Outcome: Success",
		"zh": "結果：成功",
	},
	"outcome_failure": {
		"en": "Outcome: Failure",
		"zh": "結果：失敗",
	},
	"describe_consequences": {
		"en": "Describe the immediate consequences (%d-%d words).",
		"zh": "請描述這個選擇的直接後果（%d-%d字）。",
	},
	"include_header": {
		"en": "Include:",
		"zh": "包含：",
	},
	"immediate_events": {
		"en": "1. What happens immediately",
		"zh": "1. 立即發生的事情",
	},
	"npc_reactions": {
		"en": "2. NPC/environment reactions",
		"zh": "2. NPC/環境的反應",
	},
	"long_term_hints": {
		"en": "3. Hints of long-term effects",
		"zh": "3. 潛在的長期影響暗示",
	},
}
const TEAMMATE_INTERFERENCE_INSTRUCTIONS := {
	"teammate_interferes": {
		"en": "Teammate %s decides to interfere with player's action.",
		"zh": "隊友 %s 決定干擾玩家的行動。",
	},
	"player_action": {
		"en": "Player is: %s",
		"zh": "玩家正在：%s",
	},
	"describe_help": {
		"en": "Describe how the teammate 'helps' in their own dysfunctional way (%d words).",
		"zh": "描述隊友如何以他們自己功能失調的方式「幫助」（%d字）。",
	},
	"stay_true": {
		"en": "Stay true to their personality and create unexpected complications.",
		"zh": "忠實於他們的個性，創造意想不到的複雜情況。",
	},
}
const SCENE_DIRECTIVE_INSTRUCTIONS := {
	"important_json": {
		"en": "\n\n**IMPORTANT: Your response will use structured JSON format!**",
		"zh": "\n\n**重要：回應將使用結構化JSON格式！**",
	},
	"format_description": {
		"en": "Your response will be automatically formatted as JSON with:",
		"zh": "你的回應會被自動格式化為包含以下欄位的JSON：",
	},
	"scene_fields": {
		"en": "- scene: {background, atmosphere, lighting}",
		"zh": "- scene: {background, atmosphere, lighting}",
	},
	"characters_required": {
		"en": "- characters: Expressions for all 5 main characters (ALL REQUIRED)",
		"zh": "- characters: 所有5個主要角色的表情（必須全部包含）",
	},
	"character_list": {
		"en": "  MUST include: protagonist (main character), gloria (Gloria), donkey (Donkey), ark (Ark), one (One)",
		"zh": "  必須包含: protagonist（主角）, gloria（格洛利亞）, donkey（驢子）, ark（方舟）, one（一號）",
	},
	"character_format": {
		"en": "  Each character: {expression: emotion}",
		"zh": "  每個角色: {expression: 表情}",
	},
	"story_text": {
		"en": "- story_text: Your story content",
		"zh": "- story_text: 你的故事內容",
	},
	"all_visible": {
		"en": "\n**IMPORTANT: All 5 characters are always visible. You MUST set an expression for each one.**",
		"zh": "\n**重要：所有5個角色始終可見。你必須為每個角色設置表情。**",
	},
	"choose_expressions": {
		"en": "Choose appropriate expressions for each character based on the scene and story. Even if a character doesn't speak, give them a contextually appropriate expression.",
		"zh": "根據場景和故事，為每個角色選擇適當的表情。即使角色沒有說話，也要設置符合情境的表情。",
	},
	"available_backgrounds": {
		"en": "\nAvailable backgrounds: ruins, cave, dungeon, forest, temple, laboratory, library, throne_room, battlefield, crystal_cavern, bridge, garden, portal_area, safe_zone, water, fire_area",
		"zh": "\n可用背景: ruins, cave, dungeon, forest, temple, laboratory, library, throne_room, battlefield, crystal_cavern, bridge, garden, portal_area, safe_zone, water, fire_area",
	},
	"available_expressions": {
		"en": "Available expressions: neutral, happy, sad, angry, confused, shocked, thinking, embarrassed",
		"zh": "可用表情: neutral, happy, sad, angry, confused, shocked, thinking, embarrassed",
	},
}
const METADATA_LABELS := {
	"purpose": {
		"en": "Purpose: %s",
		"zh": "目的：%s",
	},
	"player_choice": {
		"en": "Player choice: %s",
		"zh": "玩家選擇：%s",
	},
	"success_check": {
		"en": "Success check: %s",
		"zh": "成功檢查：%s",
	},
	"player_prayer": {
		"en": "Player prayer: %s",
		"zh": "玩家祈禱：%s",
	},
	"player_action": {
		"en": "Player action: %s",
		"zh": "玩家行動：%s",
	},
	"current_teammate": {
		"en": "Current teammate: %s",
		"zh": "當前隊友：%s",
	},
}
const STATS_FORMAT := {
	"reality": {
		"en": "Reality %d/%d",
		"zh": "現實值 %d/%d",
	},
	"positive": {
		"en": "Positive %d/%d",
		"zh": "正能量 %d/%d",
	},
	"entropy": {
		"en": "Entropy %d",
		"zh": "熵值 %d",
	},
	"stats_label": {
		"en": "Stats: %s",
		"zh": "數值：%s",
	},
}
static func get_text(category: Dictionary, key: String, language: String = "en") -> String:
	if category.has(key) and category[key] is Dictionary:
		var text_dict: Dictionary = category[key]
		return text_dict.get(language, text_dict.get("en", ""))
	return ""
static func get_language_instruction(language: String = "en") -> String:
	return LANGUAGE_INSTRUCTIONS.get(language, LANGUAGE_INSTRUCTIONS["en"])
static func get_section_header(section: String, language: String = "en") -> String:
	return get_text(SECTION_HEADERS, section, language)
static func get_butterfly_effect_instruction(instruction: String, language: String = "en") -> String:
	return get_text(BUTTERFLY_EFFECT_INSTRUCTIONS, instruction, language)
