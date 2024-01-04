class_name PlayerInfos extends Control

@export var HEALTHBAR: ProgressBar
@export var ABILITIES: HBoxContainer

#
# Player signals
#

func _on_player_health_update(_old_health: float, new_health: float, max_health: float):
	HEALTHBAR.max_value = max_health
	HEALTHBAR.value = new_health

func _on_player_ability_added(ability: Ability):
	var label: Label = Label.new()
	label.text = ability.NAME
	label.name = ability.IDENTIFIER_NAME
	ABILITIES.add_child(label, true)


func _on_player_ability_removed(ability_identifier: String):
	var label: Label = ABILITIES.get_node_or_null(ability_identifier)
	if label != null:
		ABILITIES.remove_child(label)
		label.queue_free()
