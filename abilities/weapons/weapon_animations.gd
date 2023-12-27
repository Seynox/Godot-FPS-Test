extends AnimationPlayer

@export_category("Animations")
@export var ATTACK_ANIMATION_NAME: StringName
@export var RELOADING_ANIMATION_NAME: StringName = "Reloading"

func _on_attack():
	stop()
	play(ATTACK_ANIMATION_NAME)


func _on_reload():
	stop()
	play(RELOADING_ANIMATION_NAME)
