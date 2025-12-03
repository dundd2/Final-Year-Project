extends Control
signal continue_requested
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
@onready var content_panel: Panel = $ContentPanel
@onready var body_text: RichTextLabel = $ContentPanel/Margin/VBox/BodyText
@onready var continue_button: Button = $ContentPanel/Margin/VBox/ContinueButton
@onready var name_label: Label = $ContentPanel/Margin/VBox/PortraitRow/TitleBox/Name
@onready var subtitle_label: Label = $ContentPanel/Margin/VBox/PortraitRow/TitleBox/Subtitle
@onready var portrait: TextureRect = $ContentPanel/Margin/VBox/PortraitRow/Portrait
@onready var dim_background: ColorRect = $Dim
const CRYING_FACE_PATH = "res://1.Codebase/src/assets/characters/gloria_protagonis_sad.png"
@onready var ai_guilt_text: RichTextLabel = $ContentPanel/Margin/VBox/AIGuiltText
@onready var horror_bg_container: Control = $HorrorBackground
var is_generating_guilt: bool = false
func _ready() -> void:
	visible = false
	scale = Vector2(1.08, 1.08)
	modulate = Color(1, 1, 1, 0)
	continue_button.pressed.connect(_on_continue_pressed)
	_setup_horror_background()
	_apply_styles()
	_apply_localization()
	await get_tree().process_frame
	if body_text.get_parsed_text().is_empty() and (not ai_guilt_text or ai_guilt_text.text.is_empty()):
		_request_ai_guilt_trip()
	visible = true
	_animate_in()
func _setup_horror_background() -> void:
	if not horror_bg_container:
		return
	var face_texture = load(CRYING_FACE_PATH)
	if not face_texture:
		print("Failed to load horror texture: ", CRYING_FACE_PATH)
		return
	var faces_data = []
	var screen_size = get_viewport_rect().size if is_inside_tree() else Vector2(1920, 1080)
	for i in range(100):
		var scale_val = randf_range(0.2, 1.5) 
		faces_data.append({
			"scale": scale_val,
			"pos": Vector2(
				randf_range(0, screen_size.x),
				randf_range(0, screen_size.y)
			),
			"rot": randf_range(-30, 30)
		})
	faces_data.sort_custom(func(a, b): return a["scale"] < b["scale"])
	for data in faces_data:
		var face = TextureRect.new()
		face.texture = face_texture
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var s = data["scale"]
		var base_size = 150.0 
		face.size = Vector2(base_size * s, base_size * s)
		face.position = data["pos"] - (face.size / 2.0) 
		face.rotation_degrees = data["rot"]
		var brightness = remap(s, 0.2, 1.5, 0.2, 0.8)
		var alpha = remap(s, 0.2, 1.5, 0.3, 0.9)
		face.modulate = Color(brightness + 0.2, brightness * 0.5, brightness * 0.5, alpha)
		horror_bg_container.add_child(face)
		var tween = face.create_tween()
		tween.set_loops()
		tween.tween_property(face, "scale", Vector2(1.05, 1.05), randf_range(2.0, 4.0)).as_relative().set_trans(Tween.TRANS_SINE)
		tween.tween_property(face, "scale", Vector2(0.95, 0.95), randf_range(2.0, 4.0)).as_relative().set_trans(Tween.TRANS_SINE)
func set_argument_text(text: String) -> void:
	print("[GloriaIntervention] Received text from controller: ", text)
	var clean_text = _clean_text(text)
	apply_content("", clean_text)
