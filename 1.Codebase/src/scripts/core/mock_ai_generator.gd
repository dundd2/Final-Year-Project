extends RefCounted
class_name MockAIGenerator
const MissionScenarioLibrary := preload("res://1.Codebase/src/scripts/core/mission_scenario_library.gd")
const GameConstants := preload("res://1.Codebase/src/scripts/core/game_constants.gd")
static var _rng := RandomNumberGenerator.new()
static var _seeded := false
static func _ensure_rng() -> void:
	if not _seeded:
		_rng.randomize()
		_seeded = true
static func generate_response(prompt: String, context: Dictionary) -> String:
	_ensure_rng()
	var purpose: String = ""
	if context.has("purpose"):
		purpose = str(context["purpose"]).to_lower()
	if purpose.is_empty():
		purpose = _infer_purpose(prompt.to_lower())
	match purpose:
		"mission":
			return _generate_mission(context)
		"consequence":
			return _generate_consequence(context)
		"prayer":
			return _generate_prayer(context)
		"interference":
			return _generate_interference(context)
		"test":
			return _generate_test_response()
		_:
			return _generate_generic()
static func _infer_purpose(prompt_lower: String) -> String:
	if "prayer" in prompt_lower or "my prayer" in prompt_lower:
		return "prayer"
	if "interference" in prompt_lower or "teammate" in prompt_lower:
		return "interference"
	if "mission" in prompt_lower or "objective" in prompt_lower:
		return "mission"
	if "consequence" in prompt_lower or "result" in prompt_lower:
		return "consequence"
	return "generic"
static func _generate_mission(context: Dictionary) -> String:
	_ensure_rng()
	var story_text := ""
	if MissionScenarioLibrary.has_scenarios():
		var scenario := MissionScenarioLibrary.get_random_scenario()
		if scenario.size() > 0:
			story_text = _format_library_scenario(scenario, context)
	if story_text.is_empty():
		story_text = _build_random_story(context)
	return JSON.stringify(_build_mission_response(story_text))
static func _build_mission_response(story_text: String) -> Dictionary:
	_ensure_rng()
	var backgrounds: Array[String] = [
		"ruins",
		"cave",
		"dungeon",
		"forest",
		"temple",
		"laboratory",
		"library",
		"throne_room",
		"battlefield",
		"crystal_cavern",
		"bridge",
		"garden",
		"portal_area",
		"safe_zone",
		"water",
		"fire_area",
	]
	var background: String = backgrounds[_rng.randi_range(0, backgrounds.size() - 1)]
	var expressions: Array[String] = ["neutral", "happy", "sad", "angry", "confused", "shocked", "thinking", "embarrassed"]
	var response := {
		"scene": {
			"background": background,
			"atmosphere": _pick(["tense", "calm", "mysterious", "chaotic"]),
			"lighting": _pick(["normal", "dim", "bright"]),
		},
		"characters": {
			"protagonist": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
			"gloria": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
			"donkey": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
			"ark": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
			"one": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
		},
		"story_text": story_text,
	}
	return response
static func _format_library_scenario(scenario: Dictionary, context: Dictionary) -> String:
	if scenario.is_empty():
		return ""
	var lang: String = MissionScenarioLibrary._resolve_language(context)
	var keys: Dictionary = scenario.get("translation_keys", {}) as Dictionary
	var fallback: Dictionary = scenario.get("fallback", {}) as Dictionary
	var lines: Array[String] = []
	var title: String = MissionScenarioLibrary._get_localized_text(keys.get("title", ""), fallback.get("title", "Unnamed Operation"), lang)
	lines.append("**Mission Codename: %s**" % title)
	var description: String = MissionScenarioLibrary._get_localized_text(keys.get("description", ""), fallback.get("description", ""), lang)
	if not description.is_empty():
		lines.append(description)
	lines.append("")
	var objective: String = MissionScenarioLibrary._get_localized_text(keys.get("objective", ""), fallback.get("objective", "Objective not provided."), lang)
	lines.append("Mission Objective: %s" % objective)
	var assets: Array = scenario.get("assets", []) as Array
	if assets is Array and not assets.is_empty():
		var asset_names: Array[String] = []
		for asset in assets:
			asset_names.append(str(asset))
		lines.append("Assets: %s" % ", ".join(asset_names))
	var complication: String = MissionScenarioLibrary._get_localized_text(keys.get("complication", ""), fallback.get("complication", ""), lang)
	if not complication.is_empty():
		lines.append("Complication: %s" % complication)
	var choices: Array[String] = MissionScenarioLibrary._get_choice_list(scenario, lang)
	if choices.size() > 0:
		lines.append("")
		lines.append("Choices (all escalate entropy):")
		for choice_text in choices:
			lines.append("- %s" % choice_text)
	lines.append("")
	lines.append("Status monitor: %s" % _build_status_line(context))
	lines.append("Reminder: the harder you try, the faster the world burns.")
	return "\n".join(lines)
