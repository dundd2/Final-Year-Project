extends Node
signal font_size_changed(scale: float)
enum FontSize {
	TINY = 0, 
	SMALL = 1, 
	NORMAL = 2, 
	LARGE = 3, 
	HUGE = 4, 
}
var font_size_multipliers = {
	FontSize.TINY: 0.75,
	FontSize.SMALL: 0.85,
	FontSize.NORMAL: 1.0,
	FontSize.LARGE: 1.25,
	FontSize.HUGE: 1.5,
}
var current_font_size: int = FontSize.NORMAL
var current_multiplier: float = 1.0
const FALLBACK_FONT: Font = preload("res://1.Codebase/src/assets/font/LibreBaskerville-Bold.ttf")
const REGISTERED_FONTS: Array[Font] = [
	preload("res://1.Codebase/src/assets/font/LibreBaskerville-Bold.ttf"),
	preload("res://1.Codebase/src/assets/font/Play-Regular.ttf"),
	preload("res://1.Codebase/src/assets/font/Ticketing.ttf"),
	preload("res://1.Codebase/src/assets/font/britrdn_.ttf"),
]
func _ready():
	load_font_settings()
	_register_font_fallbacks()
	print("FontManager initialized. Font size: ", get_font_size_name())
func set_font_size(size: int):
	if size in font_size_multipliers:
		current_font_size = size
		current_multiplier = font_size_multipliers[size]
		font_size_changed.emit(current_multiplier)
		save_font_settings()
		print("Font size changed to: ", get_font_size_name(), " (", current_multiplier, "x)")
func get_font_size() -> int:
	return current_font_size
func get_multiplier() -> float:
	return current_multiplier
func get_font_size_name() -> String:
	match current_font_size:
		FontSize.TINY:
			return "Tiny"
		FontSize.SMALL:
			return "Small"
		FontSize.NORMAL:
			return "Normal"
		FontSize.LARGE:
			return "Large"
		FontSize.HUGE:
			return "Huge"
		_:
			return "Unknown"
func get_scaled_font_size(base_size: int) -> int:
	return int(float(base_size) * current_multiplier)
func apply_to_label(label: Label, base_size: int):
	if label:
		label.add_theme_font_size_override("font_size", get_scaled_font_size(base_size))
func apply_to_button(button: Button, base_size: int):
	if button:
		button.add_theme_font_size_override("font_size", get_scaled_font_size(base_size))
func apply_to_rich_text(rich_text: RichTextLabel, base_size: int):
	if rich_text:
		rich_text.add_theme_font_size_override("normal_font_size", get_scaled_font_size(base_size))
func save_font_settings():
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("display", "font_size", current_font_size)
	config.save("user://settings.cfg")
func load_font_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		current_font_size = config.get_value("display", "font_size", FontSize.NORMAL)
		current_multiplier = font_size_multipliers.get(current_font_size, 1.0)
func _register_font_fallbacks() -> void:
	if FALLBACK_FONT == null:
		push_warning("[FontManager] Fallback font is null, skipping fallback registration")
		return
	if not _is_font_valid(FALLBACK_FONT):
		push_error("[FontManager] Fallback font is invalid")
		return
	for font in REGISTERED_FONTS:
		if font == null:
			push_warning("[FontManager] Skipping null font in REGISTERED_FONTS")
			continue
		if not _is_font_valid(font):
			push_warning("[FontManager] Skipping invalid font in REGISTERED_FONTS")
			continue
		print("[FontManager] Processing font: ", font.resource_path)
		if not font.has_method("get_fallbacks") or not font.has_method("add_fallback"):
			continue
		var fallbacks := font.get_fallbacks()
		if FALLBACK_FONT in fallbacks:
			continue
		if not _is_font_valid(FALLBACK_FONT):
			push_error("[FontManager] Fallback font is invalid, cannot add as fallback")
			return
		font.add_fallback(FALLBACK_FONT)
func _is_font_valid(font: Font) -> bool:
	if font == null:
		return false
	if font.resource_path.is_empty():
		return false
	if font is FontFile:
		var font_file = font as FontFile
		if font_file.data.is_empty() and font_file.resource_path.is_empty():
			return false
	return true
func get_safe_font(primary_font: Font) -> Font:
	if _is_font_valid(primary_font):
		return primary_font
	push_warning("[FontManager] Primary font invalid, using fallback")
	return FALLBACK_FONT if _is_font_valid(FALLBACK_FONT) else null
