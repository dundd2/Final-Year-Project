extends Control
const ERROR_CONTEXT := "AIUsageExample"
@onready var ai_manager: Node = _resolve_ai_manager()
var reality_score: int = 50
var positive_energy: int = 50
func _ready() -> void:
	var manager := _get_ai_manager()
	if not manager:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "AIManager unavailable; skipping signal connections")
		return
	_connect_signals(manager)
func _connect_signals(manager: Node) -> void:
	if manager.has_signal("ai_response_received"):
		manager.ai_response_received.connect(_on_story_generated)
	else:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "AIManager missing ai_response_received signal")
	if manager.has_signal("ai_error"):
		manager.ai_error.connect(_on_ai_error)
	else:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "AIManager missing ai_error signal")
func generate_new_mission() -> void:
	var manager := _get_ai_manager()
	if not manager:
		return
	var prompt := """
	        請生成一個新的任務場景。這個任務應該：
	        1. 表面上看起來很簡單
	        2. 但充滿了陷阱和讓隊友搞砸的機會
	        3. 包含Gloria可以發動PUA的情境
	        4. 最終無論如何都會導致災難性的結果
	
	        請用以下格式回應：
	        任務標題：[標題]
	        任務描述：[200字以內的場景描述]
	        初始選項：[3個玩家可以選擇的行動]
	        """
	var context := {
		"purpose": "mission",
		"reality_score": reality_score,
		"positive_energy": positive_energy,
	}
	manager.generate_story(prompt, context)
func generate_teammate_reaction(player_action: String) -> void:
	var manager := _get_ai_manager()
	if not manager:
		return
	var prompt := """
	        玩家剛剛採取了以下行動：%s
	
	        請生成Donkey的反應。他應該：
	        1. 完全誤解情況
	        2. 用英雄主義的方式搞砸一切
	        3. 讓原本可能成功的計劃變成災難
	
	        請用50-100字描述他的反應和後果。
	        """ % player_action
	var context := {
		"purpose": "interference",
		"reality_score": reality_score,
		"positive_energy": positive_energy,
		"teammate": "donkey",
		"player_action": player_action,
	}
	manager.generate_story(prompt, context)
func generate_gloria_pua() -> void:
	var manager := _get_ai_manager()
	if not manager:
		return
	var prompt := """
	        主角剛剛對團隊表達了不滿和質疑。
	
	        請生成Gloria的回應。她應該：
	        1. 完全迴避實際問題
	        2. 用「你太負面了」來責怪主角
	        3. 暗示主角的質疑「傷害了她的感受」
	        4. 引用「正能量法則」來證明一切都是主角的錯
	
	        請用100-150字生成她的對話。
	        """
	var context := {
		"purpose": "interference",
		"reality_score": reality_score,
		"positive_energy": positive_energy,
		"teammate": "gloria",
		"player_action": "主角提出理性質疑",
	}
	manager.generate_story(prompt, context)
func generate_prayer_consequence(prayer_text: String) -> void:
	var manager := _get_ai_manager()
	if not manager:
		return
	var prompt := """
	        玩家向「飛天意粉神」祈禱了以下內容：
	        「%s」
	
	        請生成一個與祈禱內容諷刺性相反的災難性結果。
	        玩家越是祈禱正能量的事，結果應該越荒謬、越災難。
	
	        請用100-150字描述這個災難性的轉折。
	        """ % prayer_text
	var context := {
		"purpose": "prayer",
		"reality_score": reality_score,
		"positive_energy": positive_energy,
		"prayer_text": prayer_text,
	}
	manager.generate_story(prompt, context)
func _on_story_generated(response: String) -> void:
	print("AI Generated Story:")
	print(response)
	print("=".repeat(50))
	var manager := _get_ai_manager()
	if manager:
		manager.add_to_memory(response.substr(0, min(200, response.length())))
func _on_ai_error(error_message: String) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, error_message)
	print("AI Error: ", error_message)
func example_gameplay_flow() -> void:
	generate_new_mission()
	pass
func _resolve_ai_manager() -> Node:
	if typeof(ServiceLocator) == TYPE_NIL or ServiceLocator == null:
		return null
	return ServiceLocator.get_ai_manager()
func _get_ai_manager() -> Node:
	if is_instance_valid(ai_manager):
		return ai_manager
	ai_manager = _resolve_ai_manager()
	if not ai_manager:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "AIManager not available via ServiceLocator")
	return ai_manager
