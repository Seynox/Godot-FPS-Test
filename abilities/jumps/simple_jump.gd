class_name SimpleJump extends Jump

func _execute(player: Player, _delta: float):
	is_jumping = true
	jump_velocity = _get_jump_velocity()
	player.gravity_velocity = Vector3.ZERO

func _on_player_physics(player: Player, delta: float):
	player.velocity += jump_velocity
	var finished_jump: bool = player.is_on_floor() and player.velocity.y <= 0.0
	
	if is_jumping and finished_jump:
		is_jumping = false
		jump_velocity = Vector3.ZERO
		reload()
	else:
		var gravity_force: float = player.GRAVITY * player.GRAVITY_MULTIPLIER
		jump_velocity = jump_velocity.move_toward(Vector3.ZERO, gravity_force * delta)

func _get_jump_velocity() -> Vector3:
	return Vector3(0, JUMP_SPEED, 0)
