class_name Dash extends Node

signal dash_started
signal dash_ended
signal dash_ready
signal dash_disabled
signal dash_failed

@export var DASH_DISTANCE: float # In meters
@export var DASH_COOLDOWN: float # In seconds
@export var DASH_DURATION: float # In seconds

var cooldown: Timer
var duration: Timer

var can_dash: bool = true
var is_dashing: bool = false

func _ready():
	cooldown = _create_timer(DASH_COOLDOWN)
	cooldown.timeout.connect(_enable_dash)
	
	duration = _create_timer(DASH_DURATION)
	duration.timeout.connect(_stop_dash)

func _create_timer(time: float) -> Timer:
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = time
	add_child(timer)
	return timer

func set_cooldown(seconds: float):
	DASH_COOLDOWN = seconds
	cooldown.wait_time = seconds

func set_duration(seconds: float):
	DASH_DURATION = seconds
	duration.wait_time = seconds

@rpc("call_local", "reliable")
func set_distance(meters: float):
	DASH_DISTANCE = meters

func try_dash():
	if can_dash:
		_start_cooldown()
		_start_dash()
	else:
		dash_failed.emit()

# Override this!
func get_velocity(player: Player, _delta: float) -> Vector3:
	return player.velocity

func _enable_dash():
	can_dash = true
	dash_ready.emit()

func _disable_dash():
	can_dash = false
	dash_disabled.emit()

func _start_cooldown():
	_disable_dash()
	cooldown.start()

func _start_dash():
	is_dashing = true
	duration.start()
	dash_started.emit()

func _stop_dash():
	is_dashing = false
	dash_ended.emit()
