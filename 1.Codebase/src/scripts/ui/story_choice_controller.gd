extends BaseController
class_name StoryChoiceController
const GLORIA_POSITIVE_THRESHOLD := 30
const PRAYER_CONTEXT_MISSION := "mission"
const ARCHETYPE_CONFIG := {
	"cautious": {
		"label_en": "[Cautious]",
		"label_zh": "[謹慎]",
		"style": "primary",
		"default_difficulty": 6,
	},
	"balanced": {
		"label_en": "[Balanced]",
		"label_zh": "[權衡]",
		"style": "accent",
	},
	"reckless": {
		"label_en": "[Reckless]",
		"label_zh": "[瘋狂]",
		"style": "danger",
	},
	"positive": {
		"label_en": "[Positive]",
		"label_zh": "[樂觀]",
		"style": "warning",
	},
	"complain": {
		"label_en": "[Complain]",
		"label_zh": "[抱怨]",
		"style": "danger",
	},
}
const MAX_CHOICE_SUMMARY_LENGTH := 220
const MAX_CHOICE_SUMMARY_WORDS := 20
var choice_buttons: Array[Button] = []
var choices_container: VBoxContainer
var show_options_button: Button
var current_choices: Array[Dictionary] = []
var force_prayer_only: bool = false
func _init(p_story_scene: Control) -> void:
	super(p_story_scene) 
	if story_scene.has_node("ChoicesArea/ChoicesContainer"):
		choices_container = story_scene.get_node("ChoicesArea/ChoicesContainer")
		var button_paths := [
			"ChoicesArea/ChoicesContainer/Choice1",
			"ChoicesArea/ChoicesContainer/Choice2",
			"ChoicesArea/ChoicesContainer/Choice3",
		]
		for path in button_paths:
			var node := story_scene.get_node_or_null(path)
			if node is Button:
				choice_buttons.append(node as Button)
	if story_scene.has_node("ChoicesArea/ShowOptionsBtn"):
		var node := story_scene.get_node("ChoicesArea/ShowOptionsBtn")
		if node is Button:
			show_options_button = node
func _get_language() -> String:
	var game_state = get_game_state()
	if game_state:
		var value: Variant = game_state.get("current_language")
		if typeof(value) == TYPE_STRING:
			var lang := String(value)
			if not lang.is_empty():
				return lang
	return "en"
func _get_player_stats() -> Dictionary:
	var game_state = get_game_state()
	if not game_state:
		return { }
	var stats: Variant = game_state.get("player_stats")
	if stats is Dictionary:
		return stats
	return { }
func _get_scene_flag(flag_name: String) -> bool:
	if not story_scene:
		return false
	var value: Variant = story_scene.get(flag_name)
	if typeof(value) == TYPE_BOOL:
		return value
	return false
func _get_prayer_text(lang: String) -> String:
	if lang == "en":
		return "[Pray] Appeal to the Flying Spaghetti Monster"
	return "[Pray] Offer a desperate prayer"
func generate_choices() -> void:
	var game_state = get_game_state()
	if not game_state:
		return
	var lang := _get_language()
	var prayer_text := _get_prayer_text(lang)
	if _get_scene_flag("in_night_cycle"):
		hide_choice_buttons()
		return
	if force_prayer_only:
		force_prayer_only = false
		_show_prayer_only(prayer_text)
		return
	current_choices = _build_choice_list(lang, prayer_text)
	_display_choices()
