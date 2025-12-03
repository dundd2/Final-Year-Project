extends RefCounted
const MAX_SAVE_SLOTS: int = 5
var _game_state: Node = null
var current_save_slot: int = 1
func set_game_state(game_state: Node) -> void:
	_game_state = game_state
func autosave() -> bool:
	if not _game_state:
		ErrorReporter.report_error("SaveLoadSystem", "Cannot autosave: GameState not set", -1)
		return false
	var autosave_path = "user://gda1_autosave.dat"
	var backup_path = "user://gda1_autosave_backup.dat"
	if FileAccess.file_exists(autosave_path):
		var dir = DirAccess.open("user://")
		if dir:
			dir.copy(autosave_path, backup_path)
	var save_file = FileAccess.open(autosave_path, FileAccess.WRITE)
	if save_file:
		var save_data = _game_state.get_save_data()
		save_data["is_autosave"] = true
		save_data["save_timestamp"] = Time.get_unix_time_from_system()
		save_file.store_var(save_data)
		save_file.close()
		ErrorReporter.report_info("SaveLoadSystem", "Auto-save completed successfully")
		return true
	else:
		var error = FileAccess.get_open_error()
		ErrorReporter.report_error("SaveLoadSystem", "Auto-save failed", error, false, { "path": autosave_path })
		return false
func save_to_slot(slot: int = -1) -> bool:
	if not _game_state:
		ErrorReporter.report_error("SaveLoadSystem", "Cannot save: GameState not set", -1)
		return false
	if slot == -1:
		slot = current_save_slot
	slot = clamp(slot, 1, MAX_SAVE_SLOTS)
	var save_path = "user://gda1_save_slot_%d.dat" % slot
	var backup_path = "user://gda1_save_slot_%d_backup.dat" % slot
	ErrorReporter.report_info("SaveLoadSystem", "Saving game to slot %d" % slot, { "path": save_path })
	if FileAccess.file_exists(save_path):
		var dir = DirAccess.open("user://")
		if dir:
			dir.copy(save_path, backup_path)
			ErrorReporter.report_info("SaveLoadSystem", "Backed up existing save", { "backup_path": backup_path })
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file:
		var save_data = _game_state.get_save_data()
		save_data["save_slot"] = slot
		save_data["save_timestamp"] = Time.get_unix_time_from_system()
		save_data["is_autosave"] = false
		save_file.store_var(save_data)
		save_file.close()
		current_save_slot = slot
		ErrorReporter.report_info("SaveLoadSystem", "Game saved successfully to slot %d" % slot)
		return true
	else:
		var error = FileAccess.get_open_error()
		ErrorReporter.report_error(
			"SaveLoadSystem",
			"Failed to save game",
			error,
			true,
			{
				"slot": slot,
				"path": save_path,
			},
		)
		return false
