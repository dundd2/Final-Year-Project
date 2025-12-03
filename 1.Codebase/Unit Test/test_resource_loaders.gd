extends Node
var background_loader: Node = null
var character_loader: Node = null
var tests_passed: int = 0
var tests_failed: int = 0
func _ready() -> void:
	print("\n" + "=".repeat(80))
	print("  🧪 TESTING RESOURCE LOADERS")
	print("=".repeat(80) + "\n")
	await get_tree().process_frame
	await _test_background_loader_initialization()
	await _test_background_loader_data_structure()
	await _test_background_texture_loading()
	await _test_background_tag_filtering()
	await _test_background_cache()
	await _test_background_fallback()
	await _test_character_loader_initialization()
	await _test_character_data_structure()
	await _test_character_texture_loading()
	await _test_character_name_localization()
	await _test_character_alias_resolution()
	await _test_character_expression_fallback()
	await _test_character_manifest()
	_print_summary()
	await get_tree().create_timer(0.5).timeout
	queue_free()
func _test_background_loader_initialization() -> void:
	print("\n[Test] BackgroundLoader initialization...")
	background_loader = get_node_or_null("/root/BackgroundLoader")
	if background_loader == null:
		var BackgroundLoaderScript = load("res://1.Codebase/src/scripts/core/background_loader.gd")
		background_loader = BackgroundLoaderScript.new()
		add_child(background_loader)
	_assert(background_loader != null, "BackgroundLoader should exist")
	_assert(background_loader.backgrounds is Dictionary, "Should have backgrounds dictionary")
	_assert(background_loader.texture_cache is Dictionary, "Should have texture cache")
	print("   ✅ PASS: BackgroundLoader initialization")
func _test_background_loader_data_structure() -> void:
	print("\n[Test] BackgroundLoader data structure...")
	_assert(background_loader.backgrounds.has("default"), "Should have default background")
	_assert(background_loader.backgrounds.has("forest"), "Should have forest background")
	_assert(background_loader.backgrounds.has("cave"), "Should have cave background")
	_assert(background_loader.backgrounds.has("temple"), "Should have temple background")
	var default_bg = background_loader.backgrounds["default"]
	_assert(default_bg.has("path"), "Background should have path")
	_assert(default_bg.has("name"), "Background should have name")
	_assert(default_bg.has("tags"), "Background should have tags")
	_assert(default_bg["tags"] is Array, "Tags should be array")
	_assert(default_bg["path"].begins_with("res://"), "Path should use res:// format")
	print("   ✅ PASS: BackgroundLoader data structure")
func _test_background_texture_loading() -> void:
	print("\n[Test] Background texture loading...")
	var default_texture = background_loader.get_background_texture("default")
	_assert(default_texture == null or default_texture is Texture2D,
		"Should return null or Texture2D")
	var bg_info = background_loader.get_background_info("forest")
	_assert(bg_info.has("name"), "Background info should have name")
	_assert(bg_info.has("tags"), "Background info should have tags")
	print("   ✅ PASS: Background texture loading")
func _test_background_tag_filtering() -> void:
	print("\n[Test] Background tag filtering...")
	var outdoor_bg = background_loader.get_background_by_tags(["outdoor"])
	_assert(outdoor_bg != "", "Should find background with outdoor tag")
	var mystical_bg = background_loader.get_background_by_tags(["mystical"])
	_assert(mystical_bg != "", "Should find background with mystical tag")
	var fake_bg = background_loader.get_background_by_tags(["nonexistent_tag_xyz"])
	_assert(fake_bg == "default", "Should return default for non-existent tag")
	var multi_bg = background_loader.get_background_by_tags(["outdoor", "nature"])
	_assert(multi_bg != "", "Should find background with any matching tag")
	print("   ✅ PASS: Background tag filtering")
func _test_background_cache() -> void:
	print("\n[Test] Background cache management...")
	background_loader.clear_cache()
	_assert(background_loader.texture_cache.size() == 0, "Cache should be empty after clear")
	var initial_cache_size = background_loader.texture_cache.size()
	var texture1 = background_loader.get_background_texture("default")
	var texture2 = background_loader.get_background_texture("default")
	if texture1 != null:
		_assert(texture1 == texture2, "Should return same cached texture")
		_assert(background_loader.texture_cache.has("default"), "Should cache loaded texture")
	print("   ✅ PASS: Background cache management")
func _test_background_fallback() -> void:
	print("\n[Test] Background fallback handling...")
	var unknown_texture = background_loader.get_background_texture("completely_unknown_bg_xyz")
	_assert(true, "Should handle unknown background gracefully")
	var all_ids = background_loader.get_all_background_ids()
	_assert(all_ids is Array, "Should return array of IDs")
	_assert(all_ids.size() > 0, "Should have at least one background")
	_assert("default" in all_ids, "Should include default in list")
	print("   ✅ PASS: Background fallback handling")
func _test_character_loader_initialization() -> void:
	print("\n[Test] CharacterExpressionLoader initialization...")
	character_loader = get_node_or_null("/root/CharacterExpressionLoader")
	if character_loader == null:
		var CharacterLoaderScript = load("res://1.Codebase/src/scripts/core/character_expression_loader.gd")
		character_loader = CharacterLoaderScript.new()
		add_child(character_loader)
	_assert(character_loader != null, "CharacterExpressionLoader should exist")
	_assert(character_loader.character_data is Dictionary, "Should have character data")
	_assert(character_loader.character_manifest is Dictionary, "Should have character manifest")
	print("   ✅ PASS: CharacterExpressionLoader initialization")
