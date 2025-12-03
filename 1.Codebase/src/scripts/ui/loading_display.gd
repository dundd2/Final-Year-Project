extends RefCounted
const LOADING_PHRASES_EN := [
	"Generating story...",
	"Consulting the AI oracle...",
	"Weaving narrative threads...",
	"Calculating consequences...",
	"Manifesting reality...",
	"Processing your choices...",
	"Brewing plot developments...",
	"Summoning story elements...",
]
const LOADING_PHRASES_ZH := [
	"生成故事中...",
	"諮詢AI神諭...",
	"編織敘事線索...",
	"計算後果中...",
	"顯現現實...",
	"處理你的選擇...",
	"醞釀劇情發展...",
	"召喚故事元素...",
]
const LOADING_DOTS_SEQUENCE := ["", ".", "..", "..."]
static func get_random_loading_phrase(lang: String) -> String:
	var phrases := LOADING_PHRASES_EN if lang == "en" else LOADING_PHRASES_ZH
	return phrases[randi() % phrases.size()]
static func get_loading_dots_for_time(animation_time: float) -> String:
	var dots_index := int(animation_time * 2) % LOADING_DOTS_SEQUENCE.size()
	return LOADING_DOTS_SEQUENCE[dots_index]
static func format_elapsed_time(elapsed_seconds: float) -> String:
	var minutes := int(elapsed_seconds) / 60
	var seconds := int(elapsed_seconds) % 60
	return "%02d:%02d" % [minutes, seconds]
static func get_loading_sublabel(context: String, lang: String) -> String:
	const SUBLABELS := {
		"mission": {
			"en": "Preparing your next mission...",
			"zh": "準備下一個任務...",
		},
		"choice": {
			"en": "Processing your decision...",
			"zh": "處理你的決定...",
		},
		"consequence": {
			"en": "Calculating consequences...",
			"zh": "計算後果中...",
		},
		"night": {
			"en": "The night unfolds...",
			"zh": "夜幕降臨...",
		},
		"interference": {
			"en": "Someone intervenes...",
			"zh": "有人介入...",
		},
		"gloria": {
			"en": "Gloria has something to say...",
			"zh": "Gloria有話要說...",
		},
		"trolley": {
			"en": "A dilemma emerges...",
			"zh": "難題浮現...",
		},
		"default": {
			"en": "Loading...",
			"zh": "載入中...",
		},
	}
	if context in SUBLABELS and lang in SUBLABELS[context]:
		return SUBLABELS[context][lang]
	return SUBLABELS["default"][lang]
class LoadingConfig extends RefCounted:
	var main_text: String = ""
	var sub_text: String = ""
	var show_timer: bool = true
	var show_model: bool = true
	var show_dots: bool = true
	var context: String = "default"
	func _init(p_context: String = "default") -> void:
		context = p_context
static func create_mission_loading_config(lang: String) -> LoadingConfig:
	var config := LoadingConfig.new("mission")
	config.main_text = get_random_loading_phrase(lang)
	config.sub_text = get_loading_sublabel("mission", lang)
	return config
static func create_choice_loading_config(lang: String) -> LoadingConfig:
	var config := LoadingConfig.new("choice")
	config.main_text = get_random_loading_phrase(lang)
	config.sub_text = get_loading_sublabel("choice", lang)
	return config
static func create_consequence_loading_config(lang: String) -> LoadingConfig:
	var config := LoadingConfig.new("consequence")
	config.main_text = get_random_loading_phrase(lang)
	config.sub_text = get_loading_sublabel("consequence", lang)
	return config
static func parse_progress_update(update: Dictionary) -> Dictionary:
	var result := {
		"stage": update.get("stage", "processing"),
		"message": update.get("message", ""),
		"percent": float(update.get("progress", 0.0)),
		"tokens": int(update.get("tokens_used", 0)),
		"model": update.get("model", ""),
	}
	return result
static func get_progress_display_text(progress_info: Dictionary, lang: String) -> String:
	var stage: String = progress_info.get("stage", "processing")
	var message: String = progress_info.get("message", "")
	if not message.is_empty():
		return message
	const STAGE_LABELS := {
		"starting": {
			"en": "Initializing AI request...",
			"zh": "初始化AI請求...",
		},
		"processing": {
			"en": "AI is thinking...",
			"zh": "AI思考中...",
		},
		"streaming": {
			"en": "Receiving response...",
			"zh": "接收回應中...",
		},
		"complete": {
			"en": "Complete!",
			"zh": "完成！",
		},
	}
	if stage in STAGE_LABELS and lang in STAGE_LABELS[stage]:
		return STAGE_LABELS[stage][lang]
	return get_random_loading_phrase(lang)
