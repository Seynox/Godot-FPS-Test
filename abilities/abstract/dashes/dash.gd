class_name Dash extends RechargingAbility

const TYPE: String = "Dash"

## The dashing speed in meters per second
@export var DASH_SPEED: float = 50

## The current dash velocity
var dash_velocity: Vector3

func _get_unique_type() -> String:
	return TYPE

func _handle_player_inputs(player: Player, delta: float, input: Dictionary):
	if input.get("dash"):
		try_executing(player, delta)

func _cancel_ability():
	dash_velocity = Vector3.ZERO
