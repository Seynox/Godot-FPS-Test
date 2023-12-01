class_name Enemy extends Entity

var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var HIT_DISTANCE: float = 1.5

@export var TARGET: Entity = null

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	if(TARGET == null):
		TARGET = get_closest_target()
	
	if(TARGET != null):
		hit_target_in_range()
		if TARGET.is_dead():
			TARGET = null
		else:
			chase_target()
	
	move_and_slide()

func hit_target_in_range():
	var distance = global_position.distance_squared_to(TARGET.global_position)
	if distance <= HIT_DISTANCE:
		TARGET.take_hit_from(self)

func chase_target() -> void:
	var direction = global_position.direction_to(TARGET.global_position).normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	
func get_closest_target() -> Entity:
	print("Getting closest alive player")
	return null
