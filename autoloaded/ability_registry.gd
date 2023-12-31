extends Node

var ABILITIES: Dictionary = {
	# Rarity = [String...]
}

const ALL_ABILITY_SCENES: Array = [
	"res://abilities/dashes/foward_dash.tscn",
	"res://abilities/dashes/impulse_dash.tscn",
	"res://abilities/jumps/simple_jump.tscn",
	"res://abilities/weapons/revolver.tscn"
]

func _ready():
	_sort_abilities()

func _sort_abilities():
	for ability_path: String in ALL_ABILITY_SCENES:
		var ability_scene: PackedScene = load(ability_path)
		var ability: Ability = ability_scene.instantiate()
		var rarity: Rarity.Level = ability.RARITY
		
		_append_ability(rarity, ability_path)
		ability.queue_free()

func _append_ability(rarity: Rarity.Level, ability: String):
	var abilities_list: Array = ABILITIES.get(rarity, [])
	abilities_list.append(ability)
	ABILITIES[rarity] = abilities_list

func get_random_ability(rarity: Rarity.Level, maximum_level: int = 0) -> String:
	var abilities: Array = AbilityRegistry.ABILITIES.get(rarity, [])
	var generatable_abilities = abilities.filter(
		func(ability_path):
			return _can_ability_be_generated(ability_path, maximum_level)
	)
	
	if generatable_abilities.is_empty():
		return ""
	
	var possibilities: int = generatable_abilities.size() - 1
	var random_index: int = randi_range(0, possibilities)
	
	return generatable_abilities[random_index]

func _can_ability_be_generated(ability_path: String, maximum_level: int) -> bool:
	var ability_scene: PackedScene = load(ability_path)
	var ability: Ability = ability_scene.instantiate()
	var is_at_valid_level: bool = maximum_level >= ability.GENERATE_SINCE_LEVEL
	
	ability.queue_free()
	return is_at_valid_level
