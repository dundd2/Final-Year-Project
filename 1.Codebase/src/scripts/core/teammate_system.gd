extends Node
const BEHAVIOR_LIBRARY = {
	"moral_blackmail": {
		"label": "道德勒索",
		"summary": "用柔性的內疚把所有責任推回玩家。",
		"impact": { "reality": -8, "positive": 12, "entropy": 4 },
		"style": "指控玩家的負能量，強調自己被傷害。",
	},
	"issue_replacement": {
		"label": "議題置換",
		"summary": "把具體問題換成對玩家情緒的審判。",
		"impact": { "reality": -6, "positive": 8, "entropy": 3 },
		"style": "不回答問題，只談愛與包容。",
	},
	"divine_protection": {
		"label": "神聖庇護",
		"summary": "用飛天意粉神的名義凍結一切理性討論。",
		"impact": { "reality": -4, "positive": 10, "entropy": 5 },
		"style": "呼喊神諭、要求大家祈禱。",
	},
	"heroic_nonsense": {
		"label": "英雄幻想",
		"summary": "臨場編造壯烈劇本，與現實完全脫節。",
		"impact": { "reality": -5, "positive": 6, "entropy": 4 },
		"style": "高喊口號、擺英雄姿勢。",
	},
	"blame_shifting": {
		"label": "甩鍋大師",
		"summary": "把錯誤推給玩家或無辜路人。",
		"impact": { "reality": -7, "positive": 5, "entropy": 2 },
		"style": "聲稱自己被拖累，逼大家認錯。",
	},
	"epic_planning": {
		"label": "史詩計畫",
		"summary": "提出華麗但不可行的方案。",
		"impact": { "reality": -3, "positive": 7, "entropy": 3 },
		"style": "用浮誇語彙描繪救世劇本。",
	},
	"overcomplicate": {
		"label": "過度複雜化",
		"summary": "把簡單任務塞滿繁文縟節。",
		"impact": { "reality": -6, "positive": 4, "entropy": 5 },
		"style": "列出大量表單與程序。",
	},
	"black_box_operation": {
		"label": "黑箱作業",
		"summary": "把進度藏起來，迫使大家盲目跟隨。",
		"impact": { "reality": -5, "positive": 6, "entropy": 6 },
		"style": "宣稱『我自有安排』拒絕說明。",
	},
	"absolute_plan": {
		"label": "絕對計畫",
		"summary": "強制所有人照他的完美藍圖行動。",
		"impact": { "reality": -4, "positive": 5, "entropy": 7 },
		"style": "引用規章、拒絕任何變通。",
	},
	"silent_agreement": {
		"label": "沉默附和",
		"summary": "表面順從，實際上讓玩家孤立。",
		"impact": { "reality": -2, "positive": 3, "entropy": 1 },
		"style": "公開場合只說『我沒意見』。",
	},
	"reliable_execution": {
		"label": "可靠執行",
		"summary": "默默完成任務，但加深失衡。",
		"impact": { "reality": -1, "positive": 4, "entropy": 2 },
		"style": "專注執行錯誤命令，讓災難成既定事實。",
	},
	"private_confession": {
		"label": "私下告解",
		"summary": "只在私訊中承認問題，對外保持沉默。",
		"impact": { "reality": -3, "positive": 2, "entropy": 1 },
		"style": "以低聲慰問玩家，卻拒絕出面。",
	},
}
const TEAMMATES = {
	"gloria": {
		"name": "聖光修女・Gloria",
		"title": "溫室的守護者 / 武器化的天真",
		"persona": "熱愛正能量的 PUA 傳教士，將一切質疑視為冒犯。",
		"color": Color(1.0, 0.9, 0.7),
		"base_chance": 0.35,
		"trigger_keywords": ["logic", "質疑", "抱怨", "負能量"],
		"trigger_rules": {
			"complaint_counter_min": 2,
			"reality_score_max": 65,
			"positive_energy_min": 35,
		},
		"behaviors": ["moral_blackmail", "issue_replacement", "divine_protection"],
		"interference_goal": "把焦點從真實問題轉移到玩家的『負能量』上，並用信仰合理化失敗。",
		"tone": "溫柔卻帶威脅的讚美語氣",
		"prompt_length": "90-150 字",
		"signature_lines": [
			"你是不是忘了愛與包容？",
			"如果交託給飛天意粉神，一切都會好起來。",
		],
	},
	"donkey": {
		"name": "榮光騎士・Cosplayer Donkey",
		"title": "自封的英雄 / 概念的破產者",
		"persona": "沉迷騎士浪漫的巨嬰，凡事以英雄劇本取代現實思考。",
		"color": Color(0.8, 0.6, 0.3),
		"base_chance": 0.4,
		"trigger_keywords": ["hero", "拯救", "公主", "計畫"],
		"trigger_rules": {
			"logic_success_only": true,
			"positive_energy_max": 75,
		},
		"behaviors": ["heroic_nonsense", "blame_shifting", "epic_planning"],
		"interference_goal": "把場面變成自我英雄秀，拖垮任何理智行動。",
		"tone": "浮誇、激情、對女性角色過度殷勤的風格",
		"prompt_length": "80-140 字",
		"signature_lines": [
			"看我來拯救妳，命運的公主！",
			"如果不是我，這隊伍早就毀了。",
		],
	},
	"ark": {
		"name": "秩序使徒・Cosplayer ARK",
		"title": "勤奮的破壞者 / 黑箱的建築師",
		"persona": "病態崇拜秩序的控制狂，寧可毀掉任務也要維持流程。",
		"color": Color(0.5, 0.5, 0.7),
		"base_chance": 0.32,
		"trigger_keywords": ["plan", "策略", "流程", "整理"],
		"trigger_rules": {
			"reality_score_min": 30,
			"positive_energy_min": 20,
		},
		"behaviors": ["overcomplicate", "black_box_operation", "absolute_plan"],
		"interference_goal": "用繁瑣流程拖垮節奏，讓大家無暇處理真正的危機。",
		"tone": "冷靜、命令式、充滿表格術語",
		"prompt_length": "90-160 字",
		"signature_lines": [
			"請先填完 48 份 17-B 表單。",
			"這是程序，遵守就是對世界負責。",
		],
	},
	"one": {
		"name": "被孤立的老朋友・One",
		"title": "沉默的證人 / 無聲的共犯",
		"persona": "有能力卻畏懼衝突的夥伴，總在沉默中妥協。",
		"color": Color(0.6, 0.7, 0.6),
		"base_chance": 0.1,
		"trigger_keywords": ["求助", "幫忙", "私訊", "拜託"],
		"trigger_rules": {
			"reality_score_max": 55,
			"positive_energy_max": 45,
		},
		"behaviors": ["silent_agreement", "reliable_execution", "private_confession"],
		"interference_goal": "用善良的沉默讓玩家更孤立，幫助體制持續腐敗。",
		"tone": "溫吞、壓低音量、充滿歉意",
		"prompt_length": "70-120 字",
		"signature_lines": [
			"抱歉，我在大家面前真的講不出來。",
			"私下你說什麼我都支持，但…",
		],
	},
}
signal relationship_updated(source_id: String, target_id: String)
var _team_relationships: Dictionary = {
	"gloria": {
		"player": { "status": "Saving/Purifying", "value": 50 },
		"donkey": { "status": "Tolerates", "value": 30 },
		"ark": { "status": "Uses", "value": 40 },
		"one": { "status": "Ignores", "value": 20 },
	},
	"donkey": {
		"player": { "status": "Sidekick", "value": 60 },
		"gloria": { "status": "Worships", "value": 90 },
		"ark": { "status": "Confused by", "value": 10 },
		"one": { "status": "Bullying target", "value": -20 },
	},
	"ark": {
		"player": { "status": "Variable", "value": 50 },
		"gloria": { "status": "Analyzes", "value": 30 },
		"donkey": { "status": "Disdains", "value": -40 },
		"one": { "status": "Calculates utility", "value": 40 },
	},
	"one": {
		"player": { "status": "Secretly Envies", "value": 70 },
		"gloria": { "status": "Fears", "value": -50 },
		"donkey": { "status": "Avoids", "value": -30 },
		"ark": { "status": "Obeys", "value": 20 },
	},
	"teacher_chan": {
		"player": { "status": "Brainwashing", "value": 100 },
		"gloria": { "status": "Rival", "value": -10 },
	}
}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
func _ready() -> void:
	_rng.randomize()
