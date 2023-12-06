class_name Player extends Entity

@export_category("Player")
@export_range(10, 400, 1) var acceleration: float = 100 # m/s^2
@export_range(0.1, 3.0, 0.1) var jump_height: float = 1 # In meters
@export var shooting_cooldown: float = 0.2 # In seconds
@export var dash_cooldown: float = 1 # In seconds
@export var dash_distance: float = 6 # In meters
@export var dash_duration: float = 0.1 # In seconds

@export var player_peer: int = 1:
	set(id):
		player_peer = id
		$PlayerInput.set_multiplayer_authority(id) # Multiplayer peer id (Default to server id)

var lock_velocity: bool = false # Cancel velocity updates
var can_dash: bool = true
var can_shoot: bool = true

var movement_velocity: Vector3
var jump_velocity: Vector3

@onready var camera: Camera3D = $Camera
@onready var input := $PlayerInput

func _ready() -> void:
	var is_local_player: bool = player_peer == multiplayer.get_unique_id()
	camera.current = is_local_player

func _process(_delta):
	if input.shooting:
		shoot()

func _physics_process(delta: float):
	if lock_velocity:
		move_and_slide()
		return
	
	# Apply camera rotation
	camera.rotation.x = input.camera_rotation.x
	camera.rotation.y = input.camera_rotation.y
	
	if input.jumping:
		jump()
	if input.dashing:
		dash()
	else:
		velocity = _calculate_velocity(delta)
	super._physics_process(delta)

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

func _toggle_dash() -> void:
	CAN_BE_HIT = !CAN_BE_HIT
	lock_velocity = !lock_velocity

func _start_dash_cooldown() -> void:
	if !can_dash:
		return
	can_dash = false
	var cooldown_time = dash_cooldown + dash_duration
	get_tree().create_timer(cooldown_time).timeout.connect(func(): can_dash = true)

func dash():
	# Cooldown handling
	input.dashing = false
	if !can_dash:
		return
	_start_dash_cooldown()
	# Dash action
	var dash_speed = dash_distance / dash_duration
	var dash_velocity = camera.global_transform.basis * Vector3(0, 0, dash_speed * -1)
	velocity = dash_velocity
	_toggle_dash()
	get_tree().create_timer(dash_duration).timeout.connect(_toggle_dash)

func jump():
	input.jumping = false
	if !is_on_floor():
		return
	
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
