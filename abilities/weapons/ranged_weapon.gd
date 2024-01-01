class_name RangedWeapon extends CooldownWeapon

## Emitted when the weapon successfully tries to reload.[br]
## Used to play the reloading animation which will call [method Ability.reload]
signal reloading

## If the current weapon is reloading
var is_reloading: bool

func _can_execute(player: Player):
	return not is_reloading and super(player)

func _execute(player: Player, _delta: float):
	_start_cooldown()
	if player.is_local_player:
		var aimed_object: Node3D = player.get_aimed_object(self.ATTACK_RANGE) # TODO Handle on server
		if aimed_object != null:
			hit_target(aimed_object)

## Called to try reloading manually. Will not reload if the weapon is already reloading.[br]
## If successfull, will emit [signal RangedWeapon.reloading]
func try_reloading():
	if not is_reloading and not has_maximum_uses():
		is_reloading = true
		reloading.emit()

func _set_uses(new_amount: int):
	if is_reloading and new_amount >= uses_left: # If the weapon just reloaded
		is_reloading = false 
	super(new_amount)

func _handle_player_inputs(player: Player, delta: float, inputs: Dictionary):
	super(player, delta, inputs)
	if inputs.get("reload"):
		try_reloading()
