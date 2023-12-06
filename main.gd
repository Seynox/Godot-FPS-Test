class_name Main extends Node

const DEFAULT_IP: String = "*" # All interfaces
const DEFAULT_PORT: int = 8000
const DEFAULT_MAX_CLIENTS: int = 20

@export var MAIN_MENU_SCENE: PackedScene
@export var FIRST_GAME_SCENE: PackedScene 

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
	
	_host_server.call_deferred(ip, int(port), int(max_clients))

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
	print("Quitting")
	get_tree().quit()

func _change_level(level: Node):
	_change_scene(level)
	_listen_level_signals(level)

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
	multiplayer.connected_to_server.connect(_on_server_connect)
	multiplayer.connection_failed.connect(_on_server_connection_failed)

func _listen_main_menu_signals(menu: Node):
	print("Registering menu signals")
	menu.connect("quit_game", quit_game)
	menu.connect("connect_to_server", connect_to_server)
	menu.connect("host_server", host_server_and_play)
	
func _listen_level_signals(_level: Node):
	pass

#
# Server connection/hosting
#

func _host_server(ip: String, port: int, max_clients: int):
	var peer = ENetMultiplayerPeer.new()
	peer.set_bind_ip(ip)
	var error = peer.create_server(port, max_clients)
	if error:
		print("Could not host server on port %s" % port)
		return
	
	print("Hosting server on %s:%s" % [ip, port])
	_start_multiplayer_game(peer)

func host_server_and_play(ip: String, port: int, max_clients: int):
	print("Host and play")
	_host_server(ip, port, max_clients)
	_on_server_connect()

func connect_to_server(ip: String, port: int):	
	print("Connecting to %s:%s" % [ip, port])
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)
	if error:
		print("Could not connect to server")
		return
	
	print("Connected to server!")
	_start_multiplayer_game(peer)

func _on_server_connection_failed():
	print("Connection failed")
	_open_main_menu()

#
# Server connection
#

func _on_server_connect():
	print("Joined lobby as %s" % multiplayer.get_unique_id())

func _on_server_disconnect():
	print("Server disconnected")
	_open_main_menu()
