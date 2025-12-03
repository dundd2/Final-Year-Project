extends BaseController
class_name StoryAssetController
const NPC_PORTRAIT_LOADER := preload("res://1.Codebase/src/scripts/core/npc_portrait_loader.gd")
const DIRECTIVE_SNIPPET_LIMIT := 240
var asset_interaction_system: Node 
var assets_container: Container
var npc_slots: Dictionary = { }
var asset_card_scene: PackedScene
func _init(p_story_scene: Control) -> void:
	super(p_story_scene) 
	asset_interaction_system = ServiceLocator.get_asset_interaction_system() if ServiceLocator else null
	asset_card_scene = load("res://1.Codebase/src/scenes/ui/asset_card.tscn")
	if story_scene.has_node("Toolbox/MarginContainer/VBoxContainer/ScrollContainer/ItemsContainer"):
		assets_container = story_scene.get_node("Toolbox/MarginContainer/VBoxContainer/ScrollContainer/ItemsContainer")
	if story_scene.has_node("CentralStage/SceneObjects/NPC1"):
		npc_slots["npc_slot_1"] = story_scene.get_node("CentralStage/SceneObjects/NPC1")
	if story_scene.has_node("CentralStage/SceneObjects/NPC2"):
		npc_slots["npc_slot_2"] = story_scene.get_node("CentralStage/SceneObjects/NPC2")
	if story_scene.has_node("CentralStage/SceneObjects/NPC3"):
		npc_slots["npc_slot_3"] = story_scene.get_node("CentralStage/SceneObjects/NPC3")
func _get_asset_registry():
	if ServiceLocator and ServiceLocator.has_service("AssetRegistry"):
		return ServiceLocator.get_service("AssetRegistry")
	return null
func prepare_mission_assets(count: int = 4) -> Dictionary:
	var asset_registry = _get_asset_registry()
	if not asset_registry or not asset_registry.has_method("get_asset_ids"):
		return { "asset_ids": [], "asset_list": [] }
	var ids_variant: Variant = asset_registry.get_asset_ids()
	var available_ids: Array = []
	if ids_variant is Array:
		available_ids = (ids_variant as Array).duplicate()
	else:
		return { "asset_ids": [], "asset_list": [] }
	if available_ids.is_empty():
		return { "asset_ids": [], "asset_list": [] }
	available_ids.shuffle()
	var selected_ids: Array = []
	var limit: int = min(count, available_ids.size())
	for i in range(limit):
		selected_ids.append(available_ids[i])
	if selected_ids.is_empty():
		selected_ids = available_ids.slice(0, count)
	var asset_context: Dictionary = { "asset_ids": selected_ids }
	var asset_data: Array = []
	if asset_registry.has_method("get_assets_for_context"):
		var fetched_data: Variant = asset_registry.get_assets_for_context(asset_context)
		if fetched_data is Array:
			asset_data = fetched_data
	var game_state = get_game_state()
	if game_state:
		game_state.set_metadata("current_asset_ids", selected_ids)
		game_state.set_metadata("recent_assets_data", asset_data)
		if asset_registry.has_method("get_asset_icons"):
			var icons: Variant = asset_registry.get_asset_icons(asset_data)
			game_state.set_metadata("recent_asset_icons", icons)
	return {
		"asset_ids": selected_ids,
		"asset_list": asset_data,
		"asset_data": asset_data,
	}
func get_current_asset_ids() -> Array:
	var game_state = get_game_state()
	if game_state:
		var data: Variant = game_state.get_metadata("current_asset_ids", [])
		if data is Array:
			return data
	return []
func update_asset_display() -> void:
	if not assets_container:
		return
	for child in assets_container.get_children():
		child.queue_free()
	var asset_data: Array = []
	var game_state = get_game_state()
	if game_state:
		var metadata: Variant = game_state.get_metadata("recent_assets_data", [])
		if metadata is Array:
			asset_data = metadata
	if asset_data.is_empty():
		_show_no_assets_placeholder()
		return
	for asset_entry in asset_data:
		if asset_entry is Dictionary:
			_create_asset_card(asset_entry)
