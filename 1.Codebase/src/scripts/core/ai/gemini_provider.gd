extends "res://1.Codebase/src/scripts/core/ai/ai_provider_base.gd"
class_name GeminiProvider
const GEMINI_ENDPOINT_BASE = "https://generativelanguage.googleapis.com/v1beta/models/"
const GEMINI_DEFAULT_MODEL = "gemini-3-flash-preview"
const GEMINI_NATIVE_AUDIO_MODELS = [
	"gemini-2.5-flash-native-audio-preview-12-2025",
]
const DEFAULT_OUTPUT_SAMPLE_RATE := 24000
const LEGACY_REQUIRED_CHARACTERS := ["protagonist", "gloria", "donkey", "ark", "one"]
const LEGACY_BACKGROUND_IDS := [
	"ruins",
	"cave",
	"dungeon",
	"forest",
	"temple",
	"laboratory",
	"library",
	"throne_room",
	"battlefield",
	"crystal_cavern",
	"bridge",
	"garden",
	"portal_area",
	"safe_zone",
	"water",
	"fire_area",
]
const LEGACY_EXPRESSIONS := [
	"neutral",
	"happy",
	"sad",
	"angry",
	"confused",
	"shocked",
	"thinking",
	"embarrassed",
]
const SAFETY_SETTINGS_MAP = {
	"BLOCK_NONE": [
		{ "category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE" },
		{ "category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE" },
		{ "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE" },
		{ "category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE" }
	],
	"BLOCK_ONLY_HIGH": [
		{ "category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_ONLY_HIGH" },
		{ "category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_ONLY_HIGH" },
		{ "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_ONLY_HIGH" },
		{ "category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_ONLY_HIGH" }
	],
	"BLOCK_MEDIUM_AND_ABOVE": [
		{ "category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE" },
		{ "category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_MEDIUM_AND_ABOVE" },
		{ "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_MEDIUM_AND_ABOVE" },
		{ "category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE" }
	],
	"BLOCK_LOW_AND_ABOVE": [
		{ "category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_LOW_AND_ABOVE" },
		{ "category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_LOW_AND_ABOVE" },
		{ "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_LOW_AND_ABOVE" },
		{ "category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_LOW_AND_ABOVE" }
	]
}
var api_key: String = ""
var access_token: String = ""
var project_id: String = ""
var location: String = ""
var model: String = GEMINI_DEFAULT_MODEL
var safety_settings_key: String = "BLOCK_NONE"
var http_request: HTTPRequest
var live_api_client: Node
var voice_session: Node
var pending_callback: Callable
var current_request_options: Dictionary = { }
var last_sent_messages: Array = []
var live_api_session_handle: String = ""
var live_api_retry_count: int = 0
var allow_web_requests: bool = true
const MAX_LIVE_API_RETRIES: int = 3
var _live_accumulated_text_parts: Array[String] = []
var _live_accumulated_audio_payloads: Array = []
var _live_accumulated_thought_signature: String = ""

func _get_audio_output_guardrail_text() -> String:
	return "Audio reading rules: When generating AUDIO, speak only the narrative/story text and the player choice list. Do NOT read aloud any [SCENE_DIRECTIVES] blocks, JSON, schemas, tool/function-calling data, or other metadata. Keep those silent in audio, even if they appear in the text."

func _should_add_audio_output_guardrail() -> bool:
	return voice_session and voice_session.has_method("wants_voice_output") and voice_session.wants_voice_output()
func _init():
	provider_name = "Gemini"
	allow_web_requests = _read_default_allow_web_requests()
