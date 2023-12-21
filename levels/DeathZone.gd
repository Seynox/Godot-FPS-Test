extends Area3D


func _on_body_entered(body: Node3D):
	if not is_multiplayer_authority(): return
	if body is Entity:
		body.reduce_health.rpc(body.MAX_HEALTH / 4)
