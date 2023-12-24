class_name CooldownWeapon extends Weapon

signal weapon_ready
signal weapon_disabled(for_seconds: float)

@export var WEAPON_COOLDOWN: float # In seconds

var is_on_cooldown: bool = false

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

# Attack

func try_attack(player: Player, delta: float):
	if not is_on_cooldown:
		_attack(player, delta)
	else:
		attack_failed.emit()

func _attack(_player: Player, _delta: float):
	pass

# Cooldown

func _on_cooldown_end():
	is_on_cooldown = false
	weapon_ready.emit()
	
func _start_cooldown():
	is_on_cooldown = true
	cooldown.start()
	weapon_disabled.emit(cooldown.wait_time)
