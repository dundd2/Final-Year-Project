extends Node
var SaveLoadSystemScript = preload("res://1.Codebase/src/scripts/core/save_load_system.gd")
var _save_system = null
var _mock_game_state = null
var _test_results = []
class MockGameState:
	var save_data_called = false
	var load_data_called = false
	var last_loaded_data = null
	func get_save_data() -> Dictionary:
		save_data_called = true
		return {
			"test_value": 42,
			"test_string": "Hello Test",
			"nested": { "key": "value" },
		}
	func load_save_data(data: Dictionary) -> void:
		load_data_called = true
		last_loaded_data = data
func _ready():
	print("\n" + "=".repeat(80))
	print("🧪 SAVE/LOAD SYSTEM TEST SUITE")
	print("=".repeat(80) + "\n")
	await run_all_tests()
	print_summary()
	cleanup_test_files()
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()
func run_all_tests():
	await run_test("Initialization", test_initialization)
	await run_test("Autosave Creation", test_autosave)
	await run_test("Save to Slot", test_save_to_slot)
	await run_test("Load from Slot", test_load_from_slot)
	await run_test("Multiple Slots", test_multiple_slots)
	await run_test("Autosave Info Query", test_autosave_info)
	await run_test("Slot Info Query", test_slot_info)
	await run_test("Latest Save Info", test_latest_save_info)
	await run_test("Has Saved Game", test_has_saved_game)
	await run_test("Delete Save Slot", test_delete_slot)
	await run_test("Delete Autosave", test_delete_autosave)
	await run_test("Backup Creation", test_backup_creation)
	await run_test("Backup Recovery", test_backup_recovery)
	await run_test("Slot Clamping", test_slot_clamping)
	await run_test("Empty GameState Handling", test_empty_gamestate)
func run_test(test_name: String, test_func: Callable):
	_save_system = SaveLoadSystemScript.new()
	_mock_game_state = MockGameState.new()
	_save_system.set_game_state(_mock_game_state)
	var result = await test_func.call()
	_test_results.append({ "name": test_name, "passed": result })
	if result:
		print("  ✅ %s" % test_name)
	else:
		print("  ❌ %s FAILED" % test_name)
