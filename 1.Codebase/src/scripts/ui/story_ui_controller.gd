extends BaseController
class_name StoryUIController
var ui_bindings: StorySceneUIBindings
var story_text: RichTextLabel
var story_scroll: ScrollContainer
var reality_bar: ProgressBar
var reality_value: Label
var positive_bar: ProgressBar
var positive_value: Label
var entropy_value: Label
var loading_overlay: Control
var loading_label: Label
var loading_sublabel: Label
var loading_dots: Label
var loading_timer_label: Label
var loading_model_label: Label
var status_label: Label
var ai_error_overlay: Control
var ai_error_title_label: Label
var ai_error_message_label: Label
var ai_error_details_label: Label
var ai_error_retry_button: Button
var ai_error_offline_button: Button
var ai_error_home_button: Button
var loading_animation_time: float = 0.0
var loading_start_time: float = 0.0
var current_loading_context: String = "default"
const MarkdownParser = preload("res://1.Codebase/src/scripts/ui/markdown_parser.gd")
const StoryUIHelper = preload("res://1.Codebase/src/scripts/ui/story_ui_helper.gd")
const LoadingDisplay = preload("res://1.Codebase/src/scripts/ui/loading_display.gd")
const GameConstants = preload("res://1.Codebase/src/scripts/core/game_constants.gd")
func _init(p_story_scene: Control) -> void:
	super(p_story_scene) 
	_setup_ui_references()
func _setup_ui_references() -> void:
	ui_bindings = _resolve_ui_bindings()
	if not ui_bindings:
		_report_error("StorySceneUIBindings reference not available for StoryUIController")
		return
	story_text = ui_bindings.story_text
	story_scroll = ui_bindings.story_scroll
	reality_bar = ui_bindings.reality_bar
	reality_value = ui_bindings.reality_value
	positive_bar = ui_bindings.positive_bar
	positive_value = ui_bindings.positive_value
	entropy_value = ui_bindings.entropy_value
	loading_overlay = ui_bindings.loading_overlay
	loading_label = ui_bindings.loading_label
	loading_sublabel = ui_bindings.loading_sublabel
	loading_dots = ui_bindings.loading_dots
	loading_timer_label = ui_bindings.loading_timer_label
	loading_model_label = ui_bindings.loading_model_label
	status_label = ui_bindings.status_label
	ai_error_overlay = ui_bindings.ai_error_overlay
	ai_error_title_label = ui_bindings.ai_error_title_label
	ai_error_message_label = ui_bindings.ai_error_message_label
	ai_error_details_label = ui_bindings.ai_error_details_label
	ai_error_retry_button = ui_bindings.ai_error_retry_button
	ai_error_offline_button = ui_bindings.ai_error_offline_button
	ai_error_home_button = ui_bindings.ai_error_home_button
func _resolve_ui_bindings() -> StorySceneUIBindings:
	if not story_scene:
		return null
	var binding: Variant = null
	if story_scene.has_method("get_ui_bindings"):
		binding = story_scene.get_ui_bindings()
	if (binding == null or not is_instance_valid(binding)) and story_scene.has_method("get_ui"):
		binding = story_scene.get_ui()
	if binding is StorySceneUIBindings and is_instance_valid(binding):
		return binding
	return null
func update_stats_display() -> void:
	var game_state: Node = get_game_state()
	if not game_state:
		return
	_update_reality_display(game_state)
	_update_positive_energy_display(game_state)
	_update_entropy_display(game_state)
func _update_reality_display(game_state: Node) -> void:
	if reality_bar:
		reality_bar.value = game_state.reality_score
		_apply_stat_color_gradient(reality_bar, game_state.reality_score)
	if reality_value:
		reality_value.text = str(game_state.reality_score)
func _update_positive_energy_display(game_state: Node) -> void:
	if positive_bar:
		positive_bar.value = game_state.positive_energy
		_apply_stat_color_gradient(positive_bar, game_state.positive_energy)
	if positive_value:
		positive_value.text = str(game_state.positive_energy)
func _update_entropy_display(game_state: Node) -> void:
	if entropy_value:
		var entropy_level: float = game_state.entropy_level
		var entropy_text := str(entropy_level)
		if entropy_level > GameConstants.Stats.HIGH_ENTROPY_CRITICAL:
			entropy_text = "[color=red]%s ?[/color]" % entropy_text
		elif entropy_level > GameConstants.Stats.HIGH_ENTROPY_WARNING:
			entropy_text = "[color=yellow]%s[/color]" % entropy_text
		entropy_value.text = entropy_text
