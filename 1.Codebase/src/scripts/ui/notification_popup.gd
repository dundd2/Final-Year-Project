extends PanelContainer
const UIStyleManager = preload("res://1.Codebase/src/scripts/ui/ui_style_manager.gd")
@onready var icon_label: Label = $MarginContainer/HBoxContainer/IconLabel
@onready var message_label: Label = $MarginContainer/HBoxContainer/MessageLabel 
var lifetime: float = 3.0
var fade_duration: float = 0.3
func setup(title: String, description: String, color: Color, duration: float):
	lifetime = duration
	icon_label.modulate = color
	var hbox = icon_label.get_parent()
	var content_vbox = hbox.get_node_or_null("ContentVBox")
	if not content_vbox:
		content_vbox = VBoxContainer.new()
		content_vbox.name = "ContentVBox"
		content_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
		content_vbox.size_flags_vertical = SIZE_SHRINK_CENTER
		hbox.add_child(content_vbox)
		hbox.move_child(content_vbox, 1)
		message_label.visible = false
	for child in content_vbox.get_children():
		child.queue_free()
	var lbl_title = Label.new()
	lbl_title.text = title
	lbl_title.add_theme_font_size_override("font_size", 16) 
	lbl_title.modulate = Color.WHITE 
	content_vbox.add_child(lbl_title)
	if not description.is_empty():
		var lbl_desc = Label.new()
		lbl_desc.text = description
		lbl_desc.add_theme_font_size_override("font_size", 14) 
		lbl_desc.modulate = Color(0.9, 0.9, 0.9, 0.9) 
		lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_desc.size_flags_horizontal = SIZE_EXPAND_FILL
		content_vbox.add_child(lbl_desc)
	custom_minimum_size = Vector2(0, 0)
	size_flags_vertical = SIZE_SHRINK_CENTER
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.12, 0.16, 0.95)
	style_box.border_color = color
	style_box.border_width_left = 3
	style_box.border_width_top = 3
	style_box.border_width_right = 3
	style_box.border_width_bottom = 3
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	style_box.shadow_color = Color(0, 0, 0, 0.5)
	style_box.shadow_size = 8
	style_box.shadow_offset = Vector2(0, 4)
	style_box.content_margin_left = 12
	style_box.content_margin_top = 10
	style_box.content_margin_right = 12
	style_box.content_margin_bottom = 10
	add_theme_stylebox_override("panel", style_box)
	if color.r > 0.8 and color.g < 0.5: 
		icon_label.text = "❌"
	elif color.r > 0.8 and color.g > 0.6: 
		icon_label.text = "⚠"
	elif color.g > 0.8 and color.r < 0.5: 
		icon_label.text = "✓"
	else: 
		icon_label.text = "ℹ"
	_animate_entrance()
	await get_tree().create_timer(lifetime).timeout
	_animate_exit()
func _animate_entrance():
	position.y -= 30
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position:y", position.y + 30, 0.4)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4)
func _animate_exit():
	if not is_inside_tree(): return 
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), fade_duration)
	await tween.finished
	queue_free()
func dismiss():
	_animate_exit()
