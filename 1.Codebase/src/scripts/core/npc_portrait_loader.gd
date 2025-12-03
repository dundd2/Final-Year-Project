extends Object
class_name NPCPortraitLoader
const DEFAULT_PLACEHOLDER_PATH := "res://1.Codebase/src/assets/icons/npc.png"
const NPC_LIBRARY := {
	"generic_villager_male": {
		"path": "res://1.Codebase/src/assets/characters/npc/generic_villager_male.png",
	},
	"generic_villager_female": {
		"path": "res://1.Codebase/src/assets/characters/npc/generic_villager_female.png",
	},
	"generic_guard": {
		"path": "res://1.Codebase/src/assets/characters/npc/generic_guard.png",
	},
	"generic_merchant": {
		"path": "res://1.Codebase/src/assets/characters/npc/generic_merchant.png",
	},
	"generic_elder": {
		"path": "res://1.Codebase/src/assets/characters/npc/generic_elder.png",
	},
	"generic_child": {
		"path": "res://1.Codebase/src/assets/characters/npc/generic_child.png",
	},
	"generic_priest": {
		"path": "res://1.Codebase/src/assets/characters/npc/generic_priest.png",
	},
	"generic_scientist": {
		"path": "res://1.Codebase/src/assets/characters/npc/generic_scientist.png",
	},
}
static func get_npc_texture(npc_id: String) -> Texture2D:
	var has_definition: bool = NPC_LIBRARY.has(npc_id)
	var definition: Dictionary = NPC_LIBRARY.get(npc_id, { })
	var candidates: Array[String] = []
	if has_definition:
		var direct_path := String(definition.get("path", ""))
		if not direct_path.is_empty():
			candidates.append(direct_path)
	var placeholder_path: String = DEFAULT_PLACEHOLDER_PATH
	if has_definition:
		placeholder_path = String(definition.get("placeholder", DEFAULT_PLACEHOLDER_PATH))
	if not placeholder_path.is_empty():
		candidates.append(placeholder_path)
	for path in candidates:
		if ResourceLoader.exists(path):
			var texture: Texture2D = ResourceLoader.load(path) as Texture2D
			if texture:
				return texture
			else:
				if ErrorReporter:
					ErrorReporter.report_warning("NPCPortraitLoader", "Failed to load NPC portrait texture", { "path": path })
		else:
			if ErrorReporter:
				ErrorReporter.report_warning("NPCPortraitLoader", "NPC portrait asset not found", { "path": path })
	if ErrorReporter:
		ErrorReporter.report_warning("NPCPortraitLoader", "No valid texture found for NPC", { "npc_id": npc_id })
	return null
static func get_npc_name(npc_id: String, language: String = "en") -> String:
	var has_definition: bool = NPC_LIBRARY.has(npc_id)
	if not has_definition:
		if LocalizationManager:
			return LocalizationManager.get_translation("NPC_unknown", language)
		return "NPC" if language == "en" else "角色"
	var translation_key := "NPC_" + npc_id
	if LocalizationManager:
		var translated_name := LocalizationManager.get_translation(translation_key, language)
		if not translated_name.is_empty():
			return translated_name
	return npc_id.replace("_", " ").capitalize()
static func get_known_ids() -> Array[String]:
	return NPC_LIBRARY.keys()
