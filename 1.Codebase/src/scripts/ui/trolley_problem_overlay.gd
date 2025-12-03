extends Control
signal choice_selected(choice_id: String)
const ERROR_CONTEXT := "TrolleyProblemOverlay"
@onready var scenario_label: RichTextLabel = $Root/ContentPanel/Margin/VBox/ScenarioText
@onready var choices_container: VBoxContainer = $Root/ContentPanel/Margin/VBox/ChoicesContainer
@onready var title_label: Label = $Root/ContentPanel/Margin/VBox/Header/Title
var dilemma_data: Dictionary = {}
func _ready() -> void:
	z_index = 200
	mouse_filter = Control.MOUSE_FILTER_STOP
	if AudioManager:
		AudioManager.play_sfx("heartbeat", 0.5)
func setup(data: Dictionary) -> void:
	dilemma_data = data
	if title_label:
		var lang = GameState.current_language if GameState else "en"
		title_label.text = "MORAL DILEMMA" if lang == "en" else "道德困境"
	if scenario_label:
		var scenario = data.get("scenario", "")
		scenario_label.text = "[center]%s[/center]" % scenario
	_create_choice_buttons(data.get("choices", []))
func _create_choice_buttons(choices: Array) -> void:
	if not choices_container:
		return
	for child in choices_container.get_children():
		child.queue_free()
	for choice in choices:
		var btn = Button.new()
		btn.text = choice.get("text", "Unknown Choice")
		btn.custom_minimum_size = Vector2(0, 80)
		btn.add_theme_font_size_override("font_size", 18)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_choice_pressed.bind(choice.get("id", "")))
		choices_container.add_child(btn)
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		choices_container.add_child(spacer)
func _on_choice_pressed(choice_id: String) -> void:
	if choice_id.is_empty():
		return
	if AudioManager:
		AudioManager.play_sfx("ui_click_heavy")
	choice_selected.emit(choice_id)
	for child in choices_container.get_children():
		if child is Button:
			child.disabled = true
