extends RangedWeapon

var hitscan_rays: Array[HitscanRay]

class HitscanRay:
	var starting_position: Vector3
	var end_position: Vector3
	
	func _init(start: Vector3, end: Vector3):
		starting_position = start
		end_position = end

func _spawn_bullet(starting_position: Vector3, direction: Basis):
	var forward_range: Vector3 = -direction.z * ATTACK_RANGE
	var end_position: Vector3 = starting_position + forward_range
	
	var ray: HitscanRay = HitscanRay.new(starting_position, end_position)
	hitscan_rays.append(ray)
	
	super(starting_position, direction)

func _physics_process(_delta):
	for index: int in hitscan_rays.size():
		var ray: HitscanRay = hitscan_rays[index]
		_process_hit_ray(ray)
		hitscan_rays.remove_at(index)

func _process_hit_ray(ray: HitscanRay):
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray.starting_position, ray.end_position)
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var collided_object: Node3D = space.intersect_ray(query).get("collider")
	
	if collided_object != null:
		hit_target(collided_object)
