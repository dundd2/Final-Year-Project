class_name StorySceneUIBindings
extends RefCounted
const ERROR_CONTEXT := "StorySceneUIBindings"
const ICON_MIC = preload("res://1.Codebase/src/assets/ui/icon_mic.svg")
const ICON_HISTORY = preload("res://1.Codebase/src/assets/ui/icon_history.svg")
var story_text: RichTextLabel
var story_scroll: ScrollContainer
var stats_panel: Control
var pause_button: Button
var settings_button: Button
var journal_button: Button
var butterfly_button: Button
var reality_bar: ProgressBar
var reality_value: Label
var reality_icon_rect: TextureRect
var positive_bar: ProgressBar
var positive_value: Label
var positive_icon_rect: TextureRect
var entropy_value: Label
var entropy_icon_rect: TextureRect
var loading_overlay: Control
var loading_label: Label
var loading_sublabel: Label
var loading_dots: Label
var loading_timer_label: Label
var loading_model_label: Label
var loading_debug_label: Label
var ai_error_overlay: Control
var ai_error_title_label: Label
var ai_error_message_label: Label
var ai_error_details_label: Label
var ai_error_retry_button: Button
var ai_error_home_button: Button
var ai_error_offline_button: Button
var choices_panel: Control
var choices_container: VBoxContainer
var show_options_button: Button
var next_step_button: Button
var choice_buttons: Array = [] 
var assets_panel: Control
var assets_container: Container
var background_deco: ColorRect
var status_panel: Control
var status_label: Label
var choice_label: Label
var voice_input_button: Button
var npc_slots: Dictionary = { } 
var mission_info_label: Label
var dynamic_background: TextureRect
var character_sprites: Dictionary = { }
var character_containers: Dictionary = { }
var character_name_labels: Dictionary = { }
var atmosphere_overlay: ColorRect
var error_dialog: AcceptDialog
var asset_card_scene: PackedScene
var pause_menu_scene: PackedScene
var settings_menu_scene: PackedScene
var journal_menu_scene: PackedScene
var choice_selection_overlay_scene: PackedScene
func _init():
	asset_card_scene = preload("res://1.Codebase/src/scenes/ui/asset_card.tscn")
	pause_menu_scene = preload("res://1.Codebase/src/scenes/ui/pause_menu.tscn")
	settings_menu_scene = preload("res://1.Codebase/src/scenes/ui/settings_menu.tscn")
	journal_menu_scene = preload("res://1.Codebase/src/scenes/ui/journal_system.tscn")
	choice_selection_overlay_scene = preload("res://1.Codebase/src/scenes/ui/choice_selection_overlay.tscn")
