extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var previous_normal : Vector3 = Vector3.UP
var current_cam : Camera3D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready():
	current_cam = get_viewport().get_camera_3d()
	motion_mode = 0
	floor_max_angle = PI


func update_up(up : Vector3):
	previous_normal = get_up_direction()
	set_up_direction(up)
	$magnet_ray.target_position = up * -1.0
	print("Update Up Direction ", get_up_direction())


func _physics_process(delta):
	current_cam = get_viewport().get_camera_3d()
	var col = get_last_slide_collision()
	if col != null:
		if col.get_normal() != get_up_direction():
			update_up(col.get_normal())
	var input_h = Input.get_axis("stick_l_x-", "stick_l_x+")
	var input_v = Input.get_axis("stick_l_y-", "stick_l_y+")
	var input_vec : Vector3 = Vector3(input_h, 0, input_v)
	var direction = input_vec.rotated(Vector3.UP, current_cam.rotation.y).normalized()
	var floor_angle : float = Vector3.UP.angle_to(get_up_direction())
#	print(floor_angle, " / ", (PI / 6))
	if floor_angle > (PI / 6):
#		direction = input_vec.slide(get_up_direction())
		direction = direction.rotated(
			Vector3.UP.cross(get_up_direction()).normalized(),
			floor_angle
		).normalized()
	if is_on_floor() or is_on_wall():
#		print("Floor: ", is_on_floor(), " Wall: ", is_on_wall())
		velocity = direction * SPEED
	else:
#		print("falling")
		if $magnet_ray.is_colliding() and floor_angle > (PI / 6):
#			print("pull to wall")
			velocity -= get_up_direction() * (gravity * delta)
		else:
#			print("disconnected from wall, traditional fall")
			if get_up_direction() != Vector3.UP:
				update_up(Vector3.UP)
			velocity.y -= gravity * delta
	move_and_slide()


func _input(event):
	pass
#	print("Player Received Event: ", event)
