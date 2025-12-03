extends Node
signal dilemma_generated(dilemma_data: Dictionary)
signal dilemma_resolved(choice: String, consequences: Dictionary)
const ERROR_CONTEXT := "TrolleyProblemGenerator"
var current_dilemma: Dictionary = { }
var dilemma_history: Array = []
const DILEMMA_TEMPLATES = {
	"classic": {
		"setup": "A runaway trolley problem with a GDA twist",
		"choice_count": 2,
		"moral_weight": "medium",
	},
	"sacrifice": {
		"setup": "Choose who must be sacrificed for the 'greater good'",
		"choice_count": 3,
		"moral_weight": "high",
	},
	"complicity": {
		"setup": "Inaction vs. active participation in harm",
		"choice_count": 2,
		"moral_weight": "high",
	},
	"lesser_evil": {
		"setup": "All choices lead to disaster - pick the least worst",
		"choice_count": 3,
		"moral_weight": "medium",
	},
	"positive_energy_trap": {
		"setup": "Positive solution causes worse outcome than honest approach",
		"choice_count": 2,
		"moral_weight": "thematic",
	},
}
const DILEMMA_PROPERTY_ORDER := ["scenario", "choices", "thematic_point"]
func _ready():
	print("[TrolleyProblemGenerator] Initialized")
func generate_dilemma(template_type: String = "", context: Dictionary = { }) -> void:
	if template_type.is_empty():
		template_type = DILEMMA_TEMPLATES.keys()[randi() % DILEMMA_TEMPLATES.size()]
		if not DILEMMA_TEMPLATES.has(template_type):
			_report_error(
				"Invalid dilemma template: %s" % template_type,
				ErrorCodes.General.INVALID_PARAMETER,
				{ "template_type": template_type },
			)
			return
	var template = DILEMMA_TEMPLATES[template_type]
	var prompt = _build_dilemma_prompt(template_type, template, context)
	if AIManager:
		var ai_context = context.duplicate()
		ai_context["purpose"] = "trolley_problem"
		ai_context["template"] = template_type
		ai_context["reality_score"] = GameState.reality_score if GameState else 50
		ai_context["positive_energy"] = GameState.positive_energy if GameState else 50
		ai_context["structured_output"] = _build_structured_output_options(template)
		ai_context["response_mime_type"] = "application/json"
		ai_context["response_schema"] = ai_context["structured_output"].get("schema", {})
		ai_context["property_ordering"] = DILEMMA_PROPERTY_ORDER
		var callback = Callable(self, "_on_dilemma_generated").bind(template_type)
		AIManager.generate_story(prompt, ai_context, callback)
	else:
		_generate_preset_dilemma(template_type)
