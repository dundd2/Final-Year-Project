extends Node
signal language_changed(new_language: String)
var _translations: Dictionary = { }
var _current_language: String = "en"
var _csv_path: String = "res://1.Codebase/localization/gda1_translations.csv"
const TRANSLATION_RESOURCE_PATHS := {
	"en": "res://1.Codebase/localization/gda1_translations.en.translation",
	"zh": "res://1.Codebase/localization/gda1_translations.zh.translation",
}
const FALLBACK_TRANSLATIONS := {
	"en": {
		"STAT_REALITY": "Reality Score",
		"STAT_POSITIVE": "Positive Energy",
		"STAT_ENTROPY": "Entropy Level",
		"PHASE_HONEYMOON": "Honeymoon Phase",
		"PHASE_NORMAL": "Normal Phase",
		"PHASE_CRISIS": "Crisis Phase",
		"TUTORIAL_first_stat_change": "Watch your Reality score. When it drops to 0 the game is over.",
		"TUTORIAL_first_prayer": "The prayer system lets you input positive wishes... then watch them turn into disasters.",
		"TUTORIAL_TITLE": "Tutorial Tip",
		"TUTORIAL_GOT_IT": "Got it!",
		"TUTORIAL_SKIP_ALL": "Skip all tutorials",
		"STORY_MISSION_GENERATION_INSTRUCTION": "Create a new mission scenario for the player.",
		"EVENT_PRAYER_RECORDED": "Prayer recorded: \"%s%s\"",
		"EVENT_PRAYER_LOGGED": "Prayer logged: \"%s\" | Reality %d, Positive %d",
	},
	"zh": {
		"STAT_REALITY": "現實值",
		"STAT_POSITIVE": "正能量",
		"STAT_ENTROPY": "熵等級",
		"PHASE_HONEYMOON": "蜜月期",
		"PHASE_NORMAL": "常態期",
		"PHASE_CRISIS": "危機期",
		"TUTORIAL_first_stat_change": "注意現實值。降到 0 時，遊戲立刻結束。",
		"TUTORIAL_first_prayer": "祈禱系統會把美好願望扭曲成災難，靜待反諷上演。",
		"TUTORIAL_TITLE": "教學提示",
		"TUTORIAL_GOT_IT": "我知道了",
		"TUTORIAL_SKIP_ALL": "跳過所有教學",
		"STORY_MISSION_GENERATION_INSTRUCTION": "為玩家創建一個新的任務情景。",
		"EVENT_PRAYER_RECORDED": "記錄祈禱：「%s%s」",
		"EVENT_PRAYER_LOGGED": "祈禱記錄：「%s」 | 現實值 %d，正能量 %d",
	},
}
func _ready() -> void:
	var resources_loaded = _load_translations_from_resources()
	_load_translations(resources_loaded)
	if GameState:
		_current_language = GameState.current_language
	var key_counts := []
	for lang in _translations.keys():
		key_counts.append("%s: %d" % [lang, _translations[lang].size()])
	print("[LocalizationManager] Initialized with language: %s" % _current_language)
	print("[LocalizationManager] Loaded translations: %s" % ", ".join(key_counts))
func _exit_tree() -> void:
	_translations.clear()
func _load_translations(merge_only: bool = false) -> void:
	if not merge_only:
		_translations.clear()
	var file := FileAccess.open(_csv_path, FileAccess.READ)
	if file == null:
		if merge_only:
			return 
		ErrorReporter.report_warning(
			"LocalizationManager",
			"Failed to load CSV, using fallback",
			{ "path": _csv_path },
		)
		_translations = FALLBACK_TRANSLATIONS.duplicate(true)
		return
	var headers: PackedStringArray = PackedStringArray()
	var line_number := 0
	while not file.eof_reached():
		var columns: PackedStringArray = file.get_csv_line()
		line_number += 1
		if columns.is_empty():
			continue
		var first_cell := columns[0].strip_edges()
		if first_cell.is_empty() or first_cell.begins_with("#"):
			continue
		if headers.is_empty():
			headers = columns
			for i in range(1, headers.size()):
				var lang := headers[i].strip_edges()
				if lang.is_empty():
					continue
				if not _translations.has(lang):
					_translations[lang] = { }
			continue
		var key := first_cell
		for i in range(1, headers.size()):
			var lang_header := headers[i].strip_edges()
			if lang_header.is_empty():
				continue
			if not _translations.has(lang_header):
				_translations[lang_header] = { }
			var value := ""
			if i < columns.size():
				value = columns[i].replace("\\n", "\n")
			_translations[lang_header][key] = value
	file.close()
	if _translations.is_empty():
		if merge_only:
			return
		ErrorReporter.report_warning(
			"LocalizationManager",
			"CSV did not yield translations; using fallback",
			{ "path": _csv_path },
		)
		_translations = FALLBACK_TRANSLATIONS.duplicate(true)
		return
	ErrorReporter.report_info(
		"LocalizationManager",
		"Loaded translations from CSV" + (" (merged)" if merge_only else ""),
		{ "languages": _translations.keys(), "keys": _translations.get("en", { }).size() },
	)
