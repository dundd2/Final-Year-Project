extends Node
enum AssetCategory {
	INTERACTIVE, 
	STRUCTURE, 
	CREATURE, 
	ENVIRONMENT, 
	MYSTICAL, 
	SAFE_ZONE, 
	HAZARD, 
	ITEM, 
}
var category_map := {
	AssetCategory.INTERACTIVE: ["Generic_Lever", "Generic_Button", "Generic_Door", "Generic_Chest", "Arcane_Device"],
	AssetCategory.STRUCTURE: ["Generic_Altar", "Generic_Statue", "Generic_Pillar", "Generic_Bridge", "Generic_Portal"],
	AssetCategory.CREATURE: ["Generic_Monster", "Generic_NPC", "Generic_Guardian", "Generic_Spirit"],
	AssetCategory.ENVIRONMENT: ["Glowing_Plant", "Generic_Tree", "Generic_Rock", "Generic_Water", "Generic_Fire"],
	AssetCategory.MYSTICAL: ["Arcane_Device", "Generic_Crystal", "Generic_Orb", "Generic_Portal", "Generic_Scroll"],
	AssetCategory.SAFE_ZONE: ["Rest_Spot", "Generic_Campfire", "Generic_Shelter"],
	AssetCategory.HAZARD: ["Generic_Trap", "Generic_Abyss", "Generic_Wall", "Generic_Fire"],
	AssetCategory.ITEM: ["Generic_Key", "Generic_Crystal", "Generic_Scroll", "Generic_Orb"],
}
var registry: Node = null
func _ready():
	registry = ServiceLocator.get_asset_registry() if ServiceLocator else null
func get_assets_by_category(category: AssetCategory) -> Array:
	if not registry:
		return []
	var asset_ids = category_map.get(category, [])
	var assets := []
	for id in asset_ids:
		var asset = registry.get_asset(id)
		if not asset.is_empty():
			assets.append(asset)
	return assets
func get_random_assets(count: int, exclude_ids: Array = []) -> Array:
	if not registry:
		return []
	var all_ids = registry.get_asset_ids()
	var available_ids := []
	for id in all_ids:
		if not id in exclude_ids:
			available_ids.append(id)
	available_ids.shuffle()
	var selected := []
	for i in range(min(count, available_ids.size())):
		var asset = registry.get_asset(available_ids[i])
		if not asset.is_empty():
			selected.append(asset)
	return selected
func get_balanced_asset_set(context: String = "default") -> Array:
	if not registry:
		return []
	var selected := []
	match context:
		"exploration":
			selected.append_array(get_assets_by_category(AssetCategory.INTERACTIVE).slice(0, 2))
			selected.append_array(get_assets_by_category(AssetCategory.STRUCTURE).slice(0, 1))
			selected.append_array(get_assets_by_category(AssetCategory.CREATURE).slice(0, 1))
			selected.append_array(get_assets_by_category(AssetCategory.ENVIRONMENT).slice(0, 1))
			selected.append_array(get_assets_by_category(AssetCategory.HAZARD).slice(0, 1))
		"combat":
			selected.append_array(get_assets_by_category(AssetCategory.CREATURE).slice(0, 2))
			selected.append_array(get_assets_by_category(AssetCategory.MYSTICAL).slice(0, 1))
			selected.append_array(get_assets_by_category(AssetCategory.ENVIRONMENT).slice(0, 1))
			selected.append_array(get_assets_by_category(AssetCategory.HAZARD).slice(0, 1))
			selected.append_array(get_assets_by_category(AssetCategory.STRUCTURE).slice(0, 1))
		"puzzle":
			selected.append_array(get_assets_by_category(AssetCategory.INTERACTIVE).slice(0, 3))
			selected.append_array(get_assets_by_category(AssetCategory.MYSTICAL).slice(0, 2))
			selected.append_array(get_assets_by_category(AssetCategory.STRUCTURE).slice(0, 1))
		"narrative":
			selected.append_array(get_assets_by_category(AssetCategory.SAFE_ZONE).slice(0, 2))
			selected.append_array(get_assets_by_category(AssetCategory.CREATURE).slice(0, 2))
			selected.append_array(get_assets_by_category(AssetCategory.STRUCTURE).slice(0, 1))
			selected.append_array(get_assets_by_category(AssetCategory.ITEM).slice(0, 1))
		_: 
			if registry:
				for id in registry.default_cycle:
					var asset = registry.get_asset(id)
					if not asset.is_empty():
						selected.append(asset)
	return selected
func filter_assets_by_tags(tag_filter: Array) -> Array:
	if not registry:
		return []
	return registry.get_assets_by_tags(tag_filter)
func search_assets(search_term: String) -> Array:
	if not registry:
		return []
	var results := []
	var all_ids = registry.get_asset_ids()
	search_term = search_term.to_lower()
	for id in all_ids:
		var asset = registry.get_asset(id)
		if asset.is_empty():
			continue
		if id.to_lower().contains(search_term):
			results.append(asset)
			continue
		var name = asset.get("default_name", "").to_lower()
		if name.contains(search_term):
			results.append(asset)
			continue
		var tags: Array = asset.get("tags", [])
		for tag in tags:
			if str(tag).to_lower().contains(search_term):
				results.append(asset)
				break
		var summary = asset.get("summary", "").to_lower()
		if summary.contains(search_term):
			if not asset in results:
				results.append(asset)
	return results
func get_asset_statistics() -> Dictionary:
	if not registry:
		return { }
	var stats := {
		"total_assets": 0,
		"by_category": { },
		"all_tags": [],
		"tag_usage": { },
	}
	var all_ids = registry.get_asset_ids()
	stats["total_assets"] = all_ids.size()
	for category in AssetCategory.values():
		var category_name = AssetCategory.keys()[category]
		var assets = get_assets_by_category(category)
		stats["by_category"][category_name] = assets.size()
	if registry and registry.has_method("get_all_tags"):
		stats["all_tags"] = registry.get_all_tags()
		for tag in stats["all_tags"]:
			var count = 0
			for id in all_ids:
				var asset = registry.get_asset(id)
				var tags: Array = asset.get("tags", [])
				if tag in tags:
					count += 1
			stats["tag_usage"][tag] = count
	return stats
func create_ai_prompt_with_context(context_type: String, mission_description: String = "") -> String:
	var assets = get_balanced_asset_set(context_type)
	var prompt_parts := []
	prompt_parts.append("=== 場景資產系統 / Scene Asset System ===\n")
	prompt_parts.append("以下是本場景可用的符號化資產，請將它們融入任務設計中：\n")
	if registry:
		prompt_parts.append(registry.format_assets_for_prompt(assets))
	prompt_parts.append("\n=== 任務上下文 / Mission Context ===")
	prompt_parts.append("場景類型 / Scene Type: %s" % context_type.capitalize())
	if mission_description != "":
		prompt_parts.append("任務描述 / Mission Description: %s" % mission_description)
	prompt_parts.append("\n=== AI 指引 / AI Guidelines ===")
	prompt_parts.append("1. 為每個資產賦予符合本次任務的獨特名稱")
	prompt_parts.append("2. 描述它在本次任務中的具體作用")
	prompt_parts.append("3. 說明玩家如何與之互動")
	prompt_parts.append("4. 描述隊友可能如何搞砸與此資產的互動")
	prompt_parts.append("5. 確保資產的使用符合「黑色幽默」和「正能量詛咒」的遊戲主題")
	return "\n".join(prompt_parts)
