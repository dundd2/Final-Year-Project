extends Node
func _ready():
	print("\n" + "=".repeat(60))
	print("SCENE DIRECTIVES SYSTEM TEST")
	print("=".repeat(60) + "\n")
	test_character_expression_loader()
	test_background_loader()
	test_ai_directive_parsing()
	test_scene_directive_application()
	test_bbcode_balancing()
	test_fuzzy_asset_matching()
	print("\n" + "=".repeat(60))
	print("ALL TESTS COMPLETED")
	print("=".repeat(60) + "\n")
func test_character_expression_loader():
	print("\n--- Test 1: Character Expression Loader ---")
	if not CharacterExpressionLoader:
		print("??FAIL: CharacterExpressionLoader not available")
		return
	print("??CharacterExpressionLoader is available")
	var characters = CharacterExpressionLoader.get_all_characters()
	print("??Found %d characters: %s" % [characters.size(), ", ".join(characters)])
	for char_id in characters:
		var char_name = CharacterExpressionLoader.get_character_name(char_id)
		print("\nTesting character: %s (%s)" % [char_name, char_id])
		var texture = CharacterExpressionLoader.get_character_texture(char_id, "neutral")
		if texture:
			print("  ??Loaded neutral expression")
		else:
			print("  ??No neutral expression (using fallback)")
		var expressions = CharacterExpressionLoader.get_available_expressions(char_id)
		print("  Available expressions: %s" % ", ".join(expressions))
	print("\n??Character Expression Loader test complete")
func test_background_loader():
	print("\n--- Test 2: Background Loader ---")
	if not BackgroundLoader:
		print("??FAIL: BackgroundLoader not available")
		return
	print("??BackgroundLoader is available")
	var bg_ids = BackgroundLoader.get_all_background_ids()
	print("??Found %d backgrounds" % bg_ids.size())
	var test_backgrounds = ["default", "forest", "cave", "temple", "safe_zone"]
	for bg_id in test_backgrounds:
		var texture = BackgroundLoader.get_background_texture(bg_id)
		var bg_info = BackgroundLoader.get_background_info(bg_id)
		if texture:
			var is_placeholder = bg_info.get("is_placeholder", false)
			var status = "placeholder" if is_placeholder else "proper texture"
			print("  ??Loaded '%s' (%s)" % [bg_id, status])
		else:
			print("  ??Failed to load '%s'" % bg_id)
	var ai_prompt = BackgroundLoader.get_backgrounds_for_ai_prompt()
	if ai_prompt.length() > 0:
		print("??Generated AI prompt with %d characters" % ai_prompt.length())
	else:
		print("??Failed to generate AI prompt")
	print("\n??Background Loader test complete")
func test_ai_directive_parsing():
	print("\n--- Test 3: AI Directive Parsing ---")
	if not AIManager:
		print("??FAIL: AIManager not available")
		return
	print("??AIManager is available")
	var test_response_1 = """
Here's the story content...

[SCENE_DIRECTIVES]
{
  "scene": {
	"background": "forest",
	"atmosphere": "mysterious",
	"lighting": "dim"
  },
  "characters": {
	"protagonist": {"expression": "confused", "visible": true},
	"gloria": {"expression": "angry", "visible": true}
  },
  "assets": [
	{"id": "Generic_Lever", "contextual_name": "Ancient Control Lever", "description": "A mysterious lever"}
  ]
}
[/SCENE_DIRECTIVES]
"""
	var directives_1 = AIManager.parse_scene_directives(test_response_1)
	if directives_1.has("scene") and directives_1.has("characters"):
		print("??Successfully parsed valid scene directives")
		print("  - Scene data: %s" % str(directives_1.get("scene", { })))
		print("  - Characters: %s" % str(directives_1["characters"].keys()))
		print("  - Assets: %d" % directives_1.get("assets", []).size())
	else:
		print("??Failed to parse valid scene directives")
	var story_content = AIManager.extract_story_content(test_response_1)
	if not "[SCENE_DIRECTIVES]" in story_content:
		print("??Successfully extracted story content (directives removed)")
	else:
		print("??Failed to remove scene directives from story content")
	var test_response_2 = "Just a regular story without directives"
	var directives_2 = AIManager.parse_scene_directives(test_response_2)
	if directives_2.is_empty():
		print("??Correctly handled response without directives")
	else:
		print("??Incorrectly parsed non-directive content")
	print("\n??AI Directive Parsing test complete")
func test_scene_directive_application():
	print("\n--- Test 4: Scene Directive Application ---")
	var story_scene_script = load("res://1.Codebase/src/scripts/ui/story_scene.gd")
	if story_scene_script:
		print("??Story scene script loaded")
		var required_methods = [
			"apply_scene_directives",
			"_apply_scene_settings",
			"_apply_character_directives",
			"_apply_asset_directives",
			"_transition_background",
			"_transition_character_expression",
			"_transition_character_visibility",
		]
		for method_name in required_methods:
			if story_scene_script.has_method(method_name):
				print("  ??Function exists: %s" % method_name)
			else:
				print("  ??Missing function: %s" % method_name)
	else:
		print("??Failed to load story scene script")
	print("\n??Scene Directive Application test complete")
