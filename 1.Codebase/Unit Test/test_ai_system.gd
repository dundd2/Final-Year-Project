extends Node
var test_timeout: float = 5.0
func _ready() -> void:
	print("[AISystemTest] Starting AI system unit tests...")
	await get_tree().process_frame
	_test_service_locator_access()
	_test_provider_configuration()
	await _test_mock_ai_generator()
	_test_memory_store()
	_test_context_builder()
	print("[AISystemTest] All tests completed.")
	queue_free()
func _test_service_locator_access() -> void:
	print("[Test] ServiceLocator access...")
	assert(ServiceLocator != null, "ServiceLocator should exist")
	var ai_manager = ServiceLocator.get_ai_manager()
	assert(ai_manager != null, "AIManager should be accessible via ServiceLocator")
	assert(ai_manager == AIManager, "ServiceLocator should return the same AIManager instance")
	var services = ServiceLocator.list_services()
	assert(services.size() > 0, "ServiceLocator should have registered services")
	assert(services.has("AIManager"), "AIManager should be registered")
	assert(services.has("GameState"), "GameState should be registered")
	print("[Test] ServiceLocator access PASSED")
func _test_provider_configuration() -> void:
	print("[Test] Provider configuration...")
	var ai_manager = ServiceLocator.get_ai_manager()
	assert(ai_manager != null, "AIManager should exist")
	assert(
		ai_manager.current_provider in [
			ai_manager.AIProvider.GEMINI,
			ai_manager.AIProvider.OPENROUTER,
			ai_manager.AIProvider.OLLAMA,
		],
		"Current provider should be valid",
	)
	var original_provider = ai_manager.current_provider
	ai_manager.current_provider = ai_manager.AIProvider.OLLAMA
	assert(ai_manager.current_provider == ai_manager.AIProvider.OLLAMA, "Should switch to OLLAMA")
	ai_manager.current_provider = ai_manager.AIProvider.GEMINI
	assert(ai_manager.current_provider == ai_manager.AIProvider.GEMINI, "Should switch to GEMINI")
	ai_manager.current_provider = original_provider
	var original_model = ai_manager.gemini_model
	ai_manager.gemini_model = "gemini-2.5-flash"
	assert(ai_manager.gemini_model == "gemini-2.5-flash", "Should update Gemini model")
	ai_manager.gemini_model = original_model
	print("[Test] Provider configuration PASSED")
func _test_mock_ai_generator() -> void:
	print("[Test] Mock AI generator...")
	var MockAIGenerator = load("res://1.Codebase/src/scripts/core/mock_ai_generator.gd")
	assert(MockAIGenerator != null, "MockAIGenerator should load")
	var mock_gen = MockAIGenerator.new()
	var mission_response = mock_gen.generate_mock_mission_response("Test mission prompt", "en")
	assert(mission_response is String, "Should return string response")
	assert(mission_response.length() > 0, "Response should not be empty")
	var disaster_response = mock_gen.generate_mock_disaster_response("Test prayer", "en")
	assert(disaster_response is String, "Should return string response")
	assert(disaster_response.length() > 0, "Response should not be empty")
	var zh_response = mock_gen.generate_mock_mission_response("Test mission prompt", "zh")
	assert(zh_response is String, "Should return Chinese response")
	assert(zh_response.length() > 0, "Chinese response should not be empty")
	var response_with_directives = """
	Story text here.
	[SCENE_DIRECTIVES]
	BACKGROUND:park
	CHARACTER:gloria
	[/SCENE_DIRECTIVES]
	More story.
	"""
	var parsed = mock_gen._extract_scene_directives(response_with_directives)
	assert(parsed.has("story_text"), "Should have story_text")
	assert(parsed.has("directives"), "Should have directives")
	mock_gen.free()
	print("[Test] Mock AI generator PASSED")
func _test_memory_store() -> void:
	print("[Test] AI memory store...")
	var AIMemoryStore = load("res://1.Codebase/src/scripts/core/ai_memory_store.gd")
	assert(AIMemoryStore != null, "AIMemoryStore should load")
	var memory = AIMemoryStore.new()
	memory.register_note("Test note EN", "測試筆記 ZH", ["test", "demo"], 3, "test")
	var notes_en = memory.get_notes("en", 5)
	assert(notes_en.size() > 0, "Should have English notes")
	var notes_zh = memory.get_notes("zh", 5)
	assert(notes_zh.size() > 0, "Should have Chinese notes")
	var count = memory.get_note_count()
	assert(count >= 1, "Should have at least 1 note")
	var test_notes = memory.get_notes_by_tag("test", "en", 5)
	assert(test_notes.size() >= 1, "Should find notes with 'test' tag")
	var type_notes = memory.get_notes_by_type("test", "en", 5)
	assert(type_notes.size() >= 1, "Should find notes of type 'test'")
	memory.clear_all_notes()
	var cleared_count = memory.get_note_count()
	assert(cleared_count == 0, "Notes should be cleared")
	memory.free()
	print("[Test] AI memory store PASSED")
func _test_context_builder() -> void:
	print("[Test] AI context builder...")
	var ai_manager = ServiceLocator.get_ai_manager()
	assert(ai_manager != null, "AIManager should exist")
	assert(ai_manager.memory_store != null, "Memory store should be initialized")
	ai_manager.register_note_pair("Test EN", "測試 ZH", ["test"], 2, "test_type")
	var note_count = ai_manager.memory_store.get_note_count()
	assert(note_count > 0, "Should have notes registered")
	ai_manager.clear_notes()
	var cleared_count = ai_manager.memory_store.get_note_count()
	assert(cleared_count == 0, "Notes should be cleared")
	assert(ai_manager.custom_ai_tone_style is String, "AI tone style should be string")
	assert(ai_manager.custom_ai_tone_style.length() > 0, "AI tone style should not be empty")
	print("[Test] AI context builder PASSED")