static func _build_status_line(context: Dictionary) -> String:
	var ctx: Dictionary = {}
	if context:
		ctx = context
	var reality: int = _context_stat(ctx, "reality_score", GameConstants.Stats.INITIAL_REALITY_SCORE)
	var positive: int = _context_stat(ctx, "positive_energy", GameConstants.Stats.INITIAL_POSITIVE_ENERGY)
	var entropy: int = _context_stat(ctx, "entropy_level", GameConstants.Stats.INITIAL_ENTROPY)
	return "Reality %d/100 | Positive Energy %d/100 | Entropy %d" % [reality, positive, entropy]
static func _build_random_story(context: Dictionary) -> String:
	var status: String = _build_status_line(context)
	var title: String = _pick(
		[
			"Project Glitter Leak",
			"Operation Mandatory Smile",
			"Hope Injection Drill",
			"Radiant Disaster Outreach",
		],
	)
	var setup: String = _pick(
		[
			"Gloria convened an emergency meeting at 3am to announce that the team must install exactly 300 pastel light bulbs inside the underground shelter so despair will reflect less off the concrete walls. She has already ordered them in bulk. Delivery is in four hours. The shelter's electrical system was rated for 1987.",
			"Donkey announced in the city square from atop a kiosk that today's schedule ends definitively with a royal rescue, even though no royalty lives here, has ever lived here, or was ever mentioned in any official census. He has already invited the press. They are waiting. Reality is not.",
			"ARK printed a forty page checklist that must be completed in order, signed in triplicate, and notarized before anyone is allowed to speak to the locals. The checklist itself is three pages long. The signature page is four pages. Page 28 contains only the words 'VERIFY PREVIOUS PAGE' with no other context. You have two hours.",
			"One quietly stocked the community kitchen with enough food for three weeks, but the others misinterpreted the gesture and planned an elaborate televised celebration feast. The media trucks are already here. One is watching from the corner, hoping nobody asks him to make a speech.",
		],
	)
	var context_detail := _pick(
		[
			"The weather forecast predicts both sunshine and torrential rain simultaneously in the same location.",
			"A documentary crew has been following your team for three days without permission and refuses to leave.",
			"The local government changed all the rules thirty minutes ago but hasn't informed anyone yet.",
			"Three separate volunteer groups have conflicting interpretations of what needs to happen.",
		],
	)
	var twist: String = _pick(
		[
			"Every forced smile raises the entropy monitor by another red bar. The monitoring equipment was never meant for human emotion tracking. It was meant for industrial furnaces. It is malfunctioning.",
			"A live broadcast counts down to your miracle while the signal desyncs into ghostly echoes of previous conversations you didn't know were being recorded. Gloria is taking notes. The Council is watching. Both are disappointed.",
			"Positive affirmations melt the nearby machines into syrupy sludge—the coffee maker, the printers, the air conditioning unit. Maintenance is not amused. The bill will come later. They always do.",
			"Gloria streams your every moment and the comments demand that you repent twice—once for the failure, and once for the audacity of trying in the first place. Her chat is very honest about its assessment of your character.",
		],
	)
	var goal: String = _pick(
		[
			"Convince the patrol captain that this is not a cult parade and that you have legitimate permits for the gathering, even though you don't actually have permits, and even though it does look exactly like a cult parade.",
			"Stop Donkey from repackaging demolition charges as romantic fireworks before he sells them to civilians, because the civil lawsuits are expensive and the insurance policy explicitly excludes intentional stupidity.",
			"Find at least one citizen who actually needs help and can articulate the need before Teacher Chan claims the credit for solving problems that didn't exist.",
			"Keep whatever remains of your reality score from being completely drained by mandatory group hugs and team bonding exercises that Gloria insists build trust but actually cause mild trauma.",
		],
	)
	var story_lines: Array = []
	story_lines.append("**Mission Codename: %s**" % title)
	story_lines.append(setup)
	story_lines.append("Context: %s" % context_detail)
	story_lines.append("Objective: %s" % goal)
	story_lines.append("Known complication: %s" % twist)
	story_lines.append("")
	story_lines.append("Status monitor: %s" % status)
	story_lines.append("Reminder: the harder you try, the faster the world burns.")
	return "\n".join(story_lines)
