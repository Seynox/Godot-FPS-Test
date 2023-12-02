extends Node3D

@export var spawn_interval: float = 1.0 # Seconds

@onready var ground = $Ground/GroundCollision

var enemy_speed = 5 # Meters per second

func _get_random_position() -> Vector3:
	var ground_size: Vector3 = ground.get_shape().size
	
	var half_size_x = ground_size.x / 2
	var half_size_z = ground_size.z / 2
	
	var random = RandomNumberGenerator.new()
	random.randomize()
	var x = random.randi_range(half_size_x * -1, half_size_x)
	var z = random.randi_range(half_size_z * -1, half_size_z)
	
	return Vector3(x, ground_size.y, z)

func start_enemy_spawns():
	var enemy_position: Vector3 = _get_random_position()
	var enemy = preload("res://entities/enemy/enemy.tscn").instantiate()
	add_child(enemy)
	
	enemy.global_position = enemy_position
	enemy.SPEED = enemy_speed
	
	get_tree().create_timer(spawn_interval).timeout.connect(start_enemy_spawns)

# Called when the node enters the scene tree for the first time.
func _ready():
	start_enemy_spawns()
