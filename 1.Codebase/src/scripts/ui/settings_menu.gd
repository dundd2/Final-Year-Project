extends Control
const EXIT_MODE_MAIN_MENU := 0
const EXIT_MODE_OVERLAY := 1
@warning_ignore("shadowed_global_identifier")
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const ICON_CHECK = preload("res://1.Codebase/src/assets/ui/icon_check.svg")
const ICON_BACK = preload("res://1.Codebase/src/assets/ui/icon_back.svg")
const ICON_DELETE = preload("res://1.Codebase/src/assets/ui/icon_delete.svg")
const ICON_CREATIVE = preload("res://1.Codebase/src/assets/ui/icon_creative.svg")
const ICON_MIC = preload("res://1.Codebase/src/assets/ui/icon_mic.svg")
signal close_requested
var selected_resolution: Vector2i = Vector2i(1024, 600)
var selected_mode: int = 0 
var selected_language: String = "en" 
var selected_font_size: int = 2 
var master_volume: float = 100.0
var music_volume: float = 100.0
var sfx_volume: float = 100.0
var is_muted: bool = false
var touch_controls_enabled: bool = false
var text_speed: float = 1.0 
var screen_shake_enabled: bool = true
var auto_advance_enabled: bool = false
var high_contrast_mode: bool = false
var voice_enabled: bool = false
var voice_output_enabled: bool = false
var voice_input_enabled: bool = false
var voice_volume: float = 80.0
var voice_voice_name: String = "Aoede"
var voice_input_mode: int = 0
var voice_proactive_enabled: bool = false
var voice_supported: bool = false
var voice_capture_active: bool = false
var _exit_mode: int = EXIT_MODE_MAIN_MENU
const VOICE_VOICE_NAMES = [
	"Aoede",
	"Callisto",
	"Elektra",
	"Orion",
	"Sol",
]
const VOICE_INPUT_MODE_LABELS := {
	0: "Push to talk",
	1: "Continuous",
}
const VOICE_CAPTURE_SECONDS := 4.0
const GEMINI_RECOMMENDED_NATIVE_AUDIO_MODEL := "gemini-2.5-flash-native-audio-preview-12-2025"
var resolutions = {
	0: Vector2i(1024, 600),
	1: Vector2i(1280, 720),
	2: Vector2i(1600, 900),
	3: Vector2i(1920, 1080),
	4: Vector2i(2560, 1440),
}
@onready var menu_container = $MenuContainer
@onready var panel = $MenuContainer/Panel
@onready var main_vbox = $MenuContainer/Panel/VBoxContainer
@onready var original_scroll = $MenuContainer/Panel/VBoxContainer/ScrollContainer
@onready var original_settings_vbox = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox
@onready var buttons_container = $MenuContainer/Panel/VBoxContainer/ButtonsContainer
@onready var title_label = $MenuContainer/Panel/VBoxContainer/TitleLabel
@onready var back_button = $MenuContainer/Panel/VBoxContainer/ButtonsContainer/BackButton
@onready var apply_button = $MenuContainer/Panel/VBoxContainer/ButtonsContainer/ApplyButton
@onready var ai_settings_button = $MenuContainer/Panel/VBoxContainer/ButtonsContainer/AISettingsButton
@onready var delete_logs_button = $MenuContainer/Panel/VBoxContainer/ButtonsContainer/DeleteLogsButton
@onready var delete_logs_dialog = $MenuContainer/Panel/DeleteLogsDialog
@onready var resolution_label = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/ResolutionLabel
@onready var resolution_option = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/ResolutionOption
@onready var fullscreen_label = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/FullscreenLabel
@onready var fullscreen_option = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/FullscreenOption
@onready var font_size_label = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/FontSizeLabel
@onready var font_size_option = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/FontSizeOption
@onready var language_label = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/LanguageLabel
@onready var language_option = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/LanguageOption
@onready var master_volume_hbox = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/MasterVolumeHBox
@onready var music_volume_hbox = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/MusicVolumeHBox
@onready var sfx_volume_hbox = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/SFXVolumeHBox
@onready var mute_check_box = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/MuteCheckBox
@onready var voice_description = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/VoiceInfoPanel/VoiceInfoMargin/VoiceInfoVBox/VoiceDescription
@onready var voice_availability_label = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/VoiceInfoPanel/VoiceInfoMargin/VoiceInfoVBox/VoiceAvailabilityLabel
@onready var voice_enabled_check = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/VoiceOptionsPanel/VoiceOptionsMargin/VoiceOptionsContainer/VoiceEnabledCheck
@onready var voice_options_box = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/VoiceOptionsPanel/VoiceOptionsMargin/VoiceOptionsContainer/VoiceOptionsVBox
@onready var voice_output_check = voice_options_box.get_node("VoiceOutputCheck")
@onready var voice_input_check = voice_options_box.get_node("VoiceInputCheck")
@onready var voice_choice_label = voice_options_box.get_node("VoiceVoiceHBox/VoiceChoiceLabel")
@onready var voice_voice_option = voice_options_box.get_node("VoiceVoiceHBox/VoiceVoiceOption")
@onready var voice_volume_slider = voice_options_box.get_node("VoiceVolumeHBox/VoiceVolumeSlider")
@onready var voice_volume_value = voice_options_box.get_node("VoiceVolumeHBox/VoiceVolumeValue")
@onready var voice_volume_label = voice_options_box.get_node("VoiceVolumeHBox/VoiceVolumeLabel")
@onready var voice_input_mode_option = voice_options_box.get_node("VoiceInputModeHBox/VoiceInputModeOption")
@onready var voice_input_mode_label = voice_options_box.get_node("VoiceInputModeHBox/VoiceInputModeLabel")
@onready var voice_proactive_check = voice_options_box.get_node("VoiceProactiveCheck")
@onready var voice_preview_button = voice_options_box.get_node("VoiceTestButtonsHBox/VoicePreviewButton")
@onready var voice_capture_button = voice_options_box.get_node("VoiceTestButtonsHBox/VoiceCaptureButton")
@onready var voice_status_label = voice_options_box.get_node("VoiceStatusPanel/VoiceStatusMargin/VoiceStatusLabel")
@onready var touch_controls_checkbox = $MenuContainer/Panel/VBoxContainer/ScrollContainer/SettingsVBox/TouchControlsCheckBox
var tab_container: TabContainer
var tab_gameplay: VBoxContainer
var tab_display: VBoxContainer
var tab_audio: VBoxContainer
var tab_voice: VBoxContainer
var tab_tutorial: VBoxContainer
var tab_developer: VBoxContainer
var text_speed_label: Label
var text_speed_option: OptionButton
var screen_shake_check: CheckBox
var force_mission_complete_check: CheckBox
var force_gloria_button: Button
var force_gloria_status_label: Label
var force_trolley_button: Button
var force_trolley_status_label: Label
var force_honeymoon_check: CheckBox
var _gloria_triggered: bool = false
var _trolley_triggered: bool = false
var reality_score_label: Label
var reality_score_spinbox: SpinBox
var positive_energy_label: Label
var positive_energy_spinbox: SpinBox
var entropy_level_label: Label
var entropy_level_spinbox: SpinBox
var honeymoon_charges_label: Label
var honeymoon_charges_spinbox: SpinBox
var mission_turn_label: Label
var mission_turn_spinbox: SpinBox
var max_stats_button: Button
var reset_stats_button: Button
var clear_debuffs_button: Button
var skip_turn_button: Button
var add_honeymoon_button: Button
var autosave_toggle: CheckBox
var infinite_resources_toggle: CheckBox
var skip_dialogue_toggle: CheckBox
var god_mode_toggle: CheckBox
var tutorial_enabled_toggle: CheckBox
var tutorial_progress_label: Label
var reset_tutorials_button: Button
var tutorial_list_container: VBoxContainer
var _audio_manager: Node = null
func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_background_aliases()
	_enforce_fullscreen_layout()
	_rebuild_layout_into_tabs()
	load_settings()
	var current_size = DisplayServer.window_get_size()
	selected_resolution = Vector2i(current_size.x, current_size.y)
	var window_mode = DisplayServer.window_get_mode()
	if window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		selected_mode = 1
		fullscreen_option.selected = 1
	elif window_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		selected_mode = 1
		fullscreen_option.selected = 1
	elif window_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		selected_mode = 0
		fullscreen_option.selected = 0
	for key in resolutions:
		if resolutions[key] == selected_resolution:
			resolution_option.selected = key
			break
	selected_language = GameState.current_language if GameState else "en"
	if selected_language == "en":
		language_option.selected = 1
	else:
		language_option.selected = 0
	if FontManager:
		selected_font_size = FontManager.get_font_size()
		font_size_option.selected = selected_font_size
	if master_volume_hbox.has_node("MasterVolumeSlider"):
		var s = master_volume_hbox.get_node("MasterVolumeSlider")
		s.min_value = 0.0
		s.max_value = 100.0
		s.value = master_volume
	if music_volume_hbox.has_node("MusicVolumeSlider"):
		var s = music_volume_hbox.get_node("MusicVolumeSlider")
		s.min_value = 0.0
		s.max_value = 100.0
		s.value = music_volume
	if sfx_volume_hbox.has_node("SFXVolumeSlider"):
		var s = sfx_volume_hbox.get_node("SFXVolumeSlider")
		s.min_value = 0.0
		s.max_value = 100.0
		s.value = sfx_volume
	mute_check_box.button_pressed = is_muted
	_apply_audio_settings()
	_initialize_voice_controls()
	var touch_controls = get_tree().get_root().find_child("TouchControls", true, false)
	if touch_controls:
		if not touch_controls_checkbox.toggled.is_connected(self._on_touch_controls_toggled):
			touch_controls_checkbox.toggled.connect(self._on_touch_controls_toggled)
		touch_controls_checkbox.button_pressed = touch_controls_enabled
	else:
		touch_controls_checkbox.disabled = true
	_initialize_new_controls()
	update_ui_text()
	_apply_modern_styles()
	_style_delete_logs_dialog()
	UIStyleManager.fade_in($MenuContainer/Panel, 0.4)
	await get_tree().process_frame
	if apply_button:
		apply_button.grab_focus()
	_apply_exit_mode_state()
