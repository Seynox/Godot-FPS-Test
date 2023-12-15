class_name Main extends Node

const DEFAULT_IP: String = "*" # All interfaces
const DEFAULT_PORT: int = 8000
const DEFAULT_MAX_CLIENTS: int = 20

# TODO Refactor
@export var MAIN_MENU_SCENE: PackedScene
@export var FIRST_GAME_SCENE: PackedScene 

@onready var players_container: Node3D = $Players

var current_scene: Node

func _ready():
	if DisplayServer.get_name() != "headless":
		_open_main_menu()
		return
	
	# Host server if started as headless
	var args := _parse_command_args()
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

func _start_multiplayer_game(peer: MultiplayerPeer):
	multiplayer.multiplayer_peer = peer # Connect to multiplayer
	_listen_connection_signals()
	_change_level(FIRST_GAME_SCENE.instantiate())

func quit_game():
	print("[Game] Quitting")
	get_tree().quit()

func _change_level(level: GameLevel):
	_change_scene(level)
	_listen_level_signals(level)
	
	# Set players spawn to level spawnpoint
	players_container.global_position = level.PLAYER_SPAWN.global_position
	for player: Player in players_container.get_children():
		player.position = Vector3.ZERO

func _open_main_menu():
	multiplayer.multiplayer_peer = null # Disconnect from multiplayer
	var menu = MAIN_MENU_SCENE.instantiate()
	_change_scene(menu)
	_listen_main_menu_signals(menu)

func _change_scene(scene: Node):
	if current_scene != null:
		current_scene.queue_free()
	current_scene = scene
	add_child(scene)

#
# Signals
#

func _listen_connection_signals():
	# Client-only signals
	multiplayer.server_disconnected.connect(_on_server_disconnect)
	multiplayer.connection_failed.connect(_on_server_connection_failed)

func _listen_main_menu_signals(menu: Node):
	menu.connect("quit_game", quit_game)
	menu.connect("connect_to_server", connect_to_server)
	menu.connect("host_server", host_server)
	
func _listen_level_signals(level: GameLevel):
	level.level_finished.connect(on_level_finished)
	if level.has_signal("seed_refresh"):
		level.seed_refresh.connect(on_seed_refresh)

func on_level_finished():
	var next_level: GameLevel = current_scene.NEXT_LEVEL.instantiate()
	_change_level(next_level)

func on_seed_refresh():
	# Server only
	if not multiplayer.is_server(): return
	var new_seed: int = randi()
	spread_seed.rpc(new_seed)

#
# Game
#

@rpc("call_local", "reliable")
func spread_seed(new_seed: int):
	print("New seed: ", new_seed)
	seed(new_seed)

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
	_start_multiplayer_game(peer)

func connect_to_server(ip: String, port: int):	
	print("Connecting to %s:%s..." % [ip, port])
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)
	if error:
		print("Could not connect to server")
		return
	
	_start_multiplayer_game(peer)

func _on_server_connection_failed():
	print("Connection failed")
	_open_main_menu()

func _on_server_disconnect():
	print("[Multiplayer] Server disconnected")
	_open_main_menu()
