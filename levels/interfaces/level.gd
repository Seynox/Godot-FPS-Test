class_name GameLevel extends SceneChanger

## The signal emitted when a player finished loading the level (TODO)
signal loaded

## The signal emitted when the game is lost.
signal game_over

## The current level name
@export var LEVEL_NAME: String

## The node to use as a player spawnpoint
@export var PLAYER_SPAWN: Node3D

## The node containing all players.[br]
## Automatically assigned when changing scene. Should be done manually in sub-levels.
@export var PLAYERS: Node3D

func _ready():
	PLAYERS.global_position = get_spawnpoint()
	_initialize_player.call_deferred()
	loaded.emit()

func _initialize_player():
	var player_name: String = str(multiplayer.get_unique_id())
	var local_player: Player = PLAYERS.get_node_or_null(player_name)
	if local_player != null:
		local_player.global_position = get_spawnpoint()
		_listen_player_signals(local_player)

## Get the level's [member GameLevel.PLAYER_SPAWN] position.[br]
## Return [member Vector3.ZERO] if [member GameLevel.PLAYER_SPAWN] is not set
func get_spawnpoint() -> Vector3:
	if PLAYER_SPAWN == null:
		return Vector3.ZERO
	
	return PLAYER_SPAWN.global_position

#
# Player signals
#

func _listen_player_signals(player: Player):
	player.death.connect(on_player_death.bind(player))
	player.out_of_map.connect(on_player_out_of_map.bind(player))

## Called when a player dies.[br]
## By default, emit [signal GameLevel.game_over] if everyone is dead.
func on_player_death(_dead_player: Player):
	# Check if everyone is dead
	var someone_is_alive: bool = false
	for player: Player in PLAYERS.get_children():
		if not player.is_dead():
			someone_is_alive = true
			break
	# Send game over if everyone is dead
	if not someone_is_alive:
		game_over.emit()

## Called when a player gets out of the map.[br]
## Teleports the player to spawn by default.
func on_player_out_of_map(player: Player):
	teleport_to_player_spawn(player)

#
# Players
#

## Teleport the entity to the player spawn.[br]
## Player spawn is set by [member GameLevel.PLAYER_SPAWN] node position.[br]
## If [member GameLevel.PLAYER_SPAWN] is null, spawn will be [member Vector3.ZERO].
func teleport_to_player_spawn(entity: Entity):
	var spawnpoint: Vector3 = PLAYER_SPAWN.global_position if PLAYER_SPAWN != null else Vector3.ZERO
	entity.global_position = spawnpoint