func _clean_text(raw_text: String) -> String:
	var clean = raw_text.strip_edges()
	if "[SCENE_DIRECTIVES]" in clean:
		var parts = clean.split("[/SCENE_DIRECTIVES]")
		if parts.size() > 1:
			clean = parts[parts.size() - 1].strip_edges()
	var choice_markers = ["[Choice Preview]", "[choice preview]", "[CHOICE PREVIEW]", "[Choices]", "[choices]", "[CHOICES]"]
	for marker in choice_markers:
		var marker_pos = clean.find(marker)
		if marker_pos != -1:
			clean = clean.substr(0, marker_pos).strip_edges()
	var choice_prefixes = ["[Cautious]", "[Balanced]", "[Reckless]", "[Positive]", "[Complain]", 
						   "[cautious]", "[balanced]", "[reckless]", "[positive]", "[complain]"]
	for prefix in choice_prefixes:
		var prefix_pos = clean.find(prefix)
		if prefix_pos != -1:
			clean = clean.substr(0, prefix_pos).strip_edges()
	if clean.begins_with("{"):
		var json = JSON.new()
		if json.parse(clean) == OK and json.data is Dictionary:
			var data = json.data
			if data.has("speech"): return _limit_text_length(String(data["speech"]))
			if data.has("text"): return _limit_text_length(String(data["text"]))
			if data.has("content"): return _limit_text_length(String(data["content"]))
			if data.has("message"): return _limit_text_length(String(data["message"]))
			if data.has("gloria_text"): return _limit_text_length(String(data["gloria_text"]))
			if data.has("story_text"): return _limit_text_length(String(data["story_text"]))
		var regex = RegEx.new()
		regex.compile("\"(speech|text|content|message|gloria_text|story_text)\"\\s*:\\s*\"(.*?)\"")
		var result = regex.search(clean)
		if result:
			return _limit_text_length(result.get_string(2))
		return "Gloria glares at you silently... (Data Error)"
	return _limit_text_length(clean)
func _limit_text_length(text: String) -> String:
	const MAX_CHARS = 800  
	if text.length() > MAX_CHARS:
		var truncated = text.substr(0, MAX_CHARS)
		var last_period = truncated.rfind(".")
		var last_exclaim = truncated.rfind("!")
		var last_question = truncated.rfind("?")
		var break_point = max(last_period, max(last_exclaim, last_question))
		if break_point > MAX_CHARS * 0.6:  
			return truncated.substr(0, break_point + 1)
		return truncated + "..."
	return text
func apply_content(base_line: String, argument_text: String) -> void:
	var final_text = _clean_text(argument_text)
	print("[GloriaIntervention] Applying content to UI (length: %d)" % final_text.length())
	body_text.clear()
	body_text.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER) 
	body_text.push_color(Color(1, 0.9, 0.9))
	body_text.push_bold()
	body_text.push_font_size(32) 
	var final_base_line = base_line
	if final_base_line.is_empty():
		var lang: String = GameState.current_language if GameState else "en"
		if lang == "en":
			final_base_line = "You are so negative..."
		else:
			final_base_line = "你這個人太負面了..."
	body_text.add_text(final_base_line)
	body_text.pop() 
	body_text.pop() 
	body_text.pop() 
	if not final_text.is_empty():
		body_text.newline()
		body_text.newline()
		body_text.push_font_size(24) 
		body_text.add_text(final_text)
		body_text.pop() 
	body_text.pop() 
	continue_button.disabled = false
	continue_button.visible = true
	if body_text.get_v_scroll_bar():
		body_text.get_v_scroll_bar().value = 0
func _animate_in() -> void:
	dim_background.modulate.a = 0.0
	var bg_tween := dim_background.create_tween()
	bg_tween.set_ease(Tween.EASE_OUT)
	bg_tween.set_trans(Tween.TRANS_CUBIC)
	bg_tween.tween_property(dim_background, "modulate:a", 1.0, 0.5)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	tween.tween_property(self, "scale", Vector2.ONE, 0.8)
	await get_tree().create_timer(0.3).timeout
	if portrait:
		var shake_tween = portrait.create_tween()
		shake_tween.set_loops(3)
		shake_tween.tween_property(portrait, "rotation", deg_to_rad(5), 0.05)
		shake_tween.tween_property(portrait, "rotation", deg_to_rad(-5), 0.05)
		shake_tween.tween_property(portrait, "rotation", 0.0, 0.05)
		var pulse_tween = portrait.create_tween()
		pulse_tween.set_loops()
		pulse_tween.set_ease(Tween.EASE_IN_OUT)
		pulse_tween.set_trans(Tween.TRANS_SINE)
		pulse_tween.tween_property(portrait, "scale", Vector2(1.2, 1.2), 0.8)
		pulse_tween.tween_property(portrait, "scale", Vector2.ONE, 0.8)
