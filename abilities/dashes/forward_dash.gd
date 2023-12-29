class_name ForwardDash extends TimedDash

func _execute(player: Player, delta: float):
	super(player, delta)
	dash_velocity = _get_dash_velocity(player.camera)

func _on_player_physics(player: Player, delta: float):
	super(player, delta)
	if is_dashing():
		player.velocity = dash_velocity

func _get_dash_velocity(camera: Camera3D) -> Vector3:
	var dash_vector: Vector3 = Vector3(0, 0, DASH_SPEED * -1)
	return camera.global_transform.basis * dash_vector