func _build_choice_list(lang: String, prayer_text: String) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var stats := _get_player_stats()
	if int(stats.get("logic", 0)) >= 3:
		choices.append(_make_skill_choice("logic", 5, "[Logic] Analyze the problem rationally"))
	if int(stats.get("perception", 0)) >= 3:
		choices.append(_make_skill_choice("perception", 6, "[Perception] Observe the subtle details"))
	if int(stats.get("composure", 0)) >= 3:
		choices.append(_make_skill_choice("composure", 5, "[Composure] Stay calm and hold the line"))
	if int(stats.get("empathy", 0)) >= 3:
		choices.append(_make_skill_choice("empathy", 7, "[Empathy] Listen for the human cost"))
	choices.append(
		{
			"text": "[Positive Energy] Lean into relentless optimism",
			"type": "positive",
			"skill": null,
			"difficulty": 0,
		},
	)
	choices.append(
		{
			"text": "[Complain] This mission is nonsense",
			"type": "complain",
			"skill": null,
			"difficulty": 0,
		},
	)
	choices.append(
		{
			"text": prayer_text,
			"type": "prayer",
			"skill": null,
			"difficulty": 0,
		},
	)
	return choices
func _make_skill_choice(skill: String, difficulty: int, text: String) -> Dictionary:
	return {
		"text": text,
		"type": skill,
		"skill": skill,
		"difficulty": difficulty,
	}
func apply_ai_choices(ai_choices: Array[Dictionary], lang: String) -> void:
	var normalized: Array[Dictionary] = []
	for entry in ai_choices:
		if entry is Dictionary:
			var built := _build_archetype_choice(entry, lang)
			if not built.is_empty():
				normalized.append(built)
	if normalized.is_empty():
		generate_choices()
		return
	var prayer_text := _get_prayer_text(lang)
	normalized.append({
		"text": prayer_text,
		"type": "prayer",
		"skill": null,
		"difficulty": 0,
		"effect_type": "prayer"
	})
	current_choices = normalized
	if GameState:
		GameState.set_metadata("current_choices", current_choices)
	_display_choices()
func _build_archetype_choice(entry: Dictionary, lang: String) -> Dictionary:
	var archetype := String(entry.get("archetype", "")).to_lower()
	if not ARCHETYPE_CONFIG.has(archetype):
		return { }
	var summary := String(entry.get("summary", "")).strip_edges()
	if summary.is_empty():
		return { }
	summary = _clamp_summary_length(summary)
	var label := _get_archetype_label(archetype, lang)
	var text := "%s %s" % [label, summary]
	var effect_type := _map_archetype_to_effect(archetype)
	var choice := {
		"text": text,
		"type": archetype,
		"summary": summary,
		"skill": "",
		"difficulty": int(ARCHETYPE_CONFIG[archetype].get("default_difficulty", 0)),
		"effect_type": effect_type,
	}
	if archetype == "cautious":
		choice["skill"] = _select_best_skill()
		choice["effect_type"] = choice["skill"]
	return choice
func _show_prayer_only(prayer_text: String) -> void:
	current_choices = [
		{
			"text": prayer_text,
			"type": "prayer",
			"skill": null,
			"difficulty": 0,
		},
	]
	for i in range(choice_buttons.size()):
		var button := choice_buttons[i]
		if i == 0:
			button.text = prayer_text
			button.visible = true
			button.disabled = false
			UIStyleManager.apply_button_style(button, "accent", "large")
			UIStyleManager.add_hover_scale_effect(button, 1.08)
			UIStyleManager.add_press_feedback(button)
			button.modulate.a = 1.0
			button.scale = Vector2.ONE
		else:
			button.visible = false
			button.disabled = true
func _display_choices() -> void:
	var audio_manager = get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("card_draw", 0.8)
	if story_scene and story_scene.has_node("NextStepButton"):
		var next_btn = story_scene.get_node("NextStepButton")
		if next_btn:
			next_btn.visible = true
			next_btn.modulate.a = 0.0
			next_btn.scale = Vector2(0.9, 0.9)
			var tween = next_btn.create_tween()
			tween.set_parallel(true)
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_BACK)
			tween.tween_property(next_btn, "modulate:a", 1.0, 0.4)
			tween.tween_property(next_btn, "scale", Vector2.ONE, 0.5)
	for button in choice_buttons:
		if button:
			button.visible = false
			button.disabled = true
