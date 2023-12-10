class_name Interactible extends Node3D
## Make a 3D object interactible by entities

signal interacted(interacting_entity: Entity) ## Emitted when the interaction was successfull
signal interaction_failed ## Emitted when the interaction failed

## If the entity can be interacted with or not.
## Setting it to false will fail [method Interactible.try_interact]
@export var CAN_BE_INTERACTED_WITH: bool = true

## The message that should be displayed when the entity is prompted
## to interact with the object.
@export var INTERACTION_PROMPT_MESSAGE: String

## Called when an entity tries to interact with the object.[br]
## Will call [method Interactible._interact] if successfull.[br]
## Will emit [signal Interactible.interaction_failed] if failed
func try_interact(interacting_entity: Entity):
	if CAN_BE_INTERACTED_WITH:
		_interact(interacting_entity)
	else:
		interaction_failed.emit()

## Called when an entity successfully interact with the object.
## Don't call directly, use [method Interactible.try_interact] instead.[br]
func _interact(interacting_entity: Entity):
	interacted.emit(interacting_entity)
