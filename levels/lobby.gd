extends GameLevel

@export var PLAYER_SCENE: PackedScene
@export var LEVEL_SCENE: PackedScene

var players_ready: int = 0

func _ready():
	super()

	# Add the server as a player if server isn't headless
	if multiplayer.is_server() and DisplayServer.get_name() != "headless":
		var server_player_id = multiplayer.get_unique_id()
		_on_peer_connected(server_player_id)


#
# Players
#

func _on_peer_connected(peer_id: int):
	print("[Server] Player joined (%s)" % peer_id)
	var player: Player = PLAYER_SCENE.instantiate()
	player.name = str(peer_id) # Set player node name as peer id
	PLAYERS.add_child(player, true) # Needs "force_readable_name" for using rpc

#
# Signals
#

func _on_start_game_area_body_entered(body):
	if not body is Player: return
	players_ready += 1
	
	var players_count: int = PLAYERS.get_child_count()
	var everyone_ready: bool = players_ready == players_count
	if everyone_ready and multiplayer.is_server():
		change_level.emit(LEVEL_SCENE)

func _on_start_game_area_body_exited(body):
	if not body is Player: return
	players_ready -= 1
