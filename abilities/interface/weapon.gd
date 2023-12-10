class_name Weapon extends Ability

signal attack_started
signal attack_ended
signal attack_failed
signal attacked(enemy: Entity)

@export var ATTACK_DAMAGE: float
@export var ATTACK_RANGE: float

func try_attack(_player: Player, _delta: float):
	pass

func get_velocity(player: Player, _delta: float) -> Vector3:
	return player.velocity
