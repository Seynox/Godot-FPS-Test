class_name Player extends Entity

@export_category("Player")
@export_range(10, 400, 1) var acceleration: float = 100 # m/s^2

@export_range(0.1, 3.0, 0.1) var jump_height: float = 1 # m
@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sensitivity: float = 1
@export var shooting_cooldown: float = 0.2 # In seconds
@export var shooting_range: float = 1000 # In meters

var can_shoot: bool = true
var jumping: bool = false
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

func shoot() -> void:
	if !can_shoot:
		return
	
	var mouse_position = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_max = ray_origin + camera.project_ray_normal(mouse_position) * shooting_range
	
	var ray = PhysicsRayQueryParameters3D.create(ray_origin, ray_max)
	ray.collide_with_areas = true
	ray.exclude = [self]
	
	var space = get_world_3d().direct_space_state
	var result = space.intersect_ray(ray)
	var collidedNode = result.get("collider")
	
	if collidedNode != null && collidedNode is Entity:
		collidedNode.take_hit_from(self)

#
# OVERRIDEN METHODS
#

func _ready() -> void:
	capture_mouse()

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	
	if event is InputEventMouseMotion:
		look_direction = event.relative * 0.001
		if mouse_captured: update_camera_rotation()
		return
	
	if Input.is_action_just_pressed("jump"): jumping = true
	if Input.is_action_just_pressed("shoot"): shoot()
	if Input.is_action_just_pressed("exit"): get_tree().quit()

func _physics_process(delta: float) -> void:
	if mouse_captured: handle_camera_movements(delta)
	velocity = calculate_velocity(delta) #get_walk_vector(delta) + get_gravity_vector(delta) + get_jump_vector(delta)
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

func calculate_velocity(delta: float) -> Vector3:
	# Movements velocity
	movement_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	var movement_vector_raw: Vector3 = camera.global_transform.basis * Vector3(movement_direction.x, 0, movement_direction.y)
	movement_vector_raw.y = 0
	
	var movement_vector: Vector3 = movement_vector_raw.normalized() * SPEED * movement_direction.length()
	movement_velocity = movement_velocity.move_toward(movement_vector, acceleration * delta)
	
	# Jump velocity
	if jumping:
		jumping = false
		if is_on_floor():
			jump_velocity = Vector3(0, sqrt(4 * jump_height * GRAVITY), 0)
	else:
		jump_velocity = jump_velocity.move_toward(Vector3.ZERO, GRAVITY * delta)
		
	return movement_velocity + jump_velocity