func _rebuild_layout_into_tabs():
	original_scroll.visible = false
	tab_container = TabContainer.new()
	tab_container.name = "SettingsTabs"
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var insert_idx = 1 
	main_vbox.add_child(tab_container)
	main_vbox.move_child(tab_container, insert_idx)
	tab_gameplay = _create_tab_page("Gameplay") 
	tab_display = _create_tab_page("Display")
	tab_audio = _create_tab_page("Audio")
	tab_voice = _create_tab_page("Voice")
	tab_tutorial = _create_tab_page("Tutorial")
	tab_developer = _create_tab_page("Developer")
	_move_control(language_label, tab_gameplay)
	_move_control(language_option, tab_gameplay)
	_add_separator(tab_gameplay)
	var gameplay_settings_box = VBoxContainer.new()
	gameplay_settings_box.name = "GameplayExtras"
	gameplay_settings_box.add_theme_constant_override("separation", 10)
	tab_gameplay.add_child(gameplay_settings_box)
	text_speed_label = Label.new()
	text_speed_option = OptionButton.new()
	screen_shake_check = CheckBox.new()
	gameplay_settings_box.add_child(text_speed_label)
	gameplay_settings_box.add_child(text_speed_option)
	gameplay_settings_box.add_child(screen_shake_check)
	_add_separator(tab_gameplay)
	_move_control(touch_controls_checkbox, tab_gameplay)
	_add_separator(tab_gameplay)
	_move_control(ai_settings_button, tab_gameplay)
	_move_control(delete_logs_button, tab_gameplay)
	_move_control(fullscreen_label, tab_display)
	_move_control(fullscreen_option, tab_display)
	_add_separator(tab_display)
	_move_control(resolution_label, tab_display)
	_move_control(resolution_option, tab_display)
	_add_separator(tab_display)
	_move_control(font_size_label, tab_display)
	_move_control(font_size_option, tab_display)
	_move_control(mute_check_box, tab_audio)
	_add_separator(tab_audio)
	_ensure_audio_label(master_volume_hbox, "MasterVolumeLabel")
	_move_control(master_volume_hbox, tab_audio)
	_ensure_audio_label(music_volume_hbox, "MusicVolumeLabel")
	_move_control(music_volume_hbox, tab_audio)
	_ensure_audio_label(sfx_volume_hbox, "SFXVolumeLabel")
	_move_control(sfx_volume_hbox, tab_audio)
	_move_control(voice_description, tab_voice)
	_move_control(voice_availability_label, tab_voice)
	_add_separator(tab_voice)
	_move_control(voice_enabled_check, tab_voice)
	_move_control(voice_options_box, tab_voice)
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
	if node and node.get_parent():
		node.get_parent().remove_child(node)
		new_parent.add_child(node)
		node.visible = true
func _add_separator(parent: Control):
	var sep = HSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.3)
	parent.add_child(sep)
func _initialize_new_controls():
	text_speed_option.add_item("Instant", 0) 
	text_speed_option.add_item("Fast", 1)    
	text_speed_option.add_item("Normal", 2)  
	text_speed_option.add_item("Slow", 3)    
	text_speed_option.item_selected.connect(_on_text_speed_selected)
	if text_speed == 0.0: text_speed_option.select(0)
	elif text_speed == 2.0: text_speed_option.select(1)
	elif text_speed == 1.0: text_speed_option.select(2)
	elif text_speed == 0.5: text_speed_option.select(3)
	else: text_speed_option.select(2) 
	screen_shake_check.toggled.connect(_on_screen_shake_toggled)
	screen_shake_check.button_pressed = screen_shake_enabled
	force_mission_complete_check = CheckBox.new()
	tab_developer.add_child(force_mission_complete_check)
	force_mission_complete_check.toggled.connect(_on_force_mission_complete_toggled)
	if GameState:
		force_mission_complete_check.button_pressed = GameState.debug_force_mission_complete
	var gloria_hbox = HBoxContainer.new()
	gloria_hbox.add_theme_constant_override("separation", 10)
	force_gloria_button = Button.new()
	force_gloria_button.text = "Force Gloria Intervention"
	force_gloria_button.custom_minimum_size = Vector2(250, 40)
	force_gloria_button.focus_mode = Control.FOCUS_NONE
	force_gloria_button.pressed.connect(_on_force_gloria_pressed)
	gloria_hbox.add_child(force_gloria_button)
	force_gloria_status_label = Label.new()
	force_gloria_status_label.text = ""
	force_gloria_status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	gloria_hbox.add_child(force_gloria_status_label)
	tab_developer.add_child(gloria_hbox)
	var trolley_hbox = HBoxContainer.new()
	trolley_hbox.add_theme_constant_override("separation", 10)
	force_trolley_button = Button.new()
	force_trolley_button.text = "Force Trolley Problem Now"
	force_trolley_button.custom_minimum_size = Vector2(250, 40)
	force_trolley_button.focus_mode = Control.FOCUS_NONE
	force_trolley_button.pressed.connect(_on_force_trolley_pressed)
	trolley_hbox.add_child(force_trolley_button)
	force_trolley_status_label = Label.new()
	force_trolley_status_label.text = ""
	force_trolley_status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	trolley_hbox.add_child(force_trolley_status_label)
	tab_developer.add_child(trolley_hbox)
	force_honeymoon_check = CheckBox.new()
	force_honeymoon_check.text = "Force Honeymoon Phase"
	tab_developer.add_child(force_honeymoon_check)
	force_honeymoon_check.toggled.connect(_on_force_honeymoon_toggled)
	if GameState:
		force_honeymoon_check.button_pressed = GameState.is_honeymoon_phase
	_add_separator(tab_developer)
	var reality_hbox = HBoxContainer.new()
	reality_hbox.add_theme_constant_override("separation", 10)
	reality_score_label = Label.new()
	reality_score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reality_hbox.add_child(reality_score_label)
	reality_score_spinbox = SpinBox.new()
	reality_score_spinbox.custom_minimum_size = Vector2(100, 0)
	reality_score_spinbox.min_value = 0
	reality_score_spinbox.max_value = 100
	reality_score_spinbox.step = 1
	if GameState:
		reality_score_spinbox.value = GameState.reality_score
	reality_hbox.add_child(reality_score_spinbox)
	tab_developer.add_child(reality_hbox)
	var positive_hbox = HBoxContainer.new()
	positive_hbox.add_theme_constant_override("separation", 10)
	positive_energy_label = Label.new()
	positive_energy_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	positive_hbox.add_child(positive_energy_label)
	positive_energy_spinbox = SpinBox.new()
	positive_energy_spinbox.custom_minimum_size = Vector2(100, 0)
	positive_energy_spinbox.min_value = 0
	positive_energy_spinbox.max_value = 100
	positive_energy_spinbox.step = 1
	if GameState:
		positive_energy_spinbox.value = GameState.positive_energy
	positive_hbox.add_child(positive_energy_spinbox)
	tab_developer.add_child(positive_hbox)
	var entropy_hbox = HBoxContainer.new()
	entropy_hbox.add_theme_constant_override("separation", 10)
	entropy_level_label = Label.new()
	entropy_level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entropy_hbox.add_child(entropy_level_label)
	entropy_level_spinbox = SpinBox.new()
	entropy_level_spinbox.custom_minimum_size = Vector2(100, 0)
	entropy_level_spinbox.min_value = 0
	entropy_level_spinbox.max_value = 100
	entropy_level_spinbox.step = 1
	if GameState:
		entropy_level_spinbox.value = GameState.entropy_level
	entropy_hbox.add_child(entropy_level_spinbox)
	tab_developer.add_child(entropy_hbox)
	var honeymoon_hbox = HBoxContainer.new()
	honeymoon_hbox.add_theme_constant_override("separation", 10)
	honeymoon_charges_label = Label.new()
	honeymoon_charges_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	honeymoon_hbox.add_child(honeymoon_charges_label)
	honeymoon_charges_spinbox = SpinBox.new()
	honeymoon_charges_spinbox.custom_minimum_size = Vector2(100, 0)
	honeymoon_charges_spinbox.min_value = 0
	honeymoon_charges_spinbox.max_value = 10
	honeymoon_charges_spinbox.step = 1
	if GameState:
		honeymoon_charges_spinbox.value = GameState.honeymoon_charges
	honeymoon_hbox.add_child(honeymoon_charges_spinbox)
	tab_developer.add_child(honeymoon_hbox)
	var mission_turn_hbox = HBoxContainer.new()
	mission_turn_hbox.add_theme_constant_override("separation", 10)
	mission_turn_label = Label.new()
	mission_turn_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mission_turn_hbox.add_child(mission_turn_label)
	mission_turn_spinbox = SpinBox.new()
	mission_turn_spinbox.custom_minimum_size = Vector2(100, 0)
	mission_turn_spinbox.min_value = 0
	mission_turn_spinbox.max_value = 100
	mission_turn_spinbox.step = 1
	if GameState:
		mission_turn_spinbox.value = GameState.mission_turn_count
	mission_turn_hbox.add_child(mission_turn_spinbox)
	tab_developer.add_child(mission_turn_hbox)
	reality_score_spinbox.value_changed.connect(_on_reality_score_changed)
	positive_energy_spinbox.value_changed.connect(_on_positive_energy_changed)
	entropy_level_spinbox.value_changed.connect(_on_entropy_level_changed)
	honeymoon_charges_spinbox.value_changed.connect(_on_honeymoon_charges_changed)
	mission_turn_spinbox.value_changed.connect(_on_mission_turn_changed)
	_add_separator(tab_developer)
	var quick_actions_label = Label.new()
	quick_actions_label.name = "QuickActionsLabel"
	quick_actions_label.add_theme_font_size_override("font_size", 20)
	quick_actions_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4))
	tab_developer.add_child(quick_actions_label)
	var quick_actions_grid = GridContainer.new()
	quick_actions_grid.columns = 2
	quick_actions_grid.add_theme_constant_override("h_separation", 10)
	quick_actions_grid.add_theme_constant_override("v_separation", 10)
	tab_developer.add_child(quick_actions_grid)
	max_stats_button = Button.new()
	max_stats_button.custom_minimum_size = Vector2(200, 40)
	max_stats_button.pressed.connect(_on_max_stats_pressed)
	quick_actions_grid.add_child(max_stats_button)
	reset_stats_button = Button.new()
	reset_stats_button.custom_minimum_size = Vector2(200, 40)
	reset_stats_button.pressed.connect(_on_reset_stats_pressed)
	quick_actions_grid.add_child(reset_stats_button)
	clear_debuffs_button = Button.new()
	clear_debuffs_button.custom_minimum_size = Vector2(200, 40)
	clear_debuffs_button.pressed.connect(_on_clear_debuffs_pressed)
	quick_actions_grid.add_child(clear_debuffs_button)
	add_honeymoon_button = Button.new()
	add_honeymoon_button.custom_minimum_size = Vector2(200, 40)
	add_honeymoon_button.pressed.connect(_on_add_honeymoon_pressed)
	quick_actions_grid.add_child(add_honeymoon_button)
	_add_separator(tab_developer)
	var toggles_label = Label.new()
	toggles_label.name = "TogglesLabel"
	toggles_label.add_theme_font_size_override("font_size", 20)
	toggles_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4))
	tab_developer.add_child(toggles_label)
	autosave_toggle = CheckBox.new()
	if GameState:
		autosave_toggle.set_pressed_no_signal(GameState.autosave_enabled)
	autosave_toggle.toggled.connect(_on_autosave_toggled)
	tab_developer.add_child(autosave_toggle)
	infinite_resources_toggle = CheckBox.new()
	if GameState:
		infinite_resources_toggle.set_pressed_no_signal(GameState.get_metadata("debug_infinite_resources", false))
	infinite_resources_toggle.toggled.connect(_on_infinite_resources_toggled)
	tab_developer.add_child(infinite_resources_toggle)
	skip_dialogue_toggle = CheckBox.new()
	if GameState:
		skip_dialogue_toggle.set_pressed_no_signal(GameState.settings.get("auto_advance_enabled", false))
	skip_dialogue_toggle.toggled.connect(_on_skip_dialogue_toggled)
	tab_developer.add_child(skip_dialogue_toggle)
	god_mode_toggle = CheckBox.new()
	if GameState:
		god_mode_toggle.set_pressed_no_signal(GameState.get_metadata("debug_god_mode", false))
	god_mode_toggle.toggled.connect(_on_god_mode_toggled)
	tab_developer.add_child(god_mode_toggle)
	_initialize_tutorial_controls()
