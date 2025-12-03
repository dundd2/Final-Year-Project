extends Node
var assets: Dictionary = {
	"Generic_Lever": {
		"id": "Generic_Lever",
		"default_name": "Standard Lever",
		"tags": ["Interactable", "Mechanical", "Quest_Item"],
		"summary": "A sturdy lever that can toggle machinery or open hidden passages.",
		"icon": "res://1.Codebase/src/assets/icons/lever.png",
		"scene": null,
	},
	"Generic_Button": {
		"id": "Generic_Button",
		"default_name": "Pressure Plate",
		"tags": ["Interactable", "Mechanical", "Puzzle"],
		"summary": "A button or pressure plate waiting to activate something important or catastrophic.",
		"icon": "res://1.Codebase/src/assets/icons/button.png",
		"scene": null,
	},
	"Generic_Door": {
		"id": "Generic_Door",
		"default_name": "Sealed Portal",
		"tags": ["Interactable", "Structure", "Barrier"],
		"summary": "A door that stands between you and progress, probably locked by incompetence.",
		"icon": "res://1.Codebase/src/assets/icons/door.png",
		"scene": null,
	},
	"Generic_Chest": {
		"id": "Generic_Chest",
		"default_name": "Mystery Container",
		"tags": ["Interactable", "Loot", "Quest_Item"],
		"summary": "A chest containing either salvation or another procedural nightmare.",
		"icon": "res://1.Codebase/src/assets/icons/chest.png",
		"scene": null,
	},
	"Generic_Key": {
		"id": "Generic_Key",
		"default_name": "Symbolic Key",
		"tags": ["Item", "Quest_Item", "Tool"],
		"summary": "A key that unlocks doors, metaphors, or team dysfunction.",
		"icon": "res://1.Codebase/src/assets/icons/key.png",
		"scene": null,
	},
	"Generic_Altar": {
		"id": "Generic_Altar",
		"default_name": "Ancestral Altar",
		"tags": ["Structure", "Mystic", "Lore"],
		"summary": "A ritual platform hungry for offerings, prayers, or sarcasm.",
		"icon": "res://1.Codebase/src/assets/icons/altar.png",
		"scene": null,
	},
	"Generic_Statue": {
		"id": "Generic_Statue",
		"default_name": "Ancient Statue",
		"tags": ["Structure", "Lore", "Environment"],
		"summary": "A weathered monument to forgotten heroes or marketing campaigns.",
		"icon": "res://1.Codebase/src/assets/icons/statue.png",
		"scene": null,
	},
	"Generic_Pillar": {
		"id": "Generic_Pillar",
		"default_name": "Supporting Column",
		"tags": ["Structure", "Environment", "Puzzle"],
		"summary": "A pillar holding up the ceiling and the weight of poor decisions.",
		"icon": "res://1.Codebase/src/assets/icons/pillar.png",
		"scene": null,
	},
	"Generic_Bridge": {
		"id": "Generic_Bridge",
		"default_name": "Rickety Crossing",
		"tags": ["Structure", "Environment", "Hazard"],
		"summary": "A bridge that definitely won't collapse at a dramatic moment.",
		"icon": "res://1.Codebase/src/assets/icons/bridge.png",
		"scene": null,
	},
	"Generic_Monster": {
		"id": "Generic_Monster",
		"default_name": "Symbolic Beast",
		"tags": ["Creature", "Threat", "Dynamic"],
		"summary": "A shapeless menace waiting for an identity and a reason to ruin plans.",
		"icon": "res://1.Codebase/src/assets/icons/beast.png",
		"scene": null,
	},
	"Generic_NPC": {
		"id": "Generic_NPC",
		"default_name": "Wandering Soul",
		"tags": ["NPC", "Dialogue", "Quest"],
		"summary": "A person with problems that will somehow become your problems.",
		"icon": "res://1.Codebase/src/assets/icons/npc.png",
		"scene": null,
	},
	"Generic_Guardian": {
		"id": "Generic_Guardian",
		"default_name": "Sentinel Entity",
		"tags": ["Creature", "Obstacle", "Challenge"],
		"summary": "A guardian protecting something important through rigid rules or violence.",
		"icon": "res://1.Codebase/src/assets/icons/guardian.png",
		"scene": null,
	},
	"Generic_Spirit": {
		"id": "Generic_Spirit",
		"default_name": "Ethereal Presence",
		"tags": ["Entity", "Mystic", "Dialogue"],
		"summary": "A ghostly being offering cryptic wisdom or emotional manipulation.",
		"icon": "res://1.Codebase/src/assets/icons/spirit.png",
		"scene": null,
	},
	"Glowing_Plant": {
		"id": "Glowing_Plant",
		"default_name": "Luminescent Flora",
		"tags": ["Resource", "Environment", "Organic"],
		"summary": "Bioluminescent vegetation that reacts to mood swings and entropy spikes.",
		"icon": "res://1.Codebase/src/assets/icons/plant.png",
		"scene": null,
	},
	"Generic_Tree": {
		"id": "Generic_Tree",
		"default_name": "Ancient Tree",
		"tags": ["Environment", "Organic", "Lore"],
		"summary": "A tree that has witnessed countless failures and grown stronger from them.",
		"icon": "res://1.Codebase/src/assets/icons/tree.png",
		"scene": null,
	},
	"Generic_Rock": {
		"id": "Generic_Rock",
		"default_name": "Weathered Boulder",
		"tags": ["Environment", "Obstacle", "Resource"],
		"summary": "A rock. It's been here longer than your problems and will outlast them too.",
		"icon": "res://1.Codebase/src/assets/icons/rock.png",
		"scene": null,
	},
	"Generic_Water": {
		"id": "Generic_Water",
		"default_name": "Still Waters",
		"tags": ["Environment", "Hazard", "Resource"],
		"summary": "A body of water that reflects failures with uncomfortable clarity.",
		"icon": "res://1.Codebase/src/assets/icons/water.png",
		"scene": null,
	},
	"Generic_Fire": {
		"id": "Generic_Fire",
		"default_name": "Eternal Flame",
		"tags": ["Environment", "Hazard", "Mystic"],
		"summary": "A fire burning with the intensity of Gloria's positive energy.",
		"icon": "res://1.Codebase/src/assets/icons/fire.png",
		"scene": null,
	},
	"Arcane_Device": {
		"id": "Arcane_Device",
		"default_name": "Arcane Interface",
		"tags": ["Interactable", "Mystic", "Technology"],
		"summary": "A glowing console mixing ancient runes with broken UI guidelines.",
		"icon": "res://1.Codebase/src/assets/icons/device.png",
		"scene": null,
	},
	"Generic_Crystal": {
		"id": "Generic_Crystal",
		"default_name": "Energy Crystal",
		"tags": ["Resource", "Mystic", "Quest_Item"],
		"summary": "A crystal pulsing with power or just good marketing.",
		"icon": "res://1.Codebase/src/assets/icons/crystal.png",
		"scene": null,
	},
	"Generic_Scroll": {
		"id": "Generic_Scroll",
		"default_name": "Ancient Scroll",
		"tags": ["Item", "Lore", "Quest_Item"],
		"summary": "A document containing wisdom, prophecy, or expired warranty information.",
		"icon": "res://1.Codebase/src/assets/icons/scroll.png",
		"scene": null,
	},
	"Generic_Portal": {
		"id": "Generic_Portal",
		"default_name": "Dimensional Rift",
		"tags": ["Structure", "Mystic", "Travel"],
		"summary": "A gateway to somewhere else, probably worse than here.",
		"icon": "res://1.Codebase/src/assets/icons/portal.png",
		"scene": null,
	},
	"Generic_Orb": {
		"id": "Generic_Orb",
		"default_name": "Floating Orb",
		"tags": ["Item", "Mystic", "Dynamic"],
		"summary": "A mysterious sphere that hovers ominously while judging your life choices.",
		"icon": "res://1.Codebase/src/assets/icons/orb.png",
		"scene": null,
	},
	"Rest_Spot": {
		"id": "Rest_Spot",
		"default_name": "Makeshift Camp",
		"tags": ["Safe", "Narrative", "Recovery"],
		"summary": "A temporary haven that never truly feels safe, but slows the doom spiral.",
		"icon": "res://1.Codebase/src/assets/icons/camp.png",
		"scene": null,
	},
	"Generic_Campfire": {
		"id": "Generic_Campfire",
		"default_name": "Resting Fire",
		"tags": ["Safe", "Environment", "Recovery"],
		"summary": "A campfire where you can rest and contemplate your teammates' incompetence.",
		"icon": "res://1.Codebase/src/assets/icons/campfire.png",
		"scene": null,
	},
	"Generic_Shelter": {
		"id": "Generic_Shelter",
		"default_name": "Abandoned Shelter",
		"tags": ["Safe", "Structure", "Narrative"],
		"summary": "A shelter abandoned by people who were probably smarter than you.",
		"icon": "res://1.Codebase/src/assets/icons/shelter.png",
		"scene": null,
	},
	"Generic_Trap": {
		"id": "Generic_Trap",
		"default_name": "Hidden Trap",
		"tags": ["Hazard", "Interactable", "Puzzle"],
		"summary": "A trap waiting to be triggered by the most confident team member.",
		"icon": "res://1.Codebase/src/assets/icons/trap.png",
		"scene": null,
	},
	"Generic_Abyss": {
		"id": "Generic_Abyss",
		"default_name": "Bottomless Pit",
		"tags": ["Hazard", "Environment", "Obstacle"],
		"summary": "A void that mirrors the emptiness you feel after each team meeting.",
		"icon": "res://1.Codebase/src/assets/icons/abyss.png",
		"scene": null,
	},
	"Generic_Wall": {
		"id": "Generic_Wall",
		"default_name": "Imposing Barrier",
		"tags": ["Obstacle", "Structure", "Puzzle"],
		"summary": "A wall blocking progress, much like your teammates' understanding of teamwork.",
		"icon": "res://1.Codebase/src/assets/icons/wall.png",
		"scene": null,
	},
}
var default_cycle := [
	"Generic_Lever",
	"Generic_Altar",
	"Generic_Monster",
	"Glowing_Plant",
	"Arcane_Device",
	"Rest_Spot",
]
var exploration_cycle := [
	"Generic_Door",
	"Generic_Chest",
	"Generic_Key",
	"Generic_Statue",
	"Generic_NPC",
	"Generic_Trap",
]
var combat_cycle := [
	"Generic_Monster",
	"Generic_Guardian",
	"Generic_Spirit",
	"Arcane_Device",
	"Generic_Pillar",
	"Generic_Fire",
]
var puzzle_cycle := [
	"Generic_Lever",
	"Generic_Button",
	"Arcane_Device",
	"Generic_Crystal",
	"Generic_Orb",
	"Generic_Pillar",
]
var narrative_cycle := [
	"Rest_Spot",
	"Generic_NPC",
	"Generic_Spirit",
	"Generic_Altar",
	"Generic_Scroll",
	"Generic_Campfire",
]
var context_cycles := {
	"default": default_cycle,
	"exploration": exploration_cycle,
	"combat": combat_cycle,
	"puzzle": puzzle_cycle,
	"narrative": narrative_cycle,
}
func _get_cycle_for_context_type(context_type: String) -> Array:
	var normalized := context_type.strip_edges().to_lower()
	if normalized.ends_with("_cycle"):
		normalized = normalized.substr(0, normalized.length() - 6)
	return context_cycles.get(normalized, default_cycle)
