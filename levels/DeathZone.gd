extends Area3D


func _on_body_entered(body: Node3D):
	if not is_multiplayer_authority(): return
	if body is Player:
		body.set_health(0)
