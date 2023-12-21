class_name SimpleJump extends Jump

var jump_velocity: Vector3

func try_jump(entity: Entity):
	if can_jump and entity.is_on_floor():
		_start_jump()
		_disable_jump()
	else:
		jump_failed.emit()

func get_velocity(entity: Entity, delta: float) -> Vector3:
	if !can_jump and entity.is_on_floor():
		_enable_jump()
	
	if is_jumping:
		jump_velocity = _get_jump_velocity(entity)
		_stop_jump()
		_disable_jump()
		var final_velocity: Vector3 = entity.velocity
		final_velocity.y = jump_velocity.y
		return final_velocity
	
	jump_velocity = _calculate_jump_velocity(entity, delta)
	return entity.velocity + jump_velocity

func _get_jump_velocity(entity: Entity) -> Vector3:
	var upward_velocity: float = sqrt(4 * JUMP_HEIGHT * entity.GRAVITY)
	return Vector3(0, upward_velocity, 0)

func _calculate_jump_velocity(entity: Entity, delta: float) -> Vector3:
	if entity.is_on_floor():
		return Vector3.ZERO
	var gravity_force: float = entity.GRAVITY * entity.GRAVITY_MULTIPLIER
	return jump_velocity.move_toward(Vector3.ZERO, gravity_force * delta)

func _start_jump():
	is_jumping = true
	jump_started.emit()

func _disable_jump():
	can_jump = false
	jump_disabled.emit()

func _stop_jump():
	is_jumping = false
	jump_ended.emit()

func _enable_jump():
	can_jump = true
	jump_ready.emit()
