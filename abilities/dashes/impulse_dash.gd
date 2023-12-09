class_name ImpulseDash extends CooldownDash
# Gives a speed impulse to the player

var dash_velocity: Vector3
var can_dash: bool = true # Disallow dashing mutliple times in the air

func try_dash():
	if can_dash:
		super.try_dash()
	else:
		dash_failed.emit()

func get_velocity(player: Player, delta: float) -> Vector3:
	if !can_dash and player.is_on_floor(): # Allow dashing after touching the floor
		can_dash = true
	
	if is_dashing:
		dash_velocity = _get_impulse_velocity(player.camera)
		_stop_dash()
	else:
		dash_velocity = _calculate_dash_velocity(delta)
	return player.velocity + dash_velocity

func _get_impulse_velocity(camera: Camera3D) -> Vector3:
	return camera.global_transform.basis * Vector3(0, 0, DASH_SPEED * -1)

func _calculate_dash_velocity(delta: float) -> Vector3:
	return dash_velocity.move_toward(Vector3.ZERO, DASH_SPEED * delta)

func _start_cooldown():
	can_dash = false
	super._start_cooldown()
