class_name ForwardDash extends ToggledDash

func get_velocity(player: Player, _delta: float) -> Vector3:
	if !is_dashing:
		return player.velocity
	var velocity = _calculate_dash_velocity(player.camera)
	return player.velocity + velocity

func _calculate_dash_velocity(camera: Camera3D) -> Vector3:
	if DASH_SPEED == 0:
		return Vector3.ZERO
	return camera.global_transform.basis * Vector3(0, 0, DASH_SPEED * -1)
