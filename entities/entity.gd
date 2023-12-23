class_name Entity extends CharacterBody3D

signal health_update(old_health: float, new_health: float, max_health: float)
signal death
signal out_of_map

@export_category("Entity")
@export var MAX_HEALTH: float = 4.0
@export var SPEED: float = 10 # In meters per second
@export var ATTACK_DISTANCE: float = 1.5
@export var ATTACK_DAMAGE: float = 1.0
@export var CAN_BE_HIT: bool = true
@export var GRAVITY_MULTIPLIER: float = 1.0

var GRAVITY: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_velocity: Vector3

var health: float
var is_dead: bool

func _ready():
	health = MAX_HEALTH

# Movements

func _physics_process(_delta: float):
	if global_position.y <= -10:
		out_of_map.emit()
	
	move_and_slide()

func _calculate_gravity_velocity(delta: float) -> Vector3:
	var gravity_force = GRAVITY * GRAVITY_MULTIPLIER
	if is_on_floor() and gravity_force >= 0:
		return Vector3.ZERO
	
	return gravity_velocity.move_toward(Vector3(0, velocity.y - gravity_force, 0), gravity_force * delta)

# Health

@rpc("call_local", "reliable")
func set_health(new_health: float) -> void:
	var previous_health = health
	health = new_health
	health_update.emit(previous_health, new_health, MAX_HEALTH)
	
	is_dead = new_health <= 0
	if is_dead:
		_die()

func _die():
	death.emit()

@rpc("call_local", "reliable")
func reduce_health(damages: float) -> void:
	var new_health = health - damages
	set_health(new_health)

@rpc("any_peer", "call_local", "reliable")
func try_hitting():
	if not is_multiplayer_authority(): return
	
	var player_peer_id: int = multiplayer.get_remote_sender_id()
	var player_node_name: String = str(player_peer_id)
	var player_hitting: Player = $/root/Game/Players.get_node_or_null(player_node_name)
	
	if player_hitting != null:
		try_getting_hit_by(player_hitting)

func try_getting_hit_by(source: Entity, additional_damages: float = 0, multiplicator: float = 1):
	if not is_multiplayer_authority() or not _can_be_hit(source): return
	var damages: float = source.ATTACK_DAMAGE + additional_damages
	reduce_health.rpc(damages * multiplicator)

## Called on authority to determine if the entity can be hit by [param _hitting_entity].
func _can_be_hit(_hitting_entity: Entity) -> bool:
	return CAN_BE_HIT
