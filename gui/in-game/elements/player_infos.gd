class_name PlayerInfos extends Control

@onready var healthbar: ProgressBar = $Healthbar
@onready var abilities: HBoxContainer = $Abilities

#
# Player signals
#

func _on_player_health_update(_old_health: float, new_health: float, max_health: float):
	healthbar.max_value = max_health
	healthbar.value = new_health

func _on_player_ability_changed(_player: Player, ability_type: String, ability: Ability):
	var current: Control = abilities.get_node_or_null(ability_type)
	if ability == null:
		if current != null: current.queue_free()
		return
	
	# Just a label for now
	var label: Label = Label.new()
	label.text = ability.NAME
	label.name = ability_type
	
	# Add or replace
	if current == null:
		abilities.add_child(label)
	else:
		current.replace_by(label)
		current.queue_free()
