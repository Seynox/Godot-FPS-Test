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
## Should be refilled by [method Ability.reload].
@onready var uses_left: int = MAX_USES

## The ability type.
## Should only be overriden by a direct child of the [Ability] class.
func get_ability_type() -> String: # TODO Rework
	return "none"

#
# Physics
#

## Call only from ability owner _physics_process
func process_ability_physics(player: Player, delta: float):
	_on_player_physics(player, delta)

## Called on ability owner physics ticks
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
