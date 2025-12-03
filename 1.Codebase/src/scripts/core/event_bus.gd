extends Node
var _event_registry: Dictionary = { }
const ERROR_CONTEXT := "EventBus"
var _event_history: Array = []
const MAX_HISTORY_SIZE := 100
var _event_stats: Dictionary = { }
func subscribe(event_name: String, target: Object, method: String) -> void:
	if not event_name or not target or not method:
		ErrorReporterBridge.report_error(ERROR_CONTEXT, "Invalid subscription parameters")
		return
	if not target.has_method(method):
		ErrorReporterBridge.report_error(
			ERROR_CONTEXT,
			"Method '%s' not found on target %s" % [method, target],
			ErrorCodes.General.INVALID_PARAMETER,
			false,
			{ "method": method, "target": str(target) },
		)
		return
	if not _event_registry.has(event_name):
		_event_registry[event_name] = []
	for entry in _event_registry[event_name]:
		if entry["target"] == target and entry["method"] == method:
			return 
	_event_registry[event_name].append(
		{
			"target": target,
			"method": method,
		},
	)
func unsubscribe(event_name: String, target: Object, method: String = "") -> void:
	if not _event_registry.has(event_name):
		return
	var subscribers: Array = _event_registry[event_name]
	var to_remove: Array = []
	for i in range(subscribers.size()):
		var entry = subscribers[i]
		if entry["target"] == target:
			if method.is_empty() or entry["method"] == method:
				to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		subscribers.remove_at(idx)
	if subscribers.is_empty():
		_event_registry.erase(event_name)
func unsubscribe_all(target: Object) -> void:
	for event_name in _event_registry.keys():
		unsubscribe(event_name, target)
func publish(event_name: String, data: Variant = null) -> void:
	if not event_name:
		ErrorReporterBridge.report_error(ERROR_CONTEXT, "Cannot publish event with empty name")
		return
	_record_event(event_name, data)
	_increment_stat(event_name)
	if not _event_registry.has(event_name):
		return 
	var live_registry: Array = _event_registry[event_name]
	if live_registry.is_empty():
		return
	var subscriber_snapshot: Array = live_registry.duplicate()
	var dead_subscribers: Array = []
	for entry in subscriber_snapshot:
		var target = entry["target"]
		var method = entry["method"]
		if not is_instance_valid(target):
			dead_subscribers.append(entry)
			continue
		if not target.has_method(method):
			ErrorReporterBridge.report_warning(
				ERROR_CONTEXT,
				"Subscriber missing method '%s'" % method,
				{
					"event": event_name,
					"target": str(target),
				},
			)
			dead_subscribers.append(entry)
			continue
		if data != null:
			target.call(method, data)
		else:
			target.call(method)
	if not dead_subscribers.is_empty() and _event_registry.has(event_name):
		var current_registry: Array = _event_registry[event_name]
		for dead in dead_subscribers:
			current_registry.erase(dead)
		if current_registry.is_empty():
			_event_registry.erase(event_name)
func request(event_name: String, data: Variant = null) -> Variant:
	if not _event_registry.has(event_name):
		return null
	var live_registry: Array = _event_registry[event_name]
	if live_registry.is_empty():
		return null
	var subscriber_snapshot: Array = live_registry.duplicate()
	var dead_subscribers: Array = []
	for entry in subscriber_snapshot:
		var target = entry["target"]
		var method = entry["method"]
		if not is_instance_valid(target):
			dead_subscribers.append(entry)
			continue
		if not target.has_method(method):
			ErrorReporterBridge.report_warning(
				ERROR_CONTEXT,
				"Subscriber missing method '%s' during request" % method,
				{
					"event": event_name,
					"target": str(target),
				},
			)
			dead_subscribers.append(entry)
			continue
		var response: Variant = null
		if data != null:
			response = target.call(method, data)
		else:
			response = target.call(method)
		if response != null:
			if not dead_subscribers.is_empty() and _event_registry.has(event_name):
				var current_registry: Array = _event_registry[event_name]
				for dead in dead_subscribers:
					current_registry.erase(dead)
				if current_registry.is_empty():
					_event_registry.erase(event_name)
			return response
	if not dead_subscribers.is_empty() and _event_registry.has(event_name):
		var current_registry: Array = _event_registry[event_name]
		for dead in dead_subscribers:
			current_registry.erase(dead)
		if current_registry.is_empty():
			_event_registry.erase(event_name)
	return null
func get_subscribers(event_name: String) -> Array:
	if _event_registry.has(event_name):
		return _event_registry[event_name].duplicate()
	return []
func get_registered_events() -> Array:
	return _event_registry.keys()
func get_event_stats() -> Dictionary:
	return _event_stats.duplicate()
func get_event_history(limit: int = 20) -> Array:
	var clamped_limit: int = clampi(limit, 0, _event_history.size())
	if clamped_limit == 0:
		return []
	var start_index: int = _event_history.size() - clamped_limit
	return _event_history.slice(start_index, _event_history.size())
func clear_history() -> void:
	_event_history.clear()
func clear_stats() -> void:
	_event_stats.clear()
func reset() -> void:
	_event_registry.clear()
	clear_history()
	clear_stats()
func debug_print() -> void:
	print("\n===== EventBus Debug Info =====")
	print("Registered events: %d" % _event_registry.size())
	for event_name in _event_registry.keys():
		var subscribers = _event_registry[event_name]
		print("  %s: %d subscribers" % [event_name, subscribers.size()])
		for entry in subscribers:
			var target_name = entry["target"].get_class() if is_instance_valid(entry["target"]) else "INVALID"
			print("    - %s.%s()" % [target_name, entry["method"]])
	print("\nEvent stats (top 10):")
	var sorted_stats: Array = _event_stats.keys()
	sorted_stats.sort_custom(func(a, b): return _event_stats[a] > _event_stats[b])
	var entries: int = min(10, sorted_stats.size())
	for i in range(entries):
		var event_name: String = sorted_stats[i]
		print("  %s: %d calls" % [event_name, _event_stats[event_name]])
	print("===============================\n")
func _record_event(event_name: String, data: Variant) -> void:
	_event_history.append(
		{
			"event": event_name,
			"data": data,
			"timestamp": Time.get_ticks_msec(),
		},
	)
	if _event_history.size() > MAX_HISTORY_SIZE:
		_event_history.pop_front()
func _increment_stat(event_name: String) -> void:
	if not _event_stats.has(event_name):
		_event_stats[event_name] = 0
	_event_stats[event_name] += 1
func _ready() -> void:
	print("[EventBus] Initialized")
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		reset()