func get_teammate_info(teammate_id: String) -> Dictionary:
	return TEAMMATES.get(teammate_id, { })
func list_teammate_ids() -> Array:
	return TEAMMATES.keys()
func get_teammate_name(teammate_id: String) -> String:
	var info = get_teammate_info(teammate_id)
	return info.get("name", "Unknown")
func get_behavior_details(behavior_id: String) -> Dictionary:
	return BEHAVIOR_LIBRARY.get(behavior_id, { })
func should_trigger_interference(teammate_id: String, player_action: String, game_state) -> bool:
	var info = get_teammate_info(teammate_id)
	if info.is_empty():
		return false
	var action_lower = player_action.to_lower()
	for keyword in info.get("trigger_keywords", []):
		if action_lower.find(keyword.to_lower()) != -1:
			return true
	var rules = info.get("trigger_rules", { })
	var complaints = _extract_stat(game_state, "complaint_counter", 0)
	var reality_score = _extract_stat(game_state, "reality_score", 50)
	var positive_energy = _extract_stat(game_state, "positive_energy", 50)
	if rules.has("logic_success_only") and bool(rules["logic_success_only"]) and action_lower.find("成功") == -1:
		return false
	if rules.has("complaint_counter_min") and complaints >= int(rules["complaint_counter_min"]):
		return true
	if rules.has("reality_score_max") and reality_score <= int(rules["reality_score_max"]):
		return true
	if rules.has("reality_score_min") and reality_score >= int(rules["reality_score_min"]):
		return true
	if rules.has("positive_energy_min") and positive_energy >= int(rules["positive_energy_min"]):
		return true
	if rules.has("positive_energy_max") and positive_energy <= int(rules["positive_energy_max"]):
		return true
	var base_chance = float(info.get("base_chance", 0.15))
	var mood_bonus = clamp((positive_energy - 50) / 100.0, -0.25, 0.25)
	var probability = clamp(base_chance + mood_bonus, 0.05, 0.95)
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.randomize()
	return _rng.randf() < probability
