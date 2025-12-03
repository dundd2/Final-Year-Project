extends RefCounted
class_name AIConfigManager
const CONFIG_FILE_PATH := "user://ai_settings.cfg"
const GEMINI_DEFAULT_MODEL := "gemini-3-pro-preview"
const DEFAULT_OLLAMA_MODEL := "gemma3:1b"
enum AIProvider {
	GEMINI = 0,
	OPENROUTER = 1,
	OLLAMA = 2,
}
var current_provider: AIProvider = AIProvider.GEMINI
var gemini_api_key: String = ""
var gemini_access_token: String = ""
var gemini_project_id: String = ""
var gemini_location: String = ""
var gemini_model: String = GEMINI_DEFAULT_MODEL
var gemini_allow_web_requests: bool = true
var gemini_safety_settings: String = "BLOCK_NONE"
var openrouter_api_key: String = ""
var openrouter_model: String = "google/gemini-pro"
var ollama_host: String = "127.0.0.1"
var ollama_port: int = 11434
var ollama_model: String = DEFAULT_OLLAMA_MODEL
var ollama_use_chat: bool = true
var ollama_options: Dictionary = {
	"temperature": 0.7,
	"top_p": 0.9,
	"top_k": 40,
	"repeat_penalty": 1.1,
}
var memory_max_items: int = 20
var memory_summary_threshold: int = 10
var memory_full_entries: int = 5
var custom_ai_tone_style: String = ""
var default_ai_tone_style: String = "Maintain dark humor, ironic detachment, and satire of forced positivity."
var voice_config: Dictionary = { }
const ERROR_CONTEXT := "AIConfigManager"
func _init() -> void:
	custom_ai_tone_style = default_ai_tone_style
func save_settings() -> Error:
	var config = ConfigFile.new()
	config.set_value("ai", "provider", current_provider)
	config.set_value("ai", "gemini_key", gemini_api_key)
	config.set_value("ai", "gemini_access_token", gemini_access_token)
	config.set_value("ai", "gemini_project_id", gemini_project_id)
	config.set_value("ai", "gemini_location", gemini_location)
	config.set_value("ai", "gemini_model", gemini_model)
	config.set_value("ai", "gemini_allow_web_requests", gemini_allow_web_requests)
	config.set_value("ai", "gemini_safety_settings", gemini_safety_settings)
	config.set_value("ai", "openrouter_key", openrouter_api_key)
	config.set_value("ai", "openrouter_model", openrouter_model)
	config.set_value("ai", "ollama_host", ollama_host)
	config.set_value("ai", "ollama_port", ollama_port)
	config.set_value("ai", "ollama_model", ollama_model)
	config.set_value("ai", "ollama_use_chat", ollama_use_chat)
	config.set_value("ai", "ollama_options", ollama_options)
	config.set_value("ai", "memory_limit", memory_max_items)
	config.set_value("ai", "memory_summary_threshold", memory_summary_threshold)
	config.set_value("ai", "memory_full_entries", memory_full_entries)
	config.set_value("ai", "custom_ai_tone_style", custom_ai_tone_style)
	if not voice_config.is_empty():
		for key in voice_config:
			config.set_value("voice", key, voice_config[key])
	var err = config.save(CONFIG_FILE_PATH)
	if err == OK:
		print("[AIConfigManager] Settings saved to %s" % CONFIG_FILE_PATH)
	else:
		ErrorReporterBridge.report_error(
			ERROR_CONTEXT,
			"Failed to save settings: %d" % err,
			err,
			false,
			{ "error_code": err },
		)
	return err
