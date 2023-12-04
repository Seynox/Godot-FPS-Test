extends Control

@onready var player_list_view: BoxContainer = $ContentContainer/PlayerList

# {peer_id: is_ready}
var lobby: Dictionary = {}

func _ready():
	_start_listening_signals()
	
	if DisplayServer.get_name() != "headless":
		_on_server_connect() # Add server as a player
	
func _start_listening_signals():
	multiplayer.peer_connected.connect(_on_player_connect)
	multiplayer.peer_disconnected.connect(_on_player_disconnect)
	
	# Client-only signals
	multiplayer.server_disconnected.connect(_on_server_disconnect)
	multiplayer.connected_to_server.connect(_on_server_connect)

func _set_player_ready(id: int, is_ready: bool):
	print("Player %s changed ready to: %s" % [id, is_ready])
	lobby[id] = is_ready
	update_playerlist()
	
	if multiplayer.is_server():
		if _is_everyone_ready():
			start_game.rpc()
		

func _is_everyone_ready() -> bool:
	for is_ready in lobby.values():
		if !is_ready:
			return false
	return true

#
# Signal callbacks
#

func _on_server_connect(): # Client only
	print("Joined lobby")
	var self_id = multiplayer.get_unique_id()
	_set_player_ready(self_id, false)

func _on_server_disconnect(): # Client only
	print("Server disconnected")
	quit()

func _on_player_connect(id: int):
	print("Player (%s) joined" % id)
	
	# Send our ready status to new player
	var self_id = multiplayer.get_unique_id()
	var is_self_ready = lobby[self_id]
	on_player_ready_update.rpc_id(id, is_self_ready)
	
	# Add new player to view
	lobby[id] = false
	_append_player_to_view(id, false)
	
func _on_player_disconnect(id: int):
	print("Player (%s) left" % id)
	lobby.erase(id)
	update_playerlist()

@rpc("any_peer", "call_local", "reliable")
func on_player_ready_update(is_ready: bool):
	var sender_id = multiplayer.get_remote_sender_id()
	_set_player_ready(sender_id, is_ready)

@rpc("call_local", "reliable")
func start_game(): # TODO
	print("Starting game!")

#
# Lobby view
#

func _append_player_to_view(player_id: int, is_ready: bool):
	var text = "Player %s (Ready: %s)" % [player_id, is_ready]
	
	var label = Label.new()
	label.text = text
	player_list_view.add_child(label)

func _clear_playerlist():
	var players_label = player_list_view.get_children()
	for player_label in players_label:
		player_list_view.remove_child(player_label)
		player_label.queue_free()

func update_playerlist():
	_clear_playerlist()
	for player_id in lobby.keys():
		var is_ready = lobby[player_id]
		_append_player_to_view(player_id, is_ready)

func set_ready(is_ready: bool):
	on_player_ready_update.rpc(is_ready)

func quit():
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://gui/menu/multiplayer_menu.tscn")
