class_name CooldownDash extends Dash

signal dash_ready
signal dash_disabled(for_seconds: float)

@export var DASH_COOLDOWN: float # In seconds

var cooldown: Timer
var is_on_cooldown: bool = false

func _ready():
	cooldown = _create_timer(DASH_COOLDOWN)
	cooldown.timeout.connect(_on_cooldown_end)

func _create_timer(time: float) -> Timer:
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = time
	add_child(timer)
	return timer

func set_cooldown(seconds: float):
	DASH_COOLDOWN = seconds
	cooldown.wait_time = seconds

func try_dash(_entity: Entity):
	if !is_on_cooldown:
		_start_dash()
		_start_cooldown()
	else:
		dash_failed.emit()

func _on_cooldown_end():
	is_on_cooldown = false
	dash_ready.emit()
	
func _start_cooldown():
	is_on_cooldown = true
	cooldown.start()
	dash_disabled.emit(cooldown.wait_time)
