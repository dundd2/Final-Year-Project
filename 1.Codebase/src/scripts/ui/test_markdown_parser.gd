extends Node
const MarkdownParser = preload("res://1.Codebase/src/scripts/ui/markdown_parser.gd")
func _ready():
	print("=== Markdown Parser Tests ===\n")
	test_headers()
	test_bold()
	test_italic()
	test_mixed_formatting()
	test_lists()
	test_blockquotes()
	test_code()
	print("\n=== All Tests Complete ===")
func _assert_equal(actual: String, expected: String, test_name: String) -> void:
	var message = "\n%s failed.\nExpected: %s\nActual: %s\n" % [test_name, expected, actual]
	assert(actual == expected, message)
	print("PASS: %s" % test_name)
func test_headers():
	var input = "# Heading 1\n## Heading 2\n### Heading 3"
	var output = MarkdownParser.parse_markdown(input)
	var expected = "[font_size=32][b]Heading 1[/b][/font_size]\n"
	expected += "[font_size=28][b]Heading 2[/b][/font_size]\n"
	expected += "[font_size=24][b]Heading 3[/b][/font_size]"
	_assert_equal(output, expected, "Headers")
func test_bold():
	var input = "This is **bold text** and __also bold__"
	var output = MarkdownParser.parse_markdown(input)
	var expected = "This is [b]bold text[/b] and [b]also bold[/b]"
	_assert_equal(output, expected, "Bold formatting")
func test_italic():
	var input = "This is *italic text* and _also italic_"
	var output = MarkdownParser.parse_markdown(input)
	var expected = "This is [i]italic text[/i] and [i]also italic[/i]"
	_assert_equal(output, expected, "Italic formatting")
func test_mixed_formatting():
	var input = "**Bold** and *italic* and ***both***"
	var output = MarkdownParser.parse_markdown(input)
	var expected = "[b]Bold[/b] and [i]italic[/i] and [i][b]both[/b][/i]"
	_assert_equal(output, expected, "Mixed bold and italic formatting")
func test_lists():
	var input = "- Item 1\n- Item 2\n* Item 3"
	var output = MarkdownParser.parse_markdown(input)
	var expected = "  • Item 1\n  • Item 2\n  • Item 3"
	_assert_equal(output, expected, "Unordered lists")
func test_blockquotes():
	var input = "> This is a quote\n> Another line"
	var output = MarkdownParser.parse_markdown(input)
	var expected = "[color=#888888][i]  │ This is a quote[/i][/color]\n"
	expected += "[color=#888888][i]  │ Another line[/i][/color]"
	_assert_equal(output, expected, "Blockquotes")
func test_code():
	var input = "Inline `code here` and block ```code block```"
	var output = MarkdownParser.parse_markdown(input)
	var expected = "Inline [code]code here[/code] and block [code]code block[/code]"
	_assert_equal(output, expected, "Inline and block code")
func example_ai_output():
	var ai_text = """# Mission Update

You've discovered something **critical** about the team's mission.

## Current Situation:
- Reality Score: *dangerously low*
- Positive Energy: **increasing rapidly**
- Your teammates are making things ~~better~~ worse

> "Everything is fine!" - Gloria says, while the world crumbles.

What will you do?
"""
	print("=== Example AI Output ===")
	print("Raw markdown:")
	print(ai_text)
	print("\nParsed BBCode:")
	print(MarkdownParser.parse_markdown(ai_text))