func setup(http_req: HTTPRequest, live_client: Node, voice_sess: Node = null) -> void:
	http_request = http_req
	live_api_client = live_client
	voice_session = voice_sess
	if live_api_client:
		if not live_api_client.connection_established.is_connected(_on_live_api_connection_established):
			live_api_client.connection_established.connect(_on_live_api_connection_established)
		if not live_api_client.connection_closed.is_connected(_on_live_api_connection_closed):
			live_api_client.connection_closed.connect(_on_live_api_connection_closed)
		if not live_api_client.connection_error.is_connected(_on_live_api_connection_error):
			live_api_client.connection_error.connect(_on_live_api_connection_error)
		if live_api_client.has_signal("setup_response_received"):
			if not live_api_client.setup_response_received.is_connected(_on_live_api_setup_response_received):
				live_api_client.setup_response_received.connect(_on_live_api_setup_response_received)
		if not live_api_client.server_message_received.is_connected(_on_live_api_server_message):
			live_api_client.server_message_received.connect(_on_live_api_server_message)
		if not live_api_client.error_received.is_connected(_on_live_api_error):
			live_api_client.error_received.connect(_on_live_api_error)
		if not live_api_client.session_updated.is_connected(_on_live_api_session_updated):
			live_api_client.session_updated.connect(_on_live_api_session_updated)
func is_configured() -> bool:
	return not api_key.is_empty()
func get_configuration() -> Dictionary:
	return {
		"api_key": api_key,
		"access_token": access_token,
		"project_id": project_id,
		"location": location,
		"model": model,
		"allow_web_requests": allow_web_requests,
	}
func apply_configuration(config: Dictionary) -> void:
	if config.has("api_key"):
		api_key = str(config["api_key"])
	if config.has("access_token"):
		access_token = str(config["access_token"])
	if config.has("project_id"):
		project_id = str(config["project_id"])
	if config.has("location"):
		location = str(config["location"])
	if config.has("model"):
		model = str(config["model"])
	if config.has("allow_web_requests"):
		allow_web_requests = _resolve_bool(config["allow_web_requests"], allow_web_requests)
	if config.has("safety_settings"):
		safety_settings_key = str(config["safety_settings"])
	if model.is_empty():
		model = GEMINI_DEFAULT_MODEL
func send_request(messages: Array, callback: Callable, options: Dictionary = { }) -> void:
	if not is_configured():
		_emit_error("Gemini API key is not configured")
		return
	if _is_web_environment_restricted():
		var error_msg := "Gemini web access is disabled. Enable web requests in AI settings or project settings."
		_report_error(
				error_msg,
				ErrorCodes.AI.REQUEST_FAILED,
				{ "platform": "web", "provider": "Gemini", "allow_web_requests": allow_web_requests },
		)
		_emit_error(error_msg)
		if callback and callback.is_valid():
			var error_response := {
				"success": false,
				"error": error_msg,
				"content": "",
				"provider": provider_name,
				"status_code": 0,
				"recoverable": true,
				"web_access_disabled": true,
			}
			callback.call(error_response)
		request_completed.emit(false)
		return
	is_requesting = true
	pending_callback = callback
	current_request_options = options.duplicate(true) if options is Dictionary else { }
	last_sent_messages = messages.duplicate(true)
	request_started.emit()
	var normalized_model := model.strip_edges()
	if normalized_model.is_empty():
		normalized_model = GEMINI_DEFAULT_MODEL
	if _is_live_api_model(normalized_model):
		_send_live_request(messages)
	else:
		_send_rest_request(messages)
func cancel_request() -> void:
	is_requesting = false
	if _is_live_api_model(model.strip_edges()):
		if live_api_client and live_api_client.has_method("close_connection"):
			live_api_client.close_connection(1000, "Client cancelled request")
		return
	if http_request:
		http_request.cancel_request()
func _is_live_api_model(model_name: String) -> bool:
	return GEMINI_NATIVE_AUDIO_MODELS.has(model_name)
func _is_web_environment_restricted() -> bool:
	var injected_key := BuildSecrets.get_gemini_api_key()
	if injected_key != "" and api_key == injected_key:
		return false
	if not _is_web_runtime():
		return false
	if not allow_web_requests:
		return true
	var allow_setting := "ai/gemini/allow_web_requests"
	if ProjectSettings.has_setting(allow_setting):
		return not _resolve_bool(ProjectSettings.get_setting(allow_setting), allow_web_requests)
	return false
func _read_default_allow_web_requests() -> bool:
	var allow_setting := "ai/gemini/allow_web_requests"
	if ProjectSettings.has_setting(allow_setting):
		return _resolve_bool(ProjectSettings.get_setting(allow_setting), true)
	return true
