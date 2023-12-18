class_name GameLevel extends Node3D

const LEVEL_INITIALIZATION_GROUP: String = "initializable"

## The signal sent to change the current level. Only works for authority
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
	_set_loaded.call_deferred()

func _set_loaded():
	var authority_peer: int = get_multiplayer_authority()
	player_loaded.rpc_id(authority_peer)

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

func _initialize():
	var player_name: String = str(multiplayer.get_unique_id())
	var local_player: Player = PLAYERS.get_node_or_null(player_name)
	if local_player == null:
		_spectate_random()
	else:
		local_player.global_position = get_spawnpoint()
		_listen_player_signals(local_player)

@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if not is_multiplayer_authority(): return
	loaded_players += 1
	
	# If joining level after it has been initialized
	if level_initialized:
		var loaded_peer_id: int = multiplayer.get_remote_sender_id()
		initialize_level.rpc_id(loaded_peer_id)
	else:
		var player_count: int = PLAYERS.get_child_count()
		if loaded_players == player_count:
			initialize_level.rpc()

## Called to initialize the level when all players finished loading the level.
## Calls "initialize" method on all nodes with group [member GameLevel.LEVEL_INITIALIZATION_GROUP]
@rpc("call_local", "reliable")
func initialize_level():
	if level_initialized: return
	print("[%s] %s initiliazed!" % [multiplayer.get_unique_id(), LEVEL_NAME])
	
	get_tree().call_group(LEVEL_INITIALIZATION_GROUP, "initialize")
	_initialize()
	level_initialized = true

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
	if not is_multiplayer_authority():
		return
	print("[Server] Player joined (%s)" % peer_id)
	if CAN_PLAYERS_JOIN:
		_player_joined(peer_id)

func _on_peer_disconnected(peer_id: int):
	if is_multiplayer_authority():
		print("[Server] Player left (%s)" % peer_id)
		_player_left(peer_id)

#
# Player management
#

func _player_joined(_peer_id: int):
	pass

func _player_left(_peer_id: int):
	pass

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
## By default, emit [signal GameLevel.game_over] from authority if everyone is dead.[br]
func on_player_death(_dead_player: Player):
	if not is_multiplayer_authority(): return
	
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
