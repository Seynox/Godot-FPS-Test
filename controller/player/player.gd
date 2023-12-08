class_name Player extends Entity

signal shooting
signal jumping

@export_category("Player")
@export_range(10, 400, 1) var acceleration: float = 100 # m/s^2
@export_range(0.1, 3.0, 0.1) var jump_height: float = 1 # In meters
@export var shooting_cooldown: float = 0.2 # In seconds
@export var player_peer: int = 1: # Multiplayer peer_id (Default to server id)
	set(id):
		player_peer = id
		$PlayerInput.set_multiplayer_authority(id)

var can_shoot: bool = true
var movement_velocity: Vector3
var jump_velocity: Vector3

@onready var camera: Camera3D = $Camera
@onready var input := $PlayerInput
@onready var dash: Dash = $Abilities/Dash

func _ready() -> void:
	var is_local_player: bool = player_peer == multiplayer.get_unique_id()
	camera.current = is_local_player

func _process(_delta):
	if input.shooting:
		shoot()

func _physics_process(delta: float):
	# Apply camera rotation
	camera.rotation.x = input.camera_rotation.x
	camera.rotation.y = input.camera_rotation.y
	
	velocity = _calculate_velocity(delta)
	gravity_velocity = _calculate_gravity_velocity(delta)
	velocity += gravity_velocity
	
	if input.jumping:
		jump()
	if input.dashing:
		dash.try_dash()
		input.dashing = false

	velocity = dash.get_velocity(self, delta)
	super._physics_process(delta)

#
# ABILITIES
#

@rpc("call_local", "reliable")
func replace_dash(new_dash: Dash):
	var current_dash = dash
	current_dash.replace_by(new_dash)
	current_dash.queue_free()

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

func jump():
	input.jumping = false
	if !is_on_floor():
		return
	jumping.emit()
	jump_velocity = Vector3(0, sqrt(4 * jump_height * GRAVITY), 0)

func _calculate_velocity(delta: float) -> Vector3:
	# Movements velocity
	var movement_vector_raw: Vector3 = camera.global_transform.basis * Vector3(input.movement_direction.x, 0, input.movement_direction.y)
	movement_vector_raw.y = 0
	
	var movement_vector: Vector3 = movement_vector_raw.normalized() * SPEED * input.movement_direction.length()
	movement_velocity = movement_velocity.move_toward(movement_vector, acceleration * delta)
	
	# Jump
	jump_velocity = jump_velocity.move_toward(Vector3.ZERO, GRAVITY * delta)
	
	return movement_velocity + jump_velocity