func _initialize_tutorial_controls():
	var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	var info_panel = PanelContainer.new()
	info_panel.name = "TutorialInfoPanel"
	var info_margin = MarginContainer.new()
	info_margin.add_theme_constant_override("margin_left", 15)
	info_margin.add_theme_constant_override("margin_right", 15)
	info_margin.add_theme_constant_override("margin_top", 12)
	info_margin.add_theme_constant_override("margin_bottom", 12)
	info_panel.add_child(info_margin)
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 8)
	info_margin.add_child(info_vbox)
	var info_title = Label.new()
	info_title.name = "TutorialInfoTitle"
	info_title.add_theme_font_size_override("font_size", 18)
	info_title.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	info_vbox.add_child(info_title)
	var info_desc = Label.new()
	info_desc.name = "TutorialInfoDesc"
	info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	info_vbox.add_child(info_desc)
	tab_tutorial.add_child(info_panel)
	_add_separator(tab_tutorial)
	var controls_header = Label.new()
	controls_header.name = "ControlsHeader"
	controls_header.add_theme_font_size_override("font_size", 20)
	controls_header.add_theme_color_override("font_color", Color(1, 0.8, 0.4))
	tab_tutorial.add_child(controls_header)
	tutorial_enabled_toggle = CheckBox.new()
	if tutorial_system:
		tutorial_enabled_toggle.set_pressed_no_signal(tutorial_system.tutorial_enabled)
	tutorial_enabled_toggle.toggled.connect(_on_tutorial_enabled_toggled)
	tab_tutorial.add_child(tutorial_enabled_toggle)
	_add_separator(tab_tutorial)
	var progress_panel = PanelContainer.new()
	progress_panel.name = "ProgressPanel"
	var progress_margin = MarginContainer.new()
	progress_margin.add_theme_constant_override("margin_left", 15)
	progress_margin.add_theme_constant_override("margin_right", 15)
	progress_margin.add_theme_constant_override("margin_top", 10)
	progress_margin.add_theme_constant_override("margin_bottom", 10)
	progress_panel.add_child(progress_margin)
	var progress_vbox = VBoxContainer.new()
	progress_vbox.add_theme_constant_override("separation", 5)
	progress_margin.add_child(progress_vbox)
	var progress_title = Label.new()
	progress_title.name = "ProgressTitle"
	progress_title.add_theme_font_size_override("font_size", 16)
	progress_title.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	progress_vbox.add_child(progress_title)
	tutorial_progress_label = Label.new()
	tutorial_progress_label.add_theme_font_size_override("font_size", 20)
	tutorial_progress_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	progress_vbox.add_child(tutorial_progress_label)
	_update_tutorial_progress_display()
	tab_tutorial.add_child(progress_panel)
	_add_separator(tab_tutorial)
	reset_tutorials_button = Button.new()
	reset_tutorials_button.custom_minimum_size = Vector2(250, 45)
	reset_tutorials_button.pressed.connect(_on_reset_tutorials_pressed)
	tab_tutorial.add_child(reset_tutorials_button)
	_add_separator(tab_tutorial)
	var tutorial_list_label = Label.new()
	tutorial_list_label.name = "TutorialListLabel"
	tutorial_list_label.add_theme_font_size_override("font_size", 20)
	tutorial_list_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4))
	tab_tutorial.add_child(tutorial_list_label)
	tutorial_list_container = VBoxContainer.new()
	tutorial_list_container.add_theme_constant_override("separation", 6)
	tab_tutorial.add_child(tutorial_list_container)
	var tutorial_names = {
		"first_choice": {"name": "Making Choices", "icon": ""},
		"first_stat_change": {"name": "Reality Score", "icon": ""},
		"first_prayer": {"name": "Prayer System", "icon": ""},
		"first_mission": {"name": "Mission Journal", "icon": ""},
		"first_skill_check": {"name": "Skill Checks", "icon": ""},
		"first_gloria_intervention": {"name": "Gloria's Intervention", "icon": ""},
		"first_entropy_surge": {"name": "Entropy System", "icon": ""},
		"first_night_cycle": {"name": "Night Cycle", "icon": ""}
	}
	if tutorial_system:
		var steps = tutorial_system.get_all_tutorial_steps()
		for step in steps:
			var step_id: String = step.get("id", "")
			var trigger_event: String = step.get("trigger", "")
			var tutorial_info = tutorial_names.get(step_id, {"name": step_id.replace("_", " ").capitalize(), "icon": "•"})
			var item_panel = PanelContainer.new()
			item_panel.name = "Panel_" + step_id
			var item_margin = MarginContainer.new()
			item_margin.add_theme_constant_override("margin_left", 12)
			item_margin.add_theme_constant_override("margin_right", 12)
			item_margin.add_theme_constant_override("margin_top", 8)
			item_margin.add_theme_constant_override("margin_bottom", 8)
			item_panel.add_child(item_margin)
			var hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 12)
			item_margin.add_child(hbox)
			var name_hbox = HBoxContainer.new()
			name_hbox.add_theme_constant_override("separation", 8)
			name_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var icon_label = Label.new()
			icon_label.text = tutorial_info["icon"]
			icon_label.add_theme_font_size_override("font_size", 20)
			name_hbox.add_child(icon_label)
			var label = Label.new()
			label.text = tutorial_info["name"]
			label.add_theme_font_size_override("font_size", 16)
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_hbox.add_child(label)
			hbox.add_child(name_hbox)
			var status_label = Label.new()
			status_label.name = "Status_" + step_id
			status_label.custom_minimum_size = Vector2(110, 0)
			status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			status_label.add_theme_font_size_override("font_size", 14)
			if tutorial_system.is_tutorial_completed(step_id):
				status_label.text = "✓ Completed"
				status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
			else:
				status_label.text = "Not Seen"
				status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			hbox.add_child(status_label)
			var trigger_button = Button.new()
			trigger_button.name = "Trigger_" + step_id
			trigger_button.text = "▶ Show"
			trigger_button.custom_minimum_size = Vector2(100, 35)
			trigger_button.pressed.connect(_on_trigger_tutorial.bind(step_id))
			hbox.add_child(trigger_button)
			tutorial_list_container.add_child(item_panel)
func _on_text_speed_selected(index: int):
	match index:
		0: text_speed = 0.0
		1: text_speed = 2.0
		2: text_speed = 1.0
		3: text_speed = 0.5
	_play_sfx("menu_click")
func _on_screen_shake_toggled(toggled: bool):
	screen_shake_enabled = toggled
func _on_force_mission_complete_toggled(toggled: bool):
	if GameState:
		GameState.debug_force_mission_complete = toggled
func _on_force_gloria_pressed():
	_play_sfx("menu_click")
	var flow = _get_story_flow_controller()
	if flow and flow.has_method("force_gloria_intervention"):
		flow.force_gloria_intervention()
		_gloria_triggered = true
		_update_debug_button_status(force_gloria_button, force_gloria_status_label, true, "✓ Triggered! Close menu to see effect.")
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(self):
			_close_menu()
	else:
		_update_debug_button_status(force_gloria_button, force_gloria_status_label, false, "✗ Not in story scene")
func _on_force_trolley_pressed():
	_play_sfx("menu_click")
	var flow = _get_story_flow_controller()
	if flow and flow.has_method("_schedule_trolley_problem"):
		flow._schedule_trolley_problem()
		_trolley_triggered = true
		_update_debug_button_status(force_trolley_button, force_trolley_status_label, true, "✓ Scheduled! Close menu to see effect.")
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(self):
			_close_menu()
	else:
		_update_debug_button_status(force_trolley_button, force_trolley_status_label, false, "✗ Not in story scene")
func _update_debug_button_status(button: Button, label: Label, success: bool, message: String) -> void:
	if not is_instance_valid(label):
		return
	label.text = message
	if success:
		label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4)) 
		if is_instance_valid(button):
			button.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4)) 
		if is_instance_valid(button):
			button.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
