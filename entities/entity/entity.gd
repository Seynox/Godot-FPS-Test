class_name Entity extends CharacterBody3D

@export_category("Entity")
@export var HEALTH: float = 1.0
@export var DAMAGES_ON_HIT: float = 1.0
@export var SPEED: float = 5.0
@export var JUMP_VELOCITY: float = 4.5

# Health
func set_health(new_health: float) -> void:
	if new_health <= 0:
		HEALTH = 0
		die()
	else:
		HEALTH = new_health


# Damage

func is_dead() -> bool:
	return HEALTH <= 0

func die() -> void:
	self.queue_free() # Removes entity from scene

func take_hit_from(source: Entity, multiplicator: float = 1) -> void:
	var damages = source.DAMAGES_ON_HIT * multiplicator
	var new_health = HEALTH - damages
	set_health(new_health)
