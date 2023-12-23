extends GameLevel

var players_ready: int = 0

#
# Initialization
#

func _initialize_player(player: Player):
	#player.set_default_abilities() TODO Recreate player instead
	super(player)

#
# Signals
#

func _on_start_game_area_body_entered(body):
	if not body is Player: return
	players_ready += 1
	
	# Don't start if all peers did not finish loading the lobby
	if not level_initialized:
		return
	
	# Check if everyone is in the starting area
	var players_count: int = players.get_child_count()
	var everyone_ready: bool = players_ready == players_count
	if everyone_ready and is_multiplayer_authority():
		change_level.emit(NEXT_LEVEL_SCENE)

func _on_start_game_area_body_exited(body):
	if not body is Player: return
	players_ready -= 1
