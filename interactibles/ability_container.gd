class_name AbilityContainer extends BreakableInteractible # TODO Sync

signal emptied

@export var BROKEN_INTERACTION_PROMPT_MESSAGE: String

## The ability to put inside the container.[br]
## Ignored if [member AbilityContainer.GENERATE_RANDOM_ABILITY] is true
@export var GENERATE_ABILITY: PackedScene

## If an ability should be generated randomly
@export var GENERATE_RANDOM_ABILITY: bool = true

## Restrict the ability generation to a specific rarity.[br]
## Set [enum Rarity.Level.NONE] to choose a rarity randomly
@export var GENERATE_WITH_RARITY: Rarity.Level = Rarity.Level.NONE

## The current level. Used to know what items can be generated.
## Ignored if [member AbilityContainer.GENERATE_RANDOM_ABILITY] is false
@export var CURRENT_LEVEL: int

## The ability inside the container. Does not become null after being taken
var ability_contained: Ability

## If the container contains an ability
var is_empty: bool = false

func _ready():
	ability_contained = _generate_container_ability()
	if ability_contained == null:
		set_empty()
	else:
		# Common = 1 hit, Uncommon = 2 hits etc..
		HITS_NEEDED = ability_contained.RARITY
		print("[Peer %s] Ability: %s" % [multiplayer.get_unique_id(), ability_contained.NAME]) # TODO Remove

## Generate an ability inside the container.[br]
## Uses [AbilityContainer] members to determine the ability to generate.
func _generate_container_ability() -> Ability:
	if !GENERATE_RANDOM_ABILITY:
		if GENERATE_ABILITY == null:
			return null
		return GENERATE_ABILITY.instantiate()
	
	var rarity: Rarity.Level = GENERATE_WITH_RARITY
	if rarity == Rarity.Level.NONE:
		rarity = Rarity.get_random_rarity()

	return AbilityRegistry.get_random_ability(rarity, CURRENT_LEVEL)

## Interacting hits the object if it is not broken.
## Otherwise, take the contained ability.[br]
func _interact(player: Player):
	if IS_BROKEN:
		_ability_taken_by(player)
	else:
		try_getting_hit_by(player)
	super(player)

## Give the ability contained in [member AbilityContainer.ability_contained]
## to the [param player][br]
## Makes the container empty
func _ability_taken_by(player: Player):
	player.set_ability(ability_contained)
	set_empty.rpc()

@rpc("any_peer", "call_local", "reliable")
func set_empty():
	is_empty = true
	CAN_BE_INTERACTED_WITH = false
	CAN_BE_HIT = false
	emptied.emit()

func set_broken():
	var item_prompt = "%s %s" % [BROKEN_INTERACTION_PROMPT_MESSAGE, ability_contained.NAME]
	INTERACTION_PROMPT_MESSAGE = item_prompt
	super()