func _build_dilemma_prompt(template_type: String, template: Dictionary, context: Dictionary) -> String:
	var lang = GameState.current_language if GameState else "en"
	var reality = GameState.reality_score if GameState else 50
	var positive = GameState.positive_energy if GameState else 50
	var mission_context = context.get("mission_summary", "")
	var recent_events = context.get("recent_events", [])
	var prompt = ""
	if lang == "en":
		prompt = """Generate a trolley problem moral dilemma that INTERRUPTS the current story for Glorious Deliverance Agency 1.

**Template:** %s (%s)
**Current Context:**
- Reality Score: %d/100 (lower = more delusional)
- Positive Energy: %d/100 (higher = more toxic positivity)
- **CURRENT SITUATION:** %s

**Requirements:**
1. The scenario must be an IMMEDIATE INTERRUPTION or CRISIS related to the Current Situation above.
2. Do NOT generate a generic trolley problem. It must feel like a natural (but catastrophic) branch of the story text provided.
3. Create a scenario with %d distinct choices
4. Each choice must have negative consequences
5. Frame at least one option in "positive energy" language that actually causes more harm
6. Make the player complicit in the disaster regardless of choice

**Output Format (JSON):**
{
	"scenario": "Detailed setup of the dilemma (100-150 words)",
	"choices": [
		{
			"id": "choice_1",
			"text": "Choice description",
			"framing": "How it's presented (honest/positive/manipulative)",
			"immediate_consequence": "What happens right away",
			"long_term_consequence": "The true cost revealed later",
			"stat_changes": {"reality": -5, "positive_energy": 10, "entropy": 1},
			"relationship_changes": [
				{"target": "gloria", "value": -10, "status": "Disappointed"},
				{"target": "ark", "value": 5, "status": "Approved"}
			]
		}
	],
	"thematic_point": "What this dilemma reveals about the world"
}

Make it darkly satirical while maintaining emotional weight. Begin the scenario with "Suddenly..." or "Just then..." to bridge the gap.""" % [
			template_type,
			template["setup"],
			reality,
			positive,
			mission_context if not mission_context.is_empty() else "No specific context",
			template["choice_count"],
		]
	else:
		prompt = """為《榮耀虛無機構1》生成一個「打斷當前故事」的電車難題式道德困境。

**模板：** %s (%s)
**當前情境：**
- 現實評分：%d/100（越低越妄想）
- 正能量：%d/100（越高越有毒）
- **目前故事進展：** %s

**要求：**
1. 困境必須是針對「目前故事進展」的**突發危機**或**緊急插曲**。
2. **絕對不要**生成與上文無關的通用電車難題。必須讓玩家覺得這是故事的一部分。
3. 創建一個有 %d 個不同選擇的場景
4. 每個選擇都必須有負面後果
5. 至少有一個選項用「正能量」語言包裝，但實際造成更大傷害
6. 無論選擇什麼，玩家都是災難的共犯

**輸出格式（JSON）：**
{
	"scenario": "困境的详细设置（100-150字）",
	"choices": [
		{
			"id": "choice_1",
			"text": "选择描述",
			"framing": "如何呈现（诚实/积极/操纵性）",
			"immediate_consequence": "立即发生的事情",
			"long_term_consequence": "后来揭示的真实代价",
			"stat_changes": {"reality": -5, "positive_energy": 10, "entropy": 1},
			"relationship_changes": [
				{"target": "gloria", "value": -10, "status": "失望"},
				{"target": "ark", "value": 5, "status": "贊同"}
			]
		}
	],
	"thematic_point": "這個困境揭示了關於世界的什麼"
}

使其具有黑暗諷刺性。場景描述請以「突然間...」或「就在這時...」開頭，以銜接原本的故事。""" % [
			template_type,
			template["setup"],
			reality,
			positive,
			mission_context if not mission_context.is_empty() else "無具體情境",
			template["choice_count"],
		]
	return prompt
func _on_dilemma_generated(response: Dictionary, template_type: String) -> void:
	if not response.success:
		_report_error(
			"Failed to generate dilemma: %s" % response.get("error", "Unknown error"),
			ErrorCodes.AI.REQUEST_FAILED,
			{"error": response.get("error", "Unknown error")}
		)
		_generate_preset_dilemma(template_type)
		return
	var content = response.get("content", "")
	var dilemma_data = _parse_dilemma_json(content)
	if dilemma_data.is_empty():
		_report_error("Failed to parse dilemma data")
		_generate_preset_dilemma(template_type)
		return
	current_dilemma = dilemma_data
	current_dilemma["template_type"] = template_type
	current_dilemma["generated_at"] = Time.get_datetime_string_from_system()
	if AudioManager:
		AudioManager.play_sfx("auction_start", 0.8)
	dilemma_generated.emit(current_dilemma)
	print("[TrolleyProblemGenerator] Dilemma generated: %s" % template_type)
func _parse_dilemma_json(content: String) -> Dictionary:
	var json_str := _extract_json_block(content)
	if json_str.is_empty():
		return { }
	json_str = _normalize_json_string(json_str)
	if json_str.is_empty():
		return { }
	var json := JSON.new()
	var parse_result := json.parse(json_str)
	if parse_result != OK:
		_report_error(
			"JSON parse error: %s" % json.get_error_message(),
			ErrorCodes.AI.PARSE_ERROR,
			{
				"error_message": json.get_error_message(),
				"preview": json_str.substr(0, 160),
			}
		)
		return { }
	var data: Variant = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		_report_error(
			"Parsed JSON was not a dictionary",
			ErrorCodes.AI.PARSE_ERROR,
			{"type": typeof(data)}
		)
		return { }
	return _normalize_dilemma_data(data)
