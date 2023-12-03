class_name Player extends Entity

@export_category("Player")
@export_range(10, 400, 1) var acceleration: float = 100 # m/s^2

@export_range(0.1, 3.0, 0.1) var jump_height: float = 1 # In meters
@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sensitivity: float = 1
@export var shooting_cooldown: float = 0.2 # In seconds
@export var dash_cooldown: float = 1 # In seconds
@export var dash_distance: float = 6 # In meters
@export var dash_duration: float = 0.1 # In seconds

var lock_velocity: bool = false # Cancel velocity updates
var can_dash: bool = true
var can_shoot: bool = true
var mouse_captured: bool = false

var movement_direction: Vector2 # Input direction for movement
var look_direction: Vector2 # Input direction for look/aim

var movement_velocity: Vector3
var jump_velocity: Vector3

@onready var camera: Camera3D = $Camera

#
# PLAYER
#

func _die() -> void:
	print("DEAD")
	get_tree().reload_current_scene()

func shoot_coolown() -> void:
	can_shoot = false
	get_tree().create_timer(shooting_cooldown).timeout.connect(func(): can_shoot = true)

func shoot() -> bool:
	if !can_shoot:
		return false

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
	return true

#
# OVERRIDEN METHODS
#

func _ready() -> void:
	capture_mouse()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_direction = event.relative * 0.001
		if mouse_captured: update_camera_rotation()
		return
	
	if Input.is_action_just_pressed("jump"): jump()
	if Input.is_action_just_pressed("dash"): dash()
	if Input.is_action_just_pressed("shoot"): shoot()
	if Input.is_action_just_pressed("exit"): get_tree().quit()

func _physics_process(delta: float) -> void:
	if mouse_captured: handle_camera_movements(delta)
	if lock_velocity:
		move_and_slide()
		return
	
	velocity = _calculate_velocity(delta)
	super._physics_process(delta)

#
# MOUSE
#

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

#
# CAMERA
#

func update_camera_rotation(sensitivity_multiplicator: float = 1.0) -> void:
	camera.rotation.y -= look_direction.x * camera_sensitivity * sensitivity_multiplicator
	camera.rotation.x = clamp(camera.rotation.x - look_direction.y * camera_sensitivity * sensitivity_multiplicator, -1.5, 1.5)

func handle_camera_movements(delta: float, sens_mod: float = 1.0) -> void:
	var joypad_dir: Vector2 = Input.get_vector("look_left","look_right","look_up","look_down")
	if joypad_dir.length() > 0:
		look_direction += joypad_dir * delta
		update_camera_rotation(sens_mod)
		look_direction = Vector2.ZERO

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

func dash() -> bool:
	# Cooldown handling
	if !can_dash:
		return false
	_start_dash_cooldown()
	
	# Dash action
	var dash_speed = dash_distance / dash_duration
	var dash_velocity = camera.global_transform.basis * Vector3(0, 0, dash_speed * -1)
	
	velocity = dash_velocity
	_toggle_dash()
	get_tree().create_timer(dash_duration).timeout.connect(_toggle_dash)
	return true

func jump() -> bool:
	if !is_on_floor():
		return false
		
	jump_velocity = Vector3(0, sqrt(4 * jump_height * GRAVITY), 0)
	return true

func _calculate_velocity(delta: float) -> Vector3:
	# Movements velocity
	movement_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	var movement_vector_raw: Vector3 = camera.global_transform.basis * Vector3(movement_direction.x, 0, movement_direction.y)
	movement_vector_raw.y = 0
	
	var movement_vector: Vector3 = movement_vector_raw.normalized() * SPEED * movement_direction.length()
	movement_velocity = movement_velocity.move_toward(movement_vector, acceleration * delta)
	
	# Jump
	jump_velocity = jump_velocity.move_toward(Vector3.ZERO, GRAVITY * delta)
	
	return movement_velocity + jump_velocity
