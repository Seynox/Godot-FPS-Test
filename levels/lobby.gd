extends GameLevel

## The scene created and assigned to a player when joining
@export var PLAYER_SCENE: PackedScene

var players_ready: int = 0

func _ready():
	_listen_multiplayer_signals()
	super()

func _exit_tree():
	if not multiplayer.has_multiplayer_peer():
		_disconnect_multiplayer_signals()
	super()

#
# Initialization
#

func _initialize_player(player: Player):
	player.set_default_abilities()
	super(player)

#
# Multiplayer signals
#

func _listen_multiplayer_signals():
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)

func _disconnect_multiplayer_signals():
	multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)
	multiplayer.peer_connected.disconnect(_on_peer_connected)

func _on_peer_connected(peer_id: int):
	if not is_multiplayer_authority(): return
	print("[Server] Peer joined (%s)" % peer_id)
	_add_player(peer_id)

func _on_peer_disconnected(peer_id: int):
	if not is_multiplayer_authority(): return
	print("[Server] Peer left (%s)" % peer_id)
	_remove_player(peer_id)

#
# Player management
#

## Add a player and assign it to [param peer_id].[br]
## Only called on server ! Automatically replicated on clients with MultiplayerSpawner
func _add_player(peer_id: int):
	print("[Server] Player added (%s)" % peer_id)
	var player: Player = PLAYER_SCENE.instantiate()
	player.name = str(peer_id) # Set player node name to peer id
	players.add_child(player, true)
	_on_player_spawn(player)

## Remove a player assigned to [param peer_id] if it exists.[br]
## Only called on server ! Automatically replicated on clients with MultiplayerSpawner
func _remove_player(peer_id: int):
	var player_name: String = str(peer_id)
	var player: Player = players.get_node_or_null(player_name)
	if player != null:
		_on_player_despawn(player)
		player.queue_free()

#
# Signals
#

func _on_start_game_area_body_entered(body):
	if not body is Player: return
	players_ready += 1
	
	var players_count: int = players.get_child_count()
	var everyone_ready: bool = players_ready == players_count
	if everyone_ready and is_multiplayer_authority():
		change_level.emit(NEXT_LEVEL_SCENE)

func _on_start_game_area_body_exited(body):
	if not body is Player: return
	players_ready -= 1
