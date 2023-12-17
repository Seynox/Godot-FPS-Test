class_name Main extends Node

const DEFAULT_IP: String = "127.0.0.1" # All interfaces
const DEFAULT_PORT: int = 8000
const DEFAULT_MAX_CLIENTS: int = 20

## The scene to put when the game is started
@export var FIRST_SCENE: PackedScene

## The scene to put when receiving a game over signal
@export var GAME_OVER_SCENE: PackedScene

## The node containing the players
@export var PLAYERS_NODE: Node3D

## The current displayed scene
var current_scene: SceneChanger

func _ready():
	# Host server if started as headless
	if DisplayServer.get_name() == "headless":
		_host_headless()
	_change_scene(FIRST_SCENE.instantiate())

func _host_headless():
	var args : Dictionary = _parse_command_args()
	var ip = args.get("ip", DEFAULT_IP)
	var port = args.get("port", DEFAULT_PORT)
	var max_clients = args.get("max-clients", DEFAULT_MAX_CLIENTS)
	
	host_server.call_deferred(ip, int(port), int(max_clients))

func _parse_command_args() -> Dictionary:
	var args = {}
	var latest_key: String
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--"):
			latest_key = arg.right(-2) # Removes the "--"
		else:
			args[latest_key] = arg
	return args

#
# Changing scene
#

func _change_scene(scene: SceneChanger):
	if current_scene != null:
		current_scene.queue_free()
	
	# Connect scene signals
	scene.change_scene.connect(_change_scene)
	if scene is GameLevel:
		scene.PLAYERS = PLAYERS_NODE # Gives a reference to the players node
		_listen_level_signals(scene)
	elif scene is MainMenu:
		_listen_main_menu_signals(scene)
	
	current_scene = scene
	add_child(scene, true)

func quit_game():
	print("[Game] Quitting")
	_quit_multiplayer()
	queue_free()
	get_tree().quit()

#
# Multiplayer
#

func set_multiplayer(peer: MultiplayerPeer):
	multiplayer.multiplayer_peer = peer # Connect to multiplayer
	_listen_connection_signals()

func _quit_multiplayer():
	_disconnect_connection_signals()
	multiplayer.multiplayer_peer = null
	_change_scene(FIRST_SCENE.instantiate())

#
# Signals listeners
#

func _listen_connection_signals():
	# Client-only signals
	multiplayer.server_disconnected.connect(_on_server_disconnect)
	multiplayer.connection_failed.connect(_on_server_connection_failed)

func _disconnect_connection_signals():
	multiplayer.server_disconnected.disconnect(_on_server_disconnect)
	multiplayer.connection_failed.disconnect(_on_server_connection_failed)

func _listen_main_menu_signals(menu: MainMenu):
	menu.quit_game.connect(quit_game)
	menu.connect_to_server.connect(connect_to_server)
	menu.host_server.connect(host_server)
	
func _listen_level_signals(level: GameLevel):
	level.game_over.connect(_on_game_over)
	
	if level.has_signal("lobby_ready"):
		level.lobby_ready.connect(_on_lobby_ready)

#
# Game
#

func _on_lobby_ready(rng_seed: int):
	start_run.rpc(rng_seed)

@rpc("call_local", "reliable")
func start_run(rng_seed: int):
	print("[Peer %s] Received seed: %s" % [multiplayer.get_unique_id(), rng_seed])
	seed(rng_seed)
	_change_scene(current_scene.NEXT_SCENE.instantiate())

func _on_game_over():
	print("[GAME] Game over!")
	_change_scene(GAME_OVER_SCENE.instantiate())

#
# Server connection/hosting
#

func host_server(ip: String, port: int, max_clients: int):
	var peer = ENetMultiplayerPeer.new()
	peer.set_bind_ip(ip)
	var error = peer.create_server(port, max_clients)
	if error:
		print("Could not host server on port %s" % port)
		return
	
	print("Hosting server on %s:%s" % [ip, port])
	set_multiplayer(peer)

func connect_to_server(ip: String, port: int):
	print("[Multiplayer] Connecting to %s:%s..." % [ip, port])
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)
	if error:
		print("Could not connect to server")
		return
	
	set_multiplayer(peer)

func _on_server_connection_failed():
	print("[Multiplayer] Connection to server failed")
	_quit_multiplayer()

func _on_server_disconnect():
	print("[Multiplayer] Server disconnected")
	_quit_multiplayer()
