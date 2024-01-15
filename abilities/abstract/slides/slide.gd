extends Ability

const TYPE: String = "slide"

@export var FLOOR_FRICTION: float = 0.1
@export var INITIAL_SPEED_BOOST: float = 2.0

var slide_velocity: Vector3

func _get_unique_type() -> String:
	return TYPE

func _handle_player_inputs(player: Player, delta: float, inputs: Dictionary):
	if inputs.get("slide", false):
		try_executing(player, delta)

func _cancel_ability():
	slide_velocity = Vector3.ZERO
