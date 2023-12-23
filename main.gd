class_name Main extends Node

signal scene_changed

## The scene to put when the game is started
@export var LOBBY_SCENE: PackedScene

## The node containing the players
@export var PLAYERS_NODE: Node3D

## The multiplayer spawner spawning players
@export var PLAYER_SPAWNER: MultiplayerSpawner

## The scene created when a peer is added to the game
@export var PLAYER_SCENE: PackedScene

## The scene created locally when a peer cannot join a game yet
@export var SPECTATOR_SCENE: PackedScene

## The main menu node
@export var MENU: MainMenu

## The current level path. Used for scene synchronization
var current_level_path: String

## The current displayed scene
var current_level: GameLevel

func _ready():
	MENU.start_lobby.connect(_start_lobby)
	_listen_connection_signals()

#
# Changing level
#

func _start_lobby():
	MENU.hide()
	set_new_level(LOBBY_SCENE)
	if multiplayer.is_server() and DisplayServer.get_name() != "headless":
		await scene_changed
		var server_peer_id: int = multiplayer.get_unique_id()
		_add_player(server_peer_id)

@rpc("reliable")
func change_client_level(unsafe_scene_path: String):
	var scene_path: String = Sanitizer.sanitize_scene_path(unsafe_scene_path)
	var scene: PackedScene = load(scene_path)
	_set_level.call_deferred(scene)

func set_new_level(level_scene: PackedScene):
	# Server only
	if not multiplayer.is_server(): return
	current_level_path = level_scene.resource_path
	change_client_level.rpc(current_level_path)
	
	_set_level.call_deferred(level_scene)

## DO NOT USE DIRECTLY. Use [method Main.set_new_level] from server instead.[br]
## Set the current level. Must be called at the end of a frame with [method Callable.call_deferred]
func _set_level(packed_scene: PackedScene):
	if current_level != null:
		_disconnect_level_signals(current_level)
		_disconnect_spawner_signals(current_level)
		current_level.free()
	
	var level: GameLevel = packed_scene.instantiate()
	level.players = PLAYERS_NODE # Gives a reference to the players node
	_listen_spawner_signals(level)
	_listen_level_signals(level)
	
	current_level = level
	add_child(level, true)
	scene_changed.emit()

#
# Signals listeners
#

func _listen_connection_signals():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(MENU.hide)
	
	# Client-only signals
	multiplayer.connected_to_server.connect(_on_server_connected)
	multiplayer.server_disconnected.connect(_on_server_disconnect)
	multiplayer.connection_failed.connect(_on_server_connection_failed)

	
func _listen_level_signals(level: GameLevel):
	level.change_level.connect(set_new_level)
	level.game_over.connect(_on_game_over)

func _disconnect_level_signals(level: GameLevel):
	level.change_level.disconnect(set_new_level)
	level.game_over.disconnect(_on_game_over)

func _listen_spawner_signals(level: GameLevel):
	PLAYER_SPAWNER.spawned.connect(level.on_player_spawn)
	PLAYER_SPAWNER.despawned.connect(level.on_player_despawn)

func _disconnect_spawner_signals(level: GameLevel):
	PLAYER_SPAWNER.spawned.disconnect(level.on_player_spawn)
	PLAYER_SPAWNER.despawned.disconnect(level.on_player_despawn)

#
# Game

func _on_game_over():
	print("[GAME] Game over!")
	if not is_multiplayer_authority(): return
	# TODO Save game
	
	# Go back to first scene and reset players
	set_new_level(LOBBY_SCENE)
	await scene_changed
	_recreate_all_players()

#
# Server connection/hosting
#

## Disconnect from multiplayer and display the main menu.[br]
## If set, [param error_message] will be displayed on the menu.
func _quit_game(error_message: String = ""):
	if not error_message.is_empty():
		print("[Multiplayer] ", error_message)
	
	multiplayer.multiplayer_peer = null
	MENU.set_message(error_message)
	MENU.show()
	if current_level != null:
		current_level.queue_free()

func _on_server_connection_failed():
	_quit_game("Connection to server failed")

func _on_server_disconnect():
	_quit_game("Server disconnected")

func _on_server_connected():
	# Ask the join the game
	var authority_peer_id: int = get_multiplayer_authority()
	join_game.rpc_id(authority_peer_id)

#
# Player connection
#

func _on_peer_connected(peer_id: int):
	if is_multiplayer_authority():
		print("[Server] Peer joined (%s)" % peer_id)
		# Send current scene to new peer
		change_client_level.rpc_id(peer_id, current_level_path)
	

func _on_peer_disconnected(peer_id: int):
	if not is_multiplayer_authority(): return
	print("[Server] Peer left (%s)" % peer_id)
	_remove_player(peer_id)

#
# Player creation
#

## Remove all players and add players for all peers.[br]
## Used to reset players and add spectators after a game-over.[br]
## Don't use on client ! Changes are automatically replicated on clients thanks to PlayerSpawner
func _recreate_all_players():
	var peer_list: Array = multiplayer.get_peers()
	if DisplayServer.get_name() != "headless": # Add server to list if server is not headless
		var server_peer_id: int = multiplayer.get_unique_id()
		peer_list.append(server_peer_id)
	
	for peer_id: int in peer_list:
		_remove_player(peer_id)
		_add_player(peer_id)

@rpc("any_peer", "call_local", "reliable")
func join_game():
	if not is_multiplayer_authority(): return
	var peer_id: int = multiplayer.get_remote_sender_id()
	
	# Don't do anything if the player already joined the game
	var is_already_playing: bool = PLAYERS_NODE.has_node(str(peer_id))
	if is_already_playing: return
	
	# Determine if peer should be a player or a spectator depending on the current level
	var can_become_player: bool = current_level == null or current_level.SPAWN_NEW_PLAYERS
	if can_become_player:
		_add_player(peer_id)
	else:
		add_spectator.rpc_id(peer_id)

## Add a player and assign it to [param peer_id].[br]
## Only called on server ! Automatically replicated on clients with MultiplayerSpawner
func _add_player(peer_id: int):
	print("[Server] Player added (%s)" % peer_id)
	var player: Player = PLAYER_SCENE.instantiate()
	
	player.name = str(peer_id) # Set player node name to peer id
	PLAYERS_NODE.add_child(player, true)
	
	# If the current level is null, wait for one
	if current_level == null:
		await scene_changed
	
	current_level.on_player_spawn(player)

## Remove a player assigned to [param peer_id] if it exists.[br]
## Only called on server ! Automatically replicated on clients with MultiplayerSpawner
func _remove_player(peer_id: int):
	var player_name: String = str(peer_id)
	var player: Player = PLAYERS_NODE.get_node_or_null(player_name)
	if player != null:
		if current_level != null:
			current_level.on_player_despawn(player)
		PLAYERS_NODE.remove_child(player)
		player.queue_free()

@rpc("reliable")
func add_spectator():
	# Become spectator
	var spectator: Spectator = SPECTATOR_SCENE.instantiate()
	add_child(spectator)
	
	# Wait for a level where we can spawn
	print("[%s] Waiting for a joinable level..." % multiplayer.get_unique_id())
	while current_level == null or not current_level.SPAWN_NEW_PLAYERS:
		await scene_changed
	
	# Ask authority to get added as player
	var authority_peer_id: int = get_multiplayer_authority()
	join_game.rpc_id(authority_peer_id)
	
	# Quit spectator mode
	remove_child(spectator)
	spectator.queue_free()
	