func _extract_json_block(content: String) -> String:
	var fence_start: int = content.find("```")
	while fence_start != -1:
		var fence_end: int = content.find("```", fence_start + 3)
		if fence_end == -1:
			break
		var block: String = content.substr(fence_start + 3, fence_end - fence_start - 3).strip_edges()
		if block.begins_with("json"):
			block = block.substr(4).strip_edges()
		var fenced_json: String = _capture_balanced_json(block)
		if not fenced_json.is_empty():
			return fenced_json
		fence_start = content.find("```", fence_end + 3)
	var balanced: String = _capture_balanced_json(content)
	if not balanced.is_empty():
		return balanced
	var start: int = content.find("{")
	var end: int = content.rfind("}")
	if start != -1 and end != -1 and end > start:
		return content.substr(start, end - start + 1)
	return ""
func _capture_balanced_json(source: String) -> String:
	var start: int = source.find("{")
	while start != -1:
		var candidate: String = _read_balanced_json(source, start)
		if not candidate.is_empty():
			return candidate
		start = source.find("{", start + 1)
	return ""
func _report_error(message: String, error_code: int = -1, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, error_code, false, details)
func _read_balanced_json(source: String, start_index: int) -> String:
	var depth: int = 0
	var in_string: bool = false
	var escape_next: bool = false
	var length: int = source.length()
	for i in range(start_index, length):
		var char: String = source.substr(i, 1)
		if in_string:
			if escape_next:
				escape_next = false
			elif char == "\\":
				escape_next = true
			elif char == "\"":
				in_string = false
			continue
		if char == "\"":
			in_string = true
		elif char == "{":
			depth += 1
		elif char == "}":
			if depth == 0:
				return ""
			depth -= 1
			if depth == 0:
				return source.substr(start_index, i - start_index + 1)
	return ""
func _normalize_json_string(json_str: String) -> String:
	var sanitized: String = json_str.strip_edges()
	var replacements: Dictionary = {
		"\ufeff": "",
		"\u200b": "",
		"\u201c": "\"",
		"\u201d": "\"",
		"\u2018": "'",
		"\u2019": "'",
	}
	for key in replacements.keys():
		sanitized = sanitized.replace(key, replacements[key])
	return sanitized
func _normalize_dilemma_data(raw_data: Dictionary) -> Dictionary:
	var normalized: Dictionary = { }
	var scenario_text := str(raw_data.get("scenario", raw_data.get("setup", ""))).strip_edges()
	var thematic_point := str(raw_data.get("thematic_point", raw_data.get("theme", ""))).strip_edges()
	var normalized_choices: Array = []
	var raw_choices: Variant = raw_data.get("choices", raw_data.get("options", []))
	if raw_choices is Array:
		for i in range((raw_choices as Array).size()):
			var choice_variant: Variant = (raw_choices as Array)[i]
			if not (choice_variant is Dictionary):
				continue
			var choice_dict: Dictionary = choice_variant
			var choice_id := str(choice_dict.get("id", "choice_%d" % (i + 1))).strip_edges()
			if choice_id.is_empty():
				choice_id = "choice_%d" % (i + 1)
			var normalized_choice := {
				"id": choice_id,
				"text": str(choice_dict.get("text", choice_dict.get("description", ""))).strip_edges(),
				"framing": str(choice_dict.get("framing", choice_dict.get("tone", "ambiguous"))).strip_edges(),
				"immediate_consequence": str(choice_dict.get("immediate_consequence", choice_dict.get("immediate", ""))).strip_edges(),
				"long_term_consequence": str(choice_dict.get("long_term_consequence", choice_dict.get("long_term", choice_dict.get("long_term_outcome", "")))).strip_edges(),
				"stat_changes": _normalize_stat_changes(choice_dict.get("stat_changes", choice_dict.get("stat_change", { }))),
				"relationship_changes": _normalize_relationship_changes(choice_dict.get("relationship_changes", [])),
			}
			if normalized_choice["text"].is_empty() and normalized_choice["immediate_consequence"].is_empty():
				continue
			normalized_choices.append(normalized_choice)
	if scenario_text.is_empty() or normalized_choices.is_empty() or thematic_point.is_empty():
		_report_error(
			"Parsed dilemma missing required fields",
			ErrorCodes.AI.PARSE_ERROR,
			{
				"has_scenario": not scenario_text.is_empty(),
				"choice_count": normalized_choices.size(),
				"has_thematic_point": not thematic_point.is_empty(),
			},
		)
		return { }
	normalized["scenario"] = scenario_text
	normalized["choices"] = normalized_choices
	normalized["thematic_point"] = thematic_point
	return normalized
