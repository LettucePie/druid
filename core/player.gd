extends CharacterBody3D

class_name Player

## Signals
signal request_form_wheel()
signal report_current_form(form)
signal report_interactive_popup(message)
signal request_cam_movement(direction)


## Testing Variables
@export var test_mat_a : Material
@export var test_mat_b : Material


## Mesh / Animation Variables
@onready var human_mesh : MeshInstance3D = $player_mesh/human_armature/Skeleton3D/human_mesh
@onready var anim_tree : AnimationTree = $player_animtree
#@onready var anim_root : AnimationNodeStateMachine = anim_tree.tree_root
#@onready var anim_node_movement : AnimationNode = anim_root.get_node("movement")
@onready var human_anim : AnimationPlayer = $player_mesh/AnimationPlayer


## Camera Variables
var cam_locked : bool = false
var cam_min_y : float = -PI
var cam_max_y : float = PI
var cam_min_x : float = PI * -0.35
var cam_max_x : float = PI * 0.35
@export var cam_distance_curve : Curve
var cam_distance_max : float = 10.0


## Movement Variables
var form_speed : float = 5.0
var form_jump : float = 4.5
var form_air_control : float = 0.15
var form_mag_angle : float = 0.15
const MAG_PULL = 10.5
var move_input_vec : Vector3 = Vector3.ZERO
var accelerated_dir : Vector3 = Vector3.ZERO
var floor_angle : float
var previous_normal : Vector3 = Vector3.UP
var current_cam : Camera3D
@onready var edge_ray : RayCast3D = $swivel_ring/edge_ray
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var climb_angle : float = 0.3
var jump_velocity : Vector3 = Vector3.ZERO
var jump_velocity_mag : float = 0.0


## Play Variables
enum Form {HUMAN, SPIDER, RAT, WOLF}
var available_forms : Array = [Form.HUMAN, Form.SPIDER, Form.WOLF]
var current_form : Form = Form.HUMAN
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

#var action_frame_vars : Array = [magnet_cooldown, dodge_cooldown, dodge_active]
## This didn't work. It just made an array of 0, 0, 0.
## I think there is a way to make arrays of references to variables... \
## I just don't know how yet.


func _ready():
	current_cam = get_viewport().get_camera_3d()
	motion_mode = 0
#	human_anim.play("walk")
#	floor_max_angle = PI


###
### Druid Form Block
###
func set_form_to(form : Form):
	if available_forms.has(form):
		current_form = form
	set_form_variables(form)
	emit_signal("report_current_form", form_as_string(form))


func set_form_variables(form : Form):
	if form == Form.HUMAN:
		motion_mode = 0
		climb_angle = 0.45
		floor_max_angle = climb_angle
		form_speed = 5.0
		form_jump = 4.5
		form_air_control = 2.5
		form_mag_angle = 0.8
		update_up(Vector3.UP)
	if form == Form.SPIDER:
		motion_mode = 0
		climb_angle = PI + (PI / 2)
		floor_max_angle = climb_angle
		form_speed = 4.0
		form_jump = 4.0
		form_air_control = 4.9
		form_mag_angle = 0.15
	if form == Form.RAT:
		pass
	if form == Form.WOLF:
		motion_mode = 0
		climb_angle = 0.5
		floor_max_angle = climb_angle
		form_speed = 7.0
		form_jump = 5.0
		form_air_control = 1.0
		form_mag_angle = 0.4
		update_up(Vector3.UP)


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
		Input.get_axis("cam_up", "cam_down")
	).limit_length(1.0)
	
	var parent_dial = current_cam.get_parent()
	if parent_dial.name == "cam_dial":
		if !cam_locked and !aiming:
			parent_dial.rotate_y(input.x * delta)
			parent_dial.rotate(
				parent_dial.transform.basis * Vector3.RIGHT, 
				input.y * delta)
			var x_percent = 1.0 - inverse_lerp(
				cam_min_x, 
				cam_max_x, 
				parent_dial.rotation.x)
			current_cam.position.z = \
				cam_distance_max * cam_distance_curve.sample(x_percent)
			current_cam.position.y = current_cam.position.z * 0.12
		elif aiming:
			pass
		
		parent_dial.rotation.y = clamp(
			parent_dial.rotation.y, 
			cam_min_y, 
			cam_max_y)
		parent_dial.rotation.x = clamp(
			parent_dial.rotation.x,
			cam_min_x,
			cam_max_x)


###
### Movement Input Block
###
func update_up(up : Vector3):
	previous_normal = get_up_direction()
	set_up_direction(up)
	$magnet_ray.target_position = up * -1.0
	print("Update Up : ", up)
	$norm_vec.look_at(up + position, Vector3.UP)


func turn_swivel_ring(target : Vector3):
	$swivel_ring.look_at(target + position, get_up_direction())


