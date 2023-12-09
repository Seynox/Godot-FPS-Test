extends Node3D

@export var PLAYER_SCENE: PackedScene

func _ready():
	# Only need to spawn players on server thanks to PlayerSpawner
	if !multiplayer.is_server():
		return
	
	_listen_player_signals()
	
	if DisplayServer.get_name() != "headless":
		var server_player_id = 1
		add_player(server_player_id)

func _exit_tree():
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_remove_player_signals()
#
# Players
#

func _listen_player_signals():
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)

func _remove_player_signals():
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(remove_player)

func add_player(id: int):
	print("Adding player %s" % id)
	var player = PLAYER_SCENE.instantiate()
	player.name = str(id) # Node name
	$Players.add_child(player, true) # Needs "force_readable_name" for using rpc

func remove_player(id: int):
	print("Removing player %s" % id)
	var player_node_name = str(id)
	if $Players.has_node(player_node_name):
		var player = $Players.get_node(player_node_name)
		player.queue_free()
