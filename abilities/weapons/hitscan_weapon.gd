class_name HitscanWeapon extends CooldownWeapon

signal reloading

@export var MAXIMUM_AMMO: int

var is_reloading: bool
var current_ammo: int

func _ready():
	super()
	finish_reload()

func try_attack(player: Player, delta: float):
	if current_ammo > 0 and not is_reloading:
		super(player, delta)
	else:
		attack_failed.emit()

func _attack(player: Player, _delta: float):
	attacked.emit()
	current_ammo -= 1
	if player.is_local_player:
		var aimed_object: Node3D = player.get_aimed_object(self.ATTACK_RANGE)
		if aimed_object != null:
			hit_target(aimed_object)

func reload():
	if is_reloading or current_ammo == MAXIMUM_AMMO:
		return
	
	is_reloading = true
	reloading.emit()

func finish_reload():
	is_reloading = false
	current_ammo = MAXIMUM_AMMO
