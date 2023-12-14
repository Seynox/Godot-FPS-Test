class_name GameLevel extends Node3D

@export var LEVEL_NAME: String
@export var PLAYER_SPAWN: Node3D
@export var NEXT_LEVEL: PackedScene

@onready var players: Node3D = $/root/Game/Players

signal level_finished
signal game_over

func move_to_spawn(entity: Entity):
	var spawnpoint: Vector3 = PLAYER_SPAWN.global_position if PLAYER_SPAWN != null else Vector3.ZERO
	entity.global_position = spawnpoint
