extends Node

## The camera movement speed multiplicator
@export var CAMERA_SENSITIVITY: float = 1

## The input movement direction 
@export var movement_direction: Vector2
## The rotation that should be applied to the camera
@export var camera_rotation: Vector2

## The cursor movement direction
var look_direction: Vector2

## The dictionary representing the currently pressed inputs. Used to share inputs across peers
var current_inputs: Dictionary = {
	"jump": false,
	"dash": false,
	"attack": false,
	"interact": false,
	"reload": false,
	"slide": false
}

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
		return
	_update_inputs(event)

func _unhandled_key_input(event: InputEvent):
	if event.is_action_pressed("exit"): get_tree().quit() # TODO Temporary, listen for it somewhere else

func _process(delta):
	handle_camera_movements(delta)
	movement_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

func _update_inputs(event: InputEvent):
	for action: String in current_inputs.keys():
		if event.is_action(action) and not event.is_echo(): # If the pressed/unpressed key is an action
			var is_pressed: bool = event.is_pressed()
			if current_inputs[action] != is_pressed: # Send it to all peers if it has changed state
				update_input_state.rpc(action, is_pressed)
			return

@rpc("call_local", "reliable")
func update_input_state(input: String, is_pressed: bool):
	current_inputs[input] = is_pressed

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
