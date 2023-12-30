class_name SimpleJump extends Jump

var can_reset: bool = true # TODO Find a better way to avoid canceling jump on first tick

func _execute(player: Player, _delta: float):
	is_jumping = true
	jump_velocity = _get_jump_velocity()
	player.gravity_velocity = Vector3.ZERO
	can_reset = false

func _on_player_physics(player: Player, delta: float):
	player.velocity += jump_velocity
	
	if player.is_on_floor() and can_reset:
		is_jumping = false
		jump_velocity = Vector3.ZERO
		reload()
	else:
		can_reset = true
		var gravity_force: float = player.GRAVITY * player.GRAVITY_MULTIPLIER
		jump_velocity = jump_velocity.move_toward(Vector3.ZERO, gravity_force * delta)

func _get_jump_velocity() -> Vector3:
	return Vector3(0, JUMP_SPEED, 0)
