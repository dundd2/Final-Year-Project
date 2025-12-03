extends Control
var ai_manager: Node
var current_language: String = "en"
const _ACTIVE_MODULATE := Color(1, 1, 1, 1)
const _INACTIVE_MODULATE := Color(0.6, 0.6, 0.6, 1)
const _DISABLED_MESSAGE := "Player is not using this method."
const _OLLAMA_READY_SUFFIX := " (ready)"
const _OLLAMA_OFFLINE_SUFFIX := " (offline)"
const _OLLAMA_SETUP_SUFFIX := " (setup incomplete)"
const _OLLAMA_SETUP_REQUIRED := "Ollama setup is incomplete. Please provide the host, port, and model name below. You can find the model name by running 'ollama list' in your terminal."
const _OLLAMA_OFFLINE_TEMPLATE := "Could not connect to Ollama at %s:%d. \n- Make sure the Ollama application is running on your computer. \n- Check if the host and port are correct. \n- Verify that the model has been pulled by running 'ollama list' in your terminal."
const DEFAULT_OLLAMA_URL := "http://127.0.0.1:11434"
@warning_ignore("shadowed_global_identifier")
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
@onready var main_vbox = $ScrollContainer/Panel/VBoxContainer
@onready var original_scroll = $ScrollContainer
@onready var panel = $ScrollContainer/Panel
@onready var buttons_container = $BottomControls
@onready var provider_option: OptionButton = $ScrollContainer/Panel/VBoxContainer/ProviderOption
@onready var provider_status_label: Label = $ScrollContainer/Panel/VBoxContainer/ProviderStatusLabel
@onready var test_button: Button = $ScrollContainer/Panel/VBoxContainer/TestButton
@onready var status_label: Label = $ScrollContainer/Panel/VBoxContainer/StatusLabel
@onready var provider_label: Label = $ScrollContainer/Panel/VBoxContainer/ProviderLabel
@onready var gemini_label: Label = $ScrollContainer/Panel/VBoxContainer/GeminiLabel
@onready var gemini_key_input: LineEdit = $ScrollContainer/Panel/VBoxContainer/GeminiKeyInput
@onready var gemini_hint_label: Label = $ScrollContainer/Panel/VBoxContainer/GeminiHintLabel
@onready var gemini_model_label: Label = $ScrollContainer/Panel/VBoxContainer/GeminiModelLabel
@onready var gemini_model_option: OptionButton = $ScrollContainer/Panel/VBoxContainer/GeminiModelOption
@onready var gemini_disabled_label: Label = $ScrollContainer/Panel/VBoxContainer/GeminiDisabledLabel
@onready var openrouter_label: Label = $ScrollContainer/Panel/VBoxContainer/OpenRouterLabel
@onready var openrouter_key_input: LineEdit = $ScrollContainer/Panel/VBoxContainer/OpenRouterKeyInput
@onready var openrouter_hint_label: Label = $ScrollContainer/Panel/VBoxContainer/OpenRouterHintLabel
@onready var openrouter_model_label: Label = $ScrollContainer/Panel/VBoxContainer/ModelLabel
@onready var openrouter_model_input: LineEdit = $ScrollContainer/Panel/VBoxContainer/ModelInput
@onready var openrouter_disabled_label: Label = $ScrollContainer/Panel/VBoxContainer/OpenRouterDisabledLabel
@onready var ollama_header_label: Label = $ScrollContainer/Panel/VBoxContainer/OllamaHeaderLabel
@onready var ollama_info_label: Label = $ScrollContainer/Panel/VBoxContainer/OllamaInfoLabel
@onready var ollama_host_label: Label = $ScrollContainer/Panel/VBoxContainer/OllamaHostLabel
@onready var ollama_host_input: LineEdit = $ScrollContainer/Panel/VBoxContainer/OllamaHostInput
@onready var ollama_port_label: Label = $ScrollContainer/Panel/VBoxContainer/OllamaPortLabel
@onready var ollama_port_spin: SpinBox = $ScrollContainer/Panel/VBoxContainer/OllamaPortSpin
@onready var ollama_model_label: Label = $ScrollContainer/Panel/VBoxContainer/OllamaModelLabel
@onready var ollama_model_input: LineEdit = $ScrollContainer/Panel/VBoxContainer/OllamaModelInput
@onready var ollama_use_chat_check: CheckBox = $ScrollContainer/Panel/VBoxContainer/OllamaUseChatCheck
@onready var ollama_options_label: Label = $ScrollContainer/Panel/VBoxContainer/OllamaOptionsLabel
@onready var ollama_options_input: TextEdit = $ScrollContainer/Panel/VBoxContainer/OllamaOptionsInput
@onready var ollama_hint_label: Label = $ScrollContainer/Panel/VBoxContainer/OllamaHintLabel
@onready var ollama_disabled_label: Label = $ScrollContainer/Panel/VBoxContainer/OllamaDisabledLabel
@onready var memory_settings_label: Label = $ScrollContainer/Panel/VBoxContainer/MemorySettingsLabel
@onready var memory_hint_label: Label = $ScrollContainer/Panel/VBoxContainer/MemoryHintLabel
@onready var memory_limit_container = $ScrollContainer/Panel/VBoxContainer/MemoryLimitContainer
@onready var memory_limit_label: Label = memory_limit_container.get_node("MemoryLimitLabel")
@onready var memory_limit_spin: SpinBox = memory_limit_container.get_node("MemoryLimitSpin")
@onready var memory_summary_container = $ScrollContainer/Panel/VBoxContainer/MemorySummaryContainer
@onready var memory_summary_label: Label = memory_summary_container.get_node("MemorySummaryLabel")
@onready var memory_summary_spin: SpinBox = memory_summary_container.get_node("MemorySummarySpin")
@onready var memory_full_container = $ScrollContainer/Panel/VBoxContainer/MemoryFullContainer
@onready var memory_full_label: Label = memory_full_container.get_node("MemoryFullLabel")
@onready var memory_full_spin: SpinBox = memory_full_container.get_node("MemoryFullSpin")
@onready var context_layers_label: Label = $ScrollContainer/Panel/VBoxContainer/ContextLayersLabel
@onready var context_panel = $ScrollContainer/Panel/VBoxContainer/ContextPanel
@onready var long_term_header: Label = context_panel.get_node("ContextVBox/LongTermHeader")
@onready var long_term_text: RichTextLabel = context_panel.get_node("ContextVBox/LongTermText")
@onready var notes_header: Label = context_panel.get_node("ContextVBox/NotesHeader")
@onready var notes_text: RichTextLabel = context_panel.get_node("ContextVBox/NotesText")
@onready var metrics_label: Label = $ScrollContainer/Panel/VBoxContainer/MetricsLabel
@onready var last_response_time_label: Label = $ScrollContainer/Panel/VBoxContainer/LastResponseTimeLabel
@onready var total_api_calls_label: Label = $ScrollContainer/Panel/VBoxContainer/TotalAPICallsLabel
@onready var total_tokens_used_label: Label = $ScrollContainer/Panel/VBoxContainer/TotalTokensUsedLabel
@onready var last_input_tokens_label: Label = $ScrollContainer/Panel/VBoxContainer/LastInputTokensLabel
@onready var last_output_tokens_label: Label = $ScrollContainer/Panel/VBoxContainer/LastOutputTokensLabel
@onready var metrics_chart_container: Panel = $ScrollContainer/Panel/VBoxContainer/MetricsChartContainer
@onready var ai_tone_style_label: Label = $ScrollContainer/Panel/VBoxContainer/AIToneStyleLabel
@onready var ai_tone_style_input: LineEdit = $ScrollContainer/Panel/VBoxContainer/AIToneStyleInput
@onready var save_button = $BottomControls/SaveButton
@onready var back_button = $BottomControls/BackButton
@onready var home_button = $BottomControls/HomeButton
var tab_container: TabContainer
var tab_gemini: VBoxContainer
var tab_openrouter: VBoxContainer
var tab_ollama: VBoxContainer
var tab_memory: VBoxContainer
var tab_metrics: VBoxContainer
var tab_behavior: VBoxContainer
var tab_safety: VBoxContainer
var safety_level_label: Label
var safety_level_option: OptionButton
var safety_hint_label: Label
var ai_metrics_chart: Control = preload("res://1.Codebase/src/scripts/ui/ai_metrics_chart.gd").new()
var _gemini_inputs: Array = []
var _gemini_visuals: Array = []
var _openrouter_inputs: Array = []
var _openrouter_visuals: Array = []
var _ollama_inputs: Array = []
var _ollama_visuals: Array = []
func _clamp_port(value: int) -> int:
	return clampi(value, 1, 65535)