func _resolve_bool(value, fallback: bool) -> bool:
	if value is bool:
		return value
	if value is int:
		return value != 0
	if value is String:
		var normalized := (value as String).strip_edges().to_lower()
		if normalized in ["true", "1", "yes", "on"]:
			return true
		if normalized in ["false", "0", "no", "off"]:
			return false
	return fallback
func _is_web_runtime() -> bool:
	var normalized_name := OS.get_name().to_lower()
	if normalized_name == "html5":
		return true
	for feature in ["web", "html5", "emscripten", "javascript"]:
		if OS.has_feature(feature):
			return true
	return false
func _get_structured_output_options() -> Dictionary:
	if current_request_options.has("structured_output") and current_request_options["structured_output"] is Dictionary:
		return (current_request_options["structured_output"] as Dictionary).duplicate(true)
	var options: Dictionary = { }
	if current_request_options.has("response_mime_type"):
		var mime := String(current_request_options["response_mime_type"]).strip_edges()
		if not mime.is_empty():
			options["mime_type"] = mime
	if current_request_options.has("response_schema") and current_request_options["response_schema"] is Dictionary:
		options["schema"] = (current_request_options["response_schema"] as Dictionary).duplicate(true)
	if current_request_options.has("property_ordering") and current_request_options["property_ordering"] is Array:
		options["property_ordering"] = (current_request_options["property_ordering"] as Array).duplicate(true)
	return options
func _apply_structured_output_config(generation_config: Dictionary) -> bool:
	var structured: Dictionary = _get_structured_output_options()
	if structured.is_empty():
		return false
	var mime: String = String(structured.get("mime_type", "application/json")).strip_edges()
	if mime.is_empty():
		mime = "application/json"
	generation_config["responseMimeType"] = mime
	var schema_variant: Variant = structured.get("schema", null)
	if schema_variant == null and current_request_options.has("response_schema") and current_request_options["response_schema"] is Dictionary:
		schema_variant = (current_request_options["response_schema"] as Dictionary)
	if schema_variant is Dictionary:
		var schema_dict: Dictionary = _convert_schema_for_gemini(schema_variant)
		generation_config["responseSchema"] = schema_dict
		generation_config["responseJsonSchema"] = (schema_variant as Dictionary).duplicate(true)
	var ordering_variant: Variant = structured.get("property_ordering", null)
	if ordering_variant == null and current_request_options.has("property_ordering") and current_request_options["property_ordering"] is Array:
		ordering_variant = current_request_options["property_ordering"]
	if ordering_variant is Array and generation_config.has("responseSchema") and generation_config["responseSchema"] is Dictionary:
		generation_config["responseSchema"]["propertyOrdering"] = (ordering_variant as Array).duplicate(true)
	var schema_mode: String = String(structured.get("schema_mode", "")).to_lower()
	if schema_mode == "json_schema" and schema_variant is Dictionary:
		generation_config["responseJsonSchema"] = (schema_variant as Dictionary).duplicate(true)
	return true
func _detect_scene_schema_needed(contents_array: Array) -> bool:
	if contents_array.is_empty():
		return false
	var last_content: Variant = contents_array.back()
	if not (last_content is Dictionary):
		return false
	var parts_variant: Variant = (last_content as Dictionary).get("parts", [])
	if not (parts_variant is Array) or parts_variant.size() == 0:
		return false
	var first_part: Variant = (parts_variant as Array)[0]
	if not (first_part is Dictionary) or not first_part.has("text"):
		return false
	var text: String = String(first_part["text"]).to_lower()
	if text.find("scene_directives") != -1:
		return true
	if text.find("mission generation") != -1:
		return true
	if text.find("teammate interference") != -1:
		return true
	if text.find("consequence generation") != -1:
		return true
	return false
