class_name Dash extends Node

signal dash_started
signal dash_ended
signal dash_ready
signal dash_disabled
signal dash_failed

@export var DASH_SPEED: float # In meters per seconds
@export var DASH_COOLDOWN: float # In seconds

var cooldown: Timer

var is_on_cooldown: bool = false
var is_dashing: bool = false

func _ready():
	cooldown = _create_timer(DASH_COOLDOWN)
	cooldown.timeout.connect(_enable_dash)

func _create_timer(time: float) -> Timer:
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = time
	add_child(timer)
	return timer

@rpc("call_local", "reliable")
func set_speed(meters_per_sec: float):
	DASH_SPEED = meters_per_sec

func set_cooldown(seconds: float):
	DASH_COOLDOWN = seconds
	cooldown.wait_time = seconds

func try_dash():
	if !is_on_cooldown:
		_start_dash()
		_start_cooldown()
	else:
		dash_failed.emit()

# Override this! (Called everytime in player's _physics_process)
func get_velocity(player: Player, _delta: float) -> Vector3:
	return player.velocity

func _enable_dash():
	is_on_cooldown = false
	dash_ready.emit()

func _disable_dash():
	is_on_cooldown = true
	dash_disabled.emit()

func _start_dash():
	is_dashing = true
	dash_started.emit()

func _stop_dash():
	is_dashing = false
	dash_ended.emit()

func _start_cooldown():
	_disable_dash()
	cooldown.start()
