extends Node
const SessionProgressTrackerScript = preload("res://1.Codebase/src/scripts/core/session_progress_tracker.gd")
var tracker: SessionProgressTracker = null
func _ready() -> void:
	print("[SessionProgressTrackerTest] Starting unit tests...")
	await get_tree().process_frame
	_setup()
	_test_initialization()
	_test_save_load_payload()
	_test_metadata_management()
	_test_language_setting()
	_test_reset()
	_teardown()
	print("[SessionProgressTrackerTest] All tests completed.")
	queue_free()
func _setup() -> void:
	print("[Test Setup] Creating SessionProgressTracker...")
	tracker = SessionProgressTrackerScript.new()
func _teardown() -> void:
	if tracker:
		tracker = null
func _test_initialization() -> void:
	print("[Test] Initialization...")
	assert(tracker != null, "Tracker should be created")
	assert(tracker.current_mission == 0, "Current mission should start at 0")
	assert(tracker.missions_completed == 0, "Missions completed should start at 0")
	assert(tracker.game_phase == GameConstants.GamePhase.HONEYMOON, "Should start in HONEYMOON phase")
	assert(tracker.is_session_active == false, "Session should not be active initially")
	print("[Test] Initialization PASSED")
func _test_save_load_payload() -> void:
	print("[Test] Save/Load payload...")
	tracker.current_mission = 5
	tracker.missions_completed = 4
	tracker.complaint_counter = 3
	tracker.game_phase = GameConstants.GamePhase.CRISIS
	tracker.honeymoon_charges = 2
	tracker.is_session_active = true
	tracker.current_language = "zh"
	tracker.metadata = {"key": "value", "nested": {"a": 1}}
	var payload = tracker.get_save_payload()
	assert(payload.current_mission == 5, "Payload should match current_mission")
	assert(payload.missions_completed == 4, "Payload should match missions_completed")
	assert(payload.game_phase == GameConstants.GamePhase.CRISIS, "Payload should match game_phase")
	assert(payload.metadata.key == "value", "Payload should match metadata")
	assert(payload.is_session_active == true, "Payload should match is_session_active")
	var new_tracker = SessionProgressTrackerScript.new()
	new_tracker.apply_save_payload(payload)
	assert(new_tracker.current_mission == 5, "Restored mission should match")
	assert(new_tracker.missions_completed == 4, "Restored missions completed should match")
	assert(new_tracker.game_phase == GameConstants.GamePhase.CRISIS, "Restored game phase should match")
	assert(new_tracker.is_session_active == true, "Restored session active should match")
	assert(new_tracker.metadata.key == "value", "Restored metadata should match")
	assert(new_tracker.metadata == tracker.metadata, "Metadata content should match")
	assert(not is_same(new_tracker.metadata, tracker.metadata), "Metadata should be a new instance")
	print("[Test] Save/Load payload PASSED")
func _test_metadata_management() -> void:
	print("[Test] Metadata management...")
	tracker.metadata = {"keep": 1, "delete1": 2, "delete2": 3}
	var removed = tracker.delete_metadata_keys(["delete1", "delete2", "missing"])
	assert(removed.size() == 2, "Should remove 2 keys")
	assert("delete1" in removed, "Should report delete1 removed")
	assert("delete2" in removed, "Should report delete2 removed")
	assert(tracker.metadata.has("keep"), "Should keep other keys")
	assert(not tracker.metadata.has("delete1"), "Should remove delete1")
	print("[Test] Metadata management PASSED")
func _test_language_setting() -> void:
	print("[Test] Language setting...")
	tracker.current_language = "en"
	tracker.set_language("zh")
	assert(tracker.current_language == "zh", "Should set language to zh")
	tracker.set_language("")
	assert(tracker.current_language == "zh", "Should ignore empty language")
	print("[Test] Language setting PASSED")
func _test_reset() -> void:
	print("[Test] Reset...")
	tracker.current_mission = 10
	tracker.metadata = {"dirty": true}
	tracker.is_session_active = true
	tracker.reset()
	assert(tracker.current_mission == 0, "Should reset mission")
	assert(tracker.metadata.is_empty(), "Should clear metadata")
	assert(tracker.is_session_active == false, "Should reset session active")
	assert(tracker.game_phase == GameConstants.GamePhase.HONEYMOON, "Should reset phase")
	print("[Test] Reset PASSED")
