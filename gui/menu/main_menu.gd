extends Control

signal host_server(ip: String, port: int, max_clients: int)
signal connect_to_server(ip: String, port: int)
signal quit_game

@onready var server_ip_field: LineEdit = $ContentContainer/ConnectionContainer/HostField
@onready var server_port_field: LineEdit = $ContentContainer/ConnectionContainer/PortField

@onready var connect_button: Button = $ContentContainer/ConnectionContainer/ConnectButton
@onready var host_button: Button = $ContentContainer/HostButton
@onready var quit_button: Button = $ContentContainer/QuitButton

func _ready():	
	_listen_button_signals()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _listen_button_signals(): # Could be done from node menu in editor
	connect_button.pressed.connect(on_connect_press)
	host_button.pressed.connect(on_host_press)
	quit_button.pressed.connect(on_quit_press)

func on_connect_press():
	var ip = server_ip_field.text
	var port_str = server_port_field.text
	var port = int(port_str)
	connect_to_server.emit(ip, port)

func on_host_press():
	# TODO Make it editable
	var ip = Main.DEFAULT_IP
	var port = Main.DEFAULT_PORT
	var max_clients = Main.DEFAULT_MAX_CLIENTS
	host_server.emit(ip, port, max_clients)

func on_quit_press():
	quit_game.emit()
