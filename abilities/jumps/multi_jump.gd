class_name MultiJump extends SimpleJump

@export var JUMP_AMOUNT: int = 2

var jumps_remaining: int = JUMP_AMOUNT

func try_jump(_entity: Entity):
	if can_jump:
		_start_jump()
		_disable_jump()
	else:
		jump_failed.emit()

func _enable_jump():
	jumps_remaining = JUMP_AMOUNT
	super()

func _disable_jump():
	jumps_remaining -= 1
	if jumps_remaining <= 0:
		super()