func _on_force_honeymoon_toggled(toggled: bool):
	_play_sfx("menu_click")
	var flow = _get_story_flow_controller()
	if flow and flow.has_method("force_honeymoon_phase"):
		flow.force_honeymoon_phase(toggled)
func _get_story_flow_controller() -> Object:
	if ServiceLocator:
		return ServiceLocator.get_story_flow_controller()
	return null
func _close_menu():
	if _exit_mode == EXIT_MODE_OVERLAY:
		close_requested.emit()
		queue_free()
	else:
		_on_back_button_pressed()
func _on_reality_score_changed(value: float):
	if GameState:
		GameState.reality_score = int(value)
func _on_positive_energy_changed(value: float):
	if GameState:
		GameState.positive_energy = int(value)
func _on_entropy_level_changed(value: float):
	if GameState:
		GameState.entropy_level = int(value)
func _on_honeymoon_charges_changed(value: float):
	if GameState:
		GameState.honeymoon_charges = int(value)
func _on_mission_turn_changed(value: float):
	if GameState:
		GameState.mission_turn_count = int(value)
func _on_max_stats_pressed():
	_play_sfx("menu_click")
	if GameState:
		GameState.reality_score = 100
		GameState.positive_energy = 100
		GameState.entropy_level = 0
		GameState.honeymoon_charges = 10
		reality_score_spinbox.value = 100
		positive_energy_spinbox.value = 100
		entropy_level_spinbox.value = 0
		honeymoon_charges_spinbox.value = 10
		_show_notification("All stats maximized!", true)
func _on_reset_stats_pressed():
	_play_sfx("menu_click")
	if GameState:
		GameState.reality_score = 50
		GameState.positive_energy = 50
		GameState.entropy_level = 0
		GameState.honeymoon_charges = 3
		GameState.mission_turn_count = 0
		reality_score_spinbox.value = 50
		positive_energy_spinbox.value = 50
		entropy_level_spinbox.value = 0
		honeymoon_charges_spinbox.value = 3
		mission_turn_spinbox.value = 0
		_show_notification("All stats reset to defaults!", true)
func _on_clear_debuffs_pressed():
	_play_sfx("menu_click")
	if GameState:
		if GameState.get("_debuff_system"):
			GameState._debuff_system.clear_all()
			_show_notification("All debuffs cleared!", true)
		else:
			_show_notification("Debuff system not available", false)
	else:
		_show_notification("GameState not available", false)
func _on_add_honeymoon_pressed():
	_play_sfx("menu_click")
	if GameState:
		GameState.honeymoon_charges = min(10, GameState.honeymoon_charges + 5)
		honeymoon_charges_spinbox.value = GameState.honeymoon_charges
		_show_notification("Added 5 honeymoon charges!", true)
func _on_autosave_toggled(toggled: bool):
	_play_sfx("menu_click")
	if GameState:
		GameState.autosave_enabled = toggled
		var msg = "Autosave enabled" if toggled else "Autosave disabled"
		_show_notification(msg, true)
func _on_infinite_resources_toggled(toggled: bool):
	_play_sfx("menu_click")
	if GameState:
		GameState.set_metadata("debug_infinite_resources", toggled)
		var msg = "Infinite resources enabled" if toggled else "Infinite resources disabled"
		_show_notification(msg, true)
func _on_skip_dialogue_toggled(toggled: bool):
	_play_sfx("menu_click")
	if GameState:
		GameState.settings["auto_advance_enabled"] = toggled
		var msg = "Auto-advance dialogue enabled" if toggled else "Auto-advance dialogue disabled"
		_show_notification(msg, true)
func _on_god_mode_toggled(toggled: bool):
	_play_sfx("menu_click")
	if GameState:
		GameState.set_metadata("debug_god_mode", toggled)
		var msg = "God mode enabled" if toggled else "God mode disabled"
		_show_notification(msg, true)
func _show_notification(message: String, success: bool = true):
	var notifier = ServiceLocator.get_notification_system() if ServiceLocator else null
	if notifier:
		if success:
			notifier.show_success(message)
		else:
			notifier.show_warning(message)
	else:
		print("[Settings] " + message)
func _on_tutorial_enabled_toggled(toggled: bool):
	_play_sfx("menu_click")
	var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	if tutorial_system:
		tutorial_system.set_tutorial_enabled(toggled)
		var msg = "Tutorials enabled" if toggled else "Tutorials disabled"
		_show_notification(msg, true)
func _on_reset_tutorials_pressed():
	_play_sfx("menu_click")
	var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	if tutorial_system:
		tutorial_system.reset_tutorials()
		_show_notification("All tutorials have been reset!", true)
		_update_tutorial_progress_display()
		_update_tutorial_status_labels()
func _on_trigger_tutorial(step_id: String):
	_play_sfx("menu_click")
	var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	if tutorial_system:
		tutorial_system.trigger_tutorial(step_id)
		_show_notification("Triggered: " + step_id.replace("_", " ").capitalize(), true)
func _update_tutorial_progress_display():
	if not tutorial_progress_label:
		return
	var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	if tutorial_system:
		var progress = tutorial_system.get_tutorial_progress()
		var completed_count = tutorial_system.get_completed_tutorials().size()
		var total_count = tutorial_system.get_all_tutorial_steps().size()
		tutorial_progress_label.text = "Progress: %d/%d (%.1f%%)" % [completed_count, total_count, progress]
func _update_tutorial_status_labels():
	if not tutorial_list_container:
		return
	var tutorial_system = ServiceLocator.get_tutorial_system() if ServiceLocator else null
	if not tutorial_system:
		return
	for child in tutorial_list_container.get_children():
		if child is PanelContainer:
			var status_label = child.find_child("Status_*", true, false)
			if status_label and status_label is Label:
				var step_id = status_label.name.replace("Status_", "")
				if tutorial_system.is_tutorial_completed(step_id):
					status_label.text = "✓ Completed"
					status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
				else:
					status_label.text = "Not Seen"
					status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
func _enforce_fullscreen_layout() -> void:
	if menu_container:
		menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	if panel:
		var viewport_size = get_viewport_rect().size
		panel.custom_minimum_size = viewport_size
		panel.size = viewport_size
		panel.position = Vector2.ZERO
		if not menu_container.resized.is_connected(_on_viewport_resized):
			menu_container.resized.connect(_on_viewport_resized)
func _on_viewport_resized() -> void:
	var viewport_size = get_viewport_rect().size
	if panel:
		panel.custom_minimum_size = viewport_size
		panel.size = viewport_size
