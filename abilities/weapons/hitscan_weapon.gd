class_name HitscanWeapon extends CooldownWeapon

func _attack(player: Player, _delta: float):
	attack_started.emit()
	var aimed_entity: Entity = _get_aimed_entity(player.camera)
	if aimed_entity != null:
		_apply_damages(player, aimed_entity)

func _get_aimed_entity(camera: Camera3D) -> Entity:
	var mouse_position = get_viewport().get_mouse_position() # TODO Check if it works in multiplayer
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_max = ray_origin + camera.project_ray_normal(mouse_position) * self.ATTACK_RANGE
	
	var ray = PhysicsRayQueryParameters3D.create(ray_origin, ray_max)
	ray.collide_with_areas = true
	ray.exclude = [self]
	
	var space = camera.get_world_3d().direct_space_state
	var result = space.intersect_ray(ray)
	var collidedNode = result.get("collider")
	
	if collidedNode != null && collidedNode is Entity:
		return collidedNode
	return null

func _apply_damages(player: Player, entity_attacked: Entity):
	attacked.emit(entity_attacked)
	entity_attacked.take_hit_from(player, ATTACK_DAMAGE)
