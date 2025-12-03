extends RefCounted
class_name AIRequestQueue
var _entries: Array[Dictionary] = []
var _debug_delegate: Callable = Callable()
func configure(debug_delegate: Callable) -> void:
	_debug_delegate = debug_delegate
	_entries.clear()
func enqueue(prompt: String, callback: Callable, context: Dictionary, force_mock: bool, provider_label: String) -> void:
	var entry: Dictionary = {
		"prompt": prompt,
		"callback": callback,
		"context": context.duplicate(true),
		"force_mock": force_mock,
	}
	_entries.append(entry)
	_emit_debug(
		"request_queued",
		{
			"provider": provider_label,
			"queue_size": _entries.size(),
			"prompt_chars": prompt.length(),
		},
	)
func is_empty() -> bool:
	return _entries.is_empty()
func size() -> int:
	return _entries.size()
func take_next(provider_label: String) -> Dictionary:
	if _entries.is_empty():
		return { }
	var next_entry: Dictionary = _entries.pop_front()
	_emit_debug(
		"request_dequeued",
		{
			"provider": provider_label,
			"queue_size": _entries.size(),
		},
	)
	return next_entry
func clear() -> void:
	_entries.clear()
func _emit_debug(stage: String, payload: Dictionary) -> void:
	if _debug_delegate.is_null():
		return
	_debug_delegate.call(stage, payload)
