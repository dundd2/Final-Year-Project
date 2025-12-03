extends Control
signal accepted
signal cancelled
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
var current_language: String = "en"
@onready var panel: Panel = $MenuContainer/Panel
@onready var title_label: Label = $MenuContainer/Panel/VBoxContainer/TitleLabel
@onready var body_text: RichTextLabel = $MenuContainer/Panel/VBoxContainer/BodyText
@onready var cancel_button: Button = $MenuContainer/Panel/VBoxContainer/Buttons/CancelButton
@onready var accept_button: Button = $MenuContainer/Panel/VBoxContainer/Buttons/AcceptButton
func _ready() -> void:
	current_language = GameState.current_language if GameState else "en"
	_apply_styles()
	_update_text()
	if panel:
		panel.modulate.a = 0.0
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(panel, "modulate:a", 1.0, 0.25)
func _apply_styles() -> void:
	if panel:
		UIStyleManager.apply_panel_style(panel, 0.96, UIStyleManager.CORNER_RADIUS_LARGE)
	if accept_button:
		UIStyleManager.apply_button_style(accept_button, "accent", "large")
		UIStyleManager.add_hover_scale_effect(accept_button, 1.05)
		UIStyleManager.add_press_feedback(accept_button)
		accept_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if cancel_button:
		UIStyleManager.apply_button_style(cancel_button, "secondary", "large")
		UIStyleManager.add_hover_scale_effect(cancel_button, 1.05)
		UIStyleManager.add_press_feedback(cancel_button)
		cancel_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if title_label:
		title_label.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	if body_text:
		body_text.bbcode_enabled = true
		body_text.add_theme_color_override("default_color", Color(0.88, 0.9, 1.0))
func _update_text() -> void:
	if current_language == "zh":
		title_label.text = "資料使用告知"
		body_text.text = "[b]開始祈禱前請先了解：[/b]\n\n• 若選擇雲端模型，您輸入的文字將會傳送至第三方 AI 服務。\n• 完整請求內容也會儲存在本機記錄，用於除錯與體驗評估。\n• 請勿輸入任何個人資料、敏感資訊或可識別的內容。\n\n您可隨時在「設定」選單中刪除本機記錄。"
		cancel_button.text = "取消"
		accept_button.text = "我了解"
	else:
		title_label.text = "Data Use Notice"
		body_text.text = "[b]Before you submit a prayer[/b]\n\n• Your text may be sent to a third-party AI service when a cloud model is enabled.\n• The full request is also stored in local logs for debugging and evaluation.\n• Please avoid entering personal, sensitive, or identifying information.\n\nYou can delete stored logs anytime from the Settings menu."
		cancel_button.text = "Cancel"
		accept_button.text = "I Understand"
func _on_cancel_button_pressed() -> void:
	cancelled.emit()
	queue_free()
func _on_accept_button_pressed() -> void:
	accepted.emit()
	queue_free()
