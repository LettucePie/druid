extends CharacterBody3D

class_name Player

## Signals
signal request_form_wheel()
signal report_current_form(form)
signal report_interactive_popup(message)
signal request_cam_movement(direction)


## Tools / Assistant Nodes
@onready var anim : Player_Animator = $anim_handler
@onready var edge_ray : RayCast3D = $swivel_ring/edge_ray


#### Form Assets
# Human
@onready var human_node : Node3D = $human_node 
@onready var human_shape : CollisionShape3D = $human_shape
@onready var human_mesh : MeshInstance3D = \
$human_node/human_model/human_armature/Skeleton3D/human_mesh
# Wolf
@onready var wolf_node : Node3D = $wolf_node
@onready var wolf_shape : CollisionShape3D = $wolf_shape
@onready var wolf_mesh : MeshInstance3D = \
$wolf_node/wolf_model/Armature/Skeleton3D/wolfmesh

## Iterative Lists
@onready var colshapes : Array = [
	$human_shape,
	$wolf_shape
	]
@onready var nodemeshes : Array = [
	$human_node,
	$wolf_node
	]



## Camera Variables
@onready var player_cam : Camera3D = $cam_dial/Player_Cam
@onready var aim_cam : Camera3D = $cam_dial/aim_arm/Aim_Cam
@onready var cam_dial : Node3D = $cam_dial
@onready var aim_arm : Node3D = $cam_dial/aim_arm
var cam_locked : bool = false
var cam_min_y : float = -PI
var cam_max_y : float = PI
var cam_min_x : float = PI * -0.35
var cam_max_x : float = PI * 0.35
@export var cam_distance_curve : Curve
var cam_distance_max : float = 10.0
var aim_speed = 10.0
var mouse_relative : Vector2 = Vector2.ZERO


## Movement Variables
var form_speed : float = 5.0
var form_accel : float = 0.1
var form_jump : float = 4.5
var form_weight : float = 1.0
var form_air_control : float = 0.15
var form_mag_angle : float = 0.15
var form_turn : float = 0.5
const MAG_PULL = 10.5
var move_input_vec : Vector3 = Vector3.ZERO
var move_direction : Vector3 = Vector3.ZERO
var accelerated_dir : Vector3 = Vector3.ZERO
var acceleration : float = 0.0
var deceleration : float = 1.0
var velocity_buffer : PackedVector3Array = [
	Vector3.FORWARD,
	Vector3.FORWARD,
	Vector3.FORWARD
]
@export var turn_responsiveness_curve : Curve
@export var turn_decel_curve : Curve
var floor_angle : float
var previous_normal : Vector3 = Vector3.UP
var previous_position : Vector3 = Vector3.ZERO
var current_cam : Camera3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var climb_angle : float = 0.3
@export var jump_velocity : Vector3 = Vector3.ZERO
var jump_velocity_mag : float = 0.0


## Play Variables
enum Form {HUMAN, SPIDER, RAT, WOLF}
var available_forms : Array = [Form.HUMAN, Form.SPIDER, Form.WOLF]
var current_form : Form = Form.HUMAN
var current_mesh : MeshInstance3D = human_mesh
var current_node : Node3D = human_node
var nearest_interactable : Interactable = null
var nearby_interactables : Array = []
var unlocked_skills
var current_skill
var enemies_close : Array = []
var enemies_far : Array = []
var enemies_struck : Array = []


## Action Variables
var magnet_cooldown : int = 0
var dodge_cooldown : int = 0
var dodge_active : int = 0
var air_dodge : int = 0
var dodge_direction : Vector3
const DODGE_SPEED = 14.0
@export var attack_chain : int = 0
@export var attack_interrupt : bool = false
var attack_active : bool = false
var attack_active_ebrake : int = 0
var aiming : bool = false

## Player Settings
var invert_cam : bool = false
var aim_sensitivity : float = 0.65 ## multiply the aim speed