func _normalize_stat_changes(stat_changes_variant: Variant) -> Dictionary:
	if not (stat_changes_variant is Dictionary):
		return {
			"reality": 0,
			"positive_energy": 0,
			"entropy": 0,
		}
	var stat_changes: Dictionary = stat_changes_variant
	return {
		"reality": int(stat_changes.get("reality", 0)),
		"positive_energy": int(stat_changes.get("positive_energy", stat_changes.get("positive", 0))),
		"entropy": int(stat_changes.get("entropy", 0)),
	}
func _normalize_relationship_changes(changes_variant: Variant) -> Array:
	var normalized: Array = []
	if changes_variant is Array:
		for item in changes_variant:
			if item is Dictionary:
				var target = String(item.get("target", "")).strip_edges().to_lower()
				var value = int(item.get("value", 0))
				var status = String(item.get("status", "")).strip_edges()
				if not target.is_empty():
					normalized.append({
						"target": target,
						"value": value,
						"status": status
					})
	return normalized
func _build_structured_output_options(template: Dictionary) -> Dictionary:
	var schema := {
		"type": "object",
		"description": "Structured trolley problem payload",
		"properties": {
			"scenario": {
				"type": "string",
				"description": "Detailed setup of the dilemma (100-150 words)",
			},
			"choices": {
				"type": "array",
				"minItems": max(2, int(template.get("choice_count", 2))),
				"items": {
					"type": "object",
					"properties": {
						"id": { "type": "string" },
						"text": { "type": "string" },
						"framing": { "type": "string" },
						"immediate_consequence": { "type": "string" },
						"long_term_consequence": { "type": "string" },
						"stat_changes": {
							"type": "object",
							"properties": {
								"reality": { "type": "integer" },
								"positive_energy": { "type": "integer" },
								"entropy": { "type": "integer" },
							},
							"required": [],
							"additionalProperties": false,
						},
						"relationship_changes": {
							"type": "array",
							"items": {
								"type": "object",
								"properties": {
									"target": { "type": "string" },
									"value": { "type": "integer" },
									"status": { "type": "string" }
								},
								"required": ["target", "value"],
								"additionalProperties": false
							}
						},
					},
					"required": [
						"id",
						"text",
						"framing",
						"immediate_consequence",
						"long_term_consequence",
					],
					"additionalProperties": false,
				},
			},
			"thematic_point": {
				"type": "string",
				"description": "What this dilemma reveals about the world",
			},
		},
		"required": DILEMMA_PROPERTY_ORDER,
		"additionalProperties": false,
		"propertyOrdering": DILEMMA_PROPERTY_ORDER,
	}
	return {
		"mime_type": "application/json",
		"schema_mode": "json_schema",
		"schema": schema,
		"property_ordering": DILEMMA_PROPERTY_ORDER,
	}