func _build_ollama_url(host: String, port: int, scheme: String = "http") -> String:
	var clean_host := host.strip_edges()
	if clean_host.is_empty():
		clean_host = "127.0.0.1"
	var clean_scheme := scheme.strip_edges()
	if clean_scheme.is_empty():
		clean_scheme = "http"
	var effective_port := _clamp_port(port)
	if clean_host.begins_with("[") and clean_host.ends_with("]"):
		return "%s://%s:%d" % [clean_scheme, clean_host, effective_port]
	if clean_host.contains(":") and not clean_host.contains(".") and not clean_host.begins_with("["):
		return "%s://[%s]:%d" % [clean_scheme, clean_host, effective_port]
	return "%s://%s:%d" % [clean_scheme, clean_host, effective_port]
func _parse_ollama_url(raw: String, fallback_port: int) -> Dictionary:
	var text := raw.strip_edges()
	var scheme := "http"
	var fallback := _clamp_port(fallback_port)
	if text.is_empty():
		return {
			"ok": true,
			"host": "127.0.0.1",
			"port": fallback,
			"scheme": scheme,
			"url": DEFAULT_OLLAMA_URL,
			"explicit_port": false,
		}
	var working := text
	var lower := working.to_lower()
	if lower.begins_with("http://"):
		scheme = "http"
		working = working.substr(7)
	elif lower.begins_with("https://"):
		scheme = "https"
		working = working.substr(8)
	var slash_idx := working.find("/")
	if slash_idx != -1:
		working = working.substr(0, slash_idx)
	working = working.strip_edges()
	if working.is_empty():
		return {
			"ok": false,
			"error": "Ollama URL missing host.",
		}
	var host_part := working
	var port_value := fallback
	var explicit_port := false
	if host_part.begins_with("["):
		var close_idx := host_part.find("]")
		if close_idx == -1:
			return {
				"ok": false,
				"error": "Ollama URL has malformed IPv6 host.",
			}
		var remainder := host_part.substr(close_idx + 1).strip_edges()
		if remainder.begins_with(":"):
			var port_str := remainder.substr(1).strip_edges()
			if port_str.is_empty():
				return {
					"ok": false,
					"error": "Ollama URL missing port number.",
				}
			if not port_str.is_valid_int():
				return {
					"ok": false,
					"error": "Ollama URL has invalid port.",
				}
			port_value = _clamp_port(int(port_str))
			explicit_port = true
		elif not remainder.is_empty():
			return {
				"ok": false,
				"error": "Ollama URL has invalid format.",
			}
		host_part = host_part.substr(1, close_idx - 1)
	else:
		var colon_idx := host_part.rfind(":")
		if colon_idx != -1:
			var port_str := host_part.substr(colon_idx + 1).strip_edges()
			if port_str.is_empty():
				return {
					"ok": false,
					"error": "Ollama URL missing port number.",
				}
			if not port_str.is_valid_int():
				return {
					"ok": false,
					"error": "Ollama URL has invalid port.",
				}
			port_value = _clamp_port(int(port_str))
			explicit_port = true
			host_part = host_part.substr(0, colon_idx)
	host_part = host_part.strip_edges()
	if host_part.is_empty():
		return {
			"ok": false,
			"error": "Ollama URL missing host.",
		}
	var display_host := host_part
	if display_host.contains(":") and not display_host.begins_with("["):
		display_host = "[%s]" % display_host
	return {
		"ok": true,
		"host": host_part,
		"port": port_value,
		"scheme": scheme,
		"explicit_port": explicit_port,
		"url": _build_ollama_url(host_part, port_value, scheme),
	}
