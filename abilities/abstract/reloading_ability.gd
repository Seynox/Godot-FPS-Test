class_name RechargingAbility extends Ability

## Emitted when the ability recharged once.
signal recharged
## Emitted when the ability start recharging.[br]
## [param duration] is the recharging duration is seconds.
signal recharge_started(duration: float)

## The time it takes to recharge one use of the ability
@export var RECHARGE_TIME: float = 1.0

## The recharge timer. Null if [member RechargingAbility.RECHARGE_TIME] is 0 or less.
var recharge_timer: Timer

func _ready():
	if RECHARGE_TIME <= 0: return
	recharge_timer = _create_timer(RECHARGE_TIME)
	recharge_timer.timeout.connect(_on_recharge_end)

func _create_timer(time: float) -> Timer:
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = time
	add_child(timer)
	return timer

#
# Recharge start/end
#

## Start the ability recharge.[br]
## Does not check if the ability is already recharging.
func start_recharging():
	if RECHARGE_TIME <= 0:
		_on_recharge_end()
		return
	recharge_timer.start()
	recharge_started.emit(recharge_timer.wait_time)

## When a recharge finishes.[br]
## Called on [member RechargingAbility.recharge_timer] timeout signal.
func _on_recharge_end():
	reload()
	recharged.emit()
	
	if recharge_timer != null and not has_maximum_uses():
		start_recharging()
