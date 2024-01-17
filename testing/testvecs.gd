extends Node3D

var normal = Vector3.UP


# Called when the node enters the scene tree for the first time.
func _ready():
#	n_tran = $Normal.transform
	pass # Replace with function body.


#func _input(event):
#	if event is InputEventKey:
#		if event.pressed and event.keycode == KEY_W:
#			n_tran = n_tran.rotated(Vector3.RIGHT, PI / -4)
#		if event.pressed and event.keycode == KEY_S:
#			n_tran = n_tran.rotated(Vector3.RIGHT, PI / 4)
#		if event.pressed and event.keycode == KEY_A:
#			n_tran = n_tran.rotated(Vector3.UP, PI / -4)
#		if event.pressed and event.keycode == KEY_D:
#			n_tran = n_tran.rotated(Vector3.UP, PI / 4)
#		$Normal.transform = n_tran


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
#	$Normal.look_at(normal, Vector3.UP)
#	$Normal.rotation = normal
#	normal = n_tran.basis * normal
#	normal = $Normal.transform.basis.get_rotation_quaternion().get_axis()
	normal = ($Normal.transform.basis * Vector3.UP).normalized()
	print(normal)
	
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var input_3d = Vector3(input_dir.x, 0, input_dir.y)
#	input_3d = $Camera3D.transform.basis * input_3d
	input_3d = input_3d.rotated(Vector3.UP, $Camera3D.rotation.y)
	if input_dir != Vector2.ZERO:
		$Input.look_at(input_3d + $Input.position, Vector3.UP)
	
#	var result_dir = input_3d.reflect(normal)
	var result_dir = input_3d.slide(normal)
#	var result_dir = input_3d.cross(normal)
	$Result.look_at(result_dir + $Result.position, normal)