func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	ai_manager = ServiceLocator.get_ai_manager() if ServiceLocator else AIManager
	current_language = GameState.current_language if GameState else "en"
	_rebuild_layout_into_tabs()
	_update_ui_labels()
	_configure_provider_widgets()
	if metrics_chart_container:
		metrics_chart_container.add_child(ai_metrics_chart)
		ai_metrics_chart.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_update_metrics_display()
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0 
	timer.autostart = true
	timer.timeout.connect(_update_metrics_display)
	if ai_manager:
		ai_manager.ai_response_received.connect(_on_ai_test_success)
		ai_manager.ai_error.connect(_on_ai_test_error)
		if ai_manager.has_signal("ai_request_progress") and not ai_manager.ai_request_progress.is_connected(_on_ai_request_progress):
			ai_manager.ai_request_progress.connect(_on_ai_request_progress)
		load_current_settings()
	else:
		update_provider_ui()
	_apply_modern_styles()
	await get_tree().process_frame
	if save_button:
		save_button.grab_focus()
	if panel:
		UIStyleManager.fade_in(panel, 0.4)
func _rebuild_layout_into_tabs():
	if panel and original_scroll and panel.get_parent() == original_scroll:
		panel.reparent(self)
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel.offset_left = 0
		panel.offset_top = 0
		panel.offset_right = 0
		panel.offset_bottom = 0
	if original_scroll:
		original_scroll.visible = false
	if buttons_container:
		buttons_container.visible = false
	if main_vbox:
		main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for child in main_vbox.get_children():
			main_vbox.remove_child(child)
		var global_settings = VBoxContainer.new()
		global_settings.name = "GlobalSettings"
		global_settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		global_settings.add_theme_constant_override("separation", 10)
		var global_margin = MarginContainer.new()
		global_margin.add_theme_constant_override("margin_top", 10)
		global_margin.add_theme_constant_override("margin_left", 10)
		global_margin.add_theme_constant_override("margin_right", 10)
		global_margin.add_theme_constant_override("margin_bottom", 5)
		global_margin.add_child(global_settings)
		main_vbox.add_child(global_margin)
		_move_control(provider_label, global_settings)
		_move_control(provider_option, global_settings)
		_move_control(provider_status_label, global_settings)
		_move_control(test_button, global_settings)
		_move_control(status_label, global_settings)
		tab_container = TabContainer.new()
		tab_container.name = "AISettingsTabs"
		tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		main_vbox.add_child(tab_container)
		if buttons_container:
			if buttons_container.get_parent():
				buttons_container.get_parent().remove_child(buttons_container)
			main_vbox.add_child(buttons_container)
			buttons_container.visible = true
	tab_gemini = _create_tab_page("Gemini")
	tab_safety = _create_tab_page("Safety")
	tab_openrouter = _create_tab_page("OpenRouter")
	tab_ollama = _create_tab_page("Ollama")
	tab_memory = _create_tab_page("Memory")
	tab_behavior = _create_tab_page("Behavior")
	tab_metrics = _create_tab_page("Metrics")
	safety_level_label = Label.new()
	safety_level_label.name = "SafetyLevelLabel"
	tab_safety.add_child(safety_level_label)
	safety_level_option = OptionButton.new()
	safety_level_option.name = "SafetyLevelOption"
	safety_level_option.add_item("Game Mode (Block None) - Recommended")
	safety_level_option.add_item("Low Blocking (Block Few)")
	safety_level_option.add_item("Standard (Default)")
	safety_level_option.add_item("High Blocking (Strict)")
	tab_safety.add_child(safety_level_option)
	safety_hint_label = Label.new()
	safety_hint_label.name = "SafetyHintLabel"
	safety_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	safety_hint_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	tab_safety.add_child(safety_hint_label)
	_move_control(gemini_label, tab_gemini)
	_move_control(gemini_key_input, tab_gemini)
	_move_control(gemini_hint_label, tab_gemini)
	_move_control(gemini_model_label, tab_gemini)
	_move_control(gemini_model_option, tab_gemini)
	_move_control(gemini_disabled_label, tab_gemini)
	_move_control(openrouter_label, tab_openrouter)
	_move_control(openrouter_key_input, tab_openrouter)
	_move_control(openrouter_hint_label, tab_openrouter)
	_move_control(openrouter_model_label, tab_openrouter)
	_move_control(openrouter_model_input, tab_openrouter)
	_move_control(openrouter_disabled_label, tab_openrouter)
	_move_control(ollama_header_label, tab_ollama)
	_move_control(ollama_info_label, tab_ollama)
	_move_control(ollama_host_label, tab_ollama)
	_move_control(ollama_host_input, tab_ollama)
	_move_control(ollama_port_label, tab_ollama)
	_move_control(ollama_port_spin, tab_ollama)
	_move_control(ollama_model_label, tab_ollama)
	_move_control(ollama_model_input, tab_ollama)
	_move_control(ollama_use_chat_check, tab_ollama)
	_move_control(ollama_options_label, tab_ollama)
	_move_control(ollama_options_input, tab_ollama)
	_move_control(ollama_hint_label, tab_ollama)
	_move_control(ollama_disabled_label, tab_ollama)
	_move_control(memory_settings_label, tab_memory)
	_move_control(memory_hint_label, tab_memory)
	_add_separator(tab_memory)
	_move_control(memory_limit_container, tab_memory)
	_move_control(memory_summary_container, tab_memory)
	_move_control(memory_full_container, tab_memory)
	_add_separator(tab_memory)
	_move_control(context_layers_label, tab_memory)
	_move_control(context_panel, tab_memory)
	if context_panel:
		context_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		context_panel.custom_minimum_size.y = 200
	_move_control(ai_tone_style_label, tab_behavior)
	_move_control(ai_tone_style_input, tab_behavior)
	_move_control(metrics_label, tab_metrics)
	_move_control(metrics_chart_container, tab_metrics)
	if metrics_chart_container:
		metrics_chart_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		metrics_chart_container.custom_minimum_size.y = 200
	_move_control(last_response_time_label, tab_metrics)
	_move_control(total_api_calls_label, tab_metrics)
	_move_control(total_tokens_used_label, tab_metrics)
	_move_control(last_input_tokens_label, tab_metrics)
	_move_control(last_output_tokens_label, tab_metrics)
