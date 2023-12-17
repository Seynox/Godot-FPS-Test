class_name BreakableInteractible extends Interactible

signal damaged(total_hits: int, max_hits: int)
signal hit_failed
signal broken

@export_category("Breakable")
@export var HITS_NEEDED: int
@export var HITS_TAKEN: int
@export var CAN_BE_HIT: bool = true
@export var IS_BROKEN: bool

# Local variables. Used to know if signals were already sent
var locally_broken: bool
var local_damages: int

func _ready():
	add_to_group(GameLevel.LEVEL_INITIALIZATION_GROUP)

func initialize():
	_update()

## Try hitting the object.[br]
## Calls [method BreakableInteractible.take_hit] if successfull[br]
## Emit [signal BreakableInteractible.hit_failed] if it cannot be hit.
func try_getting_hit_by(_source: Entity) -> bool:
	if CAN_BE_HIT:
		var server_peer_id: int = 1
		take_hit.rpc_id(server_peer_id)
	else:
		hit_failed.emit()
	return CAN_BE_HIT

## Called when the object takes a hit, even if it's already broken.[br]
## Don't call directly. Use [method BreakableInteractible.try_getting_hit_by] instead.[br]
## Will not call [method BreakableInteractible.break] if it's already broken
@rpc("any_peer", "call_local", "reliable")
func take_hit():
	HITS_TAKEN += 1
	if HITS_TAKEN >= HITS_NEEDED and !IS_BROKEN:
		set_broken()
	else:
		_update()

## Update the current state. Used to play signals after server synchronization changing state
func _update():
	if IS_BROKEN:
		if not locally_broken:
			broken.emit()
			locally_broken = true
		return
	
	var damage_level: int = HITS_NEEDED - HITS_TAKEN
	if damage_level != local_damages:
		damaged.emit(HITS_TAKEN, HITS_NEEDED)

## Called to set the object as broken.[br]
## Automatically called when taking enough hits with [method BreakableInteractible.take_hit].[br]
## Authority only.
func set_broken():
	if not is_multiplayer_authority():
		return
	IS_BROKEN = true
	CAN_BE_HIT = false
	_update()