func _apply_stat_color_gradient(bar: ProgressBar, value: int) -> void:
	if not bar:
		return
	var style := bar.get_theme_stylebox("fill")
	if not style is StyleBoxFlat:
		return
	var color: Color = GameConstants.UI.COLOR_STAT_LOW
	if value >= GameConstants.UI.STAT_COLOR_HIGH_THRESHOLD:
		color = GameConstants.UI.COLOR_STAT_HIGH
	elif value >= GameConstants.UI.STAT_COLOR_MEDIUM_THRESHOLD:
		color = GameConstants.UI.COLOR_STAT_MEDIUM
	style.bg_color = color
func display_story(content: String) -> void:
	if not story_text:
		return
	var bbcode: String = MarkdownParser.parse_markdown(content)
	var current_text := story_text.get_parsed_text()
	if not current_text.is_empty():
		story_text.append_text("\n\n")
	var prev_char_count = story_text.get_parsed_text().length()
	story_text.append_text(bbcode)
	var game_state = get_game_state()
	var text_speed = 1.0
	if game_state and "settings" in game_state:
		text_speed = game_state.settings.get("text_speed", 1.0)
	if text_speed > 0.0:
		var new_char_count = story_text.get_parsed_text().length()
		var chars_to_add = new_char_count - prev_char_count
		if chars_to_add > 0:
			story_text.visible_characters = prev_char_count
			var chars_per_sec = 50.0 * text_speed
			var duration = float(chars_to_add) / max(chars_per_sec, 1.0)
			var tween = story_scene.create_tween()
			tween.tween_property(story_text, "visible_characters", new_char_count, duration)
			tween.tween_callback(func(): story_text.visible_characters = -1) 
	else:
		story_text.visible_characters = -1
	await story_scene.get_tree().process_frame
	if story_scroll:
		var scroll_bar = story_scroll.get_v_scroll_bar()
		var target_value = int(scroll_bar.max_value)
		var current_val = scroll_bar.value
		if abs(target_value - current_val) < 1000:
			var tween = story_scroll.create_tween()
			tween.tween_property(story_scroll, "scroll_vertical", target_value, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			story_scroll.scroll_vertical = target_value
func clear_story_text() -> void:
	if story_text:
		story_text.clear()
func show_loading(should_show: bool, context: String = "default") -> void:
	if not loading_overlay:
		return
	if should_show:
		_start_loading(context)
	else:
		_stop_loading()
func _start_loading(context: String) -> void:
	current_loading_context = context
	if not loading_overlay:
		_report_warning("Loading overlay not bound; cannot start loading UI")
		return
	loading_overlay.visible = true
	loading_start_time = Time.get_ticks_msec() / 1000.0
	loading_animation_time = 0.0
	var game_state: Node = get_game_state()
	var lang: String = game_state.current_language if game_state else "en"
	if loading_label:
		loading_label.text = LoadingDisplay.get_random_loading_phrase(lang)
	if loading_sublabel:
		loading_sublabel.text = LoadingDisplay.get_loading_sublabel(context, lang)
	if loading_model_label:
		var ai_manager: Node = get_ai_manager()
		if ai_manager:
			var model := _get_current_model_name(ai_manager)
			loading_model_label.text = "Model: " + model
		else:
			loading_model_label.text = ""
	if loading_timer_label:
		loading_timer_label.text = "00:00"
func _stop_loading() -> void:
	if loading_overlay:
		loading_overlay.visible = false
func update_loading_progress(progress_info: Dictionary) -> void:
	if not loading_overlay or not loading_overlay.visible:
		return
	var game_state: Node = get_game_state()
	var lang: String = game_state.current_language if game_state else "en"
	var message := LoadingDisplay.get_progress_display_text(progress_info, lang)
	if loading_label:
		loading_label.text = message
func process_loading_animation(delta: float) -> void:
	if not loading_overlay or not loading_overlay.visible:
		return
	loading_animation_time += delta
	if loading_dots:
		loading_dots.text = LoadingDisplay.get_loading_dots_for_time(loading_animation_time)
	if loading_timer_label:
		var elapsed := (Time.get_ticks_msec() / 1000.0) - loading_start_time
		loading_timer_label.text = LoadingDisplay.format_elapsed_time(elapsed)
func show_ai_error_overlay(title: String, message: String, details: String = "", offline_enabled: bool = true) -> void:
	if not ai_error_overlay:
		return
	var resolved_title := title.strip_edges()
	if resolved_title.is_empty():
		resolved_title = "AI Error"
	var resolved_message := message.strip_edges()
	if resolved_message.is_empty():
		resolved_message = "The AI service did not respond."
	var resolved_details := details.strip_edges()
	ai_error_overlay.visible = true
	if ai_error_title_label:
		ai_error_title_label.text = resolved_title
	if ai_error_message_label:
		ai_error_message_label.text = resolved_message
	if ai_error_details_label:
		ai_error_details_label.text = resolved_details
		ai_error_details_label.visible = not resolved_details.is_empty()
	var lang := "en"
	var game_state = get_game_state()
	if game_state:
		lang = String(game_state.current_language)
	var retry_text := LocalizationManager.get_translation("STORY_RETRY_BUTTON", lang)
	var offline_text := LocalizationManager.get_translation("STORY_OFFLINE_BUTTON", lang)
	var home_text := LocalizationManager.get_translation("STORY_HOME_BUTTON", lang)
	if ai_error_retry_button:
		ai_error_retry_button.visible = true
		ai_error_retry_button.disabled = false
		ai_error_retry_button.text = retry_text
	if ai_error_offline_button:
		ai_error_offline_button.visible = offline_enabled
		ai_error_offline_button.disabled = not offline_enabled
		ai_error_offline_button.text = offline_text
	if ai_error_home_button:
		ai_error_home_button.visible = true
		ai_error_home_button.disabled = false
		ai_error_home_button.text = home_text
	if offline_enabled and ai_error_offline_button and ai_error_offline_button.is_inside_tree():
		ai_error_offline_button.grab_focus()
	elif ai_error_retry_button and ai_error_retry_button.is_inside_tree():
		ai_error_retry_button.grab_focus()
	elif ai_error_home_button and ai_error_home_button.is_inside_tree():
		ai_error_home_button.grab_focus()
func hide_ai_error_overlay() -> void:
	if not ai_error_overlay:
		return
	ai_error_overlay.visible = false
	if ai_error_message_label:
		ai_error_message_label.text = ""
	if ai_error_details_label:
		ai_error_details_label.text = ""
		ai_error_details_label.visible = false
	if ai_error_retry_button:
		ai_error_retry_button.visible = false
	if ai_error_offline_button:
		ai_error_offline_button.visible = false
	if ai_error_home_button:
		ai_error_home_button.visible = false
func _get_current_model_name(ai_manager: Node) -> String:
	if not ai_manager:
		return "Unknown"
	match ai_manager.current_provider:
		0: 
			return ai_manager.gemini_model
		1: 
			return ai_manager.openrouter_model
		2: 
			return ai_manager.ollama_model
		_:
			return "Unknown"
func update_ui_labels() -> void:
	var game_state: Node = get_game_state()
	if not game_state:
		return
func apply_font_sizes() -> void:
	var font_manager = get_font_manager()
	if not font_manager:
		return
	if story_text:
		var font_size: int = font_manager.get_font_size("story_text")
		if font_size > 0:
			story_text.add_theme_font_size_override("normal_font_size", font_size)
func set_status_text(text: String) -> void:
	if status_label:
		status_label.text = text
func animate_ui_entrance() -> void:
	if story_text:
		story_text.modulate.a = 0.0
		var tween := story_scene.create_tween()
		tween.tween_property(story_text, "modulate:a", 1.0, 0.5)
func show_welcome_message() -> void:
	var game_state: Node = get_game_state()
	var lang: String = game_state.current_language if game_state else "en"
	var welcome_text := ""
	if lang == "zh":
		welcome_text = """歡迎來到光榮拯救機構 1

你是一個被迫加入的英雄，被迫加入一個功能失調的團隊，他們試圖用「正能量」拯救世界。

諷刺的是？正能量只會加速世界的毀滅。

你準備好面對荒謬、黑色幽默和你隊友的「幫助」了嗎？"""
	else:
		welcome_text = """Welcome to Glorious Deliverance Agency 1

You are a reluctant hero forced to join a dysfunctional team attempting to save the world with "positive energy."

The irony? Positive energy only accelerates the world's destruction.

Are you ready to face absurdity, dark humor, and your teammates' "help"?"""
	display_story(welcome_text)
