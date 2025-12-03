extends Control
signal popup_closed
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var message_label: RichTextLabel = $Panel/VBoxContainer/MessageLabel
@onready var got_it_button: Button = $Panel/VBoxContainer/ButtonContainer/GotItButton
@onready var skip_all_button: Button = $Panel/VBoxContainer/ButtonContainer/SkipAllButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var current_highlight_element: String = ""
var current_step_id: String = ""
func _ready() -> void:
	modulate.a = 0.0
	if got_it_button:
		got_it_button.pressed.connect(_on_got_it_pressed)
	if skip_all_button:
		skip_all_button.pressed.connect(_on_skip_all_pressed)
	_fade_in()
func setup(text: String, highlight_element: String = "", step_id: String = "") -> void:
	current_highlight_element = highlight_element
	current_step_id = step_id
	var lang: String = _get_current_language()
	if title_label:
		if LocalizationManager:
			title_label.text = LocalizationManager.get_translation("TUTORIAL_TITLE", lang)
		else:
			title_label.text = "Tutorial Tip"
	if message_label:
		message_label.bbcode_enabled = true
		message_label.text = text
	if got_it_button:
		if LocalizationManager:
			got_it_button.text = LocalizationManager.get_translation("TUTORIAL_GOT_IT", lang)
		else:
			got_it_button.text = "Got it!"
	if skip_all_button:
		if LocalizationManager:
			skip_all_button.text = LocalizationManager.get_translation("TUTORIAL_SKIP_ALL", lang)
		else:
			skip_all_button.text = "Skip all tutorials"
	if highlight_element:
		_highlight_element(highlight_element)
func _fade_in() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	if panel:
		panel.scale = Vector2(0.8, 0.8)
		var scale_tween = create_tween()
		scale_tween.set_ease(Tween.EASE_OUT)
		scale_tween.set_trans(Tween.TRANS_BACK)
		scale_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4)
func _fade_out() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.finished.connect(_on_fade_out_complete)
func _on_fade_out_complete() -> void:
	popup_closed.emit()
	queue_free()
func _highlight_element(element_name: String) -> void:
	pass
func _on_got_it_pressed() -> void:
	_fade_out()
func _on_skip_all_pressed() -> void:
	var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	if tutorial_system:
		tutorial_system.set_tutorial_enabled(false)
	var notification_system = ServiceLocator.get_notification_system() if ServiceLocator else null
	if notification_system:
		var lang: String = _get_current_language()
		var msg: String = ""
		if LocalizationManager:
			msg = LocalizationManager.get_translation("TUTORIAL_ALL_SKIPPED", lang)
		else:
			msg = "All tutorials have been disabled."
		notification_system.show_notification(msg, "info")
	_fade_out()
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_got_it_pressed()
		get_viewport().set_input_as_handled()
func _get_current_language() -> String:
	if GameState:
		var raw: Variant = GameState.get("current_language")
		if raw != null:
			return str(raw).strip_edges().to_lower()
		if GameState.has_method("get_language"):
			return str(GameState.get_language()).strip_edges().to_lower()
	return "en"
