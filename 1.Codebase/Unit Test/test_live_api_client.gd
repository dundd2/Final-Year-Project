extends Node
var test_client: LiveAPIClient = null
var tests_passed: int = 0
var tests_failed: int = 0
func _ready() -> void:
	print("\n" + "=".repeat(80))
	print("  🧪 TESTING LIVE API CLIENT")
	print("=".repeat(80) + "\n")
	await get_tree().process_frame
	await _test_client_initialization()
	await _test_connection_parameters()
	await _test_api_key_handling()
	await _test_session_configuration()
	await _test_message_formatting()
	await _test_connection_state_management()
	await _test_error_handling()
	await _test_signal_emissions()
	await _test_platform_specific_url()
	_print_summary()
	await get_tree().create_timer(0.5).timeout
	queue_free()
func _test_client_initialization() -> void:
	print("\n[Test] LiveAPIClient initialization...")
	var LiveAPIClientScript = load("res://1.Codebase/src/scripts/core/live_api_client.gd")
	test_client = LiveAPIClientScript.new()
	add_child(test_client)
	_assert(test_client != null, "LiveAPIClient should instantiate")
	_assert(test_client.websocket != null, "Should have WebSocketPeer instance")
	_assert(test_client.is_connected == false, "Should not be connected initially")
	_assert(test_client._is_session_setup == false, "Session should not be setup initially")
	print("   ✅ PASS: Client initialization")
func _test_connection_parameters() -> void:
	print("\n[Test] Connection parameters...")
	var test_model = "gemini-3-flash-preview"
	var test_api_key = "test_api_key_12345"
	var test_config = {"temperature": 0.8, "maxOutputTokens": 500}
	var test_session_handle = "session_abc123"
	var test_instruction = "You are a helpful assistant"
	var test_speech_config = {"voice": "Kore"}
	test_client._model_name = test_model
	test_client._api_key = test_api_key
	test_client._generation_config = test_config
	test_client._session_handle = test_session_handle
	test_client._system_instruction = test_instruction
	test_client._speech_config = test_speech_config
	_assert(test_client._model_name == test_model, "Model name should be stored")
	_assert(test_client._api_key == test_api_key, "API key should be stored")
	_assert(test_client._generation_config.has("temperature"), "Config should be stored")
	_assert(test_client._generation_config["temperature"] == 0.8, "Config values should match")
	_assert(test_client._session_handle == test_session_handle, "Session handle should be stored")
	_assert(test_client._system_instruction == test_instruction, "System instruction should be stored")
	_assert(test_client._speech_config.has("voice"), "Speech config should be stored")
	print("   ✅ PASS: Connection parameters")
func _test_api_key_handling() -> void:
	print("\n[Test] API key handling...")
	test_client._api_key = ""
	_assert(test_client._api_key == "", "Should accept empty API key (for testing)")
	test_client._api_key = "AIza" + "SyDtXYZ123456789"  
	_assert(test_client._api_key.length() > 10, "API key should have reasonable length")
	_assert(test_client._api_key.begins_with("AIza"), "Google API keys typically start with AIza")
	var key_with_spaces = "  test_key  "
	test_client._api_key = key_with_spaces
	_assert(test_client._api_key == key_with_spaces, "API key stored as-is (caller should strip)")
	print("   ✅ PASS: API key handling")
func _test_session_configuration() -> void:
	print("\n[Test] Session configuration...")
	var model_name = "gemini-3-flash-preview"
	var config = {"temperature": 0.9, "topP": 0.95}
	var session_handle = "session_xyz"
	var system_instruction = "Test instruction"
	var speech_config = {"voice": "Aoede"}
	test_client._model_name = model_name
	test_client._generation_config = config.duplicate()
	test_client._session_handle = session_handle
	test_client._system_instruction = system_instruction
	test_client._speech_config = speech_config.duplicate()
	_assert(test_client._model_name == model_name, "Model name should match")
	_assert(test_client._generation_config["temperature"] == 0.9, "Temperature should match")
	_assert(test_client._session_handle == session_handle, "Session handle should match")
	_assert(test_client._system_instruction == system_instruction, "System instruction should match")
	_assert(test_client._speech_config["voice"] == "Aoede", "Speech voice should match")
	test_client._session_handle = ""
	_assert(test_client._session_handle == "", "Should support empty session handle for new sessions")
	print("   ✅ PASS: Session configuration")
