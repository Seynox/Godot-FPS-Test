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

func get_random_ability(rarity: Rarity.Level, maximum_level: int = 0) -> Ability:
	var abilities: Array = AbilityRegistry.ABILITIES.get(rarity, [])
	abilities = abilities.filter(
		func(ability):
			return _can_ability_be_generated(ability, maximum_level)
	)
	
	if abilities.is_empty():
		return null
	
	var possibilities: int = abilities.size() - 1
	var random_index: int = randi_range(0, possibilities)
	
	var ability_scene: PackedScene = abilities[random_index]
	return ability_scene.instantiate()

func _can_ability_be_generated(scene: PackedScene, maximum_level: int) -> bool:
	var ability: Ability = scene.instantiate()
	var is_at_valid_level: bool = maximum_level >= ability.GENERATE_SINCE_LEVEL
	ability.queue_free()
	return is_at_valid_level
