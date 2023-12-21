class_name GameLevel extends Node3D

const LEVEL_INITIALIZATION_GROUP: String = "level_initialized"

## The signal sent to change the current level. Only works for authority
signal change_level(new_level: PackedScene)

## The signal emitted when the game is lost.
signal game_over

## The current level name
@export var LEVEL_NAME: String

## The scene to change to when ending the level. Not used on game over
@export var NEXT_LEVEL_SCENE: PackedScene

## If new players can join the game.
## If false, new player will be spectators.
@export var CAN_PLAYERS_JOIN: bool

## The scene created and assigned to a player when joining
@export var PLAYER_SCENE: PackedScene

## The node to use as a player spawnpoint
@export var PLAYER_SPAWN: Node3D

## The node containing all players.[br]
## Automatically assigned when changing scene.
var players: Node3D

## If the level has already been initialized
var level_initialized: bool
var loaded_players: int

func _ready():
	_listen_multiplayer_signals()
	players.global_position = get_spawnpoint()
	_send_loaded.call_deferred()

func _exit_tree():
	if not multiplayer.has_multiplayer_peer():
		_disconnect_multiplayer_signals()
	for player: Player in players.get_children():
		_disconnect_player_signals(player)

func _send_loaded():
	var authority_peer: int = get_multiplayer_authority()
	player_loaded.rpc_id(authority_peer)

## Get the level's [member GameLevel.PLAYER_SPAWN] position.[br]
## Return 1 meter above level center if [member GameLevel.PLAYER_SPAWN] is not set
func get_spawnpoint() -> Vector3:
	if PLAYER_SPAWN == null:
		return self.global_position + Vector3(0, 1, 0)
	
	return PLAYER_SPAWN.global_position

#
# Level initialization
#

## Called on authority when a peer finished loading the current level.[br]
## Makes all peer initialize everything when all peers finished loading the level.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if not is_multiplayer_authority(): return
	loaded_players += 1
	
	# If joining level after it has been initialized
	if level_initialized:
		var loaded_peer_id: int = multiplayer.get_remote_sender_id()
		initialize_all.rpc_id(loaded_peer_id)
	else:
		var player_count: int = players.get_child_count()
		if loaded_players == player_count:
			initialize_all.rpc()

## Called to initialize the level when all players finished loading the level.[br]
## Calls "initialize" method on all nodes with group [member GameLevel.LEVEL_INITIALIZATION_GROUP][br]
## Can only be called once.
@rpc("call_local", "reliable")
func initialize_all():
	if level_initialized: return
	get_tree().call_group(LEVEL_INITIALIZATION_GROUP, "on_level_initialization")
	_initialize_level()
	level_initialized = true
	print("[%s] %s initiliazed!" % [multiplayer.get_unique_id(), LEVEL_NAME])

## Initialize the current level.
func _initialize_level():
	for player: Player in players.get_children():
		_listen_player_signals(player)
		
		# Respawn
		player.resurrect()
		
		# Move to spawn
		if player.is_local_player:
			player.global_position = get_spawnpoint()

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
	if not is_multiplayer_authority(): return
	print("[Server] Peer joined (%s)" % peer_id)
	if CAN_PLAYERS_JOIN:
		_add_player(peer_id)

func _on_peer_disconnected(peer_id: int):
	if not is_multiplayer_authority(): return
	print("[Server] Peer left (%s)" % peer_id)
	_remove_player(peer_id)

#
# Player signals
#

## Setup signal callbacks for [param player]. Called when initializating level.[br]
func _listen_player_signals(player: Player):
	print("%s listening to %s" % [multiplayer.get_unique_id(), player.name])
	player.death.connect(on_player_death.bind(player))
	player.out_of_map.connect(on_player_out_of_map.bind(player))

## Disconnect signal callbacks for [param player]. Called when level is deleted
func _disconnect_player_signals(player: Player):
	player.death.disconnect(on_player_death)
	player.out_of_map.disconnect(on_player_out_of_map)

#
# Player management
#

## Called on server when adding a player.
## Called on clients when MultiplayerSpawner spawns a player.[br]
## Note: When called on server, the player might not be replicated on other peers yet.
func _on_player_spawn(player: Player):
	if not player.is_local_player: # Will be called for local player when initializing the level
		_listen_player_signals(player)

## Called on clients when MutliplayerSpawner despawns a player
func _on_player_despawn(player: Player):
	_disconnect_player_signals(player)

## Add a player and assign it to [param peer_id].[br]
## Only called on server ! Automatically replicated on clients with MultiplayerSpawner
func _add_player(peer_id: int):
	print("[Server] Player added (%s)" % peer_id)
	var player: Player = PLAYER_SCENE.instantiate()
	player.name = str(peer_id) # Set player node name to peer id
	players.add_child(player, true)
	_on_player_spawn(player)

## Remove a player assigned to [param peer_id] if it exists.[br]
## Only called on server ! Automatically replicated on clients with MultiplayerSpawner
func _remove_player(peer_id: int):
	var player_name: String = str(peer_id)
	var player: Player = players.get_node_or_null(player_name)
	if player != null:
		_on_player_despawn(player)
		player.queue_free()

## Called on all peers when a player dies.[br]
func on_player_death(_dead_player: Player):
	# Authority check if everyone is dead for game over
	if not is_multiplayer_authority(): return
	
	var someone_is_alive: bool = false
	for player: Player in players.get_children():
		if not player.is_dead():
			someone_is_alive = true
			break
	
	if not someone_is_alive:
		game_over.emit()

## Called on all peers when a player gets out of the map.[br]
## Teleports the player to spawn by default.
func on_player_out_of_map(player: Player):
	if player.is_multiplayer_authority():
		player.global_position = get_spawnpoint()