#var action_frame_vars : Array = [magnet_cooldown, dodge_cooldown, dodge_active]
## This didn't work. It just made an array of 0, 0, 0.
## I think there is a way to make arrays of references to variables... \
## I just don't know how yet.


func _ready():
	current_node = human_node
	current_mesh = human_mesh
	current_cam = get_viewport().get_camera_3d()
	motion_mode = 0
	set_form_to(Form.HUMAN)
#	human_anim.play("walk")
#	floor_max_angle = PI


###
### Druid Form Block
###
func set_form_to(form : Form):
	if available_forms.has(form):
		current_form = form
	set_form_variables(form)
	set_form_components(form)
	emit_signal("report_current_form", form_as_string(form))


func set_form_variables(form : Form):
	if form == Form.HUMAN:
		current_node = human_node
		current_mesh = human_mesh
		motion_mode = 0
		climb_angle = 0.45
		floor_max_angle = climb_angle
		form_speed = 5.0
		form_accel = 0.1
		form_jump = 4.5
		form_weight = 1.2
		form_air_control = 2.5
		form_mag_angle = 0.8
		form_turn = 0.5
	if form == Form.SPIDER:
		current_node = human_node
		current_mesh = human_mesh
		motion_mode = 0
		climb_angle = PI + (PI / 2)
		floor_max_angle = climb_angle
		form_speed = 4.0
		form_accel = 0.15
		form_jump = 4.0
		form_weight = 0.8
		form_air_control = 4.9
		form_mag_angle = 0.15
		form_turn = 0.8
	if form == Form.RAT:
		pass
	if form == Form.WOLF:
		current_node = wolf_node
		current_mesh = wolf_mesh
		motion_mode = 0
		climb_angle = 0.5
		floor_max_angle = climb_angle
		form_speed = 7.0
		form_accel = 0.08
		form_jump = 5.0
		form_weight = 1.2
		form_air_control = 1.0
		form_mag_angle = 0.4
		form_turn = 0.15


func set_form_components(form : Form):
	for cs in colshapes:
		cs.disabled = true
	for nm in nodemeshes:
		nm.visible = false
	if form == Form.HUMAN:
		human_shape.disabled = false
		human_node.visible = true
	if form == Form.SPIDER:
		human_shape.disabled = false
		human_node.visible = true
	if form == Form.RAT:
		human_shape.disabled = false
		human_node.visible = true
	if form == Form.WOLF:
		wolf_shape.disabled = false
		wolf_node.visible = true
	anim.set_form(form)


func form_as_string(form : Form) -> String:
	var result : String = "Form"
	if form == Form.HUMAN:
		result = "Human"
	if form == Form.SPIDER:
		result = "Spider"
	if form == Form.RAT:
		result = "Rat"
	if form == Form.WOLF:
		result = "Wolf"
	return result


###
### Camera Input Block
###
func cam_process(delta):
	current_cam = get_viewport().get_camera_3d()
	var input : Vector2 = Vector2(
		Input.get_axis("cam_left", "cam_right"),
		Input.get_axis("cam_down", "cam_up")
	).limit_length(1.0)
	if mouse_relative != Vector2.ZERO and input == Vector2.ZERO:
		input = mouse_relative
		mouse_relative = Vector2.ZERO
	if invert_cam:
		input.y *= -1.0
	input.x *= -1.0
	
	if !cam_locked and !aiming:
		cam_dial.rotate_y(input.x * delta)
		cam_dial.rotate(
			cam_dial.transform.basis * Vector3.RIGHT, 
			input.y * delta)
		var x_percent = 1.0 - inverse_lerp(
			cam_min_x, 
			cam_max_x, 
			cam_dial.rotation.x)
		current_cam.position.z = \
			cam_distance_max * cam_distance_curve.sample(x_percent)
		current_cam.position.y = current_cam.position.z * 0.12
		clamp_cam_dolly_rotation(cam_dial)
	elif aiming:
		cam_dial.rotate_y(input.x * (aim_speed * aim_sensitivity) * delta)
		#aim_arm.rotate_y(input.x * delta)
		#aim_arm.rotate(
			#aim_arm.transform.basis * Vector3.UP,
			#input.x * delta
		#)
		aim_arm.rotate_x(input.y * (aim_speed * aim_sensitivity) * delta)
		clamp_cam_dolly_rotation(aim_arm)


