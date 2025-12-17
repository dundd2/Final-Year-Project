extends Control
const MarkdownParser = preload("res://1.Codebase/src/scripts/ui/markdown_parser.gd")
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const ICON_PLAY = preload("res://1.Codebase/src/assets/ui/icon_play.svg")
const ICON_SETTINGS = preload("res://1.Codebase/src/assets/ui/icon_settings.svg")
const ICON_JOURNAL = preload("res://1.Codebase/src/assets/ui/icon_journal.svg")
const ICON_ACHIEVEMENTS = preload("res://1.Codebase/src/assets/ui/icon_achievements.svg")
const ICON_HOME = preload("res://1.Codebase/src/assets/ui/icon_home.svg")
signal resume_requested
signal settings_requested
signal journal_requested
signal achievements_requested
signal characters_requested
signal home_requested
@onready var resume_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsContainer/ResumeButton
@onready var settings_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsContainer/SettingsButton
@onready var journal_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsContainer/JournalButton
@onready var achievements_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsContainer/AchievementsButton
@onready var characters_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsContainer/RelationshipButton
@onready var home_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsContainer/HomeButton
@onready var token_report_label: RichTextLabel = $CenterContainer/Panel/MarginContainer/VBoxContainer/TokenReportPanel/MarginContainer/TokenReportBox/ScrollContainer/TokenReportText
var title_label: Label
var token_header_label: Label
var _audio_manager: Node = null
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_locate_labels()
	_style_buttons()
	_apply_animations()
	_refresh_token_report()
	_update_text()
	if LocalizationManager:
		if not LocalizationManager.language_changed.is_connected(_update_text):
			LocalizationManager.language_changed.connect(_update_text)
	await get_tree().process_frame
	if resume_button and is_instance_valid(resume_button):
		resume_button.grab_focus()
	if resume_button and not resume_button.pressed.is_connected(_on_resume_pressed):
		resume_button.pressed.connect(_on_resume_pressed)
	if settings_button and not settings_button.pressed.is_connected(_on_settings_pressed):
		settings_button.pressed.connect(_on_settings_pressed)
	if journal_button and not journal_button.pressed.is_connected(_on_journal_pressed):
		journal_button.pressed.connect(_on_journal_pressed)
	if achievements_button and not achievements_button.pressed.is_connected(_on_achievements_pressed):
		achievements_button.pressed.connect(_on_achievements_pressed)
	if characters_button and not characters_button.pressed.is_connected(_on_characters_pressed):
		characters_button.pressed.connect(_on_characters_pressed)
	if home_button and not home_button.pressed.is_connected(_on_home_pressed):
		home_button.pressed.connect(_on_home_pressed)
func _exit_tree():
	if LocalizationManager and LocalizationManager.language_changed.is_connected(_update_text):
		LocalizationManager.language_changed.disconnect(_update_text)
func _locate_labels() -> void:
	var vbox = $CenterContainer/Panel/MarginContainer/VBoxContainer
	if vbox:
		if vbox.get_child_count() > 0:
			var first = vbox.get_child(0)
			if first is Label:
				title_label = first
			else:
				title_label = vbox.find_child("TitleLabel", true, false)
				if not title_label:
					for child in vbox.get_children():
						if child is Label:
							title_label = child
							break
	var token_panel = $CenterContainer/Panel/MarginContainer/VBoxContainer/TokenReportPanel
	if token_panel:
		token_header_label = token_panel.find_child("Label", true, false)
		if not token_header_label:
			token_header_label = token_panel.find_child("Title", true, false)
		if not token_header_label:
			token_header_label = token_panel.find_child("Header", true, false)
		if not token_header_label:
			token_header_label = token_panel.find_child("TokenReportTitle", true, false)
func _update_text(lang: String = "") -> void:
	if LocalizationManager == null:
		return
	var get_text = func(key: String) -> String:
		return LocalizationManager.get_translation(key)
	if resume_button:
		resume_button.text = get_text.call("MENU_CONTINUE")
	if settings_button:
		settings_button.text = get_text.call("MENU_SETTINGS")
	if journal_button:
		journal_button.text = get_text.call("MENU_JOURNAL")
	if achievements_button:
		achievements_button.text = get_text.call("MENU_ACHIEVEMENTS")
	if home_button:
		home_button.text = get_text.call("STORY_HOME_BUTTON")
	if characters_button:
		characters_button.text = get_text.call("PAUSE_MENU_CHARACTERS")
	if title_label:
		title_label.text = get_text.call("PAUSE_TITLE")
	if token_header_label:
		token_header_label.text = get_text.call("PAUSE_TOKEN_REPORT_TITLE")
func _on_resume_pressed():
	_play_sfx("menu_click")
	emit_signal("resume_requested")
func _on_settings_pressed():
	_play_sfx("menu_click")
	emit_signal("settings_requested")
func _on_journal_pressed():
	_play_sfx("menu_click")
	emit_signal("journal_requested")
func _on_achievements_pressed():
	_play_sfx("menu_click")
	emit_signal("achievements_requested")