func _apply_legacy_scene_schema(generation_config: Dictionary) -> void:
	var character_entry_schema := {
		"type": "object",
		"properties": {
			"expression": {
				"type": "string",
				"enum": LEGACY_EXPRESSIONS,
				"description": "Character expression identifier matching in-game sprite sets.",
			},
		},
		"required": ["expression"],
		"additionalProperties": false,
	}
	var character_props: Dictionary = { }
	for character_id in LEGACY_REQUIRED_CHARACTERS:
		character_props[character_id] = character_entry_schema.duplicate(true)
	var characters_schema := {
		"type": "object",
		"description": "Expressions to apply to main cast members (and optional supporting characters).",
		"properties": character_props,
		"required": LEGACY_REQUIRED_CHARACTERS,
		"additionalProperties": character_entry_schema.duplicate(true),
	}
	var scene_schema := {
		"type": "object",
		"description": "Scene dressing instructions for the current mission step.",
		"properties": {
			"background": {
				"type": "string",
				"enum": LEGACY_BACKGROUND_IDS,
				"description": "Background asset identifier drawn from the stage catalog.",
			},
			"atmosphere": {
				"type": "string",
				"description": "Short tone descriptor describing the mood (<= 6 words).",
			},
			"lighting": {
				"type": "string",
				"description": "Lighting cue or direction (<= 6 words).",
			},
		},
		"required": ["background"],
		"additionalProperties": false,
	}
	var root_schema := {
		"type": "object",
		"description": "Structured story payload consumed by the stage renderer.",
		"properties": {
			"story_text": {
				"type": "string",
				"description": "Narrative paragraph rendered to the story panel.",
			},
			"scene": scene_schema,
			"characters": characters_schema,
		},
		"required": ["story_text", "scene", "characters"],
		"additionalProperties": false,
		"propertyOrdering": ["story_text", "scene", "characters"],
	}
	generation_config["responseMimeType"] = "application/json"
	generation_config["responseSchema"] = _convert_schema_for_gemini(root_schema)
	generation_config["responseJsonSchema"] = root_schema
func _convert_schema_for_gemini(schema_variant) -> Dictionary:
	if not (schema_variant is Dictionary):
		return { }
	return _convert_schema_node(schema_variant, "")
func _convert_schema_node(node, parent_key: String):
	if node is Dictionary:
		var result: Dictionary = { }
		for key in (node as Dictionary).keys():
			if key == "additionalProperties":
				continue
			var value = (node as Dictionary)[key]
			if key == "type":
				result[key] = _convert_type_value(value)
			elif key == "items":
				result[key] = _convert_schema_node(value, key)
			elif key == "properties" or key == "patternProperties":
				if value is Dictionary:
					var nested: Dictionary = { }
					for nested_key in (value as Dictionary).keys():
						nested[nested_key] = _convert_schema_node(value[nested_key], nested_key)
					result[key] = nested
				else:
					result[key] = _convert_schema_node(value, key)
			else:
				result[key] = _convert_schema_node(value, key)
		return result
	elif node is Array:
		var array_result: Array = []
		for entry in node:
			array_result.append(_convert_schema_node(entry, parent_key))
		return array_result
	return node
func _convert_type_value(value) -> Variant:
	if value is String:
		return String(value).to_upper()
	if value is Array:
		var converted: Array = []
		for entry in value:
			if entry is String:
				converted.append(String(entry).to_upper())
			else:
				converted.append(entry)
		return converted
	return value