func update_ui_text():
	if tab_container:
		tab_container.set_tab_title(0, "Gameplay" if selected_language == "en" else "遊戲設定")
		tab_container.set_tab_title(1, "Display" if selected_language == "en" else "顯示")
		tab_container.set_tab_title(2, "Audio" if selected_language == "en" else "音訊")
		tab_container.set_tab_title(3, "Voice" if selected_language == "en" else "語音")
		tab_container.set_tab_title(4, "Tutorial" if selected_language == "en" else "教學")
		tab_container.set_tab_title(5, "Developer" if selected_language == "en" else "開發者")
	if selected_language == "en":
		title_label.text = "SETTINGS"
		text_speed_label.text = "Text Speed:"
		text_speed_option.set_item_text(0, "Instant")
		text_speed_option.set_item_text(1, "Fast")
		text_speed_option.set_item_text(2, "Normal")
		text_speed_option.set_item_text(3, "Slow")
		screen_shake_check.text = "Enable Screen Shake"
		touch_controls_checkbox.text = "Enable Touch Controls"
		if force_mission_complete_check:
			force_mission_complete_check.text = "Force Mission End (Debug)"
			force_mission_complete_check.tooltip_text = tr("SETTINGS_DEV_FORCE_COMPLETE_HINT")
		reality_score_label.text = "Reality Score:"
		positive_energy_label.text = "Positive Energy:"
		entropy_level_label.text = "Entropy Level:"
		honeymoon_charges_label.text = "Honeymoon Charges:"
		mission_turn_label.text = "Mission Turn Count:"
		if tab_developer.has_node("QuickActionsLabel"):
			tab_developer.get_node("QuickActionsLabel").text = "Quick Actions"
		if tab_developer.has_node("TogglesLabel"):
			tab_developer.get_node("TogglesLabel").text = "Game State Toggles"
		max_stats_button.text = "Max All Stats"
		reset_stats_button.text = "Reset All Stats"
		clear_debuffs_button.text = "Clear All Debuffs"
		add_honeymoon_button.text = "+5 Honeymoon Charges"
		autosave_toggle.text = "Enable Autosave"
		infinite_resources_toggle.text = "Infinite Resources Mode"
		skip_dialogue_toggle.text = "Auto-Advance Dialogue"
		god_mode_toggle.text = "God Mode (No Fail)"
		if master_volume_hbox.has_node("MasterVolumeLabel"):
			master_volume_hbox.get_node("MasterVolumeLabel").text = "Master Volume:"
		if music_volume_hbox.has_node("MusicVolumeLabel"):
			music_volume_hbox.get_node("MusicVolumeLabel").text = "Music Volume:"
		if sfx_volume_hbox.has_node("SFXVolumeLabel"):
			sfx_volume_hbox.get_node("SFXVolumeLabel").text = "SFX Volume:"
		mute_check_box.text = " Mute All"
		voice_description.text = "[b]Native voice[/b] lets supported Gemini Live models stream speech output and accept microphone input. Unsupported models stay text-only."
		voice_enabled_check.text = "Enable native voice pipeline"
		voice_output_check.text = "Play AI voice responses"
		voice_input_check.text = "Send microphone input to AI"
		voice_choice_label.text = "Voice preset:"
		voice_volume_label.text = "Voice volume:"
		voice_input_mode_label.text = "Microphone mode:"
		voice_proactive_check.text = "Enable proactive listening"
		if not voice_capture_active:
			voice_capture_button.text = "Capture mic test"
		voice_preview_button.text = "Play sample line"
		if not voice_status_label.text:
			voice_status_label.text = "Voice idle."
		resolution_label.text = "Resolution:"
		fullscreen_label.text = "Display Mode:"
		language_label.text = "Language:"
		font_size_label.text = "Font Size:"
		if tab_tutorial:
			if tab_tutorial.has_node("TutorialInfoPanel"):
				var info_panel = tab_tutorial.get_node("TutorialInfoPanel")
				if info_panel.has_node("TutorialInfoTitle"):
					info_panel.find_child("TutorialInfoTitle", true, false).text = "About Tutorials"
				if info_panel.has_node("TutorialInfoDesc"):
					info_panel.find_child("TutorialInfoDesc", true, false).text = "Tutorials provide helpful tips when you encounter new game mechanics. You can replay any tutorial here or disable them entirely."
			if tab_tutorial.has_node("ControlsHeader"):
				tab_tutorial.get_node("ControlsHeader").text = "Settings"
			if tab_tutorial.has_node("ProgressPanel"):
				var progress_panel = tab_tutorial.get_node("ProgressPanel")
				if progress_panel.has_node("ProgressTitle"):
					progress_panel.find_child("ProgressTitle", true, false).text = "Your Progress"
			if tab_tutorial.has_node("TutorialListLabel"):
				tab_tutorial.get_node("TutorialListLabel").text = "All Tutorials"
		if tutorial_enabled_toggle:
			tutorial_enabled_toggle.text = "Enable Tutorials"
		if reset_tutorials_button:
			reset_tutorials_button.text = "🔄 Reset All Tutorials"
		_update_tutorial_progress_display()
		ai_settings_button.text = "AI Provider Settings"
		apply_button.text = "APPLY"
		if delete_logs_button:
			delete_logs_button.text = "DELETE LOCAL LOGS"
		back_button.text = "BACK"
		if delete_logs_dialog:
			delete_logs_dialog.title = "Delete Local Logs"
			delete_logs_dialog.dialog_text = "This deletes locally stored logs and cached AI prompts. Continue?"
			delete_logs_dialog.ok_button_text = "Delete"
			delete_logs_dialog.cancel_button_text = "Cancel"
		fullscreen_option.set_item_text(0, "Windowed")
		fullscreen_option.set_item_text(1, "Fullscreen")
		fullscreen_option.set_item_text(2, "Borderless Window")
	else:
		title_label.text = "設定"
		text_speed_label.text = "文字速度："
		text_speed_option.set_item_text(0, "瞬間")
		text_speed_option.set_item_text(1, "快")
		text_speed_option.set_item_text(2, "正常")
		text_speed_option.set_item_text(3, "慢")
		screen_shake_check.text = "啟用畫面震動"
		touch_controls_checkbox.text = "啟用觸控模式"
		if force_mission_complete_check:
			force_mission_complete_check.text = "強制結束任務 (Debug)"
			force_mission_complete_check.tooltip_text = tr("SETTINGS_DEV_FORCE_COMPLETE_HINT")
		reality_score_label.text = "現實值："
		positive_energy_label.text = "正能量值："
		entropy_level_label.text = "熵值："
		honeymoon_charges_label.text = "蜜月期次數："
		mission_turn_label.text = "任務回合數："
		if tab_developer.has_node("QuickActionsLabel"):
			tab_developer.get_node("QuickActionsLabel").text = "快速操作"
		if tab_developer.has_node("TogglesLabel"):
			tab_developer.get_node("TogglesLabel").text = "遊戲狀態切換"
		max_stats_button.text = "全部屬性最大化"
		reset_stats_button.text = "重置全部屬性"
		clear_debuffs_button.text = "清除所有減益"
		add_honeymoon_button.text = "+5 蜜月期次數"
		autosave_toggle.text = "啟用自動存檔"
		infinite_resources_toggle.text = "無限資源模式"
		skip_dialogue_toggle.text = "自動推進對話"
		god_mode_toggle.text = "上帝模式（無失敗）"
		if master_volume_hbox.has_node("MasterVolumeLabel"):
			master_volume_hbox.get_node("MasterVolumeLabel").text = "主音量："
		if music_volume_hbox.has_node("MusicVolumeLabel"):
			music_volume_hbox.get_node("MusicVolumeLabel").text = "音樂音量："
		if sfx_volume_hbox.has_node("SFXVolumeLabel"):
			sfx_volume_hbox.get_node("SFXVolumeLabel").text = "音效音量："
		mute_check_box.text = " 全部靜音"
		voice_description.text = "[b]原生語音[/b] 允許支援的 Gemini Live 模型輸出語音並接收麥克風輸入。"
		voice_enabled_check.text = "啟用原生語音管線"
		voice_output_check.text = "播放 AI 語音回應"
		voice_input_check.text = "傳送麥克風輸入給 AI"
		voice_choice_label.text = "語音預設："
		voice_volume_label.text = "語音音量："
		voice_input_mode_label.text = "麥克風模式："
		voice_proactive_check.text = "啟用主動聆聽"
		if not voice_capture_active:
			voice_capture_button.text = "測試麥克風截取"
		voice_preview_button.text = "播放範例"
		if not voice_status_label.text:
			voice_status_label.text = "語音待機。"
		resolution_label.text = "解析度："
		fullscreen_label.text = "顯示模式："
		language_label.text = "語言："
		font_size_label.text = "字體大小："
		if tab_tutorial:
			if tab_tutorial.has_node("TutorialInfoPanel"):
				var info_panel = tab_tutorial.get_node("TutorialInfoPanel")
				if info_panel.has_node("TutorialInfoTitle"):
					info_panel.find_child("TutorialInfoTitle", true, false).text = "關於教學"
				if info_panel.has_node("TutorialInfoDesc"):
					info_panel.find_child("TutorialInfoDesc", true, false).text = "教學會在您遇到新遊戲機制時提供有用的提示。您可以在此重新觀看任何教學或完全停用它們。"
			if tab_tutorial.has_node("ControlsHeader"):
				tab_tutorial.get_node("ControlsHeader").text = "設定"
			if tab_tutorial.has_node("ProgressPanel"):
				var progress_panel = tab_tutorial.get_node("ProgressPanel")
				if progress_panel.has_node("ProgressTitle"):
					progress_panel.find_child("ProgressTitle", true, false).text = "您的進度"
			if tab_tutorial.has_node("TutorialListLabel"):
				tab_tutorial.get_node("TutorialListLabel").text = "所有教學"
		if tutorial_enabled_toggle:
			tutorial_enabled_toggle.text = "啟用教學"
		if reset_tutorials_button:
			reset_tutorials_button.text = "🔄 重置所有教學"
		_update_tutorial_progress_display()
		ai_settings_button.text = "AI 提供者設定"
		apply_button.text = "套用"
		if delete_logs_button:
			delete_logs_button.text = "刪除本機記錄"
		back_button.text = "返回"
		if delete_logs_dialog:
			delete_logs_dialog.title = "刪除本機記錄"
			delete_logs_dialog.dialog_text = "這將刪除本機儲存的記錄與 AI 快取。是否繼續？"
			delete_logs_dialog.ok_button_text = "刪除"
			delete_logs_dialog.cancel_button_text = "取消"
		fullscreen_option.set_item_text(0, "視窗化")
		fullscreen_option.set_item_text(1, "全螢幕")
		fullscreen_option.set_item_text(2, "無邊框視窗")
	_update_voice_availability_label()
func _set_button_pressed_safely(button: BaseButton, pressed: bool) -> void:
	if not button: return
	if button.has_method("set_pressed_no_signal"):
		button.call("set_pressed_no_signal", pressed)
		return
	var was_blocking := button.is_blocking_signals()
	button.set_block_signals(true)
	button.button_pressed = pressed
	button.set_block_signals(was_blocking)
func _ensure_background_aliases() -> void:
	if not BackgroundLoader: return
	var catalog = BackgroundLoader.get("backgrounds")
	if typeof(catalog) != TYPE_DICTIONARY: return
	if catalog.has("fire_area"): return
	if not catalog.has("fire"): return
	var source: Dictionary = catalog["fire"].duplicate(true)
	source["name"] = source.get("name", "Fire Area")
	catalog["fire_area"] = source
	var cache = BackgroundLoader.get("texture_cache")
	if typeof(cache) == TYPE_DICTIONARY and cache.has("fire"):
		cache["fire_area"] = cache["fire"]
func _cleanup_ai_resources(force_clear_callback: bool = false) -> void:
	_cancel_active_voice_capture()
	_disconnect_ai_signals()
	_clear_pending_ai_callback(force_clear_callback)
func _cancel_active_voice_capture() -> void:
	if not AIManager: return
	if voice_capture_active:
		AIManager.cancel_voice_capture()
		voice_capture_active = false
func _disconnect_ai_signals() -> void:
	if not AIManager: return
	if AIManager.voice_capability_changed.is_connected(_on_voice_capability_changed):
		AIManager.voice_capability_changed.disconnect(_on_voice_capability_changed)
	if AIManager.voice_audio_received.is_connected(_on_voice_audio_received):
		AIManager.voice_audio_received.disconnect(_on_voice_audio_received)
	if AIManager.voice_input_buffer_ready.is_connected(_on_voice_input_buffer_ready):
		AIManager.voice_input_buffer_ready.disconnect(_on_voice_input_buffer_ready)
	if AIManager.voice_transcription_ready.is_connected(_on_voice_transcription_ready):
		AIManager.voice_transcription_ready.disconnect(_on_voice_transcription_ready)
	if AIManager.voice_transcription_failed.is_connected(_on_voice_transcription_failed):
		AIManager.voice_transcription_failed.disconnect(_on_voice_transcription_failed)
func _clear_pending_ai_callback(force_clear: bool) -> void:
	if not AIManager: return
	var pending := AIManager.pending_callback
	if pending.is_null(): return
	if force_clear:
		AIManager.pending_callback = Callable()
		return
	if pending.is_valid():
		var target := pending.get_object()
		if target == self:
			AIManager.pending_callback = Callable()
	else:
		AIManager.pending_callback = Callable()
