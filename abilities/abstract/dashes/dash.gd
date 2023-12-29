class_name Dash extends CooldownAbility

const TYPE: String = "Dash"

## The dashing speed in meters per second
@export var DASH_SPEED: float = 50

## The current dash velocity
var dash_velocity: Vector3

func get_ability_type() -> String:
	return TYPE

func _cancel_ability():
	dash_velocity = Vector3.ZERO
