extends Node
const ERROR_CONTEXT := "AudioManager"
const VOICE_BUS_NAME := "Voice"
const VOICE_INPUT_BUS_NAME := "VoiceInput"
const MAX_SFX_PLAYERS := 8
const DEFAULT_VOICE_SAMPLE_RATE := 24000
const AUDIO_DIRECTORIES := {
	"music": "res://1.Codebase/src/assets/music",
	"sfx": "res://1.Codebase/src/assets/sound",
}
const SUPPORTED_AUDIO_EXTENSIONS := ["mp3", "ogg", "wav", "opus", "flac", "webm"]
const SFX_ALIASES := {
	"menu_close": "menu_click",
	"menu_back": "menu_click",
	"menu_focus": "happy_click",
	"prayer_start": "happy_click",
	"prayer_complete": "happy_click",
	"gloria_appears": "group_present",
	"night_start": "game_start",
}
const _PRELOADED_SOUNDS := {}
var music_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_next_index: int = 0
var master_volume: float = 0.8
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var voice_volume: float = 0.8
var is_muted: bool = false
var current_music: AudioStream = null
var current_voice_stream: AudioStream = null
var latest_voice_sample_rate: int = DEFAULT_VOICE_SAMPLE_RATE
var latest_voice_pcm: PackedByteArray = PackedByteArray()
var sounds: Dictionary = { }
var sound_manifest: Dictionary = { }
signal voice_stream_started(sample_rate: int)
signal voice_stream_finished()
func _ready() -> void:
	_warm_export_preloads()
	music_player = AudioStreamPlayer.new()
	music_player.bus = _resolve_bus("Music", "Master")
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = _resolve_bus(VOICE_BUS_NAME, "SFX")
	voice_player.process_mode = Node.PROCESS_MODE_ALWAYS
	voice_player.finished.connect(_on_voice_finished)
	add_child(voice_player)
	for i in range(MAX_SFX_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.bus = _resolve_bus("SFX", "Master")
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		sfx_players.append(player)
	_load_sounds()
	sync_from_audio_server()
	update_volumes()
func _exit_tree() -> void:
	sounds.clear()
	sound_manifest.clear()
func _resolve_bus(preferred_bus: String, fallback_bus: String) -> String:
	return preferred_bus if AudioServer.get_bus_index(preferred_bus) != -1 else fallback_bus
func _load_sounds() -> void:
	var preloaded_count := sounds.size()
	for category in AUDIO_DIRECTORIES.keys():
		var directory_path: String = AUDIO_DIRECTORIES[category]
		_load_audio_directory(directory_path, category)
	_register_sound_aliases()
	var scanned_count := sounds.size() - preloaded_count
	if scanned_count > 0:
		print("[AudioManager] Discovered %d additional audio assets via directory scan." % scanned_count)
	print("[AudioManager] Total: %d audio assets ready." % sounds.size())
func _load_audio_directory(directory_path: String, category: String, prefix: String = "") -> void:
	var dir := DirAccess.open(directory_path)
	if dir == null:
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Audio directory not found: %s" % directory_path,
			{ "path": directory_path },
		)
		return
	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry == "":
			break
		if entry == "." or entry == "..":
			continue
		var entry_path := _join_path(directory_path, entry)
		if dir.current_is_dir():
			if entry.begins_with("."):
				continue
			var nested_prefix := entry if prefix.is_empty() else "%s/%s" % [prefix, entry]
			_load_audio_directory(entry_path, category, nested_prefix)
			continue
		if entry.begins_with(".") or not _is_supported_audio_file(entry):
			continue
		var sound_name := entry.get_basename()
		if not prefix.is_empty():
			sound_name = "%s/%s" % [prefix, sound_name]
		_register_sound(sound_name, entry_path, category)
	dir.list_dir_end()
