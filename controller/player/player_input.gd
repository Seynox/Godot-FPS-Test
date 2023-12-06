extends MultiplayerSynchronizer

@export var CAMERA_SENSITIVITY: float = 1 # Not sync

@export var jumping: bool = false
@export var dashing: bool = false
@export var shooting: bool = false

@export var movement_direction: Vector2 # Input direction for movement
@export var camera_rotation: Vector2
var look_direction: Vector2 # Input direction for look/aim

func _ready():
	# Enable processing for local player
	var is_local_player: bool = get_multiplayer_authority() == multiplayer.get_unique_id()
	set_process(is_local_player)
	if is_local_player:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_direction = event.relative * 0.001
		update_camera_rotation()

func _process(delta):
	handle_camera_movements(delta)
	movement_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if Input.is_action_just_pressed("jump"): jump.rpc()
	if Input.is_action_just_pressed("dash"): dash.rpc()
	if Input.is_action_just_pressed("shoot"): shoot.rpc()
#
# Movements
#

@rpc("call_local", "reliable")
func jump():
	jumping = true

@rpc("call_local", "reliable")
func dash():
	dashing = true

@rpc("call_local", "reliable")
func shoot():
	shooting = true

#
# Camera
#

func handle_camera_movements(delta: float) -> void:
	var joypad_dir: Vector2 = Input.get_vector("look_left","look_right","look_up","look_down")
	if joypad_dir.length() > 0:
		look_direction += joypad_dir * delta
		update_camera_rotation()
		look_direction = Vector2.ZERO

func update_camera_rotation() -> void:
	camera_rotation.y -= look_direction.x * CAMERA_SENSITIVITY
	camera_rotation.x = clamp(camera_rotation.x - look_direction.y * CAMERA_SENSITIVITY, -1.5, 1.5)