func _setup_choice_button(index: int) -> void:
	var button: Button = choice_buttons[index]
	var choice: Dictionary = current_choices[index]
	button.text = choice.get("text", "")
	button.visible = true
	button.disabled = false
	var choice_type := String(choice.get("type", ""))
	match choice_type:
		"positive":
			UIStyleManager.apply_button_style(button, "warning", "large")
		"complain":
			UIStyleManager.apply_button_style(button, "danger", "large")
		"prayer":
			UIStyleManager.apply_button_style(button, "accent", "large")
		_:
			UIStyleManager.apply_button_style(button, "primary", "large")
	UIStyleManager.add_hover_scale_effect(button, 1.08)
	UIStyleManager.add_press_feedback(button)
	_animate_choice_entrance(button, index)
func _animate_choice_entrance(button: Button, index: int) -> void:
	button.modulate.a = 0.0
	button.scale = Vector2(0.85, 0.85)
	var original_y := button.position.y
	button.position.y += 20.0
	await story_scene.get_tree().create_timer(0.12 * float(index)).timeout
	var tween := button.create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "modulate:a", 1.0, 0.4)
	tween.tween_property(button, "scale", Vector2.ONE, 0.5)
	tween.tween_property(button, "position:y", original_y, 0.5)
func on_choice_selected(choice_index: int) -> void:
	if _get_scene_flag("awaiting_ai_response"):
		return
	if choice_index >= current_choices.size():
		return
	var choice: Dictionary = current_choices[choice_index]
	print("[ChoiceController] Player selected: ", choice.get("text", "?"))
	if GameState:
		GameState.mission_turn_count += 1
	if story_scene:
		var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
		if tutorial_system and tutorial_system.has_method("check_tutorial_trigger"):
			tutorial_system.check_tutorial_trigger("first_choice")
	_record_butterfly_choice(choice)
	_play_choice_sound(choice)
	disable_choice_buttons()
	var lang := _get_language()
	if story_scene.ui_controller:
		var status_text := "Processing..." if lang == "en" else "Processing choice..."
		story_scene.ui_controller.set_status_text(status_text)
	process_choice(choice)
func _play_choice_sound(choice: Dictionary) -> void:
	var audio_manager = get_audio_manager()
	if not audio_manager:
		return
	var effect_type := String(choice.get("effect_type", choice.get("type", "")))
	match effect_type:
		"prayer":
			audio_manager.play_sfx("watson_games")
		"complain", "reckless":
			audio_manager.play_sfx("angry_click")
		"positive", "balanced":
			audio_manager.play_sfx("countdown")
		"cautious":
			audio_manager.play_sfx("menu_focus")
		_:
			audio_manager.play_sfx("menu_click")
func _record_butterfly_choice(choice: Dictionary) -> void:
	var game_state = get_game_state()
	if not game_state:
		return
	var tracker: Variant = game_state.get("butterfly_tracker")
	if tracker and tracker.has_method("record_choice"):
		tracker.record_choice(choice)
func process_choice(choice: Dictionary) -> void:
	var game_state = get_game_state()
	if not game_state:
		return
	var lang := _get_language()
	var choice_type := String(choice.get("type", ""))
	var effect_type := String(choice.get("effect_type", choice_type))
	print(
		"[ChoiceController] Processing choice | text=%s | type=%s | effect=%s" % [
			choice.get("text", "?"),
			choice_type,
			effect_type,
		],
	)
	match effect_type:
		"logic", "perception", "composure", "empathy":
			_process_skill_choice(choice)
		"positive":
			_process_positive_choice(choice, lang)
		"complain":
			_process_complain_choice(choice, lang)
		"prayer":
			_process_prayer_choice()
		"cautious":
			_process_cautious_choice(choice)
		"balanced":
			_process_balanced_choice(choice, lang)
		"reckless":
			_process_reckless_choice(choice, lang)
	if choice_type != "prayer":
		enable_choice_buttons()