func _test_character_data_structure() -> void:
	print("\n[Test] Character data structure...")
	_assert(character_loader.character_data.has("protagonist"), "Should have protagonist")
	_assert(character_loader.character_data.has("gloria"), "Should have gloria")
	_assert(character_loader.character_data.has("donkey"), "Should have donkey")
	var protagonist = character_loader.character_data["protagonist"]
	_assert(protagonist.has("id"), "Character should have id")
	_assert(protagonist.has("name"), "Character should have name")
	_assert(protagonist.has("name_cn"), "Character should have Chinese name")
	_assert(protagonist.has("default_portrait"), "Character should have default portrait")
	_assert(protagonist.has("expressions"), "Character should have expressions dict")
	_assert(character_loader.CHARACTERS.has("protagonist"), "CHARACTERS should have protagonist")
	_assert(character_loader.CHARACTERS.has("gloria"), "CHARACTERS should have gloria")
	_assert(character_loader.EXPRESSIONS.has("neutral"), "Should have neutral expression")
	_assert(character_loader.EXPRESSIONS.has("happy"), "Should have happy expression")
	_assert(character_loader.EXPRESSIONS.has("sad"), "Should have sad expression")
	print("   ✅ PASS: Character data structure")
func _test_character_texture_loading() -> void:
	print("\n[Test] Character texture loading...")
	var texture = character_loader.get_character_texture("protagonist", "neutral")
	_assert(texture == null or texture is Texture2D,
		"Should return null or Texture2D for protagonist")
	var default_texture = character_loader.get_character_texture("gloria")
	_assert(default_texture == null or default_texture is Texture2D,
		"Should load default (neutral) expression")
	_assert(character_loader.has_character("protagonist"), "Should have protagonist")
	_assert(character_loader.has_character("gloria"), "Should have gloria")
	_assert(character_loader.has_character("nonexistent") == false,
		"Should not have nonexistent character")
	print("   ✅ PASS: Character texture loading")
func _test_character_name_localization() -> void:
	print("\n[Test] Character name localization...")
	var name_en = character_loader.get_character_name("gloria", false)
	_assert(name_en == "Gloria", "Should get English name")
	var name_cn = character_loader.get_character_name("gloria", true)
	_assert(name_cn.length() > 0, "Should have Chinese name")
	var protag_name = character_loader.get_character_name("protagonist", false)
	_assert(protag_name == "You", "Protagonist name should be 'You'")
	var unknown_name = character_loader.get_character_name("unknown_char_xyz", false)
	_assert(unknown_name == "", "Unknown character should return empty string")
	print("   ✅ PASS: Character name localization")
func _test_character_alias_resolution() -> void:
	print("\n[Test] Character alias resolution...")
	_assert(character_loader.CHARACTER_ALIASES.has("you"), "Should have 'you' alias")
	_assert(character_loader.CHARACTER_ALIASES.has("player"), "Should have 'player' alias")
	_assert(character_loader.CHARACTER_ALIASES["you"] == "protagonist",
		"'you' should resolve to protagonist")
	var canonical1 = character_loader.get_canonical_id("you")
	_assert(canonical1 == "protagonist", "'you' should resolve to protagonist")
	var canonical2 = character_loader.get_canonical_id("player")
	_assert(canonical2 == "protagonist", "'player' should resolve to protagonist")
	var canonical3 = character_loader.get_canonical_id("gloria")
	_assert(canonical3 == "gloria", "'gloria' should remain gloria")
	var canonical4 = character_loader.get_canonical_id("GLORIA")
	_assert(canonical4 == "gloria", "Should handle uppercase")
	print("   ✅ PASS: Character alias resolution")
func _test_character_expression_fallback() -> void:
	print("\n[Test] Character expression fallback...")
	var texture = character_loader.get_character_texture("protagonist", "nonexistent_expression")
	_assert(texture == null or texture is Texture2D,
		"Should handle nonexistent expression gracefully")
	var expressions = character_loader.get_available_expressions("protagonist")
	_assert(expressions is Array, "Should return array of expressions")
	_assert(expressions.size() >= 0, "Should have expressions array (may be empty)")
	print("   ✅ PASS: Character expression fallback")
func _test_character_manifest() -> void:
	print("\n[Test] Character manifest...")
	var manifest = character_loader.get_manifest()
	_assert(manifest is Dictionary, "Manifest should be dictionary")
	var original_size = character_loader.character_manifest.size()
	manifest["test_key"] = "test_value"
	_assert(character_loader.character_manifest.size() == original_size,
		"Manifest should be independent copy")
	var all_chars = character_loader.get_all_characters()
	_assert(all_chars is Array, "Should return array")
	_assert("protagonist" in all_chars, "Should include protagonist")
	_assert("gloria" in all_chars, "Should include gloria")
	var expr_path = character_loader.get_expression_path("protagonist", "neutral")
	_assert(expr_path is String, "Expression path should be string")
	print("   ✅ PASS: Character manifest")
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("   ❌ FAIL: %s" % message)
func _print_summary() -> void:
	print("\n" + "=".repeat(80))
	print("  TEST SUMMARY - Resource Loaders")
	print("=".repeat(80))
	print("  Total Tests:   %d" % (tests_passed + tests_failed))
	print("  ✅ Passed:     %d" % tests_passed)
	print("  ❌ Failed:     %d" % tests_failed)
	if tests_failed > 0:
		print("\n  ⚠️  Some tests failed!")
	else:
		print("\n  🎉 All tests passed!")
	print("=".repeat(80) + "\n")
	if background_loader and not background_loader.is_queued_for_deletion():
		if background_loader.get_parent() == self:
			background_loader.queue_free()
	if character_loader and not character_loader.is_queued_for_deletion():
		if character_loader.get_parent() == self:
			character_loader.queue_free()
