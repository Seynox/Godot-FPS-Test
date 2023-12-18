class_name HitscanWeapon extends CooldownWeapon
# TODO Add ammos

func _attack(player: Player, _delta: float):
	attack_started.emit()
	var aimed_object: Node3D = player.get_aimed_object(self.ATTACK_RANGE)
	if aimed_object != null:
		hit_target(aimed_object)
	attack_ended.emit()
