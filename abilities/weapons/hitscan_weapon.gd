class_name HitscanWeapon extends CooldownWeapon
# TODO Add ammos

func _attack(player: Player, _delta: float):
	attack_started.emit()
	var aimed_object: Node3D = player.get_aimed_object(self.ATTACK_RANGE)
	if aimed_object != null:
		_apply_damages(player, aimed_object)

func _apply_damages(player: Player, object_attacked: Node3D): # TODO Make a damageable class? Refactor to weapon interface
	if object_attacked is Entity:
		attacked.emit(object_attacked)
		object_attacked.take_hit_from(player, ATTACK_DAMAGE)
	elif object_attacked is BreakableInteractible:
		object_attacked.try_hitting(player)
