extends Control
signal prayer_completed(result: Dictionary)
signal prayer_cancelled
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const PRAYER_NOTICE_SCENE: PackedScene = preload("res://1.Codebase/src/scenes/ui/prayer_notice.tscn")
@onready var prayer_panel: Panel = $PrayerPanel
@onready var prayer_input: TextEdit = $PrayerPanel/MarginContainer/VBoxContainer/PrayerInput
@onready var submit_button: Button = $PrayerPanel/MarginContainer/VBoxContainer/ButtonsContainer/SubmitButton
@onready var cancel_button: Button = $PrayerPanel/MarginContainer/VBoxContainer/ButtonsContainer/CancelButton
@onready var home_button: Button = $PrayerPanel/MarginContainer/VBoxContainer/ButtonsContainer/HomeButton
@onready var warning_label: Label = $PrayerPanel/MarginContainer/VBoxContainer/WarningLabel
@onready var title_label: Label = $PrayerPanel/MarginContainer/VBoxContainer/Title
@onready var description_label: Label = $PrayerPanel/MarginContainer/VBoxContainer/Description
var _reality_bar: ProgressBar
var _entropy_bar: ProgressBar
var _positive_energy_bar: ProgressBar
var is_processing: bool = false
var _notice_overlay: Control = null
var _input_locked_by_notice: bool = false
var _context: String = "default"
var _connecting_tween: Tween
var _retry_button: Button = null
var _last_prayer_text: String = ""
func _ready():
	print("[DEBUG] PrayerSystem: _ready called. Initializing prayer screen.")
	_setup_fullscreen_layout()
	_apply_modern_styling()
	_apply_localization()
	_update_stats_display()
	update_warning()
	if prayer_panel:
		prayer_panel.modulate.a = 0.0
		prayer_panel.scale = Vector2.ONE
		var tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(prayer_panel, "modulate:a", 1.0, 0.5)
	_maybe_show_data_notice()
func _setup_fullscreen_layout():
	if not prayer_panel:
		return
	prayer_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin = 40
	prayer_panel.offset_left = margin
	prayer_panel.offset_top = margin
	prayer_panel.offset_right = -margin
	prayer_panel.offset_bottom = -margin
	var margin_container = prayer_panel.get_node("MarginContainer")
	var input_vbox = margin_container.get_node("VBoxContainer")
	var h_split = HBoxContainer.new()
	h_split.name = "MainSplit"
	h_split.add_theme_constant_override("separation", 40)
	h_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stats_vbox = VBoxContainer.new()
	stats_vbox.name = "StatsColumn"
	stats_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_vbox.size_flags_stretch_ratio = 0.4 
	stats_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin_container.remove_child(input_vbox)
	margin_container.add_child(h_split)
	h_split.add_child(stats_vbox)
	h_split.add_child(input_vbox)
	input_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_vbox.size_flags_stretch_ratio = 0.6 
	input_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_build_stats_column(stats_vbox)
func _build_stats_column(parent: Control):
	var lang = GameState.current_language if GameState else "en"
	var header = Label.new()
	header.text = "Current State" if lang == "en" else "當前狀態"
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(header)
	parent.add_child(HSeparator.new())
	_reality_bar = _create_stat_row(parent, "Reality Perception" if lang == "en" else "現實感知", Color(0.2, 0.6, 1.0))
	_positive_energy_bar = _create_stat_row(parent, "Positive Energy" if lang == "en" else "正能量", Color(1.0, 0.8, 0.2))
	_entropy_bar = _create_stat_row(parent, "Entropy" if lang == "en" else "熵值", Color(0.8, 0.2, 0.2))
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	parent.add_child(spacer)
	var lore_label = Label.new()
	lore_label.text = "Warning: High entropy levels increase the risk of timeline collapse. Maintain your reality perception." if lang == "en" else "警告：高熵值會增加時間線崩潰的風險。請保持你的現實感知。"
	lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lore_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	parent.add_child(lore_label)
