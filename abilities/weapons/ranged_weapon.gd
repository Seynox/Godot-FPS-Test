class_name RangedWeapon extends CooldownWeapon

## Emitted when the weapon successfully tries to reload.[br]
## Used to play the reloading animation which will call [method Ability.reload]
signal reloading

## The bullets that gets spawned when shooting
@export var BULLET_SCENE: PackedScene

## If the current weapon is reloading
var is_reloading: bool

#
# Shooting
#

func _can_execute(player: Player):
	return not is_reloading and super(player)

func _execute(player: Player, _delta: float):
	_start_cooldown()
	if player.is_local_player:
		shoot_in_direction.rpc(player.camera.global_position, player.camera.global_transform.basis)

@rpc("any_peer", "call_local", "reliable")
func shoot_in_direction(shooter_position: Vector3, direction: Basis):
	_spawn_bullet(shooter_position, direction)

func _spawn_bullet(starting_position: Vector3, direction: Basis):
	var bullet: Bullet = BULLET_SCENE.instantiate()
	add_child(bullet)
	bullet.global_position = starting_position
	bullet.global_transform.basis = direction

#
# Reloading
#

func _handle_player_inputs(player: Player, delta: float, inputs: Dictionary):
	super(player, delta, inputs)
	if inputs.get("reload"):
		try_reloading()

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
