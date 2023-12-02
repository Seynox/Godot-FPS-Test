class_name Entity extends CharacterBody3D

@export_category("Entity")
@export var HEALTH: float = 1.0
@export var SPEED: float = 10 # In meters per second
@export var ATTACK_DISTANCE: float = 1.5
@export var DAMAGES_ON_HIT: float = 1.0
@export var CAN_BE_HIT: bool = true
@export var GRAVITY_MULTIPLIER: float = 1.0

var GRAVITY: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_velocity: Vector3 = Vector3.ZERO

# Movements

func _physics_process(delta: float):
	if global_position.y <= -10:
		_die()
	
	_apply_gravity(delta)
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	var gravity_force = GRAVITY * GRAVITY_MULTIPLIER
	if is_on_floor() and gravity_force >= 0:
		gravity_velocity = Vector3.ZERO
	else:
		gravity_velocity = gravity_velocity.move_toward(Vector3(0, velocity.y - gravity_force, 0), gravity_force * delta)
		
	velocity += gravity_velocity

func walk_towards(pos: Vector3) -> void:
	var direction = global_position.direction_to(pos).normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED

# Health

func _set_health(new_health: float) -> void:
	HEALTH = new_health

func reduce_health(damages: float) -> void:
	var new_health = HEALTH - damages
	if new_health <= 0:
		_die()
	
	_set_health(new_health)

func is_dead() -> bool:
	return HEALTH <= 0

func _die() -> void:
	HEALTH = 0
	self.queue_free() # Removes entity from scene

func take_hit_from(source: Entity, multiplicator: float = 1) -> void:
	if CAN_BE_HIT:
		reduce_health(source.DAMAGES_ON_HIT * multiplicator)
