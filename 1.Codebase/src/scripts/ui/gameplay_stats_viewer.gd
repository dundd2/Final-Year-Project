extends Control
const UIConstants = preload("res://1.Codebase/src/scripts/ui/ui_constants.gd")
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var stats_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsContainer
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/CloseButton
@onready var refresh_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/RefreshButton
var stat_categories := [
	{
		"id": "missions",
		"title_en": "Mission Statistics",
		"title_zh": "任务统计",
		"stats": [
			{ "key": "missions_completed", "label_en": "Total Missions", "label_zh": "完成任务数", "format": "number" },
			{ "key": "current_mission", "label_en": "Current Mission", "label_zh": "当前任务", "format": "number" },
		],
	},
	{
		"id": "time",
		"title_en": "Time Statistics",
		"title_zh": "时间统计",
		"stats": [
			{ "key": "total_playtime", "label_en": "Total Playtime", "label_zh": "总游戏时间", "format": "time" },
			{ "key": "session_start", "label_en": "Session Started", "label_zh": "本次会话开始", "format": "datetime" },
		],
	},
	{
		"id": "core_stats",
		"title_en": "Core Stats",
		"title_zh": "核心数据",
		"stats": [
			{ "key": "reality_score", "label_en": "Reality Score", "label_zh": "现实值", "format": "stat" },
			{ "key": "positive_energy", "label_en": "Positive Energy", "label_zh": "正能量", "format": "stat" },
			{ "key": "entropy_level", "label_en": "Entropy Level", "label_zh": "熵值", "format": "stat" },
		],
	},
	{
		"id": "stat_changes",
		"title_en": "Stat Changes",
		"title_zh": "数值变化",
		"stats": [
			{ "key": "reality_changes", "label_en": "Reality Changes", "label_zh": "现实值变化次数", "format": "number" },
			{ "key": "entropy_peak", "label_en": "Peak Entropy", "label_zh": "最高熵值", "format": "number" },
			{ "key": "lowest_reality", "label_en": "Lowest Reality", "label_zh": "最低现实值", "format": "number" },
		],
	},
	{
		"id": "skills",
		"title_en": "Skills",
		"title_zh": "技能",
		"stats": [
			{ "key": "logic", "label_en": "Logic", "label_zh": "逻辑", "format": "skill" },
			{ "key": "perception", "label_en": "Perception", "label_zh": "感知", "format": "skill" },
			{ "key": "composure", "label_en": "Composure", "label_zh": "镇定", "format": "skill" },
			{ "key": "empathy", "label_en": "Empathy", "label_zh": "共情", "format": "skill" },
		],
	},
	{
		"id": "skill_checks",
		"title_en": "Skill Checks",
		"title_zh": "技能检定",
		"stats": [
			{ "key": "logic_checks", "label_en": "Logic Checks Passed", "label_zh": "逻辑检定通过", "format": "number" },
			{ "key": "perception_checks", "label_en": "Perception Checks Passed", "label_zh": "感知检定通过", "format": "number" },
			{ "key": "composure_checks", "label_en": "Composure Checks Passed", "label_zh": "镇定检定通过", "format": "number" },
			{ "key": "empathy_checks", "label_en": "Empathy Checks Passed", "label_zh": "共情检定通过", "format": "number" },
		],
	},
	{
		"id": "choices",
		"title_en": "Choice Patterns",
		"title_zh": "选择模式",
		"stats": [
			{ "key": "most_chosen_type", "label_en": "Most Chosen Option Type", "label_zh": "最常选择类型", "format": "text" },
			{ "key": "total_choices", "label_en": "Total Choices Made", "label_zh": "总选择次数", "format": "number" },
		],
	},
	{
		"id": "social",
		"title_en": "Social",
		"title_zh": "社交",
		"stats": [
			{ "key": "teammates_met", "label_en": "Teammates Met", "label_zh": "遇见的队友", "format": "number" },
			{ "key": "gloria_interventions", "label_en": "Gloria Interventions", "label_zh": "Gloria干预次数", "format": "number" },
			{ "key": "complaint_counter", "label_en": "Current Complaints", "label_zh": "当前抱怨数", "format": "number" },
		],
	},
	{
		"id": "activities",
		"title_en": "Activities",
		"title_zh": "活动",
		"stats": [
			{ "key": "prayers_made", "label_en": "Prayers Made", "label_zh": "祈祷次数", "format": "number" },
			{ "key": "journal_entries", "label_en": "Journal Entries", "label_zh": "日志记录", "format": "number" },
			{ "key": "moral_dilemmas", "label_en": "Moral Dilemmas Faced", "label_zh": "道德困境次数", "format": "number" },
		],
	},
	{
		"id": "achievements",
		"title_en": "Achievements",
		"title_zh": "成就",
		"stats": [
			{ "key": "achievements_unlocked", "label_en": "Achievements Unlocked", "label_zh": "已解锁成就", "format": "achievement_ratio" },
			{ "key": "achievement_progress", "label_en": "Achievement Progress", "label_zh": "成就进度", "format": "percentage" },
		],
	},
]
var playtime_start: int = 0
func _ready() -> void:
	playtime_start = Time.get_ticks_msec()
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if refresh_button:
		refresh_button.pressed.connect(_on_refresh_pressed)
	_localize_ui()
	_render_stats()