func _create_stat_row(parent: Control, title: String, color: Color) -> ProgressBar:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	var label = Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	container.add_child(label)
	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 20)
	bar.show_percentage = true
	bar.add_theme_color_override("font_color", Color.WHITE)
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = color
	style_box.corner_radius_top_left = 4
	style_box.corner_radius_top_right = 4
	style_box.corner_radius_bottom_left = 4
	style_box.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", style_box)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.5)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bg_style)
	container.add_child(bar)
	parent.add_child(container)
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	parent.add_child(spacer)
	return bar
func _update_stats_display():
	if not GameState:
		return
	if _reality_bar:
		_reality_bar.value = GameState.reality_score
	if _positive_energy_bar:
		_positive_energy_bar.value = GameState.positive_energy
	if _entropy_bar:
		_entropy_bar.value = GameState.entropy_level
func set_context(context: String) -> void:
	print("[DEBUG] PrayerSystem: set_context called. Context: %s" % context)
	_context = context
	if _context == "night":
		if cancel_button: cancel_button.visible = false
		if home_button: home_button.visible = false
func _apply_modern_styling():
	if prayer_panel:
		UIStyleManager.apply_panel_style(prayer_panel, 0.95, UIStyleManager.CORNER_RADIUS_LARGE)
	if submit_button:
		UIStyleManager.apply_button_style(submit_button, "primary", "large")
		UIStyleManager.add_hover_scale_effect(submit_button, 1.05)
		UIStyleManager.add_press_feedback(submit_button)
		submit_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if cancel_button:
		UIStyleManager.apply_button_style(cancel_button, "secondary", "medium")
		UIStyleManager.add_hover_scale_effect(cancel_button, 1.05)
		UIStyleManager.add_press_feedback(cancel_button)
		cancel_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if home_button:
		UIStyleManager.apply_button_style(home_button, "secondary", "medium")
		UIStyleManager.add_hover_scale_effect(home_button, 1.05)
		UIStyleManager.add_press_feedback(home_button)
		home_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if prayer_input:
		prayer_input.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		prayer_input.add_theme_color_override("caret_color", Color(0.7, 0.85, 1.0))
		prayer_input.add_theme_color_override("selection_color", Color(0.3, 0.5, 0.8, 0.5))
		prayer_input.add_theme_font_size_override("font_size", 16)
	if title_label:
		title_label.add_theme_font_size_override("font_size", 32)
		title_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	if description_label:
		description_label.add_theme_font_size_override("font_size", 14)
		description_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
func _apply_localization() -> void:
	var gs = GameState
	var lang = gs.current_language if gs else "en"
	if title_label:
		title_label.text = "The Prayer" if lang == "en" else "禱告"
	if description_label:
		description_label.text = "Offer your thoughts to the Flying Spaghetti Monster..." if lang == "en" else "向飛天意粉神獻上你的思緒..."
	if submit_button:
		submit_button.text = "Begin Prayer" if lang == "en" else "開始禱告"
	if cancel_button:
		cancel_button.text = "Cancel" if lang == "en" else "取消"
	if home_button:
		home_button.text = "Main Menu" if lang == "en" else "主選單"
	if prayer_input:
		prayer_input.placeholder_text = "Type your prayer here..." if lang == "en" else "在此輸入你的禱告..."
func _maybe_show_data_notice() -> void:
	if not GameState:
		return
	var has_seen := bool(GameState.get_metadata("prayer_notice_acknowledged", false))
	if has_seen:
		_set_input_enabled(true)
		return
	_set_input_enabled(false)
	_input_locked_by_notice = true
	if is_instance_valid(_notice_overlay):
		_notice_overlay.queue_free()
	var notice_instance: Node = PRAYER_NOTICE_SCENE.instantiate()
	var notice_control: Control = notice_instance as Control
	if notice_control == null:
		return
	_notice_overlay = notice_control
	add_child(notice_control)
	notice_control.connect("accepted", Callable(self, "_on_prayer_notice_accepted"))
	notice_control.connect("cancelled", Callable(self, "_on_prayer_notice_cancelled"))
func _set_input_enabled(enabled: bool) -> void:
	if prayer_input:
		prayer_input.editable = enabled
		prayer_input.mouse_filter = Control.MOUSE_FILTER_PASS if enabled else Control.MOUSE_FILTER_IGNORE
		if enabled and not is_processing:
			prayer_input.grab_focus()
	if submit_button:
		submit_button.disabled = not enabled or is_processing
