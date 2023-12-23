class_name Player extends Entity

signal ability_changed(player: Player, ability_type: String, ability: Ability)
signal interactible_hovering(interactible: Interactible)
signal interactible_hover_ended

@export_subgroup("Abilities")
@export var DEFAULT_DASH: PackedScene
@export var DEFAULT_JUMP: PackedScene
@export var DEFAULT_WEAPON: PackedScene

@onready var camera: Camera3D = $Camera
@onready var camera_ui: Control = $Camera/UI

@onready var interaction_ray: RayCast3D = $Camera/InteractionRay
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
	$Camera.set_multiplayer_authority(player_peer)
	$PlayerSynchronizer.set_multiplayer_authority(player_peer)

func _ready() -> void:
	is_local_player = multiplayer.get_unique_id() == player_peer
	show_camera(is_local_player)

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
	super(delta)

func _calculate_movement_velocity(_delta: float) -> Vector3:
	var movement_direction: Vector3 = Vector3(input.movement_direction.x, 0, input.movement_direction.y)
	var movement_vector_raw: Vector3 = camera.global_transform.basis * movement_direction
	movement_vector_raw.y = 0
	
	return movement_vector_raw.normalized() * SPEED * input.movement_direction.length()

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
	if input.consume_interacting() and currently_hovered != null:
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
# ABILITIES
#

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

func set_default_abilities():
	var default_dash = DEFAULT_DASH.instantiate() if DEFAULT_DASH != null else null
	dash = _put_ability(dash, default_dash)
	
	var default_jump = DEFAULT_JUMP.instantiate() if DEFAULT_JUMP != null else null
	jump = _put_ability(jump, default_jump)
	
	var default_weapon = DEFAULT_WEAPON.instantiate() if DEFAULT_WEAPON != null else null
	weapon = _put_ability(weapon, default_weapon)

#
# Spectating
#

func show_camera(value: bool):
	camera.current = value
	camera_ui.visible = value

## Client-only. Allow the client to spectate other players.[br]
## Ignored if the player is already a spectator
func _make_spectator():
	show_camera(false)
	if not is_local_player or local_spectator_node != null: return
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