func _apply_modern_styles():
	var panel_style = UIStyleManager.create_panel_style(0.98, 0)
	panel.add_theme_stylebox_override("panel", panel_style)
	if apply_button:
		UIStyleManager.apply_button_style(apply_button, "accent", "large")
		apply_button.icon = ICON_CHECK
		apply_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(apply_button, 1.06)
		UIStyleManager.add_press_feedback(apply_button)
		apply_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if ai_settings_button:
		UIStyleManager.apply_button_style(ai_settings_button, "primary", "large")
		ai_settings_button.icon = ICON_CREATIVE
		ai_settings_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(ai_settings_button, 1.06)
		UIStyleManager.add_press_feedback(ai_settings_button)
		ai_settings_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if back_button:
		UIStyleManager.apply_button_style(back_button, "primary", "large")
		back_button.icon = ICON_BACK
		back_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(back_button, 1.06)
		UIStyleManager.add_press_feedback(back_button)
		back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if delete_logs_button:
		UIStyleManager.apply_button_style(delete_logs_button, "danger", "medium")
		delete_logs_button.icon = ICON_DELETE
		delete_logs_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(delete_logs_button, 1.05)
		UIStyleManager.add_press_feedback(delete_logs_button)
		delete_logs_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if master_volume_hbox.has_node("MasterVolumeSlider"):
		master_volume_hbox.get_node("MasterVolumeSlider").mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if music_volume_hbox.has_node("MusicVolumeSlider"):
		music_volume_hbox.get_node("MusicVolumeSlider").mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if sfx_volume_hbox.has_node("SFXVolumeSlider"):
		sfx_volume_hbox.get_node("SFXVolumeSlider").mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if voice_preview_button:
		UIStyleManager.apply_button_style(voice_preview_button, "secondary", "medium")
		UIStyleManager.add_press_feedback(voice_preview_button)
		voice_preview_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if voice_capture_button:
		UIStyleManager.apply_button_style(voice_capture_button, "secondary", "medium")
		voice_capture_button.icon = ICON_MIC
		voice_capture_button.expand_icon = true
		UIStyleManager.add_press_feedback(voice_capture_button)
		voice_capture_button.expand_icon = true
		UIStyleManager.add_press_feedback(voice_capture_button)
		voice_capture_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if reset_tutorials_button:
		UIStyleManager.apply_button_style(reset_tutorials_button, "accent", "medium")
		UIStyleManager.add_press_feedback(reset_tutorials_button)
		reset_tutorials_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if tab_tutorial:
		if tab_tutorial.has_node("TutorialInfoPanel"):
			var info_panel = tab_tutorial.get_node("TutorialInfoPanel")
			var info_style = UIStyleManager.create_panel_style(0.92, UIStyleManager.CORNER_RADIUS_MEDIUM)
			info_style.border_width_left = 3
			info_style.border_width_top = 0
			info_style.border_width_right = 0
			info_style.border_width_bottom = 0
			info_style.border_color = Color(0.4, 0.7, 1.0, 0.8)
			info_panel.add_theme_stylebox_override("panel", info_style)
		if tab_tutorial.has_node("ProgressPanel"):
			var progress_panel = tab_tutorial.get_node("ProgressPanel")
			var progress_style = UIStyleManager.create_panel_style(0.94, UIStyleManager.CORNER_RADIUS_MEDIUM)
			progress_style.border_width_left = 0
			progress_style.border_width_top = 2
			progress_style.border_width_right = 0
			progress_style.border_width_bottom = 2
			progress_style.border_color = Color(0.7, 0.9, 1.0, 0.5)
			progress_panel.add_theme_stylebox_override("panel", progress_style)
	if tutorial_list_container:
		for child in tutorial_list_container.get_children():
			if child is PanelContainer:
				var item_style = UIStyleManager.create_panel_style(0.9, UIStyleManager.CORNER_RADIUS_SMALL)
				item_style.border_width_left = 2
				item_style.border_width_top = 0
				item_style.border_width_right = 0
				item_style.border_width_bottom = 0
				item_style.border_color = Color(0.5, 0.5, 0.5, 0.3)
				child.add_theme_stylebox_override("panel", item_style)
				var trigger_button = child.find_child("Trigger_*", true, false)
				if trigger_button and trigger_button is Button:
					UIStyleManager.apply_button_style(trigger_button, "primary", "small")
					UIStyleManager.add_press_feedback(trigger_button)
					trigger_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_connect_button_sounds()
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
func _connect_button_sounds() -> void:
	var menu_click_buttons = [
		back_button, ai_settings_button,
		voice_preview_button, voice_capture_button,
		screen_shake_check, touch_controls_checkbox,
		mute_check_box, delete_logs_button
	]
	for btn in menu_click_buttons:
		if btn:
			if not btn.pressed.is_connected(_play_sfx.bind("menu_click")):
				btn.pressed.connect(_play_sfx.bind("menu_click"))
	if apply_button:
		if not apply_button.pressed.is_connected(_play_sfx.bind("happy_click")):
			apply_button.pressed.connect(_play_sfx.bind("happy_click"))
	if delete_logs_dialog:
		var ok_btn = delete_logs_dialog.get_ok_button()
		if ok_btn and not ok_btn.pressed.is_connected(_play_sfx.bind("angry_click")):
			ok_btn.pressed.connect(_play_sfx.bind("angry_click"))
func _style_delete_logs_dialog() -> void:
	if not delete_logs_dialog: return
	var dialog_style: StyleBoxFlat = UIStyleManager.create_panel_style(0.96, UIStyleManager.CORNER_RADIUS_LARGE)
	delete_logs_dialog.add_theme_stylebox_override("panel", dialog_style)
	var ok_button: Button = delete_logs_dialog.get_ok_button()
	if ok_button:
		UIStyleManager.apply_button_style(ok_button, "danger", "medium")
		UIStyleManager.add_press_feedback(ok_button)
		ok_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var cancel_button: Button = delete_logs_dialog.get_cancel_button()
	if cancel_button:
		UIStyleManager.apply_button_style(cancel_button, "secondary", "medium")
		UIStyleManager.add_press_feedback(cancel_button)
		cancel_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
func _initialize_voice_controls():
	if voice_voice_option:
		voice_voice_option.clear()
		for voice_name in VOICE_VOICE_NAMES:
			voice_voice_option.add_item(voice_name)
	if voice_input_mode_option:
		voice_input_mode_option.clear()
		for mode in VOICE_INPUT_MODE_LABELS.keys():
			voice_input_mode_option.add_item(VOICE_INPUT_MODE_LABELS[mode], mode)
	if AudioManager:
		var audio_snapshot := AudioManager.get_volume_settings()
		voice_volume = float(audio_snapshot.get("voice_volume", voice_volume))
	var ai_voice_settings := { }
	if AIManager:
		ai_voice_settings = AIManager.get_voice_settings()
		voice_supported = bool(ai_voice_settings.get("native_voice_supported", voice_supported))
		voice_enabled = bool(ai_voice_settings.get("prefer_native_audio", voice_enabled))
		voice_output_enabled = bool(ai_voice_settings.get("voice_output_enabled", voice_output_enabled))
		voice_input_enabled = bool(ai_voice_settings.get("voice_input_enabled", voice_input_enabled))
		voice_voice_name = String(ai_voice_settings.get("preferred_voice_name", voice_voice_name))
		voice_input_mode = int(ai_voice_settings.get("voice_input_mode", voice_input_mode))
		voice_proactive_enabled = bool(ai_voice_settings.get("proactive_audio_enabled", voice_proactive_enabled))
		if not AIManager.voice_capability_changed.is_connected(_on_voice_capability_changed):
			AIManager.voice_capability_changed.connect(_on_voice_capability_changed)
		if not AIManager.voice_audio_received.is_connected(_on_voice_audio_received):
			AIManager.voice_audio_received.connect(_on_voice_audio_received)
		if not AIManager.voice_input_buffer_ready.is_connected(_on_voice_input_buffer_ready):
			AIManager.voice_input_buffer_ready.connect(_on_voice_input_buffer_ready)
		if not AIManager.voice_transcription_ready.is_connected(_on_voice_transcription_ready):
			AIManager.voice_transcription_ready.connect(_on_voice_transcription_ready)
		if not AIManager.voice_transcription_failed.is_connected(_on_voice_transcription_failed):
			AIManager.voice_transcription_failed.connect(_on_voice_transcription_failed)
	if not voice_supported:
		voice_enabled = false
		voice_output_enabled = false
		voice_input_enabled = false
	if voice_volume_slider:
		voice_volume_slider.value = voice_volume
	_update_voice_volume_display()
	if voice_voice_option:
		var voice_index := 0
		for i in range(voice_voice_option.item_count):
			if voice_voice_option.get_item_text(i) == voice_voice_name:
				voice_index = i
				break
		voice_voice_option.select(voice_index)
	if voice_input_mode_option:
		var selected_index := 0
		for i in range(voice_input_mode_option.item_count):
			if voice_input_mode_option.get_item_id(i) == voice_input_mode:
				selected_index = i
				break
		voice_input_mode_option.select(selected_index)
	_set_button_pressed_safely(voice_proactive_check, voice_proactive_enabled)
	_update_voice_availability_label()
	_sync_voice_ui_state()
	if not voice_status_label.text:
		_update_voice_status("Voice idle.")
func _sync_voice_ui_state():
	var supported := voice_supported
	if voice_enabled and not supported:
		voice_enabled = false
		voice_output_enabled = false
		voice_input_enabled = false
	if not (voice_enabled and supported):
		voice_capture_active = false
	_set_button_pressed_safely(voice_enabled_check, voice_enabled and supported)
	voice_enabled_check.disabled = AIManager == null
	voice_options_box.visible = voice_enabled and supported
	_set_button_pressed_safely(voice_output_check, voice_output_enabled)
	voice_output_check.disabled = not (voice_enabled and supported)
	_set_button_pressed_safely(voice_input_check, voice_input_enabled)
	voice_input_check.disabled = not (voice_enabled and supported)
	voice_volume_slider.editable = voice_enabled and supported
	voice_volume_slider.focus_mode = Control.FOCUS_ALL if voice_enabled and supported else Control.FOCUS_NONE
	voice_volume_slider.value = voice_volume
	_update_voice_volume_display()
	var continuous_available := voice_enabled and supported and voice_input_enabled
	voice_input_mode_option.disabled = not continuous_available
	_set_button_pressed_safely(voice_proactive_check, voice_proactive_enabled)
	voice_proactive_check.disabled = not (voice_enabled and supported and voice_output_enabled)
	voice_preview_button.disabled = not (voice_enabled and supported and voice_output_enabled)
	voice_capture_button.disabled = not (voice_enabled and supported and voice_input_enabled)
	voice_capture_button.text = "Cancel capture" if voice_capture_active else "Capture mic test"
	voice_description.visible = true
	voice_status_label.visible = voice_enabled and supported
	_update_voice_availability_label()
