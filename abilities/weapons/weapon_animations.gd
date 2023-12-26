extends AnimationPlayer

@export_category("Animations")
@export var ON_ATTACK_STARTED: StringName

func _on_attack_started():
	play(ON_ATTACK_STARTED)
