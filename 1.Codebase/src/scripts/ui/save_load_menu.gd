extends Control
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
const ICON_SAVE = preload("res://1.Codebase/src/assets/ui/icon_save.svg")
const ICON_PLAY = preload("res://1.Codebase/src/assets/ui/icon_play.svg")
const ICON_DELETE = preload("res://1.Codebase/src/assets/ui/icon_delete.svg")
const ICON_REFRESH = preload("res://1.Codebase/src/assets/ui/icon_refresh.svg")
const ICON_CLOSE = preload("res://1.Codebase/src/assets/ui/icon_close.svg")
var backdrop: ColorRect
var panel: Panel
var title_label: Label
var subtitle_label: Label
var info_label: Label
var autosave_info_label: Label
var autosave_timestamp_label: Label
var autosave_load_button: Button
var autosave_delete_button: Button
var autosave_panel: Panel
var slot_list: VBoxContainer
var scroll_container: ScrollContainer
var status_label: Label
var close_button: Button
var refresh_button: Button
var empty_hint_label: Label
var _lang: String = "en"
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_lang = GameState.current_language if GameState else "en"
	_cache_nodes()
	_apply_locale()
	_apply_styles()
	_connect_signals()
	refresh_autosave()
	refresh_slots()
	if panel:
		var viewport_size = get_viewport_rect().size
		panel.custom_minimum_size = viewport_size * 0.9
		UIStyleManager.fade_in(panel, 0.25)
		UIStyleManager.slide_in_from_bottom(panel, 0.35, 25.0)
	if close_button:
		close_button.grab_focus()
func _apply_locale() -> void:
	if title_label:
		title_label.text = "存檔 / 讀檔" if _lang == "zh" else "Save / Load"
	if subtitle_label:
		subtitle_label.text = "管理你的冒險進度" if _lang == "zh" else "Manage your progress"
	if info_label:
		info_label.text = "選擇存檔槽即可載入、覆寫或刪除；自動存檔會顯示在上方。" if _lang == "zh" else "Choose a slot to load, overwrite, or delete. Autosave data appears above when available."
	if autosave_load_button:
		autosave_load_button.text = "載入自動存檔" if _lang == "zh" else "Load autosave"
	if autosave_delete_button:
		autosave_delete_button.text = "刪除自動存檔" if _lang == "zh" else "Delete autosave"
	if refresh_button:
		refresh_button.text = "重新整理" if _lang == "zh" else "Refresh"
	if close_button:
		close_button.text = "關閉" if _lang == "zh" else "Close"
	if empty_hint_label:
		empty_hint_label.text = "目前沒有手動存檔。使用任一槽位的「存檔」按鈕建立進度。" if _lang == "zh" else "No manual saves yet. Use a slot's Save button to create one."
func _find_node(node_name: String) -> Node:
	return find_child(node_name, true, false)
func _cache_nodes():
	backdrop = get_node_or_null("Backdrop") as ColorRect
	panel = get_node_or_null("ModalRoot/Panel") as Panel
	title_label = _find_node("TitleLabel") as Label
	subtitle_label = _find_node("SubtitleLabel") as Label
	info_label = _find_node("InfoLabel") as Label
	autosave_info_label = _find_node("AutosaveInfo") as Label
	autosave_timestamp_label = _find_node("AutosaveTimestamp") as Label
	autosave_load_button = _find_node("LoadAutosaveButton") as Button
	autosave_delete_button = _find_node("DeleteAutosaveButton") as Button
	autosave_panel = _find_node("AutosavePanel") as Panel
	slot_list = _find_node("SlotList") as VBoxContainer
	scroll_container = _find_node("ScrollContainer") as ScrollContainer
	status_label = _find_node("StatusLabel") as Label
	close_button = _find_node("CloseButton") as Button
	refresh_button = _find_node("RefreshButton") as Button
	empty_hint_label = _find_node("EmptyHintLabel") as Label
