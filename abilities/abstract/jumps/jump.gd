class_name Jump extends Ability

const TYPE: String = "Jump"

## The speed of the jump in meters per second.
@export var JUMP_SPEED: float = 20.0

## If the first jump can be started in the air
@export var STARTABLE_IN_AIR: bool

## The current jump velocity
var jump_velocity: Vector3

## If the ability owner is in the air because of a jump.
var is_jumping: bool

func get_ability_type() -> String:
	return TYPE

func _cancel_ability():
	is_jumping = false
	jump_velocity = Vector3.ZERO

func _can_execute(player: Player) -> bool:
	var can_jump: bool = is_jumping or player.is_on_floor() or STARTABLE_IN_AIR
	return can_jump and super(player)

func _handle_player_inputs(player: Player, delta: float, input: Dictionary):
	if input.get("jump"):
		try_executing(player, delta)
