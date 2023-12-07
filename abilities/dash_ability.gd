class_name Dash extends Node

signal dash_started
signal dash_ended
signal dash_ready
signal dash_disabled
signal dash_failed

@export var DASH_DISTANCE: float = 6 # In meters

@onready var cooldown: Timer = $Cooldown
@onready var duration: Timer = $Duration

var can_dash: bool = true
var is_dashing: bool = false

func _ready():
	cooldown.timeout.connect(_enable_dash)
	duration.timeout.connect(_stop_dash)

func try_dash():
	if can_dash:
		_start_cooldown()
		_start_dash()
	else:
		dash_failed.emit()

func get_velocity(player: Player, _delta: float) -> Vector3:
	if is_dashing:
		return _calculate_dash_velocity(player.camera)
	return player.velocity

func _calculate_dash_velocity(camera: Camera3D) -> Vector3:
	var dash_duration = duration.get_wait_time()
	var dash_speed = DASH_DISTANCE / dash_duration
	return camera.global_transform.basis * Vector3(0, 0, dash_speed * -1)

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
