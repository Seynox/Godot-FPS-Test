class_name CooldownWeapon extends Weapon

## Emitted when the cooldown finished
signal weapon_ready
## Emitted when the cooldown is set on cooldown
signal weapon_disabled(for_seconds: float)

## The weapon cooldown between uses, in seconds
@export var WEAPON_COOLDOWN: float = 1

## The cooldown timer
var cooldown: Timer

func _ready():
	cooldown = _create_timer(WEAPON_COOLDOWN)
	cooldown.timeout.connect(_on_cooldown_end)
	
func _create_timer(time: float) -> Timer:
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = time
	add_child(timer)
	return timer

func _can_execute(player: Player) -> bool:
	return not is_on_cooldown() and super(player)

# Cooldown

func is_on_cooldown() -> bool:
	return not cooldown.is_stopped()

## Called when the cooldown timer ends
func _on_cooldown_end():
	weapon_ready.emit()

## Starts the cooldown. Restart the cooldown if it was already started
func _start_cooldown():
	cooldown.start()
	weapon_disabled.emit(cooldown.wait_time)