func _create_tab_page(tab_name: String) -> VBoxContainer:
	var scroll = ScrollContainer.new()
	scroll.name = tab_name + "Scroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vbox = VBoxContainer.new()
	vbox.name = tab_name + "VBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 15)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	margin.add_child(vbox)
	tab_container.add_child(scroll)
	return vbox
func _move_control(node: Control, new_parent: Control):
	if node:
		if node.get_parent():
			node.get_parent().remove_child(node)
		new_parent.add_child(node)
		node.visible = true 
func _add_separator(parent: Control):
	var sep = HSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.3)
	parent.add_child(sep)
func _apply_modern_styles():
	if panel:
		var style = UIStyleManager.create_panel_style(0.98, 0)
		panel.add_theme_stylebox_override("panel", style)
	if save_button:
		UIStyleManager.apply_button_style(save_button, "primary", "large")
		UIStyleManager.add_hover_scale_effect(save_button)
	if back_button:
		UIStyleManager.apply_button_style(back_button, "secondary", "medium")
		UIStyleManager.add_hover_scale_effect(back_button)
	if home_button:
		UIStyleManager.apply_button_style(home_button, "secondary", "medium")
		UIStyleManager.add_hover_scale_effect(home_button)
	if test_button:
		UIStyleManager.apply_button_style(test_button, "accent", "medium")
		UIStyleManager.add_press_feedback(test_button)
	var inputs = [gemini_key_input, openrouter_key_input, openrouter_model_input, ollama_host_input, ollama_model_input, ai_tone_style_input]
	for input in inputs:
		if input:
			pass
func _exit_tree() -> void:
	if ai_manager:
		if ai_manager.ai_response_received.is_connected(_on_ai_test_success):
			ai_manager.ai_response_received.disconnect(_on_ai_test_success)
		if ai_manager.ai_error.is_connected(_on_ai_test_error):
			ai_manager.ai_error.disconnect(_on_ai_test_error)
		if ai_manager.has_signal("ai_request_progress") and ai_manager.ai_request_progress.is_connected(_on_ai_request_progress):
			ai_manager.ai_request_progress.disconnect(_on_ai_request_progress)
func _configure_provider_widgets() -> void:
	if not _gemini_inputs.is_empty():
		return
	_gemini_inputs = [gemini_key_input, gemini_model_option]
	_gemini_visuals = [gemini_label, gemini_key_input, gemini_hint_label, gemini_model_label, gemini_model_option]
	_openrouter_inputs = [openrouter_key_input, openrouter_model_input]
	_openrouter_visuals = [openrouter_label, openrouter_key_input, openrouter_hint_label, openrouter_model_label, openrouter_model_input]
	_ollama_inputs = [ollama_host_input, ollama_port_spin, ollama_model_input, ollama_use_chat_check, ollama_options_input]
	_ollama_visuals = [
		ollama_header_label,
		ollama_info_label,
		ollama_host_label,
		ollama_host_input,
		ollama_port_label,
		ollama_port_spin,
		ollama_model_label,
		ollama_model_input,
		ollama_use_chat_check,
		ollama_options_label,
		ollama_options_input,
		ollama_hint_label,
	]
func _set_provider_section_state(inputs: Array, visuals: Array, disabled_label: Label, is_active: bool) -> void:
	for control in inputs:
		if control is LineEdit:
			(control as LineEdit).editable = is_active
		elif control is TextEdit:
			(control as TextEdit).editable = is_active
		elif control is SpinBox:
			(control as SpinBox).editable = is_active
		elif control is OptionButton:
			(control as OptionButton).disabled = not is_active
		elif control is CheckBox:
			(control as CheckBox).disabled = not is_active
		if control is Control:
			var ctrl := control as Control
			ctrl.mouse_filter = Control.MOUSE_FILTER_STOP if is_active else Control.MOUSE_FILTER_IGNORE
			if not is_active and ctrl.is_inside_tree():
				ctrl.release_focus()
	for item in visuals:
		if item is CanvasItem:
			(item as CanvasItem).modulate = _ACTIVE_MODULATE if is_active else _INACTIVE_MODULATE
	if is_active:
		disabled_label.text = ""
		disabled_label.visible = false
	else:
		disabled_label.text = _DISABLED_MESSAGE
		disabled_label.visible = true
func _get_provider_display_name(provider: int) -> String:
	match provider:
		AIManager.AIProvider.GEMINI:
			return "Google Gemini"
		AIManager.AIProvider.OPENROUTER:
			return "OpenRouter"
		AIManager.AIProvider.OLLAMA:
			return "Ollama (Local)"
	return "Unknown"
func update_provider_ui() -> void:
	_configure_provider_widgets()
	var selected := provider_option.selected
	_set_provider_section_state(_gemini_inputs, _gemini_visuals, gemini_disabled_label, true)
	_set_provider_section_state(_openrouter_inputs, _openrouter_visuals, openrouter_disabled_label, true)
	_set_provider_section_state(_ollama_inputs, _ollama_visuals, ollama_disabled_label, true)
	gemini_disabled_label.visible = false
	openrouter_disabled_label.visible = false
	ollama_disabled_label.visible = false
	var provider_name := _get_provider_display_name(selected)
	if selected == AIManager.AIProvider.OLLAMA:
		provider_name = _decorate_ollama_provider_label(provider_name)
	provider_status_label.text = "Currently using: %s" % provider_name
