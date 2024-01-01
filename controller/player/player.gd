class_name Player extends Entity

signal ability_changed(player: Player, ability_type: String, ability: Ability)
signal interactible_hovering(interactible: Interactible)
signal interactible_hover_ended

@export_subgroup("Abilities")
@export var DEFAULT_DASH: PackedScene
@export var DEFAULT_JUMP: PackedScene
@export var DEFAULT_WEAPON: PackedScene

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera
@onready var camera_ui: Control = $Head/Camera/UI

@onready var interaction_ray: RayCast3D = $Head/Camera/InteractionRay
@onready var input: Node = $PlayerInput
@onready var abilities: Node = $Abilities

# A dictionary would be cleaner but a bit slower
var dash: Dash
var jump: Jump
var weapon: Weapon

var movement_velocity: Vector3
var interactible_hovered: Interactible

var player_peer: int
var is_local_player: bool

var local_spectator_node: Spectator

func _enter_tree():
	player_peer = str(name).to_int()
	$PlayerInput.set_multiplayer_authority(player_peer)
	$Head/Camera.set_multiplayer_authority(player_peer)
	$ClientSynchronizer.set_multiplayer_authority(player_peer)

func _ready():
	is_local_player = multiplayer.get_unique_id() == player_peer
	show_camera(is_local_player)
	_init_default_abilities()

func _exit_tree():
	# Free all abilities
	for ability: Ability in abilities.get_children():
		abilities.remove_child(ability)
		ability.queue_free()

#
# Player processing
#

func _process(delta: float):
	# Apply rotation
	self.basis = Basis() # Reset player rotation
	rotate_object_local(Vector3(0, 1, 0), input.camera_rotation.y) # Rotate player
	
	head.basis = Basis() # Reset head rotation
	head.rotate_object_local(Vector3(1, 0, 0), input.camera_rotation.x) # Rotate head
	
	_process_abilities_inputs(delta)

func _process_abilities_inputs(delta: float):
	var inputs: Dictionary = input.current_inputs
	for ability: Ability in abilities.get_children():
		ability.process_inputs(self, delta, inputs)
	
	input.reset_inputs()

func _physics_process(delta: float):
	# Get aimed interactible
	_update_aimed_interactible()
	
	# Calculate forces
	velocity = _calculate_movement_velocity(delta)
	gravity_velocity = _calculate_gravity_velocity(delta)
	velocity += gravity_velocity
	
	_process_abilities_physics(delta)
	super(delta)

func _calculate_movement_velocity(_delta: float) -> Vector3:
	var movement_direction: Vector3 = Vector3(input.movement_direction.x, 0, input.movement_direction.y)
	var movement_vector_raw: Vector3 = camera.global_transform.basis * movement_direction
	movement_vector_raw.y = 0
	
	return movement_vector_raw.normalized() * SPEED * input.movement_direction.length()

func _process_abilities_physics(delta: float):
	for ability: Ability in abilities.get_children():
		ability.process_ability_physics(self, delta)

#
# ACTIONS
#

func get_aimed_object(range_in_meters: float) -> Node3D:
	var mouse_position = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_max = ray_origin + camera.project_ray_normal(mouse_position) * range_in_meters
	
	var ray = PhysicsRayQueryParameters3D.create(ray_origin, ray_max)
	ray.collide_with_areas = true
	ray.exclude = [self]
	
	var space = camera.get_world_3d().direct_space_state
	var result = space.intersect_ray(ray)
	return result.get("collider")

func _update_aimed_interactible():
	if not is_local_player: return
	var currently_hovered: Node3D = interaction_ray.get_collider()
	
	if not currently_hovered is Interactible:
		currently_hovered = null
	
	# Interact with interactible if the player tries to
	var wants_to_interact: bool = input.current_inputs["interact"]
	if wants_to_interact and currently_hovered != null:
		var authority_id: int = currently_hovered.get_multiplayer_authority()
		currently_hovered.try_interact.rpc_id(authority_id)
	
	# Send signals when hovering or stopping hovering
	if currently_hovered != null:
		interactible_hovering.emit(currently_hovered)
	elif interactible_hovered != null:
		interactible_hover_ended.emit()
	
	# Update last hovered
	interactible_hovered = currently_hovered

#
# Abilities
#

func _init_default_abilities():
	if DEFAULT_DASH != null:
		dash = _put_ability(dash, DEFAULT_DASH.instantiate())
	if DEFAULT_JUMP != null:
		jump = _put_ability(jump, DEFAULT_JUMP.instantiate())
	if DEFAULT_WEAPON != null:
		weapon = _put_ability(weapon, DEFAULT_WEAPON.instantiate())

func set_ability(ability: Ability):
	var ability_type: String = ability.get_ability_type()
	match ability_type:
		Dash.TYPE:
			dash = _put_ability(dash, ability)
		Jump.TYPE:
			jump = _put_ability(jump, ability)
		Weapon.TYPE:
			weapon = _put_ability(weapon, ability)

func _put_ability(current: Ability, new: Ability) -> Ability:
	# Remove the current if new is null
	if new == null:
		if current != null:
			ability_changed.emit(self, current.get_ability_type(), null)
			current.queue_free()
		return null
	
	# Add the new ability or replace the current one
	if current == null:
		abilities.add_child(new)
	else:
		var old: Node = current
		current.replace_by(new)
		old.queue_free()
		
	ability_changed.emit(self, new.get_ability_type(), new)
	return new

#
# Spectating
#

func show_camera(value: bool):
	camera.current = value
	camera_ui.visible = value

## Client-only. Allow the client to spectate other players.[br]
## Ignored if the player is already a spectator
func _make_spectator():
	if not is_local_player or local_spectator_node != null: return
	show_camera(false)
	local_spectator_node = Spectator.new()
	add_child(local_spectator_node)

#
# Death
#

func _set_enabled(enable: bool):
	set_visible(enable)
	set_process(enable)
	set_physics_process(enable)
	input.set_enabled(enable and is_local_player)

func _die():
	_set_enabled(false)
	_make_spectator()
	super()

@rpc("call_local", "reliable")
func resurrect():
	set_health(MAX_HEALTH)
	_set_enabled(true)
	
	# Remove spectator node
	if local_spectator_node != null:
		local_spectator_node.queue_free()
		show_camera(true)
