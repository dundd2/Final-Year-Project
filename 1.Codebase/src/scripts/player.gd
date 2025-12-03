extends CharacterBody2D
func _physics_process(delta: float) -> void:
	var input_direction: Vector2 = _get_input_direction()
	var speed: float = GameConstants.Player.WALK_SPEED
	if Input.is_action_pressed("sprint"):
		speed *= GameConstants.Player.SPRINT_MULTIPLIER
	if input_direction != Vector2.ZERO:
		var target_velocity: Vector2 = input_direction.normalized() * speed
		velocity = velocity.move_toward(target_velocity, GameConstants.Player.ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, GameConstants.Player.DECELERATION * delta)
	move_and_slide()
func _get_input_direction() -> Vector2:
	var direction: Vector2 = Vector2.ZERO
	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return direction
func reset_motion() -> void:
	velocity = Vector2.ZERO
