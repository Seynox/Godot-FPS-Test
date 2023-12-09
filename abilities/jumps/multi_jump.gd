class_name MultiJump extends SimpleJump

@export var JUMP_AMOUNT: int = 2

var jumps_remaining: int = JUMP_AMOUNT

func get_velocity(entity: Entity, delta: float) -> Vector3:
	if jumps_remaining <= 0 and entity.is_on_floor():
		jumps_remaining = JUMP_AMOUNT
	
	return super.get_velocity(entity, delta)

func _start_jump():
	jumps_remaining -= 1
	super._start_jump()

func _disable_jump():
	if jumps_remaining <= 0:
		super._disable_jump()
