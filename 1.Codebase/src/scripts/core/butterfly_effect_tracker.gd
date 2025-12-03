extends Node
class_name ButterflyEffectTracker
signal choice_recorded(choice_id: String)
signal consequence_triggered(choice_id: String, consequence: Dictionary)
signal butterfly_effect_revealed(choice_id: String, scenes_later: int)
var recorded_choices: Array[Dictionary] = []
var current_scene_number: int = 0
var next_choice_id: int = 1
const MAX_STORED_CHOICES: int = 100
const CONSEQUENCE_LOOKBACK_SCENES: int = 20 
enum ChoiceType {
	MINOR, 
	MAJOR, 
	CRITICAL, 
}
func _ready():
	print("[DEBUG] ButterflyEffectTracker initialized")
func record_choice(
		choice_input: Variant,
		choice_type: String = "major",
		tags: Array = [],
		predicted_consequences: Array = [],
) -> String:
	var choice_text := ""
	var resolved_type := choice_type
	var resolved_tags: Array = tags.duplicate()
	var resolved_consequences: Array = predicted_consequences.duplicate(true)
	var source_metadata: Dictionary = { }
	if choice_input is Dictionary:
		var choice_dict: Dictionary = (choice_input as Dictionary).duplicate(true)
		choice_text = String(choice_dict.get("text", choice_dict.get("choice_text", ""))).strip_edges()
		if choice_text.is_empty():
			choice_text = String(choice_dict.get("description", "")).strip_edges()
		if choice_text.is_empty():
			choice_text = "Unnamed choice"
		var dict_type := String(choice_dict.get("importance", choice_dict.get("choice_type", resolved_type)))
		if not dict_type.is_empty():
			resolved_type = dict_type
		var dict_tags: Variant = choice_dict.get("tags", [])
		if dict_tags is Array:
			for tag in dict_tags:
				if not resolved_tags.has(tag):
					resolved_tags.append(tag)
		var dict_consequences: Variant = choice_dict.get("predicted_consequences", choice_dict.get("consequences", []))
		if dict_consequences is Array and (dict_consequences as Array).size() > 0:
			resolved_consequences = (dict_consequences as Array).duplicate(true)
		source_metadata = choice_dict
	else:
		choice_text = String(choice_input).strip_edges()
		if choice_text.is_empty():
			choice_text = "Unnamed choice"
	resolved_type = resolved_type.to_lower()
	match resolved_type:
		"critical", "major", "minor":
			pass
		_:
			resolved_type = choice_type
	var choice_id = "choice_%d_%d" % [current_scene_number, next_choice_id]
	next_choice_id += 1
	var choice_entry = {
		"id": choice_id,
		"scene_number": current_scene_number,
		"timestamp": Time.get_unix_time_from_system(),
		"choice_text": choice_text,
		"choice_type": resolved_type,
		"stats_at_time": _capture_current_stats(),
		"tags": resolved_tags,
		"consequences": resolved_consequences,
		"consequences_triggered": 0,
		"consequences_total": resolved_consequences.size(),
	}
	if not source_metadata.is_empty():
		choice_entry["metadata"] = source_metadata
	recorded_choices.append(choice_entry)
	if recorded_choices.size() > MAX_STORED_CHOICES:
		recorded_choices.remove_at(0)
	print("[DEBUG] Recorded choice: ", choice_id, " | ", choice_text.left(50))
	choice_recorded.emit(choice_id)
	return choice_id
func advance_scene():
	current_scene_number += 1
	print("[DEBUG] Advanced to scene ", current_scene_number, " | Checking for consequences...")
	_check_pending_consequences()
func _check_pending_consequences() -> Array[Dictionary]:
	var triggered: Array[Dictionary] = []
	for choice in recorded_choices:
		for consequence in choice["consequences"]:
			if not consequence.get("triggered", false):
				var trigger_scene = consequence.get("scene_number", -1)
				if trigger_scene == current_scene_number:
					consequence["triggered"] = true
					consequence["actual_scene"] = current_scene_number
					choice["consequences_triggered"] += 1
					triggered.append(
						{
							"choice_id": choice["id"],
							"choice_text": choice["choice_text"],
							"scenes_ago": current_scene_number - choice["scene_number"],
							"consequence": consequence,
						},
					)
					print(
						"[DEBUG] Consequence triggered! Choice '",
						choice["id"],
						"' from ",
						current_scene_number - choice["scene_number"],
						" scenes ago",
					)
					consequence_triggered.emit(choice["id"], consequence)
					butterfly_effect_revealed.emit(choice["id"], current_scene_number - choice["scene_number"])
	return triggered
func trigger_consequence_for_choice(choice_id: String, consequence_description: String, severity: String = "medium") -> bool:
	var choice = get_choice_by_id(choice_id)
	if choice.is_empty():
		print("[DEBUG] Cannot trigger consequence: choice '", choice_id, "' not found")
		return false
	var new_consequence = {
		"scene_number": current_scene_number,
		"description": consequence_description,
		"triggered": true,
		"severity": severity,
		"actual_scene": current_scene_number,
	}
	choice["consequences"].append(new_consequence)
	choice["consequences_triggered"] += 1
	choice["consequences_total"] += 1
	print("[DEBUG] Manually triggered consequence for choice '", choice_id, "'")
	consequence_triggered.emit(choice_id, new_consequence)
	butterfly_effect_revealed.emit(choice_id, current_scene_number - choice["scene_number"])
	return true
