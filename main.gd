class_name Main extends Node

signal scene_changed

## The scene to put when the game is started
@export var LOBBY_SCENE: PackedScene

## The node containing the players
@export var PLAYERS_NODE: Node3D

## The multiplayer spawner spawning players
@export var PLAYER_SPAWNER: MultiplayerSpawner

## The main menu
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
		current_level._on_peer_connected(server_peer_id)

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
	multiplayer.connected_to_server.connect(MENU.hide)
	
	# Client-only signals
	multiplayer.server_disconnected.connect(_on_server_disconnect)
	multiplayer.connection_failed.connect(_on_server_connection_failed)

	
func _listen_level_signals(level: GameLevel):
	level.change_level.connect(set_new_level)
	level.game_over.connect(_on_game_over)

func _disconnect_level_signals(level: GameLevel):
	level.change_level.disconnect(set_new_level)
	level.game_over.disconnect(_on_game_over)

func _listen_spawner_signals(level: GameLevel):
	PLAYER_SPAWNER.spawned.connect(level._on_player_spawn)
	PLAYER_SPAWNER.despawned.connect(level._on_player_despawn)

func _disconnect_spawner_signals(level: GameLevel):
	PLAYER_SPAWNER.spawned.disconnect(level._on_player_spawn)
	PLAYER_SPAWNER.despawned.disconnect(level._on_player_despawn)

#
# Game

func _on_game_over():
	print("[GAME] Game over!")
	# TODO Save game
	set_new_level(LOBBY_SCENE)

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

func _on_peer_connected(peer_id: int):
	if multiplayer.is_server(): # Send current scene to new peer
		change_client_level.rpc_id(peer_id, current_level_path)
