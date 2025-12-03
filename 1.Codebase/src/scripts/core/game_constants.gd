extends RefCounted
class_name GameConstants
class GamePhase:
	const HONEYMOON := "honeymoon"
	const NORMAL := "normal"
	const CRISIS := "crisis"
class Player:
	const WALK_SPEED := 160.0
	const SPRINT_MULTIPLIER := 1.5
	const ACCELERATION := 900.0
	const DECELERATION := 1100.0
class Honeymoon:
	const INITIAL_CHARGES := 5
	const MIN_CHARGES := 0
	const MAX_CHARGES := 10
class Gloria:
	const MIN_COMPLAINTS_FOR_TRIGGER := 5
	const HIGH_REALITY_THRESHOLD := 80
	const HIGH_REALITY_COMPLAINT_THRESHOLD := 3
class Stats:
	const MIN_REALITY_SCORE := 0
	const MAX_REALITY_SCORE := 100
	const MIN_POSITIVE_ENERGY := 0
	const MAX_POSITIVE_ENERGY := 100
	const MIN_ENTROPY := 0
	const INITIAL_REALITY_SCORE := 50
	const INITIAL_POSITIVE_ENERGY := 50
	const INITIAL_ENTROPY := 0
	const LOW_REALITY_THRESHOLD := 20
	const HIGH_REALITY_THRESHOLD := 80
	const HIGH_ENTROPY_WARNING := 25
	const HIGH_ENTROPY_CRITICAL := 50
	const STAT_CHANGE_IMPORTANCE_THRESHOLDS := [20, 12, 6, 2]
class Entropy:
	const LOW_THRESHOLD := 0.3
	const MEDIUM_THRESHOLD := 0.7
	const HIGH_THRESHOLD := 1.0
	const BASE_ENTROPY_DIVISOR := 100.0
	const POSITIVE_ENERGY_MULTIPLIER := 0.3
class Skills:
	const DEFAULT_SKILL_VALUE := 5
	const MIN_SKILL_VALUE := 0
	const MAX_SKILL_VALUE := 20
	const DEFAULT_SKILLS := {
		"logic": DEFAULT_SKILL_VALUE,
		"perception": DEFAULT_SKILL_VALUE,
		"composure": DEFAULT_SKILL_VALUE,
		"empathy": DEFAULT_SKILL_VALUE,
	}
	const MIN_DICE_ROLL := 1
	const MAX_DICE_ROLL := 10
	const COGNITIVE_DISSONANCE_PENALTY := -2
class Events:
	const MAX_RECENT_EVENTS := 10
	const MAX_EVENT_LOG_SIZE := 200
	const DEFAULT_EVENT_LIMIT := 6
class SaveSystem:
	const MAX_SAVE_SLOTS := 5
	const AUTOSAVE_SLOT := 0
	const FIRST_MANUAL_SLOT := 1
	const AUTOSAVE_INTERVAL_SECONDS := 300.0 
	const SAVE_FILE_EXTENSION := ".save"
	const AUTOSAVE_BACKUP_EXTENSION := ".backup"
class Debuffs:
	const COGNITIVE_DISSONANCE_NAME := "cognitive_dissonance"
	const COGNITIVE_DISSONANCE_DURATION := 3
	const DEFAULT_DEBUFF_DURATION := 1
class UI:
	const LOADING_DOTS_CYCLE_TIME := 0.5
	const MAX_LOADING_DOTS := 3
	const SCROLL_ANIMATION_DURATION := 0.3
	const STORY_SNIPPET_CHAR_LIMIT := 600
	const STAT_COLOR_HIGH_THRESHOLD := 70
	const STAT_COLOR_MEDIUM_THRESHOLD := 40
	const COLOR_STAT_HIGH := Color(0.2, 0.8, 0.2) 
	const COLOR_STAT_MEDIUM := Color(0.8, 0.8, 0.2) 
	const COLOR_STAT_LOW := Color(0.8, 0.2, 0.2) 
class Achievements:
	const SKILL_CHECK_SUCCESS_THRESHOLD := 10
	const MISSION_COMPLETION_THRESHOLD := 5
	const GLORIA_TRIGGER_THRESHOLD := 3
class Language:
	const ENGLISH := "en"
	const CHINESE := "zh"
	const DEFAULT_LANGUAGE := ENGLISH
	const SUPPORTED_LANGUAGES := ["en", "zh"]
class Paths:
	const SAVE_DIRECTORY := "user://saves/"
	const CONFIG_FILE := "user://ai_settings.cfg"
	const LOG_DIRECTORY := "user://logs/"
	const AUTOSAVE_FILE := "user://saves/autosave.save"
class AI:
	const MIN_REQUEST_INTERVAL_MSEC := 1500
	const MAX_REQUESTS_PER_MINUTE := 10
	const RATE_LIMIT_COOLDOWN_MSEC := 5000
	const DEFAULT_REQUEST_TIMEOUT := 24.0
	const DEFAULT_MAX_RETRIES := 2
	const MAX_HISTORY_SIZE := 20
	const DEFAULT_INPUT_SAMPLE_RATE := 16000
	const DEFAULT_OUTPUT_SAMPLE_RATE := 24000
	const SHORT_TERM_MEMORY_WINDOW := 6
	const LONG_TERM_SUMMARY_LIMIT := 5
	const MAX_NOTES := 20
	const MEMORY_SUMMARY_THRESHOLD := 10
	const MAX_MEMORY_ITEMS := 20
	const PROMPT_MIN_LENGTH := 1
	const PROMPT_MAX_LENGTH := 4000
	const PROMPT_FORBIDDEN_PATTERN := "[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]"
class Journal:
	const MAX_SUGGESTIONS := 3
	const SUGGESTION_WORD_LIMIT := 30
	const SUMMARY_WORD_LIMIT := 50
	const SUGGESTION_TIMEOUT_SECONDS := 6.0
