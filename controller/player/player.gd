class_name Player extends Entity
# TODO Fix multiplayer lag handling

signal shooting

@export_category("Player")
@export_range(10, 400, 1) var acceleration: float = 100 # m/s^2
@export var shooting_cooldown: float = 0.2 # In seconds
@export var player_peer: int = 1: # Multiplayer peer_id (Default to server id)
	set(id):
		player_peer = id
		$PlayerInput.set_multiplayer_authority(id)

@export_subgroup("Abilities")
@export var DEFAULT_DASH: PackedScene
@export var DEFAULT_JUMP: PackedScene

var can_shoot: bool = true
var movement_velocity: Vector3

@onready var camera: Camera3D = $Camera
@onready var input := $PlayerInput
@onready var abilities := $Abilities

var dash: Dash
var jump: Jump

func _ready() -> void:
	var is_local_player: bool = player_peer == multiplayer.get_unique_id()
	camera.current = is_local_player
	
	if DEFAULT_DASH != null:
		dash = _put_ability(dash, DEFAULT_DASH.instantiate())
	if DEFAULT_JUMP != null:
		jump = _put_ability(jump, DEFAULT_JUMP.instantiate())

func _process(_delta):
	if input.shooting:
		shoot()

func _physics_process(delta: float):
	# Apply camera rotation
	camera.rotation.x = input.camera_rotation.x
	camera.rotation.y = input.camera_rotation.y
	
	# Calculate forces
	velocity = _calculate_velocity(delta)
	gravity_velocity = _calculate_gravity_velocity(delta)
	velocity += gravity_velocity
		
	_process_abilities_physics(delta)
	super._physics_process(delta)

func _process_abilities_physics(delta: float):
	# Dash
	if dash != null:
		_process_dash_physics(delta)
	if jump != null:
		_process_jump_physics(delta)

#
# ABILITIES
#

func _process_dash_physics(delta: float):
	if input.dashing:
		dash.try_dash()
		input.dashing = false
	velocity = dash.get_velocity(self, delta)

func _process_jump_physics(delta: float):
	if input.jumping:
		jump.try_jump()
		input.jumping = false
	velocity = jump.get_velocity(self, delta)

func _put_ability(current: Node, new: Node) -> Node:
	if current == null and new != null:
		abilities.add_child(new)
		return new
	
	var old = current	
	if new != null:
		current.replace_by(new)
		return new

	old.queue_free()
	return null
#
# PLAYER
#

func shoot_coolown() -> void:
	can_shoot = false
	get_tree().create_timer(shooting_cooldown).timeout.connect(func(): can_shoot = true)

func shoot():
	input.shooting = false
	if !can_shoot:
		return
	
	shooting.emit()
	var mouse_position = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_max = ray_origin + camera.project_ray_normal(mouse_position) * self.ATTACK_DISTANCE
	
	var ray = PhysicsRayQueryParameters3D.create(ray_origin, ray_max)
	ray.collide_with_areas = true
	ray.exclude = [self]
	
	var space = get_world_3d().direct_space_state
	var result = space.intersect_ray(ray)
	var collidedNode = result.get("collider")
	
	if collidedNode != null && collidedNode is Entity:
		collidedNode.take_hit_from(self)
	
	shoot_coolown()

#
# MOVEMENTS
#
	

func _calculate_velocity(delta: float) -> Vector3:
	# Movements velocity
	var movement_vector_raw: Vector3 = camera.global_transform.basis * Vector3(input.movement_direction.x, 0, input.movement_direction.y)
	movement_vector_raw.y = 0
	
	var movement_vector: Vector3 = movement_vector_raw.normalized() * SPEED * input.movement_direction.length()
	movement_velocity = movement_velocity.move_toward(movement_vector, acceleration * delta)
	
	return movement_velocity