func update_warning():
	var gs = GameState
	var lang = gs.current_language if gs else "en"
	if not warning_label:
		return
	var warning_text = ""
	var warning_color = Color.WHITE
	if gs.cognitive_dissonance_active:
		warning_text = "⚠️ COGNITIVE DISSONANCE: Your mind forces you to add positive words!" if lang == "en" else "⚠️ 認知失調：你的思維強迫你添加正能量詞彙！"
		warning_color = Color(1.0, 0.4, 1.0) 
	elif gs.reality_score < 30:
		warning_text = "⚠️ DANGER: Reality critically low! Prayer will bring catastrophic consequences!" if lang == "en" else "⚠️ 危險：現實感知極度低下！禱告將帶來災難性後果！"
		warning_color = Color(1.0, 0.2, 0.2)
	elif gs.reality_score < 50:
		warning_text = "⚠️ Warning: Low reality — prayer effects may spiral out of control" if lang == "en" else "⚠️ 警告：現實感知偏低，禱告效果可能失控"
		warning_color = Color(1.0, 0.6, 0.2)
	else:
		warning_text = "🍝 The Flying Spaghetti Monster will answer in His own way..." if lang == "en" else "🍝 飛天意粉神會以祂的方式回應你的禱告..."
		warning_color = Color(0.8, 0.8, 0.9)
	warning_label.text = warning_text
	warning_label.add_theme_color_override("font_color", warning_color)
	warning_label.add_theme_font_size_override("font_size", 15)
	if gs.reality_score < 30 or gs.cognitive_dissonance_active:
		_pulse_warning()
func _on_prayer_notice_accepted() -> void:
	_input_locked_by_notice = false
	if GameState:
		GameState.set_metadata("prayer_notice_acknowledged", true)
	_set_input_enabled(true)
	if is_instance_valid(_notice_overlay):
		_notice_overlay.queue_free()
	_notice_overlay = null
func _on_prayer_notice_cancelled() -> void:
	_input_locked_by_notice = false
	if is_instance_valid(_notice_overlay):
		_notice_overlay.queue_free()
	_notice_overlay = null
	_on_cancel_pressed()
func _on_submit_pressed():
	print("[DEBUG] PrayerSystem: Submit button pressed.")
	var lang = GameState.current_language if GameState else "en"
	if is_processing:
		return
	if _input_locked_by_notice:
		return
	var prayer_text = prayer_input.text.strip_edges()
	if prayer_text.is_empty():
		var msg = "Please enter your prayer" if lang == "en" else "請輸入你的禱告內容"
		show_error(msg)
		return
	if prayer_text.length() < 5:
		var msg = "Prayer is too short" if lang == "en" else "禱告內容太短了"
		show_error(msg)
		return
	var original_input = prayer_input.text.strip_edges()
	if GameState and GameState.cognitive_dissonance_active:
		prayer_text = _inject_positive_words(prayer_text, lang)
	var sanitized_prayer = _sanitize_prayer_text(prayer_text)
	if sanitized_prayer.is_empty():
		var blocked_msg = "Prayer contains unsupported content" if lang == "en" else "禱告內容包含不支援的格式"
		show_error(blocked_msg)
		return
	if sanitized_prayer.length() < 5:
		var trimmed_msg = "Prayer is too short after filtering" if lang == "en" else "移除受阻字詞後禱告太短"
		show_error(trimmed_msg)
		return
	if sanitized_prayer != original_input:
		prayer_input.text = sanitized_prayer
	prayer_text = sanitized_prayer
	_last_prayer_text = prayer_text  
	if _retry_button and is_instance_valid(_retry_button):
		_retry_button.visible = false
	is_processing = true
	submit_button.disabled = true
	_start_connecting_animation()
	_trigger_curse_flash()
	print("[DEBUG] PrayerSystem: Calling process_prayer with text length: %d" % prayer_text.length())
	process_prayer(prayer_text)
	var failsafe_timer = get_tree().create_timer(32.0)
	failsafe_timer.timeout.connect(func():
		if is_processing:
			print("[DEBUG] PrayerSystem: Request timed out (32s failsafe).")
			_on_disaster_generated({"success": false, "error": "Request timed out"})
	)
