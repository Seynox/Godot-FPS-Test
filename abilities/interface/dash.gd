class_name Dash extends Ability

signal dash_started
signal dash_ended
signal dash_failed

@export var DASH_SPEED: float # In meters per seconds

var is_dashing: bool = false

func get_ability_type() -> String:
	return str(Dash)

@rpc("call_local", "reliable")
func set_speed(meters_per_sec: float):
	DASH_SPEED = meters_per_sec

func try_dash(_entity: Entity):
	pass

# Override this! (Called everytime in player's _physics_process)
func get_velocity(player: Player, _delta: float) -> Vector3:
	return player.velocity

func _start_dash():
	is_dashing = true
	dash_started.emit()

func _stop_dash():
	is_dashing = false
	dash_ended.emit()
