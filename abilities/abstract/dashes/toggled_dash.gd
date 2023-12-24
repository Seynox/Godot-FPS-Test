class_name ToggledDash extends CooldownDash

@export var DASH_DURATION: float # In seconds

var duration: Timer

func _ready():
	duration = _create_timer(DASH_DURATION)
	duration.timeout.connect(_stop_dash)
	super()

func set_duration(seconds: float):
	DASH_DURATION = seconds
	duration.wait_time = seconds

func _start_dash():
	duration.start()
	super()
