extends RefCounted
class_name AIRequestRateLimiter
var min_interval_msec: int = 1500
var max_requests_per_minute: int = 10
var cooldown_msec: int = 5000
var _request_timestamps: Array[int] = []
var _blocked_until_msec: int = 0
func configure(min_interval: int, max_per_minute: int, cooldown: int) -> void:
	min_interval_msec = max(0, min_interval)
	max_requests_per_minute = max(1, max_per_minute)
	cooldown_msec = max(0, cooldown)
	reset()
func reset() -> void:
	_request_timestamps.clear()
	_blocked_until_msec = 0
func attempt() -> Dictionary:
	var now_msec: int = Time.get_ticks_msec()
	_prune(now_msec)
	if now_msec < _blocked_until_msec:
		return {
			"allowed": false,
			"retry_after_msec": max(0, _blocked_until_msec - now_msec),
		}
	if _request_timestamps.size() > 0:
		var diff: int = now_msec - _request_timestamps.back()
		if diff < min_interval_msec:
			_blocked_until_msec = now_msec + cooldown_msec
			return {
				"allowed": false,
				"retry_after_msec": max(0, min_interval_msec - diff),
			}
	if _request_timestamps.size() >= max_requests_per_minute:
		_blocked_until_msec = now_msec + cooldown_msec
		return {
			"allowed": false,
			"retry_after_msec": max(0, cooldown_msec),
		}
	_request_timestamps.append(now_msec)
	return {
		"allowed": true,
	}
func _prune(current_msec: int) -> void:
	var cutoff: int = current_msec - 60000
	var filtered: Array[int] = []
	for stamp in _request_timestamps:
		if stamp >= cutoff:
			filtered.append(stamp)
	_request_timestamps = filtered