func _send_rest_request(messages: Array) -> void:
	if api_key.is_empty():
		_report_error("API key is empty. Cannot send request")
		is_requesting = false
		_emit_error("API key is not configured")
		request_completed.emit(false)
		return
	if api_key.begins_with("http://") or api_key.begins_with("https://"):
		_report_error(
			"API key appears to be a URL ('%s...'). Please provide a valid Gemini API key string" % api_key.substr(0, 30),
			ErrorCodes.AI.INVALID_API_KEY,
			{ "api_key_preview": api_key.substr(0, 30) },
		)
		is_requesting = false
		_emit_error("Invalid API key format - appears to be a URL instead of an API key")
		request_completed.emit(false)
		return
	var endpoint := GEMINI_ENDPOINT_BASE + model + ":generateContent"
	var url := endpoint + "?key=" + api_key
	var contents_array: Array = []
	var system_parts: Array = []
	if _should_add_audio_output_guardrail():
		system_parts.append({ "text": _get_audio_output_guardrail_text() })
	for msg in messages:
		var role := str(msg.get("role", "user"))
		if role == "system":
			if msg.has("parts"):
				for part in msg["parts"]:
					system_parts.append(part)
			else:
				system_parts.append({ "text": str(msg.get("content", "")) })
			continue
		var gemini_role := "user"
		if role == "assistant":
			gemini_role = "model"
		var parts_payload: Array = []
		if msg.has("parts"):
			for part in msg["parts"]:
				parts_payload.append(part)
		else:
			parts_payload.append({ "text": str(msg.get("content", "")) })
		contents_array.append(
			{
				"role": gemini_role,
				"parts": parts_payload,
			},
		)
	var body: Dictionary = {
		"contents": contents_array,
		"generationConfig": {
			"maxOutputTokens": 2048,
		},
		"safetySettings": SAFETY_SETTINGS_MAP.get(safety_settings_key, SAFETY_SETTINGS_MAP["BLOCK_NONE"]),
	}
	var generation_config: Dictionary = body.get("generationConfig", { })
	if model.begins_with("gemini-3"):
		generation_config["temperature"] = 1.0 
	else:
		generation_config["temperature"] = 0.9 
	var structured_applied := _apply_structured_output_config(generation_config)
	if not structured_applied and _detect_scene_schema_needed(contents_array):
		_apply_legacy_scene_schema(generation_config)
	body["generationConfig"] = generation_config
	if system_parts.size() > 0:
		body["system_instruction"] = { "parts": system_parts }
	var response_modalities: Array = ["TEXT"]
	if voice_session and voice_session.has_method("wants_voice_output") and voice_session.wants_voice_output():
		response_modalities.append("AUDIO")
	if response_modalities.has("AUDIO"):
		body["responseModalities"] = response_modalities
	if voice_session and voice_session.has_method("prefers_native_audio") and voice_session.prefers_native_audio():
		var speech_config := {
			"voiceConfig": {
				"prebuiltVoiceConfig": {
					"voiceName": voice_session.get_preferred_voice_name() if voice_session.has_method("get_preferred_voice_name") else "Kore",
				},
			},
			"enableNativeVoice": true,
		}
		body["speechConfig"] = speech_config
	var headers: PackedStringArray = ["Content-Type: application/json"]
	var json_body := JSON.stringify(body)
	_emit_progress({ "status": "sending_rest", "body_bytes": json_body.length() })
	var error := http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		is_requesting = false
		_emit_error("Failed to send Gemini REST request: " + str(error))
		request_completed.emit(false)
func _send_live_request(messages: Array) -> void:
	if not live_api_client:
		_emit_error("Live API client not initialized")
		return
	_live_accumulated_text_parts.clear()
	_live_accumulated_audio_payloads.clear()
	_live_accumulated_thought_signature = ""
	var system_instruction_text := ""
	if _should_add_audio_output_guardrail():
		system_instruction_text += _get_audio_output_guardrail_text() + "\n"
	var contents_array: Array = []
	for msg in messages:
		if not (msg is Dictionary):
			continue
		var role := str(msg.get("role", "user"))
		if role == "system":
			system_instruction_text += _message_to_plain_text(msg) + "\n"
			continue
		var gemini_role := "user"
		if role == "assistant":
			gemini_role = "model"
		var parts_payload: Array = []
		if msg.has("parts"):
			for part in msg["parts"]:
				parts_payload.append(part)
		elif msg.has("content"):
			parts_payload.append({ "text": str(msg["content"]) })
		else:
			var text_content := _message_to_plain_text(msg)
			if not text_content.is_empty():
				parts_payload.append({ "text": text_content })
		if not parts_payload.is_empty():
			contents_array.append({
				"role": gemini_role,
				"parts": parts_payload,
			})
	system_instruction_text = system_instruction_text.strip_edges()
	var generation_config: Dictionary = {
		"temperature": 0.9,
		"maxOutputTokens": 2048,
	}
	# Live (BidiGenerateContent) behaves differently from REST; keep config minimal for compatibility.
	var speech_config := { }
	if voice_session and voice_session.has_method("prefers_native_audio") and voice_session.prefers_native_audio():
		speech_config = {
			"voiceConfig": {
				"prebuiltVoiceConfig": {
					"voiceName": voice_session.get_preferred_voice_name() if voice_session.has_method("get_preferred_voice_name") else "Kore",
				},
			},
			"enableNativeVoice": true,
		}
	_emit_progress({ "status": "connecting_live", "messages": messages.size() })
	live_api_client.connect_to_server(
		model.trim_prefix("models/"),
		api_key,
		generation_config,
		live_api_session_handle,
		system_instruction_text,
		speech_config,
	)