func clamp_cam_dolly_rotation(dolly):
	dolly.rotation.y = clamp(
		dolly.rotation.y, 
		cam_min_y, 
		cam_max_y)
	dolly.rotation.x = clamp(
		dolly.rotation.x,
		cam_min_x,
		cam_max_x)

###
### Movement Input Block
###


## Turns the Swivel Ring to the input direction. The Swivel Ring is used for \
## dictating the direction the player will travel.
func turn_swivel_ring(target : Vector3) -> float:
	var speed_percent : float = acceleration
	speed_percent = turn_responsiveness_curve.sample(speed_percent)
	speed_percent = clampf(speed_percent, form_turn, 1.0)
	var ring_basis : Basis = $swivel_ring.transform.basis
	var target_basis : Basis = ring_basis.looking_at(target, get_up_direction())
	var result_basis : Basis = ring_basis.slerp(target_basis, speed_percent)
	$swivel_ring.transform.basis = result_basis
	
	## Find the difference to calculate the level of deceleration to return
	var angle_target = (ring_basis * Vector3.FORWARD).signed_angle_to(
		target_basis * Vector3.FORWARD, get_up_direction()
	)
	var angle_result = (ring_basis * Vector3.FORWARD).signed_angle_to(
		result_basis * Vector3.FORWARD, get_up_direction()
	)
	var lost_angle = abs(angle_target - angle_result)
	return turn_decel_curve.sample(lost_angle / PI)


func lerp_mesh(delta : float):
	var node_t3 : Transform3D = current_node.transform
	var swiv_t3 : Transform3D = $swivel_ring.transform
	current_node.transform = node_t3.interpolate_with(swiv_t3, 0.25)


func apply_jump_velocity(delta : float):
	## Catch the directional movement and clamp down corner speed
	var float_dir = Vector2(
		accelerated_dir.x, 
		accelerated_dir.z).limit_length(form_speed * form_air_control)
	
	## Add on the new airborne directional movement.
	jump_velocity.x = clamp(
		jump_velocity.x + float_dir.x * delta,
		jump_velocity_mag * -1.0,
		jump_velocity_mag
	)
	jump_velocity.z = clamp(
		jump_velocity.z + float_dir.y * delta,
		jump_velocity_mag * -1.0,
		jump_velocity_mag
	)
	
	## Clamp down the cornering speed AGAIN...
	## There's probably a better way to do this.
	var mag_limited = Vector2(
		jump_velocity.x,
		jump_velocity.z).limit_length(jump_velocity_mag)
	jump_velocity.x = mag_limited.x
	jump_velocity.z = mag_limited.y
	
	## Apply (possibly) modified jump velocity
	velocity.x = jump_velocity.x
	velocity.z = jump_velocity.z


func player_landed():
	jump_velocity = Vector3.ZERO
	$norm_vec/mag.visible = false
	air_dodge = 0
	anim.play("land")


func movement_process(delta : float):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = form_jump

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var move_input_vec = Vector3(
		Input.get_axis("move_left", "move_right"), 
		0, 
		Input.get_axis("move_up", "move_down")).limit_length(1.0)
	turn_swivel_ring(move_input_vec)
	var input_dir : Vector3 = move_input_vec
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.z)).normalized()
	if direction:
		velocity.x = direction.x * form_speed
		velocity.z = direction.z * form_speed
	else:
		velocity.x = move_toward(velocity.x, 0, form_speed)
		velocity.z = move_toward(velocity.z, 0, form_speed)

	move_and_slide()


###
### Action Input Block
###
func action_cooldowns():
	if magnet_cooldown > 0:
		magnet_cooldown -= 1
	if dodge_active > 0:
		dodge_active -= 1
	if dodge_cooldown > 0:
		dodge_cooldown -= 1


