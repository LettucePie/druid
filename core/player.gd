extends CharacterBody3D

class_name Player

## Signals
signal request_form_wheel()
signal report_current_form(form)
signal request_cam_movement(direction)


## Camera Variables
var cam_locked : bool = false
var cam_min_y : float = -PI
var cam_max_y : float = PI
var cam_min_x : float = PI * -0.35
var cam_max_x : float = PI * 0.35
@export var cam_distance_curve : Curve
var cam_distance_max : float = 10.0


## Movement Variables
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MAG_PULL = SPEED + 1.5
const MAG_ANGLE = 0.85
var previous_normal : Vector3 = Vector3.UP
var current_cam : Camera3D
@onready var edge_ray : RayCast3D = $swivel_ring/edge_ray
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var climb_angle : float = 0.3


## Druid Variables
enum Form {HUMAN, SPIDER, RAT, WOLF}
var available_forms : Array = [Form.HUMAN, Form.SPIDER]
var current_form : Form = Form.HUMAN


func _ready():
	current_cam = get_viewport().get_camera_3d()
	motion_mode = 0
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
		update_up(Vector3.UP)
	if form == Form.SPIDER:
		motion_mode = 0
		climb_angle = PI + (PI / 2)
		floor_max_angle = climb_angle
	if form == Form.RAT:
		pass
	if form == Form.WOLF:
		pass


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
		if !cam_locked:
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
	print("Update Up Direction ", get_up_direction())


func turn_swivel_ring(target : Vector3):
	$swivel_ring.look_at(target + position, get_up_direction())


func lerp_mesh(delta : float):
	var mesh_t3 : Transform3D = $MeshInstance3D.transform
	var swiv_t3 : Transform3D = $swivel_ring.transform
	$MeshInstance3D.transform = mesh_t3.interpolate_with(swiv_t3, 0.25)


func movement_process(delta : float):
	## Get the Latest Collision data to reference the new Up Direction \
	## Based on the Normal of the collision.
	var col = get_last_slide_collision()
	if col != null:
		if col.get_normal() != get_up_direction():
			if Vector3.UP.angle_to(col.get_normal()) < climb_angle:
				update_up(col.get_normal())
	
	## Gather input vector for movement.
	var input_vec : Vector3 = Vector3(
		Input.get_axis("move_left", "move_right"), 
		0, 
		Input.get_axis("move_up", "move_down")).limit_length(1.0)
	
	## Orientate the input vector to the camera angle.
	## **Note** This is currently limited to the aspect of walking on \
	## the ground, and only the ground.
	var direction = input_vec.rotated(Vector3.UP, current_cam.global_rotation.y)
	
	## Get the Floor Angle by comparing the floor normal against Vector3.UP.
	## Then get the cross product to find a perpindicular axis to rotate \
	## the Orientated Input vector upon, by Floor Angle amount.
	var floor_angle : float = Vector3.UP.angle_to(get_up_direction())
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
		edge_ray.position.z = lerp(0.0, -0.5, direction.length_squared() / 1.0)
		if edge_ray.is_colliding():
			
			## Set the blended_normal to the halfway between the detected
			## normal and the current up direction to enhance the 
			## Magnet Pull while moving.
			blended_normal = get_up_direction().lerp(edge_ray.get_collision_normal(), 0.5)
			if blended_normal.angle_to(get_up_direction()) > 0.25 \
			and Vector3.UP.angle_to(blended_normal) < climb_angle:
				update_up(blended_normal)
	
	## Finally, apply the velocity
	var accelerated_dir : Vector3 = direction * SPEED
	if is_on_floor():
		velocity = accelerated_dir
	else:
		## Check if the Magnet Ray is colliding, if so pull the player to it
		## by subtracting blended_normal from the velocity.
		if $magnet_ray.is_colliding() and floor_angle >= MAG_ANGLE:
			velocity -= blended_normal * MAG_PULL
		else:
			if blended_normal != Vector3.UP:
				update_up(Vector3.UP)
			velocity.x = accelerated_dir.x
			velocity.y -= gravity * delta
			velocity.z = accelerated_dir.z
	
	## For Testing Purposes.
	## Resets player to Center if they "fall out"
	if position.y < -10:
		velocity = Vector3.ZERO
		position = Vector3(0, 2, 0)


###
### Action Input Block
###
func action_process(delta):
	if Input.is_action_pressed("jump") and is_on_floor():
		if current_form == Form.HUMAN:
#			velocity = velocity.lerp(get_up_direction() * JUMP_VELOCITY, 0.5)
			velocity.y = JUMP_VELOCITY
	if Input.is_action_just_pressed("form_switcher"):
		if current_form == Form.HUMAN:
			set_form_to(Form.SPIDER)
		else:
			set_form_to(Form.HUMAN)


func _physics_process(delta):
	cam_process(delta)
	movement_process(delta)
	action_process(delta)
	move_and_slide()
	lerp_mesh(delta)



func _input(event):
	pass
#	print("Player Received Event: ", event)
