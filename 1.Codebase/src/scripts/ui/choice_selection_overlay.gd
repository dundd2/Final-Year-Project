extends Control
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
signal choice_selected(choice_index: int)
signal overlay_closed()
var backdrop: ColorRect
var panel: Panel
var title_label: Label
var subtitle_label: Label
var choices_scroll: ScrollContainer
var choices_container: VBoxContainer
var cancel_button: Button
var choice_buttons: Array[Button] = []
var current_choices: Array[Dictionary] = []
var _lang: String = "en"
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_lang = GameState.current_language if GameState else "en"
	_cache_nodes()
	_apply_styles()
	_connect_signals()
	if panel:
		UIStyleManager.fade_in(panel, 0.25)
	if not choice_buttons.is_empty() and choice_buttons[0]:
		choice_buttons[0].grab_focus()
func _find_node(node_name: String) -> Node:
	return find_child(node_name, true, false)
func _cache_nodes():
	backdrop = get_node_or_null("Backdrop") as ColorRect
	panel = get_node_or_null("CenterContainer/Panel") as Panel
	title_label = _find_node("TitleLabel") as Label
	subtitle_label = _find_node("SubtitleLabel") as Label
	choices_scroll = _find_node("ChoicesScrollContainer") as ScrollContainer
	choices_container = _find_node("ChoicesContainer") as VBoxContainer
	cancel_button = _find_node("CancelButton") as Button
func _apply_styles():
	if backdrop:
		backdrop.color = Color(0, 0, 0, 0.85)
		backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	if panel:
		UIStyleManager.apply_panel_style(panel, 0.98, UIStyleManager.CORNER_RADIUS_LARGE)
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if title_label:
		var title_text = "Choose Your Action" if _lang == "en" else "選擇你的行動"
		title_label.text = title_text
		title_label.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	if subtitle_label:
		var subtitle_text = "Select how you want to proceed..." if _lang == "en" else "選擇你想要如何進行..."
		subtitle_label.text = subtitle_text
		subtitle_label.add_theme_color_override("font_color", Color(0.78, 0.83, 0.95))
	if cancel_button:
		UIStyleManager.apply_button_style(cancel_button, "secondary", "medium")
		UIStyleManager.add_hover_scale_effect(cancel_button, 1.05)
		UIStyleManager.add_press_feedback(cancel_button)
		cancel_button.text = "← Cancel" if _lang == "en" else "← 取消"
		cancel_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
func _connect_signals():
	if cancel_button and not cancel_button.pressed.is_connected(_on_cancel_pressed):
		cancel_button.pressed.connect(_on_cancel_pressed)
func setup_choices(choices: Array[Dictionary]):
	current_choices = choices
	_populate_choices()
func _populate_choices():
	if not choices_container:
		return
	for button in choice_buttons:
		if is_instance_valid(button):
			button.queue_free()
	choice_buttons.clear()
	for child in choices_container.get_children():
		child.queue_free()
	if current_choices.is_empty():
		_show_no_choices()
		return
	for i in range(current_choices.size()):
		var choice = current_choices[i]
		var button = _create_choice_button(choice, i)
		choices_container.add_child(button)
		choice_buttons.append(button)
		_animate_button_entrance(button, i)
func _show_no_choices():
	var label = Label.new()
	var text = "No choices available." if _lang == "en" else "沒有可用的選項。"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	choices_container.add_child(label)
func _create_choice_button(choice: Dictionary, index: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(0, 85)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = choice.get("text", "Unknown choice")
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.clip_text = false
	button.add_theme_font_size_override("font_size", 20)
	var choice_type = String(choice.get("type", ""))
	match choice_type:
		"positive":
			UIStyleManager.apply_button_style(button, "warning", "large")
		"complain":
			UIStyleManager.apply_button_style(button, "danger", "large")
		"prayer":
			UIStyleManager.apply_button_style(button, "accent", "large")
		"cautious":
			UIStyleManager.apply_button_style(button, "primary", "large")
		"balanced":
			UIStyleManager.apply_button_style(button, "accent", "large")
		"reckless":
			UIStyleManager.apply_button_style(button, "danger", "large")
		_:
			UIStyleManager.apply_button_style(button, "primary", "large")
	UIStyleManager.add_hover_scale_effect(button, 1.03)
	UIStyleManager.add_press_feedback(button)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(_on_choice_button_pressed.bind(index))
	return button
func _animate_button_entrance(button: Button, index: int):
	button.modulate.a = 0.0
	button.scale = Vector2(0.9, 0.9)
	await get_tree().create_timer(0.08 * float(index)).timeout
	var tween = button.create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "modulate:a", 1.0, 0.3)
	tween.tween_property(button, "scale", Vector2.ONE, 0.4)
func _on_choice_button_pressed(choice_index: int):
	if AudioManager:
		AudioManager.play_sfx("menu_click")
	choice_selected.emit(choice_index)
	_close_overlay()
func _on_cancel_pressed():
	if AudioManager:
		AudioManager.play_sfx("menu_back")
	overlay_closed.emit()
	_close_overlay()
func _close_overlay():
	if panel:
		var tween = panel.create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(panel, "modulate:a", 0.0, 0.2)
		await tween.finished
	queue_free()
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()