func _start_connecting_animation() -> void:
	if _connecting_tween:
		_connecting_tween.kill()
	var audio_manager = get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("countdown")
	_connecting_tween = create_tween()
	_connecting_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_connecting_tween.set_loops()
	_connecting_tween.tween_callback(func(): submit_button.text = "Connecting.").set_delay(0.5)
	_connecting_tween.tween_callback(func(): submit_button.text = "Connecting..").set_delay(0.5)
	_connecting_tween.tween_callback(func(): submit_button.text = "Connecting...").set_delay(0.5)
func _trigger_curse_flash() -> void:
	var flash = ColorRect.new()
	flash.color = Color(0.8, 0.1, 0.3, 0.0) 
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tween = flash.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(flash, "color:a", 0.4, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "color:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(flash.queue_free)
	if not GameState or GameState.settings.get("screen_shake_enabled", true):
		_shake_panel()
func process_prayer(prayer_text: String):
	var gs = GameState
	prayer_text = _sanitize_prayer_text(prayer_text)
	if prayer_text.is_empty():
		return
	var disaster_prompt = build_disaster_prompt(prayer_text)
	print("[DEBUG] PrayerSystem: Sending AI request via AIManager...")
	var callback = Callable(self, "_on_disaster_generated")
	AIManager.generate_story(disaster_prompt, { "purpose": "prayer", "prayer_text": prayer_text, "reality_score": gs.reality_score, "positive_energy": gs.positive_energy, "asset_ids": GameState.get_metadata("current_asset_ids", []) }, callback)
	_safe_record_event(gs, prayer_text)
	var achievement_system = ServiceLocator.get_achievement_system() if ServiceLocator else null
	if achievement_system:
		achievement_system.check_prayer()
func _safe_record_event(gs, prayer_text):
	if gs and gs.has_method("record_event"):
		gs.record_event(
			"prayer_made",
			{
				"prayer": prayer_text,
				"reality_score": gs.reality_score,
				"positive_energy": gs.positive_energy,
			},
		)
func build_disaster_prompt(prayer_text: String) -> String:
	prayer_text = _sanitize_prayer_text(prayer_text)
	var gs = GameState
	var lang = gs.current_language if gs else "en"
	var distortion_level = ""
	if lang == "en":
		if gs.reality_score < 30:
			distortion_level = "extremely twisted and catastrophic"
		elif gs.reality_score < 50:
			distortion_level = "severely twisted"
		elif gs.reality_score < 70:
			distortion_level = "twisted"
		else:
			distortion_level = "subtly twisted"
	else:
		if gs.reality_score < 30:
			distortion_level = "極度扭曲且災難性的"
		elif gs.reality_score < 50:
			distortion_level = "嚴重扭曲的"
		elif gs.reality_score < 70:
			distortion_level = "扭曲的"
		else:
			distortion_level = "微妙扭曲的"
	var prompt = ""
	if lang == "en":
		prompt = """
Player prays to the "Flying Spaghetti Monster": "%s"

Player's Reality Score: %d/100 (lower = more susceptible to distortion)
Player's Positive Energy: %d/100 (higher = more blindly optimistic)

Generate a %s consequence (150-200 words):

1. Superficially "grants" the prayer's wish
2. But actually causes a greater disaster
3. Uses irony to showcase the absurdity of "positive thinking"
4. Disaster severity is inversely proportional to reality score

Example Logic:
- Pray for "world peace" → Everyone brainwashed, losing self-awareness
- Pray to "eliminate negativity" → All people who can perceive reality are eliminated
- Pray to "make everyone happy" → Forced "happiness hormones" cause societal collapse

Generate the twisted result of this prayer, maintaining dark humor.
""" % [prayer_text, gs.reality_score, gs.positive_energy, distortion_level]
	else:
		prompt = """
玩家向「飛天意粉神」禱告：「%s」

玩家的現實感知: %d/100 (越低越容易被扭曲)
玩家的正能量指數: %d/100 (越高越盲目樂觀)

請生成一個%s後果（150-200字）：

1. 表面上「實現」了禱告的願望
2. 但實際上造成了更大的災難
3. 用諷刺的方式展現「正能量思維」的荒謬
4. 災難的嚴重程度與現實感知成反比

範例邏輯：
- 禱告「世界和平」→ 所有人被洗腦失去自我意識
- 禱告「消除負能量」→ 所有能感知現實的人被消滅
- 禱告「讓大家快樂」→ 強制注射「快樂激素」導致社會崩潰

請生成這次禱告的扭曲結果，保持黑色幽默。
""" % [prayer_text, gs.reality_score, gs.positive_energy, distortion_level]
	return prompt
func _on_disaster_generated(response: Dictionary):
	print("[DEBUG] PrayerSystem: _on_disaster_generated called.")
	print("[DEBUG] PrayerSystem: Response success: %s" % str(response.get("success", false)))
	if not response.get("success", false):
		print("[DEBUG] PrayerSystem: Error details: %s" % str(response.get("error", "Unknown error")))
	var lang = GameState.current_language if GameState else "en"
	if _connecting_tween:
		_connecting_tween.kill()
	is_processing = false
	submit_button.disabled = false
	submit_button.text = "Begin Prayer" if lang == "en" else "開始禱告"
	var audio_manager = get_audio_manager()
	if audio_manager:
		audio_manager.play_sfx("game_over")
	if response.success:
		var disaster_text = response.content
		var reality_penalty = -15
		var positive_increase = 20
		var entropy_increase = 1
		if GameState.reality_score < 30:
			reality_penalty = -25
			positive_increase = 30
			entropy_increase = 2
		elif GameState.reality_score < 50:
			reality_penalty = -20
			positive_increase = 25
			entropy_increase = 1
		GameState.modify_reality_score(reality_penalty)
		GameState.modify_positive_energy(positive_increase)
		var entropy_reason = "Prayer aftershock" if lang == "en" else "禱告餘震"
		GameState.modify_entropy(entropy_increase, entropy_reason)
		var result = {
			"prayer": prayer_input.text,
			"disaster": disaster_text,
			"reality_change": reality_penalty,
			"positive_change": positive_increase,
			"entropy_change": entropy_increase,
			"context": _context,
		}
		prayer_completed.emit(result)
		print("[DEBUG] PrayerSystem: Prayer completed signal emitted.")
		queue_free()
	else:
		var error_text = String(response.get("error", "Unknown error"))
		var display_error: String
		if "timed out" in error_text.to_lower() or "timeout" in error_text.to_lower():
			display_error = "The divine connection was interrupted. Please try again." if lang == "en" else "與神靈的連結中斷了，請再試一次。"
		elif "network" in error_text.to_lower() or "connection" in error_text.to_lower():
			display_error = "Unable to reach the divine realm. Check your connection." if lang == "en" else "無法連接神靈領域，請檢查網絡連接。"
		elif "api" in error_text.to_lower() or "key" in error_text.to_lower():
			display_error = "The divine gateway is sealed. API configuration needed." if lang == "en" else "神靈通道已封印，需要設置 API。"
		else:
			var error_msg = "Prayer failed: " if lang == "en" else "禱告失敗: "
			display_error = error_msg + error_text
		show_error(display_error)
		_show_retry_button(lang)
func _on_cancel_pressed():
	prayer_cancelled.emit()
	queue_free()
func _on_home_pressed():
	GameState.save_game()
	get_tree().change_scene_to_file("res://1.Codebase/menu_main.tscn")
func get_audio_manager():
	if ServiceLocator and ServiceLocator.has_service("AudioManager"):
		return ServiceLocator.get_service("AudioManager")
	return null
func show_error(message: String):
	if not warning_label:
		return
	warning_label.text = message
	warning_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	warning_label.add_theme_font_size_override("font_size", 15)
	if not GameState or GameState.settings.get("screen_shake_enabled", true):
		_shake_panel()
func _show_retry_button(lang: String) -> void:
	if not _retry_button or not is_instance_valid(_retry_button):
		_retry_button = Button.new()
		_retry_button.name = "RetryButton"
		_retry_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_retry_button.custom_minimum_size = Vector2(0, 45)
		_retry_button.pressed.connect(_on_retry_pressed)
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color(0.8, 0.3, 0.3, 1.0)  
		stylebox.corner_radius_top_left = 8
		stylebox.corner_radius_top_right = 8
		stylebox.corner_radius_bottom_left = 8
		stylebox.corner_radius_bottom_right = 8
		_retry_button.add_theme_stylebox_override("normal", stylebox)
		var hover_style = stylebox.duplicate()
		hover_style.bg_color = Color(1.0, 0.4, 0.4, 1.0)
		_retry_button.add_theme_stylebox_override("hover", hover_style)
		_retry_button.add_theme_color_override("font_color", Color.WHITE)
		_retry_button.add_theme_font_size_override("font_size", 18)
		if warning_label and warning_label.get_parent():
			var parent = warning_label.get_parent()
			var warning_idx = warning_label.get_index()
			parent.add_child(_retry_button)
			parent.move_child(_retry_button, warning_idx + 1)
	_retry_button.text = "🔄 Retry Prayer" if lang == "en" else "🔄 重試禱告"
	_retry_button.visible = true
func _on_retry_pressed() -> void:
	var lang = GameState.current_language if GameState else "en"
	update_warning()
	if _retry_button and is_instance_valid(_retry_button):
		_retry_button.visible = false
	var prayer_text = _last_prayer_text if not _last_prayer_text.is_empty() else prayer_input.text.strip_edges()
	if prayer_text.is_empty():
		show_error("Please enter your prayer" if lang == "en" else "請輸入你的禱告內容")
		return
	is_processing = true
	submit_button.disabled = true
	_start_connecting_animation()
	_trigger_curse_flash()
	print("[DEBUG] PrayerSystem: Retrying prayer with text length: %d" % prayer_text.length())
	process_prayer(prayer_text)
	get_tree().create_timer(32.0).timeout.connect(func():
		if is_processing:
			print("[DEBUG] PrayerSystem: Retry request timed out (32s failsafe).")
			_on_disaster_generated({"success": false, "error": "Request timed out"})
	)
func _sanitize_prayer_text(prayer_text: String) -> String:
	var sanitized = prayer_text.strip_edges()
	if AIManager and AIManager.has_method("sanitize_user_text"):
		sanitized = AIManager.sanitize_user_text(sanitized, 320)
	else:
		sanitized = sanitized.replace("\r", " ")
		sanitized = sanitized.replace("\n", " ")
		sanitized = sanitized.replace("\t", " ")
		var blocked_tokens = ["```", ":::", "===", "[INST]", "[/INST]", "<s>", "</s>"]
		for token in blocked_tokens:
			sanitized = sanitized.replace(token, "")
		var regex = RegEx.new()
		regex.compile("\\s+")
		sanitized = regex.sub(sanitized, " ", true).strip_edges()
		if sanitized.length() > 320:
			sanitized = sanitized.substr(0, 320)
	return sanitized
func _inject_positive_words(prayer_text: String, lang: String) -> String:
	const POSITIVE_WORDS_EN = ["hope", "love", "positive energy", "blessing", "wonderful", "grateful", "optimistic"]
	const POSITIVE_WORDS_ZH = ["希望", "愛", "正能量", "祝福", "美好", "感恩", "樂觀"]
	var positive_words = POSITIVE_WORDS_EN if lang == "en" else POSITIVE_WORDS_ZH
	var injected_word = positive_words[randi() % positive_words.size()]
	if lang == "en":
		return prayer_text + ". May " + injected_word + " guide us."
	else:
		return prayer_text + "。願" + injected_word + "指引我們。"
func _pulse_warning():
	if not warning_label:
		return
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_loops()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(warning_label, "modulate:a", 0.6, 0.8)
	tween.tween_property(warning_label, "modulate:a", 1.0, 0.8)
func _shake_panel():
	if not prayer_panel:
		return
	var original_pos = prayer_panel.position
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SPRING)
	for i in range(4):
		var offset_x = 10 if i % 2 == 0 else -10
		tween.tween_property(prayer_panel, "position", original_pos + Vector2(offset_x, 0), 0.05)
	tween.tween_property(prayer_panel, "position", original_pos, 0.1)
