class_name CooldownAbility extends Ability

## Emitted when the ability cooldown ends.
signal cooldown_ended
## Emitted when the ability cooldown starts.[br]
## [param duration] is the cooldown duration is seconds.
signal cooldown_started(duration: float)

## The ability cooldown in seconds.
@export var COOLDOWN: float = 1.0

## The cooldown timer. Null if [member CooldownAbility.COOLDOWN] is 0 or less.
var cooldown_timer: Timer

func _ready():
	if COOLDOWN <= 0: return
	cooldown_timer = _create_timer(COOLDOWN)
	cooldown_timer.timeout.connect(_on_cooldown_end)

func _create_timer(time: float) -> Timer:
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = time
	add_child(timer)
	return timer

#
# Cooldown start/end
#

## Start the ability cooldown.[br]
## Does not check if the ability is already in cooldown.
func start_cooldown():
	if COOLDOWN <= 0:
		_on_cooldown_end()
		return
	cooldown_timer.start()
	cooldown_started.emit(cooldown_timer.wait_time)

## End a cooldown.[br]
## Called on [member CooldownAbility.cooldown_timer] timeout signal.
## Called when trying to start a 0s cooldown, with a null [member CooldownAbility.cooldown_timer].
func _on_cooldown_end():
	reload()
	cooldown_ended.emit()
	
	if cooldown_timer != null and not has_maximum_uses():
		start_cooldown()
