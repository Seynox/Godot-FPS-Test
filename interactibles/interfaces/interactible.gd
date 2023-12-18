class_name Interactible extends Node3D
## Make a 3D object interactible by players

signal interacted(interacting_player: Player) ## Emitted when the interaction was successfull

## If the object can be interacted with or not.
## Setting it to false will fail [method Interactible.try_interact]
@export var CAN_BE_INTERACTED_WITH: bool = true

## The message that should be displayed when a player is prompted
## to interact with the object.
@export var INTERACTION_PROMPT_MESSAGE: String

## Called on authority when a player tries to interact with the object.[br]
## Will call [method Interactible.on_interact] if successfull.[br]
@rpc("any_peer", "call_local", "reliable")
func try_interact():
	if is_multiplayer_authority() and CAN_BE_INTERACTED_WITH:
		var interacting_peer_id: int = multiplayer.get_remote_sender_id()
		on_interact.rpc(interacting_peer_id)

## Called by authority when a player successfully interact with the object.
@rpc("call_local", "reliable")
func on_interact(interacting_player_id: int):
	var player_node_name: String = str(interacting_player_id)
	var interacting_player: Player = $/root/Game/Players.get_node_or_null(player_node_name)
	interact(interacting_player)

## Handle successfull interaction from player
## Don't call directly, use [method Interactible.try_interact] instead.[br].
## Called on all peers
func interact(interacting_player: Player):
	interacted.emit(interacting_player)

#
# Synchronization
#

@rpc("any_peer", "call_local", "reliable")
func _request_current_state():
	var requesting_peer_id: int = multiplayer.get_remote_sender_id()
	_send_current_state(requesting_peer_id)

func _send_current_state(peer_id: int = 0, state: Dictionary = {}):
	if not is_multiplayer_authority(): return
	
	var current_state: Dictionary = {
		"CAN_BE_INTERACTED_WITH": CAN_BE_INTERACTED_WITH,
		"INTERACTION_PROMPT_MESSAGE": INTERACTION_PROMPT_MESSAGE
	}
	state.merge(current_state)
	
	if peer_id == 0:
		update_state.rpc(state)
	else:
		update_state.rpc_id(peer_id, state)

@rpc("reliable")
func update_state(state: Dictionary):
	CAN_BE_INTERACTED_WITH = state.get("CAN_BE_INTERACTED_WITH", CAN_BE_INTERACTED_WITH)
	INTERACTION_PROMPT_MESSAGE = state.get("INTERACTION_PROMPT_MESSAGE", INTERACTION_PROMPT_MESSAGE)