func test_bbcode_balancing():
	print("\n--- Test 5: BBCode Tag Balancing ---")
	var StoryUIHelper = load("res://1.Codebase/src/scripts/ui/story_ui_helper.gd")
	if not StoryUIHelper:
		print("??FAIL: StoryUIHelper not available")
		return
	print("??StoryUIHelper loaded")
	var test_1 = "This is [b]bold text without closing"
	var result_1 = StoryUIHelper.sanitize_story_text(test_1)
	if result_1.count("[b]") == result_1.count("[/b]"):
		print("??Auto-closed unclosed [b] tag")
	else:
		print("??Failed to balance [b] tag")
	var test_2 = "[b]Bold [i]italic [u]underline"
	var result_2 = StoryUIHelper.sanitize_story_text(test_2)
	var balanced = result_2.count("[b]") == result_2.count("[/b]") and \
	result_2.count("[i]") == result_2.count("[/i]") and \
	result_2.count("[u]") == result_2.count("[/u]")
	if balanced:
		print("??Balanced multiple nested tags")
	else:
		print("??Failed to balance nested tags")
	var test_3 = "**Bold text** and *italic text*"
	var result_3 = StoryUIHelper.sanitize_story_text(test_3)
	if result_3.count("[b]") == result_3.count("[/b]") and \
	result_3.count("[i]") == result_3.count("[/i]"):
		print("??Markdown converted and balanced")
	else:
		print("??Markdown conversion unbalanced")
	var test_4 = "[b]Bold[/b] and [i]italic[/i] text"
	var result_4 = StoryUIHelper.sanitize_story_text(test_4)
	if result_4.count("[b]") == result_4.count("[/b]") and \
	result_4.count("[i]") == result_4.count("[/i]"):
		print("??Already balanced tags preserved")
	else:
		print("??Broke already balanced tags")
	print("\n??BBCode Tag Balancing test complete")
func test_fuzzy_asset_matching():
	print("\n--- Test 6: Fuzzy Asset Matching ---")
	if not AIManager:
		print("??FAIL: AIManager not available")
		return
	print("??AIManager is available")
	var test_response_1 = """
[SCENE_DIRECTIVES]
{
  "scene": {"background": "forest"},
  "assets": [
	{"id": "Generic Lever", "contextual_name": "Old Lever"},
	{"id": "generic lever", "contextual_name": "Rusty Lever"}
  ]
}
[/SCENE_DIRECTIVES]
"""
	var directives_1 = AIManager.parse_scene_directives(test_response_1)
	if directives_1.has("assets") and directives_1["assets"].size() > 0:
		var first_asset = directives_1["assets"][0]
		var asset_id = first_asset.get("id", "")
		if asset_id == "Generic_Lever" or AssetRegistry.get_asset(asset_id).size() > 0:
			print("??Fuzzy matched 'Generic Lever' -> valid asset ID")
		else:
			print("??Asset ID '%s' may not be canonical" % asset_id)
	else:
		print("??Failed to parse test directives")
	var test_response_2 = """
[SCENE_DIRECTIVES]
{
  "assets": [
	{"id": "GENERIC_MONSTER", "contextual_name": "Scary Beast"}
  ]
}
[/SCENE_DIRECTIVES]
"""
	var directives_2 = AIManager.parse_scene_directives(test_response_2)
	if directives_2.has("assets") and directives_2["assets"].size() > 0:
		var asset = directives_2["assets"][0]
		var asset_id = asset.get("id", "")
		if AssetRegistry.get_asset(asset_id).size() > 0:
			print("??Case-insensitive match successful")
		else:
			print("??Case match may need improvement")
	else:
		print("??Failed to parse case test")
	var test_response_3 = """
[SCENE_DIRECTIVES]
{
  "scene": {"background": "Crystal Cavern"},
  "characters": {"protagonist": {"expression": "shocked"}}
}
[/SCENE_DIRECTIVES]
"""
	var directives_3 = AIManager.parse_scene_directives(test_response_3)
	if directives_3.has("scene") and directives_3["scene"].has("background"):
		var bg_id = directives_3["scene"]["background"]
		if BackgroundLoader.get_background_texture(bg_id) != null:
			print("??Background ID normalized successfully")
		else:
			print("??Background '%s' may not exist" % bg_id)
	else:
		print("??Failed to parse background test")
	var test_response_4 = """
The team enters a dark chamber...

[SCENE_DIRECTIVES]
{
  "scene": {"background": "dungeon", "atmosphere": "dark", "lighting": "dim"},
  "characters": {
	"protagonist": {"expression": "confused", "visible": true},
	"gloria": {"expression": "happy", "visible": true}
  },
  "assets": [
	{"id": "ancient statue", "contextual_name": "Crumbling Statue"},
	{"id": "Generic_Chest", "contextual_name": "Locked Chest"}
  ]
}
[/SCENE_DIRECTIVES]
"""
	var directives_4 = AIManager.parse_scene_directives(test_response_4)
	var story_4 = AIManager.extract_story_content(test_response_4)
	var passed := true
	if not directives_4.has("scene") or not directives_4.has("characters") or not directives_4.has("assets"):
		passed = false
	if "[SCENE_DIRECTIVES]" in story_4:
		passed = false
	if passed:
		print("??Complete integration test passed")
		print("  - Parsed scene: %s" % directives_4.get("scene", { }).get("background", "none"))
		print("  - Characters: %d" % directives_4.get("characters", { }).size())
		print("  - Assets: %d" % directives_4.get("assets", []).size())
		print("  - Story cleaned: %s" % ("✓" if not "[SCENE_DIRECTIVES]" in story_4 else "✗"))
	else:
		print("??Integration test failed")
	print("\n??Fuzzy Asset Matching test complete")
func _exit_tree():
	print("\n[Press Ctrl+C or close window to exit]")
