extends GameLevel

signal lobby_ready(rng_seed: int)

@export var PLAYER_SCENE: PackedScene

var players_ready: int = 0

func _ready():
	super()
	# Only need to spawn players on server thanks to PlayerSpawner
	if not multiplayer.is_server(): return
	
	_listen_multiplayer_signals()
	# Add the server as a player if server isn't headless
	if DisplayServer.get_name() != "headless":
		var server_player_id = multiplayer.get_unique_id()
		add_player(server_player_id)

func _exit_tree():
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_remove_multiplayer_signals()

#
# Players
#

func _listen_multiplayer_signals():
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)

func _remove_multiplayer_signals():
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(remove_player)

func add_player(id: int): # Server only
	print("[Server] Player joined (%s)" % id)
	var player: Player = PLAYER_SCENE.instantiate()
	player.name = str(id) # Set player node name as peer id
	PLAYERS.add_child(player, true) # Needs "force_readable_name" for using rpc

func remove_player(id: int): # Server only
	print("[Server] Player left (%s)" % id)
	var player_node_name = str(id)
	if PLAYERS.has_node(player_node_name):
		var player = PLAYERS.get_node(player_node_name)
		player.queue_free()

#
# Signals
#

func _on_start_game_area_body_entered(body):
	if not body is Player: return
	players_ready += 1
	
	var players_count: int = PLAYERS.get_child_count()
	var everyone_ready: bool = players_ready == players_count
	if everyone_ready and multiplayer.is_server():
		var new_seed: int = randi()
		lobby_ready.emit(new_seed)

func _on_start_game_area_body_exited(body):
	if not body is Player: return
	players_ready -= 1