func _apply_styles():
	if backdrop:
		backdrop.color = Color(0, 0, 0, 1.0)
		backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	if panel:
		UIStyleManager.apply_panel_style(panel, 0.95, UIStyleManager.CORNER_RADIUS_LARGE)
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if autosave_panel:
		UIStyleManager.apply_panel_style(autosave_panel, 0.9, UIStyleManager.CORNER_RADIUS_MEDIUM)
	if title_label:
		title_label.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	if subtitle_label:
		subtitle_label.add_theme_color_override("font_color", Color(0.78, 0.83, 0.95))
	if info_label:
		info_label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.98))
	if empty_hint_label:
		empty_hint_label.add_theme_color_override("font_color", Color(0.76, 0.82, 0.92))
	if status_label:
		status_label.add_theme_color_override("font_color", Color(0.66, 0.86, 0.66))
	if autosave_load_button:
		UIStyleManager.apply_button_style(autosave_load_button, "primary", "medium")
		autosave_load_button.icon = ICON_PLAY
		autosave_load_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(autosave_load_button, 1.05)
		UIStyleManager.add_press_feedback(autosave_load_button)
		autosave_load_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if autosave_delete_button:
		UIStyleManager.apply_button_style(autosave_delete_button, "danger", "medium")
		autosave_delete_button.icon = ICON_DELETE
		autosave_delete_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(autosave_delete_button, 1.05)
		UIStyleManager.add_press_feedback(autosave_delete_button)
		autosave_delete_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if refresh_button:
		UIStyleManager.apply_button_style(refresh_button, "primary", "medium")
		refresh_button.icon = ICON_REFRESH
		refresh_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(refresh_button, 1.05)
		UIStyleManager.add_press_feedback(refresh_button)
		refresh_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if close_button:
		UIStyleManager.apply_button_style(close_button, "accent", "medium")
		close_button.icon = ICON_CLOSE
		close_button.expand_icon = true
		UIStyleManager.add_hover_scale_effect(close_button, 1.05)
		UIStyleManager.add_press_feedback(close_button)
		close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
func _connect_signals():
	if close_button and not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	if refresh_button and not refresh_button.pressed.is_connected(_on_refresh_pressed):
		refresh_button.pressed.connect(_on_refresh_pressed)
	if autosave_load_button and not autosave_load_button.pressed.is_connected(_on_load_autosave_pressed):
		autosave_load_button.pressed.connect(_on_load_autosave_pressed)
	if autosave_delete_button and not autosave_delete_button.pressed.is_connected(_on_delete_autosave_pressed):
		autosave_delete_button.pressed.connect(_on_delete_autosave_pressed)
func refresh_slots():
	if not slot_list:
		return
	for child in slot_list.get_children():
		child.queue_free()
	var slot_count := 0
	for slot in range(1, GameState.MAX_SAVE_SLOTS + 1):
		var info = GameState.get_save_slot_info(slot)
		var slot_item = _create_slot_item(slot, info)
		slot_list.add_child(slot_item)
		slot_count += 1
	_update_empty_state(slot_count)
func refresh_autosave():
	var info = GameState.get_autosave_info()
	if not info.get("exists", false):
		if autosave_info_label:
			autosave_info_label.text = "No autosave available." if _lang == "en" else "目前沒有自動存檔。"
		if autosave_timestamp_label:
			autosave_timestamp_label.text = ""
		if autosave_load_button:
			autosave_load_button.disabled = true
		if autosave_delete_button:
			autosave_delete_button.disabled = true
		_set_autosave_visibility(false)
	else:
		var missions = info.get("missions_completed", 0)
		var entropy = info.get("entropy_level", 0)
		var reality = info.get("reality_score", 0)
		if autosave_info_label:
			autosave_info_label.text = _format_autosave_summary(reality, missions, entropy)
		if autosave_timestamp_label:
			autosave_timestamp_label.text = _format_timestamp(info.get("timestamp", 0))
		if autosave_load_button:
			autosave_load_button.disabled = false
		if autosave_delete_button:
			autosave_delete_button.disabled = false
		_set_autosave_visibility(true)