func get_choice_by_id(choice_id: String) -> Dictionary:
	for choice in recorded_choices:
		if choice["id"] == choice_id:
			return choice
	return { }
func get_choices_by_tag(tag: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for choice in recorded_choices:
		if choice["tags"].has(tag):
			results.append(choice)
	return results
func get_recent_choices(scene_count: int = 10) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var cutoff_scene = current_scene_number - scene_count
	for choice in recorded_choices:
		if choice["scene_number"] >= cutoff_scene:
			results.append(choice)
	return results
func get_choices_with_pending_consequences() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for choice in recorded_choices:
		var has_pending = false
		for consequence in choice["consequences"]:
			if not consequence.get("triggered", false):
				has_pending = true
				break
		if has_pending:
			results.append(choice)
	return results
func get_context_for_ai(language: String = "en") -> String:
	var recent = get_recent_choices(5)
	if recent.is_empty():
		return ""
	var context = ""
	if language == "en":
		context = "Recent player choices that may have consequences:\n"
	else:
		context = "玩家最近的選擇可能產生後果：\n"
	for choice in recent:
		var scenes_ago = current_scene_number - choice["scene_number"]
		var pending = 0
		for consequence in choice["consequences"]:
			if not consequence.get("triggered", false):
				pending += 1
		if language == "en":
			context += "- [%d scenes ago] %s (pending consequences: %d)\n" % [
				scenes_ago,
				choice["choice_text"],
				pending,
			]
		else:
			context += "- [%d場景前] %s（待觸發後果：%d）\n" % [
				scenes_ago,
				choice["choice_text"],
				pending,
			]
	return context
func get_butterfly_effect_summary(_language: String = "en") -> Array[Dictionary]:
	var summary: Array[Dictionary] = []
	for choice in recorded_choices:
		var triggered_count = 0
		var recent_consequences: Array[Dictionary] = []
		for consequence in choice["consequences"]:
			if consequence.get("triggered", false):
				triggered_count += 1
				var actual_scene = consequence.get("actual_scene", -1)
				if actual_scene >= current_scene_number - 5: 
					recent_consequences.append(consequence)
		if triggered_count > 0:
			summary.append(
				{
					"choice_id": choice["id"],
					"choice_text": choice["choice_text"],
					"scene_number": choice["scene_number"],
					"scenes_ago": current_scene_number - choice["scene_number"],
					"consequences_triggered": triggered_count,
					"consequences_total": choice["consequences"].size(),
					"recent_consequences": recent_consequences,
					"choice_type": choice["choice_type"],
				},
			)
	summary.sort_custom(func(a, b): return a["scene_number"] > b["scene_number"])
	return summary
func get_eligible_for_ripple() -> Array[Dictionary]:
	var eligible: Array[Dictionary] = []
	for choice in recorded_choices:
		var scenes_since = current_scene_number - choice["scene_number"]
		if scenes_since >= 3 and scenes_since <= CONSEQUENCE_LOOKBACK_SCENES:
			var triggered = choice.get("consequences_triggered", 0)
			var _total = choice.get("consequences_total", 0)
			var max_consequences = 1
			match choice["choice_type"]:
				"critical":
					max_consequences = 5
				"major":
					max_consequences = 3
				"minor":
					max_consequences = 1
			if triggered < max_consequences:
				eligible.append(choice)
	return eligible
func suggest_choice_for_callback(tags: Array = [], exclude_recent_scenes: int = 3) -> Dictionary:
	var eligible = get_eligible_for_ripple()
	if not tags.is_empty():
		var filtered: Array[Dictionary] = []
		for choice in eligible:
			for tag in tags:
				if choice["tags"].has(tag):
					filtered.append(choice)
					break
		eligible = filtered
	var filtered_by_time: Array[Dictionary] = []
	for choice in eligible:
		if current_scene_number - choice["scene_number"] > exclude_recent_scenes:
			filtered_by_time.append(choice)
	if filtered_by_time.is_empty():
		return { }
	var weights: Array[float] = []
	for choice in filtered_by_time:
		var scenes_ago = current_scene_number - choice["scene_number"]
		weights.append(1.0 / sqrt(scenes_ago))
	var total_weight = 0.0
	for w in weights:
		total_weight += w
	var random_val = randf() * total_weight
	var cumulative = 0.0
	for i in range(filtered_by_time.size()):
		cumulative += weights[i]
		if random_val <= cumulative:
			return filtered_by_time[i]
	return filtered_by_time[0] if not filtered_by_time.is_empty() else { }
func clear_all():
	recorded_choices.clear()
	current_scene_number = 0
	next_choice_id = 1
	print("[DEBUG] ButterflyEffectTracker cleared")
func get_save_data() -> Dictionary:
	return {
		"recorded_choices": recorded_choices.duplicate(true),
		"current_scene_number": current_scene_number,
		"next_choice_id": next_choice_id,
	}
func load_save_data(data: Dictionary):
	recorded_choices = data.get("recorded_choices", []).duplicate(true)
	current_scene_number = data.get("current_scene_number", 0)
	next_choice_id = data.get("next_choice_id", 1)
	print("[DEBUG] ButterflyEffectTracker loaded: ", recorded_choices.size(), " choices")
func _capture_current_stats() -> Dictionary:
	if not GameState:
		return { }
	return {
		"reality": GameState.reality_score,
		"positive": GameState.positive_energy,
		"entropy": GameState.entropy_level,
		"phase": GameState.game_phase,
	}
