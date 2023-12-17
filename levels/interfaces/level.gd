class_name GameLevel extends Node3D

## The signal sent to change the current level. Only works for server
signal change_level(new_level: PackedScene)

## The signal emitted when the game is lost.
signal game_over

## The current level name
@export var LEVEL_NAME: String

## If new players can join the game.
## If false, new player will be spectators.
@export var CAN_PLAYERS_JOIN: bool

## The node to use as a player spawnpoint
@export var PLAYER_SPAWN: Node3D

## The node containing all players.[br]
## Automatically assigned when changing scene.
@export var PLAYERS: Node3D

## If the level has already been initialized
var level_initialized: bool
var loaded_players: int

func _ready():
	_listen_multiplayer_signals()
	
	PLAYERS.global_position = get_spawnpoint()
	_initialize_player.call_deferred()
	
	var server_peer: int = 1
	player_loaded.rpc_id(server_peer)

func _initialize_player():
	var player_name: String = str(multiplayer.get_unique_id())
	var local_player: Player = PLAYERS.get_node_or_null(player_name)
	if local_player == null:
		_spectate_random()
	else:
		local_player.global_position = get_spawnpoint()
		_listen_player_signals(local_player)

func _spectate_random():
	var player: Player = PLAYERS.get_children().pick_random()
	if player != null:
		player.camera.current = true

## Get the level's [member GameLevel.PLAYER_SPAWN] position.[br]
## Return [member Vector3.ZERO] if [member GameLevel.PLAYER_SPAWN] is not set
func get_spawnpoint() -> Vector3:
	if PLAYER_SPAWN == null:
		return Vector3.ZERO
	
	return PLAYER_SPAWN.global_position

func _exit_tree():
	if multiplayer.has_multiplayer_peer():
		_disconnect_multiplayer_signals()

#
# Level initialization
#

@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if not multiplayer.is_server(): return
	loaded_players += 1
	
	var player_count: int = PLAYERS.get_child_count()
	if loaded_players == player_count:
		initialize_level.rpc()

@rpc("call_local", "reliable")
func initialize_level():
	if level_initialized: return
	print("[%s] All players loaded!" % LEVEL_NAME)
	_initialize_level()
	level_initialized = true

## Called to initialize the level when all players finished loading the level
func _initialize_level():
	pass

#
# Multiplayer signals
#

func _listen_multiplayer_signals():
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)

func _disconnect_multiplayer_signals():
	multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)
	multiplayer.peer_connected.disconnect(_on_peer_connected)

func _on_peer_connected(peer_id: int):
	if not multiplayer.is_server():
		return
	print("[Server] Player joined (%s)" % peer_id)
	if CAN_PLAYERS_JOIN:
		_add_player(peer_id)

func _on_peer_disconnected(peer_id: int):
	if multiplayer.is_server():
		print("[Server] Player left (%s)" % peer_id)
		_delete_player(peer_id)

#
# Player management
#

func _add_player(_peer_id: int):
	pass

func _delete_player(peer_id: int):
	var player = PLAYERS.get_node_or_null(str(peer_id))
	if player != null:
		_disconnect_player_signals(player)
		player.queue_free()

#
# Player signals
#

func _listen_player_signals(player: Player):
	player.death.connect(on_player_death.bind(player))
	player.out_of_map.connect(on_player_out_of_map.bind(player))

func _disconnect_player_signals(player: Player):
	player.death.disconnect(on_player_death)
	player.out_of_map.disconnect(on_player_out_of_map)

## Called when a player dies.[br]
## By default, emit [signal GameLevel.game_over] if everyone is dead.
func on_player_death(_dead_player: Player):
	# Check if everyone is dead
	var someone_is_alive: bool = false
	for player: Player in PLAYERS.get_children():
		if not player.is_dead():
			someone_is_alive = true
			break
	# Send game over if everyone is dead
	if not someone_is_alive:
		game_over.emit()

## Called when a player gets out of the map.[br]
## Teleports the player to spawn by default.
func on_player_out_of_map(player: Player):
	if player.is_multiplayer_authority():
		player.global_position = get_spawnpoint()