func _localize_ui() -> void:
	var lang = GameState.current_language if GameState else "en"
	if lang == "zh":
		if title_label:
			title_label.text = "游戏统计"
		if close_button:
			close_button.text = "关闭"
		if refresh_button:
			refresh_button.text = "刷新"
	else:
		if title_label:
			title_label.text = "Gameplay Statistics"
		if close_button:
			close_button.text = "Close"
		if refresh_button:
			refresh_button.text = "Refresh"
func _render_stats() -> void:
	if not stats_container:
		return
	for child in stats_container.get_children():
		child.queue_free()
	var gameplay_stats = _get_gameplay_stats()
	var lang = GameState.current_language if GameState else "en"
	for category in stat_categories:
		_render_category(category, gameplay_stats, lang)
func _get_gameplay_stats() -> Dictionary:
	var stats := { }
	if not GameState:
		return stats
	stats["missions_completed"] = GameState.missions_completed
	stats["current_mission"] = GameState.current_mission
	stats["total_playtime"] = _get_playtime_formatted()
	stats["session_start"] = Time.get_datetime_string_from_system()
	stats["reality_score"] = GameState.reality_score
	stats["positive_energy"] = GameState.positive_energy
	stats["entropy_level"] = GameState.entropy_level
	stats["reality_changes"] = _count_stat_changes("reality")
	stats["entropy_peak"] = _get_max_entropy_reached()
	stats["lowest_reality"] = _get_min_reality_reached()
	var player_skills = GameState.player_skills
	stats["logic"] = player_skills.get("logic", 0)
	stats["perception"] = player_skills.get("perception", 0)
	stats["composure"] = player_skills.get("composure", 0)
	stats["empathy"] = player_skills.get("empathy", 0)
	if AchievementSystem:
		stats["logic_checks"] = AchievementSystem.skill_check_counters.get("logic", 0)
		stats["perception_checks"] = AchievementSystem.skill_check_counters.get("perception", 0)
		stats["composure_checks"] = AchievementSystem.skill_check_counters.get("composure", 0)
		stats["empathy_checks"] = AchievementSystem.skill_check_counters.get("empathy", 0)
	stats["most_chosen_type"] = _analyze_choice_patterns()
	stats["total_choices"] = _count_total_choices()
	stats["teammates_met"] = _get_unlocked_teammates()
	stats["gloria_interventions"] = _count_gloria_interventions()
	stats["complaint_counter"] = GameState.complaint_counter
	stats["prayers_made"] = _count_prayers()
	stats["journal_entries"] = _count_journal_entries()
	stats["moral_dilemmas"] = _count_moral_dilemmas()
	if AchievementSystem:
		var unlocked = AchievementSystem.get_unlocked_achievements().size()
		var total = AchievementSystem.get_all_achievements().size()
		stats["achievements_unlocked"] = "%d / %d" % [unlocked, total]
		stats["achievement_progress"] = (float(unlocked) / float(total) * 100.0) if total > 0 else 0.0
	return stats
func _render_category(category: Dictionary, gameplay_stats: Dictionary, lang: String) -> void:
	var title_text = category["title_zh"] if lang == "zh" else category["title_en"]
	var title = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_SUBTITLE)
	title.add_theme_color_override("font_color", UIConstants.COLOR_ACCENT_BLUE)
	stats_container.add_child(title)
	for stat in category["stats"]:
		_render_stat_row(stat, gameplay_stats, lang)
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, UIConstants.SPACING_SMALL)
	stats_container.add_child(spacer)