func update_assets_from_directives(directives_assets: Array) -> void:
	if directives_assets.is_empty():
		update_asset_display()
		return
	var game_state = get_game_state()
	if not game_state:
		return
	var current_data: Array = []
	var metadata: Variant = game_state.get_metadata("recent_assets_data", [])
	if metadata is Array:
		current_data = metadata.duplicate(true)
	var updated = false
	for update in directives_assets:
		if not (update is Dictionary):
			continue
		var update_dict: Dictionary = update
		var id = String(update_dict.get("id", update_dict.get("asset_id", "")))
		if id.is_empty():
			continue
		var found = false
		for i in range(current_data.size()):
			var existing: Dictionary = current_data[i]
			if String(existing.get("id", "")) == id:
				for key in update_dict.keys():
					if key != "id" and key != "asset_id":
						existing[key] = update_dict[key]
				current_data[i] = existing
				found = true
				updated = true
				break
	if updated:
		game_state.set_metadata("recent_assets_data", current_data)
		print("[StoryAssetController] Updated persistent asset metadata from directives")
	update_asset_display()
func _show_no_assets_placeholder() -> void:
	var placeholder := Label.new()
	if LocalizationManager:
		placeholder.text = LocalizationManager.get_translation("PLACEHOLDER_NO_ASSETS")
	else:
		placeholder.text = "(No symbolic assets assigned yet.)"
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	assets_container.add_child(placeholder)
func _create_asset_card(asset: Dictionary) -> void:
	if not asset_card_scene or not assets_container:
		return
	var card := asset_card_scene.instantiate()
	assets_container.add_child(card)
	if card.has_method("set_asset"):
		card.set_asset(asset)
	elif card.has_method("setup"):
		card.setup(asset)
	elif card.has_method("set_asset_data"):
		card.set_asset_data(asset)
	if card.has_signal("action_requested"):
		card.action_requested.connect(_on_asset_action_requested)
func _on_asset_action_requested(asset_id: String, action_id: String) -> void:
	perform_asset_action(asset_id, action_id)
func setup_asset_interactions(asset_ids: Array) -> void:
	if not asset_interaction_system:
		return
	var asset_registry = _get_asset_registry()
	if asset_interaction_system.has_method("clear_asset_rules"):
		asset_interaction_system.clear_asset_rules()
	if asset_ids.is_empty():
		return
	for asset_id in asset_ids:
		var asset_data: Dictionary = { }
		if asset_registry and asset_registry.has_method("get_asset"):
			var fetched: Variant = asset_registry.get_asset(asset_id)
			if fetched is Dictionary:
				asset_data = fetched
		var interaction_rules := _build_default_interaction_rules(asset_id, asset_data)
		if asset_interaction_system.has_method("set_asset_context"):
			asset_interaction_system.set_asset_context(asset_id, interaction_rules)
func perform_asset_action(asset_id: String, action_id: String) -> void:
	if not asset_interaction_system:
		_report_error("AssetInteractionSystem not available")
		return
	print("[AssetController] Performing action: ", action_id, " on ", asset_id)
	var available_actions: Array = []
	if asset_interaction_system.has_method("get_available_actions_for_asset"):
		var actions_variant: Variant = asset_interaction_system.get_available_actions_for_asset(asset_id)
		if actions_variant is Array:
			available_actions = actions_variant
	if available_actions.is_empty():
		var lang := "en"
		var game_state = get_game_state()
		if game_state:
			var language_value: Variant = game_state.get("current_language")
			if typeof(language_value) == TYPE_STRING:
				lang = language_value
		var message := "No actions available for this asset."
		if lang != "en":
			message = "No available interactions for this asset."
		if story_scene and story_scene.ui_controller:
			story_scene.ui_controller.display_story(message)
		return
	var result: Dictionary = { }
	if asset_interaction_system.has_method("perform_action"):
		var result_variant: Variant = asset_interaction_system.perform_action(asset_id, action_id)
		if result_variant is Dictionary:
			result = result_variant
	if result.has("outcome_text") and story_scene and story_scene.ui_controller:
		story_scene.ui_controller.display_story(result["outcome_text"])
	if result.get("success", false) and result.has("narrative_consequence"):
		var narrative: String = str(result.get("narrative_consequence", ""))
		if not narrative.is_empty() and story_scene and story_scene.ui_controller:
			story_scene.ui_controller.display_story(narrative)
