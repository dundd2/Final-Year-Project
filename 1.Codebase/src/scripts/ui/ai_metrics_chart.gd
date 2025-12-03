extends Control
var response_time_data: Array = []
var token_usage_data: Array = []
const LINE_COLOR_RESPONSE_TIME = Color(0.3, 0.8, 1.0) 
const LINE_COLOR_TOKEN_USAGE = Color(1.0, 0.6, 0.3) 
const GRID_COLOR = Color(0.5, 0.5, 0.5, 0.2)
const TEXT_COLOR = Color(0.8, 0.8, 0.8)
func _draw():
	var rect = get_rect()
	var width = rect.size.x
	var height = rect.size.y
	draw_rect(rect, Color(0.1, 0.1, 0.1, 0.8), true)
	var grid_lines = 5
	for i in range(grid_lines):
		var y_pos = height / (grid_lines - 1) * i
		draw_line(Vector2(0, y_pos), Vector2(width, y_pos), GRID_COLOR, 1.0)
		var x_pos = width / (grid_lines - 1) * i
		draw_line(Vector2(x_pos, 0), Vector2(x_pos, height), GRID_COLOR, 1.0)
	if not response_time_data.is_empty():
		_draw_chart_line(response_time_data, LINE_COLOR_RESPONSE_TIME, "s")
	if not token_usage_data.is_empty():
		_draw_chart_line(token_usage_data, LINE_COLOR_TOKEN_USAGE, "tokens")
func _draw_chart_line(data: Array, color: Color, unit: String):
	var rect = get_rect()
	var width = rect.size.x
	var height = rect.size.y
	if data.is_empty():
		return
	var max_value = 0.0
	for val in data:
		max_value = max(max_value, val)
	max_value = max(max_value, 0.1) 
	var points: Array[Vector2] = []
	var step_x = width / (data.size() - 1.0) if data.size() > 1 else 0.0
	for i in range(data.size()):
		var x = i * step_x
		var y = height - (data[i] / max_value) * height
		points.append(Vector2(x, y))
	if points.size() > 1:
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], color, 2.0)
	var min_val = INF
	var max_val = -INF
	if not data.is_empty():
		min_val = data.min()
		max_val = data.max()
	var font = get_theme_font("font")
	var font_size = get_theme_font_size("font_size")
	if font and font_size:
		var max_text = "%.2f %s" % [max_val, unit]
		var max_text_size = font.get_string_size(max_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, Vector2(width - max_text_size.x - 5, max_text_size.y + 5), max_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TEXT_COLOR)
		if min_val != max_val:
			var min_text = "%.2f %s" % [min_val, unit]
			draw_string(font, Vector2(5, height - 5), min_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TEXT_COLOR)
func set_data(response_times: Array, token_usages: Array):
	response_time_data = response_times
	token_usage_data = token_usages
	queue_redraw() 