func set_jump_velocity(vel : Vector3):
	jump_velocity = vel
	jump_velocity_mag = Vector2(
		jump_velocity.x, 
		jump_velocity.z).limit_length(form_speed).length()
	anim.play("jump")


func action_effects(delta):
	if dodge_active > 0:
		print("Dodge Active : ", dodge_active)
		velocity = dodge_direction * DODGE_SPEED
	
	## If attack frames are active, filter through the targets gathered \
	## by the detection hitbox. Then apply the hit for this attack, and \
	## add them to the list of struck enemies to prevent double-proc.
	if attack_active and attack_active_ebrake > 0:
		print("Attack Active and Attack E-Brake > 0")
		var proximity = []
		proximity.append_array(enemies_close)
		if attack_chain >= 3:
			proximity.append_array(enemies_far)
		for target in proximity:
			if !enemies_struck.has(target):
				print("Strike Enemy: ", target)
				if target.has_method("player_hit"):
					target.player_hit()
				enemies_struck.append(target)
		attack_active_ebrake -= 1
		if attack_active_ebrake <= 0:
			attack_frames_active(false)


## Toggled by Animation Function calls.
## NOTE : Please make sure to set to false upon animation interrupts.
func attack_frames_active(active : bool):
	print("AttackFramesActive = ", active)
	attack_active = active
	if active:
		attack_active_ebrake = 30 * attack_chain
	else:
		enemies_struck.clear()


func attack_finished():
	print("Attack Finished on chain: ", attack_chain)
	attack_chain = 0
	attack_interrupt = false


func action_process(delta):
	## Process Action Cooldowns before... I guess?
	## I'm not sure.
	## I suppose having their status updated before actionable input \
	## allows the player to experience the full set of frames of an action?
	## ... Right?
	action_cooldowns()
	
	## This whole next section is just the inputs... might move to its own \
	## function later.
	if Input.is_action_just_pressed("jump"):
		if current_form == Form.HUMAN and is_on_floor():
			velocity.y = form_jump
			set_jump_velocity(velocity)
		if current_form == Form.SPIDER \
		and (is_on_floor() or is_on_ceiling() or is_on_wall()):
			if floor_angle >= form_mag_angle:
				magnet_cooldown = 30
				velocity = get_up_direction() * 5
			else:
				velocity.y = form_jump
			set_jump_velocity(velocity)
		if current_form == Form.WOLF and is_on_floor():
			## Adding Lunge Speed by multiplying velocity.
			velocity *= 1.25
			velocity.y = form_jump
			set_jump_velocity(velocity)
	
	if Input.is_action_just_pressed("interact"):
		print("Interact Key Pressed")
		if nearest_interactable != null:
			nearest_interactable.interact_command()
			emit_signal(
				"report_interactive_popup", 
				nearest_interactable.interactive_message())
	
	if Input.is_action_just_pressed("special"):
		print("Special Key Pressed")
		if current_form == Form.WOLF \
		and (dodge_cooldown <= 0 or dodge_active <= 0) \
		and move_input_vec != Vector3.ZERO \
		and ((jump_velocity != Vector3.ZERO and air_dodge < 1) \
		or jump_velocity == Vector3.ZERO):
			print("Wolf Dodge")
			var angle : float = move_direction.normalized().signed_angle_to(
				velocity_buffer[2].normalized(),
				get_up_direction()
			)
			anim.set_dodge_direction(Vector2.UP.rotated(angle))
			turn_swivel_ring(velocity_buffer[2].normalized())
			dodge_cooldown = 15
			dodge_active = 10
			dodge_direction = move_direction.normalized()
