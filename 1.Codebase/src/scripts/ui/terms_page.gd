extends Control
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
var current_language: String = "en"
var _audio_manager: Node = null
func _ready():
	current_language = GameState.current_language if GameState else "en"
	_apply_modern_styling()
	update_ui_text()
	var panel = $MenuContainer/Panel
	if panel:
		UIStyleManager.fade_in(panel, 0.4)
func _apply_modern_styling():
	var panel = $MenuContainer/Panel
	if panel:
		UIStyleManager.apply_panel_style(panel, 0.95, UIStyleManager.CORNER_RADIUS_LARGE)
	var close_button = $MenuContainer/Panel/VBoxContainer/CloseButton
	if close_button:
		UIStyleManager.apply_button_style(close_button, "accent", "large")
		UIStyleManager.add_hover_scale_effect(close_button, 1.06)
		UIStyleManager.add_press_feedback(close_button)
		close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var title_label = $MenuContainer/Panel/VBoxContainer/TitleLabel
	if title_label:
		title_label.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
func _on_close_pressed():
	var audio := _get_audio_manager()
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx("menu_click")
	var parent = get_parent()
	if parent and (parent.name == "StartMenu" or parent.get_script() and parent.get_script().get_path().contains("start_menu")):
		queue_free()
	else:
		get_tree().change_scene_to_file("res://1.Codebase/src/scenes/ui/start_menu.tscn")
func _get_audio_manager() -> Node:
	if is_instance_valid(_audio_manager):
		return _audio_manager
	if ServiceLocator:
		_audio_manager = ServiceLocator.get_audio_manager()
	return _audio_manager
func update_ui_text():
	if current_language == "en":
		$MenuContainer/Panel/VBoxContainer/TitleLabel.text = "TERMS & CONDITIONS"
		$MenuContainer/Panel/VBoxContainer/ScrollContainer/BodyLabel.text = "AI-Generated Content Disclaimer

This game uses AI (Artificial Intelligence) to generate dynamic story content, dialogue, and scenarios. By playing this game, you acknowledge and agree to the following:

1. AI Content Generation
   - Story elements, dialogue, and events may be generated in real-time by AI
   - AI-generated content may vary each playthrough
   - Content quality and coherence may vary

2. Content Unpredictability
   - AI may produce unexpected or unusual responses
   - The game's satirical and dark humor nature means content may be provocative
   - Players should be prepared for absurd or unconventional scenarios

3. API Usage & Privacy
   - The game may send prompts to AI services (Google Gemini, OpenRouter, Ollama Local Runtime)
   - Game context and player choices may be transmitted to these services
   - No personal information is collected or transmitted
   - AI providers may have their own terms of service and privacy policies

4. Mock Mode
   - The game can operate in \"mock mode\" without external AI services
   - Mock mode generates predetermined responses locally

5. Parental Guidance
   - This game contains satirical content and dark humor
   - Suitable for mature audiences who understand satire

6. No Warranty
   - AI-generated content is provided \"as is\"
   - The developers are not responsible for AI-generated content
   - Use at your own discretion

By clicking \"Accept\" or continuing to play, you acknowledge that you have read, understood, and agree to these terms."
		$MenuContainer/Panel/VBoxContainer/CloseButton.text = "ACCEPT & CONTINUE"
	else:
		$MenuContainer/Panel/VBoxContainer/TitleLabel.text = "條款與細則"
		$MenuContainer/Panel/VBoxContainer/ScrollContainer/BodyLabel.text = "AI 生成內容免責聲明

本遊戲使用人工智慧（AI）生成動態故事內容、對話和場景。通過遊玩此遊戲，您確認並同意以下條款：

1. AI 內容生成
   - 故事元素、對話和事件可能由 AI 實時生成
   - AI 生成的內容每次遊玩可能不同
   - 內容質量和連貫性可能有所差異

2. 內容不可預測性
   - AI 可能產生意外或不尋常的回應
   - 遊戲的諷刺和黑色幽默性質意味著內容可能具有挑戰性
   - 玩家應準備好面對荒謬或非傳統的場景

3. API 使用與隱私
   - 遊戲可能向外部 AI 服務（Google Gemini、OpenRouter）發送提示
   - 遊戲上下文和玩家選擇可能被傳輸到這些服務
   - 不會收集或傳輸個人信息
   - AI 提供商可能有自己的服務條款和隱私政策

4. 模擬模式
   - 遊戲可以在「模擬模式」下運行，無需外部 AI 服務
   - 模擬模式在本地生成預定的回應

5. 家長指引
   - 本遊戲包含諷刺內容和黑色幽默
   - 適合理解諷刺的成熟觀眾

6. 免責聲明
   - AI 生成的內容按「現狀」提供
   - 開發者不對 AI 生成的內容負責
   - 使用需自行判斷

點擊「接受」或繼續遊玩，即表示您已閱讀、理解並同意這些條款。"
		$MenuContainer/Panel/VBoxContainer/CloseButton.text = "接受並繼續"
