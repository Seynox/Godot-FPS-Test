class_name MainMenu extends SceneChanger

signal host_server(ip: String, port: int, max_clients: int)
signal connect_to_server(ip: String, port: int)
signal quit_game

@export var SERVER_IP_FIELD: LineEdit
@export var SERVER_PORT_FIELD: LineEdit

func _ready():
	# Skip the menu if the game has no display
	if DisplayServer.get_name() == "headless":
		_change_to_next_scene()
		return
	
	SERVER_PORT_FIELD.text = str(Main.DEFAULT_PORT) # Set port to default value
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

#
# Buttons signals
#

func on_connect_press():
	var ip = SERVER_IP_FIELD.text
	var port_str = SERVER_PORT_FIELD.text
	var port = int(port_str)
	connect_to_server.emit(ip, port)
	_change_to_next_scene()

func on_host_press():
	# TODO Make it editable
	var ip = Main.DEFAULT_IP
	var port = Main.DEFAULT_PORT
	var max_clients = Main.DEFAULT_MAX_CLIENTS
	host_server.emit(ip, port, max_clients)
	_change_to_next_scene()

func on_quit_press():
	quit_game.emit()
