class_name ToggledDash extends Dash

@export var DASH_DURATION: float # In seconds

var duration: Timer

func _ready():
	duration = _create_timer(DASH_DURATION)
	duration.timeout.connect(_stop_dash)
	super._ready()

func set_duration(seconds: float):
	DASH_DURATION = seconds
	duration.wait_time = seconds

func _start_dash():
	duration.start()
	super._start_dash()
