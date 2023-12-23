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

## The node to use as a player spawnpoint
@export var PLAYER_SPAWN: Node3D

## If peers joining should be added as players. Setting it to false will add them as spectators
@export var SPAWN_NEW_PLAYERS: bool

## The node containing all players.[br]
## Automatically assigned when level is set as scene.
var players: Node3D

## If the level has already been initialized
var level_initialized: bool
var loaded_peers: int

func _ready():
	players.global_position = get_spawnpoint()
	_send_loaded.call_deferred()

func _exit_tree():
	for player: Player in players.get_children():
		_disconnect_player_signals(player)

func _send_loaded():
	var authority_peer: int = get_multiplayer_authority()
	peer_loaded.rpc_id(authority_peer)

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
func peer_loaded():
	if not is_multiplayer_authority(): return
	loaded_peers += 1
	
	# If joining level after it has been initialized
	if level_initialized:
		var loaded_peer_id: int = multiplayer.get_remote_sender_id()
		initialize_all.rpc_id(loaded_peer_id)
	else:
		# Check if all peers finished loading to initialize all
		var peers_count: int = multiplayer.get_peers().size()
		var server_is_player: bool = DisplayServer.get_name() != "headless"
		if server_is_player: peers_count += 1
		
		if loaded_peers == peers_count:
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

## Initialize the current level. Called after initializing everything.
func _initialize_level():
	for player: Player in players.get_children():
		_initialize_player(player)

func _initialize_player(player: Player):
	_listen_player_signals(player)
	
	# Respawn dead players
	if player.is_dead:
		player.resurrect()
	
	# Move to spawn
	player.global_position = get_spawnpoint()

#
# Player signals
#

## Setup signal callbacks for [param player]. Called when initializating level.[br]
func _listen_player_signals(player: Player):
	player.death.connect(_on_player_death.bind(player))
	player.out_of_map.connect(_on_player_out_of_map.bind(player))

## Disconnect signal callbacks for [param player]. Called when level is deleted
func _disconnect_player_signals(player: Player):
	player.death.disconnect(_on_player_death)
	player.out_of_map.disconnect(_on_player_out_of_map)

#
# Player management
#

## Called on server when adding a player.[br]
## Called on clients when MultiplayerSpawner spawns a player.[br]
## Note: When called on server, the player might not be replicated on other peers yet.
func on_player_spawn(player: Player):
	# Listen to player signals (Will be called for local player when initializing the level)
	if not player.is_local_player and level_initialized:
		_listen_player_signals(player)

## Called on server when removing a player.[br]
## Called on clients when MutliplayerSpawner despawns a player.
## Note: When called on client, the player might be already removed on other peers.
func on_player_despawn(player: Player):
	_disconnect_player_signals(player)

## Called on all peers when a player dies.[br]
## Check on authority if all players are dead to emit [signal GameLevel.game_over]
func _on_player_death(_dead_player: Player):
	if not is_multiplayer_authority(): return
	
	var player_list: Array = players.get_children()
	var someone_is_alive: bool = false
	for player: Player in player_list:
		if not player.is_dead:
			someone_is_alive = true
			break
	
	if not someone_is_alive:
		game_over.emit()

## Called on all peers when a player gets out of the map.[br]
## Teleports the player to spawn by default.
func _on_player_out_of_map(player: Player):
	if player.is_multiplayer_authority():
		player.global_position = get_spawnpoint()