func _decorate_ollama_provider_label(base_label: String) -> String:
	var model_text := ollama_model_input.text.strip_edges()
	var fallback_port := _clamp_port(int(ollama_port_spin.value))
	var parsed := _parse_ollama_url(ollama_host_input.text, fallback_port)
	if not parsed.get("ok", false):
		ollama_disabled_label.visible = true
		ollama_disabled_label.text = parsed.get("error", _OLLAMA_SETUP_REQUIRED)
		return base_label + _OLLAMA_SETUP_SUFFIX
	var host_text := String(parsed.get("host", ""))
	var port_value := int(parsed.get("port", fallback_port))
	if host_text.is_empty() or model_text.is_empty() or port_value <= 0:
		ollama_disabled_label.visible = true
		ollama_disabled_label.text = _OLLAMA_SETUP_REQUIRED
		return base_label + _OLLAMA_SETUP_SUFFIX
	if not ai_manager:
		ollama_disabled_label.visible = false
		ollama_disabled_label.text = ""
		return base_label
	var is_ready: bool = ai_manager.is_ollama_ready()
	if is_ready:
		ollama_disabled_label.visible = false
		ollama_disabled_label.text = ""
		return base_label + _OLLAMA_READY_SUFFIX
	var host_display: String = ai_manager.ollama_host.strip_edges()
	if host_display.is_empty():
		host_display = host_text
	var port_display: int = ai_manager.ollama_port
	if port_display <= 0:
		port_display = port_value
	ollama_disabled_label.visible = true
	ollama_disabled_label.text = _OLLAMA_OFFLINE_TEMPLATE % [host_display, port_display]
	return base_label + _OLLAMA_OFFLINE_SUFFIX
func _update_ui_labels():
	if tab_container:
		tab_container.set_tab_title(0, "Gemini")
		tab_container.set_tab_title(1, "Safety" if current_language == "en" else "安全設定")
		tab_container.set_tab_title(2, "OpenRouter")
		tab_container.set_tab_title(3, "Ollama")
		tab_container.set_tab_title(4, "Memory" if current_language == "en" else "記憶")
		tab_container.set_tab_title(5, "Behavior" if current_language == "en" else "行為")
		tab_container.set_tab_title(6, "Metrics" if current_language == "en" else "指標")
	if current_language == "en":
		if safety_level_label: safety_level_label.text = "Gemini Safety Filter Level:"
		if safety_hint_label: safety_hint_label.text = "Controls how strictly the AI filters content. 'Game Mode' is recommended to allow dramatic storytelling, conflict, and dark humor without being blocked."
		if safety_level_option:
			safety_level_option.set_item_text(0, "Game Mode (Block None) - Recommended")
			safety_level_option.set_item_text(1, "Low Blocking")
			safety_level_option.set_item_text(2, "Standard (Default)")
			safety_level_option.set_item_text(3, "Strict (High Blocking)")
	else:
		if safety_level_label: safety_level_label.text = "Gemini 安全過濾等級："
		if safety_hint_label: safety_hint_label.text = "控制 AI 過濾內容的嚴格程度。建議使用「遊戲模式」，以允許戲劇性的故事、衝突和黑色幽默，而不被系統攔截。"
		if safety_level_option:
			safety_level_option.set_item_text(0, "遊戲模式 (不攔截) - 推薦")
			safety_level_option.set_item_text(1, "低度攔截")
			safety_level_option.set_item_text(2, "標準 (預設)")
			safety_level_option.set_item_text(3, "嚴格 (高度攔截)")
	ollama_header_label.text = "Configure Ollama"
	ollama_info_label.text = "Provide the local Ollama service URL and model tag. Default URL: http://127.0.0.1:11434"
	ollama_host_label.text = "Ollama URL:"
	ollama_port_label.text = "Ollama Port:"
	ollama_model_label.text = "Ollama Model Tag:"
	ollama_use_chat_check.text = "Use /api/chat streaming endpoint"
	if ollama_host_input:
		ollama_host_input.placeholder_text = DEFAULT_OLLAMA_URL
	ollama_hint_label.text = "Edit advanced sampling options in the JSON block below (temperature, top_p, num_predict, context, etc.)."
	ollama_options_label.text = "Ollama Options (JSON):"
	if current_language == "en":
		memory_settings_label.text = "Memory Settings"
		memory_hint_label.text = "Configure how the AI remembers past conversations. Higher values use more tokens."
		memory_limit_label.text = "Max Memory:"
		memory_summary_label.text = "Summary Threshold:"
		memory_full_label.text = "Full Retention:"
		context_layers_label.text = "Context Layers"
		long_term_header.text = "Long-term Summaries"
		notes_header.text = "Tracked Notes"
		if provider_label: provider_label.text = "AI Provider:"
		gemini_label.text = "Google Gemini API Key:"
		gemini_hint_label.text = "Get your key from: https://makersuite.google.com/app/apikey"
		gemini_model_label.text = "Gemini Model:"
		openrouter_label.text = "OpenRouter API Key:"
		openrouter_hint_label.text = "Get your key from: https://openrouter.ai/keys"
		openrouter_model_label.text = "OpenRouter Model:"
		test_button.text = "TEST CONNECTION"
		save_button.text = "SAVE"
		back_button.text = "BACK"
		home_button.text = "HOME"
		memory_limit_spin.suffix = " items"
		memory_summary_spin.suffix = " items"
		memory_full_spin.suffix = " items"
		metrics_label.text = "AI Metrics"
		last_response_time_label.text = "Last Response Time:"
		total_api_calls_label.text = "Total API Calls:"
		total_tokens_used_label.text = "Total Tokens Used:"
		last_input_tokens_label.text = "Last Input Tokens:"
		last_output_tokens_label.text = "Last Output Tokens:"
		ai_tone_style_label.text = "AI Tone Style:"
		ai_tone_style_input.placeholder_text = "e.g., Maintain a tone of dark humor and calm irony."
	else: 
		memory_settings_label.text = "記憶設定"
		memory_hint_label.text = "設定 AI 如何記憶過往對話。數值越高，消耗的 token 越多。"
		memory_limit_label.text = "最大記憶："
		memory_summary_label.text = "摘要門檻："
		memory_full_label.text = "完整保留："
		context_layers_label.text = "情境層"
		long_term_header.text = "長期摘要"
		notes_header.text = "備忘事項"
		if provider_label: provider_label.text = "AI 提供者："
		gemini_label.text = "Google Gemini API 金鑰："
		gemini_hint_label.text = "從這裡獲取金鑰：https://makersuite.google.com/app/apikey"
		gemini_model_label.text = "Gemini 模型："
		openrouter_label.text = "OpenRouter API 金鑰："
		openrouter_hint_label.text = "從這裡獲取金鑰：https://openrouter.ai/keys"
		openrouter_model_label.text = "OpenRouter 模型："
		test_button.text = "測試連線"
		save_button.text = "儲存"
		back_button.text = "返回"
		home_button.text = "主頁"
		memory_limit_spin.suffix = " 條"
		memory_summary_spin.suffix = " 條"
		memory_full_spin.suffix = " 條"
		metrics_label.text = "AI 指標"
		last_response_time_label.text = "上次回應時間："
		total_api_calls_label.text = "總 API 調用次數："
		total_tokens_used_label.text = "總 Token 使用量："
		last_input_tokens_label.text = "上次輸入 Token："
		last_output_tokens_label.text = "上次輸出 Token："
		ai_tone_style_label.text = "AI 回應風格："
		ai_tone_style_input.placeholder_text = "例如：保持黑色幽默和冷靜諷刺的語氣。"
	_refresh_context_layers()