func get_translation(key: String, language: String = "") -> String:
	var lang = language if not language.is_empty() else _current_language
	if _translations.has(lang) and _translations[lang].has(key):
		return _translations[lang][key]
	if lang != "en" and _translations.has("en") and _translations["en"].has(key):
		return _translations["en"][key]
	if FALLBACK_TRANSLATIONS.has(lang) and FALLBACK_TRANSLATIONS[lang].has(key):
		return FALLBACK_TRANSLATIONS[lang][key]
	if FALLBACK_TRANSLATIONS.has("en") and FALLBACK_TRANSLATIONS["en"].has(key):
		return FALLBACK_TRANSLATIONS["en"][key]
	ErrorReporter.report_warning("LocalizationManager", "Translation key not found", { "key": key, "lang": lang })
	return key
func tr_stat(stat_id: String, language: String = "") -> String:
	var key = "STAT_" + stat_id.to_upper()
	return get_translation(key, language)
func tr_skill(skill_id: String, language: String = "") -> String:
	var key = "SKILL_" + skill_id.to_upper()
	return get_translation(key, language)
func tr_teammate(teammate_id: String, language: String = "") -> String:
	var key = "TEAMMATE_" + teammate_id.to_upper()
	return get_translation(key, language)
func tr_phase(phase_id: String, language: String = "") -> String:
	var key = "PHASE_" + phase_id.to_upper()
	return get_translation(key, language)
func tr_entropy_level(level_id: String, language: String = "") -> String:
	var key = "ENTROPY_LEVEL_" + level_id.to_upper()
	return get_translation(key, language)
func tr_reason(reason: String, language: String = "") -> String:
	var reason_map = {
		"正能量詛咒": "REASON_POSITIVE_CURSE",
		"Positive Energy Curse": "REASON_POSITIVE_CURSE",
		"禱告餘震": "REASON_PRAYER_AFTERSHOCK",
		"Prayer aftershock": "REASON_PRAYER_AFTERSHOCK",
		"Gloria的負能量控訴": "REASON_GLORIA_ACCUSATION",
		"Gloria's negative-energy accusation": "REASON_GLORIA_ACCUSATION",
		"陳老師的天啟演唱會": "REASON_TEACHER_CONCERT",
		"Teacher Chan's apocalypse concert": "REASON_TEACHER_CONCERT",
		"被迫附和聖母": "REASON_FORCED_ECHO",
		"Forced to echo Gloria": "REASON_FORCED_ECHO",
		"任務「成功」": "REASON_MISSION_SUCCESS",
		"Mission \"success\" backlash": "REASON_MISSION_SUCCESS",
		"任務餘波": "REASON_MISSION_AFTERSHOCK",
		"Mission aftershock": "REASON_MISSION_AFTERSHOCK",
	}
	var trimmed = reason.strip_edges()
	if trimmed.is_empty():
		return ""
	if reason_map.has(trimmed):
		return get_translation(reason_map[trimmed], language)
	return trimmed
func set_language(language: String) -> void:
	if not _translations.has(language):
		ErrorReporter.report_warning("LocalizationManager", "Language not available", { "language": language })
		return
	var old_language = _current_language
	_current_language = language
	if GameState:
		GameState.current_language = language
	language_changed.emit(language)
	ErrorReporter.report_info("LocalizationManager", "Language changed", { "from": old_language, "to": language })
func get_language() -> String:
	return _current_language
func get_available_languages() -> Array:
	return _translations.keys()
func has_language(language: String) -> bool:
	return _translations.has(language)
func get_all_keys() -> Array:
	if _translations.has("en"):
		return _translations["en"].keys()
	return []
func reload_translations() -> void:
	_translations.clear()
	_load_translations()
	ErrorReporter.report_info("LocalizationManager", "Translations reloaded")
func _load_translations_from_resources() -> bool:
	var loaded := false
	for lang in TRANSLATION_RESOURCE_PATHS.keys():
		var path: String = TRANSLATION_RESOURCE_PATHS[lang]
		if not ResourceLoader.exists(path):
			continue
		var translation: Translation = ResourceLoader.load(path)
		if translation == null:
			continue
		if not _translations.has(lang):
			_translations[lang] = { }
		for key in translation.get_message_list():
			_translations[lang][key] = translation.get_message(key)
		loaded = true
	if loaded:
		ErrorReporter.report_info(
			"LocalizationManager",
			"Loaded translations from .translation resources",
			{ "languages": TRANSLATION_RESOURCE_PATHS.keys() },
		)
	return loaded
