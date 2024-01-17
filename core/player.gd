extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var current_cam : Camera3D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready():
	current_cam = get_viewport().get_camera_3d()


func _physics_process(delta):
	current_cam = get_viewport().get_camera_3d()
	
	# Add the gravity.
	if not is_on_floor():
		velocity -= get_up_direction() * (gravity * delta)
#		velocity.y -= gravity * delta
	else:
		## Check if climbing
		if get_slide_collision_count() > 0:
			var col : KinematicCollision3D = get_slide_collision(0)
		#	if col.get_collider().is_in_group("climbable"):
			set_up_direction(col.get_normal())

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity = get_up_direction() * JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Vector3(
		Input.get_axis("stick_l_x-", "stick_l_x+"), 
		0, 
		Input.get_axis("stick_l_y-", "stick_l_y+")).normalized()
	var stop : bool = input_dir == Vector3.ZERO
	
	## Assign movement direction to Camera Orientation
#	## Basis Method
#	var direction_orient : Basis = current_cam.transform.basis
#	var direction = (direction_orient * input_dir).normalized()
#	## Note
#	## Multiplying input by Camera.transform.basis causes direction.y to reflect
#	## the up and down tilt of the Camera.
	
	## Angle Method
	var direction = input_dir.rotated(Vector3.UP, current_cam.rotation.y)
	
	## Transform direction perpindicular to get_up_direction()
	## How? I don't know if it's cross, slide, bounce, reflect...
#	direction = direction.slide(get_up_direction())
	direction = direction.cross(get_up_direction())
	
#	print(direction)
	if stop:
		velocity.lerp(Vector3.ZERO, delta)
	else:
		velocity = direction * SPEED

	move_and_slide()


func _input(event):
	pass
#	print("Player Received Event: ", event)