static func _generate_consequence(context: Dictionary) -> String:
	var choice_text: String = str(context.get("choice_text", "that choice"))
	var success: bool = bool(context.get("success", false))
	var opening = "Brief success" if success else "Failure as scheduled"
	var reactions_success = [
		"Just as the guard nods and the situation stabilizes, Donkey bursts onto the scene and launches into an impromptu victory speech about saving invisible princesses from an interdimensional threat. Security is called. The moment is lost. Glory is complicated.",
		"The plan almost works—you can feel it succeeding, the positive energy building—until Gloria interrupts and requests a gratitude circle live on air so everyone can affirm their mutual success. By the time the circle ends thirty minutes later, the original problem has escalated and compounded.",
		"Success feels palpable until ARK realizes the solution violates section 7B of the official procedures, requiring immediate documentation revision before the success can be counted as legitimate.",
	]
	var reactions_fail = [
		"The moment you stumble, the team begins passing blame like a hot potato, each person carefully documenting their objections for the inevitable inquiry later. One apologizes to you privately but is already drafting his explanation to Gloria.",
		"Logic flickers out completely as positive slogans rain down like confetti from Gloria's social media network. The comments section becomes a tribunal. Your mistakes are now immortalized in multiple mediums.",
		"The failure triggers a chain reaction of team recriminations, with each member blaming the specific decision they opposed most vocally, thereby absolving themselves of responsibility while reinforcing their personal narrative of prescience.",
	]
	var sabotage = [
		"Donkey hijacks the conversation to advertise his heroic memoir, 'Donkey: A Story of Impossible Choices,' with a self-published link he pulls from his pocket. He has copies. He is selling them.",
		"ARK issues seventeen alternate flow charts showing how the situation should have been handled and demands signatures in triplicate, including notarization, on each one. He has been preparing these charts since before the mission began.",
		"Gloria claims your concern about the complications wounded her aura deeply and asks the crowd to form a spontaneous comfort circle around her while she processes the emotional injury. Your problem is now secondary to her recovery.",
		"One messages you privately with genuine support and validation, telling you your instincts were correct. He then tells the group he has no particular opinion, allowing your argument to die under the weight of collective silence.",
	]
	var nudges = [
		"You must now decide whether to keep arguing against an increasingly hostile consensus or start drafting a public apology for decisions you know were correct. Neither option improves the situation.",
		"Perhaps the wisest move is to smile through the pain, nod at Gloria's explanation, and quietly record the latest entropy spike in your personal journal—the one nobody else will ever see.",
		"Staying on site any longer drains what little remains of your sanity meter, but leaving implies guilt. You are trapped in a cage of social obligation and workplace politics.",
	]
	var story_lines: Array = []
	story_lines.append("%s: %s" % [opening, choice_text])
	story_lines.append(_pick(reactions_success if success else reactions_fail))
	story_lines.append("Teammate follow-up: %s" % _pick(sabotage))
	story_lines.append(_pick(nudges))
	var story_text = "\n".join(story_lines)
	var expressions = ["neutral", "happy", "sad", "angry", "confused", "shocked", "thinking", "embarrassed"]
	var response = {
		"characters": {
			"protagonist": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
			"gloria": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
			"donkey": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
			"ark": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
			"one": { "expression": expressions[_rng.randi_range(0, expressions.size() - 1)] },
		},
		"story_text": story_text,
	}
	return JSON.stringify(response)