func load_from_slot(slot: int = -1) -> bool:
	if not _game_state:
		ErrorReporter.report_error("SaveLoadSystem", "Cannot load: GameState not set", -1)
		return false
	if slot == -1:
		slot = current_save_slot
	slot = clamp(slot, 1, MAX_SAVE_SLOTS)
	var save_path = "user://gda1_save_slot_%d.dat" % slot
	var backup_path = "user://gda1_save_slot_%d_backup.dat" % slot
	ErrorReporter.report_info("SaveLoadSystem", "Loading game from slot %d" % slot)
	if FileAccess.file_exists(save_path):
		var save_file = FileAccess.open(save_path, FileAccess.READ)
		if save_file:
			var save_data = save_file.get_var()
			save_file.close()
			if save_data == null:
				ErrorReporter.report_error("SaveLoadSystem", "Save file returned null data in slot %d" % slot, -1)
				if FileAccess.file_exists(backup_path):
					var restored_null := _load_from_backup(slot)
					if not restored_null:
						ErrorReporter.report_error(
							"SaveLoadSystem",
							"Failed to recover null save via backup for slot %d" % slot,
							-1,
							true,
							{ "backup_path": backup_path },
						)
					return restored_null
				return false
			if not save_data is Dictionary:
				ErrorReporter.report_error("SaveLoadSystem", "Save data is not a Dictionary in slot %d (type: %s)" % [slot, typeof(save_data)], -1)
				if FileAccess.file_exists(backup_path):
					var restored_type := _load_from_backup(slot)
					if not restored_type:
						ErrorReporter.report_error(
							"SaveLoadSystem",
							"Failed to recover malformed save via backup for slot %d" % slot,
							-1,
							true,
							{ "backup_path": backup_path },
						)
					return restored_type
				return false
			if save_data.has("reality_score") or save_data.has("player_stats_data"):
				_game_state.load_save_data(save_data)
				current_save_slot = slot
				ErrorReporter.report_info("SaveLoadSystem", "Game loaded successfully from slot %d" % slot)
				return true
			else:
				ErrorReporter.report_warning("SaveLoadSystem", "Corrupted save in slot %d (missing required keys), attempting backup..." % slot)
				if FileAccess.file_exists(backup_path):
					var restored_missing := _load_from_backup(slot)
					if not restored_missing:
						ErrorReporter.report_error(
							"SaveLoadSystem",
							"Failed to recover corrupted save via backup for slot %d" % slot,
							-1,
							true,
							{ "backup_path": backup_path },
						)
					return restored_missing
		else:
			var open_error := FileAccess.get_open_error()
			ErrorReporter.report_error(
				"SaveLoadSystem",
				"Failed to open save file for slot %d" % slot,
				open_error,
				true,
				{ "path": save_path },
			)
			if FileAccess.file_exists(backup_path):
				var restored_open := _load_from_backup(slot)
				if not restored_open:
					ErrorReporter.report_error(
						"SaveLoadSystem",
						"Failed to recover from unreadable save via backup for slot %d" % slot,
						-1,
						true,
						{ "backup_path": backup_path },
					)
				return restored_open
	else:
		ErrorReporter.report_info("SaveLoadSystem", "Save file does not exist at slot %d" % slot)
	return false
func _load_from_backup(slot: int) -> bool:
	if not _game_state:
		return false
	var backup_path = "user://gda1_save_slot_%d_backup.dat" % slot
	if not FileAccess.file_exists(backup_path):
		ErrorReporter.report_warning("SaveLoadSystem", "Backup file missing for slot %d" % slot, { "backup_path": backup_path })
		return false
	var save_file = FileAccess.open(backup_path, FileAccess.READ)
	if not save_file:
		var open_error := FileAccess.get_open_error()
		ErrorReporter.report_error(
			"SaveLoadSystem",
			"Failed to open backup save for slot %d" % slot,
			open_error,
			false,
			{ "backup_path": backup_path },
		)
		return false
	var save_data = save_file.get_var()
	save_file.close()
	if not save_data is Dictionary or not (save_data.has("reality_score") or save_data.has("player_stats_data")):
		ErrorReporter.report_warning(
			"SaveLoadSystem",
			"Backup save invalid for slot %d" % slot,
			{ "backup_path": backup_path, "data_type": typeof(save_data) },
		)
		return false
	_game_state.load_save_data(save_data)
	current_save_slot = slot
	ErrorReporter.report_info("SaveLoadSystem", "Game loaded from backup slot %d" % slot, { "backup_path": backup_path })
	return true
func load_game() -> bool:
	if not _game_state:
		return false
	if FileAccess.file_exists("user://gda1_autosave.dat"):
		var save_file = FileAccess.open("user://gda1_autosave.dat", FileAccess.READ)
		if save_file:
			var save_data = save_file.get_var()
			save_file.close()
			if save_data is Dictionary and (save_data.has("reality_score") or save_data.has("player_stats_data")):
				_game_state.load_save_data(save_data)
				return true
	return load_from_slot(current_save_slot)
