extends Node
var test_client: Node = null
var tests_passed: int = 0
var tests_failed: int = 0
func _ready() -> void:
	print("\n" + "=".repeat(80))
	print("  🧪 TESTING OLLAMA CLIENT")
	print("=".repeat(80) + "\n")
	await get_tree().process_frame
	await _test_client_initialization()
	await _test_configuration()
	await _test_default_options()
	await _test_request_payload_formatting()
	await _test_chat_message_normalization()
	await _test_queue_management()
	await _test_concurrent_request_limits()
	await _test_request_cancellation()
	await _test_option_merging()
	await _test_empty_prompt_handling()
	await _test_logging_levels()
	_print_summary()
	await get_tree().create_timer(0.5).timeout
	queue_free()
func _test_client_initialization() -> void:
	print("\n[Test] OllamaClient initialization...")
	var OllamaClientScript = load("res://1.Codebase/src/scripts/core/ollama_client.gd")
	test_client = OllamaClientScript.new()
	add_child(test_client)
	_assert(test_client != null, "OllamaClient should instantiate")
	_assert(test_client.host == "127.0.0.1", "Default host should be 127.0.0.1")
	_assert(test_client.port == 11434, "Default port should be 11434")
	_assert(test_client.model == "gemma3:1b", "Default model should be gemma3:1b")
	_assert(test_client.use_chat == true, "Default use_chat should be true")
	_assert(test_client.max_concurrent == 1, "Default max_concurrent should be 1")
	_assert(test_client.request_timeout_sec == 60.0, "Default timeout should be 60s")
	print("   ✅ PASS: Client initialization")
func _test_configuration() -> void:
	print("\n[Test] Configuration...")
	test_client.configure("192.168.1.100", 8080, "llama2:7b", false, {"temperature": 0.5})
	_assert(test_client.host == "192.168.1.100", "Host should update")
	_assert(test_client.port == 8080, "Port should update")
	_assert(test_client.model == "llama2:7b", "Model should update")
	_assert(test_client.use_chat == false, "use_chat should update")
	_assert(test_client.default_options.has("temperature"), "Options should update")
	_assert(test_client.default_options["temperature"] == 0.5, "Temperature should be 0.5")
	test_client.configure("  10.0.0.1  ", 11434, "  gemma3:1b  ")
	_assert(test_client.host == "10.0.0.1", "Host should strip whitespace")
	_assert(test_client.model == "gemma3:1b", "Model should strip whitespace")
	print("   ✅ PASS: Configuration")
func _test_default_options() -> void:
	print("\n[Test] Default options...")
	var default_opts = test_client.default_options
	_assert(default_opts.has("temperature"), "Should have temperature option")
	_assert(default_opts.has("top_p"), "Should have top_p option")
	_assert(default_opts.has("num_ctx"), "Should have num_ctx option")
	_assert(default_opts.has("seed"), "Should have seed option")
	_assert(default_opts.has("num_predict"), "Should have num_predict option")
	var new_options = {"temperature": 0.8, "max_tokens": 500}
	test_client.set_default_options(new_options)
	_assert(test_client.default_options["temperature"] == 0.8, "Temperature should update")
	_assert(test_client.default_options.has("max_tokens"), "Should have new option")
	_assert(not test_client.default_options.has("top_p"), "Old options should be replaced")
	print("   ✅ PASS: Default options")
func _test_request_payload_formatting() -> void:
	print("\n[Test] Request payload formatting...")
	test_client.configure("127.0.0.1", 11434, "test-model")
	var initial_queue_size = test_client._queue.size()
	var task_id = test_client.ask_prompt("Test prompt", {"temperature": 0.9}, true)
	_assert(task_id > 0, "Should return positive task ID")
	_assert(test_client._queue.size() == initial_queue_size + 1, "Should enqueue request")
	var job = test_client._queue[test_client._queue.size() - 1]
	_assert(job.has("task_id"), "Job should have task_id")
	_assert(job.has("path"), "Job should have path")
	_assert(job.has("payload"), "Job should have payload")
	_assert(job["path"] == "/api/generate", "Should use /api/generate endpoint")
	var payload = job["payload"]
	_assert(payload.has("model"), "Payload should have model")
	_assert(payload.has("prompt"), "Payload should have prompt")
	_assert(payload.has("stream"), "Payload should have stream")
	_assert(payload.has("options"), "Payload should have options")
	_assert(payload["model"] == "test-model", "Model should match configured model")
	_assert(payload["prompt"] == "Test prompt", "Prompt should match input")
	_assert(payload["stream"] == true, "Stream should match input")
	print("   ✅ PASS: Request payload formatting")