func _on_characters_pressed():
	_play_sfx("menu_click")
	emit_signal("characters_requested")
func _on_home_pressed():
	_play_sfx("menu_click")
	emit_signal("home_requested")
func _refresh_token_report() -> void:
	var ai_manager = ServiceLocator.get_ai_manager() if ServiceLocator else null
	if ai_manager == null:
		if token_report_label:
			token_report_label.text = "[color=#ffaa88]AI manager not loaded.[/color]"
		return
	var last_request_metrics: Dictionary = ai_manager.get_prompt_metrics()
	var session_metrics: Dictionary = ai_manager.get_ai_metrics()
	var token_history: Array = ai_manager.get_token_usage_history()
	var time_history: Array = ai_manager.get_response_time_history()
	if session_metrics.is_empty() and last_request_metrics.is_empty():
		if token_report_label:
			token_report_label.text = "No AI requests have been sent yet this session."
		return
	var report_text := ""
	report_text += "### Session Statistics\n"
	
	var provider_name = "Unknown"
	var model_name = "Unknown"
	var provider_enum = ai_manager.current_provider
	var provider_keys = AIConfigManager.AIProvider.keys()
	if provider_enum >= 0 and provider_enum < provider_keys.size():
		provider_name = provider_keys[provider_enum]
	
	match provider_enum:
		AIConfigManager.AIProvider.GEMINI:
			model_name = ai_manager.gemini_model
		AIConfigManager.AIProvider.OPENROUTER:
			model_name = ai_manager.openrouter_model
		AIConfigManager.AIProvider.OLLAMA:
			model_name = ai_manager.ollama_model
	
	var provider_label = LocalizationManager.get_translation("PAUSE_AI_PROVIDER") if LocalizationManager else "AI Provider"
	var model_label = LocalizationManager.get_translation("PAUSE_AI_MODEL") if LocalizationManager else "Active Model"
	
	report_text += "[b]%s[/b]: %s\n" % [provider_label, provider_name]
	report_text += "[b]%s[/b]: %s\n" % [model_label, model_name]
	
	var total_calls = int(session_metrics.get("total_requests", 0))
	var total_tokens = int(session_metrics.get("total_tokens", 0))
	report_text += "[b]Total API Calls[/b]: %d\n" % total_calls
	report_text += "[b]Total Tokens Consumed[/b]: %d\n" % total_tokens
	if not token_history.is_empty() and token_history.size() > 0:
		var avg_tokens = float(total_tokens) / token_history.size()
		var max_tokens = token_history.max()
		report_text += "[b]Average Tokens/Request[/b]: %.0f\n" % avg_tokens
		report_text += "[b]Max Tokens/Request[/b]: %d\n" % max_tokens
	if not time_history.is_empty() and time_history.size() > 0:
		var total_time = 0.0
		for t in time_history:
			total_time += t
		var avg_time = total_time / time_history.size()
		var max_time = time_history.max()
		report_text += "[b]Average Response Time[/b]: %.2f s\n" % avg_time
		report_text += "[b]Longest Response Time[/b]: %.2f s\n" % max_time
	report_text += "\n" 
	if not last_request_metrics.is_empty():
		report_text += "### Last Request Details\n"
		var lines: Array = []
		var mode = str(last_request_metrics.get("mode", "unknown"))
		lines.append("[b]Mode[/b]: %s" % mode)
		if last_request_metrics.has("provider"):
			var provider = last_request_metrics["provider"]
			if typeof(provider) == TYPE_INT:
				var names = AIManager.AIProvider.keys()
				if provider >= 0 and provider < names.size():
					provider = names[provider]
			lines.append("[b]Provider[/b]: %s" % str(provider))
		var prompt_chars = int(last_request_metrics.get("prompt_chars", 0))
		var response_chars = int(last_request_metrics.get("response_chars", 0))
		var is_estimated = bool(last_request_metrics.get("is_estimated", true))
		var input_tokens = int(last_request_metrics.get("input_tokens", last_request_metrics.get("prompt_tokens_est", 0)))
		var output_tokens = int(last_request_metrics.get("output_tokens", last_request_metrics.get("response_tokens_est", 0)))
		var request_total_tokens = int(last_request_metrics.get("total_tokens", input_tokens + output_tokens))
		var tps = float(last_request_metrics.get("tps", 0.0))
		if is_estimated:
			lines.append("[b]Token Usage (Estimated)[/b]: ~%d total" % request_total_tokens)
			lines.append("  - Input: ~%d | Output: ~%d" % [input_tokens, output_tokens])
		else:
			lines.append("[b]Token Usage (Real)[/b]: %d total" % request_total_tokens)
			lines.append("  - Input: %d | Output: %d" % [input_tokens, output_tokens])
		if tps > 0:
			lines.append("[b]Speed[/b]: %.1f tokens/sec" % tps)
		lines.append("[b]Character Count[/b]: %d in / %d out" % [prompt_chars, response_chars])
		if last_request_metrics.has("response_time_sec"):
			lines.append("[b]Response Time[/b]: %.2f s" % float(last_request_metrics.get("response_time_sec", 0.0)))
		var before_count = int(last_request_metrics.get("memory_entries_before", 0))
		var after_count = int(last_request_metrics.get("memory_entries_after", before_count))
		lines.append("[b]Memory entries[/b]: %d -> %d" % [before_count, after_count])
		lines.append("[b]Full entries kept[/b]: %d" % int(last_request_metrics.get("full_entries_used", 0)))
		lines.append("[b]Summary threshold[/b]: %d" % int(last_request_metrics.get("summary_threshold", 0)))
		lines.append("[b]Memory limit[/b]: %d" % int(last_request_metrics.get("memory_limit", 0)))
		var assets_info = last_request_metrics.get("assets", [])
		if assets_info is Array and assets_info.size() > 0:
			var asset_names: Array = []
			for asset in assets_info:
				asset_names.append(str(asset.get("id", asset.get("default_name", "Asset"))))
			lines.append("[b]Assets[/b]: %s" % ", ".join(asset_names))
		var force_mock = bool(last_request_metrics.get("force_mock_requested", false))
		lines.append("[b]Forced mock[/b]: %s" % ("Yes" if force_mock else "No"))
		if last_request_metrics.has("timestamp"):
			lines.append("[b]Timestamp[/b]: %s" % str(last_request_metrics.get("timestamp")))
		report_text += "\n".join(lines)
		var prompt_preview = str(last_request_metrics.get("prompt_preview", ""))
		if not prompt_preview.is_empty():
			if prompt_preview.length() > 300:
				prompt_preview = prompt_preview.substr(0, 300) + "..."
			report_text += "\n\n[b]Prompt Preview[/b]:\n[code]%s[/code]" % prompt_preview
		var response_preview = str(last_request_metrics.get("response_preview", ""))
		if not response_preview.is_empty():
			if response_preview.length() > 300:
				response_preview = response_preview.substr(0, 300) + "..."
			report_text += "\n\n[b]Response Preview[/b]:\n[code]%s[/code]" % response_preview
	var parsed_report = MarkdownParser.parse_markdown(report_text)
	if token_report_label:
		token_report_label.clear()
		token_report_label.bbcode_enabled = true
		token_report_label.text = parsed_report
