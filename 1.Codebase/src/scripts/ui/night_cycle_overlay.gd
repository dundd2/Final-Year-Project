extends Control
signal prayer_requested
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
var _main_container: MarginContainer
var _content_vbox: VBoxContainer
var _reflection_panel: PanelContainer
var _reflection_label: RichTextLabel
var _concert_panel: PanelContainer
var _concert_content_vbox: VBoxContainer
var _concert_text_label: RichTextLabel
var _concert_song_label: Label
var _concert_portrait: TextureRect
var _concert_lyrics_container: VBoxContainer
var _concert_video_placeholder: PanelContainer
var _honeymoon_panel: PanelContainer
var _honeymoon_label: RichTextLabel
var _title_label: Label
var _pray_button: Button
var _skip_button: Button
var current_language: String = "en"
var current_lyrics: Array = []
var lyrics_animation_time: float = 0.0
var lyrics_line_index: int = 0
const LYRICS_LINE_DURATION: float = 1.0
var _content_received: bool = false
var _content_failsafe_timer: Timer
var _audio_manager: Node = null
func _ready() -> void:
	print("[NightCycle] Initializing complete layout reset...")
	for child in get_children():
		child.queue_free()
	var game_state = ServiceLocator.get_game_state() if ServiceLocator else null
	current_language = game_state.current_language if game_state else "en"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 100
	_build_ui_structure()
	_start_failsafe_timer()
	if get_parent() == get_tree().root:
		print("[NightCycle] Standalone mode detected.")
		get_tree().create_timer(0.5).timeout.connect(_on_content_failsafe_timeout)
	modulate.a = 0.0
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
func _process(delta: float) -> void:
	if current_lyrics.size() > 0:
		if lyrics_line_index < current_lyrics.size():
			lyrics_animation_time += delta
			if lyrics_animation_time >= LYRICS_LINE_DURATION:
				lyrics_animation_time = 0.0
				lyrics_line_index += 1
				_update_lyrics_display()
		if lyrics_line_index >= current_lyrics.size() and _pray_button and not _pray_button.visible:
			_finish_concert()
func _exit_tree() -> void:
	if _content_failsafe_timer:
		_content_failsafe_timer.queue_free()
