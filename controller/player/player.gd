class_name Player extends Entity

@export_category("Player")
@export_range(10, 400, 1) var acceleration: float = 100 # m/s^2

@export_subgroup("Abilities")
@export var DEFAULT_DASH: PackedScene
@export var DEFAULT_JUMP: PackedScene
@export var DEFAULT_WEAPON: PackedScene

var movement_velocity: Vector3

@onready var camera: Camera3D = $Camera
@onready var input := $PlayerInput
@onready var abilities := $Abilities

var dash: Dash
var jump: Jump
var weapon: Weapon

func _enter_tree():
	var player_peer = str(name).to_int()
	set_multiplayer_authority(player_peer)

func _ready() -> void:
	var is_local_player: bool = is_multiplayer_authority()
	$Camera.current = is_local_player
	set_process(is_local_player)
	set_physics_process(is_local_player)
	
	if !is_local_player:
		return
	
	if DEFAULT_DASH != null:
		dash = _put_ability(dash, DEFAULT_DASH.instantiate())
	if DEFAULT_JUMP != null:
		jump = _put_ability(jump, DEFAULT_JUMP.instantiate())
	if DEFAULT_WEAPON != null:
		weapon = _put_ability(weapon, DEFAULT_WEAPON.instantiate())

func _process(delta: float):
	_process_abilities_inputs(delta)

func _process_abilities_inputs(delta: float):
	if input.dashing and dash != null:
		dash.try_dash()
		input.dashing = false
	
	if input.jumping and jump != null:
		jump.try_jump()
		input.jumping = false
	
	if input.attacking and weapon != null:
		weapon.try_attack(self, delta)
		input.attacking = false

func _physics_process(delta: float):
	# Apply camera rotation
	camera.rotation.x = input.camera_rotation.x
	camera.rotation.y = input.camera_rotation.y
	
	# Calculate forces
	velocity = _calculate_movement_velocity(delta)
	gravity_velocity = _calculate_gravity_velocity(delta)
	velocity += gravity_velocity
		
	_process_abilities_physics(delta)
	super._physics_process(delta)

func _calculate_movement_velocity(delta: float) -> Vector3:
	var movement_direction: Vector3 = Vector3(input.movement_direction.x, 0, input.movement_direction.y)
	var movement_vector_raw: Vector3 = camera.global_transform.basis * movement_direction
	movement_vector_raw.y = 0
	
	var movement_vector: Vector3 = movement_vector_raw.normalized() * SPEED * input.movement_direction.length()
	movement_velocity = movement_velocity.move_toward(movement_vector, acceleration * delta)
	return movement_velocity

func _process_abilities_physics(delta: float):
	if dash != null:
		velocity = dash.get_velocity(self, delta)
	if jump != null:
		velocity = jump.get_velocity(self, delta)
	if weapon != null:
		velocity = weapon.get_velocity(self, delta)

#
# ABILITIES
#

func _put_ability(current: Node, new: Node) -> Node:
	var old = current
	if new != null:
		var player_peer: int = get_multiplayer_authority()
		new.set_multiplayer_authority(player_peer)
		if current == null:
			abilities.add_child(new)
		else:
			current.replace_by(new)
		return new

	old.queue_free()
	return null
