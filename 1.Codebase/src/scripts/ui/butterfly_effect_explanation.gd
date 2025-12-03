extends Control
signal close_requested
func _ready() -> void:
	z_index = 200
	var close_btn = $Root/ContentPanel/Margin/VBox/Header/CloseButton
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
func setup() -> void:
	var title_label = $Root/ContentPanel/Margin/VBox/Header/Title
	var body_label = $Root/ContentPanel/Margin/VBox/BodyText
	if title_label:
		title_label.text = LocalizationManager.get_translation("BUTTERFLY_EXPLAIN_TITLE")
	if body_label:
		body_label.text = LocalizationManager.get_translation("BUTTERFLY_EXPLAIN_BODY")
func _on_close_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click_back")
	close_requested.emit()
	queue_free()
