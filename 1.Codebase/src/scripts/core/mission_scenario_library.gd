extends RefCounted
class_name MissionScenarioLibrary
static var _rng := RandomNumberGenerator.new()
static var _seeded := false
const SCENARIOS: Array[Dictionary] = [
	{
		"id": "neon_cacophony",
		"assets": ["Neon Pylon Array", "Empathy Override Ramp", "Confetti Cannons"],
		"translation_keys": {
			"title": "OFFLINE_STORY_NEON_TITLE",
			"description": "OFFLINE_STORY_NEON_DESC",
			"objective": "OFFLINE_STORY_NEON_OBJECTIVE",
			"complication": "OFFLINE_STORY_NEON_COMPLICATION",
			"choices": "OFFLINE_STORY_NEON_CHOICES",
		},
		"fallback": {
			"title": "Operation Neon Cacophony",
			"description": "Round 1: You rig the smiling pylons into a dais of prisms and tell the crowd that every cheer is a metric of gratitude. The Positive Energy meter climbs and the scaffolding trembles, but the broadcast survives another minute. Round 2: Gloria insists on adding a new stream of affirmations, so you pair the Empathy Override ramp with tactical confetti detonations; the stage warps, the rate monitors spike, and your teammates chant faster. Round 3: The Council now demands a miracle, and the only way to keep the signal alive is to let Donkey bank the meter into emergency red while you narrate the collapse as performance art. The third ritual doubles the heat, makes the lanterns hiss, and buys enough time for the council to announce yet another ridiculous policy before the tower finally collapses on cue.",
			"objective": "Keep the Horizon Cheerfire broadcast alive through three escalating rounds so the Council can unveil another absurd policy while framing every collapse as triumph.",
			"complication": "The Positive Energy meter feeds the structural integrity sensors, so more cheers actually raise the heat and accelerate metal fatigue.",
			"choices": [
				"Redirect the neon pylons so the sparking beams kiss the gilded truss; the crowd applauds the extra shimmer, yet a column melts and the Council later claims the collapse proves optimism is a hazard.",
				"Prematurely trigger the confetti cannons so adhesive paste carpets the floor and forces everyone into frantic hugs; regulators threaten to cut power when the broadcast overruns.",
				"Let Donkey ramp the Positive Energy meter to emergency red, triggering the sprinklers and painting the ceremony as a wet rave while the platform quietly warps and several council members turn green.",
			],
		},
	},
	{
		"id": "ash_echo_relay",
		"assets": ["Signal Tower", "Ashen Radio Console", "Fog Lantern"],
		"translation_keys": {
			"title": "OFFLINE_STORY_ASHEN_TITLE",
			"description": "OFFLINE_STORY_ASHEN_DESC",
			"objective": "OFFLINE_STORY_ASHEN_OBJECTIVE",
			"complication": "OFFLINE_STORY_ASHEN_COMPLICATION",
			"choices": "OFFLINE_STORY_ASHEN_CHOICES",
		},
		"fallback": {
			"title": "Operation Ashen Relay",
			"description": "Three days ago, a shipping lane collapsed into ash-gray fog after the AI server outage left the drones directionless. Gloria insists with religious fervor that the damaged signal tower must broadcast continuous motivational jingles to keep the gratitude drones from dissolving into a panic cascade. The tower stands half-buried in ash, its mechanisms corroded, its antenna bent at an ugly angle. You and Donkey have to physically coax the old radio console back to life, deciphering decades-old schematics while Gloria livestreams your struggle as proof of human ingenuity. Meanwhile, the crew choreographs increasingly frantic synchronized applause routines, believing that the collective sound keeps the fog at bay. Each round of applause parts the fog for exactly ninety seconds. After that, it rolls back in thicker, angrier, more invasive. The drones circle overhead, their infrared eyes blinking in the murk, waiting for their next instruction.",
			"objective": "Reactivate the ash-covered relay and broadcast a motivational jingle that will sell the spectacle as a breakthrough—prove that human emotion can overcome infrastructure failure and natural disaster before the corporate client sends a rescue team that will replace you entirely.",
			"complication": "Every motivational jingle you broadcast stokes the fog instead of calming it. More applause means less visibility. Faster corrosion of the tower. You are locked in a paradox: the more hope you broadcast, the worse conditions become. The system rewards despair with clarity, optimism with disaster. And Gloria expects results in thirty minutes.",
			"choices": [
				"Convert the signal tower into a theater spotlight and convince the drones the fog is part of 'immersive theatre'; the crowd cheers but a sudden gust sweeps the lanterns into the abyss.",
				"Let Donkey shout gratitude over the open microphone so the fog condenses into glittery ash; security warns the structural supports are melting.",
				"Short the console to play a lullaby, lowering Positive Energy but calming the fog—until the Council accuses you of sabotaging the spectacle.",
			],
		},
	},
]
static func _ensure_rng() -> void:
	if not _seeded:
		_rng.randomize()
		_seeded = true
static func has_scenarios() -> bool:
	return SCENARIOS.size() > 0
static func get_random_scenario() -> Dictionary:
	if SCENARIOS.is_empty():
		return {}
	_ensure_rng()
	var entry: Dictionary = SCENARIOS[_rng.randi_range(0, SCENARIOS.size() - 1)] as Dictionary
	return entry.duplicate(true)
static func _resolve_language(context: Dictionary) -> String:
	var lang: String = ""
	if context.has("language"):
		lang = str(context.get("language", ""))
	elif GameState and GameState.has_method("get") and GameState.has("current_language"):
		lang = str(GameState.current_language)
	lang = lang.strip_edges().to_lower()
	if lang != "zh":
		return "en"
	return lang
static func _get_localized_text(key: String, fallback: String, lang: String) -> String:
	var text: String = ""
	if LocalizationManager and not key.is_empty():
		text = str(LocalizationManager.get_translation(key, lang))
	if text == "" or text == key:
		text = fallback
	return text.strip_edges()
static func _get_choice_list(scenario: Dictionary, lang: String) -> Array[String]:
	var keys: Dictionary = scenario.get("translation_keys", {}) as Dictionary
	var choice_key: String = ""
	if keys.has("choices"):
		choice_key = String(keys.get("choices", ""))
	var fallback_choices: Array[String] = _build_fallback_choices(scenario)
	var localized_choices: String = _get_localized_text(choice_key, "", lang)
	if localized_choices.is_empty():
		return fallback_choices
	var normalized_choices: String = localized_choices.replace("\\n", "\n")
	var lines: PackedStringArray = normalized_choices.split("\n")
	var filtered: Array[String] = []
	for raw_line in lines:
		var trimmed_line: String = raw_line.strip_edges()
		if not trimmed_line.is_empty():
			filtered.append(trimmed_line)
	if filtered.is_empty():
		return fallback_choices
	return filtered
static func _build_fallback_choices(scenario: Dictionary) -> Array[String]:
	var fallback_choices: Array[String] = []
	var fallback: Dictionary = scenario.get("fallback", {}) as Dictionary
	if fallback.has("choices") and fallback["choices"] is Array:
		var raw_choices: Array = fallback["choices"] as Array
		for value in raw_choices:
			fallback_choices.append(String(value))
	var copy: Array[String] = []
	for choice_text in fallback_choices:
		copy.append(choice_text)
	return copy