func _generate_preset_dilemma(template_type: String) -> void:
	var lang = GameState.current_language if GameState else "en"
	var dilemma = { }
	match template_type:
		"positive_energy_trap":
			if lang == "en":
				dilemma = {
					"scenario": "A citizen is drowning in despair after losing their job. Gloria insists you tell them 'Everything happens for a reason!' and smile. ARK suggests giving them realistic job counseling resources. Both approaches will have consequences.",
					"choices": [
						{
							"id": "positive",
							"text": "?? Follow Gloria: 'Everything happens for a reason! Stay positive!'",
							"framing": "positive",
							"immediate_consequence": "The person smiles weakly. Gloria praises you.",
							"long_term_consequence": "They stop seeking real help, spiral deeper, blame themselves for 'not being positive enough'",
							"stat_changes": { "reality": -8, "positive_energy": 15, "entropy": 2 },
							"relationship_changes": [{"target": "gloria", "value": 5, "status": "Pleased"}, {"target": "ark", "value": -5, "status": "Disappointed"}]
						},
						{
							"id": "realistic",
							"text": "?? Follow ARK: Provide job search resources and acknowledge their pain",
							"framing": "honest",
							"immediate_consequence": "Gloria accuses you of being 'negative' and weaponizing empathy",
							"long_term_consequence": "The person gets help, but you face Gloria's emotional manipulation for weeks",
							"stat_changes": { "reality": 5, "positive_energy": -10, "entropy": 1 },
							"relationship_changes": [{"target": "gloria", "value": -10, "status": "Hostile"}, {"target": "ark", "value": 5, "status": "Approved"}]
						},
					],
					"thematic_point": "Sometimes honesty is punished while toxic positivity is rewarded",
				}
			else:
				dilemma = {
					"scenario": LocalizationManager.get_translation("DILEMMA_TEAM_STRATEGY_SCENARIO", lang),
					"choices": [
						{
							"id": "positive",
							"text": LocalizationManager.get_translation("DILEMMA_TEAM_STRATEGY_CHOICE_POSITIVE", lang),
							"framing": "positive",
							"immediate_consequence": LocalizationManager.get_translation("DILEMMA_TEAM_STRATEGY_CHOICE_POSITIVE_IMMEDIATE", lang),
							"long_term_consequence": LocalizationManager.get_translation("DILEMMA_TEAM_STRATEGY_CHOICE_POSITIVE_LONGTERM", lang),
							"stat_changes": { "reality": -8, "positive_energy": 15, "entropy": 2 },
							"relationship_changes": [{"target": "gloria", "value": 5, "status": "滿意"}, {"target": "ark", "value": -5, "status": "失望"}]
						},
						{
							"id": "realistic",
							"text": LocalizationManager.get_translation("DILEMMA_TEAM_STRATEGY_CHOICE_REALISTIC", lang),
							"framing": "honest",
							"immediate_consequence": LocalizationManager.get_translation("DILEMMA_TEAM_STRATEGY_CHOICE_REALISTIC_IMMEDIATE", lang),
							"long_term_consequence": LocalizationManager.get_translation("DILEMMA_TEAM_STRATEGY_CHOICE_REALISTIC_LONGTERM", lang),
							"stat_changes": { "reality": 5, "positive_energy": -10, "entropy": 1 },
							"relationship_changes": [{"target": "gloria", "value": -10, "status": "敵視"}, {"target": "ark", "value": 5, "status": "贊同"}]
						},
					],
					"thematic_point": LocalizationManager.get_translation("DILEMMA_TEAM_STRATEGY_THEME", lang),
				}
		_:
			if lang == "en":
				dilemma = {
					"scenario": "Your team faces an impossible choice. No matter what you pick, someone will suffer.",
					"choices": [
						{
							"id": "choice_1",
							"text": "Take the 'safe' option",
							"framing": "positive",
							"immediate_consequence": "Immediate comfort",
							"long_term_consequence": "Long-term disaster",
							"stat_changes": { "reality": -5, "positive_energy": 10, "entropy": 1 },
							"relationship_changes": [{"target": "gloria", "value": 2, "status": "Content"}]
						},
						{
							"id": "choice_2",
							"text": "Face reality",
							"framing": "honest",
							"immediate_consequence": "Immediate discomfort",
							"long_term_consequence": "Slightly less disaster",
							"stat_changes": { "reality": 5, "positive_energy": -5, "entropy": 1 },
							"relationship_changes": [{"target": "gloria", "value": -5, "status": "Annoyed"}]
						},
					],
					"thematic_point": "You are always complicit",
				}
			else:
				dilemma = {
					"scenario": "你的團隊面臨一個不可能的選擇。無論你選擇什麼，都會有人受苦。",
					"choices": [
						{
							"id": "choice_1",
							"text": "選擇「安全」的選項",
							"framing": "positive",
							"immediate_consequence": "短暫的舒適",
							"long_term_consequence": "長期的災難",
							"stat_changes": { "reality": -5, "positive_energy": 10, "entropy": 1 },
							"relationship_changes": [{"target": "gloria", "value": 2, "status": "滿意"}]
						},
						{
							"id": "choice_2",
							"text": "面對現實",
							"framing": "honest",
							"immediate_consequence": "立即的不適",
							"long_term_consequence": "稍微減輕的災難",
							"stat_changes": { "reality": 5, "positive_energy": -5, "entropy": 1 },
							"relationship_changes": [{"target": "gloria", "value": -5, "status": "不悅"}]
						},
					],
					"thematic_point": "你總是共犯",
				}
	current_dilemma = dilemma
	current_dilemma["template_type"] = template_type
	current_dilemma["generated_at"] = Time.get_datetime_string_from_system()
	current_dilemma["preset"] = true
	dilemma_generated.emit(current_dilemma)
