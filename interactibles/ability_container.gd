class_name AbilityContainer extends BreakableInteractible

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

## If the container has been locally initialized. True after the first state update
var is_initialized: bool

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
	
	# Common = 1 hit, Uncommon = 2 hits etc
	HITS_NEEDED = ability.RARITY
	
	ability.queue_free()

func _get_ability() -> Ability:
	if ABILITY_CONTAINED.is_empty():
		return null
	
	var ability_scene_path: String = Sanitizer.sanitize_scene_path(ABILITY_CONTAINED)
	var ability_scene: PackedScene = load(ability_scene_path)
	return ability_scene.instantiate()

## Interacting hits the object if it is not broken.
## Otherwise, take the contained ability.[br]
func interact(player: Player):
	if IS_BROKEN:
		_ability_taken_by(player)
	else:
		try_hitting(player.player_peer)
	
	super(player)

## Give the ability contained in [member AbilityContainer.ABILITY_CONTAINED]
## to the [param player][br]
## Makes the container empty.
func _ability_taken_by(player: Player):
	if player.is_local_player:
		var ability: Ability = _get_ability()
		player.try_adding_ability(ability)
	
	set_empty()

func set_empty():
	ABILITY_CONTAINED = ""
	CAN_BE_INTERACTED_WITH = false
	CAN_BE_HIT = false
	emptied.emit()

func set_broken():
	var ability: Ability = _get_ability()
	var item_prompt = "%s %s\n\n%s" % [BROKEN_INTERACTION_PROMPT_MESSAGE, ability.NAME, ability.DESCRIPTION]
	INTERACTION_PROMPT_MESSAGE = item_prompt
	
	ability.queue_free()
	super()

#
# Synchronization
#

func _send_current_state(peer_id: int = 0, state: Dictionary = {}):
	var current_state: Dictionary = {
		"ABILITY_CONTAINED": ABILITY_CONTAINED
	}
	state.merge(current_state)
	super(peer_id, state)

func update_state(state: Dictionary):
	super(state)
	ABILITY_CONTAINED = state.get("ABILITY_CONTAINED", ABILITY_CONTAINED)
	if not is_initialized and ABILITY_CONTAINED.is_empty():
		emptied.emit()
	
	is_initialized = true
