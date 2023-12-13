class_name Player extends Entity

signal ability_changed(player: Player, ability_type: String, ability: Ability)
signal interactible_hovering(interactible: Interactible)
signal interactible_hover_ended

@export_category("Player")
@export_range(10, 400, 1) var acceleration: float = 100 # m/s^2

@export_subgroup("Abilities")
@export var DEFAULT_DASH: PackedScene
@export var DEFAULT_JUMP: PackedScene
@export var DEFAULT_WEAPON: PackedScene

@onready var camera: Camera3D = $Camera
@onready var interaction_ray: RayCast3D = $Camera/InteractionRay
@onready var input := $PlayerInput
@onready var abilities := $Abilities

# A dictionary would be cleaner but a bit slower
var dash: Dash
var jump: Jump
var weapon: Weapon

var movement_velocity: Vector3
var interactible_hovered: Interactible

func _enter_tree():
	var player_peer = str(name).to_int()
	set_multiplayer_authority(player_peer)

func _ready() -> void:
	var is_local_player: bool = is_multiplayer_authority()
	camera.current = is_local_player
	set_process(is_local_player)
	set_physics_process(is_local_player)
	
	if !is_local_player:
		return
	
	if DEFAULT_DASH != null:
		dash = _put_ability(dash, DEFAULT_DASH.instantiate())
	if DEFAULT_JUMP != null:
		jump = _put_ability(jump, DEFAULT_JUMP.instantiate())
	if DEFAULT_WEAPON != null:
		weapon = _put_ability(weapon, DEFAULT_WEAPON.instantiate())

func _process(delta: float):
	_process_abilities_inputs(delta)

func _process_abilities_inputs(delta: float):
	if input.consume_dashing() and dash != null:
		dash.try_dash(self)
	
	if input.consume_jumping() and jump != null:
		jump.try_jump(self)
	
	if input.consume_attacking() and weapon != null:
		weapon.try_attack(self, delta)

func _physics_process(delta: float):
	# Apply camera rotation
	camera.rotation.x = input.camera_rotation.x
	camera.rotation.y = input.camera_rotation.y
	
	# Get aimed interactible
	_update_aimed_interactible()
	
	# Calculate forces
	velocity = _calculate_movement_velocity(delta)
	gravity_velocity = _calculate_gravity_velocity(delta)
	velocity += gravity_velocity
		
	_process_abilities_physics(delta)
	super._physics_process(delta)

func _calculate_movement_velocity(delta: float) -> Vector3:
	var movement_direction: Vector3 = Vector3(input.movement_direction.x, 0, input.movement_direction.y)
	var movement_vector_raw: Vector3 = camera.global_transform.basis * movement_direction
	movement_vector_raw.y = 0
	
	var movement_vector: Vector3 = movement_vector_raw.normalized() * SPEED * input.movement_direction.length()
	movement_velocity = movement_velocity.move_toward(movement_vector, acceleration * delta)
	return movement_velocity

func _process_abilities_physics(delta: float):
	if dash != null:
		velocity = dash.get_velocity(self, delta)
	if jump != null:
		velocity = jump.get_velocity(self, delta)
	if weapon != null:
		velocity = weapon.get_velocity(self, delta)

#
# ACTIONS
#

func get_aimed_object(range_in_meters: float) -> Node3D:
	var mouse_position = get_viewport().get_mouse_position() # TODO Check if it works in multiplayer
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_max = ray_origin + camera.project_ray_normal(mouse_position) * range_in_meters
	
	var ray = PhysicsRayQueryParameters3D.create(ray_origin, ray_max)
	ray.collide_with_areas = true
	ray.exclude = [self]
	
	var space = camera.get_world_3d().direct_space_state
	var result = space.intersect_ray(ray)
	return result.get("collider")

func _update_aimed_interactible():
	var currently_hovered: Node3D = interaction_ray.get_collider()
	
	if not currently_hovered is Interactible:
		currently_hovered = null
	
	# Interact with interactible if the player tries to
	if currently_hovered != null and input.consume_interacting():
		currently_hovered.try_interact(self)
	
	# Send signals when hovering or stopping hovering
	if currently_hovered != null:
		interactible_hovering.emit(currently_hovered)
	elif interactible_hovered != null:
		interactible_hover_ended.emit()
	
	# Update last hovered
	interactible_hovered = currently_hovered

#
# ABILITIES
#

func set_ability(ability: Ability):
	# TODO Can be a match statement?
	if ability is Dash:
		dash = _put_ability(dash, ability)
	elif ability is Jump:
		jump = _put_ability(jump, ability)
	elif ability is Weapon:
		weapon = _put_ability(weapon, ability)

func _put_ability(current: Ability, new: Ability) -> Ability:
	# Remove the current if new is null
	if new == null:
		if current != null:
			ability_changed.emit(self, current.get_ability_type(), null)
			current.queue_free()
		return null
	
	# Copy our authority to child
	var player_peer: int = get_multiplayer_authority()
	new.set_multiplayer_authority(player_peer)
	
	# Add the new ability or replace the current one
	if current == null:
		abilities.add_child(new)
	else:
		var old: Node = current
		current.replace_by(new)
		old.queue_free()
		
	ability_changed.emit(self, new.get_ability_type(), new)
	return new
