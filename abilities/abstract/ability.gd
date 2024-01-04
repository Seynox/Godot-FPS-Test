class_name Ability extends Node3D

## Emitted when the ability failed to execute
signal failed
## Emitted when the amount of uses is changed. (Decreased or filled)[br]
## [param uses_remaining] is the new amount of uses left.[br]
## [param previous_uses] is the previous amount of uses left.
signal uses_updated(previous_uses: int, uses_remaining: int)
## Emitted when the ability got canceled. (By another ability for exemple)
signal canceled

@export_category("Ability")
## The ability unique name
@export var IDENTIFIER_NAME: String

## The ability name
@export var NAME: String

## The description of the ability
@export var DESCRIPTION: String

@export_subgroup("Uses")
## The amount of times the ability can be used before having to reload.[br]
## The way of reloading depends on the ability implementation.[br]
## Negative values will give unlimited uses.
@export var MAX_USES: int = 1

## The amount of uses given per reload.[br]
@export var USES_GIVEN_PER_RELOAD: int = 1

## The amount of uses removed per execution.[br]
@export var USES_CONSUMED_PER_EXECUTION: int = 1

@export_subgroup("Generation")
## The rarity of the ability. Set [enum Rarity.Level.NONE] to disabled generation
@export var RARITY: Rarity.Level

## The minimum level in which the ability can be generated
@export var GENERATE_SINCE_LEVEL: int

## The number of uses the ability has left. Ability will not be executable if equal to 0.[br]
## Should be refilled by [method Ability.reload].[br]
## Default value is [member Ability.MAX_USES]
@onready var uses_left: int = MAX_USES

## The unique ability type. See [method Ability._get_unique_type]
func get_type() -> String:
	return _get_unique_type()

## Return the unique ability type. A player can only have 1 ability of a type.[br]
## Return an empty string if the ability has no unique type.
func _get_unique_type() -> String:
	return ""

#
# Inputs
#

## Call to handle the player inputs related to the ability.[br]
## [param player] is the ability owner.[br]
## [param delta] is the frames delta time.[br]
## [param inputs] is a dictionary containing the actions name as key, and a boolean as a value, showing if the input is pressed.
func process_inputs(player: Player, delta: float, inputs: Dictionary):
	_handle_player_inputs(player, delta, inputs)

## Called on every frame. Used to make the ability react to a given input.
func _handle_player_inputs(_player: Player, _delta: float, _inputs: Dictionary):
	pass

#
# Physics
#

## Call only from ability owner [method Node._physics_process].[br]
## Used to apply ability physics modifications to the player.
func process_ability_physics(player: Player, delta: float):
	_on_player_physics(player, delta)

## Called on ability owner physics ticks.[br]
## Used to apply physics modifications to the player.
func _on_player_physics(_player: Player, _delta: float):
	pass

#
# Execution
#

## Called to cancel the execution of the current ability.
func cancel():
	_cancel_ability()
	canceled.emit()

## Called when the execution of the current ability needs to be canceled.
func _cancel_ability():
	pass

## Called when the owner successfully execute the ability.
func _execute(_player: Player, _delta: float):
	pass

## Try executing the ability.
func try_executing(player: Player, delta: float):
	if _can_execute(player):
		consume_use()
		_execute(player, delta)
	else:
		failed.emit()

## Used to determine if the owner is allowed to execute the ability.[br]
## Called when trying to execute the ability.
func _can_execute(_player: Player) -> bool:
	return has_uses()

#
# Uses
#

## If the ability has uses left.
func has_uses() -> bool:
	return uses_left != 0

## If the amount of uses left is at maximum
func has_maximum_uses() -> bool:
	return MAX_USES < 0 or uses_left >= MAX_USES

## Called to recharge uses.
## Will give [member Ability.USES_PER_RELOAD] uses.[br]
## Cannot go higher than [member Ability.MAX_USES][br]
## Ignored if the uses left are already at maximum amount
func reload():
	if has_maximum_uses(): return
	var new_uses: int = mini(uses_left + USES_GIVEN_PER_RELOAD, MAX_USES)
	_set_uses(new_uses)

## Decrease uses by [member Ability.USES_CONSUMED_PER_EXECUTION].
## Cannot go below 0. Ignored if [member Ability.uses_left] is negative.
func consume_use():
	if uses_left < 0: return
	var new_uses: int = maxi(uses_left - USES_CONSUMED_PER_EXECUTION, 0) # Set minimum uses to 0
	_set_uses(new_uses)

func _set_uses(uses_amount: int):
	uses_updated.emit(uses_left, uses_amount)
	uses_left = uses_amount
