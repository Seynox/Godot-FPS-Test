class_name TimedDash extends Dash

## The dash duration in seconds. Should not be 0 or less.
@export_range(0.1, 99) var DASH_DURATION: float = 0.1

## The timer representing the dash duration.[br]
## Stops dashing on timeout.
var dash_timer: Timer

func _ready():
	super()
	dash_timer = _create_timer(DASH_DURATION)
	dash_timer.timeout.connect(_on_dash_timeout)

func _cancel_ability():
	super()
	dash_timer.stop()
	_on_dash_timeout()

func _execute(_player: Player, _delta: float):
	dash_timer.start()

func _on_player_physics(player: Player, _delta: float):
	if is_dashing():
		player.gravity_velocity = Vector3.ZERO

func _on_dash_timeout():
	start_recharging()

func is_dashing() -> bool:
	return not dash_timer.is_stopped()
