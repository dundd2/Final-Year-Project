extends RefCounted
static func parse_markdown(text: String) -> String:
	var result = text
	result = _parse_headers(result)
	result = _parse_bold(result)
	result = _parse_italic(result)
	result = _parse_strikethrough(result)
	result = _parse_code_blocks(result)
	result = _parse_inline_code(result)
	result = _parse_links(result)
	result = _parse_lists(result)
	result = _parse_blockquotes(result)
	return result
static func _parse_headers(text: String) -> String:
	var lines = text.split("\n")
	var result_lines = []
	for line in lines:
		var trimmed = line.strip_edges(true, false) 
		if trimmed.begins_with("#"):
			var header_match = RegEx.create_from_string("^(#{1,6})\\s+(.+)$")
			var match_result = header_match.search(trimmed)
			if match_result:
				var level = match_result.get_string(1).length()
				var content = match_result.get_string(2)
				var font_sizes = {
					1: 32, 
					2: 28, 
					3: 24, 
					4: 20, 
					5: 18, 
					6: 16, 
				}
				var size = font_sizes.get(level, 16)
				var formatted = "[font_size=%d][b]%s[/b][/font_size]" % [size, content]
				result_lines.append(formatted)
				continue
		result_lines.append(line)
	return "\n".join(result_lines)
static func _parse_bold(text: String) -> String:
	var regex_double_star = RegEx.create_from_string("\\*\\*([^*]+)\\*\\*")
	var result = regex_double_star.sub(text, "[b]$1[/b]", true)
	var regex_double_underscore = RegEx.create_from_string("__([^_]+)__")
	result = regex_double_underscore.sub(result, "[b]$1[/b]", true)
	return result
static func _parse_italic(text: String) -> String:
	var regex_star = RegEx.create_from_string("(?<!\\*)\\*(?!\\*)([^*]+)\\*(?!\\*)")
	var result = regex_star.sub(text, "[i]$1[/i]", true)
	var regex_underscore = RegEx.create_from_string("(?<!_)_(?!_)([^_]+)_(?!_)")
	result = regex_underscore.sub(result, "[i]$1[/i]", true)
	return result
static func _parse_strikethrough(text: String) -> String:
	var regex = RegEx.create_from_string("~~([^~]+)~~")
	return regex.sub(text, "[s]$1[/s]", true)
static func _parse_code_blocks(text: String) -> String:
	var regex = RegEx.create_from_string("```([^`]+)```")
	return regex.sub(text, "[code]$1[/code]", true)
static func _parse_inline_code(text: String) -> String:
	var regex = RegEx.create_from_string("`([^`]+)`")
	return regex.sub(text, "[code]$1[/code]", true)
static func _parse_links(text: String) -> String:
	var regex = RegEx.create_from_string("\\[([^\\]]+)\\]\\(([^)]+)\\)")
	return regex.sub(text, "[url=$2]$1[/url]", true)
static func _parse_lists(text: String) -> String:
	var lines = text.split("\n")
	var result_lines = []
	for line in lines:
		var trimmed = line.strip_edges(true, false)
		if trimmed.begins_with("- ") or trimmed.begins_with("* "):
			var content = trimmed.substr(2)
			result_lines.append("  • " + content)
		else:
			result_lines.append(line)
	return "\n".join(result_lines)
static func _parse_blockquotes(text: String) -> String:
	var lines = text.split("\n")
	var result_lines = []
	for line in lines:
		var trimmed = line.strip_edges(true, false)
		if trimmed.begins_with("> "):
			var content = trimmed.substr(2)
			result_lines.append("[color=#888888][i]  │ " + content + "[/i][/color]")
		else:
			result_lines.append(line)
	return "\n".join(result_lines)