func _build_ui_structure() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 1.0) 
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_create_love_particles()
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)
	_main_container = MarginContainer.new()
	_main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_main_container.add_theme_constant_override("margin_left", 40)
	_main_container.add_theme_constant_override("margin_right", 40)
	_main_container.add_theme_constant_override("margin_top", 40)
	_main_container.add_theme_constant_override("margin_bottom", 40)
	scroll.add_child(_main_container)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 30)
	_main_container.add_child(vbox)
	var header_vbox = VBoxContainer.new()
	header_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(header_vbox)
	_title_label = Label.new()
	_title_label.text = _tr("NIGHT_TITLE") 
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	header_vbox.add_child(_title_label)
	var separator = HSeparator.new()
	separator.modulate = Color(1, 1, 1, 0.3)
	vbox.add_child(separator)
	_content_vbox = VBoxContainer.new()
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_vbox.add_theme_constant_override("separation", 25)
	vbox.add_child(_content_vbox)
	_reflection_panel = _create_content_panel("Reflection")
	_content_vbox.add_child(_reflection_panel)
	var ref_margin = _reflection_panel.get_child(0) as MarginContainer
	var ref_vbox = ref_margin.get_child(0) as VBoxContainer
	_reflection_label = _create_rich_text_label()
	ref_vbox.add_child(_reflection_label)
	_concert_panel = _create_content_panel("Teacher Chan's Liturgy", true) 
	_content_vbox.add_child(_concert_panel)
	var con_margin = _concert_panel.get_child(0) as MarginContainer
	var con_root_vbox = con_margin.get_child(0) as VBoxContainer
	var con_hsplit = HBoxContainer.new()
	con_hsplit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	con_hsplit.add_theme_constant_override("separation", 20)
	con_root_vbox.add_child(con_hsplit)
	_concert_portrait = TextureRect.new()
	_concert_portrait.custom_minimum_size = Vector2(150, 150)
	_concert_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_concert_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_concert_portrait.texture = load("res://1.Codebase/src/assets/characters/teacher_chan_happy.png")
	con_hsplit.add_child(_concert_portrait)
	var con_text_vbox = VBoxContainer.new()
	con_text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	con_hsplit.add_child(con_text_vbox)
	_concert_song_label = Label.new()
	_concert_song_label.text = "♫ Song Title ♫"
	_concert_song_label.add_theme_font_size_override("font_size", 22)
	_concert_song_label.add_theme_color_override("font_color", Color(1, 1, 0.4)) 
	_concert_song_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_concert_song_label.add_theme_constant_override("outline_size", 4)
	con_text_vbox.add_child(_concert_song_label)
	_concert_text_label = _create_rich_text_label()
	_concert_text_label.add_theme_color_override("default_color", Color(1, 0.9, 1.0)) 
	con_text_vbox.add_child(_concert_text_label)
	var lyrics_container_box = VBoxContainer.new()
	con_root_vbox.add_child(lyrics_container_box)
	_concert_video_placeholder = PanelContainer.new()
	_concert_video_placeholder.custom_minimum_size = Vector2(0, 180)
	var vid_style = StyleBoxFlat.new()
	vid_style.bg_color = Color(0.1, 0.0, 0.2, 0.9) 
	vid_style.border_width_top = 2
	vid_style.border_width_bottom = 2
	vid_style.border_color = Color(0.8, 0.2, 0.8) 
	_concert_video_placeholder.add_theme_stylebox_override("panel", vid_style)
	lyrics_container_box.add_child(_concert_video_placeholder)
	var vid_center = CenterContainer.new()
	_concert_video_placeholder.add_child(vid_center)
	_concert_lyrics_container = VBoxContainer.new()
	_concert_lyrics_container.custom_minimum_size = Vector2(400, 0)
	vid_center.add_child(_concert_lyrics_container)
	_honeymoon_panel = _create_content_panel("Honeymoon Mirage")
	_content_vbox.add_child(_honeymoon_panel)
	var honey_margin = _honeymoon_panel.get_child(0) as MarginContainer
	var honey_vbox = honey_margin.get_child(0) as VBoxContainer
	_honeymoon_label = _create_rich_text_label()
	honey_vbox.add_child(_honeymoon_label)
	vbox.add_child(HSeparator.new())
	var footer_center = CenterContainer.new()
	footer_center.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(footer_center)
	_pray_button = Button.new()
	_pray_button.text = _tr("NIGHT_BUTTON_PRAY") 
	_pray_button.custom_minimum_size = Vector2(200, 60)
	_pray_button.visible = false 
	_pray_button.pressed.connect(_on_pray_button_pressed)
	if UIStyleManager:
		UIStyleManager.apply_button_style(_pray_button, "accent", "large")
	footer_center.add_child(_pray_button)
	_skip_button = Button.new()
	_skip_button.text = "Skip >>"
	add_child(_skip_button)
	_skip_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_skip_button.position = Vector2(-120, 20) 
	_skip_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_skip_button.anchor_left = 1.0
	_skip_button.anchor_right = 1.0
	_skip_button.offset_left = -100
	_skip_button.offset_right = -20
	_skip_button.offset_top = 20
	_skip_button.offset_bottom = 60
	_skip_button.pressed.connect(_on_skip_button_pressed)
	_skip_button.visible = false
func _create_content_panel(title_text: String, is_concert: bool = false) -> PanelContainer:
	var pc = PanelContainer.new()
	var style = StyleBoxFlat.new()
	if is_concert:
		style.bg_color = Color(0.3, 0.05, 0.2, 0.95)
		style.border_width_left = 4
		style.border_width_right = 4
		style.border_width_top = 4
		style.border_width_bottom = 4
		style.border_color = Color(1.0, 0.4, 0.8) 
		style.border_blend = true
		pc.name = "ConcertPanel"
	else:
		style.bg_color = Color(0.15, 0.15, 0.20, 0.95)
		style.border_width_left = 4
		style.border_color = Color(0.4, 0.5, 0.8)
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_top_left = 10
	style.corner_radius_bottom_left = 10
	pc.add_theme_stylebox_override("panel", style)
	var mc = MarginContainer.new()
	pc.add_child(mc)
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	mc.add_child(vb)
	var lbl = Label.new()
	lbl.text = _tr(title_text) if title_text.begins_with("NIGHT_") else title_text
	lbl.add_theme_font_size_override("font_size", 18)
	if is_concert:
		lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.8)) 
	else:
		lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	lbl.uppercase = true
	vb.add_child(lbl)
	return pc
