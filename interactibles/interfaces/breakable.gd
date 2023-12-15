class_name BreakableInteractible extends Interactible

signal damaged(total_hits: int, max_hits: int)
signal hit_failed
signal broken

@export_category("Breakable")
@export var HITS_NEEDED: int
@export var HITS_TAKEN: int
@export var CAN_BE_HIT: bool = true
@export var IS_BROKEN: bool


## Try hitting the object.[br]
## Calls [method BreakableInteractible.take_hit] if successfull[br]
## Emit [signal BreakableInteractible.hit_failed] if it cannot be hit.
func try_getting_hit_by(_source: Entity) -> bool:
	if CAN_BE_HIT:
		take_hit.rpc()
	else:
		hit_failed.emit()
	return CAN_BE_HIT

## Called when the object takes a hit, even if it's already broken.[br]
## Don't call directly. Use [method BreakableInteractible.try_getting_hit_by] instead.[br]
## Will not call [method BreakableInteractible.break] if it's already broken
@rpc("any_peer", "call_local", "reliable")
func take_hit():
	damaged.emit(HITS_TAKEN, HITS_NEEDED)
	HITS_TAKEN += 1
	if HITS_TAKEN >= HITS_NEEDED and !IS_BROKEN:
		set_broken()

## Called to set the object as broken.[br]
## Automatically called when taking enough hits with [method BreakableInteractible.take_hit]
func set_broken():
	IS_BROKEN = true
	CAN_BE_HIT = false
	broken.emit()