func _update_metrics_display():
	if ai_manager:
		var metrics = ai_manager.get_ai_metrics()
		var last_metrics = ai_manager.get_prompt_metrics()
		last_response_time_label.text = ("%s %.2f s" % [tr("Last Response Time:"), metrics.get("last_response_time", 0.0)])
		total_api_calls_label.text = ("%s %d" % [tr("Total API Calls:"), metrics.get("total_api_calls", 0)])
		total_tokens_used_label.text = ("%s %d" % [tr("Total Tokens Used:"), metrics.get("total_tokens_consumed", 0)])
		var input_tokens = int(metrics.get("last_input_tokens", 0))
		var output_tokens = int(metrics.get("last_output_tokens", 0))
		var tps = float(last_metrics.get("tps", 0.0))
		last_input_tokens_label.text = ("%s %d" % [tr("Last Input Tokens:"), input_tokens])
		last_output_tokens_label.text = ("%s %d" % [tr("Last Output Tokens:"), output_tokens])
		if tps > 0:
			last_output_tokens_label.text += " (%.1f T/s)" % tps
	if ai_metrics_chart:
		ai_metrics_chart.set_data(ai_manager.get_response_time_history(), ai_manager.get_token_usage_history())
	_refresh_context_layers()
func _refresh_context_layers():
	var language = current_language
	var summary_count = 0
	var notes_count = 0
	var summary_lines: Array = []
	var note_lines: Array = []
	if ai_manager:
		summary_count = ai_manager.get_long_term_summary_count()
		notes_count = ai_manager.get_note_count()
		summary_lines = ai_manager.get_long_term_lines(language, 12)
		note_lines = ai_manager.get_notes_lines(language, 12)
	if language == "en":
		long_term_header.text = "Long-term Summaries (%d)" % summary_count
		notes_header.text = "Tracked Notes (%d)" % notes_count
	else:
		long_term_header.text = "長期摘要（%d）" % summary_count
		notes_header.text = "備忘事項（%d）" % notes_count
	if summary_lines.is_empty():
		long_term_text.text = "[i]%s[/i]" % ("No summaries captured yet." if language == "en" else "尚未產生摘要。")
	else:
		var builder := ""
		for i in range(summary_lines.size()):
			builder += "%d. %s\n" % [i + 1, summary_lines[i]]
		long_term_text.text = builder.strip_edges()
	if note_lines.is_empty():
		notes_text.text = "[i]%s[/i]" % ("No notes recorded." if language == "en" else "尚未記錄備忘。")
	else:
		var note_builder := ""
		for line in note_lines:
			note_builder += "- %s\n" % line
		notes_text.text = note_builder.strip_edges()
	update_provider_ui()
func load_current_settings():
	if not ai_manager:
		return
	provider_option.selected = ai_manager.current_provider
	gemini_key_input.text = ai_manager.gemini_api_key
	openrouter_key_input.text = ai_manager.openrouter_api_key
	var gemini_display = [
		"gemini-3-pro-preview",
		"gemini-2.5-pro",
		"gemini-2.5-flash-native-audio-preview-09-2025",
		"gemini-flash-latest",
		"gemini-2.5-flash-lite",
	]
	var gemini_values = [
		"gemini-3-pro-preview",
		"gemini-2.5-pro",
		"gemini-2.5-flash-native-audio-preview-09-2025",
		"gemini-flash-latest",
		"gemini-2.5-flash-lite",
	]
	var option = gemini_model_option
	if option:
		option.clear()
		for display_label in gemini_display:
			option.add_item(display_label)
	var gemini_index = gemini_values.find(ai_manager.gemini_model)
	if gemini_index >= 0 and option:
		option.selected = gemini_index
	if safety_level_option:
		var current_safety = ai_manager.gemini_safety_settings
		match current_safety:
			"BLOCK_NONE": safety_level_option.selected = 0
			"BLOCK_ONLY_HIGH": safety_level_option.selected = 1
			"BLOCK_MEDIUM_AND_ABOVE": safety_level_option.selected = 2
			"BLOCK_LOW_AND_ABOVE": safety_level_option.selected = 3
			_: safety_level_option.selected = 0
	openrouter_model_input.text = ai_manager.openrouter_model
	var parsed_url := _parse_ollama_url(ai_manager.ollama_host, ai_manager.ollama_port)
	if parsed_url.get("ok", false):
		ollama_host_input.text = String(parsed_url.get("url", DEFAULT_OLLAMA_URL))
		ollama_port_spin.value = int(parsed_url.get("port", ai_manager.ollama_port))
	else:
		ollama_host_input.text = _build_ollama_url(ai_manager.ollama_host, ai_manager.ollama_port)
		ollama_port_spin.value = ai_manager.ollama_port
	ollama_model_input.text = ai_manager.ollama_model
	ollama_use_chat_check.button_pressed = ai_manager.ollama_use_chat
	var options_json := JSON.stringify(ai_manager.ollama_options, "  ")
	ollama_options_input.text = options_json
	ai_tone_style_input.text = ai_manager.custom_ai_tone_style
	if ai_manager.memory_store:
		memory_limit_spin.value = ai_manager.memory_store.max_memory_items
		memory_summary_spin.value = ai_manager.memory_store.memory_summary_threshold
		memory_full_spin.value = ai_manager.memory_store.memory_full_entries
	else:
		memory_limit_spin.value = memory_limit_spin.min_value
		memory_summary_spin.value = memory_summary_spin.min_value
		memory_full_spin.value = memory_full_spin.min_value
	_sync_memory_spinners()
	update_provider_ui()