func _register_sound(sound_name: String, resource_path: String, category: String) -> void:
	if not ResourceLoader.exists(resource_path):
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Audio asset missing at %s (key: %s)" % [resource_path, sound_name],
			{ "path": resource_path, "key": sound_name },
		)
		return
	var stream := ResourceLoader.load(resource_path)
	if stream == null or not (stream is AudioStream):
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Failed to load audio stream at %s (key: %s)" % [resource_path, sound_name],
			{ "path": resource_path, "key": sound_name },
		)
		return
	if sounds.has(sound_name):
		var previous: Dictionary = sound_manifest.get(sound_name, { })
		var previous_path: String = previous.get("path", "unknown")
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Duplicate audio key '%s'. Replacing asset %s with %s." % [sound_name, previous_path, resource_path],
			{ "key": sound_name, "previous": previous_path, "new": resource_path },
		)
	sounds[sound_name] = stream
	sound_manifest[sound_name] = {
		"path": resource_path,
		"category": category,
	}
func _register_sound_aliases() -> void:
	for alias in SFX_ALIASES.keys():
		var canonical: String = SFX_ALIASES[alias]
		if not sounds.has(canonical):
			ErrorReporterBridge.report_warning(
				ERROR_CONTEXT,
				"Alias '%s' references missing sound '%s'." % [alias, canonical],
				{ "alias": alias, "target": canonical },
			)
			continue
		sounds[alias] = sounds[canonical]
		var manifest_entry: Dictionary = sound_manifest.get(canonical, {}).duplicate()
		manifest_entry["alias_of"] = canonical
		sound_manifest[alias] = manifest_entry
func _is_supported_audio_file(file_name: String) -> bool:
	var extension := file_name.get_extension().to_lower()
	return SUPPORTED_AUDIO_EXTENSIONS.has(extension)
func _join_path(base_path: String, element: String) -> String:
	var sanitized_base := base_path
	if sanitized_base.ends_with("/"):
		sanitized_base = sanitized_base.substr(0, sanitized_base.length() - 1)
	var sanitized_element := element
	if sanitized_element.begins_with("/"):
		sanitized_element = sanitized_element.substr(1, sanitized_element.length() - 1)
	return "%s/%s" % [sanitized_base, sanitized_element]
func _warm_export_preloads() -> void:
	for sound_name in _PRELOADED_SOUNDS.keys():
		var stream: AudioStream = _PRELOADED_SOUNDS[sound_name]
		if stream == null:
			continue
		sounds[sound_name] = stream
		var category := "sfx"
		if sound_name == "background_music" or sound_name.ends_with("_music"):
			category = "music"
		sound_manifest[sound_name] = {
			"path": "preloaded",
			"category": category,
		}
	print("[AudioManager] Registered %d preloaded audio assets." % sounds.size())
func _apply_music_loop(stream: AudioStream, loop: bool) -> void:
	if stream == null:
		return
	if stream is AudioStreamWAV and stream.has_method("set_loop_mode"):
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	elif stream.has_method("set_loop"):
		stream.loop = loop
func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	if sfx_players.is_empty():
		return null
	var player: AudioStreamPlayer = sfx_players[sfx_next_index % sfx_players.size()]
	sfx_next_index = (sfx_next_index + 1) % sfx_players.size()
	return player
func play_music(music_name: String, loop: bool = true) -> void:
	if not sounds.has(music_name):
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Music track not found: %s" % music_name,
			{ "music_name": music_name },
		)
		return
	var stream: AudioStream = sounds[music_name]
	_apply_music_loop(stream, loop)
	var should_restart := current_music != stream or not music_player.playing
	current_music = stream
	music_player.stream = stream
	if should_restart:
		music_player.play()
func stop_music(fade_duration: float = 0.0) -> void:
	if music_player == null:
		current_music = null
		return
	if fade_duration > 0.0 and music_player.playing:
		var tween := create_tween()
		tween.tween_property(music_player, "volume_db", -80, fade_duration)
		await tween.finished
	music_player.stop()
	current_music = null
	update_volumes()