func _build_default_interaction_rules(asset_id: String, asset_data: Dictionary) -> Dictionary:
	var name: String = asset_data.get("default_name", asset_id.capitalize())
	var summary: String = asset_data.get("summary", "A symbolic asset awaiting definition.")
	var tags: Array = asset_data.get("tags", [])
	var available_actions: Array = []
	var success_conditions: Dictionary = { }
	var failure_outcomes: Dictionary = { }
	var ensure_action: Callable = func(action_id: String) -> void:
		if not available_actions.has(action_id):
			available_actions.append(action_id)
	var set_success: Callable = func(action_id: String, data: Dictionary) -> void:
		success_conditions[action_id] = data
	var set_failure: Callable = func(action_id: String, data: Dictionary) -> void:
		if data.is_empty():
			return
		failure_outcomes[action_id] = data
	ensure_action.call("EXAMINE")
	set_success.call(
		"EXAMINE",
		{
			"type": "always",
			"success_text": "You study %s and piece together its hidden symbolism." % name,
			"stat_changes": { "reality": 1 },
			"narrative": summary,
		},
	)
	var is_creature := tags.has("Creature") or tags.has("NPC") or tags.has("Entity")
	var is_hazard := tags.has("Hazard") or tags.has("Obstacle")
	var is_mystic := tags.has("Mystic") or tags.has("Lore")
	var is_interactable := tags.has("Interactable") or tags.has("Mechanical") or tags.has("Puzzle")
	if is_interactable:
		ensure_action.call("USE")
		var use_success_text := "You manipulate %s and hear ominous mechanisms stir." % name
		set_success.call(
			"USE",
			{
				"type": "always",
				"success_text": use_success_text,
				"stat_changes": { "entropy": -1 },
				"narrative": "The contraption grudgingly responds, revealing another procedural layer.",
			},
		)
		if is_hazard:
			set_failure.call(
				"USE",
				{
					"failure_text": "%s jolts violently, threatening to destabilize reality." % name,
					"stat_changes": { "entropy": 2 },
					"narrative": "Tampering without caution amplifies the world's collapse.",
				},
			)
	if is_creature:
		ensure_action.call("SPEAK")
		set_success.call(
			"SPEAK",
			{
				"type": "always",
				"success_text": "You negotiate with %s, uncovering grudges soaked in toxic positivity." % name,
				"stat_changes": { "positive_energy": -1, "reality": 1 },
				"narrative": "Their confession exposes another layer of cultish indoctrination.",
			},
		)
		ensure_action.call("PACIFY")
		set_success.call(
			"PACIFY",
			{
				"type": "stat_check",
				"stat": "positive_energy",
				"threshold": 45,
				"operator": ">=",
				"success_text": "Your forced optimism unsettles %s just enough to stand down." % name,
				"stat_changes": { "positive_energy": -3 },
				"narrative": "Peace is brokered through weaponised cheerfulness.",
			},
		)
		set_failure.call(
			"PACIFY",
			{
				"failure_text": "%s recoils from your hollow platitudes." % name,
				"stat_changes": { "entropy": 1 },
				"narrative": "The encounter frays the world's stability.",
			},
		)
		ensure_action.call("CHALLENGE")
		set_success.call(
			"CHALLENGE",
			{
				"type": "stat_check",
				"stat": "reality",
				"threshold": 55,
				"operator": ">=",
				"success_text": "You confront %s with cold facts, shaking their doctrine." % name,
				"stat_changes": { "reality": 2 },
				"narrative": "The cultist falters, revealing a crack in the regime.",
			},
		)
		set_failure.call(
			"CHALLENGE",
			{
				"failure_text": "%s doubles down on rehearsed slogans." % name,
				"stat_changes": { "positive_energy": 2 },
				"narrative": "Their relentless optimism overwhelms the moment.",
			},
		)
	if is_mystic:
		ensure_action.call("PRAY")
		set_success.call(
			"PRAY",
			{
				"type": "always",
				"success_text": "You offer a sardonic prayer at %s." % name,
				"stat_changes": { "positive_energy": 1, "reality": 1 },
				"narrative": "The ritual leaks both comfort and unease into the air.",
			},
		)
	if is_hazard:
		ensure_action.call("IGNORE")
		set_success.call(
			"IGNORE",
			{
				"type": "stat_check",
				"stat": "reality",
				"threshold": 60,
				"operator": ">=",
				"success_text": "You skirt around %s, resisting the urge to tempt fate." % name,
				"narrative": "Discipline keeps entropy at bay this time.",
			},
		)
		set_failure.call(
			"IGNORE",
			{
				"failure_text": "Turning your back on %s invites calamity." % name,
				"stat_changes": { "entropy": 3 },
				"narrative": "Neglect feeds the encroaching collapse.",
			},
		)
	if available_actions.is_empty():
		available_actions.append("EXAMINE")
	return {
		"description": summary,
		"ai_lore": summary,
		"available_actions": available_actions,
		"success_conditions": success_conditions,
		"failure_outcomes": failure_outcomes,
		"required_assets": [],
		"puzzle_solution": "",
	}