func _on_provider_changed(index: int):
	update_provider_ui()
	if ai_manager:
		ai_manager.current_provider = index
		update_status("Provider changed. Remember to save!")
func _on_test_button_pressed():
	if not ai_manager:
		update_status("Error: AI Manager not found!", true)
		return
	if not save_ui_to_manager():
		return
	var use_mock := false
	var status_message := "Testing connection..."
	match ai_manager.current_provider:
		AIManager.AIProvider.GEMINI:
			use_mock = ai_manager.gemini_api_key.strip_edges().is_empty()
			if use_mock:
				status_message = "Testing offline mock response..."
		AIManager.AIProvider.OPENROUTER:
			use_mock = ai_manager.openrouter_api_key.strip_edges().is_empty()
			if use_mock:
				status_message = "Testing offline mock response..."
		AIManager.AIProvider.OLLAMA:
			if not OllamaClient.health_check(1.0, true):
				update_status("Ollama service unavailable. Start the local server first.", true)
				return
			var tags_result: Dictionary = OllamaClient.fetch_tags(2.0, true)
			if not tags_result.get("ok", false):
				var tags_error := str(tags_result.get("error", "Unable to query models."))
				var status_code := int(tags_result.get("status_code", 0))
				if status_code > 0:
					tags_error += " (HTTP %d)" % status_code
				update_status("Connected to Ollama but could not list models: %s" % tags_error, true)
				return
			var normalized_model: String = ai_manager.ollama_model.strip_edges()
			var models: Array = tags_result.get("models", [])
			var model_found: bool = normalized_model.is_empty()
			if models is Array and not normalized_model.is_empty():
				for entry in models:
					if entry is Dictionary:
						var model_name := str(entry.get("name", entry.get("model", ""))).strip_edges()
						if model_name == normalized_model:
							model_found = true
							break
					else:
						if str(entry).strip_edges() == normalized_model:
							model_found = true
							break
			if not model_found:
				update_status("Ollama is running but model '%s' is not installed. Run 'ollama pull %s' and try again." % [normalized_model, normalized_model], true)
				return
			status_message = "Testing local Ollama service..."
			use_mock = false
		_:
			use_mock = true
			status_message = "Testing offline mock response..."
	update_status(status_message, false)
	var test_prompt = "Hello, AI! Are you there?" if current_language == "en" else "你好，AI！你在嗎？"
	ai_manager.generate_story(test_prompt, { "purpose": "test", "force_mock": use_mock })
func _on_ai_test_success(response):
	var display_text = ""
	if typeof(response) == TYPE_DICTIONARY:
		if response.has("content"):
			display_text = str(response["content"])
		elif response.has("error"):
			display_text = "(error) " + str(response["error"])
	elif typeof(response) == TYPE_STRING:
		display_text = response
	update_status("✓ Connection successful!", false)
	print("AI Test Response: ", display_text)
func _on_ai_test_error(error_message: String):
	update_status("✗ Error: " + error_message, true)
func _on_ai_request_progress(update: Dictionary) -> void:
	if not ai_manager:
		return
	var provider: int = int(update.get("provider", ai_manager.current_provider))
	if provider != AIManager.AIProvider.OLLAMA:
		return
	var status: String = str(update.get("status", ""))
	var model: String = str(update.get("model", ai_manager.ollama_model))
	var host: String = str(update.get("host", ai_manager.ollama_host))
	var port: int = int(update.get("port", ai_manager.ollama_port))
	var elapsed: float = float(update.get("elapsed_sec", 0.0))
	var tokens: int = 0
	if update.has("partial_tokens"):
		tokens = int(update["partial_tokens"])
	elif update.has("response_tokens"):
		tokens = int(update["response_tokens"])
	var is_error := false
	var message := ""
	match status:
		"queued":
			message = "Queued local Ollama request for '%s' (%s:%d)..." % [model, host, port]
		"started":
			message = "Contacted Ollama at %s:%d. Awaiting first tokens..." % [host, port]
		"stream":
			message = "Streaming from Ollama... ~%d tokens (%.1f s elapsed)." % [tokens, elapsed]
			var chunk_preview: String = str(update.get("last_chunk", "")).strip_edges()
			if chunk_preview.length() > 0:
				if chunk_preview.length() > 60:
					chunk_preview = chunk_preview.substr(0, 60) + "..."
				message += "\nLast chunk: \"%s\"" % chunk_preview
		"timeout":
			var attempt := int(update.get("attempt", 1))
			message = "Ollama timed out after %.1f s. Retrying (attempt %d)..." % [elapsed, attempt]
			is_error = true
		"error":
			var reason: String = str(update.get("reason", "unknown error"))
			message = "Ollama reported an error: %s" % reason
			is_error = true
		"completed":
			message = "Ollama completed in %.1f s (~%d tokens)." % [elapsed, tokens]
		_:
			return
	update_status(message, is_error)
