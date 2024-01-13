class_name HitscanWeapon extends RangedWeapon

## The list of raycast to process on physics ticks
var ray_query_queue: Array[PhysicsRayQueryParameters3D]

## Shoot a raycast from the shooter position towards the direction they are facing
func _spawn_bullet(starting_position: Vector3, direction: Basis):
	var forward_range: Vector3 = -direction.z * ATTACK_RANGE
	var end_position: Vector3 = starting_position + forward_range
	
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(starting_position, end_position)
	ray_query_queue.append(ray)
	
	super(starting_position, direction)

## Process all ray queries inside [member HitscanWeapon.ray_query_queue] and removes it after being processed.
func _physics_process(_delta):
	for index: int in ray_query_queue.size():
		var ray: PhysicsRayQueryParameters3D = ray_query_queue[index]
		_process_hit_ray(ray)
		ray_query_queue.remove_at(index)

## Process the ray collision to try hitting the collided object.[br]
## Can only be called on physics ticks
func _process_hit_ray(ray: PhysicsRayQueryParameters3D):
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var collided_object: Node3D = space.intersect_ray(ray).get("collider")
	
	if collided_object != null:
		hit_target(collided_object)