func get_asset_ids() -> Array:
	return Array(assets.keys())
func get_asset(asset_id: String) -> Dictionary:
	return assets.get(asset_id, { })
func get_assets_by_tags(required_tags: Array) -> Array:
	var matching := []
	for asset_id in assets.keys():
		var asset = assets[asset_id]
		var asset_tags: Array = asset.get("tags", [])
		var has_all_tags := true
		for tag in required_tags:
			if not tag in asset_tags:
				has_all_tags = false
				break
		if has_all_tags:
			matching.append(asset.duplicate(true))
	return matching
func get_assets_for_context(context: Dictionary) -> Array:
	var selected: Array = []
	if context.has("asset_ids") and context["asset_ids"] is Array:
		for asset_id in context["asset_ids"]:
			var data = get_asset(str(asset_id))
			if data:
				selected.append(data.duplicate(true))
	elif context.has("context_type"):
		var cycle = _get_cycle_for_context_type(str(context["context_type"]))
		for asset_id in cycle:
			var data = get_asset(asset_id)
			if data:
				selected.append(data.duplicate(true))
	elif context.has("required_tags"):
		selected = get_assets_by_tags(context["required_tags"])
	if selected.is_empty():
		for asset_id in default_cycle:
			var data = get_asset(asset_id)
			if data:
				selected.append(data.duplicate(true))
	return selected