func load_settings() -> Error:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILE_PATH)
	if err != OK:
		print("[AIConfigManager] No config file found, using defaults")
		return err
	print("[AIConfigManager] Loading settings from %s" % CONFIG_FILE_PATH)
	current_provider = config.get_value("ai", "provider", AIProvider.GEMINI)
	gemini_api_key = config.get_value("ai", "gemini_key", "")
	if BuildSecrets.GEMINI_API_KEY != "":
		print("[AIConfigManager] Using build-time injected API key")
		gemini_api_key = BuildSecrets.GEMINI_API_KEY
	gemini_access_token = config.get_value("ai", "gemini_access_token", "")
	gemini_project_id = config.get_value("ai", "gemini_project_id", "")
	gemini_location = config.get_value("ai", "gemini_location", "")
	gemini_model = config.get_value("ai", "gemini_model", GEMINI_DEFAULT_MODEL)
	gemini_allow_web_requests = bool(config.get_value("ai", "gemini_allow_web_requests", gemini_allow_web_requests))
	gemini_safety_settings = config.get_value("ai", "gemini_safety_settings", "BLOCK_NONE")
	openrouter_api_key = config.get_value("ai", "openrouter_key", "")
	openrouter_model = config.get_value("ai", "openrouter_model", "google/gemini-pro")
	ollama_host = str(config.get_value("ai", "ollama_host", ollama_host))
	ollama_port = int(config.get_value("ai", "ollama_port", ollama_port))
	ollama_model = str(config.get_value("ai", "ollama_model", DEFAULT_OLLAMA_MODEL))
	var migrated := _migrate_ollama_model(config)
	ollama_use_chat = bool(config.get_value("ai", "ollama_use_chat", ollama_use_chat))
	var stored_options = config.get_value("ai", "ollama_options", ollama_options)
	if stored_options is Dictionary:
		ollama_options = (stored_options as Dictionary).duplicate(true)
	memory_max_items = int(config.get_value("ai", "memory_limit", memory_max_items))
	memory_summary_threshold = int(config.get_value("ai", "memory_summary_threshold", memory_summary_threshold))
	memory_full_entries = int(config.get_value("ai", "memory_full_entries", memory_full_entries))
	custom_ai_tone_style = config.get_value("ai", "custom_ai_tone_style", default_ai_tone_style)
	voice_config.clear()
	if config.has_section("voice"):
		for key in config.get_section_keys("voice"):
			voice_config[key] = config.get_value("voice", key)
	if migrated:
		config.save(CONFIG_FILE_PATH)
	return OK
func _migrate_ollama_model(config: ConfigFile) -> bool:
	var normalized := ollama_model.strip_edges().to_lower()
	if normalized.is_empty() or normalized.begins_with("llama3"):
		print("[AIConfigManager] Migrating Ollama model from '%s' to '%s'" % [ollama_model, DEFAULT_OLLAMA_MODEL])
		ollama_model = DEFAULT_OLLAMA_MODEL
		config.set_value("ai", "ollama_model", ollama_model)
		return true
	return false
func get_ai_system_persona() -> String:
	return "You are the story director for Glorious Deliverance Agency 1 (GDA1). You are responsible for creating scenarios full of dark humor and challenging tasks. " + custom_ai_tone_style
func get_state_snapshot() -> Dictionary:
	return {
		"provider": current_provider,
		"gemini_model": gemini_model,
		"gemini_safety_settings": gemini_safety_settings,
		"openrouter_model": openrouter_model,
		"ollama_host": ollama_host,
		"ollama_port": ollama_port,
		"ollama_model": ollama_model,
		"custom_tone": custom_ai_tone_style,
		"memory_max": memory_max_items,
		"memory_threshold": memory_summary_threshold,
	}
func load_state_snapshot(state: Dictionary) -> void:
	if state.has("provider"):
		current_provider = state["provider"]
	if state.has("gemini_model"):
		gemini_model = state["gemini_model"]
	if state.has("gemini_safety_settings"):
		gemini_safety_settings = state["gemini_safety_settings"]
	if state.has("openrouter_model"):
		openrouter_model = state["openrouter_model"]
	if state.has("ollama_host"):
		ollama_host = state["ollama_host"]
	if state.has("ollama_port"):
		ollama_port = state["ollama_port"]
	if state.has("ollama_model"):
		ollama_model = state["ollama_model"]
	if state.has("custom_tone"):
		custom_ai_tone_style = state["custom_tone"]
	if state.has("memory_max"):
		memory_max_items = state["memory_max"]
	if state.has("memory_threshold"):
		memory_summary_threshold = state["memory_threshold"]
func is_provider_configured(provider: AIProvider) -> bool:
	match provider:
		AIProvider.GEMINI:
			return not gemini_api_key.is_empty() or not gemini_access_token.is_empty()
		AIProvider.OPENROUTER:
			return not openrouter_api_key.is_empty()
		AIProvider.OLLAMA:
			return true 
		_:
			return false
func get_provider_config(provider: AIProvider) -> Dictionary:
	match provider:
		AIProvider.GEMINI:
			return {
				"api_key": gemini_api_key,
				"access_token": gemini_access_token,
				"project_id": gemini_project_id,
				"location": gemini_location,
				"model": gemini_model,
				"allow_web_requests": gemini_allow_web_requests,
				"safety_settings": gemini_safety_settings,
			}
		AIProvider.OPENROUTER:
			return {
				"api_key": openrouter_api_key,
				"model": openrouter_model,
			}
		AIProvider.OLLAMA:
			return {
				"host": ollama_host,
				"port": ollama_port,
				"model": ollama_model,
				"use_chat": ollama_use_chat,
				"options": ollama_options.duplicate(),
			}
		_:
			return { }
func get_memory_config() -> Dictionary:
	return {
		"max_items": memory_max_items,
		"summary_threshold": memory_summary_threshold,
		"full_entries": memory_full_entries,
	}
func get_voice_config() -> Dictionary:
	return voice_config.duplicate()
func set_voice_config(config: Dictionary) -> void:
	voice_config = config.duplicate()
