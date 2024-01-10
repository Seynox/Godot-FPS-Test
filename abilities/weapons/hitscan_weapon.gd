extends RangedWeapon

func _spawn_bullet(starting_position: Vector3, direction: Basis):
	# TODO Refactor & Raycast in physics process instead
	var forward_range: Vector3 = -direction.z * ATTACK_RANGE
	var end_position: Vector3 = starting_position + forward_range
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(starting_position, end_position)
	
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var collided_object: Node3D = space.intersect_ray(query).get("collider")
	if collided_object != null and collided_object.has_method("try_hitting"):
		collided_object.try_hitting()
	
	super(starting_position, direction)
