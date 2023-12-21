extends GameLevel

var players_ready: int = 0

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
