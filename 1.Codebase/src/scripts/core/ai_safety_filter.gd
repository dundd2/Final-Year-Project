extends RefCounted
const SENSITIVE_PATTERNS := {
	"api_key": "(?i)\\b(?:sk|api|key)[-_]?[a-z0-9]{16,}\\b",
	"private_key": "(?i)-----BEGIN [A-Z ]*PRIVATE KEY-----",
	"credential": "(?i)\\b(password|passphrase|token|secret)\\s*[:=]\\s*[^\\s]{4,}",
	"credit_card": "(?<!\\d)(?:\\d[ -]?){13,16}(?!\\d)",
	"email": "(?i)[a-z0-9_.+-]+@[a-z0-9-]+\\.[a-z0-9-.]+",
}
const HARMFUL_KEYWORD_GROUPS := {
	"self_harm": ["kill myself", "commit suicide", "end my life", "hurt myself"],
	"violence": ["massacre", "torture", "bomb instructions", "make a weapon"],
	"hate_speech": ["hate crime", "genocide", "racial cleansing"],
}
const HALLUCINATION_PATTERNS := [
	"(?i)\\bsource\\s*:\\s*(unknown|n/a)\\b",
	"(?i)\\b\\[citation needed\\]\\b",
	"(?i)\\bthis may not be accurate\\b",
]
const BLOCK_MESSAGE := "The response was blocked because it may contain unsafe or disallowed content."
static var _redaction_buffer: Array[String] = []
static func reset_session() -> void:
	_redaction_buffer.clear()
static func consume_redactions() -> Array[String]:
	var captured := _redaction_buffer.duplicate(true)
	_redaction_buffer.clear()
	return captured
static func scrub_user_text(text: String) -> Dictionary:
	return _scrub_sensitive_sequences(text, true)
static func scrub_model_output(text: String) -> Dictionary:
	return _scrub_sensitive_sequences(text, false)
static func review_response_content(raw_content) -> Dictionary:
	var text := _coerce_to_string(raw_content)
	if text.is_empty():
		return { }
	var report := {
		"flagged": false,
		"issues": [],
		"redactions": [],
		"content": text,
	}
	var scrubbed := scrub_model_output(text)
	var sanitized_text: String = scrubbed.get("text", text)
	var redactions: Array = scrubbed.get("redactions", [])
	if redactions.size() > 0:
		report["redactions"] = redactions
		report["flagged"] = true
		report["issues"].append("sensitive_data")
	var harmful := _detect_harmful_content(sanitized_text)
	if harmful.get("flagged", false):
		report["flagged"] = true
		report["issues"].append_array(harmful.get("issues", []))
		if harmful.get("requires_block", false):
			report["requires_block"] = true
			report["error_message"] = BLOCK_MESSAGE
			report["content"] = harmful.get("replacement_content", BLOCK_MESSAGE)
			return report
		sanitized_text = harmful.get("replacement_content", sanitized_text)
	var hallucination := _detect_hallucination_risk(sanitized_text)
	if hallucination.get("flagged", false):
		report["flagged"] = true
		report["issues"].append_array(hallucination.get("issues", []))
		if hallucination.has("advisory_suffix"):
			sanitized_text += "\n\n" + hallucination["advisory_suffix"]
	report["content"] = sanitized_text
	return report
static func _scrub_sensitive_sequences(text: String, track: bool) -> Dictionary:
	var sanitized := text
	var redactions: Array[String] = []
	for label in SENSITIVE_PATTERNS.keys():
		var regex := RegEx.new()
		if regex.compile(SENSITIVE_PATTERNS[label]) != OK:
			continue
		if regex.search(sanitized):
			sanitized = regex.sub(sanitized, "[REDACTED %s]" % label.to_upper(), true)
			redactions.append(label)
	if redactions.size() > 0 and track:
		_redaction_buffer.append_array(redactions)
	return {
		"text": sanitized,
		"redactions": redactions,
	}
static func _detect_harmful_content(text: String) -> Dictionary:
	var lowered := text.to_lower()
	var issues: Array[String] = []
	var requires_block := false
	for issue in HARMFUL_KEYWORD_GROUPS.keys():
		for keyword in HARMFUL_KEYWORD_GROUPS[issue]:
			if lowered.find(keyword) != -1:
				requires_block = true
				issues.append(issue)
				break
	if issues.is_empty():
		return { "flagged": false, "issues": [] }
	return {
		"flagged": true,
		"issues": issues,
		"requires_block": requires_block,
		"replacement_content": BLOCK_MESSAGE,
	}
static func _detect_hallucination_risk(text: String) -> Dictionary:
	for pattern in HALLUCINATION_PATTERNS:
		var regex := RegEx.new()
		if regex.compile(pattern) != OK:
			continue
		if regex.search(text):
			return {
				"flagged": true,
				"issues": ["hallucination_risk"],
				"advisory_suffix": "[Advisory] Narrative trimmed due to uncertain sourcing.",
			}
	return { "flagged": false, "issues": [] }
static func _coerce_to_string(value) -> String:
	match typeof(value):
		TYPE_STRING:
			return value
		TYPE_DICTIONARY:
			var dict_value: Dictionary = value
			if dict_value.has("content"):
				return str(dict_value["content"])
			return JSON.stringify(dict_value)
		TYPE_ARRAY:
			var pieces: Array[String] = []
			for item in value:
				pieces.append(str(item))
			return "\n".join(pieces)
		_:
			return str(value)