func generate_interference_prompt(teammate_id: String, context: Dictionary) -> String:
	var info = get_teammate_info(teammate_id)
	var lang = GameState.current_language if GameState else "en"
	if info.is_empty():
		if lang == "en":
			return "Describe in an ironic tone how an incompetent teammate ruins the mission."
		else:
			return "請用諷刺語氣描述一位豬隊友如何把任務搞砸。"
	var player_action = str(context.get("player_action", "（玩家行動描述缺失）" if lang == "zh" else "(Player action missing)"))
	var reality_score = int(context.get("reality_score", _extract_stat(GameState, "reality_score", 50)))
	var positive_energy = int(context.get("positive_energy", _extract_stat(GameState, "positive_energy", 50)))
	var entropy_level = int(context.get("entropy_level", context.get("entropy", _extract_stat(GameState, "entropy_level", 0))))
	var behavior_lines = _build_behavior_guidelines(info, lang)
	if behavior_lines.is_empty():
		if lang == "en":
			behavior_lines = "- (No defined actions; improvise actions that worsen the situation)"
		else:
			behavior_lines = "- （暫無定義的行動，請自行編造讓情況更糟的舉動）"
	var recent_summary = ""
	if context.has("recent_events_summary"):
		recent_summary = str(context["recent_events_summary"])
	elif context.has("recent_events") and context["recent_events"] is Array and context["recent_events"].size() > 0:
		var events: Array = context["recent_events"]
		var slice_start = max(0, events.size() - 2)
		recent_summary = ", ".join(events.slice(slice_start, events.size()))
	var lines = []
	if lang == "en":
		lines.append("You are now playing %s (%s), %s." % [info.get("name", teammate_id.capitalize()), info.get("title", ""), info.get("persona", "an eccentric teammate")])
		lines.append("Player's recent action: %s" % player_action)
		if not recent_summary.is_empty():
			lines.append("Recent failures summary: %s" % recent_summary)
		lines.append("Status monitoring:")
		lines.append("- Reality Score: %d/100 (%s)" % [reality_score, _describe_meter(reality_score, true, lang)])
		lines.append("- Positive Energy: %d/100 (%s)" % [positive_energy, _describe_meter(positive_energy, false, lang)])
		lines.append("- Entropy Level: %d (%s)" % [entropy_level, _describe_entropy_level(entropy_level, lang)])
		lines.append("Mission goal: %s" % info.get("interference_goal", "Make everything worse."))
		lines.append("")
		lines.append("Available methods:")
		lines.append(behavior_lines)
		var signature: Array = info.get("signature_lines", [])
		if signature.size() > 0:
			lines.append("Reference tone or catchphrases: %s" % ", ".join(signature))
		lines.append("")
		lines.append("Write an intervention narrative in %s tone, within %s, describing how you drag the situation toward chaos." % [info.get("tone", "ironic and hypocritical"), info.get("prompt_length", "80-140 words")])
		lines.append("The narrative must include:")
		lines.append("1. Specific actions and tactics (mention at least one method above).")
		lines.append("2. Actual damage, delays, or chaos caused to the mission or crowd.")
		lines.append("3. Tear apart both the player's rationality and guilt simultaneously.")
	else:
		lines.append("你現在扮演%s（%s），%s。" % [info.get("name", teammate_id.capitalize()), info.get("title", ""), info.get("persona", "古怪隊友")])
		lines.append("玩家剛剛的行動：%s" % player_action)
		if not recent_summary.is_empty():
			lines.append("最近失誤摘要：%s" % recent_summary)
		lines.append("狀態監視：")
		lines.append("- 現實值：%d/100（%s）" % [reality_score, _describe_meter(reality_score, true, lang)])
		lines.append("- 正能量：%d/100（%s）" % [positive_energy, _describe_meter(positive_energy, false, lang)])
		lines.append("- 熵增等級：%d（%s）" % [entropy_level, _describe_entropy_level(entropy_level, lang)])
		lines.append("任務目標：%s" % info.get("interference_goal", "讓一切變得更糟。"))
		lines.append("")
		lines.append("可用手段：")
		lines.append(behavior_lines)
		var signature: Array = info.get("signature_lines", [])
		if signature.size() > 0:
			lines.append("參考語氣或口頭禪：%s" % ", ".join(signature))
		lines.append("")
		lines.append("請用%s的語氣，在%s內寫出一段介入敘事，描述你如何把局勢拉向失控。" % [info.get("tone", "諷刺又偽善"), info.get("prompt_length", "80-140 字")])
		lines.append("敘事需包含：")
		lines.append("1. 具體行為與招數（至少提及上述手段之一）。")
		lines.append("2. 對任務或群眾造成的實際損害、延誤或混亂。")
		lines.append("3. 讓玩家的理智與罪惡感同時被撕裂。")
	var assets_context = context.duplicate() if context else { }
	if not assets_context.has("asset_ids") and GameState:
		assets_context["asset_ids"] = GameState.get_metadata("current_asset_ids", [])
	var assets_info: Array = AssetRegistry.get_assets_for_context(assets_context)
	if assets_info.size() > 0:
		lines.append("")
		if lang == "en":
			lines.append("--- Available Symbolic Assets ---")
			lines.append(AssetRegistry.format_assets_for_prompt(assets_info))
			lines.append("Describe how you misuse these assets to spiral the situation further out of control.")
		else:
			lines.append("--- 可用符號資產 ---")
			lines.append(AssetRegistry.format_assets_for_prompt(assets_info))
			lines.append("請描述你如何濫用這些資產，讓局勢更失控。")
	if lang == "en":
		lines.append("End with an ironic or misaligned blessing.")
	else:
		lines.append("最後請用一句反諷或錯位的祝福收尾。")
	return "\n".join(lines)
