class_name AbilityContainer extends BreakableInteractible
# FIXME "ContainerSynchronizer" node being null when joining after initialization
# Is container loaded before level?

signal emptied

## The message to display when prompted to interact with the broken container
@export var BROKEN_INTERACTION_PROMPT_MESSAGE: String

## If an ability should be generated randomly on initialization
@export var GENERATE_RANDOM_ABILITY: bool = true

## Restrict the ability generation to a specific rarity.[br]
## Set [enum Rarity.Level.NONE] to use a random rarity
@export var GENERATE_WITH_RARITY: Rarity.Level = Rarity.Level.NONE

## The current level. Used to know what items can be generated.
## Ignored if [member AbilityContainer.GENERATE_RANDOM_ABILITY] is false
@export var CURRENT_LEVEL: int

## The scene path of the ability inside the container. Empty string if empty.
@export var ABILITY_CONTAINED: String

# Local variables. Used to know if signals were already sent
var locally_empty: bool

func _ready():
	super()
	_generate_contained_ability()

## Generate an ability inside the container.[br]
## Authority only
func _generate_contained_ability():
	if not is_multiplayer_authority() or not GENERATE_RANDOM_ABILITY:
		return
	
	var rarity: Rarity.Level = GENERATE_WITH_RARITY
	if rarity == Rarity.Level.NONE:
		rarity = Rarity.get_random_rarity()

	ABILITY_CONTAINED = AbilityRegistry.get_random_ability(rarity, CURRENT_LEVEL)
	if ABILITY_CONTAINED.is_empty():
		set_empty()
		return
	
	var ability: Ability = _get_ability()
	
	print("[DEBUG] Server generated ability: ", ability.NAME)
	
	# Common = 1 hit, Uncommon = 2 hits etc
	HITS_NEEDED = ability.RARITY
	
	ability.queue_free()

func _update():
	print("[Peer %s] Updating container! Ability path: %s" % [multiplayer.get_unique_id(), ABILITY_CONTAINED])
	if ABILITY_CONTAINED.is_empty():
		if not locally_empty:
			emptied.emit()
			locally_empty = true
		return
	
	locally_empty = false
	super()

## Interacting hits the object if it is not broken.
## Otherwise, take the contained ability.[br]
func _interact(player: Player):
	if IS_BROKEN:
		_ability_taken_by(player)
	else:
		try_getting_hit_by(player)
	super(player)

## Give the ability contained in [member AbilityContainer.ABILITY_CONTAINED]
## to the [param player][br]
## Makes the container empty
func _ability_taken_by(player: Player):
	var ability: Ability = _get_ability()
	player.set_ability(ability)
	
	var server_peer_id: int = 1
	set_empty.rpc_id(server_peer_id)

func _get_ability() -> Ability:
	if ABILITY_CONTAINED.is_empty():
		return null
	
	var ability_scene: PackedScene = load(ABILITY_CONTAINED)
	return ability_scene.instantiate()

@rpc("any_peer", "call_local", "reliable")
func set_empty():
	if not is_multiplayer_authority():
		return
	
	ABILITY_CONTAINED = ""
	CAN_BE_INTERACTED_WITH = false
	CAN_BE_HIT = false
	_update()

func set_broken():
	if not is_multiplayer_authority():
		return
	
	var ability: Ability = _get_ability()
	var item_prompt = "%s %s" % [BROKEN_INTERACTION_PROMPT_MESSAGE, ability.NAME]
	INTERACTION_PROMPT_MESSAGE = item_prompt
	
	ability.queue_free()
	super()
