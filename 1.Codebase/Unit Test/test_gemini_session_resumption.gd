extends SceneTree
var tests_passed = 0
var tests_failed = 0
class MockLiveClient:
	extends Node
	signal connection_established()
	signal connection_closed(code, reason)
	signal connection_error()
	signal setup_response_received(response)
	signal server_message_received(message)
	signal error_received(error_message)
	signal session_updated(session_handle)
func _init():
	print("Running Gemini Session Resumption Test...")
	_test_session_resumption()
	quit(tests_failed)
func _test_session_resumption():
	var GeminiProviderScript = load("res://1.Codebase/src/scripts/core/ai/gemini_provider.gd")
	var provider = GeminiProviderScript.new()
	var mock_client = MockLiveClient.new()
	var mock_http = HTTPRequest.new()
	print("Calling setup()...")
	provider.setup(mock_http, mock_client, null)
	var test_handle = "test_handle_12345"
	print("Emitting session_updated with handle: " + test_handle)
	mock_client.session_updated.emit(test_handle)
	if provider.live_api_session_handle == test_handle:
		print("PASS: live_api_session_handle updated correctly.")
		tests_passed += 1
	else:
		print("FAIL: live_api_session_handle not updated. Expected '%s', got '%s'" % [test_handle, provider.live_api_session_handle])
		tests_failed += 1
	mock_http.free()
	mock_client.free()
	provider.free()
