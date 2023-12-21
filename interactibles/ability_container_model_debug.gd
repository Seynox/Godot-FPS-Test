extends MeshInstance3D

func _on_ability_container_damaged(total_hits: int, max_hits: int):
	var material: StandardMaterial3D = StandardMaterial3D.new()
	
	var remaining_hits: int = max_hits - total_hits
	var color: float = 255.0 if remaining_hits <= 0 else 255.0 / remaining_hits
	material.albedo_color = Color(color, color, color)
	set_surface_override_material(0, material)

func _on_ability_container_broken():
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	set_surface_override_material(0, material)

func _on_ability_container_emptied():
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color.BLUE
	set_surface_override_material(0, material)
