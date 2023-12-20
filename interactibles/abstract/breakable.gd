class_name BreakableInteractible extends Interactible

signal damaged(total_hits: int, max_hits: int)
signal broken

@export_category("Breakable")
@export var HITS_NEEDED: int
@export var HITS_TAKEN: int
@export var CAN_BE_HIT: bool = true
@export var IS_BROKEN: bool

func _ready():
	add_to_group(GameLevel.LEVEL_INITIALIZATION_GROUP)

func on_level_initialization():
	if not is_multiplayer_authority():
		var authority_peer_id: int = get_multiplayer_authority()
		_request_current_state.rpc_id(authority_peer_id)

## Try hitting the object from rpc sender player.
## Calls [method BreakableInteractible.try_getting_hit_by] if player exists.
@rpc("any_peer", "call_local", "reliable")
func try_hitting():
	if not is_multiplayer_authority(): return
	
	var player_peer_id: int = multiplayer.get_remote_sender_id()
	var player_node_name: String = str(player_peer_id)
	var hitting_player: Player = $/root/Game/Players.get_node_or_null(player_node_name)
	
	if hitting_player != null:
		try_getting_hit_by(hitting_player)

## Try hitting the object from entity.[br]
## Calls [method BreakableInteractible.take_hit] if successfull[br]
func try_getting_hit_by(_source: Entity):
	if CAN_BE_HIT and is_multiplayer_authority():
		take_hit.rpc()

## Called when the object takes a hit, even if it's already broken.[br]
## Don't call directly. Use [method BreakableInteractible.try_getting_hit_by] instead.[br]
## Will not call [method BreakableInteractible.set_broken] if it's already broken
@rpc("call_local", "reliable")
func take_hit():
	HITS_TAKEN += 1
	if HITS_TAKEN >= HITS_NEEDED and !IS_BROKEN:
		set_broken()
	else:
		damaged.emit(HITS_TAKEN, HITS_NEEDED)

## Called to set the object as broken.[br]
## Automatically called when taking enough hits with [method BreakableInteractible.take_hit].[br]
func set_broken():
	IS_BROKEN = true
	CAN_BE_HIT = false
	broken.emit()

#
# Synchronization
#

func _send_current_state(peer_id: int = 0, state: Dictionary = {}):
	var current_state: Dictionary = {
		"HITS_NEEDED": HITS_NEEDED,
		"HITS_TAKEN": HITS_TAKEN,
		"CAN_BE_HIT": CAN_BE_HIT,
		"IS_BROKEN": IS_BROKEN
	}
	state.merge(current_state)
	super(peer_id, state)

func update_state(state: Dictionary):
	CAN_BE_HIT = state.get("CAN_BE_HIT", CAN_BE_HIT)
	
	HITS_NEEDED = state.get("HITS_NEEDED", HITS_NEEDED)
	HITS_TAKEN = state.get("HITS_TAKEN", HITS_TAKEN)
	if HITS_TAKEN > 0:
		damaged.emit(HITS_TAKEN, HITS_NEEDED)
	
	var broken_before: int = IS_BROKEN
	IS_BROKEN = state.get("IS_BROKEN", IS_BROKEN)
	if IS_BROKEN and not broken_before:
		broken.emit()
	
	super(state)
