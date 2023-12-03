extends Control

@onready var server_ip_field: LineEdit = $ContentContainer/ConnectionContainer/HostField
@onready var server_port_field: LineEdit = $ContentContainer/ConnectionContainer/PortField

@onready var connect_button: Button = $ContentContainer/ConnectionContainer/ConnectButton

const DEFAULT_PORT: int = 8000
const MAX_CLIENTS: int = 10

func _ready():
	if DisplayServer.get_name() == "headless":
		host_server()
		return
	server_port_field.text = str(DEFAULT_PORT)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func connect_to_server():
	connect_button.disabled = true
	
	var server_ip = server_ip_field.text
	var server_port = server_port_field.text
	
	print("Connecting to %s:%s" % [server_ip, server_port])
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(server_ip, int(server_port))
	if error:
		print("Could not connect to server")
		connect_button.disabled = false
		return
	
	print("Connected to server!")
	multiplayer.multiplayer_peer = peer
	_show_lobby()

func host_server():
	var listening_ip = "*" # All interfaces
	
	var peer = ENetMultiplayerPeer.new()
	peer.set_bind_ip(listening_ip)
	var error = peer.create_server(DEFAULT_PORT, MAX_CLIENTS)
	if error:
		print("Could not host server on port %s" % DEFAULT_PORT)
		return
	
	print("Hosting server on %s:%s" % [listening_ip, DEFAULT_PORT])
	multiplayer.multiplayer_peer = peer
	_show_lobby()
	
func _show_lobby():
	get_tree().change_scene_to_file("res://gui/menu/lobby_menu.tscn")

func quit_game():
	get_tree().quit()
