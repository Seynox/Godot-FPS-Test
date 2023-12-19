class_name Main extends Node

## The scene to put when the game is started
@export var LOBBY_SCENE: PackedScene

## The node containing the players
@export var PLAYERS_NODE: Node3D

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
		current_level.free()
	
	var scene: GameLevel = packed_scene.instantiate()
	scene.PLAYERS = PLAYERS_NODE # Gives a reference to the players node
	_listen_level_signals(scene)
	
	current_level = scene
	add_child(scene, true)

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

#
# Game

func _on_game_over():
	print("[GAME] Game over!")
	set_new_level(LOBBY_SCENE)

#
# Server connection/hosting
#

func _quit_game():
	multiplayer.multiplayer_peer = null
	MENU.show()
	current_level.queue_free()

func _on_server_connection_failed():
	print("[Multiplayer] Connection to server failed")
	_quit_game()

func _on_server_disconnect():
	print("[Multiplayer] Server disconnected")
	_quit_game()

func _on_peer_connected(peer_id: int):
	if multiplayer.is_server():
		change_client_level.rpc_id(peer_id, current_level_path)
