class_name Slide extends RechargingAbility

const TYPE: String = "slide"

## The speed of the steering when sliding. The higher the value, the easier it is to turn while sliding
@export var STEERING_SPEED: float = 5.0
## The slide impulse speed. Added to the ability owner velocity when the ability is executed
@export var SLIDE_SPEED_IMPULSE: float = 13.0
## The [member Player.SPEED] multiplier used to determine the maximum slide speed
@export var MAX_SPEED_MULTIPLIER: float = 8.0
## The slide speed decceleration
@export var DECCELERATION: float = 1.0
## The friction applied on top of [member Slide.DECCELERATION] when sliding on the floor
@export var FLOOR_FRICTION: float = 1.0

## If the ability owner is currently sliding
var is_sliding: bool
## The directions in which the slide speed will be applied
var slide_direction: Vector3
## The current slide speed
var slide_speed: float

func _get_unique_type() -> String:
	return TYPE

func _cancel_ability(_player: Player):
	is_sliding = false
	slide_speed = 0.0

#
# Slide
#

## Get the updated sliding direction. Will slide forward if [param direction] is [member Vector3.ZERO].[br]
## Set [param interpolate] to true to interpolate the returned direction from the current direction using [member Slide.STEERING_SPEED]
func _get_slide_direction(player: Player, delta: float, interpolate: bool) -> Vector3:
	# Go forward if no direction is provided by inputs
	var input_direction: Vector2 = player.get_input_direction()
	if input_direction == Vector2.ZERO:
		input_direction = Vector2.UP # Go forward
	
	# Get input direction
	var movement_direction: Vector3 = Vector3(input_direction.x, 0.0, input_direction.y)
	var new_direction: Vector3 = player.get_look_relative_direction(movement_direction)
	if not interpolate:
		return new_direction
	
	# Slowly turn towards new direction
	return slide_direction.lerp(new_direction, STEERING_SPEED * delta)

#
# Execution
#

func _handle_player_inputs(player: Player, delta: float, inputs: Dictionary):
	var trying_to_slide: bool = inputs.get("slide", false)
	
	if trying_to_slide and not is_sliding: # Start sliding
		# Set sliding direction
		slide_direction = _get_slide_direction(player, delta, false)
		# Try sliding
		try_executing(player, delta)
	elif not trying_to_slide and is_sliding: # Stop sliding on release
		is_sliding = false

func _can_execute(player: Player) -> bool:
	return not is_sliding and player.is_on_floor() and super(player)

## Initialize slide speed and start sliding
func _execute(player: Player, _delta: float):
	# Set slide speed
	var max_slide_speed: float = player.SPEED * MAX_SPEED_MULTIPLIER
	var new_speed: float = SLIDE_SPEED_IMPULSE + player.velocity.length()
	slide_speed = minf(new_speed, max_slide_speed)
	# Start sliding
	is_sliding = true
	# Start cooldown
	start_recharging()

func _on_player_physics(player: Player, delta: float):
	if not is_sliding: return
	# Update slide direction
	slide_direction = _get_slide_direction(player, delta, true)
	
	# Update slide decceleration
	var friction: float = DECCELERATION
	if player.is_on_floor():
		friction += FLOOR_FRICTION
	slide_speed = lerpf(slide_speed, 0.0, friction * delta)
	
	# Apply velocity
	var slide_velocity: Vector3 = slide_direction * slide_speed

	player.velocity.x = slide_velocity.x
	player.velocity.z = slide_velocity.z