func bind_to_scene(scene: Control) -> bool:
	if not scene:
		_report_error("Cannot bind to null scene")
		return false
	story_text = scene.get_node_or_null("NarratorBox/MarginContainer/ScrollContainer/NarratorText") as RichTextLabel
	story_scroll = scene.get_node_or_null("NarratorBox/MarginContainer/ScrollContainer") as ScrollContainer
	stats_panel = scene.get_node_or_null("TopBar") as Control
	pause_button = scene.get_node_or_null("TopBar/MarginContainer/HBoxContainer/MenuButtons/PauseBtn") as Button
	settings_button = scene.get_node_or_null("TopBar/MarginContainer/HBoxContainer/MenuButtons/SettingsBtn") as Button
	journal_button = scene.get_node_or_null("TopBar/MarginContainer/HBoxContainer/MenuButtons/JournalBtn") as Button
	reality_bar = scene.get_node_or_null("TopBar/MarginContainer/HBoxContainer/RealityScore/ProgressBar") as ProgressBar
	reality_value = scene.get_node_or_null("TopBar/MarginContainer/HBoxContainer/RealityScore/Value") as Label
	reality_icon_rect = scene.get_node_or_null("TopBar/MarginContainer/HBoxContainer/RealityScore/TitleBox/Icon") as TextureRect
	positive_bar = scene.get_node_or_null("TopBar/MarginContainer/HBoxContainer/PositiveEnergy/ProgressBar") as ProgressBar
	positive_value = scene.get_node_or_null("TopBar/MarginContainer/HBoxContainer/PositiveEnergy/Value") as Label
	positive_icon_rect = scene.get_node_or_null("TopBar/MarginContainer/HBoxContainer/PositiveEnergy/TitleBox/Icon") as TextureRect
	entropy_value = scene.get_node_or_null("TopBar/MarginContainer/HBoxContainer/EntropyLevel/Value") as Label
	entropy_icon_rect = scene.get_node_or_null("TopBar/MarginContainer/HBoxContainer/EntropyLevel/TitleBox/Icon") as TextureRect
	loading_overlay = scene.get_node_or_null("LoadingOverlay") as Control
	if loading_overlay:
		loading_label = loading_overlay.get_node_or_null("CenterContainer/VBoxContainer/LoadingLabel") as Label
		loading_sublabel = loading_overlay.get_node_or_null("CenterContainer/VBoxContainer/SubLabel") as Label
		loading_dots = loading_overlay.get_node_or_null("CenterContainer/VBoxContainer/Dots") as Label
		loading_timer_label = loading_overlay.get_node_or_null("CenterContainer/VBoxContainer/TimerLabel") as Label
		loading_model_label = loading_overlay.get_node_or_null("CenterContainer/VBoxContainer/ModelLabel") as Label
	ai_error_overlay = scene.get_node_or_null("AIErrorOverlay") as Control
	if ai_error_overlay:
		ai_error_title_label = ai_error_overlay.get_node_or_null("CenterContainer/DialogPanel/MarginContainer/VBoxContainer/TitleLabel") as Label
		ai_error_message_label = ai_error_overlay.get_node_or_null("CenterContainer/DialogPanel/MarginContainer/VBoxContainer/MessageLabel") as Label
		ai_error_details_label = ai_error_overlay.get_node_or_null("CenterContainer/DialogPanel/MarginContainer/VBoxContainer/DetailsLabel") as Label
		var button_row := ai_error_overlay.get_node_or_null("CenterContainer/DialogPanel/MarginContainer/VBoxContainer/ButtonRow")
		if button_row:
			ai_error_offline_button = button_row.get_node_or_null("OfflineButton") as Button
			ai_error_retry_button = button_row.get_node_or_null("RetryButton") as Button
			ai_error_home_button = button_row.get_node_or_null("HomeButton") as Button
	choices_panel = scene.get_node_or_null("ChoicesArea") as Control
	choices_container = scene.get_node_or_null("ChoicesArea/ChoicesContainer") as VBoxContainer
	show_options_button = scene.get_node_or_null("ChoicesArea/ShowOptionsBtn") as Button
	next_step_button = scene.get_node_or_null("NextStepButton") as Button
	choice_buttons = [
	scene.get_node_or_null("ChoicesArea/ChoicesContainer/Choice1") as Button,
	scene.get_node_or_null("ChoicesArea/ChoicesContainer/Choice2") as Button,
	scene.get_node_or_null("ChoicesArea/ChoicesContainer/Choice3") as Button,
	]
	choice_buttons = choice_buttons.filter(func(b): return b != null)
	assets_panel = scene.get_node_or_null("Toolbox") as Control
	assets_container = scene.get_node_or_null("Toolbox/MarginContainer/VBoxContainer/ScrollContainer/ItemsContainer") as Container
	background_deco = scene.get_node_or_null("BackgroundOverlay") as ColorRect
	status_panel = null 
	status_label = null 
	choice_label = null 
	npc_slots = {
	"npc_slot_1": scene.get_node_or_null("CentralStage/SceneObjects/NPC1") as TextureRect,
	"npc_slot_2": scene.get_node_or_null("CentralStage/SceneObjects/NPC2") as TextureRect,
	"npc_slot_3": scene.get_node_or_null("CentralStage/SceneObjects/NPC3") as TextureRect,
	}
	_bind_enhanced_scene_nodes(scene)
	return validate_required_nodes()
func _bind_enhanced_scene_nodes(scene: Control) -> void:
	dynamic_background = scene.get_node_or_null("DynamicBackground") as TextureRect
	atmosphere_overlay = scene.get_node_or_null("AtmosphereOverlay") as ColorRect
	var badge = scene.get_node_or_null("LocationBadge")
	if badge:
		badge.visible = false
		badge.queue_free()
	character_sprites.clear()
	character_containers.clear()
	character_name_labels.clear()
	var char_container = scene.get_node_or_null("CharacterSprites")
	if char_container:
		for child in char_container.get_children():
			if child is TextureRect:
				character_sprites[child.name] = child
	var enhanced_row := scene.get_node_or_null("CentralStage/CharacterRow")
	if enhanced_row:
		var canonical_order := ["protagonist", "gloria", "donkey", "ark", "one"]
		var index := 0
		for child in enhanced_row.get_children():
			if not (child is Control):
				continue
			var vbox := child as Control
			var sprite := vbox.get_node_or_null("Sprite") as TextureRect
			var name_label := vbox.get_node_or_null("NameLabel") as Label
			var canonical_id := ""
			if name_label:
				canonical_id = CharacterExpressionLoader.get_canonical_id(name_label.text.to_lower()) if CharacterExpressionLoader else ""
			if canonical_id == "" and vbox:
				canonical_id = CharacterExpressionLoader.get_canonical_id(vbox.name.to_lower()) if CharacterExpressionLoader else ""
			if canonical_id == "" and index < canonical_order.size():
				canonical_id = canonical_order[index]
			elif canonical_id == "":
				canonical_id = "character_%d" % (index + 1)
			character_containers[canonical_id] = vbox
			if sprite:
				character_sprites[canonical_id] = sprite
				if CharacterExpressionLoader:
					var default_texture := CharacterExpressionLoader.get_character_texture(canonical_id, "neutral")
					if default_texture:
						sprite.texture = default_texture
						sprite.visible = true
						sprite.modulate = Color(1, 1, 1, 1)
			if name_label:
				character_name_labels[canonical_id] = name_label
			index += 1