func _update_voice_availability_label():
	if not voice_availability_label: return
	if not AIManager:
		voice_availability_label.text = "Native voice unavailable (AI Manager missing)."
		return
	if voice_supported:
		var provider_name := ""
		var model_name := ""
		match AIManager.current_provider:
			AIManager.AIProvider.GEMINI:
				provider_name = "Gemini"
				model_name = AIManager.gemini_model
			AIManager.AIProvider.OPENROUTER:
				provider_name = "OpenRouter"
				model_name = AIManager.openrouter_model
			AIManager.AIProvider.OLLAMA:
				provider_name = "Ollama (Local)"
				model_name = AIManager.ollama_model
			_:
				provider_name = "Unknown"
		voice_availability_label.text = "Native audio ready via %s (%s)." % [provider_name, model_name]
	else:
		var extra := ""
		if AIManager.current_provider == AIManager.AIProvider.GEMINI:
			extra = " Toggle native audio to auto-switch to %s." % GEMINI_RECOMMENDED_NATIVE_AUDIO_MODEL
		voice_availability_label.text = "Current model does not expose native audio.%s" % extra

func _try_enable_gemini_native_audio_support() -> bool:
	if not AIManager:
		return false
	if AIManager.current_provider != AIManager.AIProvider.GEMINI:
		return false
	var current := String(AIManager.gemini_model).strip_edges()
	if current != GEMINI_RECOMMENDED_NATIVE_AUDIO_MODEL:
		AIManager.gemini_model = GEMINI_RECOMMENDED_NATIVE_AUDIO_MODEL
		AIManager.save_ai_settings()
	AIManager.refresh_voice_capabilities()
	voice_supported = AIManager.is_native_voice_supported()
	_update_voice_availability_label()
	return voice_supported
func _update_voice_volume_display():
	if voice_volume_value:
		voice_volume_value.text = "%d%%" % int(round(voice_volume))
func _update_voice_status(message: String, is_error: bool = false):
	if not voice_status_label: return
	voice_status_label.text = message
	if is_error:
		voice_status_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	else:
		voice_status_label.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
func _gather_voice_preferences() -> Dictionary:
	return {
		"prefer_native_audio": voice_enabled,
		"voice_output_enabled": voice_output_enabled,
		"voice_input_enabled": voice_input_enabled,
		"preferred_voice_name": voice_voice_name,
		"voice_input_mode": voice_input_mode,
		"proactive_audio_enabled": voice_proactive_enabled,
	}
func _apply_voice_preferences():
	if not AIManager: return
	var prefs := _gather_voice_preferences()
	AIManager.apply_voice_settings(prefs)
	AIManager.refresh_voice_capabilities()
	AIManager.save_ai_settings()
	voice_supported = AIManager.is_native_voice_supported()
	_sync_voice_ui_state()
func _on_voice_capability_changed(supported: bool):
	voice_supported = supported
	if not supported:
		voice_enabled = false
		voice_output_enabled = false
		voice_input_enabled = false
	_update_voice_availability_label()
	_sync_voice_ui_state()
	var state_text := "enabled" if supported else "disabled"
	_update_voice_status("Native audio %s for current model." % state_text)
func _on_voice_audio_received(payload: Dictionary):
	if not (voice_enabled and voice_output_enabled): return
	var mime: String = str(payload.get("mime_type", "audio/pcm"))
	var sample_rate := int(payload.get("sample_rate", 24000))
	_update_voice_status("Received AI audio (%s @ %d Hz)." % [mime, sample_rate])
func _on_voice_input_buffer_ready(pcm: PackedByteArray, sample_rate: int, metadata: Dictionary):
	voice_capture_active = false
	var length_sec := float(metadata.get("length_seconds", float(pcm.size()) / max(sample_rate * 2, 1)))
	_update_voice_status("Captured microphone sample (%.2f s @ %d Hz)." % [length_sec, sample_rate])
	_sync_voice_ui_state()
func _on_voice_transcription_ready(transcript: String, metadata: Dictionary):
	voice_capture_active = false
	var direction: String = str(metadata.get("direction", "output"))
	var label := "AI transcription" if direction == "output" else "Input transcription"
	_update_voice_status("%s: %s" % [label, transcript])
	_sync_voice_ui_state()
func _on_voice_transcription_failed(reason: String):
	voice_capture_active = false
	_update_voice_status("Voice transcription failed: %s" % reason, true)
	_sync_voice_ui_state()
func _on_voice_enabled_toggled(button_pressed: bool):
	if button_pressed and not voice_supported:
		if _try_enable_gemini_native_audio_support():
			_update_voice_status("Switched Gemini model for native audio: %s" % GEMINI_RECOMMENDED_NATIVE_AUDIO_MODEL)
		else:
			_set_button_pressed_safely(voice_enabled_check, false)
			_update_voice_status("Current model does not support native audio.", true)
			return
	voice_enabled = button_pressed and voice_supported
	if not voice_enabled:
		voice_output_enabled = false
		voice_input_enabled = false
	voice_capture_active = false
	_apply_voice_preferences()
	_sync_voice_ui_state()
func _on_voice_output_toggled(button_pressed: bool):
	if not (voice_enabled and voice_supported):
		_set_button_pressed_safely(voice_output_check, false)
		_update_voice_status("Enable native voice first.", true)
		return
	voice_output_enabled = button_pressed
	_apply_voice_preferences()
	_sync_voice_ui_state()
func _on_voice_input_toggled(button_pressed: bool):
	if not (voice_enabled and voice_supported):
		_set_button_pressed_safely(voice_input_check, false)
		_update_voice_status("Enable native voice first.", true)
		return
	voice_input_enabled = button_pressed
	if not voice_input_enabled:
		voice_capture_active = false
		if AIManager:
			AIManager.cancel_voice_capture()
	_apply_voice_preferences()
	_sync_voice_ui_state()
func _on_voice_voice_option_selected(index: int):
	if voice_voice_option:
		voice_voice_name = voice_voice_option.get_item_text(index)
	_apply_voice_preferences()
func _on_voice_volume_changed(value: float):
	voice_volume = value
	_update_voice_volume_display()
	_apply_audio_settings()
func _on_voice_input_mode_selected(index: int):
	if not voice_input_mode_option: return
	var selected_id: int = voice_input_mode_option.get_item_id(index)
	if selected_id == -1:
		selected_id = voice_input_mode_option.selected
	voice_input_mode = selected_id
	_apply_voice_preferences()
func _on_voice_proactive_toggled(button_pressed: bool):
	voice_proactive_enabled = button_pressed
	_apply_voice_preferences()
func _on_voice_preview_button_pressed():
	if not (voice_enabled and voice_supported and voice_output_enabled):
		_update_voice_status("Enable native voice output to preview audio.", true)
		return
	if not AudioManager:
		_update_voice_status("AudioManager unavailable for preview.", true)
		return
	var snapshot := AudioManager.get_last_voice_snapshot()
	if snapshot.is_empty() and not AIManager:
		_update_voice_status("No voice playback data available yet.", true)
		return
	if snapshot.has("stream") and snapshot["stream"]:
		AudioManager.play_voice_stream(snapshot["stream"])
		_update_voice_status("Replaying most recent AI voice output.")
		return
	var pcm: PackedByteArray = snapshot.get("pcm", PackedByteArray())
	if pcm.is_empty():
		_update_voice_status("No AI voice output captured yet.", true)
		return
	var sample_rate := int(snapshot.get("sample_rate", AudioManager.DEFAULT_VOICE_SAMPLE_RATE))
	AudioManager.play_voice_from_pcm(pcm, sample_rate)
	_update_voice_status("Replaying buffered AI voice sample.")
func _on_voice_capture_button_pressed():
	if voice_capture_active:
		if AIManager:
			AIManager.cancel_voice_capture()
		voice_capture_active = false
		_update_voice_status("Capture cancelled.")
		_sync_voice_ui_state()
		return
	if not (voice_enabled and voice_supported and voice_input_enabled):
		_update_voice_status("Enable native voice input to capture audio.", true)
		return
	if not AIManager:
		_update_voice_status("AI Manager unavailable for capture.", true)
		return
	voice_capture_active = true
	_update_voice_status("Listening for %.1f seconds..." % VOICE_CAPTURE_SECONDS)
	_sync_voice_ui_state()
	AIManager.request_voice_capture(VOICE_CAPTURE_SECONDS)
func _on_touch_controls_toggled(button_pressed: bool) -> void:
	touch_controls_enabled = button_pressed
	var touch_controls = get_tree().get_root().find_child("TouchControls", true, false)
	if touch_controls:
		touch_controls.visible = touch_controls_enabled
func _on_master_volume_changed(value: float):
	master_volume = value
	if master_volume_hbox.has_node("MasterVolumeValue"):
		master_volume_hbox.get_node("MasterVolumeValue").text = str(int(value)) + "%"
	_apply_audio_settings()
func _on_music_volume_changed(value: float):
	music_volume = value
	if music_volume_hbox.has_node("MusicVolumeValue"):
		music_volume_hbox.get_node("MusicVolumeValue").text = str(int(value)) + "%"
	_apply_audio_settings()
func _on_sfx_volume_changed(value: float):
	sfx_volume = value
	if sfx_volume_hbox.has_node("SFXVolumeValue"):
		sfx_volume_hbox.get_node("SFXVolumeValue").text = str(int(value)) + "%"
	_apply_audio_settings()
func _on_mute_toggled(button_pressed: bool):
	is_muted = button_pressed
	_apply_audio_settings()
