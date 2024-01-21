extends CharacterBody3D

class_name Player

## Signals
signal report_current_form(form)


## Movement Variables
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MAG_PULL = SPEED + 1.5
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
### Movement Block
###
func update_up(up : Vector3):
	previous_normal = get_up_direction()
	set_up_direction(up)
	$magnet_ray.target_position = up * -1.0
	print("Update Up Direction ", get_up_direction())
	print("Angle from Vec3UP : ", Vector3.UP.angle_to(get_up_direction()))


func turn_swivel_ring(target : Vector3):
	$swivel_ring.look_at(target + position, get_up_direction())


func lerp_mesh(delta : float):
	var mesh_t3 : Transform3D = $MeshInstance3D.transform
	var swiv_t3 : Transform3D = $swivel_ring.transform
	$MeshInstance3D.transform = mesh_t3.interpolate_with(swiv_t3, 0.25)


func _physics_process(delta):
	current_cam = get_viewport().get_camera_3d()
	
	## Climbing / Steepness
	var col = get_last_slide_collision()
	if col != null:
		if col.get_normal() != get_up_direction():
			if Vector3.UP.angle_to(col.get_normal()) < climb_angle:
				update_up(col.get_normal())
	
	var input_h = Input.get_axis("stick_l_x-", "stick_l_x+")
	var input_v = Input.get_axis("stick_l_y-", "stick_l_y+")
	var input_vec : Vector3 = Vector3(input_h, 0, input_v).limit_length(1.0)
	var direction = input_vec.rotated(Vector3.UP, current_cam.global_rotation.y)
	var floor_angle : float = Vector3.UP.angle_to(get_up_direction())
	direction = direction.rotated(
		Vector3.UP.cross(get_up_direction()).normalized(),
		floor_angle)
	
	## Turn the Swivel Ring to match the input direction.
	## Swivel ring is used to help align the players input with
	## Mesh and Edge Detection.
	turn_swivel_ring(direction)
	
	## Check if moving at all before bothering with edge_ray
	var blended_normal : Vector3 = get_up_direction()
	if direction.length_squared() > 0.0:
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
	
	if is_on_floor() or is_on_wall():
		velocity = direction * SPEED
	else:
		## Check if the Magnet Ray is colliding, if so pull the player to it
		## by subtracting up normal against the velocity.
		if $magnet_ray.is_colliding():
			velocity -= blended_normal * MAG_PULL
		else:
			if blended_normal != Vector3.UP:
				update_up(Vector3.UP)
			velocity.y -= gravity * delta
	move_and_slide()
	lerp_mesh(delta)
	
	if position.y < -10:
		velocity = Vector3.ZERO
		position = Vector3(0, 2, 0)


func _input(event):
	pass
#	print("Player Received Event: ", event)
