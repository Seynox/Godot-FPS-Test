extends MeshInstance3D

func _on_ability_container_damaged(total_hits: int, max_hits: int):
	var material: BaseMaterial3D = get_active_material(0)
	
	var remaining_hits: int = max_hits - total_hits
	var color: float = 255.0 if remaining_hits <= 0 else 255.0 / remaining_hits
	material.albedo_color = Color(color, color, color)

func _on_ability_container_broken():
	var material: BaseMaterial3D = get_active_material(0)
	material.albedo_color = Color.RED

func _on_ability_container_emptied():
	var material: BaseMaterial3D = get_active_material(0)
	material.albedo_color = Color.BLUE
