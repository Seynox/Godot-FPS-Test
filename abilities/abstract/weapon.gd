class_name Weapon extends Ability

const TYPE: String = "Weapon"

signal attack_started
signal attack_ended
signal attack_failed

@export var ATTACK_DAMAGE: float
@export var ATTACK_RANGE: float

func get_ability_type() -> String:
	return TYPE

func try_attack(_player: Player, _delta: float):
	pass

func get_velocity(player: Player, _delta: float) -> Vector3:
	return player.velocity

func hit_target(target: Node3D):
	if target.has_method("try_hitting"):
		var authority_id: int = target.get_multiplayer_authority()
		target.try_hitting.rpc_id(authority_id)
