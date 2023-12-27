extends AnimationPlayer

@export_category("Animations")
@export var ATTACK_ANIMATION_NAME: StringName
@export var RELOADING_ANIMATION_NAME: StringName = "Reloading"

func _on_attack():
	play(ATTACK_ANIMATION_NAME)


func _on_reload():
	play(RELOADING_ANIMATION_NAME)
