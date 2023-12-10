extends Node3D

@export var GENERATE_ABILITY: PackedScene # The ability to generate in the container. Ignore if random ability is true
@export var GENERATE_RANDOM_ABILITY: bool = true
@export var GENERATE_WITH_RARITY: Rarity.Level = Rarity.Level.NONE # None = Choosen randomly
@export var CURRENT_LEVEL: int # Used to know what items can be generated.

var ability_contained: Ability
var is_empty: bool

func _ready():
	if GENERATE_RANDOM_ABILITY:
		var rarity: Rarity.Level = GENERATE_WITH_RARITY
		if rarity == Rarity.Level.NONE:
			rarity = Rarity.get_random_rarity()
		
		ability_contained = _get_random_ability(rarity)
	elif GENERATE_ABILITY != null:
		ability_contained = GENERATE_ABILITY.instantiate()
	
	print("null") if ability_contained == null else print(ability_contained.NAME) # TODO Remove debug print
	is_empty = ability_contained == null

func _get_random_ability(rarity: Rarity.Level) -> Ability:
	var abilities: Array = AbilityRegistry.ABILITIES.get(rarity, [])
	if abilities.is_empty():
		return null
	
	var possibilities: int = abilities.size() - 1
	var random_index: int = randi_range(0, possibilities)
	
	var ability_scene: PackedScene = abilities[random_index]
	return ability_scene.instantiate()
