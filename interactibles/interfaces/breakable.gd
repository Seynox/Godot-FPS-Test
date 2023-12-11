class_name BreakableInteractible extends Interactible

signal damaged(total_hits: int, source: Entity)
signal hit_failed
signal broken(source: Entity)

@export_category("Breakable")
@export var HITS_NEEDED: int
@export var HITS_TAKEN: int
@export var CAN_BE_HIT: bool = true
@export var IS_BROKEN: bool


## Try hitting the object.[br]
## Calls [method BreakableInteractible._take_hit] if successfull[br]
## Emit [signal BreakableInteractible.hit_failed] if it cannot be hit.
func try_hitting(source: Entity) -> bool:
	if CAN_BE_HIT:
		_take_hit(source)
	else:
		hit_failed.emit()
	return CAN_BE_HIT

## Called when the object takes a hit, even if it's already broken.[br]
## Don't call directly. Use [method BreakableInteractible.try_hitting] instead.[br]
## Will not call [method BreakableInteractible.break] if it's already broken
func _take_hit(source: Entity):
	damaged.emit(HITS_TAKEN, source)
	HITS_TAKEN += 1
	if HITS_TAKEN >= HITS_NEEDED and !IS_BROKEN:
		_break(source)

## Called to set the object as broken.[br]
## Automatically called when taking enough hits with [method BreakableInteractible._take_hit]
func _break(source: Entity):
	IS_BROKEN = true
	broken.emit(source)