static func _generate_prayer(context: Dictionary) -> String:
	var prayer_text: String = str(context.get("prayer_text", "We believe in sunshine."))
	var reality_score: int = _context_stat(context, "reality_score", GameConstants.Stats.INITIAL_REALITY_SCORE)
	var backlash = _pick(
		[
			"The universe loops your prayer into a twelve hour wellness broadcast that plays on repeat through the PA system. Everyone is trapped. Nobody can escape. All must listen to your words eternally.",
			"Positive energy boils the drinking water into motivational tea that tastes of artificial sweetness and regret. Consumption is mandatory. Hydration is now a political statement.",
			"A corporate sponsor remixes your words into a pop anthem about compliance and mandatory joy, complete with a music video. It gets 47 million views. You cannot escape it. It plays in every elevator.",
			"Gloria schedules you to share more affirmations at tomorrow's stand-up meeting, already promoting you to the staff as 'our resident positivity expert.' You have become a brand. Your authenticity is now product.",
		],
	)
	var clarity_line = "Reality crouches in the corner, pretending to faint, while the monitors blink red around it." if reality_score < GameConstants.UI.STAT_COLOR_MEDIUM_THRESHOLD else "Reality staggers backward, pelted mercilessly by applause and glitter and confetti, its coherence fragmenting with each cheer."
	var lines: Array = []
	lines.append("You whisper into the void: \"%s\"." % prayer_text)
	lines.append("The Flying Spaghetti Monster answers by: %s" % backlash)
	lines.append(clarity_line)
	lines.append("Entropy observes your prayer with satisfaction, then takes a confident step forward. It is growing stronger. Thanks for the assistance.")
	return "\n".join(lines)
static func _generate_interference(context: Dictionary) -> String:
	var teammate: String = str(context.get("teammate", "gloria"))
	var player_action: String = str(context.get("player_action", "your sensible attempt"))
	match teammate:
		"gloria":
			return "Gloria hears %s and softly accuses you of poisoning the vibe with negativity and fear. She immediately replaces the plan with a mandatory group prayer while the crisis snowballs offstage, growing larger and more complicated by the minute." % player_action
		"donkey":
			return "Donkey decides %s lacks drama and vision. He kneels down to propose marriage to the nearest passer-by in what he calls 'a bold statement about community,' forcing security to detain the entire squad and leaving the mission objective unattended." % player_action
		"ark":
			return "ARK confiscates control of the situation, announcing solemnly that everyone must complete Form 17-B in full before anyone is even allowed to breathe. By the time signatures and notarizations finish, the mission objective has combusted on its own, proving ARK's point about proper procedure."
		"one":
			return "One messages you privately: 'I agree with you completely, but please do not drag me into this.' Moments later he tells the group he has no particular opinion on the matter, burying your argument under the weight of collective silence and his calculated neutrality."
		_:
			return "A nameless teammate steps forward, radiating absolute sincerity and moral clarity while meticulously ruining the timeline and your chances of success with well-intentioned interference."
static func _generate_test_response() -> String:
	return "Offline mock response: systems ready to embrace your forced optimism."
static func _generate_generic() -> String:
	var filler = _pick(
		[
			"The cosmos enjoys how you polish despair until it shines.",
			"Positive energy behaves like spam email: once subscribed, never gone.",
			"Every desperate effort is fuel for the entropy furnace.",
		],
	)
	return "AI service offline. Local narrative module says: %s" % filler
static func _pick(options: Array) -> String:
	_ensure_rng()
	if options.is_empty():
		return ""
	return String(options[_rng.randi_range(0, options.size() - 1)])
static func _get_game_state() -> Node:
	if not Engine.has_singleton("ServiceLocator"):
		return null
	var locator: Node = Engine.get_singleton("ServiceLocator") as Node
	if locator == null or not locator.has_method("get_game_state"):
		return null
	var game_state: Node = locator.call("get_game_state")
	return game_state if is_instance_valid(game_state) else null
static func _context_stat(context: Dictionary, key: String, fallback: int) -> int:
	if context.has(key):
		return int(context[key])
	var game_state := _get_game_state()
	if game_state:
		var value = game_state.get(key)
		if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
			return int(value)
	return fallback
