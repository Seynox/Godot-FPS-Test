extends Area3D

func _on_body_entered(body: Node3D):
	if is_multiplayer_authority() and body is Entity:
		var damages: float = body.MAX_HEALTH / 2
		body.reduce_health.rpc(damages)