func play_sfx(sfx_name: String, volume_multiplier: float = 1.0) -> void:
	if not sounds.has(sfx_name):
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Sound effect not found: %s" % sfx_name,
			{ "sfx_name": sfx_name },
		)
		return
	if is_muted:
		return
	var player := _get_available_sfx_player()
	if player == null:
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"No SFX players available to play %s" % sfx_name,
			{ "sfx_name": sfx_name },
		)
		return
	player.stream = sounds[sfx_name]
	var safe_multiplier: float = max(volume_multiplier, 0.0)
	var sfx_idx = AudioServer.get_bus_index("SFX")
	var master_idx = AudioServer.get_bus_index("Master")
	if sfx_idx != -1:
		player.volume_db = linear_to_db(safe_multiplier)
	elif master_idx != -1:
		player.volume_db = linear_to_db(sfx_volume * safe_multiplier)
	else:
		player.volume_db = linear_to_db(sfx_volume * safe_multiplier * master_volume)
	player.play()
func update_volumes() -> void:
	if is_muted:
		if music_player:
			music_player.volume_db = -80
		if voice_player:
			voice_player.volume_db = -80
		for player in sfx_players:
			player.volume_db = -80
		return
	if music_player:
		if AudioServer.get_bus_index("Music") != -1:
			music_player.volume_db = 0.0
		else:
			music_player.volume_db = linear_to_db(music_volume * master_volume)
	if voice_player:
		if AudioServer.get_bus_index(VOICE_BUS_NAME) != -1:
			voice_player.volume_db = 0.0
		else:
			voice_player.volume_db = linear_to_db(voice_volume * master_volume)
	var sfx_bus_exists = AudioServer.get_bus_index("SFX") != -1
	for player in sfx_players:
		if sfx_bus_exists:
			player.volume_db = 0.0
		else:
			player.volume_db = linear_to_db(sfx_volume * master_volume)
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume))
	update_volumes()
func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx != -1:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume))
	else:
		if music_player:
			music_player.volume_db = linear_to_db(music_volume * master_volume)
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(sfx_volume))
	else:
		update_volumes() 
func set_voice_volume(volume: float) -> void:
	voice_volume = clamp(volume, 0.0, 1.0)
	var voice_idx = AudioServer.get_bus_index(VOICE_BUS_NAME)
	if voice_idx != -1:
		AudioServer.set_bus_volume_db(voice_idx, linear_to_db(voice_volume))
	if voice_player:
		voice_player.volume_db = linear_to_db(voice_volume * master_volume)
func is_music_playing() -> bool:
	return music_player != null and music_player.playing
func get_current_music() -> String:
	for key in sounds.keys():
		if sounds[key] == current_music:
			return key
	return ""
func set_muted(muted: bool) -> void:
	is_muted = muted
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		AudioServer.set_bus_mute(master_idx, muted)
	var voice_idx = AudioServer.get_bus_index(VOICE_BUS_NAME)
	if voice_idx != -1:
		AudioServer.set_bus_mute(voice_idx, muted)
	update_volumes()
func sync_from_audio_server() -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		is_muted = AudioServer.is_bus_mute(master_idx)
		if not is_muted:
			master_volume = clamp(db_to_linear(AudioServer.get_bus_volume_db(master_idx)), 0.0, 1.0)
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx != -1:
		music_volume = clamp(db_to_linear(AudioServer.get_bus_volume_db(music_idx)), 0.0, 1.0)
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		sfx_volume = clamp(db_to_linear(AudioServer.get_bus_volume_db(sfx_idx)), 0.0, 1.0)
	var voice_idx = AudioServer.get_bus_index(VOICE_BUS_NAME)
	if voice_idx != -1 and not is_muted:
		voice_volume = clamp(db_to_linear(AudioServer.get_bus_volume_db(voice_idx)), 0.0, 1.0)
func get_volume_settings() -> Dictionary:
	sync_from_audio_server()
	return {
		"master_volume": master_volume * 100.0,
		"music_volume": music_volume * 100.0,
		"sfx_volume": sfx_volume * 100.0,
		"voice_volume": voice_volume * 100.0,
		"muted": is_muted,
	}