func _set_autosave_visibility(has_autosave: bool) -> void:
	if not autosave_panel:
		return
	autosave_panel.visible = true
	autosave_panel.modulate = Color(1, 1, 1, 1.0) if has_autosave else Color(1, 1, 1, 0.7)
	if autosave_info_label and not has_autosave:
		autosave_info_label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.86))
	elif autosave_info_label:
		autosave_info_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	if autosave_timestamp_label:
		autosave_timestamp_label.add_theme_color_override("font_color", Color(0.68, 0.72, 0.82) if not has_autosave else Color(0.82, 0.88, 0.98))
func _update_empty_state(slot_count: int) -> void:
	var has_slots := slot_count > 0
	if scroll_container:
		scroll_container.visible = has_slots
	if slot_list:
		slot_list.visible = has_slots
	if empty_hint_label:
		empty_hint_label.visible = not has_slots
func _create_slot_item(slot: int, info: Dictionary) -> Control:
	var container = PanelContainer.new()
	container.name = "Slot_%d" % slot
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.28, 0.38, 0.9) if info.get("exists", false) else Color(0.16, 0.18, 0.24, 0.75)
	style.border_color = Color(0.42, 0.76, 0.96, 0.95) if info.get("exists", false) else Color(0.35, 0.42, 0.56, 0.8)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	container.add_theme_stylebox_override("panel", style)
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	container.add_child(margin)
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(hbox)
	var info_box = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_box)
	var header = Label.new()
	header.text = "Slot %d" % slot if _lang == "en" else "槽位 %d" % slot
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	info_box.add_child(header)
	var summary = Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD
	summary.add_theme_font_size_override("font_size", 14)
	if info.get("exists", false):
		summary.text = _format_slot_summary(info)
	else:
		summary.text = "Empty slot. Create a new save here." if _lang == "en" else "空槽位，可在此建立存檔。"
		summary.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	info_box.add_child(summary)
	if info.get("exists", false):
		var timestamp_label = Label.new()
		timestamp_label.text = _format_timestamp(info.get("timestamp", 0))
		timestamp_label.add_theme_font_size_override("font_size", 12)
		timestamp_label.add_theme_color_override("font_color", Color(0.78, 0.82, 0.88))
		info_box.add_child(timestamp_label)
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	hbox.add_child(button_row)
	var save_button = Button.new()
	save_button.text = "Save" if _lang == "en" else "存檔"
	save_button.icon = ICON_SAVE
	save_button.expand_icon = true
	UIStyleManager.apply_button_style(save_button, "primary", "small")
	UIStyleManager.add_hover_scale_effect(save_button, 1.05)
	UIStyleManager.add_press_feedback(save_button)
	save_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	save_button.pressed.connect(_on_save_slot_pressed.bind(slot))
	button_row.add_child(save_button)
	var load_button = Button.new()
	load_button.text = "Load" if _lang == "en" else "讀檔"
	load_button.icon = ICON_PLAY
	load_button.expand_icon = true
	UIStyleManager.apply_button_style(load_button, "accent", "small")
	UIStyleManager.add_hover_scale_effect(load_button, 1.05)
	UIStyleManager.add_press_feedback(load_button)
	load_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	load_button.pressed.connect(_on_load_slot_pressed.bind(slot))
	load_button.disabled = not info.get("exists", false)
	button_row.add_child(load_button)
	var delete_button = Button.new()
	delete_button.text = "Delete" if _lang == "en" else "刪除"
	delete_button.icon = ICON_DELETE
	delete_button.expand_icon = true
	UIStyleManager.apply_button_style(delete_button, "danger", "small")
	UIStyleManager.add_hover_scale_effect(delete_button, 1.05)
	UIStyleManager.add_press_feedback(delete_button)
	delete_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	delete_button.pressed.connect(_on_delete_slot_pressed.bind(slot))
	delete_button.disabled = not info.get("exists", false)
	button_row.add_child(delete_button)
	return container
func _format_slot_summary(info: Dictionary) -> String:
	var current_mission_idx = info.get("current_mission", 0)
	var mission_title = info.get("current_mission_title", "")
	var entropy = info.get("entropy_level", 0)
	var reality = info.get("reality_score", 0)
	if mission_title.is_empty():
		mission_title = "Untitled" if _lang == "en" else "無題"
	if _lang == "en":
		return "Mission %d: %s\nReality %d | Entropy %d" % [current_mission_idx, mission_title, reality, entropy]
	else:
		return "第 %d 章：%s\n現實 %d｜熵增 %d" % [current_mission_idx, mission_title, reality, entropy]