func lerp_mesh(delta : float):
	var mesh_t3 : Transform3D = $player_mesh.transform
	var swiv_t3 : Transform3D = $swivel_ring.transform
	$player_mesh.transform = mesh_t3.interpolate_with(swiv_t3, 0.25)


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


func movement_process(delta : float):
	## Get the Latest Collision data to reference the new Up Direction \
	## Based on the Normal of the collision.
	var col = get_last_slide_collision()
	if col != null:
		if col.get_normal() != get_up_direction():
			if Vector3.UP.angle_to(col.get_normal()) < climb_angle:
				update_up(col.get_normal())
	
	## Gather input vector for movement.
	move_input_vec = Vector3(
		Input.get_axis("move_left", "move_right"), 
		0, 
		Input.get_axis("move_up", "move_down")).limit_length(1.0)
	
	## Forward movement input length to anim_player
	anim_tree.set_player_move(move_input_vec.length())
	
	
	## Orientate the input vector to the camera angle.
	## **Note** This is currently limited to the aspect of walking on \
	## the ground, and only the ground.
	var direction = move_input_vec.rotated(
		Vector3.UP, current_cam.global_rotation.y)
	
	## Get the Floor Angle by comparing the StateMachinefloor normal against Vector3.UP.
	## Then get the cross product to find a perpindicular axis to rotate \
	## the Orientated Input vector upon, by Floor Angle amount.
	floor_angle = Vector3.UP.angle_to(get_up_direction())
	var cross_vec : Vector3 = Vector3.UP.cross(get_up_direction()).normalized()
	if cross_vec != Vector3.ZERO:
		direction = direction.rotated(cross_vec, floor_angle)
	
	## Check if moving at all before bothering with edge_ray
	var blended_normal : Vector3 = get_up_direction()
	if direction.length_squared() > 0.0:
		
		## Turn the Swivel Ring to match the input direction.
		## Swivel ring is used to help align the players input with
		## Mesh and Edge Detection.
		turn_swivel_ring(direction)
		
		## Move Edge Ray further when full sprinting and closer when creeping
		## adds realism to the accuracy of the edge_detection
		edge_ray.position.z = lerp(0.0, -0.3, direction.length_squared() / 1.0)
		if edge_ray.is_colliding():
			
			## Set the blended_normal to the halfway between the detected
			## normal and the current up direction to enhance the 
			## Magnet Pull while moving.
			blended_normal = get_up_direction().lerp(edge_ray.get_collision_normal(), 0.5)
			if blended_normal.angle_to(get_up_direction()) > 0.1 \
			and Vector3.UP.angle_to(blended_normal) < climb_angle:
				update_up(blended_normal)
				human_mesh.material_override = test_mat_a
			else:
				human_mesh.material_override = test_mat_b
	
	## Finally, apply the velocity
	accelerated_dir = direction * form_speed
	if is_on_floor():
		velocity = accelerated_dir
		if jump_velocity != Vector3.ZERO:
			player_landed()
		$norm_vec/mag.visible = false
	else:
		## Check if the Magnet Ray is colliding, if so pull the player to it
		## by subtracting blended_normal from the velocity.
		if $magnet_ray.is_colliding() \
		and Vector3.UP.angle_to(blended_normal) >= form_mag_angle \
		and magnet_cooldown <= 0:
			velocity -= blended_normal * MAG_PULL
			$norm_vec/mag.visible = true
		else:
			if blended_normal != Vector3.UP:
				update_up(Vector3.UP)
			## Apply Gravity
			velocity.y -= gravity * delta
			$norm_vec/mag.visible = false
			
			## Check if player has jumped, and apply jump velocity
			if jump_velocity != Vector3.ZERO:
				apply_jump_velocity(delta)
	
	## For Testing Purposes.
	## Resets player to Center if they "fall out"
	if position.y < -10:
		velocity = Vector3.ZERO
		position = Vector3(0, 2, 0)


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


func action_effects(delta):
	if dodge_active > 0:
		print("Dodge Active : ", dodge_active)
		velocity = dodge_direction * DODGE_SPEED
	
	## If attack frames are active, filter through the targets gathered \
	## by the detection hitbox. Then apply the hit for this attack, and \
	## add them to the list of struck enemies to prevent double-proc.
	if attack_active and attack_active_ebrake > 0:
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
			dodge_cooldown = 15
			dodge_active = 10
			dodge_direction = accelerated_dir.normalized()
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
		print("Aim Pressed")
		aiming = true
		$cam_dial/Aim_Cam.make_current()
	elif !$cam_dial/Player_Cam.is_current():
		aiming = false
		$cam_dial/Player_Cam.make_current()
	
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
#				anim_tree.start_attack(attack_chain)
			elif attack_interrupt:
				if attack_chain < 3:
					attack_chain += 1
				else:
					attack_chain = 1
				attack_interrupt = false
#				anim_tree.start_attack(attack_chain)
	
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


func _input(event):
	pass
#	print("Player Received Event: ", event)

