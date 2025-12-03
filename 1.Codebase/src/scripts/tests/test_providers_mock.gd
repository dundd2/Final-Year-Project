extends SceneTree
class MockHTTPRequest:
	extends Node
	signal request_completed(result, response_code, headers, body)
	var last_url = ""
	var last_headers = []
	var last_method = -1
	var last_body = ""
	var mock_response_body = ""
	var mock_response_code = 200
	func request(url, headers, method, body):
		last_url = url
		last_headers = headers
		last_method = method
		last_body = body
		_flush_response()
		return OK
	func cancel_request():
		pass
	func set_mock_response(body_dict, code=200):
		mock_response_body = JSON.stringify(body_dict)
		mock_response_code = code
	func _flush_response():
		request_completed.emit(HTTPRequest.RESULT_SUCCESS, mock_response_code, [], mock_response_body.to_utf8_buffer())
class MockOllamaClient:
	extends Node
	signal token(task_id, text)
	signal completed(task_id, ok, data)
	signal error(task_id, reason)
	signal request_started(task_id)
	var last_endpoint = ""
	var last_payload = {}
	var mock_response_text = ""
	func configure(h, p, m, c, o):
		pass
	func health_check(timeout):
		return true
	func ask_chat(messages, opts, stream = true):
		last_endpoint = "/api/chat"
		last_payload = {
			"messages": messages,
			"options": opts,
			"stream": stream
		}
		_simulate_response(1)
		return 1
	func ask_prompt(prompt, opts, stream = true):
		last_endpoint = "/api/generate"
		last_payload = {
			"prompt": prompt,
			"options": opts,
			"stream": stream
		}
		_simulate_response(1)
		return 1
	func _simulate_response(task_id):
		request_started.emit(task_id)
		token.emit(task_id, mock_response_text)
		completed.emit(task_id, true, {"text": mock_response_text})
func _init():
	print("========================================================")
	print("   RUNNING MOCK AI PROVIDER TESTS (NO NETWORK)   ")
	print("========================================================")
	var total_errors = 0
	total_errors += test_openrouter_formatting()
	total_errors += test_ollama_formatting()
	if total_errors == 0:
		print("\n✅ ALL TESTS PASSED")
		quit(0)
	else:
		print("\n❌ %d TESTS FAILED" % total_errors)
		quit(1)
func test_openrouter_formatting():
	print("\n[TEST] OpenRouter Request Formatting & Response Parsing")
	var OpenRouterProvider = load("res://1.Codebase/src/scripts/core/ai/openrouter_provider.gd")
	var provider = OpenRouterProvider.new()
	var mock_http = MockHTTPRequest.new()
	provider.setup(mock_http)
	provider.api_key = "sk-mock-key"
	mock_http.set_mock_response({
		"choices": [
			{ "message": { "content": "OpenRouter Success" } }
		]
	})
	var input_messages = [
		{
			"role": "model",
			"parts": [
				{ "text": "Hello user." },
				{ "thoughtSignature": "hidden_thought" } 
			]
		}
	]
	var success = false
	var response_content = ""
	provider.send_request(input_messages, func(resp):
		success = resp.success
		response_content = resp.content
	)
	var json = JSON.new()
	json.parse(mock_http.last_body)
	var body = json.data
	var err_count = 0
	var sent_msgs = body["messages"]
	if sent_msgs[0]["role"] != "assistant":
		print("❌ FAIL: Role 'model' not converted to 'assistant'. Got: " + sent_msgs[0]["role"])
		err_count += 1
	else:
		print("✅ PASS: Role 'model' -> 'assistant'")
	if sent_msgs[0]["content"] != "Hello user.":
		print("❌ FAIL: Content not flattened correctly. Got: " + str(sent_msgs[0]["content"]))
		err_count += 1
	else:
		print("✅ PASS: 'parts' flattened to string, 'thoughtSignature' ignored")
	if not success or response_content != "OpenRouter Success":
		print("❌ FAIL: Response parsing failed. Success=%s Content=%s" % [success, response_content])
		err_count += 1
	else:
		print("✅ PASS: Mock response parsed correctly")
	provider = null
	return err_count
func test_ollama_formatting():
	print("\n[TEST] Ollama Request Formatting")
	var OllamaProvider = load("res://1.Codebase/src/scripts/core/ai/ollama_provider.gd")
	var provider = OllamaProvider.new()
	var mock_client = MockOllamaClient.new()
	provider.setup(mock_client)
	provider.host = "localhost"
	mock_client.mock_response_text = "Ollama Success"
	var input_messages = [
		{
			"role": "model",
			"parts": [
				{ "text": "I am Ollama." }
			]
		}
	]
	var response_content = ""
	provider.send_request(input_messages, func(resp):
		response_content = resp.content
	)
	var sent_msgs = mock_client.last_payload["messages"]
	var err_count = 0
	if sent_msgs[0]["role"] != "assistant":
		print("❌ FAIL: Role 'model' not converted to 'assistant'")
		err_count += 1
	else:
		print("✅ PASS: Role 'model' -> 'assistant'")
	if response_content != "Ollama Success":
		print("❌ FAIL: Response parsing failed")
		err_count += 1
	else:
		print("✅ PASS: Mock response parsed correctly")
	provider = null
	return err_count