func format_assets_for_prompt(asset_list: Array) -> String:
	if asset_list.is_empty():
		return "No symbolic assets have been defined."
	var lines: Array = []
	lines.append("場景中的可用資產 / Assets available in this scene:")
	lines.append("(ID | 建議名稱 / Suggested Name | 標籤 / Tags)")
	lines.append("")
	for asset in asset_list:
		var id = asset.get("id", "Unknown")
		var name = asset.get("default_name", id.capitalize())
		var tags: Array = asset.get("tags", [])
		var summary = asset.get("summary", "")
		lines.append("• %s | %s | [%s]" % [id, name, ", ".join(tags)])
		lines.append("  ↳ %s" % summary)
	lines.append("")
	lines.append("請為每個資產提供：")
	lines.append("1. 符合當前任務的獨特情境名稱")
	lines.append("2. 生動的描述（突出其在本次任務中的角色）")
	lines.append("3. 互動規則（玩家可以如何與之互動，以及隊友如何搞砸它）")
	return "\n".join(lines)
func get_asset_icons(asset_list: Array) -> Dictionary:
	var mapping := { }
	for asset in asset_list:
		mapping[asset.get("id", "")] = asset.get("icon", "")
	return mapping
func get_all_tags() -> Array:
	var all_tags := []
	for asset in assets.values():
		var tags: Array = asset.get("tags", [])
		for tag in tags:
			if not tag in all_tags:
				all_tags.append(tag)
	return all_tags