func _create_rich_text_label() -> RichTextLabel:
	var rtl = RichTextLabel.new()
	rtl.fit_content = true
	rtl.bbcode_enabled = true
	rtl.scroll_active = false
	rtl.autowrap_mode = TextServer.AUTOWRAP_WORD
	rtl.add_theme_font_size_override("normal_font_size", 16)
	rtl.add_theme_color_override("default_color", Color(0.9, 0.9, 0.9))
	return rtl
func set_content(payload: Dictionary) -> void:
	print("[NightCycle] Setting content: %s" % str(payload).substr(0, 100))
	if _content_received: return
	_content_received = true
	if _content_failsafe_timer: _content_failsafe_timer.stop()
	var reflection = String(payload.get("reflection_text", ""))
	var concert = String(payload.get("teacher_chan_text", ""))
	var honeymoon = String(payload.get("honeymoon_text", ""))
	var prompt = String(payload.get("prayer_prompt", ""))
	var song_title = String(payload.get("song_title", ""))
	var lyrics: Array = []
	if payload.has("concert_lyrics"):
		var l = payload.get("concert_lyrics")
		if l is Array: lyrics = l
	if lyrics.is_empty() and AIManager and not _should_use_preset_lyrics():
		_request_ai_lyrics(reflection, concert, song_title, honeymoon, prompt)
		return
	apply_content_with_lyrics(reflection, concert, lyrics, song_title, honeymoon, prompt)
func apply_content_with_lyrics(reflection: String, concert: String, lyrics: Array, song_title: String, honeymoon: String, prompt: String, is_fallback: bool = false) -> void:
	var clean_reflection = _filter_choice_previews(reflection)
	if clean_reflection.strip_edges().is_empty():
		_reflection_panel.visible = false
	else:
		_reflection_panel.visible = true
		_reflection_label.text = clean_reflection
	if honeymoon.strip_edges().is_empty():
		_honeymoon_panel.visible = false
	else:
		_honeymoon_panel.visible = true
		_honeymoon_label.text = honeymoon
	var has_concert = not concert.strip_edges().is_empty()
	_concert_panel.visible = has_concert
	if has_concert:
		_concert_text_label.text = concert
		_concert_song_label.text = song_title if not song_title.is_empty() else _tr("NIGHT_SONG_DEFAULT")
		_animate_concert_joyful()
		var final_lyrics = lyrics
		if final_lyrics.size() < 2:
			final_lyrics = _get_preset_lyrics()
		current_lyrics = final_lyrics
		lyrics_line_index = 0
		lyrics_animation_time = 0.0
		if final_lyrics.size() > 0:
			_skip_button.visible = true
			_setup_lyrics_animation()
		else:
			_finish_concert()
	else:
		_finish_concert()
	if prompt.strip_edges().is_empty():
		_pray_button.text = _tr("NIGHT_BUTTON_PRAY")
	else:
		pass
func _animate_concert_joyful() -> void:
	if not _concert_panel: return
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_loops()
	tween.tween_property(_concert_panel, "modulate", Color(1.0, 0.9, 1.0), 1.0) 
	tween.tween_property(_concert_panel, "modulate", Color(1.0, 1.0, 1.0), 1.0)
	var s_tween = create_tween()
	s_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	s_tween.set_loops()
	s_tween.tween_property(_concert_panel, "scale", Vector2(1.01, 1.01), 2.0).set_trans(Tween.TRANS_SINE)
	s_tween.tween_property(_concert_panel, "scale", Vector2(1.0, 1.0), 2.0).set_trans(Tween.TRANS_SINE)
	if _concert_portrait:
		var p_tween = create_tween()
		p_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		p_tween.set_loops()
		p_tween.tween_property(_concert_portrait, "rotation_degrees", 5.0, 0.5).set_trans(Tween.TRANS_SINE)
		p_tween.tween_property(_concert_portrait, "rotation_degrees", -5.0, 0.5).set_trans(Tween.TRANS_SINE)
		var p_scale = create_tween()
		p_scale.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		p_scale.set_loops()
		p_scale.tween_property(_concert_portrait, "scale", Vector2(1.1, 1.1), 0.4).set_trans(Tween.TRANS_BOUNCE)
		p_scale.tween_property(_concert_portrait, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BOUNCE)
		_concert_portrait.pivot_offset = _concert_portrait.size / 2