func assert_equal(actual, expected, message: String = "") -> bool:
	if actual != expected:
		if message:
			print("    ⚠️  %s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
func assert_true(condition: bool, message: String = "") -> bool:
	if not condition:
		if message:
			print("    ⚠️  %s" % message)
		return false
	return true
func assert_file_exists(path: String, message: String = "") -> bool:
	if not FileAccess.file_exists(path):
		if message:
			print("    ⚠️  %s: file not found at %s" % [message, path])
		return false
	return true
func assert_file_not_exists(path: String, message: String = "") -> bool:
	if FileAccess.file_exists(path):
		if message:
			print("    ⚠️  %s: file unexpectedly exists at %s" % [message, path])
		return false
	return true
func test_initialization() -> bool:
	var success = true
	success = assert_equal(_save_system.current_save_slot, 1, "Default save slot is 1") and success
	success = assert_equal(_save_system.MAX_SAVE_SLOTS, 5, "Max save slots is 5") and success
	return success
func test_autosave() -> bool:
	var success = true
	var result = _save_system.autosave()
	success = assert_true(result, "Autosave succeeded") and success
	success = assert_true(_mock_game_state.save_data_called, "get_save_data was called") and success
	success = assert_file_exists("user://gda1_autosave.dat", "Autosave file created") and success
	var file = FileAccess.open("user://gda1_autosave.dat", FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()
		success = assert_true(data is Dictionary, "Autosave contains dictionary") and success
		success = assert_equal(data.get("test_value"), 42, "Autosave has correct data") and success
		success = assert_true(data.get("is_autosave"), "Autosave flag is true") and success
		success = assert_true(data.has("save_timestamp"), "Autosave has timestamp") and success
	return success
func test_save_to_slot() -> bool:
	var success = true
	var result = _save_system.save_to_slot(3)
	success = assert_true(result, "Save to slot 3 succeeded") and success
	success = assert_equal(_save_system.current_save_slot, 3, "Current slot updated to 3") and success
	success = assert_file_exists("user://gda1_save_slot_3.dat", "Slot 3 file created") and success
	var file = FileAccess.open("user://gda1_save_slot_3.dat", FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()
		success = assert_equal(data.get("save_slot"), 3, "Save slot number stored") and success
		success = assert_equal(data.get("is_autosave"), false, "Not marked as autosave") and success
	_save_system.current_save_slot = 2
	result = _save_system.save_to_slot(-1) 
	success = assert_true(result, "Save to current slot succeeded") and success
	success = assert_file_exists("user://gda1_save_slot_2.dat", "Slot 2 file created") and success
	return success
func test_load_from_slot() -> bool:
	var success = true
	_save_system.save_to_slot(4)
	_mock_game_state.load_data_called = false
	_mock_game_state.last_loaded_data = null
	var result = _save_system.load_from_slot(4)
	success = assert_true(result, "Load from slot 4 succeeded") and success
	success = assert_true(_mock_game_state.load_data_called, "load_save_data was called") and success
	success = assert_true(_mock_game_state.last_loaded_data is Dictionary, "Loaded data is dictionary") and success
	success = assert_equal(_mock_game_state.last_loaded_data.get("test_value"), 42, "Loaded correct data") and success
	success = assert_equal(_save_system.current_save_slot, 4, "Current slot updated") and success
	return success
func test_multiple_slots() -> bool:
	var success = true
	for slot in range(1, 6): 
		var result = _save_system.save_to_slot(slot)
		success = assert_true(result, "Save to slot %d succeeded" % slot) and success
	for slot in range(1, 6):
		success = assert_file_exists("user://gda1_save_slot_%d.dat" % slot, "Slot %d exists" % slot) and success
	return success
func test_autosave_info() -> bool:
	var success = true
	var info = _save_system.get_autosave_info()
	success = assert_equal(info.get("exists"), false, "No autosave initially") and success
	_save_system.autosave()
	info = _save_system.get_autosave_info()
	success = assert_equal(info.get("exists"), true, "Autosave exists") and success
	success = assert_equal(info.get("is_autosave"), true, "Marked as autosave") and success
	success = assert_true(info.has("timestamp"), "Has timestamp") and success
	return success
func test_slot_info() -> bool:
	var success = true
	var info = _save_system.get_save_slot_info(5)
	success = assert_equal(info.get("exists"), false, "Slot 5 doesn't exist initially") and success
	_save_system.save_to_slot(5)
	info = _save_system.get_save_slot_info(5)
	success = assert_equal(info.get("exists"), true, "Slot 5 exists") and success
	success = assert_equal(info.get("save_slot"), 5, "Correct slot number") and success
	success = assert_equal(info.get("is_autosave"), false, "Not autosave") and success
	success = assert_true(info.has("timestamp"), "Has timestamp") and success
	return success
func test_latest_save_info() -> bool:
	var success = true
	var info = _save_system.get_latest_save_info()
	success = assert_equal(info.get("exists"), false, "No saves initially") and success
	_save_system.save_to_slot(1)
	await get_tree().create_timer(0.1).timeout 
	_save_system.save_to_slot(2)
	info = _save_system.get_latest_save_info()
	success = assert_equal(info.get("exists"), true, "Latest save exists") and success
	success = assert_equal(info.get("save_slot"), 2, "Latest is slot 2") and success
	return success
func test_has_saved_game() -> bool:
	var success = true
	success = assert_equal(_save_system.has_saved_game(), false, "No saved game initially") and success
	_save_system.save_to_slot(1)
	success = assert_equal(_save_system.has_saved_game(), true, "Has saved game after save") and success
	return success
func test_delete_slot() -> bool:
	var success = true
	_save_system.save_to_slot(3)
	success = assert_file_exists("user://gda1_save_slot_3.dat", "Slot 3 created") and success
	var result = _save_system.delete_save_slot(3)
	success = assert_true(result, "Delete succeeded") and success
	success = assert_file_not_exists("user://gda1_save_slot_3.dat", "Slot 3 deleted") and success
	return success
func test_delete_autosave() -> bool:
	var success = true
	_save_system.autosave()
	success = assert_file_exists("user://gda1_autosave.dat", "Autosave created") and success
	var result = _save_system.delete_autosave()
	success = assert_true(result, "Delete succeeded") and success
	success = assert_file_not_exists("user://gda1_autosave.dat", "Autosave deleted") and success
	return success
func test_backup_creation() -> bool:
	var success = true
	_save_system.save_to_slot(1)
	_save_system.save_to_slot(1)
	success = assert_file_exists("user://gda1_save_slot_1_backup.dat", "Backup created") and success
	return success
func test_backup_recovery() -> bool:
	var success = true
	_save_system.save_to_slot(1)
	var corrupt_file = FileAccess.open("user://gda1_save_slot_1.dat", FileAccess.WRITE)
	if corrupt_file:
		corrupt_file.store_string("CORRUPTED DATA")
		corrupt_file.close()
	var result = _save_system.load_from_slot(1)
	success = assert_true(_mock_game_state.load_data_called, "Attempted to load data") and success
	return success
func test_slot_clamping() -> bool:
	var success = true
	_save_system.save_to_slot(0)
	success = assert_file_exists("user://gda1_save_slot_1.dat", "Slot 0 clamped to 1") and success
	_save_system.save_to_slot(10)
	success = assert_file_exists("user://gda1_save_slot_5.dat", "Slot 10 clamped to 5") and success
	_save_system.delete_save_slot(-1)
	success = assert_file_not_exists("user://gda1_save_slot_1.dat", "Delete with -1 clamped to 1") and success
	return success
func test_empty_gamestate() -> bool:
	var success = true
	var empty_system = SaveLoadSystemScript.new()
	var result = empty_system.autosave()
	success = assert_equal(result, false, "Autosave fails without GameState") and success
	result = empty_system.save_to_slot(1)
	success = assert_equal(result, false, "Save fails without GameState") and success
	result = empty_system.load_from_slot(1)
	success = assert_equal(result, false, "Load fails without GameState") and success
	return success
func cleanup_test_files():
	var dir = DirAccess.open("user://")
	if dir:
		if dir.file_exists("gda1_autosave.dat"):
			dir.remove("gda1_autosave.dat")
		if dir.file_exists("gda1_autosave_backup.dat"):
			dir.remove("gda1_autosave_backup.dat")
		for slot in range(1, 6):
			var main_file = "gda1_save_slot_%d.dat" % slot
			var backup_file = "gda1_save_slot_%d_backup.dat" % slot
			if dir.file_exists(main_file):
				dir.remove(main_file)
			if dir.file_exists(backup_file):
				dir.remove(backup_file)
	print("\n🧹 Test files cleaned up")
func print_summary():
	print("\n" + "=".repeat(80))
	var passed = _test_results.filter(func(r): return r.passed).size()
	var total = _test_results.size()
	if passed == total:
		print("✅ ALL TESTS PASSED (%d/%d)" % [passed, total])
	else:
		print("❌ SOME TESTS FAILED (%d/%d passed)" % [passed, total])
		print("\nFailed tests:")
		for result in _test_results:
			if not result.passed:
				print("  • %s" % result.name)
	print("=".repeat(80) + "\n")