func validate_required_nodes() -> bool:
	var missing := []
	if not story_text:
		missing.append("story_text")
	if not loading_overlay:
		missing.append("loading_overlay")
	if not choices_container:
		missing.append("choices_container")
	if choice_buttons.is_empty():
		missing.append("choice_buttons (all null)")
		if not missing.is_empty():
			_report_error(
				"Missing required nodes: %s" % ", ".join(missing),
				{ "missing_nodes": missing, "context": "StorySceneUIBindings validation" },
			)
			return false
	return true
func setup_voice_input_button(scene: Control) -> Button:
	voice_input_button = Button.new()
	voice_input_button.name = "VoiceInputButton"
	voice_input_button.icon = ICON_MIC
	voice_input_button.text = ""
	voice_input_button.expand_icon = true
	voice_input_button.tooltip_text = "Voice Input"
	voice_input_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	voice_input_button.focus_mode = Control.FOCUS_CLICK
	UIStyleManager.apply_button_style(voice_input_button, "secondary", "small")
	voice_input_button.custom_minimum_size = Vector2(36, 36)
	var ai_manager = ServiceLocator.get_ai_manager() if ServiceLocator else AIManager
	if ai_manager and ai_manager.has_method("is_voice_supported"):
		voice_input_button.visible = ai_manager.is_voice_supported()
	else:
		voice_input_button.visible = false
	var parent: Control = status_panel if status_panel else stats_panel
	if parent:
		var hbox = parent.get_node_or_null("MarginContainer/HBoxContainer")
		if hbox:
			hbox.add_child(voice_input_button)
		else:
			parent.add_child(voice_input_button)
	else:
		scene.add_child(voice_input_button)
	return voice_input_button
func setup_butterfly_button(scene: Control) -> Button:
	butterfly_button = Button.new()
	butterfly_button.name = "ButterflyEffectButton"
	butterfly_button.icon = ICON_HISTORY
	butterfly_button.text = ""
	butterfly_button.expand_icon = true
	butterfly_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if stats_panel:
		var menu_buttons = stats_panel.get_node_or_null("MarginContainer/HBoxContainer/MenuButtons")
		if menu_buttons:
			menu_buttons.add_child(butterfly_button)
		else:
			stats_panel.add_child(butterfly_button)
	else:
		scene.add_child(butterfly_button)
	return butterfly_button
func _report_error(message: String, details: Dictionary = { }) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func setup_loading_debug_label() -> Label:
	loading_debug_label = Label.new()
	loading_debug_label.name = "LoadingDebugLabel"
	loading_debug_label.visible = false
	loading_debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loading_debug_label.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0))
	loading_debug_label.add_theme_constant_override("line_spacing", 2)
	if loading_overlay:
		var vbox = loading_overlay.get_node_or_null("CenterContainer/VBoxContainer")
		if vbox:
			vbox.add_child(loading_debug_label)
	return loading_debug_label
func is_fully_initialized() -> bool:
	return story_text != null and loading_overlay != null and not choice_buttons.is_empty()
func get_all_buttons() -> Array:
	var buttons := []
	if pause_button:
		buttons.append(pause_button)
	if settings_button:
		buttons.append(settings_button)
	if journal_button:
		buttons.append(journal_button)
	if butterfly_button:
		buttons.append(butterfly_button)
	if show_options_button:
		buttons.append(show_options_button)
	if next_step_button:
		buttons.append(next_step_button)
	if voice_input_button:
		buttons.append(voice_input_button)
	if ai_error_retry_button:
		buttons.append(ai_error_retry_button)
	if ai_error_home_button:
		buttons.append(ai_error_home_button)
	if ai_error_offline_button:
		buttons.append(ai_error_offline_button)
	buttons.append_array(choice_buttons)
	return buttons
func get_stat_display_nodes() -> Dictionary:
	return {
		"reality_bar": reality_bar,
		"reality_value": reality_value,
		"reality_icon": reality_icon_rect,
		"positive_bar": positive_bar,
		"positive_value": positive_value,
		"positive_icon": positive_icon_rect,
		"entropy_value": entropy_value,
		"entropy_icon": entropy_icon_rect,
	}
func get_npc_slot(slot_id: String) -> TextureRect:
	return npc_slots.get(slot_id, null)
func has_enhanced_scene() -> bool:
	return dynamic_background != null or not character_sprites.is_empty()