func _test_chat_message_normalization() -> void:
	print("\n[Test] Chat message normalization...")
	var messages_dict = [
		{"role": "user", "content": "Hello"},
		{"role": "assistant", "content": "Hi there"}
	]
	var task_id = test_client.ask_chat(messages_dict, {}, false)
	_assert(task_id > 0, "Should enqueue chat request")
	var job = test_client._queue[test_client._queue.size() - 1]
	_assert(job["path"] == "/api/chat", "Should use /api/chat endpoint")
	var payload = job["payload"]
	_assert(payload.has("messages"), "Payload should have messages")
	_assert(payload["messages"].size() == 2, "Should have 2 messages")
	var first_msg = payload["messages"][0]
	_assert(first_msg.has("role"), "Message should have role")
	_assert(first_msg.has("content"), "Message should have content")
	_assert(first_msg["role"] == "user", "Role should be normalized to lowercase")
	_assert(first_msg["content"] is String, "Content should be String (for compatibility)")
	_assert(first_msg["content"] == "Hello", "Content string should be correct")
	var messages_array = [
		["user", "Test message"],
		["assistant", "Test response"]
	]
	task_id = test_client.ask_chat(messages_array, {}, false)
	job = test_client._queue[test_client._queue.size() - 1]
	payload = job["payload"]
	_assert(payload["messages"].size() == 2, "Should normalize array format")
	_assert(payload["messages"][0]["role"] == "user", "Should extract role from array")
	_assert(payload["messages"][0]["content"] is String, "Content should be String") 
	print("   ✅ PASS: Chat message normalization")
func _test_queue_management() -> void:
	print("\n[Test] Queue management...")
	test_client._queue.clear()
	test_client._active.clear()
	var task_ids = []
	for i in range(5):
		var task_id = test_client.ask_prompt("Test %d" % i, {}, false)
		task_ids.append(task_id)
	_assert(test_client._queue.size() + test_client._active.size() == 5,
		"Should have 5 requests total (queue + active)")
	for i in range(task_ids.size() - 1):
		_assert(task_ids[i] < task_ids[i + 1], "Task IDs should be sequential")
	print("   ✅ PASS: Queue management")
func _test_concurrent_request_limits() -> void:
	print("\n[Test] Concurrent request limits...")
	test_client._queue.clear()
	test_client._active.clear()
	test_client.set_max_concurrent(3)
	_assert(test_client.max_concurrent == 3, "Should set max concurrent to 3")
	test_client.set_max_concurrent(0)
	_assert(test_client.max_concurrent == 1, "Should enforce minimum of 1")
	test_client.set_max_concurrent(-5)
	_assert(test_client.max_concurrent == 1, "Should enforce minimum of 1 for negative values")
	print("   ✅ PASS: Concurrent request limits")
func _test_request_cancellation() -> void:
	print("\n[Test] Request cancellation...")
	test_client._queue.clear()
	test_client._active.clear()
	var task_id_1 = test_client.ask_prompt("Test 1")
	var task_id_2 = test_client.ask_prompt("Test 2")
	var task_id_3 = test_client.ask_prompt("Test 3")
	var initial_total = test_client._queue.size() + test_client._active.size()
	test_client.cancel(task_id_2)
	var after_cancel = test_client._queue.size() + test_client._active.size()
	_assert(after_cancel == initial_total - 1, "Should remove cancelled request")
	test_client.cancel_all()
	_assert(test_client._queue.size() == 0, "Queue should be empty after cancel_all")
	_assert(test_client._active.size() == 0, "Active should be empty after cancel_all")
	print("   ✅ PASS: Request cancellation")
func _test_option_merging() -> void:
	print("\n[Test] Option merging...")
	test_client.set_default_options({"temperature": 0.7, "top_p": 0.9, "seed": 42})
	var extra_opts = {"temperature": 0.5, "max_tokens": 100}
	var merged = test_client._merge_options(extra_opts)
	_assert(merged.has("temperature"), "Should have temperature")
	_assert(merged["temperature"] == 0.5, "Extra options should override defaults")
	_assert(merged.has("top_p"), "Should keep default options")
	_assert(merged["top_p"] == 0.9, "Default values should be preserved")
	_assert(merged.has("max_tokens"), "Should include new options")
	_assert(merged["max_tokens"] == 100, "New option value should be correct")
	_assert(merged.has("seed"), "Should keep all default options")
	var merged_empty = test_client._merge_options({})
	_assert(merged_empty["temperature"] == 0.7, "Should use all defaults when no extras")
	print("   ✅ PASS: Option merging")
func _test_empty_prompt_handling() -> void:
	print("\n[Test] Empty prompt handling...")
	test_client._queue.clear()
	var task_id = test_client.ask_prompt("", {}, false)
	_assert(task_id > 0, "Should return task ID even for empty prompt")
	_assert(test_client._queue.size() > 0, "Should enqueue empty prompt request")
	var task_id_2 = test_client.ask_prompt("   ", {}, false)
	_assert(task_id_2 > 0, "Should handle whitespace-only prompt")
	print("   ✅ PASS: Empty prompt handling")
func _test_logging_levels() -> void:
	print("\n[Test] Logging levels...")
	_assert(test_client.LogLevel.ERROR == 0, "ERROR should be 0")
	_assert(test_client.LogLevel.WARN == 1, "WARN should be 1")
	_assert(test_client.LogLevel.INFO == 2, "INFO should be 2")
	_assert(test_client.LogLevel.DEBUG == 3, "DEBUG should be 3")
	_assert(test_client.log_level == test_client.LogLevel.INFO, "Default log level should be INFO")
	test_client.log_level = test_client.LogLevel.DEBUG
	_assert(test_client.log_level == test_client.LogLevel.DEBUG, "Should be able to set log level")
	test_client.log_level = test_client.LogLevel.ERROR
	_assert(test_client.log_level == test_client.LogLevel.ERROR, "Should be able to set to ERROR")
	print("   ✅ PASS: Logging levels")
func _assert(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		print("   ❌ FAIL: %s" % message)
func _print_summary() -> void:
	print("\n" + "=".repeat(80))
	print("  TEST SUMMARY - OllamaClient")
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
