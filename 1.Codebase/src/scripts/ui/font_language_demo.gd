extends Control
const ERROR_CONTEXT := "FontLanguageDemo"
var current_language: String = "en"
var _game_state: Node = null
var _font_manager: Node = null
var _ai_manager: Node = null
func _ready():
	_resolve_services()
	_load_language_from_state()
	_apply_font_sizes()
	update_ui_text()
	_connect_font_signal()
	_connect_buttons()
func _exit_tree() -> void:
	_disconnect_font_signal()
func _resolve_services() -> void:
	if not ServiceLocator:
		_report_warning("ServiceLocator unavailable; using defaults")
		return
	_game_state = ServiceLocator.get_game_state()
	_font_manager = ServiceLocator.get_font_manager()
	_ai_manager = ServiceLocator.get_ai_manager()
func _load_language_from_state() -> void:
	current_language = _game_state.current_language if _game_state else "en"
func _connect_font_signal() -> void:
	if not is_instance_valid(_font_manager):
		return
	var font_signal: Signal = _font_manager.font_size_changed
	if not font_signal.is_connected(_on_font_size_changed):
		font_signal.connect(_on_font_size_changed)
func _disconnect_font_signal() -> void:
	if not is_instance_valid(_font_manager):
		return
	var font_signal: Signal = _font_manager.font_size_changed
	if font_signal.is_connected(_on_font_size_changed):
		font_signal.disconnect(_on_font_size_changed)
func _connect_buttons() -> void:
	$Panel/VBox/LanguageButton.pressed.connect(_toggle_language)
	$Panel/VBox/FontSizeButton.pressed.connect(_cycle_font_size)
	$Panel/VBox/TestAIButton.pressed.connect(_test_ai_output)
func _apply_font_sizes():
	if not is_instance_valid(_font_manager):
		_report_warning("FontManager not available; skipping font setup")
		return
	_font_manager.apply_to_label($Panel/VBox/TitleLabel, 36)
	_font_manager.apply_to_label($Panel/VBox/DescriptionLabel, 18)
	_font_manager.apply_to_button($Panel/VBox/LanguageButton, 20)
	_font_manager.apply_to_button($Panel/VBox/FontSizeButton, 20)
	_font_manager.apply_to_button($Panel/VBox/TestAIButton, 20)
	_font_manager.apply_to_label($Panel/VBox/StatusLabel, 16)
func _on_font_size_changed(multiplier: float):
	print("Font size changed to: ", multiplier, "x")
	_apply_font_sizes()
func update_ui_text():
	if current_language == "en":
		$Panel/VBox/TitleLabel.text = "Font & Language Demo"
		$Panel/VBox/DescriptionLabel.text = "This demo shows dynamic font sizing and language switching."
		$Panel/VBox/LanguageButton.text = "Switch to Chinese (切換到中文)"
		$Panel/VBox/FontSizeButton.text = "Change Font Size"
		$Panel/VBox/TestAIButton.text = "Test AI Language"
		_update_status_en()
	else:
		$Panel/VBox/TitleLabel.text = "字體與語言示範"
		$Panel/VBox/DescriptionLabel.text = "此示範展示動態字體縮放與語言切換功能。"
		$Panel/VBox/LanguageButton.text = "Switch to English"
		$Panel/VBox/FontSizeButton.text = "更改字體大小"
		$Panel/VBox/TestAIButton.text = "測試 AI 語言"
		_update_status_zh()
func _update_status_en():
	var font_name = _font_manager.get_font_size_name() if _font_manager else "Normal"
	var multiplier = _font_manager.get_multiplier() if _font_manager else 1.0
	$Panel/VBox/StatusLabel.text = "Current: %s (%.0f%%) | Language: English" % [font_name, multiplier * 100]
func _update_status_zh():
	var font_name = _get_font_name_zh()
	var multiplier = _font_manager.get_multiplier() if _font_manager else 1.0
	$Panel/VBox/StatusLabel.text = "當前：%s (%.0f%%) | 語言：中文" % [font_name, multiplier * 100]
func _get_font_name_zh() -> String:
	if not _font_manager:
		return "標準"
	match _font_manager.get_font_size():
		0:
			return "極小"
		1:
			return "小"
		2:
			return "標準"
		3:
			return "大"
		4:
			return "極大"
		_:
			return "未知"
func _toggle_language():
	current_language = "en" if current_language == "zh" else "zh"
	if _game_state:
		_game_state.current_language = current_language
	update_ui_text()
	print("Language changed to: ", current_language)
func _cycle_font_size():
	if not is_instance_valid(_font_manager):
		_report_warning("FontManager not available; cannot change font size")
		return
	var current = _font_manager.get_font_size()
	var next_size = (current + 1) % 5 
	_font_manager.set_font_size(next_size)
	update_ui_text()
func _test_ai_output():
	if not is_instance_valid(_ai_manager):
		_report_warning("AIManager not available; cannot generate test output")
		$Panel/VBox/StatusLabel.text = "AI unavailable" if current_language == "en" else "AI 無法使用"
		return
	$Panel/VBox/StatusLabel.text = "Generating AI response..." if current_language == "en" else "正在生成 AI 回應..."
	var prompt = "Describe a beautiful sunset in 2 sentences." if current_language == "en" else "用兩句話描述美麗的日落。"
	_ai_manager.generate_story(
		prompt,
		{ },
		func(response):
			if response.success:
				var result = "AI Response: %s" % response.content if current_language == "en" else "AI 回應：%s" % response.content
				print(result)
				$Panel/VBox/StatusLabel.text = "AI response received (check console)" if current_language == "en" else "已收到 AI 回應（查看控制台）"
			else:
				$Panel/VBox/StatusLabel.text = "AI error: %s" % response.error if current_language == "en" else "AI 錯誤：%s" % response.error
	)
func _report_warning(message: String) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message)
