extends RefCounted
static func validate_choice_structure(choice: Dictionary) -> bool:
	if not choice.has("text") or choice["text"].is_empty():
		return false
	if not choice.has("id"):
		return false
	return true
static func sanitize_choice(choice: Dictionary) -> Dictionary:
	var sanitized := {
		"id": choice.get("id", ""),
		"text": choice.get("text", "Unknown choice"),
		"type": choice.get("type", "normal"),
		"consequences": choice.get("consequences", { }),
		"requirements": choice.get("requirements", { }),
		"metadata": choice.get("metadata", { }),
	}
	return sanitized
static func choices_are_valid(choices: Array) -> bool:
	if choices.is_empty():
		return false
	for choice in choices:
		if not choice is Dictionary:
			return false
		if not validate_choice_structure(choice):
			return false
	return true
static func filter_available_choices(choices: Array, game_state) -> Array:
	var available := []
	for choice in choices:
		if not choice is Dictionary:
			continue
		var requirements: Dictionary = choice.get("requirements", { })
		if requirements.has("min_reality"):
			if game_state.reality_score < requirements["min_reality"]:
				continue
		if requirements.has("min_positive"):
			if game_state.positive_energy < requirements["min_positive"]:
				continue
		if requirements.has("max_entropy"):
			if game_state.entropy_level > requirements["max_entropy"]:
				continue
		if requirements.has("required_asset"):
			var required_asset: String = requirements["required_asset"]
			if not game_state.current_mission_assets.has(required_asset):
				continue
		if requirements.has("teammate_relationship"):
			var req_relationship: Dictionary = requirements["teammate_relationship"]
			var teammate: String = req_relationship.get("id", "")
			var min_level: int = req_relationship.get("min_level", 0)
			if game_state.teammate_relationships.has(teammate):
				var current_level: int = game_state.teammate_relationships[teammate]
				if current_level < min_level:
					continue
			else:
				continue
		available.append(choice)
	return available
static func calculate_choice_impact(choice: Dictionary) -> Dictionary:
	var impact := {
		"reality": 0,
		"positive": 0,
		"entropy": 0,
	}
	var consequences: Dictionary = choice.get("consequences", { })
	if consequences.has("reality_change"):
		impact["reality"] = int(consequences["reality_change"])
	if consequences.has("positive_change"):
		impact["positive"] = int(consequences["positive_change"])
	if consequences.has("entropy_change"):
		impact["entropy"] = int(consequences["entropy_change"])
	if consequences.is_empty():
		var choice_type: String = choice.get("type", "normal")
		match choice_type:
			"prayer":
				impact["positive"] = 5
				impact["reality"] = -2
			"aggressive":
				impact["entropy"] = 3
				impact["reality"] = -5
			"diplomatic":
				impact["reality"] = 3
				impact["positive"] = 2
			"deceptive":
				impact["entropy"] = 2
				impact["reality"] = -3
	return impact
static func get_choice_type_label(choice_type: String, lang: String) -> String:
	const TYPE_LABELS := {
		"prayer": {
			"en": "[Prayer]",
			"zh": "[祈禱]",
		},
		"aggressive": {
			"en": "[Aggressive]",
			"zh": "[激進]",
		},
		"diplomatic": {
			"en": "[Diplomatic]",
			"zh": "[外交]",
		},
		"deceptive": {
			"en": "[Deceptive]",
			"zh": "[欺騙]",
		},
		"sacrifice": {
			"en": "[Sacrifice]",
			"zh": "[犧牲]",
		},
		"normal": {
			"en": "",
			"zh": "",
		},
	}
	if choice_type in TYPE_LABELS and lang in TYPE_LABELS[choice_type]:
		return TYPE_LABELS[choice_type][lang]
	return ""
static func get_choice_display_text(choice: Dictionary, lang: String) -> String:
	var text: String = choice.get("text", "")
	var choice_type: String = choice.get("type", "normal")
	var type_label := get_choice_type_label(choice_type, lang)
	if not type_label.is_empty():
		return type_label + " " + text
	return text