func _process_skill_choice(choice: Dictionary) -> void:
	var game_state = get_game_state()
	if not game_state:
		return
	if game_state.has_method("consume_honeymoon_charge"):
		game_state.consume_honeymoon_charge("player_decision")
	print(
		"[ChoiceController] Skill choice start | skill=%s | difficulty=%d" % [
			String(choice.get("skill", "")),
			int(choice.get("difficulty", 0)),
		],
	)
	var skill := String(choice.get("skill", ""))
	var difficulty := int(choice.get("difficulty", 0))
	var check_result: Dictionary = { }
	if game_state.has_method("skill_check"):
		var result_variant: Variant = game_state.skill_check(skill, difficulty)
		if result_variant is Dictionary:
			check_result = result_variant
	var success := bool(check_result.get("success", false))
	print("[ChoiceController] Skill check result | success=%s | roll=%s" % [success, str(check_result.get("roll", "-"))])
	var lang := _get_language()
	var audio_manager = get_audio_manager()
	if audio_manager:
		if success:
			audio_manager.play_sfx("roll_doubles")
		else:
			audio_manager.play_sfx("angry_click", 0.7)
	if success:
		if game_state.has_method("modify_reality_score"):
			game_state.modify_reality_score(5, "Skill check success")
		if game_state.has_method("modify_positive_energy"):
			game_state.modify_positive_energy(-5, "Rational thought reduces delusion")
		var achievement_system = get_achievement_system()
		if achievement_system and achievement_system.has_method("check_skill_check_success"):
			achievement_system.check_skill_check_success(skill)
		if choice.get("type", "") == "logic" and randf() < 0.4:
			if story_scene.narrative_controller:
				story_scene.narrative_controller.request_teammate_interference("donkey", choice.get("text", ""))
			return
		if story_scene.ui_controller:
			var text_success := "[color=green]Success![/color]" if lang == "en" else "[color=green]成功！[/color]"
			story_scene.ui_controller.display_story(text_success)
	else:
		if game_state.has_method("modify_reality_score"):
			game_state.modify_reality_score(-3, "Skill check failure")
		if game_state.has_method("record_event"):
			game_state.record_event(
				"skill_check_failed",
				{
					"skill": skill,
					"difficulty": difficulty,
					"roll": check_result.get("roll", 0),
				},
			)
		if story_scene.ui_controller:
			var text_fail := "[color=red]Failed...[/color]" if lang == "en" else "[color=red]失敗...[/color]"
			story_scene.ui_controller.display_story(text_fail)
	if story_scene.narrative_controller:
		story_scene.narrative_controller.request_consequence_generation(choice, success)
func _process_cautious_choice(choice: Dictionary) -> void:
	if String(choice.get("skill", "")).is_empty():
		choice["skill"] = _select_best_skill()
	if int(choice.get("difficulty", 0)) <= 0:
		choice["difficulty"] = int(ARCHETYPE_CONFIG["cautious"].get("default_difficulty", 6))
	_process_skill_choice(choice)
	_display_choice_summary(choice, Color(0.5, 0.8, 1.0))
func _process_positive_choice(choice: Dictionary, lang: String) -> void:
	var game_state = get_game_state()
	if not game_state:
		return
	if game_state.has_method("consume_honeymoon_charge"):
		game_state.consume_honeymoon_charge("positive_choice")
	if game_state.has_method("modify_positive_energy"):
		game_state.modify_positive_energy(15, "Chose positive thinking")
	if game_state.has_method("modify_reality_score"):
		game_state.modify_reality_score(-5, "Positive thinking detachment")
	print("[ChoiceController] Positive choice: +15 positive, -5 reality")
	if story_scene.ui_controller:
		var message := "[color=yellow]You embraced toxic optimism...[/color]" if lang == "en" else "[color=yellow]你擁抱了有毒的樂觀...[/color]"
		story_scene.ui_controller.display_story(message)
	if story_scene.narrative_controller:
		story_scene.narrative_controller.request_consequence_generation(choice, false)