func apply_volume_settings(settings: Dictionary) -> void:
	var master_percent = float(settings.get("master_volume", master_volume * 100.0))
	var music_percent = float(settings.get("music_volume", music_volume * 100.0))
	var sfx_percent = float(settings.get("sfx_volume", sfx_volume * 100.0))
	var voice_percent = float(settings.get("voice_volume", voice_volume * 100.0))
	var muted = bool(settings.get("muted", is_muted))
	master_volume = clamp(master_percent / 100.0, 0.0, 1.0)
	music_volume = clamp(music_percent / 100.0, 0.0, 1.0)
	sfx_volume = clamp(sfx_percent / 100.0, 0.0, 1.0)
	voice_volume = clamp(voice_percent / 100.0, 0.0, 1.0)
	is_muted = muted
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		AudioServer.set_bus_mute(master_idx, muted)
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume))
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx != -1:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume))
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(sfx_volume))
	var voice_idx = AudioServer.get_bus_index(VOICE_BUS_NAME)
	if voice_idx != -1:
		AudioServer.set_bus_mute(voice_idx, muted)
		AudioServer.set_bus_volume_db(voice_idx, linear_to_db(voice_volume))
	update_volumes()
func play_voice_stream(stream: AudioStream) -> void:
	if voice_player == null or stream == null:
		return
	current_voice_stream = stream
	if stream is AudioStreamWAV:
		var sample := stream as AudioStreamWAV
		latest_voice_sample_rate = sample.mix_rate
		latest_voice_pcm = sample.data
	else:
		latest_voice_sample_rate = DEFAULT_VOICE_SAMPLE_RATE
		latest_voice_pcm = PackedByteArray()
	voice_player.stream = stream
	if is_muted:
		voice_player.volume_db = -80
	else:
		voice_player.volume_db = linear_to_db(voice_volume * master_volume)
	voice_player.play()
	voice_stream_started.emit(latest_voice_sample_rate)
func play_voice_from_pcm(pcm_buffer: PackedByteArray, sample_rate: int = DEFAULT_VOICE_SAMPLE_RATE, stereo: bool = false) -> void:
	if pcm_buffer.is_empty():
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Received empty PCM buffer for voice playback",
		)
		return
	var sample := AudioStreamWAV.new()
	sample.format = 16
	sample.stereo = stereo
	sample.mix_rate = sample_rate
	sample.data = pcm_buffer
	sample.loop_mode = AudioStreamWAV.LOOP_DISABLED
	latest_voice_sample_rate = sample_rate
	latest_voice_pcm = pcm_buffer
	play_voice_stream(sample)
func play_voice_from_base64(encoded: String, sample_rate: int = DEFAULT_VOICE_SAMPLE_RATE, stereo: bool = false) -> void:
	if encoded.is_empty():
		ErrorReporterBridge.report_warning(
			ERROR_CONTEXT,
			"Empty base64 voice payload",
		)
		return
	var raw := Marshalls.base64_to_raw(encoded)
	play_voice_from_pcm(raw, sample_rate, stereo)
func stop_voice(fade_duration: float = 0.0) -> void:
	if voice_player == null:
		return
	if fade_duration > 0.0 and voice_player.playing:
		var tween := create_tween()
		tween.tween_property(voice_player, "volume_db", -80, fade_duration)
		await tween.finished
	voice_player.stop()
	if is_muted:
		voice_player.volume_db = -80
	else:
		voice_player.volume_db = linear_to_db(voice_volume * master_volume)
	_on_voice_finished()
func is_voice_playing() -> bool:
	return voice_player != null and voice_player.playing
func get_last_voice_snapshot() -> Dictionary:
	return {
		"pcm": latest_voice_pcm.duplicate(),
		"sample_rate": latest_voice_sample_rate,
		"stream": current_voice_stream,
	}
func _on_music_finished() -> void:
	current_music = null
func _on_voice_finished() -> void:
	if current_voice_stream == null:
		return
	current_voice_stream = null
	voice_stream_finished.emit()