func _setup_lyrics_animation() -> void:
	_update_lyrics_display()
func _update_lyrics_display() -> void:
	for child in _concert_lyrics_container.get_children():
		child.queue_free()
	var display_range = 3
	var start_idx = max(0, lyrics_line_index - 1)
	var end_idx = min(current_lyrics.size(), start_idx + display_range)
	for i in range(start_idx, end_idx):
		var lbl = RichTextLabel.new()
		lbl.bbcode_enabled = true
		lbl.fit_content = true
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.custom_minimum_size.y = 30
		var text = current_lyrics[i]
		if i == lyrics_line_index:
			lbl.text = "[center][wave amp=50 freq=8][rainbow freq=1.0 sat=0.8 val=1.0]%s[/rainbow][/wave][/center]" % text
			lbl.add_theme_font_size_override("normal_font_size", 26)
			lbl.add_theme_constant_override("outline_size", 2)
			lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		else:
			lbl.text = "[center]%s[/center]" % text
			lbl.add_theme_font_size_override("normal_font_size", 16)
			lbl.modulate.a = 0.6
		_concert_lyrics_container.add_child(lbl)
func _finish_concert() -> void:
	_skip_button.visible = false
	if not _pray_button.visible:
		_pray_button.visible = true
		_pray_button.modulate.a = 0.0
		var t = create_tween()
		t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t.tween_property(_pray_button, "modulate:a", 1.0, 0.5)
		for child in _concert_video_placeholder.get_children():
			child.queue_free()
		var lbl = Label.new()
		lbl.text = _tr("NIGHT_CONCERT_ENDED")
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		_concert_video_placeholder.add_child(lbl)
func _on_pray_button_pressed() -> void:
	var audio = _get_audio_manager()
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx("happy_click")
	prayer_requested.emit()
func _on_skip_button_pressed() -> void:
	var audio = _get_audio_manager()
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx("menu_click")
	lyrics_line_index = current_lyrics.size()
	_update_lyrics_display()
	_finish_concert()
func _start_failsafe_timer() -> void:
	_content_failsafe_timer = Timer.new()
	_content_failsafe_timer.wait_time = 10.0
	_content_failsafe_timer.one_shot = true
	_content_failsafe_timer.timeout.connect(_on_content_failsafe_timeout)
	add_child(_content_failsafe_timer)
	_content_failsafe_timer.start()
func _on_content_failsafe_timeout() -> void:
	if _content_received: return
	print("[NightCycle] Failsafe timeout! Using fallback content.")
	var preset_lyrics = _get_preset_lyrics()
	apply_content_with_lyrics(
		_tr("NIGHT_REFLECTION_FALLBACK"),
		_tr("NIGHT_CONCERT_FALLBACK"),
		preset_lyrics,
		_tr("NIGHT_SONG_DEFAULT"),
		"",
		_tr("NIGHT_PROMPT_DEFAULT"),
		true
	)
func _request_ai_lyrics(reflection: String, concert: String, song_title: String, honeymoon: String, prompt: String) -> void:
	_concert_song_label.text = _tr("NIGHT_GENERATING_LYRICS")
	var context = {
		"purpose": "concert_lyrics",
		"song_title": song_title,
		"reflection": reflection,
		"concert_theme": concert
	}
	var ai_prompt = _build_lyrics_prompt(reflection, song_title)
	AIManager.generate_story(ai_prompt, context, Callable(self, "_on_lyrics_generated").bind(reflection, concert, song_title, honeymoon, prompt))
