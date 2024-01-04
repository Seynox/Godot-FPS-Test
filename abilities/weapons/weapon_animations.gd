extends AnimationPlayer

@export_category("Animations")
@export var ATTACK_ANIMATION_NAME: StringName
@export var RELOADING_ANIMATION_NAME: StringName = "Reloading"

func _on_uses_updated(previous_uses: int, uses_remaining: int):
	var difference: int = previous_uses - uses_remaining
	if difference > 0: # If the number of uses decreased
		play("RESET")
		queue(ATTACK_ANIMATION_NAME)

func _on_reload():
	play("RESET")
	queue(RELOADING_ANIMATION_NAME)
