extends Node
var _test_log: Array = []
var _failed: bool = false
class MockServiceLocator extends Node:
	var teammate_system = null
	func get_teammate_system():
		return teammate_system
	func get_achievement_system():
		return null
class MockTeammateSystem extends Node:
	var relationships_updated = []
	func update_relationship(source: String, target: String, status: String, value: int):
		relationships_updated.append({
			"source": source,
			"target": target,
			"status": status,
			"value": value
		})
class MockGameState extends Node:
	var reality_score = 50
	var positive_energy = 50
	var entropy_level = 0
	var butterfly_tracker = null
	func modify_reality_score(amount): pass
	func modify_positive_energy(amount): pass
	func modify_entropy(amount, reason): pass
func _ready() -> void:
	print("🧪 RUNNING TROLLEY PROBLEM BUG REPRODUCTION TEST")
	var mock_service_locator = MockServiceLocator.new()
	var mock_teammate_system = MockTeammateSystem.new()
	var mock_game_state = MockGameState.new()
	mock_service_locator.teammate_system = mock_teammate_system
	test_reproduction()
	if not _failed:
		print("✅ TEST PASSED (Bug Reproduced if failing expectedly, or Logic verified)")
	queue_free()
func test_reproduction():
	var TrolleyGenScript = load("res://1.Codebase/src/scripts/core/trolley_problem_generator.gd")
	var generator = TrolleyGenScript.new()
	add_child(generator)
	var test_dilemma = {
		"template_type": "test",
		"choices": [
			{
				"id": "choice_1",
				"text": "Test Choice",
				"relationship_changes": [
					{
						"target": "gloria",
						"value": -10,
						"status": "Disappointed"
					}
				]
			}
		]
	}
	generator.current_dilemma = test_dilemma
	var teammate_system = ServiceLocator.get_teammate_system()
	if teammate_system:
		teammate_system.update_relationship("player", "gloria", "Neutral", 0) 
		teammate_system.update_relationship("gloria", "player", "Neutral", 0)
		teammate_system._team_relationships["player"]["gloria"]["value"] = 0
		teammate_system._team_relationships["gloria"]["player"]["value"] = 0
	generator.resolve_dilemma("choice_1")
	var player_to_gloria = teammate_system.get_relationships_for("player").get("gloria", {})
	var gloria_to_player = teammate_system.get_relationships_for("gloria").get("player", {})
	print("Player -> Gloria: ", player_to_gloria)
	print("Gloria -> Player: ", gloria_to_player)
	if player_to_gloria.get("status") == "Disappointed" and player_to_gloria.get("value") == -10:
		print("❌ BUG CONFIRMED: Player -> Gloria was updated with 'Disappointed'")
		_failed = true
	else:
		print("✅ Player -> Gloria was NOT updated (or updated differently)")
	if gloria_to_player.get("status") == "Disappointed" and gloria_to_player.get("value") == -10:
		print("✅ Gloria -> Player was updated with 'Disappointed' (Correct)")
	else:
		print("❌ Gloria -> Player was NOT updated correctly")
		_failed = true