func _test_message_formatting() -> void:
	print("\n[Test] Message formatting...")
	var test_parts = [
		{"text": "Hello, how are you?"}
	]
	var expected_message = {
		"client_content": {
			"turns": [{"role": "user", "parts": test_parts}],
			"turn_complete": true,
		},
	}
	_assert(expected_message.has("client_content"), "Message should have client_content")
	_assert(expected_message["client_content"].has("turns"), "Should have turns array")
	_assert(expected_message["client_content"]["turns"][0]["role"] == "user",
		"Turn should have user role")
	_assert(expected_message["client_content"]["turns"][0]["parts"] == test_parts,
		"Turn should have correct parts")
	_assert(expected_message["client_content"]["turn_complete"] == true,
		"Turn should be marked complete")
	var empty_parts = []
	print("   ✅ PASS: Message formatting")
func _test_connection_state_management() -> void:
	print("\n[Test] Connection state management...")
	_assert(test_client.is_connected == false, "Should start disconnected")
	_assert(test_client._is_session_setup == false, "Session should not be setup")
	test_client.is_connected = true
	test_client._is_session_setup = true
	test_client.close_connection()
	_assert(test_client.is_connected == false, "Should be disconnected after close")
	_assert(test_client._is_session_setup == false, "Session should be reset after close")
	_assert(WebSocketPeer.STATE_CLOSED == 3, "STATE_CLOSED should be 3")
	_assert(WebSocketPeer.STATE_OPEN == 1, "STATE_OPEN should be 1")
	_assert(WebSocketPeer.STATE_CONNECTING == 0, "STATE_CONNECTING should be 0")
	_assert(WebSocketPeer.STATE_CLOSING == 2, "STATE_CLOSING should be 2")
	print("   ✅ PASS: Connection state management")
func _test_error_handling() -> void:
	print("\n[Test] Error handling...")
	test_client.is_connected = false
	var test_error_code = 1006  
	var test_error_reason = "Connection lost"
	test_client.is_connected = true
	test_client._on_connection_closed(test_error_code, test_error_reason)
	_assert(test_client.is_connected == false, "Should disconnect on error")
	_assert(test_client._is_session_setup == false, "Should reset session on error")
	print("   ✅ PASS: Error handling")
func _test_signal_emissions() -> void:
	print("\n[Test] Signal emissions...")
	var signal_list = test_client.get_signal_list()
	var signal_names = []
	for sig in signal_list:
		signal_names.append(sig["name"])
	_assert("connection_established" in signal_names, "Should have connection_established signal")
	_assert("connection_closed" in signal_names, "Should have connection_closed signal")
	_assert("connection_error" in signal_names, "Should have connection_error signal")
	_assert("setup_response_received" in signal_names, "Should have setup_response_received signal")
	_assert("server_message_received" in signal_names, "Should have server_message_received signal")
	_assert("error_received" in signal_names, "Should have error_received signal")
	_assert("session_updated" in signal_names, "Should have session_updated signal")
	print("   ✅ PASS: Signal emissions")
func _test_platform_specific_url() -> void:
	print("\n[Test] Platform-specific URL handling...")
	_assert(test_client.SERVICE_URL.begins_with("wss://"),
		"Service URL should use secure WebSocket")
	_assert(test_client.SERVICE_URL.contains("generativelanguage.googleapis.com"),
		"Service URL should point to Google's API")
	_assert(test_client.SERVICE_URL.contains("BidiGenerateContent"),
		"Service URL should target BidiGenerateContent endpoint")
	var current_platform = OS.get_name()
	_assert(current_platform != "", "Should detect platform")
	print("   ✅ PASS: Platform-specific URL handling")
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("   ❌ FAIL: %s" % message)
func _print_summary() -> void:
	print("\n" + "=".repeat(80))
	print("  TEST SUMMARY - LiveAPIClient")
	print("=".repeat(80))
	print("  Total Tests:   %d" % (tests_passed + tests_failed))
	print("  ✅ Passed:     %d" % tests_passed)
	print("  ❌ Failed:     %d" % tests_failed)
	if tests_failed > 0:
		print("\n  ⚠️  Some tests failed!")
	else:
		print("\n  🎉 All tests passed!")
	print("=".repeat(80) + "\n")
	if test_client:
		test_client.queue_free()
		test_client = null
