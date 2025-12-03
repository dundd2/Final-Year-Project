extends Node
const LoaderScript = preload("res://1.Codebase/src/scripts/core/background_loader.gd")
var loader: Node
func _ready() -> void:
	print("[BackgroundLoaderTest] Starting unit tests...")
	await get_tree().process_frame
	_setup()
	_test_initialization()
	_test_background_data_integrity()
	_test_tag_search()
	_test_prompt_generation()
	_test_fallback_safety()
	_teardown()
	print("[BackgroundLoaderTest] All tests completed.")
	queue_free()
func _setup() -> void:
	loader = LoaderScript.new()
	add_child(loader)
func _teardown() -> void:
	if loader:
		loader.queue_free()
		loader = null
func _test_initialization() -> void:
	print("[Test] Initialization...")
	assert(loader != null, "Loader created")
	assert(not loader.backgrounds.is_empty(), "Backgrounds data populated")
	print("[Test] Initialization PASSED")
func _test_background_data_integrity() -> void:
	print("[Test] Data integrity...")
	for bg_id in loader.backgrounds:
		var bg = loader.backgrounds[bg_id]
		assert(bg.has("path"), "Background %s missing path" % bg_id)
		assert(bg.has("name"), "Background %s missing name" % bg_id)
		assert(bg.has("tags"), "Background %s missing tags" % bg_id)
	print("[Test] Data integrity PASSED")
func _test_tag_search() -> void:
	print("[Test] Tag search...")
	var bg_id = loader.get_background_by_tags(["forest"])
	if bg_id != "default":
		assert(loader.backgrounds[bg_id].tags.has("forest"), "Should find forest tag")
	var fallback = loader.get_background_by_tags(["nonexistent_tag_xyz"])
	assert(fallback == "default", "Should fallback to default")
	print("[Test] Tag search PASSED")
func _test_prompt_generation() -> void:
	print("[Test] Prompt generation...")
	var prompt = loader.get_backgrounds_for_ai_prompt()
	assert(prompt is String, "Should return string")
	assert(prompt.length() > 0, "Prompt should not be empty")
	assert("forest" in prompt, "Prompt should contain forest")
	print("[Test] Prompt generation PASSED")
func _test_fallback_safety() -> void:
	print("[Test] Fallback safety...")
	var result = loader.get_background_texture("completely_invalid_id_999")
	print("Fallback safety check passed (no crash)")
