extends Control

func _ready():
	# Hide other players UI
	visible = is_multiplayer_authority()

#
# Player signals
#

func _on_player_health_update(old_health: float, new_health: float, _max_health: float):
	if old_health == new_health: return
	
	if old_health < new_health:
		play_heal_effect()
	else:
		play_damage_effect()

func _on_player_death():
	pass

#
# Interactible signals
#

func _on_player_interactible_hover_started(interactible: Interactible):
	print(interactible.INTERACTION_PROMPT_MESSAGE)


func _on_player_interactible_hover_ended():
	print("Stopped hovering")

#
# TODO Effects
#

func play_heal_effect():
	pass

func play_damage_effect():
	pass