func get_behavior_description(behavior_id: String) -> String:
	var details: Dictionary = get_behavior_details(behavior_id)
	if details.is_empty():
		return "Unknown Behavior"
	var impact: String = _format_impact(details.get("impact", { }))
	var label: String = details.get("label", behavior_id.capitalize())
	var summary: String = details.get("summary", "Unknown Behavior")
	if impact.is_empty():
		return "%s - %s" % [label, summary]
	return "%s - %s %s" % [label, summary, impact]
func get_all_relationships() -> Dictionary:
	return _team_relationships.duplicate(true)
func get_relationships_for(source_id: String) -> Dictionary:
	return _team_relationships.get(source_id, {}).duplicate(true)
func update_relationship(source_id: String, target_id: String, status: String, value_change: int = 0) -> void:
	if not _team_relationships.has(source_id):
		_team_relationships[source_id] = {}
	if not _team_relationships[source_id].has(target_id):
		_team_relationships[source_id][target_id] = { "status": status, "value": 0 }
	else:
		_team_relationships[source_id][target_id]["status"] = status
	_team_relationships[source_id][target_id]["value"] = clamp(_team_relationships[source_id][target_id]["value"] + value_change, -100, 100)
	relationship_updated.emit(source_id, target_id)
func get_state_snapshot() -> Dictionary:
	return { "relationships": _team_relationships.duplicate(true) }