func reset_npc_slots() -> void:
	for slot in npc_slots.values():
		if slot is TextureRect:
			slot.texture = null
			slot.visible = false
func display_npc_entries(npc_entries: Array) -> void:
	reset_npc_slots()
	var slot_ids: Array = ["npc_slot_1", "npc_slot_2", "npc_slot_3"]
	var limit: int = min(npc_entries.size(), slot_ids.size())
	for i in range(limit):
		var npc_data_variant: Variant = npc_entries[i]
		if not (npc_data_variant is Dictionary):
			_report_npc_directive_issue("NPC entry is not a dictionary", npc_data_variant)
			continue
		var slot_id: String = slot_ids[i]
		if not npc_slots.has(slot_id):
			continue
		var slot: Control = npc_slots[slot_id]
		if slot is Control:
			_display_npc_in_slot(npc_data_variant, slot)
func _display_npc_in_slot(npc_data: Dictionary, slot: Control) -> void:
	if not slot:
		return
	var character_variant: Variant = npc_data.get("character_id", "")
	if not (character_variant is String):
		_report_npc_directive_issue("NPC directive missing character_id string", npc_data)
		return
	var character_id := String(character_variant).strip_edges()
	if character_id.is_empty():
		_report_npc_directive_issue("NPC directive has empty character_id", npc_data)
		return
	var expression := String(npc_data.get("expression", "neutral")).strip_edges()
	if expression.is_empty():
		expression = "neutral"
	var texture: Texture2D = _load_npc_texture(character_id, expression)
	if not texture:
		_report_npc_directive_issue(
			"npc_portrait_missing",
			"NPC portrait not found for directive entry",
			{
				"character_id": character_id,
				"expression": expression,
				"npc_data": npc_data.duplicate(true),
			},
		)
		return
	if slot is TextureRect:
		slot.texture = texture
		slot.visible = true
		slot.modulate.a = 0.0
		var tween := story_scene.create_tween()
		tween.tween_property(slot, "modulate:a", 1.0, 0.5)
	else:
		_report_npc_directive_issue(
			"npc_slot_invalid",
			"NPC slot is not a TextureRect",
			{
				"slot_path": slot.get_path(),
				"npc_data": npc_data.duplicate(true),
			},
		)
func _load_npc_texture(character_id: String, expression: String) -> Texture2D:
	var texture: Texture2D = null
	if NPC_PORTRAIT_LOADER:
		var loader = NPC_PORTRAIT_LOADER.new()
		if loader and loader.has_method("load_portrait"):
			texture = loader.load_portrait(character_id, expression)
		if texture:
			return texture
	if typeof(NPCPortraitLoader) != TYPE_NIL:
		return NPCPortraitLoader.get_npc_texture(character_id)
	return null
func _report_npc_directive_issue(reason: String, payload, extra: Dictionary = { }) -> void:
	var snippet := _directive_payload_to_snippet(payload)
	var details := { "npc_payload": snippet }
	if not extra.is_empty():
		details.merge(extra, true)
	ErrorReporterBridge.report_warning(
		get_controller_name(),
		"Invalid NPC directive: %s" % reason,
		details,
	)
	print("[StoryAssetController][NPCDirectiveError] %s | %s" % [reason, snippet])
func _directive_payload_to_snippet(payload) -> String:
	var snippet := ""
	if payload is Dictionary or payload is Array:
		snippet = JSON.stringify(payload)
		if snippet.is_empty():
			snippet = var_to_str(payload)
	else:
		snippet = str(payload)
	if snippet.length() > DIRECTIVE_SNIPPET_LIMIT:
		snippet = snippet.substr(0, DIRECTIVE_SNIPPET_LIMIT) + "..."
	return snippet
