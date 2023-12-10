extends Node

var ABILITIES: Dictionary = {
	# Rarity = [PackedScene...]
}

const ALL_ABILITY_SCENES: Array = [
	preload("res://abilities/dashes/foward_dash.tscn"),
	preload("res://abilities/dashes/impulse_dash.tscn"),
	preload("res://abilities/jumps/multi_jump.tscn"),
	preload("res://abilities/jumps/simple_jump.tscn"),
	preload("res://abilities/weapons/hitscan_weapon.tscn")
]

func _ready():
	# TODO Do it in another thread?
	_sort_abilities()

func _sort_abilities():
	for ability_scene: PackedScene in ALL_ABILITY_SCENES:
		var ability: Ability = ability_scene.instantiate()
		var rarity: Rarity.Level = ability.RARITY
		
		_append_ability(rarity, ability_scene)
		ability.queue_free()

func _append_ability(rarity: Rarity.Level, ability: PackedScene):
	var abilities_list: Array = ABILITIES.get(rarity, [])
	abilities_list.append(ability)
	ABILITIES[rarity] = abilities_list
