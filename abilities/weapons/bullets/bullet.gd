class_name Bullet extends Node3D

## The bullet speed in meter per seconds.
@export var SPEED: float = 100.0

## The bullet deceleration in meter per seconds.
@export var DECELERATION: float = 0.0

## The multiplier applied to the default bullet gravity force
@export var GRAVITY_MULTIPLIER: float = 0.0

## The maximum bullet lifetime in seconds. The bullet will be deleted after this time.
@export var MAX_LIFETIME: float = 5.0

## The current bullet velocity
var velocity: Vector3

## The timer representing the bullet lifetime
var lifetime: Timer

## The raw gravity force applied to the bullet. [member Bullet.GRAVITY_MULTIPLIER] is not applied to it.
var gravity_force: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	velocity = Vector3(0, 0, -SPEED)
	lifetime = _create_timer(MAX_LIFETIME)
	lifetime.timeout.connect(_on_lifetime_end)

func _create_timer(time_in_seconds: float):
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = time_in_seconds
	add_child(timer)
	return timer

#
# Bullet Physics
#

func _physics_process(delta):
	# Move the bullet
	translate_object_local(velocity * delta)
	# Applies friction
	velocity = velocity.move_toward(Vector3.ZERO, DECELERATION * delta)
	# Applies gravity
	velocity.y -= gravity_force * GRAVITY_MULTIPLIER * delta

#
# Lifetime
#

## Called when the bullet lifetime ends.
func _on_lifetime_end():
	_destroy_bullet()

## Called to destroy the bullet
func _destroy_bullet():
	queue_free()
