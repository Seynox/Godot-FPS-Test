## Client-only. Allow client to switch between alive players camera
class_name Spectator extends Node

## The node containing all players
@onready var players: Node3D = $/root/Game/Players

## The player currently spectated
var spectated_player: Player

## The list index of the spectated player
var spectating_index: int

func _ready():
	multiplayer.peer_disconnected.connect(_on_player_disconnect)
	_spectate_first_player()

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("next_camera"):
		_spectate_next_player()
	elif event.is_action_pressed("previous_camera"):
		_spectate_previous_player()

func _exit_tree():
	if multiplayer.has_multiplayer_peer():
		multiplayer.peer_disconnected.disconnect(_on_player_disconnect)
	if spectated_player != null:
		spectated_player.show_camera(false)

#
# Player Spectating
#

func _get_alive_players() -> Array:
	return players.get_children().filter(func(player): return not player.is_dead)

func _spectate_player(player: Player):
	if spectated_player != null:
		spectated_player.death.disconnect(_on_spectated_player_death)
		spectated_player.show_camera(false)
	
	player.show_camera(true)
	spectated_player = player
	player.death.connect(_on_spectated_player_death)

func _spectate_at_index(index: int):
	var alive_players: Array = _get_alive_players()
	if alive_players.is_empty(): return
	
	# Limit the index to the available players list
	spectating_index = index % alive_players.size()
	
	var player: Player = alive_players[spectating_index]
	_spectate_player(player)

func _spectate_first_player():
	_spectate_at_index(0)

func _spectate_next_player():
	_spectate_at_index(spectating_index + 1)

func _spectate_previous_player():
	_spectate_at_index(spectating_index - 1)

#
# Player signals
#

## Spectate the first player alive if the spectated player dies
func _on_spectated_player_death():
	_spectate_first_player()

## Spectate the first player alive if the spectated player disconnects
func _on_player_disconnect(peer_id: int):
	if spectated_player != null and spectated_player.player_peer == peer_id:
		_spectate_first_player()