func _on_live_api_connection_established() -> void:
	_emit_progress({ "status": "live_connected" })
	if last_sent_messages.is_empty():
		ErrorReporterBridge.report_warning(
			"GeminiProvider",
			"Live API connected, but no messages were queued to be sent",
		)
		return
	var last_message: Variant = last_sent_messages.back()
	if last_message is Dictionary:
		var last_message_dict: Dictionary = last_message
		var parts_to_send: Array = last_message_dict.get("parts", [])
		if not parts_to_send.is_empty():
			live_api_client.send_user_turn(parts_to_send)
		else:
			var text_to_send := _message_to_plain_text(last_message_dict)
			if not text_to_send.is_empty():
				live_api_client.send_user_turn([{ "text": text_to_send }])
func _on_live_api_connection_closed(code: int, reason: String) -> void:
	if code == 1011 and live_api_retry_count < MAX_LIVE_API_RETRIES:
		live_api_retry_count += 1
		_emit_progress({ "status": "live_retry", "attempt": live_api_retry_count })
		_send_live_request(last_sent_messages)
		return
	is_requesting = false
	_emit_error("Live API connection closed. Code: %d, Reason: %s" % [code, reason])
	request_completed.emit(false)
func _on_live_api_connection_error() -> void:
	if live_api_retry_count < MAX_LIVE_API_RETRIES:
		live_api_retry_count += 1
		_emit_progress({ "status": "live_retry", "attempt": live_api_retry_count })
		_send_live_request(last_sent_messages)
		return
	is_requesting = false
	_emit_error("Live API connection error")
	request_completed.emit(false)
func _on_live_api_server_message(message: Dictionary) -> void:
	if not (message.has("serverContent") or message.has("server_content")):
		return
	_extract_live_response_chunks(message)
	var turn_complete := _is_live_turn_complete(message)
	if not turn_complete:
		_emit_progress({ "status": "live_streaming" })
		return
	is_requesting = false
	live_api_retry_count = 0
	_emit_progress({ "status": "live_completed" })
	var combined_text := "".join(_live_accumulated_text_parts)
	var response := {
		"success": true,
		"content": combined_text,
		"text_parts": _live_accumulated_text_parts.duplicate(true),
		"audio_payloads": _live_accumulated_audio_payloads.duplicate(true),
		"thought_signature": _live_accumulated_thought_signature,
		"error": "",
	}
	if not pending_callback.is_null():
		pending_callback.call(response)
	request_completed.emit(true)

func _on_live_api_setup_response_received(message: Dictionary) -> void:
	if message.has("serverContent") or message.has("server_content"):
		_on_live_api_server_message(message)