func _format_autosave_summary(reality: int, missions: int, entropy: int) -> String:
	if _lang == "en":
		return "Autosave • Reality %d / Entropy %d / Missions %d" % [reality, entropy, missions]
	else:
		return "自動存檔 • 現實 %d / 熵增 %d / 任務 %d" % [reality, entropy, missions]
func _format_timestamp(timestamp: int) -> String:
	if timestamp <= 0:
		return "Unknown time" if _lang == "en" else "時間未知"
	var dt = Time.get_datetime_dict_from_unix_time(timestamp)
	if _lang == "en":
		return "Saved on %04d-%02d-%02d %02d:%02d" % [dt["year"], dt["month"], dt["day"], dt["hour"], dt["minute"]]
	return "%04d年%02d月%02d日 %02d:%02d 存檔" % [dt["year"], dt["month"], dt["day"], dt["hour"], dt["minute"]]
func _on_save_slot_pressed(slot: int):
	if AudioManager:
		AudioManager.play_sfx("menu_click")
	var success = GameState.save_game_to_slot(slot)
	if success:
		_show_status("Saved to slot %d." % slot if _lang == "en" else "已存入槽位 %d。" % slot, true)
		refresh_slots()
	else:
		_show_status("Failed to save to slot %d." % slot if _lang == "en" else "槽位 %d 存檔失敗。" % slot, false)
func _on_load_slot_pressed(slot: int):
	if AudioManager:
		AudioManager.play_sfx("menu_click")
	var success = GameState.load_game_from_slot(slot)
	if success:
		_show_status("Loaded slot %d." % slot if _lang == "en" else "已讀取槽位 %d。" % slot, true)
		await get_tree().process_frame
		queue_free()
		get_tree().change_scene_to_file("res://1.Codebase/src/scenes/ui/story_scene_enhanced.tscn")
	else:
		_show_status("Failed to load slot %d." % slot if _lang == "en" else "槽位 %d 讀檔失敗。" % slot, false)
func _on_delete_slot_pressed(slot: int):
	if AudioManager:
		AudioManager.play_sfx("angry_click")
	var success = GameState.delete_save_slot(slot)
	if success:
		_show_status("Slot %d cleared." % slot if _lang == "en" else "已清除槽位 %d。" % slot, true)
		refresh_slots()
	else:
		_show_status("Unable to clear slot %d." % slot if _lang == "en" else "無法清除槽位 %d。" % slot, false)
func _on_load_autosave_pressed():
	if AudioManager:
		AudioManager.play_sfx("menu_click")
	var success = GameState.load_game()
	if success:
		_show_status("Autosave loaded." if _lang == "en" else "已載入自動存檔。", true)
		await get_tree().process_frame
		queue_free()
		get_tree().change_scene_to_file("res://1.Codebase/src/scenes/ui/story_scene_enhanced.tscn")
	else:
		_show_status("Failed to load autosave." if _lang == "en" else "自動存檔讀取失敗。", false)
func _on_delete_autosave_pressed():
	if AudioManager:
		AudioManager.play_sfx("angry_click")
	var success = GameState.delete_autosave()
	if success:
		_show_status("Autosave removed." if _lang == "en" else "已刪除自動存檔。", true)
	else:
		_show_status("Unable to remove autosave." if _lang == "en" else "無法刪除自動存檔。", false)
	refresh_autosave()
func _on_refresh_pressed():
	if AudioManager:
		AudioManager.play_sfx("menu_click", 0.7)
	refresh_autosave()
	refresh_slots()
	_show_status("Save list refreshed." if _lang == "en" else "存檔列表已更新。", true)
func _on_close_pressed():
	if AudioManager:
		AudioManager.play_sfx("menu_click", 0.7)
	queue_free()
func _show_status(message: String, success: bool):
	if not status_label:
		return
	status_label.text = message
	if success:
		status_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	else:
		status_label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.55))
