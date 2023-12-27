extends Node

@export var CAMERA_SENSITIVITY: float = 1

var jumping: bool
var dashing: bool
var attacking: bool
var interacting: bool
var reloading: bool

@export var movement_direction: Vector2 # Input direction for movement
@export var camera_rotation: Vector2
var look_direction: Vector2 # Input direction for look/aim

func _ready():
	# Enable processing for local player
	var is_local_player: bool = is_multiplayer_authority()
	set_enabled(is_local_player)

	if is_local_player:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func set_enabled(enable: bool):
	set_process(enable)
	set_process_unhandled_input(enable)
	set_process_unhandled_key_input(enable)

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		look_direction = event.relative * 0.001
		update_camera_rotation()
	
	if event.is_action_pressed("attack"): attack.rpc()

func _unhandled_key_input(event):
	if event.is_action_pressed("jump"): jump.rpc()
	if event.is_action_pressed("dash"): dash.rpc()
	if event.is_action_pressed("interact"): interact.rpc()
	if event.is_action_pressed("reload"): reload.rpc()
	if event.is_action_pressed("exit"): get_tree().quit() # TODO Temporary, listen for it somewhere else

func _process(delta):
	handle_camera_movements(delta)
	movement_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

#
# Input RPCs
#

@rpc("call_local", "reliable")
func jump():
	jumping = true

@rpc("call_local", "reliable")
func dash():
	dashing = true

@rpc("call_local", "reliable")
func interact():
	interacting = true

@rpc("call_local", "reliable")
func attack():
	attacking = true

@rpc("call_local", "reliable")
func reload():
	reloading = true

#
# Input handling
#

func consume_jumping() -> bool:
	var is_jumping = jumping
	jumping = false
	return is_jumping

func consume_dashing() -> bool:
	var is_dashing = dashing
	dashing = false
	return is_dashing

func consume_interacting() -> bool:
	var is_interacting = interacting
	interacting = false
	return is_interacting

func consume_attacking() -> bool:
	var is_attacking = attacking
	attacking = false
	return is_attacking

func consume_reloading() -> bool:
	var is_reloading = reloading
	reloading = false
	return is_reloading

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

