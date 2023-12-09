class_name Jump extends Node

signal jump_ready
signal jump_disabled
signal jump_started
signal jump_ended
signal jump_failed

@export var JUMP_HEIGHT: float # In meters

var is_jumping: bool = false
var can_jump: bool = true

func try_jump():
	pass

# Override this!
func get_velocity(entity: Entity, _delta: float) -> Vector3:
	return entity.velocity
