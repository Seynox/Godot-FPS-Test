class_name Enemy extends Entity

@export_category("Enemy")
@export var TARGET: Entity

func _physics_process(delta):
	if(TARGET == null):
		TARGET = get_closest_target()
	
	if(TARGET != null):
		_hit_target_in_range()
		if TARGET.is_dead():
			TARGET = null
		else:
			walk_towards(TARGET.global_position)
	
	super._physics_process(delta)

func _hit_target_in_range():
	var distance = global_position.distance_squared_to(TARGET.global_position)
	if distance <= self.HIT_DISTANCE:
		TARGET.take_hit_from(self)

func get_closest_target() -> Entity:
	print("Getting closest alive player")
	var players = get_tree().get_nodes_in_group("Player")
	var distance_sorting = func(player: Player): return global_position.distance_squared_to(player.global_position)
	players.sort_custom(distance_sorting)
	return players[0]
