class_name Enemy extends Entity

signal target_found(entity: Entity)
signal target_lost(entity: Entity)

@export_category("Enemy")
@export var TARGET_GROUP: String
@export var TARGET_FINDING_INTERVAL: float = 1 # In seconds
@export var ENABLE_TARGET_FINDING: bool = true
@export var TARGET_DETECTION_RANGE: float = 15 # In meters
@export var TARGET: Entity

func _ready():
	if ENABLE_TARGET_FINDING:
		_start_target_finding_loop()

func _die():
	super._die()
	queue_free()

func _start_target_finding_loop():
	var update_target_and_repeat = func():
		update_current_target()
		_start_target_finding_loop()
	
	get_tree().create_timer(TARGET_FINDING_INTERVAL).timeout.connect(update_target_and_repeat)

func _process(_delta: float):
	if TARGET == null:
		return
	if TARGET.is_dead():
		TARGET = null
		return
	
	_hit_target_in_range()

func _physics_process(delta):
	if TARGET != null:
		var direction = global_position.direction_to(TARGET.global_position)
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity = Vector3(0, velocity.y, 0)
	
	super._physics_process(delta)

func _hit_target_in_range():
	var distance = global_position.distance_to(TARGET.global_position)
	if distance <= self.ATTACK_DISTANCE:
		TARGET.take_hit_from(self)

func get_closest_target() -> Entity:
	var all_targets = get_tree().get_nodes_in_group(TARGET_GROUP)
	var closest_target = null
	var smallest_distance = TARGET_DETECTION_RANGE
	
	for target in all_targets:
		var distance = global_position.distance_to(target.global_position)
		if distance < smallest_distance:
			closest_target = target
			smallest_distance = distance
	
	return closest_target

func update_current_target():
	var new_target = get_closest_target()
	if TARGET != null && new_target == null:
		target_lost.emit(TARGET)
	else:
		target_found.emit(new_target)
	TARGET = new_target
