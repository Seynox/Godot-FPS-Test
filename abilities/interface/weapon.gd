class_name Weapon extends Ability

signal attack_started
signal attack_ended
signal attack_failed
signal attacked(enemy: Entity)

@export var ATTACK_DAMAGE: float
@export var ATTACK_RANGE: float

func get_ability_type() -> String:
	return str(Weapon)

func try_attack(_player: Player, _delta: float):
	pass

func get_velocity(player: Player, _delta: float) -> Vector3:
	return player.velocity

func hit_target(attacker: Player, target: Node3D):
	if target is Entity:
		attacked.emit(target)
	if target.has_method("try_getting_hit_by"):
		var is_successfull = target.try_getting_hit_by(attacker)
		if !is_successfull:
			attack_failed.emit()
		elif target is Entity:
			attacked.emit(target)