func _on_save_button_pressed():
	if not ai_manager:
		update_status("Error: AI Manager not found!", true, true)
		return
	if not save_ui_to_manager():
		return
	if ai_manager.has_method("_sync_gemini_provider"):
		ai_manager._sync_gemini_provider()
	if ai_manager.has_method("_sync_openrouter_provider"):
		ai_manager._sync_openrouter_provider()
	if ai_manager.has_method("_sync_ollama_provider"):
		ai_manager._sync_ollama_provider()
	ai_manager.save_ai_settings()
	update_status("✓ Settings saved successfully!", false, true)
	await get_tree().create_timer(1.0).timeout
	_on_back_button_pressed()
func save_ui_to_manager() -> bool:
	if not ai_manager:
		update_status("Error: AI Manager not found!", true, true)
		return false
	_sync_memory_spinners()
	ai_manager.current_provider = provider_option.selected
	var gemini_key_value := gemini_key_input.text.strip_edges()
	if not gemini_key_value.is_empty():
		if gemini_key_value.begins_with("http://") or gemini_key_value.begins_with("https://"):
			update_status("Invalid Gemini API key: appears to be a URL. Please enter the actual API key string.", true, true)
			return false
	ai_manager.gemini_api_key = gemini_key_value
	var gemini_values = [
		"gemini-3-pro-preview",
		"gemini-2.5-pro",
		"gemini-2.5-flash-native-audio-preview-09-2025",
		"gemini-flash-latest",
		"gemini-2.5-flash-lite",
	]
	var gemini_selected = gemini_model_option.selected
	if gemini_selected >= 0 and gemini_selected < gemini_values.size():
		ai_manager.gemini_model = gemini_values[gemini_selected]
	if safety_level_option:
		match safety_level_option.selected:
			0: ai_manager.gemini_safety_settings = "BLOCK_NONE"
			1: ai_manager.gemini_safety_settings = "BLOCK_ONLY_HIGH"
			2: ai_manager.gemini_safety_settings = "BLOCK_MEDIUM_AND_ABOVE"
			3: ai_manager.gemini_safety_settings = "BLOCK_LOW_AND_ABOVE"
			_: ai_manager.gemini_safety_settings = "BLOCK_NONE"
	ai_manager.openrouter_api_key = openrouter_key_input.text
	ai_manager.openrouter_model = openrouter_model_input.text
	var fallback_port := _clamp_port(int(ollama_port_spin.value))
	var parsed_url := _parse_ollama_url(ollama_host_input.text, fallback_port)
	if not parsed_url.get("ok", false):
		update_status(parsed_url.get("error", "Invalid Ollama URL."), true, true)
		return false
	var host_text := String(parsed_url.get("host", "127.0.0.1"))
	var scheme := String(parsed_url.get("scheme", "http"))
	var use_port := fallback_port
	if parsed_url.get("explicit_port", false):
		use_port = int(parsed_url.get("port", fallback_port))
	var normalized_url := _build_ollama_url(host_text, use_port, scheme)
	ollama_host_input.text = normalized_url
	ollama_port_spin.value = use_port
	ai_manager.ollama_host = host_text
	ai_manager.ollama_port = use_port
	var model_text := ollama_model_input.text.strip_edges()
	if model_text.is_empty():
		model_text = ai_manager.ollama_model
		ollama_model_input.text = model_text
	ai_manager.ollama_model = model_text
	var options_text := ollama_options_input.text.strip_edges()
	if not options_text.is_empty():
		var json := JSON.new()
		var parse_err := json.parse(options_text)
		if parse_err != OK:
			update_status("Invalid Ollama options JSON (error %d)." % parse_err, true, true)
			return false
		if not (json.data is Dictionary):
			update_status("Ollama options must be a JSON object.", true, true)
			return false
		ai_manager.ollama_options = (json.data as Dictionary).duplicate(true)
	ai_manager.ollama_use_chat = ollama_use_chat_check.button_pressed
	if ai_manager.has_method("_apply_ollama_configuration"):
		ai_manager._apply_ollama_configuration()
	ai_manager.custom_ai_tone_style = ai_tone_style_input.text
	if ai_manager.memory_store:
		ai_manager.memory_store.max_memory_items = int(memory_limit_spin.value)
		ai_manager.memory_store.memory_summary_threshold = int(memory_summary_spin.value)
		ai_manager.memory_store.memory_full_entries = int(memory_full_spin.value)
		ai_manager.apply_memory_settings()
	update_provider_ui()
	return true
func _on_back_button_pressed():
	var tree := get_tree()
	if not tree:
		return
	tree.paused = false
	tree.change_scene_to_file("res://1.Codebase/src/scenes/ui/settings_menu.tscn")
func _on_home_button_pressed():
	var tree := get_tree()
	if not tree:
		return
	tree.paused = false
	tree.change_scene_to_file("res://1.Codebase/menu_main.tscn")
func update_status(message: String, is_error: bool = false, emit_notification: bool = false):
	if not status_label:
		return
	status_label.text = "Status: " + message
	if is_error:
		status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	if emit_notification:
		_show_notification(message, is_error)
func _show_notification(message: String, is_error: bool) -> void:
	var notifier = ServiceLocator.get_notification_system() if ServiceLocator else null
	if notifier == null:
		return
	if is_error:
		notifier.show_error(message)
	else:
		notifier.show_success(message)
func _sync_memory_spinners() -> void:
	memory_limit_spin.step = 10
	memory_summary_spin.max_value = memory_limit_spin.value
	memory_full_spin.max_value = memory_limit_spin.value
	if memory_full_spin.value > memory_limit_spin.value:
		memory_full_spin.value = memory_limit_spin.value
	if memory_summary_spin.value > memory_limit_spin.value:
		memory_summary_spin.value = memory_limit_spin.value
	if memory_summary_spin.value < memory_full_spin.value:
		memory_summary_spin.value = memory_full_spin.value
	memory_summary_spin.min_value = memory_full_spin.value
func _on_memory_limit_value_changed(_value: float) -> void:
	_sync_memory_spinners()
func _on_memory_full_value_changed(value: float) -> void:
	if memory_summary_spin.value < value:
		memory_summary_spin.value = value
	_sync_memory_spinners()