func _process_balanced_choice(choice: Dictionary, lang: String) -> void:
	var game_state = get_game_state()
	if not game_state:
		return
	if game_state.has_method("consume_honeymoon_charge"):
		game_state.consume_honeymoon_charge("balanced_choice")
	if game_state.has_method("modify_reality_score"):
		game_state.modify_reality_score(2, "Balanced compromise")
	if game_state.has_method("modify_entropy"):
		game_state.modify_entropy(1, "Balanced compromise tension")
	if game_state.has_method("modify_positive_energy"):
		game_state.modify_positive_energy(-2, "Balanced view")
	if story_scene.ui_controller:
		var message := "[color=skyblue]You attempt a measured compromise...[/color]" if lang == "en" else "[color=skyblue]你嘗試一個謹慎權衡的決定...[/color]"
		story_scene.ui_controller.display_story(message)
	if story_scene.narrative_controller:
		story_scene.narrative_controller.request_consequence_generation(choice, true)
func _process_complain_choice(choice: Dictionary, lang: String) -> void:
	var game_state = get_game_state()
	if not game_state:
		return
	if game_state.has_method("consume_honeymoon_charge"):
		game_state.consume_honeymoon_charge("complain")
	if game_state.has_method("modify_positive_energy"):
		game_state.modify_positive_energy(-10, "Venting negativity")
	var complaint_count := int(game_state.get("complaint_counter"))
	complaint_count += 1
	game_state.set("complaint_counter", complaint_count)
	print("[ChoiceController] Complain choice: complaint_counter=%d" % complaint_count)
	if complaint_count >= 3:
		var achievement_system = get_achievement_system()
		if achievement_system and achievement_system.has_method("check_gloria_trigger"):
			achievement_system.check_gloria_trigger()
		var positive_energy := int(game_state.get("positive_energy"))
		if positive_energy <= GLORIA_POSITIVE_THRESHOLD:
			if story_scene.narrative_controller:
				story_scene.narrative_controller.request_gloria_intervention(choice)
		else:
			if story_scene.narrative_controller:
				story_scene.narrative_controller.request_teammate_interference("gloria", choice.get("text", ""))
	else:
		if story_scene.ui_controller:
			var message := "[color=gray]You complained, but nobody listens...[/color]" if lang == "en" else "[color=gray]你抱怨了，但沒人理會...[/color]"
			story_scene.ui_controller.display_story(message)
		if story_scene.narrative_controller:
			story_scene.narrative_controller.request_consequence_generation(choice, false)
func _process_reckless_choice(choice: Dictionary, lang: String) -> void:
	var game_state = get_game_state()
	if not game_state:
		return
	if game_state.has_method("consume_honeymoon_charge"):
		game_state.consume_honeymoon_charge("reckless_choice")
	if game_state.has_method("modify_positive_energy"):
		game_state.modify_positive_energy(10, "Reckless gambit")
	if game_state.has_method("modify_entropy"):
		game_state.modify_entropy(3, "Reckless chaos")
	if game_state.has_method("modify_reality_score"):
		game_state.modify_reality_score(-6, "Reckless fallout")
	if story_scene.ui_controller:
		var message := "[color=orange]You ignite a reckless gambit...[/color]" if lang == "en" else "[color=orange]你點燃了一場瘋狂的賭局...[/color]"
		story_scene.ui_controller.display_story(message)
	if story_scene.narrative_controller:
		story_scene.narrative_controller.request_consequence_generation(choice, false)
func _process_prayer_choice() -> void:
	if story_scene:
		var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
		if tutorial_system and tutorial_system.has_method("check_tutorial_trigger"):
			tutorial_system.check_tutorial_trigger("first_prayer")
	if story_scene:
		story_scene.set("prayer_context", PRAYER_CONTEXT_MISSION)
	if story_scene.overlay_controller:
		story_scene.overlay_controller.open_prayer_system()
func hide_choice_buttons() -> void:
	for button in choice_buttons:
		button.visible = false
