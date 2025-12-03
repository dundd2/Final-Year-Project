extends RefCounted
class_name SessionSubsystemRegistry
class SubsystemConfig:
	var key: String
	var capture: Callable
	var restore: Callable
	var default_value: Variant
	var flatten_keys: Array[String]
	func _init(p_key: String, p_capture: Callable, p_restore: Callable, p_default_value: Variant, p_flatten_keys: Array[String]):
		key = p_key
		capture = p_capture
		restore = p_restore
		default_value = p_default_value
		flatten_keys = p_flatten_keys
var _entries: Array[SubsystemConfig] = []
var _entry_map: Dictionary = { }
func register_subsystem(
	key: String,
	capture_callable: Callable,
	restore_callable: Callable,
	default_value = null,
	options: Dictionary = { }
) -> void:
	var flatten_keys: Array[String] = []
	if options.has("flatten_keys"):
		var provided = options["flatten_keys"]
		if provided is Array:
			for value in provided:
				flatten_keys.append(str(value))
		elif provided is PackedStringArray:
			flatten_keys = provided.duplicate()
	var config := SubsystemConfig.new(key, capture_callable, restore_callable, default_value, flatten_keys)
	_entry_map[key] = config
	_entries.append(config)
func capture_all() -> Dictionary:
	var snapshot: Dictionary = { }
	for config in _entries:
		if config.capture.is_null():
			continue
		var value = config.capture.call()
		if config.flatten_keys.is_empty():
			snapshot[config.key] = value
		else:
			var dict_value: Dictionary = value if value is Dictionary else { }
			for flatten_key in config.flatten_keys:
				snapshot[flatten_key] = dict_value.get(flatten_key, _get_default_for_key(config, flatten_key))
	return snapshot
func restore_all(data: Dictionary) -> void:
	for config in _entries:
		if config.restore.is_null():
			continue
		var payload = null
		if config.flatten_keys.is_empty():
			payload = data.get(config.key, config.default_value)
		else:
			payload = { }
			for flatten_key in config.flatten_keys:
				var fallback = _get_default_for_key(config, flatten_key)
				payload[flatten_key] = data.get(flatten_key, fallback)
		config.restore.call(payload)
func has_subsystem(key: String) -> bool:
	return _entry_map.has(key)
func clear() -> void:
	_entries.clear()
	_entry_map.clear()
func _get_default_for_key(config: SubsystemConfig, flatten_key: String) -> Variant:
	if config.default_value is Dictionary:
		return config.default_value.get(flatten_key)
	return null
