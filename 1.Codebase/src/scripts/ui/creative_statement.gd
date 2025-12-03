extends Control
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
var current_language: String = "en"
@onready var close_button: Button = $MenuContainer/Panel/VBoxContainer/CloseButton
@onready var statement_label: RichTextLabel = $MenuContainer/Panel/VBoxContainer/StatementLabel
@onready var title_label: Label = $MenuContainer/Panel/VBoxContainer/TitleLabel
@onready var panel: Panel = $MenuContainer/Panel
var _audio_manager: Node = null
func _ready():
	var game_state = ServiceLocator.get_game_state() if ServiceLocator else null
	current_language = game_state.current_language if game_state else "en"
	_apply_styles()
	_update_text()
	if panel:
		UIStyleManager.fade_in(panel, 0.4)
func _apply_styles():
	if panel:
		UIStyleManager.apply_panel_style(panel, 0.96, UIStyleManager.CORNER_RADIUS_LARGE)
	if close_button:
		UIStyleManager.apply_button_style(close_button, "accent", "large")
		UIStyleManager.add_hover_scale_effect(close_button, 1.06)
		UIStyleManager.add_press_feedback(close_button)
		close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if title_label:
		title_label.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	if statement_label:
		statement_label.bbcode_enabled = true
func _update_text():
	if current_language == "zh":
		title_label.text = "創作聲明"
		statement_label.text = "[b]創作聲明[/b]\n\n本遊戲中的所有角色、事件與宗教隱喻皆為虛構，僅用於諷刺與戲仿之目的，無意影射任何真實人物、團體或信仰。"
		close_button.text = "返回主選單"
	else:
		title_label.text = "Creative Statement"
		statement_label.text = "[b]Creative Statement[/b]\n\nAll characters, events, and religious metaphors in this game are purely fictional and intended for satirical purposes. There is no intention to allude to any real-life individuals, groups, or beliefs."
		close_button.text = "Back to Menu"
func _on_close_pressed():
	var audio := _get_audio_manager()
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx("menu_click")
	queue_free()
func _get_audio_manager() -> Node:
	if is_instance_valid(_audio_manager):
		return _audio_manager
	if ServiceLocator:
		_audio_manager = ServiceLocator.get_audio_manager()
	return _audio_manager
