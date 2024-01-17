extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var current_cam : Camera3D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready():
	current_cam = get_viewport().get_camera_3d()
	motion_mode = 1
	floor_max_angle = PI


func update_up():
	pass


func _physics_process(delta):
	current_cam = get_viewport().get_camera_3d()
	var col = get_last_slide_collision()
	if col != null:
		if col.get_normal() != get_up_direction():
			set_up_direction(col.get_normal())
			print("Update Up Direction ", get_up_direction())
	var input_h = Input.get_axis("stick_l_x-", "stick_l_x+")
	var input_v = Input.get_axis("stick_l_y-", "stick_l_y+")
	var input_vec : Vector3 = Vector3(input_h, 0, input_v)
	var direction = input_vec.rotated(Vector3.UP, current_cam.rotation.y)
	if get_up_direction() != Vector3.UP:
		direction = direction.slide(get_up_direction())
	if is_on_floor() or is_on_wall():
		print("Floor: ", is_on_floor(), " Wall: ", is_on_wall())
		velocity = direction * SPEED
	else:
		print("falling")
		set_up_direction(Vector3.UP)
		velocity.y -= gravity * delta
	move_and_slide()


func _input(event):
	pass
#	print("Player Received Event: ", event)