func _on_lyrics_generated(response: Dictionary, reflection: String, concert: String, song_title: String, honeymoon: String, prompt: String) -> void:
	var lyrics: Array = []
	if response.get("success", false):
		var content = response.get("content", "")
		var json = JSON.new()
		if json.parse(content) == OK:
			if json.data is Array: lyrics = json.data
			elif json.data is Dictionary and json.data.has("lyrics"): lyrics = json.data["lyrics"]
	if lyrics.size() >= 2:
		apply_content_with_lyrics(reflection, concert, lyrics, song_title, honeymoon, prompt, false)
	else:
		apply_content_with_lyrics(reflection, concert, [], song_title, honeymoon, prompt, true)
func _build_lyrics_prompt(reflection: String, song_title: String) -> String:
	var lang = LocalizationManager.get_language()
	if lang == "en":
		return """Generate 8-12 lines of lyrics for Teacher Chan's brainwashing concert song.
Context: Title="%s", Events="%s".
Style: Syrupy, cult-like positivity.
IMPORTANT: Return ONLY a raw JSON list of strings. Example: ["Happiness is mandatory", "Smile"]""" % [song_title, reflection]
	else:
		return """為陳老師的洗腦演唱會歌曲生成 8-12 行歌詞。
背景：標題="%s"，事件="%s"。
風格：糖衣般、邪教式的正能量。
重要：只回傳一個原始的 JSON 字串列表。範例：["快樂是義務", "微笑"]""" % [song_title, reflection]
func _get_preset_lyrics() -> Array:
	var lyrics = []
	for i in range(1, 11):
		lyrics.append(_tr("NIGHT_LYRICS_" + str(i)))
	return lyrics
func _should_use_preset_lyrics() -> bool:
	if not AIManager: return true
	return AIManager.gemini_api_key.strip_edges().is_empty() and AIManager.openrouter_api_key.strip_edges().is_empty()
func _tr(key: String) -> String:
	var localization_manager = ServiceLocator.get_localization_manager() if ServiceLocator else null
	if localization_manager:
		return localization_manager.get_translation(key, current_language)
	return key
func _get_audio_manager() -> Node:
	if is_instance_valid(_audio_manager): return _audio_manager
	if ServiceLocator: _audio_manager = ServiceLocator.get_audio_manager()
	return _audio_manager
func _create_love_particles() -> void:
	var particles = GPUParticles2D.new()
	particles.name = "LoveParticles"
	add_child(particles)
	particles.z_index = -5 
	particles.amount = 40
	particles.process_material = _create_heart_particle_material()
	particles.texture = preload("res://1.Codebase/src/assets/icons/crystal.png")
	particles.lifetime = 6.0
	particles.position = Vector2(960, 1100) 
func _create_heart_particle_material() -> ParticleProcessMaterial:
	var mat = ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(960, 1, 1) 
	mat.direction = Vector3(0, -1, 0) 
	mat.gravity = Vector3(0, -20, 0)
	mat.initial_velocity_min = 50.0
	mat.initial_velocity_max = 100.0
	mat.scale_min = 0.1
	mat.scale_max = 0.3
	mat.color = Color(1.0, 1.0, 1.0, 0.3) 
	return mat
func _filter_choice_previews(text: String) -> String:
	if text.is_empty():
		return text
	var clean = text
	var choice_markers = [
		"[Choice Preview]", "[choice preview]", "[CHOICE PREVIEW]",
		"[Choices]", "[choices]", "[CHOICES]",
		"選項預告", "选项预告",
		"[選項預告]", "[选项预告]",
		"選項預告：", "选项预告：",
	]
	for marker in choice_markers:
		var marker_pos = clean.find(marker)
		if marker_pos != -1:
			clean = clean.substr(0, marker_pos).strip_edges()
	var choice_prefixes = [
		"[Cautious]", "[Balanced]", "[Reckless]", "[Positive]", "[Complain]",
		"[cautious]", "[balanced]", "[reckless]", "[positive]", "[complain]",
		"[謹慎]", "[權衡]", "[瘋狂]", "[樂觀]", "[抱怨]",
		"[谨慎]", "[权衡]", "[疯狂]", "[乐观]", "[抱怨]",
	]
	for prefix in choice_prefixes:
		var prefix_pos = clean.find(prefix)
		if prefix_pos != -1:
			clean = clean.substr(0, prefix_pos).strip_edges()
	return clean