#			dodge_direction.y = clampf(velocity.normalized().y, 0, 1)
			if jump_velocity != Vector3.ZERO:
				set_jump_velocity(dodge_direction * DODGE_SPEED)
				dodge_direction.y = 0.12
				air_dodge += 1
	
	if Input.is_action_just_pressed("form_switcher"):
		if current_form == Form.HUMAN:
			set_form_to(Form.SPIDER)
		elif current_form == Form.SPIDER:
			set_form_to(Form.WOLF)
		elif current_form == Form.WOLF:
			set_form_to(Form.HUMAN)
	
	if Input.get_action_strength("aim") >= 0.3:
		if !aiming:
			print("Aim Pressed")
			aiming = true
			aim_arm.rotation = Vector3.ZERO
			aim_cam.make_current()
	elif aiming:
		aiming = false
		player_cam.make_current()
	
	if Input.get_action_strength("fire") >= 0.3:
		print("Fire Pressed")
		## Future Self.
		## Do we make an entire Skill/Ability Modular Component system...
		## Or just hard code some strings to some effects?
		if current_form == Form.HUMAN:
			pass
		elif current_form == Form.SPIDER:
			pass
		elif current_form == Form.WOLF:
			pass
	
	if Input.is_action_just_pressed("attack"):
		print("Attack Key Pressed")
		if current_form == Form.HUMAN:
			if attack_chain <= 0:
				attack_chain = 1
				attack_interrupt = false
				anim.play("attack_" + str(attack_chain))
			elif attack_interrupt:
				print("***Interrupting Attack!")
				if attack_chain < 3:
					attack_chain += 1
				else:
					attack_chain = 1
				attack_interrupt = false
				anim.play("attack_" + str(attack_chain))
	
	## Process Effects of actions after inputs assign the variables...
	action_effects(delta)


func _physics_process(delta):
	cam_process(delta)
	## movement_process handles Movement, Climbing, and Jumping.
	movement_process(delta)
	## action_process handles Attacks, Interactions, and Abilities.
	action_process(delta)
	## Lastly, apply Move and Slide. This allows Player Movement + Player Action
	## to manipulate position and movement properly... I think...
	move_and_slide()
	lerp_mesh(delta)


func _input(event):
	if event is InputEventMouseMotion:
		mouse_relative = event.relative


###
### World to Player Block
###
func find_nearest_interactable():
	## Filter through and find distance of each
	var smallest_distance : float = 1000
	for interactable in nearby_interactables:
		var distance = position.distance_to(interactable.global_position)
		if distance < smallest_distance:
			nearest_interactable = interactable
			smallest_distance = distance


func proximity_interactable(interactable : Interactable):
	print("Player reached by interactable : ", interactable)
	## Add to Nearby Interactables list. 
	nearby_interactables.append(interactable)
	
	## Check if multiple are in area, if so set nearest.
	if nearby_interactables.size() > 1:
		var before_search = nearest_interactable
		find_nearest_interactable()
		if nearest_interactable != before_search:
			emit_signal(
				"report_interactive_popup", 
				nearest_interactable.interactive_message())
	else:
		nearest_interactable = interactable
		emit_signal(
			"report_interactive_popup", 
			nearest_interactable.interactive_message())


func out_of_range_interactable(interactable : Interactable):
	if nearby_interactables.has(interactable):
		nearby_interactables.erase(interactable)
	if nearby_interactables.size() > 1:
		find_nearest_interactable()
	elif nearby_interactables.size() == 1:
		nearest_interactable = nearby_interactables.front()
		emit_signal(
			"report_interactive_popup", 
			nearest_interactable.interactive_message())
	elif nearby_interactables.size() == 0:
		nearest_interactable = null
		emit_signal("report_interactive_popup", "")


## IF nightmare... there are more elegant solutions to this
func _on_hitbox_detection(body : Node3D, far : bool, register : bool):
	print("HitBox Detection | far = ", far, " | register = ", register)
	var registered = enemies_close.has(body)
	if far:
		registered = enemies_far.has(body)
	if register and !registered:
		if far:
			enemies_far.append(body)
		else:
			enemies_close.append(body)
		if body.has_method("set_color"):
			if far:
				body.set_color(Color.PINK)
			else:
				body.set_color(Color.DEEP_PINK)
	elif !register and registered:
		if far:
			enemies_far.erase(body)
		else:
			enemies_close.erase(body)
		if body.has_method("set_color"):
			body.set_color(Color.WHITE)