func _extract_live_response_chunks(message: Dictionary) -> void:
	if not (message is Dictionary):
		return
	var server_content: Variant = message.get("serverContent", message.get("server_content", null))
	var content_dict: Dictionary = server_content if server_content is Dictionary else message
	var model_turn: Variant = content_dict.get("modelTurn", content_dict.get("model_turn", null))
	var turn_dict: Dictionary = model_turn if model_turn is Dictionary else content_dict
	var parts_variant: Variant = turn_dict.get("parts", null)
	if not (parts_variant is Array):
		return
	var parts: Array = parts_variant
	for part in parts:
		if not (part is Dictionary):
			continue
		var part_dict: Dictionary = part
		if part_dict.has("text"):
			var text := str(part_dict.get("text", ""))
			if not text.is_empty():
				_live_accumulated_text_parts.append(text)
		if part_dict.has("thoughtSignature"):
			var sig := str(part_dict.get("thoughtSignature", ""))
			if not sig.is_empty():
				_live_accumulated_thought_signature = sig
		elif part_dict.has("thought_signature"):
			var sig2 := str(part_dict.get("thought_signature", ""))
			if not sig2.is_empty():
				_live_accumulated_thought_signature = sig2
		var inline_variant: Variant = part_dict.get("inlineData", part_dict.get("inline_data", null))
		if inline_variant is Dictionary:
			var inline_dict: Dictionary = inline_variant
			var mime := str(inline_dict.get("mimeType", inline_dict.get("mime_type", "")))
			var data_base64 := str(inline_dict.get("data", ""))
			if not mime.is_empty() and not data_base64.is_empty() and mime.begins_with("audio/"):
				_live_accumulated_audio_payloads.append(
					{
						"mime_type": mime,
						"data_base64": data_base64,
						"source": "live",
						"sample_rate": _sample_rate_from_mime(mime, DEFAULT_OUTPUT_SAMPLE_RATE),
					},
				)

func _is_live_turn_complete(message: Dictionary) -> bool:
	var server_content: Variant = message.get("serverContent", message.get("server_content", null))
	if server_content is Dictionary:
		var content_dict: Dictionary = server_content
		if content_dict.has("turnComplete"):
			return bool(content_dict.get("turnComplete", false))
		if content_dict.has("turn_complete"):
			return bool(content_dict.get("turn_complete", false))
	return true

func _sample_rate_from_mime(mime: String, fallback: int) -> int:
	var fragments := mime.split(";")
	for frag in fragments:
		var trimmed := frag.strip_edges()
		if trimmed.begins_with("rate="):
			var rate_value := int(trimmed.substr(5, trimmed.length()))
			if rate_value > 0:
				return rate_value
	return fallback
func _on_live_api_error(error_message: String) -> void:
	is_requesting = false
	_emit_error("Live API error: " + error_message)
	request_completed.emit(false)
func _on_live_api_session_updated(session_handle: String) -> void:
	live_api_session_handle = session_handle
	var handle_preview := session_handle.substr(0, 20) + "..." if session_handle.length() > 20 else session_handle
	_emit_progress({ "status": "session_updated", "handle_preview": handle_preview })
func _message_to_plain_text(message: Dictionary) -> String:
	if not message is Dictionary:
		return ""
	if message.has("parts") and message["parts"] is Array:
		var combined_text := ""
		for part in message["parts"]:
			if part is Dictionary and part.has("text"):
				combined_text += str(part["text"])
		if not combined_text.is_empty():
			return combined_text
	return str(message.get("content", ""))
