extends RefCounted
class_name AIProviderManager
const GeminiProvider = preload("res://1.Codebase/src/scripts/core/ai/gemini_provider.gd")
const OpenRouterProvider = preload("res://1.Codebase/src/scripts/core/ai/openrouter_provider.gd")
const OllamaProvider = preload("res://1.Codebase/src/scripts/core/ai/ollama_provider.gd")
var _gemini_provider: GeminiProvider = null
var _openrouter_provider: OpenRouterProvider = null
var _ollama_provider: OllamaProvider = null
var _ollama_client: Node = null 
const ERROR_CONTEXT := "AIProviderManager"
var _config_manager: AIConfigManager = null
signal provider_request_completed(success: bool)
signal provider_request_error(message: String)
signal provider_request_progress(update: Dictionary)
func set_config_manager(config_mgr: AIConfigManager) -> void:
	_config_manager = config_mgr
func initialize_providers(
		http_request: HTTPRequest,
		live_api_client,
		voice_session,
		ollama_client = null,
) -> void:
	_ollama_client = ollama_client
	_gemini_provider = GeminiProvider.new()
	_gemini_provider.setup(http_request, live_api_client, voice_session)
	_gemini_provider.request_completed.connect(_on_provider_request_completed)
	_gemini_provider.request_error.connect(_on_provider_error)
	_gemini_provider.request_progress.connect(_on_provider_progress)
	_openrouter_provider = OpenRouterProvider.new()
	_openrouter_provider.setup(http_request)
	_openrouter_provider.request_completed.connect(_on_provider_request_completed)
	_openrouter_provider.request_error.connect(_on_provider_error)
	_openrouter_provider.request_progress.connect(_on_provider_progress)
	_ollama_provider = OllamaProvider.new()
	_ollama_provider.setup(_ollama_client)
	_ollama_provider.request_completed.connect(_on_provider_request_completed)
	_ollama_provider.request_error.connect(_on_provider_error)
	_ollama_provider.request_progress.connect(_on_provider_progress)
	print("[AIProviderManager] Providers initialized: Gemini, OpenRouter, Ollama")
func get_current_provider():
	if not _config_manager:
		ErrorReporterBridge.report_error(ERROR_CONTEXT, "Config manager not set")
		return null
	match _config_manager.current_provider:
		AIConfigManager.AIProvider.GEMINI:
			return _gemini_provider
		AIConfigManager.AIProvider.OPENROUTER:
			return _openrouter_provider
		AIConfigManager.AIProvider.OLLAMA:
			return _ollama_provider
	return null
func get_provider_name(provider: AIConfigManager.AIProvider) -> String:
	match provider:
		AIConfigManager.AIProvider.GEMINI:
			return "GEMINI"
		AIConfigManager.AIProvider.OPENROUTER:
			return "OPENROUTER"
		AIConfigManager.AIProvider.OLLAMA:
			return "OLLAMA"
	return "UNKNOWN"
func get_current_provider_name() -> String:
	if not _config_manager:
		return "UNKNOWN"
	return get_provider_name(_config_manager.current_provider)
func sync_provider(provider_type: AIConfigManager.AIProvider) -> void:
	if not _config_manager:
		ErrorReporterBridge.report_error(ERROR_CONTEXT, "Cannot sync provider - config manager not set")
		return
	var config := _config_manager.get_provider_config(provider_type)
	match provider_type:
		AIConfigManager.AIProvider.GEMINI:
			if _gemini_provider:
				_gemini_provider.apply_configuration(config)
				print("[AIProviderManager] Synced Gemini provider")
		AIConfigManager.AIProvider.OPENROUTER:
			if _openrouter_provider:
				_openrouter_provider.apply_configuration(config)
				print("[AIProviderManager] Synced OpenRouter provider")
		AIConfigManager.AIProvider.OLLAMA:
			if _ollama_provider:
				_ollama_provider.apply_configuration(config)
				print("[AIProviderManager] Synced Ollama provider")
func sync_all_providers() -> void:
	sync_provider(AIConfigManager.AIProvider.GEMINI)
	sync_provider(AIConfigManager.AIProvider.OPENROUTER)
	sync_provider(AIConfigManager.AIProvider.OLLAMA)
	print("[AIProviderManager] All providers synced")
func is_provider_configured(provider: AIConfigManager.AIProvider) -> bool:
	if not _config_manager:
		return false
	return _config_manager.is_provider_configured(provider)
func is_ollama_ready(timeout_sec: float = 0.5) -> bool:
	if _ollama_provider == null:
		return false
	sync_provider(AIConfigManager.AIProvider.OLLAMA)
	if _ollama_client == null or not _ollama_client.has_method("health_check"):
		return false
	return _ollama_client.health_check(timeout_sec)
func get_provider_instance(provider_type: AIConfigManager.AIProvider):
	match provider_type:
		AIConfigManager.AIProvider.GEMINI:
			return _gemini_provider
		AIConfigManager.AIProvider.OPENROUTER:
			return _openrouter_provider
		AIConfigManager.AIProvider.OLLAMA:
			return _ollama_provider
	return null
func are_providers_initialized() -> bool:
	return _gemini_provider != null and _openrouter_provider != null and _ollama_provider != null
func _on_provider_request_completed(success: bool) -> void:
	provider_request_completed.emit(success)
func _on_provider_error(message: String) -> void:
	provider_request_error.emit(message)
func _on_provider_progress(update: Dictionary) -> void:
	provider_request_progress.emit(update)
