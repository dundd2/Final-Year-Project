extends Control
@onready var icon_rect: TextureRect = $Panel/MarginContainer/HBoxContainer/IconPanel/Icon
@onready var name_label: Label = $Panel/MarginContainer/HBoxContainer/Details/NameLabel
@onready var tags_list_label: Label = $Panel/MarginContainer/HBoxContainer/Details/TagsContainer/TagsList
@onready var tags_label: Label = $Panel/MarginContainer/HBoxContainer/Details/TagsContainer/TagsLabel
@onready var summary_label: Label = $Panel/MarginContainer/HBoxContainer/Details/SummaryLabel
@onready var hover_effect: ColorRect = $Panel/HoverEffect
const TRANSLATION_KEY_NO_TAGS := "ASSET_NO_TAGS"
const TRANSLATION_KEY_NO_DESCRIPTION := "ASSET_NO_DESCRIPTION"
const FALLBACK_NO_TAGS := "No tags"
const FALLBACK_NO_DESCRIPTION := "No description"
var asset_data: Dictionary = { }
func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_localize_ui()
func _localize_ui() -> void:
	var lang: String = _get_current_language()
	if tags_label:
		tags_label.text = _get_translation("ASSET_TAGS_LABEL", lang)
func set_asset(asset: Dictionary, fallback_icon: Texture2D = null) -> void:
	asset_data = asset.duplicate(true)
	if name_label == null or tags_list_label == null or summary_label == null or icon_rect == null:
		call_deferred("_update_asset_data", asset, fallback_icon)
		return
	_update_asset_data(asset, fallback_icon)
func _update_asset_data(asset: Dictionary, fallback_icon: Texture2D = null) -> void:
	if name_label == null:
		return
	var lang: String = _get_current_language()
	_localize_ui()
	var display_name_value = asset.get("display_name", asset.get("default_name", asset.get("id", "Unknown Asset")))
	var display_name: String = str(display_name_value)
	name_label.text = display_name
	var tags: Array = asset.get("tags", [])
	if tags.size() > 0:
		tags_list_label.text = ", ".join(tags)
	else:
		tags_list_label.text = _get_localized_fallback(TRANSLATION_KEY_NO_TAGS, FALLBACK_NO_TAGS, lang)
	var description_value = asset.get("description", asset.get("summary", ""))
	var description: String = str(description_value)
	if description != "":
		summary_label.text = description
		summary_label.tooltip_text = description
	else:
		var fallback := _get_localized_fallback(TRANSLATION_KEY_NO_DESCRIPTION, FALLBACK_NO_DESCRIPTION, lang)
		summary_label.text = fallback
		summary_label.tooltip_text = fallback
	var icon_path = asset.get("icon", "")
	var texture: Texture2D = null
	if icon_path != "" and ResourceLoader.exists(icon_path):
		texture = load(icon_path)
	elif fallback_icon:
		texture = fallback_icon
	if texture:
		icon_rect.texture = texture
	else:
		icon_rect.texture = null
func highlight(active: bool) -> void:
	if active:
		$Panel.modulate = Color(1.1, 1.1, 1.1, 1)
		if hover_effect:
			hover_effect.visible = true
	else:
		$Panel.modulate = Color(1, 1, 1, 1)
		if hover_effect:
			hover_effect.visible = false
func _on_mouse_entered() -> void:
	highlight(true)
	var hover_sound_path = "res://1.Codebase/src/assets/sound/menu_click.mp3"
	if ResourceLoader.exists(hover_sound_path):
		pass
func _on_mouse_exited() -> void:
	highlight(false)
func get_asset_id() -> String:
	return asset_data.get("id", "")
func get_asset_data() -> Dictionary:
	return asset_data.duplicate(true)
func _get_current_language() -> String:
	var localization_manager = ServiceLocator.get_localization_manager()
	if localization_manager != null and localization_manager.has_method("get_language"):
		var language: String = localization_manager.get_language()
		if not language.is_empty():
			return language
	var game_state = ServiceLocator.get_game_state()
	if game_state != null:
		var lang_value = game_state.get("current_language")
		if typeof(lang_value) == TYPE_STRING:
			var lang_string := String(lang_value)
			if not lang_string.is_empty():
				return lang_string
	return GameConstants.Language.DEFAULT_LANGUAGE
func _get_localized_fallback(key: String, fallback: String, language: String) -> String:
	var translated = _get_translation(key, language)
	if translated != key and not translated.is_empty():
		return translated
	return fallback
func _get_translation(key: String, language: String) -> String:
	var localization_manager = ServiceLocator.get_localization_manager()
	if localization_manager != null and localization_manager.has_method("get_translation"):
		return localization_manager.get_translation(key, language)
	return key