func _apply_audio_settings():
	if AudioManager:
		AudioManager.apply_volume_settings(
			{
				"master_volume": master_volume,
				"music_volume": music_volume,
				"sfx_volume": sfx_volume,
				"voice_volume": voice_volume,
				"muted": is_muted,
			},
		)
	else:
		var master_bus_idx = AudioServer.get_bus_index("Master")
		var music_bus_idx = AudioServer.get_bus_index("Music")
		var sfx_bus_idx = AudioServer.get_bus_index("SFX")
		var voice_bus_idx = AudioServer.get_bus_index("Voice")
		if master_bus_idx != -1:
			AudioServer.set_bus_mute(master_bus_idx, is_muted)
		if not is_muted:
			var master_db = linear_to_db(master_volume / 100.0)
			var music_db = linear_to_db(music_volume / 100.0)
			var sfx_db = linear_to_db(sfx_volume / 100.0)
			var voice_db = linear_to_db(voice_volume / 100.0)
			AudioServer.set_bus_volume_db(master_bus_idx, master_db)
			if music_bus_idx != -1:
				AudioServer.set_bus_volume_db(music_bus_idx, music_db)
			if sfx_bus_idx != -1:
				AudioServer.set_bus_volume_db(sfx_bus_idx, sfx_db)
			if voice_bus_idx != -1:
				AudioServer.set_bus_volume_db(voice_bus_idx, voice_db)
func _on_resolution_changed(index: int):
	selected_resolution = resolutions[index]
func _on_fullscreen_changed(index: int):
	selected_mode = index
func _on_language_changed(index: int):
	selected_language = "zh" if index == 0 else "en"
	if GameState:
		GameState.current_language = selected_language
	update_ui_text()
func _on_font_size_changed(index: int):
	selected_font_size = index
	if FontManager:
		FontManager.set_font_size(selected_font_size)
	get_tree().reload_current_scene()
func _on_apply_button_pressed():
	var window := get_window()
	var allow_resize := true
	if window:
		if window.has_method("is_embedded") and window.call("is_embedded"):
			allow_resize = false
		match selected_mode:
			0: 
				window.mode = Window.MODE_WINDOWED
				window.borderless = false
				if allow_resize:
					window.size = selected_resolution
			1: 
				window.borderless = false
				window.mode = Window.MODE_FULLSCREEN
			2: 
				window.mode = Window.MODE_WINDOWED
				window.borderless = true
				if allow_resize:
					window.size = selected_resolution
	else:
		print("SettingsMenu: get_window() returned null, using DisplayServer fallback.")
	if not window:
		match selected_mode:
			0:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
				DisplayServer.window_set_size(selected_resolution)
			1:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			2:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
				DisplayServer.window_set_size(selected_resolution)
	if allow_resize and selected_mode == 0:
		await get_tree().process_frame
		var screen_size = DisplayServer.screen_get_size()
		var window_size = DisplayServer.window_get_size()
		var centered_pos = (screen_size - window_size) / 2
		DisplayServer.window_set_position(centered_pos)
	if GameState:
		GameState.current_language = selected_language
	if FontManager:
		FontManager.set_font_size(selected_font_size)
	_apply_audio_settings()
	if DisplayManager:
		var reported_size = selected_resolution
		if window and allow_resize:
			reported_size = window.size
		DisplayManager.current_window_size = reported_size
	save_settings()
	var feedback_text = "Settings applied!" if selected_language == "en" else "設定已套用！"
	print(feedback_text)
func _on_delete_logs_button_pressed():
	if AudioManager:
		AudioManager.play_sfx("menu_click")
	if delete_logs_dialog:
		delete_logs_dialog.popup_centered()
		var ok_button: Button = delete_logs_dialog.get_ok_button()
		if ok_button:
			ok_button.call_deferred("grab_focus")
func _on_delete_logs_confirmed():
	var success := false
	var files_removed := 0
	var metadata_removed := 0
	if AudioManager:
		AudioManager.play_sfx("happy_click")
	if GameState and GameState.has_method("delete_local_logs"):
		var result: Dictionary = GameState.delete_local_logs()
		success = true
		files_removed = int(result.get("files_deleted", 0))
		var removed_array_variant: Variant = result.get("metadata_keys_removed", [])
		if removed_array_variant is Array:
			var removed_array: Array = removed_array_variant
			metadata_removed = removed_array.size()
		GameState.set_metadata("prayer_notice_acknowledged", false)
	else:
		success = false
	var message := ""
	if selected_language == "en":
		if success:
			message = "Local logs cleared (%d files removed, %d caches reset)." % [files_removed, metadata_removed]
		else:
			message = "Unable to clear logs because the game state service is unavailable."
	else:
		if success:
			message = "已清除本機記錄（刪除檔案 %d 個，重設快取 %d 項）。" % [files_removed, metadata_removed]
		else:
			message = "無法清除記錄，因遊戲狀態不可用。"
	var notifier = ServiceLocator.get_notification_system() if ServiceLocator else null
	if notifier:
		if success:
			notifier.show_success(message)
		else:
			notifier.show_warning(message)
func _on_ai_settings_button_pressed():
	if _exit_mode == EXIT_MODE_OVERLAY:
		_emit_close_requested()
	var tree := get_tree()
	if not tree: return
	tree.paused = false
	tree.change_scene_to_file("res://1.Codebase/src/scenes/ui/ai_settings_menu.tscn")
func _on_back_button_pressed():
	save_settings()
	if _exit_mode == EXIT_MODE_OVERLAY:
		_emit_close_requested()
	else:
		close_requested.emit()
		_go_to_main_menu()
func _on_home_button_pressed():
	if _exit_mode == EXIT_MODE_OVERLAY:
		_emit_close_requested()
		EventBus.publish(
			"return_to_menu_requested",
			{
				"confirm": true,
				"source": "settings_menu",
			},
		)
	else:
		_go_to_main_menu()
func save_settings():
	var config = ConfigFile.new()
	config.set_value("display", "resolution", selected_resolution)
	config.set_value("display", "mode", selected_mode)
	config.set_value("display", "font_size", selected_font_size)
	config.set_value("display", "high_contrast", high_contrast_mode)
	config.set_value("game", "language", selected_language)
	config.set_value("game", "text_speed", text_speed)
	config.set_value("game", "screen_shake", screen_shake_enabled)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "muted", is_muted)
	config.set_value("voice", "enabled", voice_enabled)
	config.set_value("voice", "output_enabled", voice_output_enabled)
	config.set_value("voice", "input_enabled", voice_input_enabled)
	config.set_value("voice", "voice_volume", voice_volume)
	config.set_value("voice", "voice_name", voice_voice_name)
	config.set_value("voice", "voice_input_mode", voice_input_mode)
	config.set_value("voice", "proactive_enabled", voice_proactive_enabled)
	config.set_value("controls", "touch_controls_enabled", touch_controls_enabled)
	config.save("user://settings.cfg")
	if GameState:
		GameState.settings.text_speed = text_speed
		GameState.settings.screen_shake_enabled = screen_shake_enabled
		GameState.settings.high_contrast_mode = high_contrast_mode
func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		selected_resolution = config.get_value("display", "resolution", Vector2i(1024, 600))
		selected_mode = config.get_value("display", "mode", 0)
		selected_font_size = config.get_value("display", "font_size", 2)
		high_contrast_mode = config.get_value("display", "high_contrast", false)
		selected_language = config.get_value("game", "language", "en")
		text_speed = config.get_value("game", "text_speed", 1.0)
		screen_shake_enabled = config.get_value("game", "screen_shake", true)
		master_volume = config.get_value("audio", "master_volume", 100.0)
		music_volume = config.get_value("audio", "music_volume", 100.0)
		sfx_volume = config.get_value("audio", "sfx_volume", 100.0)
		is_muted = config.get_value("audio", "muted", false)
		voice_enabled = config.get_value("voice", "enabled", voice_enabled)
		voice_output_enabled = config.get_value("voice", "output_enabled", voice_output_enabled)
		voice_input_enabled = config.get_value("voice", "input_enabled", voice_input_enabled)
		voice_volume = config.get_value("voice", "voice_volume", voice_volume)
		voice_voice_name = config.get_value("voice", "voice_name", voice_voice_name)
		voice_input_mode = int(config.get_value("voice", "voice_input_mode", voice_input_mode))
		voice_proactive_enabled = config.get_value("voice", "proactive_enabled", voice_proactive_enabled)
		touch_controls_enabled = config.get_value("controls", "touch_controls_enabled", false)
		_apply_audio_settings()
		if GameState:
			GameState.settings.text_speed = text_speed
			GameState.settings.screen_shake_enabled = screen_shake_enabled
			GameState.settings.high_contrast_mode = high_contrast_mode
func _emit_close_requested() -> void:
	close_requested.emit()
	if _exit_mode == EXIT_MODE_OVERLAY:
		_cleanup_ai_resources()
	if not is_queued_for_deletion() and _exit_mode == EXIT_MODE_OVERLAY:
		queue_free()
func _go_to_main_menu() -> void:
	var tree := get_tree()
	if not tree: return
	_cleanup_ai_resources(true)
	tree.paused = false
	tree.change_scene_to_file("res://1.Codebase/menu_main.tscn")
func _exit_tree() -> void:
	_cleanup_ai_resources()
func set_exit_mode(mode: int) -> void:
	_exit_mode = mode
	_apply_exit_mode_state()
func _apply_exit_mode_state() -> void:
	if title_label == null: return
	var callback := Callable(self, "_on_title_label_gui_input")
	if _exit_mode == EXIT_MODE_OVERLAY:
		var is_english := GameState == null or GameState.current_language == "en"
		title_label.tooltip_text = "Return to mission" if is_english else "返回任務"
		title_label.mouse_filter = Control.MOUSE_FILTER_STOP
		if not title_label.gui_input.is_connected(callback):
			title_label.gui_input.connect(callback)
	else:
		title_label.tooltip_text = ""
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if title_label.gui_input.is_connected(callback):
			title_label.gui_input.disconnect(callback)
func _on_title_label_gui_input(event: InputEvent) -> void:
	if _exit_mode != EXIT_MODE_OVERLAY: return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_emit_close_requested()
func _ensure_audio_label(hbox: Control, label_name: String) -> void:
	if not hbox: return
	if hbox.has_node(label_name): return
	var label = Label.new()
	label.name = label_name
	label.custom_minimum_size.x = 140 
	hbox.add_child(label)
	hbox.move_child(label, 0)
