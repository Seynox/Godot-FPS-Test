class_name HitscanWeapon extends CooldownWeapon
# TODO Add ammos

func _attack(player: Player, _delta: float):
	attack_started.emit()
	var aimed_object: Node3D = _get_aimed_object(player.camera)
	if aimed_object != null:
		_apply_damages(player, aimed_object)

func _get_aimed_object(camera: Camera3D) -> Node3D:
	var mouse_position = get_viewport().get_mouse_position() # TODO Check if it works in multiplayer
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_max = ray_origin + camera.project_ray_normal(mouse_position) * self.ATTACK_RANGE
	
	var ray = PhysicsRayQueryParameters3D.create(ray_origin, ray_max)
	ray.collide_with_areas = true
	ray.exclude = [self]
	
	var space = camera.get_world_3d().direct_space_state
	var result = space.intersect_ray(ray)
	return result.get("collider")

func _apply_damages(player: Player, object_attacked: Node3D): # TODO Make a damageable class? Refactor to weapon interface
	if object_attacked is Entity:
		attacked.emit(object_attacked)
		object_attacked.take_hit_from(player, ATTACK_DAMAGE)
	elif object_attacked is BreakableInteractible:
		object_attacked.try_hitting(player)
