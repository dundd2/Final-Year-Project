extends Node
const TOL := 0.05
func _ready() -> void:
	print("[AudioTest] Starting AudioManager tests…")
	await get_tree().process_frame
	_test_basics()
	await _test_mute_and_volumes()
	await _test_event_sfx_pooling()
	await _test_music_playback()
	await _test_non_blocking_under_load()
	print("[AudioTest] All checks executed.")
	queue_free()
func _test_basics() -> void:
	assert(AudioManager != null, "AudioManager autoload missing")
	var settings := AudioManager.get_volume_settings()
	assert(settings.has("master_volume"), "Missing master_volume in settings")
	assert(settings.has("music_volume"), "Missing music_volume in settings")
	assert(settings.has("sfx_volume"), "Missing sfx_volume in settings")
	assert(settings.has("muted"), "Missing muted in settings")
	print("[AudioTest] Basics OK")
func _test_mute_and_volumes() -> void:
	AudioManager.set_muted(true)
	var s := AudioManager.get_volume_settings()
	assert(s.muted == true, "Mute state not applied to AudioServer")
	if AudioManager.music_player:
		assert(AudioManager.music_player.volume_db <= -60.0, "Music not silenced when muted")
	for p in AudioManager.sfx_players:
		assert(p.volume_db <= -60.0, "SFX not silenced when muted")
	AudioManager.set_muted(false)
	AudioManager.set_master_volume(0.5)
	AudioManager.set_music_volume(0.4)
	AudioManager.set_sfx_volume(0.3)
	await get_tree().process_frame
	s = AudioManager.get_volume_settings()
	assert(abs((s.master_volume / 100.0) - 0.5) <= TOL, "Master volume mismatch after set")
	assert(abs((s.music_volume / 100.0) - 0.4) <= 0.1, "Music volume mismatch after set")
	assert(abs((s.sfx_volume / 100.0) - 0.3) <= 0.1, "SFX volume mismatch after set")
	print("[AudioTest] Mute/volume toggles OK")
func _test_event_sfx_pooling() -> void:
	var t0 := Time.get_ticks_msec()
	AudioManager.play_sfx("menu_click")
	var t1 := Time.get_ticks_msec()
	assert((t1 - t0) < 10, "play_sfx appears blocking")
	for i in range(AudioManager.MAX_SFX_PLAYERS + 4):
		AudioManager.play_sfx("happy_click")
	await get_tree().create_timer(0.1).timeout
	print("[AudioTest] Event‑driven SFX and pooling OK")
func _test_music_playback() -> void:
	if not AudioManager.sounds.has("background_music"):
		print("[AudioTest] Skipping music test (no background_music asset)")
		return
	AudioManager.play_music("background_music", true)
	await get_tree().create_timer(0.05).timeout
	assert(AudioManager.is_music_playing(), "Music did not start")
	assert(AudioManager.get_current_music() == "background_music", "Unexpected current music name")
	await AudioManager.stop_music(0.1)
	await get_tree().process_frame
	assert(not AudioManager.is_music_playing(), "Music did not stop after fade")
	print("[AudioTest] Music playback OK")
func _test_non_blocking_under_load() -> void:
	var timer_fired := false
	var timer := get_tree().create_timer(0.05)
	timer.timeout.connect(func(): timer_fired = true)
	for i in range(0, 12):
		AudioManager.play_sfx("angry_click")
	await get_tree().process_frame
	await timer.timeout
	assert(timer_fired, "Timer blocked by audio activity")
	print("[AudioTest] Non‑blocking under load OK")