func _style_buttons() -> void:
	if resume_button:
		UIStyleManager.apply_button_style(resume_button, "accent", "large")
		resume_button.icon = ICON_PLAY
		resume_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(resume_button, 1.08)
		UIStyleManager.add_press_feedback(resume_button)
	if settings_button:
		UIStyleManager.apply_button_style(settings_button, "primary", "medium")
		settings_button.icon = ICON_SETTINGS
		settings_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(settings_button, 1.05)
		UIStyleManager.add_press_feedback(settings_button)
	if journal_button:
		UIStyleManager.apply_button_style(journal_button, "primary", "medium")
		journal_button.icon = ICON_JOURNAL
		journal_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(journal_button, 1.05)
		UIStyleManager.add_press_feedback(journal_button)
	if achievements_button:
		UIStyleManager.apply_button_style(achievements_button, "primary", "medium")
		achievements_button.icon = ICON_ACHIEVEMENTS
		achievements_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(achievements_button, 1.05)
		UIStyleManager.add_press_feedback(achievements_button)
	if characters_button:
		UIStyleManager.apply_button_style(characters_button, "primary", "medium")
		characters_button.icon = ICON_JOURNAL 
		characters_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(characters_button, 1.05)
		UIStyleManager.add_press_feedback(characters_button)
	if home_button:
		UIStyleManager.apply_button_style(home_button, "warning", "medium")
		home_button.icon = ICON_HOME
		home_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(home_button, 1.05)
		UIStyleManager.add_press_feedback(home_button)
	for button in [resume_button, settings_button, journal_button, home_button, characters_button]:
		if button:
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if achievements_button:
		achievements_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
func _apply_animations() -> void:
	var panel = $CenterContainer/Panel
	if panel:
		UIStyleManager.fade_in(panel, 0.3)
		panel.scale = Vector2(0.95, 0.95)
		var tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(panel, "scale", Vector2.ONE, 0.4)
	var buttons = [resume_button, settings_button, journal_button, home_button]
	if achievements_button:
		buttons.insert(3, achievements_button)
	if characters_button:
		buttons.insert(4, characters_button) 
	for i in range(buttons.size()):
		var button = buttons[i]
		if button:
			button.modulate.a = 0.0
			button.scale = Vector2(0.9, 0.9)
			await get_tree().create_timer(0.05 * i + 0.1).timeout
			UIStyleManager.fade_in(button, 0.2)
			var btn_tween = button.create_tween()
			btn_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			btn_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			btn_tween.tween_property(button, "scale", Vector2.ONE, 0.3)
func _get_audio_manager() -> Node:
	if is_instance_valid(_audio_manager):
		return _audio_manager
	if ServiceLocator:
		_audio_manager = ServiceLocator.get_audio_manager()
	return _audio_manager
func _play_sfx(sfx_name: String) -> void:
	var audio := _get_audio_manager()
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx(sfx_name)
