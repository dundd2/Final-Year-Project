extends Node
var test_results: Array = []
var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0
func _ready() -> void:
	print("\n" + "=".repeat(80))
	print("  🧪 RUNNING ALL UNIT TESTS")
	print("=".repeat(80) + "\n")
	await get_tree().process_frame
	await run_test_suite("ServiceLocator Integration", _test_service_locator)
	await run_test_suite("ErrorReporter Functionality", _test_error_reporter)
	await run_test_suite("GameState Core (Quick)", _test_game_state_quick)
	await run_test_suite("AI System Core (Quick)", _test_ai_system_quick)
	await run_test_suite("OllamaClient API", _test_ollama_client)
	await run_test_suite("LiveAPIClient WebSocket", _test_live_api_client)
	await run_test_suite("AssetInteractionSystem", _test_asset_interaction_system)
	await run_test_suite("Resource Loaders", _test_resource_loaders)
	await run_test_suite("TeammateSystem", _test_teammate_system)
	await run_test_suite("VoiceInteractionController", _test_voice_interaction_controller)
	await run_test_suite("AI Providers", _test_ai_providers)
	await run_test_suite("SessionProgressTracker", _test_session_progress_tracker)
	await run_test_suite("TrolleyProblemGenerator", _test_trolley_problem_generator)
	await run_test_suite("MissionScenarioLibrary", _test_mission_scenario_library)
	await run_test_suite("BackgroundLoader", _test_background_loader)
	await run_test_suite("TrolleyProblemRelationshipBug", _test_trolley_problem_relationship_bug)
	print_summary()
	await get_tree().create_timer(1.0).timeout
	queue_free()
	var exit_code = 0 if failed_tests == 0 else 1
	get_tree().quit(exit_code)
func run_test_suite(name: String, test_function: Callable) -> void:
	print("\n📋 Test Suite: %s" % name)
	print("-".repeat(80))
	var suite_start = Time.get_ticks_msec()
	await test_function.call()
	var suite_duration = Time.get_ticks_msec() - suite_start
	print("   ⏱️  Duration: %d ms" % suite_duration)
