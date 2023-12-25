class_name Ability extends Node3D

@export_category("Ability")
@export var NAME: String
@export var DESCRIPTION: String

@export_subgroup("Generation")
@export var RARITY: Rarity.Level # The rarity to be found in a container. NONE = Cannot be generated
@export var GENERATE_SINCE_LEVEL: int # The minimum level number in which the ability can be generated


## The ability type.
## Should only be overriden by a direct child of the [Ability] class.
func get_ability_type() -> String:
	return "none"