func load_state_snapshot(data: Dictionary) -> void:
	if data.has("relationships") and data["relationships"] is Dictionary:
		_team_relationships = data["relationships"].duplicate(true)
func _build_behavior_guidelines(info: Dictionary, lang: String = "zh") -> String:
	var lines = []
	for behavior_id in info.get("behaviors", []):
		var details = get_behavior_details(behavior_id)
		if details.is_empty():
			continue
		var label = details.get("label", behavior_id.capitalize())
		var summary = details.get("summary", "")
		var impact = _format_impact(details.get("impact", { }), lang)
		var style = details.get("style", "")
		var line = "- %s：%s" % [label, summary]
		if not impact.is_empty():
			line += " %s" % impact
		if not style.is_empty():
			var method_prefix = "；Preferred approach: " if lang == "en" else "；偏好做法："
			line += "%s%s" % [method_prefix, style]
		lines.append(line)
	return "\n".join(lines)
func _format_impact(impact: Dictionary, lang: String = "zh") -> String:
	if impact.is_empty():
		return ""
	var parts = []
	if impact.has("reality"):
		var reality_label = "Reality Score" if lang == "en" else "現實值"
		parts.append("%s%+d" % [reality_label, int(impact["reality"])])
	if impact.has("positive"):
		var positive_label = "Positive Energy" if lang == "en" else "正能量"
		parts.append("%s%+d" % [positive_label, int(impact["positive"])])
	if impact.has("entropy"):
		var entropy_label = "Entropy" if lang == "en" else "熵增"
		parts.append("%s%+d" % [entropy_label, int(impact["entropy"])])
	var expected_label = "(Expected impact: " if lang == "en" else "（預期影響："
	var suffix = ")" if lang == "en" else "）"
	return "%s%s%s" % [expected_label, ", ".join(parts), suffix]
func _describe_meter(value: int, high_is_good: bool, lang: String = "zh") -> String:
	var bucket = ""
	if value >= 80:
		bucket = "極高"
	elif value >= 60:
		bucket = "偏高"
	elif value >= 40:
		bucket = "中庸"
	elif value >= 20:
		bucket = "偏低"
	else:
		bucket = "危殆"
	if lang == "en":
		if high_is_good:
			match bucket:
				"極高":
					return "disturbingly lucid"
				"偏高":
					return "barely maintaining sanity"
				"中庸":
					return "wavering sense of reality"
				"偏低":
					return "almost brainwashed"
				_:
					return "can barely see the truth"
		else:
			match bucket:
				"極高":
					return "positive energy overload, toxicity spreading"
				"偏高":
					return "forced smile, brainwashing risk"
				"中庸":
					return "surface optimism, hidden contradictions"
				"偏低":
					return "still somewhat lucid"
				_:
					return "rare moment of rationality"
	else:
		if high_is_good:
			match bucket:
				"極高":
					return "清醒到令人不安"
				"偏高":
					return "勉強維持理智"
				"中庸":
					return "正在搖晃的現實感"
				"偏低":
					return "快被洗腦拖走"
				_:
					return "幾乎看不到真相"
		else:
			match bucket:
				"極高":
					return "正能量爆表、毒性蔓延"
				"偏高":
					return "笑容僵硬、具洗腦風險"
				"中庸":
					return "表面樂觀、暗藏矛盾"
				"偏低":
					return "稍微還能清醒"
				_:
					return "罕見的理性呼吸"
func _describe_entropy_level(level: int, lang: String = "zh") -> String:
	if lang == "en":
		if level >= 60:
			return "world on brink of collapse"
		if level >= 30:
			return "entropy curve rising steeply"
		if level >= 10:
			return "deep decay incubating"
		return "surface calm but fermenting within"
	else:
		if level >= 60:
			return "世界瀕臨崩壞"
		if level >= 30:
			return "熵增曲線陡升"
		if level >= 10:
			return "深層崩壞正在孵化"
		return "表面平靜但內裡發酵"
func _extract_stat(source, key: String, default_value):
	if source == null:
		return default_value
	match typeof(source):
		TYPE_DICTIONARY:
			return source.get(key, default_value)
		TYPE_OBJECT:
			var value = source.get(key)
			return value if value != null else default_value
		_:
			return default_value