func resolve_dilemma(choice_id: String) -> Dictionary:
	if current_dilemma.is_empty():
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "No active dilemma to resolve")
		return { }
	var choice_data: Dictionary = {}
	for choice in current_dilemma.get("choices", []):
		if choice["id"] == choice_id:
			choice_data = choice
			break
	if choice_data == null:
		_report_error(
			"Invalid choice: %s" % choice_id,
			ErrorCodes.General.INVALID_PARAMETER,
			{"choice_id": choice_id}
		)
		return { }
	if choice_data.has("stat_changes") and GameState:
		for stat in choice_data["stat_changes"]:
			var value = choice_data["stat_changes"][stat]
			match stat:
				"reality":
					GameState.modify_reality_score(value)
				"positive_energy":
					GameState.modify_positive_energy(value)
				"entropy":
					GameState.modify_entropy(value, "Moral dilemma")
	if choice_data.has("relationship_changes"):
		var teammate_system = ServiceLocator.get_teammate_system() if ServiceLocator else null
		if teammate_system:
			for rel in choice_data["relationship_changes"]:
				var target = rel.get("target", "")
				var value = rel.get("value", 0)
				var status = rel.get("status", "Affected")
				if not target.is_empty():
					teammate_system.update_relationship(target, "player", status, value)
	var resolution = {
		"dilemma_template": current_dilemma.get("template_type", "unknown"),
		"choice_id": choice_id,
		"choice_text": choice_data.get("text", ""),
		"immediate_consequence": choice_data.get("immediate_consequence", ""),
		"long_term_consequence": choice_data.get("long_term_consequence", ""),
		"stat_changes": choice_data.get("stat_changes", { }),
		"resolved_at": Time.get_datetime_string_from_system(),
	}
	dilemma_history.append(resolution)
	var AchievementSystem = ServiceLocator.get_achievement_system() if ServiceLocator else null
	if AchievementSystem and AchievementSystem.has_method("check_dilemma_resolved"):
		AchievementSystem.check_dilemma_resolved()
	else:
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"AchievementSystem unavailable; skipping dilemma resolution tracking.",
			{"service": "AchievementSystem"}
		)
	if GameState and GameState.butterfly_tracker:
		var butterfly_data = {
			"text": "Dilemma: %s" % choice_data.get("text", "Unknown Choice"),
			"choice_type": "major",
			"tags": ["dilemma", "moral_choice", current_dilemma.get("template_type", "unknown")],
			"metadata": {
				"dilemma_template": current_dilemma.get("template_type", "unknown"),
				"immediate_consequence": choice_data.get("immediate_consequence", ""),
				"long_term_consequence": choice_data.get("long_term_consequence", "")
			}
		}
		GameState.butterfly_tracker.record_choice(butterfly_data, "major", butterfly_data["tags"])
		print("[TrolleyProblemGenerator] Recorded choice to Butterfly Tracker")
	dilemma_resolved.emit(choice_id, resolution)
	current_dilemma.clear()
	return resolution
func get_dilemma_history() -> Array:
	return dilemma_history.duplicate()
func get_current_dilemma() -> Dictionary:
	return current_dilemma.duplicate()
