class_name PlayerInfos extends Control

@export var HEALTHBAR: ProgressBar
@export var ABILITIES: HBoxContainer

#
# Player signals
#

func _on_player_health_update(_old_health: float, new_health: float, max_health: float):
	HEALTHBAR.max_value = max_health
	HEALTHBAR.value = new_health

func _on_player_ability_changed(_player: Player, ability_type: String, ability: Ability):
	var current: Control = ABILITIES.get_node_or_null(ability_type)
	if ability == null:
		if current != null: current.queue_free()
		return
	
	# Just a label for now
	var label: Label = Label.new()
	label.text = ability.NAME
	label.name = ability_type
	
	# Add or replace
	if current == null:
		ABILITIES.add_child(label)
	else:
		current.replace_by(label)
		current.queue_free()
