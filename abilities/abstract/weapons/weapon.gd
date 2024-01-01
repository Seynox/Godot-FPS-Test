class_name Weapon extends Ability

const TYPE: String = "Weapon"

@export var ATTACK_DAMAGE: float
@export var ATTACK_RANGE: float

func get_ability_type() -> String:
	return TYPE

func _handle_player_inputs(player: Player, delta: float, inputs: Dictionary):
	if inputs.get("attack", false):
		try_executing(player, delta)

func hit_target(target: Node3D):
	if target.has_method("try_hitting"):
		var authority_id: int = target.get_multiplayer_authority()
		target.try_hitting.rpc_id(authority_id)
