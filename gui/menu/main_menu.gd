class_name MainMenu extends Control

signal start_lobby

const DEFAULT_IP: String = "127.0.0.1" # All interfaces
const DEFAULT_PORT: int = 8000
const DEFAULT_MAX_CLIENTS: int = 20

@export var SERVER_IP_FIELD: LineEdit
@export var SERVER_PORT_FIELD: LineEdit

func _ready():
	# Host server if started as headless
	if DisplayServer.get_name() == "headless":
		_host_headless()
		return
	
	SERVER_PORT_FIELD.text = str(DEFAULT_PORT) # Set port to default value

#
# Connect to multiplayer
#

func host_server(ip: String, port: int, max_clients: int):
	var peer = ENetMultiplayerPeer.new()
	peer.set_bind_ip(ip)
	var error = peer.create_server(port, max_clients)
	if error:
		print("Could not host server on port %s" % port)
		return
	
	print("Hosting server on %s:%s" % [ip, port])
	multiplayer.multiplayer_peer = peer
	start_lobby.emit()

func connect_to_server(ip: String, port: int):
	print("[Multiplayer] Connecting to %s:%s..." % [ip, port])
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)
	if error:
		print("Could not connect to server")
		return
	
	multiplayer.multiplayer_peer = peer

func _host_headless():
	var args : Dictionary = _parse_command_args()
	var ip = args.get("ip", "*")
	var port = args.get("port", DEFAULT_PORT)
	var max_clients = args.get("max-clients", DEFAULT_MAX_CLIENTS)
	
	host_server(ip, int(port), int(max_clients))

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
# Buttons signals
#

func on_connect_press():
	var ip = _get_ip(false)
	var port = _get_port()
	connect_to_server(ip, port)

func on_host_press():
	var ip = _get_ip(true)
	var port: int = _get_port()
	var max_clients: int = DEFAULT_MAX_CLIENTS
	host_server(ip, port, max_clients)

func on_quit_press():
	print("[Game] Quitting")
	multiplayer.multiplayer_peer = null
	get_tree().quit()

#
# Menu signals
#

func _on_visibility_changed():
	if visible and DisplayServer.get_name() != "headless":
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
#
# Inputs
#

func _get_port() -> int:
	var input: String = SERVER_PORT_FIELD.text
	if input.is_valid_int():
		return int(input)
	return DEFAULT_PORT

func _get_ip(is_hosting: bool) -> String:
	var input: String = SERVER_IP_FIELD.text
	if not input.is_empty():
		return input
	return "*" if is_hosting else DEFAULT_IP
