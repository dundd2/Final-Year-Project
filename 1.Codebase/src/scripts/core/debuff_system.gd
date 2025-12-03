extends RefCounted
var active_debuffs: Array = []
var cognitive_dissonance_active: bool = false
var cognitive_dissonance_choices_left: int = 0
func add_debuff(debuff_name: String, duration: int, effect: String) -> void:
	active_debuffs.append(
		{
			"name": debuff_name,
			"duration": duration,
			"effect": effect,
		},
	)
	if debuff_name == GameConstants.Debuffs.COGNITIVE_DISSONANCE_NAME:
		cognitive_dissonance_active = true
		cognitive_dissonance_choices_left = duration
func process_debuffs() -> void:
	var to_remove = []
	for i in range(active_debuffs.size()):
		active_debuffs[i]["duration"] -= 1
		if active_debuffs[i]["duration"] <= 0:
			to_remove.append(i)
	for i in range(to_remove.size() - 1, -1, -1):
		var debuff = active_debuffs[to_remove[i]]
		if debuff["name"] == GameConstants.Debuffs.COGNITIVE_DISSONANCE_NAME:
			cognitive_dissonance_active = false
		active_debuffs.remove_at(to_remove[i])
func use_cognitive_dissonance_choice() -> void:
	if cognitive_dissonance_active:
		cognitive_dissonance_choices_left -= 1
		if cognitive_dissonance_choices_left <= 0:
			cognitive_dissonance_active = false
func has_debuff(debuff_name: String) -> bool:
	for debuff in active_debuffs:
		if debuff["name"] == debuff_name:
			return true
	return false
func get_active_debuffs() -> Array:
	return active_debuffs.duplicate()
func get_debuff(debuff_name: String) -> Dictionary:
	for debuff in active_debuffs:
		if debuff["name"] == debuff_name:
			return debuff.duplicate()
	return { }
func clear_all() -> void:
	active_debuffs.clear()
	cognitive_dissonance_active = false
	cognitive_dissonance_choices_left = 0
func get_save_data() -> Dictionary:
	return {
		"active_debuffs": active_debuffs.duplicate(true),
		"cognitive_dissonance_active": cognitive_dissonance_active,
		"cognitive_dissonance_choices_left": cognitive_dissonance_choices_left,
	}
func load_save_data(data: Dictionary) -> void:
	var debuffs_data = data.get("active_debuffs", [])
	active_debuffs = debuffs_data.duplicate(true) if debuffs_data is Array else []
	cognitive_dissonance_active = data.get("cognitive_dissonance_active", false)
	cognitive_dissonance_choices_left = data.get("cognitive_dissonance_choices_left", 0)
func reset() -> void:
	clear_all()