func _render_stat_row(stat: Dictionary, gameplay_stats: Dictionary, lang: String) -> void:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 30)
	var label_text = stat["label_zh"] if lang == "zh" else stat["label_en"]
	var label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size = Vector2(250, 0)
	hbox.add_child(label)
	var value_label = Label.new()
	var value = gameplay_stats.get(stat["key"], 0)
	value_label.text = _format_stat_value(value, stat["format"])
	value_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
	hbox.add_child(value_label)
	stats_container.add_child(hbox)
func _format_stat_value(value: Variant, format: String) -> String:
	match format:
		"number":
			return str(value)
		"stat":
			return "%.1f / 100" % float(value)
		"skill":
			return "%d / 10" % int(value)
		"time":
			return str(value)
		"datetime":
			return str(value)
		"text":
			return str(value)
		"percentage":
			return "%.1f%%" % float(value)
		"achievement_ratio":
			return str(value)
		_:
			return str(value)
func _get_playtime_formatted() -> String:
	var elapsed_ms = Time.get_ticks_msec() - playtime_start
	var elapsed_sec = elapsed_ms / 1000
	var hours = elapsed_sec / 3600
	var minutes = (elapsed_sec % 3600) / 60
	var seconds = elapsed_sec % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]
func _count_stat_changes(stat_name: String) -> int:
	if not GameState:
		return 0
	var count = 0
	for event in GameState.event_log:
		if event.get("type", "") == "stat_changed" and event.get("details", { }).get("stat", "") == stat_name:
			count += 1
	return count
func _get_max_entropy_reached() -> float:
	if not GameState:
		return 0.0
	var max_entropy = GameState.entropy_level
	for event in GameState.event_log:
		if event.get("type", "") == "stat_changed" and event.get("details", { }).get("stat", "") == "entropy":
			var value = event.get("details", { }).get("new_value", 0.0)
			if value > max_entropy:
				max_entropy = value
	return max_entropy
func _get_min_reality_reached() -> float:
	if not GameState:
		return 100.0
	var min_reality = GameState.reality_score
	for event in GameState.event_log:
		if event.get("type", "") == "stat_changed" and event.get("details", { }).get("stat", "") == "reality":
			var value = event.get("details", { }).get("new_value", 100.0)
			if value < min_reality:
				min_reality = value
	return min_reality
func _analyze_choice_patterns() -> String:
	if not GameState or not GameState.butterfly_tracker:
		return "N/A"
	var choice_types := { }
	var choices = GameState.butterfly_tracker.recorded_choices if GameState.butterfly_tracker.has("recorded_choices") else []
	for choice in choices:
		var choice_type = choice.get("type", "unknown")
		choice_types[choice_type] = choice_types.get(choice_type, 0) + 1
	var most_common = ""
	var max_count = 0
	for type in choice_types:
		if choice_types[type] > max_count:
			max_count = choice_types[type]
			most_common = type
	return most_common if most_common else "N/A"
func _count_total_choices() -> int:
	if not GameState or not GameState.butterfly_tracker:
		return 0
	var choices = GameState.butterfly_tracker.recorded_choices if GameState.butterfly_tracker.has("recorded_choices") else []
	return choices.size()
func _get_unlocked_teammates() -> int:
	if not GameState:
		return 0
	var encountered_teammates := {}
	for event in GameState.event_log:
		if event.get("type", "") == "teammate_interference":
			var teammate_id = event.get("details", {}).get("teammate", "")
			if not teammate_id.is_empty():
				encountered_teammates[teammate_id] = true
	return encountered_teammates.size()
func _count_gloria_interventions() -> int:
	if not GameState:
		return 0
	var count = 0
	for event in GameState.event_log:
		if event.get("type", "") == "gloria_intervention":
			count += 1
	return count
func _count_prayers() -> int:
	if not GameState:
		return 0
	var count = 0
	for event in GameState.event_log:
		if event.get("type", "") == "prayer_made":
			count += 1
	return count
func _count_journal_entries() -> int:
	if not AchievementSystem:
		return 0
	return AchievementSystem.journal_entry_count
func _count_moral_dilemmas() -> int:
	if not AchievementSystem:
		return 0
	return AchievementSystem.moral_dilemma_count
func _on_close_pressed() -> void:
	hide()
func _on_refresh_pressed() -> void:
	_render_stats()
func show_stats() -> void:
	show()
	_render_stats()