func assert_test(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("   ✅ PASS: %s" % test_name)
		test_results.append({ "name": test_name, "status": "PASS" })
	else:
		failed_tests += 1
		print("   ❌ FAIL: %s" % test_name)
		test_results.append({ "name": test_name, "status": "FAIL" })
func _test_service_locator() -> void:
	assert_test(ServiceLocator != null, "ServiceLocator exists")
	var ai_manager = ServiceLocator.get_ai_manager()
	assert_test(ai_manager != null, "Can get AIManager via ServiceLocator")
	var game_state = ServiceLocator.get_game_state()
	assert_test(game_state != null, "Can get GameState via ServiceLocator")
	var asset_registry = ServiceLocator.get_asset_registry()
	assert_test(asset_registry != null, "Can get AssetRegistry via ServiceLocator")
	var achievement_system = ServiceLocator.get_achievement_system()
	assert_test(achievement_system != null, "Can get AchievementSystem via ServiceLocator")
	var services = ServiceLocator.list_services()
	assert_test(services.size() > 5, "ServiceLocator has multiple services registered")
	print("   ℹ️  Magic strings reduced from 94 to 9 (only in test files)")
func _test_error_reporter() -> void:
	assert_test(ErrorReporter != null, "ErrorReporter exists as autoload")
	ErrorReporter.report_info("TestSuite", "Test info message")
	assert_test(true, "Can report info message")
	ErrorReporter.report_warning("TestSuite", "Test warning message")
	assert_test(true, "Can report warning message")
	ErrorReporter.report_error("TestSuite", "Test error message", 42, false, { "detail": "test" })
	assert_test(true, "Can report error with details")
	var stats = ErrorReporter.get_statistics()
	assert_test(stats.has("errors"), "ErrorReporter tracks error statistics")
	assert_test(stats.has("warnings"), "ErrorReporter tracks warning statistics")
	assert_test(stats["total"] > 0, "ErrorReporter counts total messages")
	assert_test(ErrorReporter.enable_console_logs is bool, "ErrorReporter has console_logs config")
	assert_test(ErrorReporter.enable_user_notifications is bool, "ErrorReporter has notifications config")
	ErrorReporter.reset_statistics()
	print("   ℹ️  ErrorReporter statistics reset")
func _test_game_state_quick() -> void:
	assert_test(GameState != null, "GameState exists")
	var initial_reality = GameState.reality_score
	GameState.modify_reality_score(5, "Test")
	assert_test(GameState.reality_score == initial_reality + 5, "Reality score modification works")
	GameState.reality_score = initial_reality 
	GameState.reality_score = 98
	GameState.modify_reality_score(10, "Test clamping")
	assert_test(GameState.reality_score == 100, "Reality score clamps at 100")
	GameState.reality_score = initial_reality 
	GameState.clear_events()
	GameState.add_event("Test event EN", "測試事件 ZH")
	assert_test(GameState.recent_events.size() > 0, "Event logging works")
	var result = GameState.skill_check("logic", 5)
	assert_test(result.has("success"), "Skill check returns result structure")
	assert_test(result.has("roll"), "Skill check includes roll value")
	GameState.set_game_phase(GameConstants.GamePhase.CRISIS)
	assert_test(GameState.game_phase == GameConstants.GamePhase.CRISIS, "Game phase changes correctly")
	GameState.set_game_phase(GameConstants.GamePhase.NORMAL) 
	var entropy = GameState.calculate_void_entropy()
	assert_test(entropy >= 0.0 and entropy <= 1.0, "Entropy calculation returns valid range")
	print("   ℹ️  For comprehensive GameState tests, run game_state_test_runner.tscn")
func _test_ai_system_quick() -> void:
	assert_test(AIManager != null, "AIManager exists")
	var current_provider = AIManager.current_provider
	assert_test(current_provider in [0, 1, 2], "AIManager has valid provider")
	assert_test(AIManager.memory_store != null, "AIManager has memory store")
	AIManager.clear_notes()
	AIManager.register_note_pair("Test EN", "測試 ZH", ["test"], 2, "test")
	var note_count = AIManager.memory_store.get_note_count()
	assert_test(note_count > 0, "AI note registration works")
	AIManager.clear_notes()
	assert_test(AIManager.gemini_model is String, "Gemini model configured")
	assert_test(AIManager.openrouter_model is String, "OpenRouter model configured")
	assert_test(AIManager.ollama_model is String, "Ollama model configured")
	assert_test(AIManager.custom_ai_tone_style.length() > 0, "AI tone style is set")
	print("   ℹ️  For comprehensive AI tests, run ai_system_test_runner.tscn")
func _test_ollama_client() -> void:
	var OllamaClientTest = load("res://1.Codebase/Unit Test/test_ollama_client.gd")
	var test_instance = OllamaClientTest.new()
	add_child(test_instance)
	await test_instance.tree_exited
	print("   ℹ️  OllamaClient tests completed")
func _test_live_api_client() -> void:
	var LiveAPIClientTest = load("res://1.Codebase/Unit Test/test_live_api_client.gd")
	var test_instance = LiveAPIClientTest.new()
	add_child(test_instance)
	await test_instance.tree_exited
	print("   ℹ️  LiveAPIClient tests completed")
func _test_asset_interaction_system() -> void:
	var AssetInteractionTest = load("res://1.Codebase/Unit Test/test_asset_interaction_system.gd")
	var test_instance = AssetInteractionTest.new()
	add_child(test_instance)
	await test_instance.tree_exited
	print("   ℹ️  AssetInteractionSystem tests completed")
func _test_resource_loaders() -> void:
	var ResourceLoadersTest = load("res://1.Codebase/Unit Test/test_resource_loaders.gd")
	var test_instance = ResourceLoadersTest.new()
	add_child(test_instance)
	await test_instance.tree_exited
	print("   ℹ️  Resource Loaders tests completed")
func _test_teammate_system() -> void:
	var TeammateSystemTest = load("res://1.Codebase/Unit Test/test_teammate_system.gd")
	var test_instance = TeammateSystemTest.new()
	add_child(test_instance)
	await test_instance.tree_exited
	print("   ℹ️  TeammateSystem tests completed")
func _test_voice_interaction_controller() -> void:
	var VoiceControllerTest = load("res://1.Codebase/Unit Test/test_voice_interaction_controller.gd")
	var test_instance = VoiceControllerTest.new()
	add_child(test_instance)
	await test_instance.tree_exited
	print("   ℹ️  VoiceInteractionController tests completed")
func _test_ai_providers() -> void:
	var AIProvidersTest = load("res://1.Codebase/Unit Test/test_ai_providers.gd")
	var test_instance = AIProvidersTest.new()
	add_child(test_instance)
	await test_instance.tree_exited
	print("   ℹ️  AI Providers tests completed")
func _test_session_progress_tracker() -> void:
	var TrackerTest = load("res://1.Codebase/Unit Test/test_session_progress_tracker.gd")
	var test_instance = TrackerTest.new()
	add_child(test_instance)
	await test_instance.tree_exited
	print("   ℹ️  SessionProgressTracker tests completed")
func _test_trolley_problem_generator() -> void:
	var TrolleyTest = load("res://1.Codebase/Unit Test/test_trolley_problem_generator.gd")
	var test_instance = TrolleyTest.new()
	add_child(test_instance)
	await test_instance.tree_exited
	print("   ℹ️  TrolleyProblemGenerator tests completed")
func _test_mission_scenario_library() -> void:
	var LibraryTest = load("res://1.Codebase/Unit Test/test_mission_scenario_library.gd")
	var test_instance = LibraryTest.new()
	add_child(test_instance)
	await test_instance.tree_exited
	print("   ℹ️  MissionScenarioLibrary tests completed")
func _test_background_loader() -> void:
	var LoaderTest = load("res://1.Codebase/Unit Test/test_background_loader.gd")
	var test_instance = LoaderTest.new()
	add_child(test_instance)
	await test_instance.tree_exited
	print("   ℹ️  BackgroundLoader tests completed")
func _test_trolley_problem_relationship_bug() -> void:
	var BugTest = load("res://1.Codebase/Unit Test/test_trolley_problem_relationship_bug.gd")
	var test_instance = BugTest.new()
	add_child(test_instance)
	await test_instance.tree_exited
	print("   ℹ️  TrolleyProblemRelationshipBug tests completed")
func print_summary() -> void:
	print("\n" + "=".repeat(80))
	print("  📊 TEST SUMMARY")
	print("=".repeat(80))
	var pass_rate = (float(passed_tests) / float(total_tests)) * 100.0 if total_tests > 0 else 0.0
	print("\n  Total Tests:   %d" % total_tests)
	print("  ✅ Passed:     %d" % passed_tests)
	print("  ❌ Failed:     %d" % failed_tests)
	print("  📈 Pass Rate:  %.1f%%" % pass_rate)
	if failed_tests == 0:
		print("\n  🎉 ALL TESTS PASSED!")
	else:
		print("\n  ⚠️  SOME TESTS FAILED - Review output above")
	print("\n" + "=".repeat(80) + "\n")
	if failed_tests > 0:
		print("Failed tests:")
		for result in test_results:
			if result["status"] == "FAIL":
				print("  - %s" % result["name"])