func _on_continue_pressed() -> void:
	continue_button.disabled = true
	continue_requested.emit()
	if AudioManager:
		AudioManager.play_sfx("menu_click", 0.7)
	_animate_out()
func _animate_out() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.3)
	await tween.finished
	queue_free()
func _apply_styles() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.0, 0.05, 0.85)
	panel_style.border_color = Color(0.8, 0.0, 0.0, 0.9) 
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.shadow_size = 50
	panel_style.shadow_color = Color(1.0, 0.0, 0.0, 0.3) 
	content_panel.add_theme_stylebox_override("panel", panel_style)
	content_panel.anchor_left = 0.05
	content_panel.anchor_right = 0.95
	content_panel.anchor_top = 0.05
	content_panel.anchor_bottom = 0.95
	content_panel.offset_left = 0
	content_panel.offset_right = 0
	content_panel.offset_top = 0
	content_panel.offset_bottom = 0
	content_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	content_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	if UIStyleManager:
		UIStyleManager.apply_button_style(continue_button, "danger", "large")
		continue_button.custom_minimum_size = Vector2(300, 80)
		UIStyleManager.add_hover_scale_effect(continue_button, 1.1)
		UIStyleManager.add_press_feedback(continue_button)
	if FontManager:
		FontManager.apply_to_label(name_label, 48)
		FontManager.apply_to_label(subtitle_label, 32)
		FontManager.apply_to_rich_text(body_text, 28)
		FontManager.apply_to_button(continue_button, 32)
	if name_label:
		name_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		name_label.add_theme_color_override("font_shadow_color", Color(0.5, 0.0, 0.0, 1.0))
		name_label.add_theme_constant_override("shadow_offset_x", 4)
		name_label.add_theme_constant_override("shadow_offset_y", 4)
	if subtitle_label:
		subtitle_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.6))
	if body_text:
		body_text.add_theme_color_override("default_color", Color(1.0, 0.9, 0.9))
	if portrait:
		portrait.modulate = Color(1.2, 0.8, 0.8)
		portrait.custom_minimum_size = Vector2(300, 300)
func _request_ai_guilt_trip() -> void:
	if not AIManager:
		return
	is_generating_guilt = true
	var lang = GameState.current_language if GameState else "en"
	var prompt = ""
	if lang == "en":
		prompt = "Generate a short, moral blackmail monologue from Gloria. She is disappointed. Exaggerate the player's minor actions into catastrophic failures involving their family, society, and the world. Use gaslighting tactics. Keep it under 50 words."
	else:
		prompt = "生成一段來自 Gloria 的道德勒索獨白。她非常失望。將玩家微小的行為誇大為牽涉到家人、社會甚至世界的災難性失敗。使用煤氣燈效應（Gaslighting）手段。50字以內。"
	var context = {
		"purpose": "gloria_guilt",
		"language": lang
	}
	AIManager.generate_story(prompt, context, Callable(self, "_on_guilt_generated"))
func _on_guilt_generated(response: Dictionary) -> void:
	is_generating_guilt = false
	if not response.success:
		return
	var content = response.get("content", "")
	if content.strip_edges().is_empty():
		return
	var clean_content = _clean_text(content)
	ai_guilt_text.text = "[i]" + clean_content + "[/i]"
	UIStyleManager.fade_in(ai_guilt_text, 1.0)
func _apply_localization() -> void:
	var lang: String = GameState.current_language if GameState else "en"
	if lang == "en":
		name_label.text = "💔 Saint Gloria is Watching"
		subtitle_label.text = "YOUR NEGATIVITY IS DESTROYING THE WORLD"
		continue_button.text = "I Accept My Guilt"
	else:
		name_label.text = "💔 聖母 Gloria 正在注視"
		subtitle_label.text = "你的負能量正在毀滅世界"
		continue_button.text = "我承認我的罪過"