func get_autosave_info() -> Dictionary:
	var save_path = "user://gda1_autosave.dat"
	if not FileAccess.file_exists(save_path):
		return { "exists": false }
	var save_file = FileAccess.open(save_path, FileAccess.READ)
	if not save_file:
		return { "exists": false }
	var save_data = save_file.get_var()
	save_file.close()
	if not save_data is Dictionary:
		return { "exists": false }
	var reality_score = 0
	if save_data.has("player_stats_data"):
		reality_score = save_data["player_stats_data"].get("reality_score", 0)
	else:
		reality_score = save_data.get("reality_score", 0)
	var entropy_level = 0
	if save_data.has("player_stats_data"):
		entropy_level = save_data["player_stats_data"].get("entropy_level", 0)
	else:
		entropy_level = save_data.get("entropy_level", 0)
	return {
		"exists": true,
		"timestamp": save_data.get("save_timestamp", 0),
		"reality_score": reality_score,
		"missions_completed": save_data.get("missions_completed", 0),
		"entropy_level": entropy_level,
		"save_slot": save_data.get("save_slot", 0),
		"is_autosave": true,
	}
func get_save_slot_info(slot: int) -> Dictionary:
	var save_path = "user://gda1_save_slot_%d.dat" % slot
	if not FileAccess.file_exists(save_path):
		return { "exists": false }
	var save_file = FileAccess.open(save_path, FileAccess.READ)
	if not save_file:
		return { "exists": false }
	var save_data = save_file.get_var()
	save_file.close()
	if not save_data is Dictionary:
		return { "exists": false }
	var reality_score = 0
	if save_data.has("player_stats_data"):
		reality_score = save_data["player_stats_data"].get("reality_score", 0)
	else:
		reality_score = save_data.get("reality_score", 0)
	var entropy_level = 0
	if save_data.has("player_stats_data"):
		entropy_level = save_data["player_stats_data"].get("entropy_level", 0)
	else:
		entropy_level = save_data.get("entropy_level", 0)
	return {
		"exists": true,
		"timestamp": save_data.get("save_timestamp", 0),
		"reality_score": reality_score,
		"missions_completed": save_data.get("missions_completed", 0),
		"entropy_level": entropy_level,
		"is_autosave": save_data.get("is_autosave", false),
		"save_slot": slot,
	}
func get_latest_save_info() -> Dictionary:
	var latest_timestamp: int = -1
	var latest_info: Dictionary = { "exists": false }
	var autosave_info := get_autosave_info()
	if autosave_info.get("exists", false):
		latest_timestamp = int(autosave_info.get("timestamp", 0))
		latest_info = autosave_info.duplicate()
	for slot in range(1, MAX_SAVE_SLOTS + 1):
		var slot_info := get_save_slot_info(slot)
		if not slot_info.get("exists", false):
			continue
		var slot_timestamp := int(slot_info.get("timestamp", 0))
		if slot_timestamp > latest_timestamp:
			latest_timestamp = slot_timestamp
			latest_info = slot_info.duplicate()
	if latest_info.get("exists", false):
		return latest_info
	return { "exists": false }
func has_saved_game() -> bool:
	return get_latest_save_info().get("exists", false)
func delete_save_slot(slot: int) -> bool:
	slot = clamp(slot, 1, MAX_SAVE_SLOTS)
	var dir = DirAccess.open("user://")
	if dir == null:
		return false
	var main_name = "gda1_save_slot_%d.dat" % slot
	var backup_name = "gda1_save_slot_%d_backup.dat" % slot
	var success = true
	if dir.file_exists(main_name):
		if dir.remove(main_name) != OK:
			success = false
			ErrorReporter.report_error("SaveLoadSystem", "Failed to delete save slot %d" % slot, -1)
	if dir.file_exists(backup_name):
		dir.remove(backup_name)
	if success:
		ErrorReporter.report_info("SaveLoadSystem", "Deleted save slot %d" % slot)
	return success
func delete_autosave() -> bool:
	var dir = DirAccess.open("user://")
	if dir == null:
		return false
	var main_name = "gda1_autosave.dat"
	var backup_name = "gda1_autosave_backup.dat"
	var success = true
	if dir.file_exists(main_name):
		if dir.remove(main_name) != OK:
			success = false
			ErrorReporter.report_error("SaveLoadSystem", "Failed to delete autosave", -1)
	if dir.file_exists(backup_name):
		dir.remove(backup_name)
	if success:
		ErrorReporter.report_info("SaveLoadSystem", "Deleted autosave")
	return success
