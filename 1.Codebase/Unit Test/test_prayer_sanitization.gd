extends SceneTree
func _init():
	print("Running PrayerSystem Sanitization Logic Test")
	print("------------------------------------------")
	var test_str = "  hello   world  \t\n  test  "
	print("Test string: '%s'" % test_str.replace("\n", "\\n").replace("\t", "\\t"))
	print("\n[Check 1] verifying String.simplify_whitespace() existence...")
	if test_str.has_method("simplify_whitespace"):
		print("[FAIL] String.simplify_whitespace() exists (unexpected in Godot 4).")
	else:
		print("[PASS] String.simplify_whitespace() is missing (Bug Confirmed).")
	print("\n[Check 2] verifying RegEx replacement logic...")
	var regex = RegEx.new()
	regex.compile("\\s+")
	var fixed_result = regex.sub(test_str, " ", true).strip_edges()
	var expected = "hello world test"
	if fixed_result == expected:
		print("[PASS] Fix logic works correctly.")
		print("       Result: '%s'" % fixed_result)
	else:
		print("[FAIL] Fix logic failed.")
		print("       Expected: '%s'" % expected)
		print("       Actual:   '%s'" % fixed_result)
	print("\nTest Complete.")
	quit()
