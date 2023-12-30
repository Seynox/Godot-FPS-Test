class_name ImpulseDash extends Dash

## The friction applies to the dash velocity when the ability owner is on the floor
@export var FRICTION_FORCE: float

func _execute(player: Player, _delta: float):
	dash_velocity = _get_impulse_velocity(player.camera)
	player.gravity_velocity = Vector3.ZERO
	start_recharging()

#
# Physics
#

func _on_player_physics(player: Player, delta: float):
	super(player, delta)
	player.velocity += dash_velocity
	dash_velocity = _calculate_dash_velocity(player, delta)

func _get_impulse_velocity(camera: Camera3D) -> Vector3:
	return camera.global_transform.basis * Vector3(0, 0, -DASH_SPEED)

func _calculate_dash_velocity(player: Player, delta: float) -> Vector3:
	var deceleration: float = DASH_SPEED
	if player.is_on_floor():
		deceleration += FRICTION_FORCE
	
	return dash_velocity.move_toward(Vector3.ZERO, deceleration * delta)