func parse_response(result: int, response_code: int, body: PackedByteArray) -> Dictionary:
	var body_str := body.get_string_from_utf8()
	if result != HTTPRequest.RESULT_SUCCESS:
		var network_error := "Network error (code %d)" % result
		if OS.has_feature("web"):
			var cors_hint := _build_web_network_hint(result)
			if cors_hint.is_empty():
				cors_hint = "Check CORS settings and network connectivity in web build"
			network_error += " - " + cors_hint
		_report_error(
			network_error,
			ErrorCodes.AI.REQUEST_FAILED,
			{ "result_code": result, "is_web": OS.has_feature("web") },
		)
		return {
			"success": false,
			"error": network_error,
			"content": "",
			"status_code": response_code,
			"recoverable": true,
		}
	if response_code != 200:
		var error_msg := _build_http_error_message(response_code, body_str)
		var recoverable := response_code >= 500 or response_code == 429
		_report_error(
			error_msg,
			ErrorCodes.AI.HTTP_ERROR,
			{
				"response_code": response_code,
				"body_preview": body_str.substr(0, 200),
			},
		)
		return {
			"success": false,
			"error": error_msg,
			"content": "",
			"status_code": response_code,
			"recoverable": recoverable,
		}
	if body_str.is_empty():
		var empty_msg := "Empty response from server"
		_report_error(empty_msg)
		return {
			"success": false,
			"error": empty_msg,
			"content": "",
			"status_code": response_code,
			"recoverable": true,
		}
	var json = JSON.new()
	var parse_error := json.parse(body_str)
	if parse_error != OK:
		var parse_message := "JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()]
		_report_error(
			parse_message,
			ErrorCodes.AI.PARSE_ERROR,
			{
				"error_line": json.get_error_line(),
				"error_message": json.get_error_message(),
				"response_preview": body_str.substr(0, 200),
			},
		)
		return {
			"success": false,
			"error": "JSON parse error",
			"content": "",
			"status_code": response_code,
			"recoverable": true,
		}
	var response_data = json.data
	var ai_text_parts: Array = []
	var audio_payloads: Array = []
	var thought_signature: String = ""
	var input_tokens: int = 0
	var output_tokens: int = 0
	var total_tokens: int = 0
	if response_data.has("usageMetadata"):
		var usage = response_data["usageMetadata"]
		input_tokens = int(usage.get("promptTokenCount", 0))
		output_tokens = int(usage.get("candidatesTokenCount", 0))
		total_tokens = int(usage.get("totalTokenCount", 0))
	if response_data.has("candidates") and response_data["candidates"].size() > 0:
		var candidate = response_data["candidates"][0]
		if candidate.has("content") and candidate["content"].has("parts"):
			for part in candidate["content"]["parts"]:
				if part is Dictionary:
					if part.has("text"):
						ai_text_parts.append(str(part["text"]))
					if part.has("thoughtSignature"): 
						thought_signature = str(part["thoughtSignature"])
					if part.has("inlineData"):
						var inline_dict: Dictionary = part["inlineData"]
						var inline_mime := str(inline_dict.get("mimeType", ""))
						var inline_data := str(inline_dict.get("data", ""))
						if inline_mime.begins_with("audio/") and not inline_data.is_empty():
							audio_payloads.append(
								{
									"mime_type": inline_mime,
									"data_base64": inline_data,
									"source": "candidate",
									"sample_rate": DEFAULT_OUTPUT_SAMPLE_RATE,
								},
							)
	return {
		"success": true,
		"error": "",
		"content": ai_text_parts[0] if ai_text_parts.size() > 0 else "", 
		"text_parts": ai_text_parts,
		"audio_payloads": audio_payloads,
		"thought_signature": thought_signature,
		"status_code": response_code,
		"recoverable": false,
		"input_tokens": input_tokens,
		"output_tokens": output_tokens,
		"total_tokens": total_tokens,
	}
func _build_http_error_message(response_code: int, body_str: String) -> String:
	if OS.has_feature("web") and response_code == 0:
		return "Browser blocked Gemini request (CORS). Configure an API proxy or enable cross-origin support."
	var error_msg := "HTTP %d" % response_code
	if response_code == 400:
		error_msg += " Bad Request - likely invalid API key or request format"
	var detail := _extract_error_message_from_body(body_str)
	if not detail.is_empty():
		error_msg += " - " + detail
	return error_msg
func _build_web_network_hint(result: int) -> String:
	match result:
		HTTPRequest.RESULT_CANT_CONNECT, HTTPRequest.RESULT_CONNECTION_ERROR:
			return "Verify Gemini endpoint CORS or route requests through a proxy"
		HTTPRequest.RESULT_TIMEOUT:
			return "Request timed out in browser; check proxy or network latency"
	return ""
func _extract_error_message_from_body(body_str: String) -> String:
	if body_str.is_empty():
		return ""
	var json_test := JSON.new()
	if json_test.parse(body_str) != OK:
		return ""
	if not json_test.data is Dictionary:
		return ""
	var error_detail: Variant = json_test.data.get("error", { })
	if error_detail is Dictionary:
		var err_message: Variant = error_detail.get("message", "")
		if typeof(err_message) == TYPE_STRING:
			var err_string := String(err_message)
			if not err_string.is_empty():
				return err_string
	return ""
func _report_error(message: String, error_code: int = -1, details: Dictionary = { }) -> void:
	ErrorReporterBridge.report_error("GeminiProvider", message, error_code, false, details)
