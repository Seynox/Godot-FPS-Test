class_name Weapon extends Ability

const TYPE: String = "Weapon"

@export var ATTACK_DAMAGE: float = 1
@export var ATTACK_RANGE: float = 50

func _get_unique_type() -> String:
	return TYPE

func _handle_player_inputs(player: Player, delta: float, inputs: Dictionary):
	if inputs.get("attack", false):
		try_executing(player, delta)

## Make the ability owner hit the target if the target is hittable
func hit_target(target: Node3D):
	if target.has_method("try_hitting"):
		target.try_hitting(self.owner_peer)
