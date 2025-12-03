extends Control
signal tutorial_manager_closed
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var progress_bar: ProgressBar = $Panel/VBoxContainer/ProgressContainer/ProgressBar
@onready var progress_label: Label = $Panel/VBoxContainer/ProgressContainer/ProgressLabel
@onready var tutorial_list: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/TutorialList
@onready var close_button: Button = $Panel/VBoxContainer/ButtonContainer/CloseButton
@onready var reset_button: Button = $Panel/VBoxContainer/ButtonContainer/ResetButton
const TUTORIAL_ITEM_SCENE: String = "res://1.Codebase/src/scenes/ui/tutorial_item.tscn"
var tutorial_system: Node = null
func _ready() -> void:
	tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	_load_tutorials()
	_update_localization()
func _update_localization() -> void:
	var lang: String = _get_current_language()
	if title_label:
		if LocalizationManager:
			title_label.text = LocalizationManager.get_translation("TUTORIAL_MANAGER_TITLE", lang)
		else:
			title_label.text = "📚 Tutorial Manager"
	if close_button:
		if LocalizationManager:
			close_button.text = LocalizationManager.get_translation("TUTORIAL_CLOSE", lang)
		else:
			close_button.text = "Close"
	if reset_button:
		if LocalizationManager:
			reset_button.text = LocalizationManager.get_translation("TUTORIAL_RESET_ALL", lang)
		else:
			reset_button.text = "Reset All"
func _load_tutorials() -> void:
	if not tutorial_system:
		return
	for child in tutorial_list.get_children():
		child.queue_free()
	var all_steps: Array = tutorial_system.get_all_tutorial_steps()
	var completed_tutorials: Array = tutorial_system.get_completed_tutorials()
	var completion_percentage: float = tutorial_system.get_tutorial_progress()
	if progress_bar:
		progress_bar.value = completion_percentage
	if progress_label:
		progress_label.text = "%d%%" % int(completion_percentage)
	for i in range(all_steps.size()):
		var step: Dictionary = all_steps[i]
		var step_id: String = step.get("id", "")
		var is_completed: bool = step_id in completed_tutorials
		_create_tutorial_item(step, i + 1, is_completed)
func _create_tutorial_item(step: Dictionary, step_number: int, is_completed: bool) -> void:
	var step_id: String = step.get("id", "")
	var lang: String = _get_current_language()
	var item_container: HBoxContainer = HBoxContainer.new()
	item_container.custom_minimum_size = Vector2(0, 50)
	var number_label: Label = Label.new()
	number_label.text = "%d." % step_number
	number_label.custom_minimum_size = Vector2(40, 0)
	number_label.add_theme_font_size_override("font_size", 16)
	item_container.add_child(number_label)
	var name_label: Label = Label.new()
	var tutorial_text: String = ""
	if LocalizationManager:
		tutorial_text = LocalizationManager.get_translation("TUTORIAL_" + step_id, lang)
	if tutorial_text.is_empty():
		tutorial_text = step_id.replace("_", " ").capitalize()
	if tutorial_text.length() > 50:
		tutorial_text = tutorial_text.substr(0, 47) + "..."
	name_label.text = tutorial_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 14)
	item_container.add_child(name_label)
	var status_label: Label = Label.new()
	status_label.text = "✓" if is_completed else "○"
	status_label.custom_minimum_size = Vector2(30, 0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 20)
	if is_completed:
		status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	item_container.add_child(status_label)
	var replay_button: Button = Button.new()
	if LocalizationManager:
		replay_button.text = LocalizationManager.get_translation("TUTORIAL_REPLAY", lang)
	else:
		replay_button.text = "Replay"
	replay_button.custom_minimum_size = Vector2(100, 0)
	replay_button.pressed.connect(_on_replay_tutorial.bind(step_id))
	item_container.add_child(replay_button)
	tutorial_list.add_child(item_container)
func _on_replay_tutorial(step_id: String) -> void:
	if tutorial_system and tutorial_system.has_method("trigger_tutorial"):
		tutorial_system.trigger_tutorial(step_id)
func _on_close_pressed() -> void:
	tutorial_manager_closed.emit()
	queue_free()
func _on_reset_pressed() -> void:
	if tutorial_system and tutorial_system.has_method("reset_tutorials"):
		var lang: String = _get_current_language()
		var confirmation_text: String = ""
		if LocalizationManager:
			confirmation_text = LocalizationManager.get_translation("TUTORIAL_RESET_CONFIRM", lang)
		else:
			confirmation_text = "Are you sure you want to reset all tutorial progress?"
		tutorial_system.reset_tutorials()
		var notification_system = ServiceLocator.get_notification_system() if ServiceLocator else null
		if notification_system:
			var msg: String = ""
			if LocalizationManager:
				msg = LocalizationManager.get_translation("TUTORIAL_RESET_SUCCESS", lang)
			else:
				msg = "Tutorial progress has been reset."
			notification_system.show_notification(msg, "info")
		_load_tutorials()
func _get_current_language() -> String:
	if GameState:
		var raw: Variant = GameState.get("current_language")
		if raw != null:
			return str(raw).strip_edges().to_lower()
		if GameState.has_method("get_language"):
			return str(GameState.get_language()).strip_edges().to_lower()
	return "en"
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