func clear_and_hide() -> void:
	current_choices.clear()
	hide_choice_buttons()
	if choices_container:
		choices_container.visible = false
	if show_options_button:
		show_options_button.visible = false
	if story_scene and story_scene.ui and story_scene.ui.next_step_button:
		story_scene.ui.next_step_button.visible = false
	elif story_scene and story_scene.has_node("NextStepButton"):
		story_scene.get_node("NextStepButton").visible = false
func disable_choice_buttons() -> void:
	for button in choice_buttons:
		button.disabled = true
func enable_choice_buttons() -> void:
	for button in choice_buttons:
		if button.visible:
			button.disabled = false
func _clamp_summary_length(summary: String) -> String:
	var trimmed := summary.strip_edges()
	if trimmed.is_empty():
		return trimmed
	var normalized := trimmed.replace("\n", " ").replace("\t", " ")
	var words := normalized.split(" ", false)
	if words.size() > MAX_CHOICE_SUMMARY_WORDS:
		normalized = " ".join(words.slice(0, MAX_CHOICE_SUMMARY_WORDS))
	else:
		normalized = normalized.strip_edges()
	if normalized.length() > MAX_CHOICE_SUMMARY_LENGTH:
		normalized = normalized.substr(0, MAX_CHOICE_SUMMARY_LENGTH).strip_edges()
	return normalized
func _get_archetype_label(archetype: String, lang: String) -> String:
	if not ARCHETYPE_CONFIG.has(archetype):
		return "[Action]"
	var labels: Dictionary = ARCHETYPE_CONFIG[archetype]
	var lang_key := "label_en" if lang == "en" else "label_zh"
	return String(labels.get(lang_key, "[Action]"))
func _select_best_skill() -> String:
	var stats := _get_player_stats()
	var best_skill := "logic"
	var best_value := -999999
	for skill in ["logic", "perception", "composure", "empathy"]:
		var value := int(stats.get(skill, 0))
		if value > best_value:
			best_value = value
			best_skill = skill
	return best_skill
func _map_archetype_to_effect(archetype: String) -> String:
	match archetype:
		"balanced":
			return "balanced"
		"reckless":
			return "reckless"
		"cautious":
			return "cautious"
		_:
			return archetype
func _display_choice_summary(choice: Dictionary, color: Color = Color(0.9, 0.9, 0.9, 1.0)) -> void:
	var summary := String(choice.get("summary", "")).strip_edges()
	if summary.is_empty():
		return
	if story_scene and story_scene.ui_controller:
		var color_hex := "#%02x%02x%02x" % [
			int(color.r * 255.0),
			int(color.g * 255.0),
			int(color.b * 255.0),
		]
		var formatted := "[color=%s]%s[/color]" % [color_hex, summary]
		story_scene.ui_controller.display_story(formatted)
func show_choices_container() -> void:
	if choices_container:
		choices_container.visible = true
	if show_options_button:
		show_options_button.visible = false
func on_show_options_pressed() -> void:
	show_choices_container()
func find_choice_by_keyword(text: String) -> int:
	var lower_text := text.to_lower()
	if lower_text.find("pray") != -1:
		for i in range(current_choices.size()):
			if String(current_choices[i].get("type", "")) == "prayer":
				return i
		return -2
	for i in range(current_choices.size()):
		var choice_text := String(current_choices[i].get("text", "")).to_lower()
		if choice_text.is_empty():
			continue
		if choice_text.find(lower_text) != -1:
			return i
		var parts := lower_text.split(" ")
		for word in parts:
			if word.length() >= 3 and choice_text.find(word) != -1:
				return i
	return -1
func on_voice_transcription_ready(text: String) -> void:
	var index := find_choice_by_keyword(text)
	if index == -2:
		_process_prayer_choice()
	elif index >= 0:
		on_choice_selected(index)
	else:
		print("[ChoiceController] No matching choice for voice input: ", text)
