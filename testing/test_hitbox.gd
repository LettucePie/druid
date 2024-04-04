extends Node3D

var counter : int = 0
@onready var mat : BaseMaterial3D = $mesh.get_surface_override_material(0)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func player_hit():
	counter += 1
	print("Player Hit Box : ", counter, " times!")
	if counter % 2 == 0:
		set_color(Color.RED)
	else:
		set_color(Color.BLUE)


func set_color(col : Color):
	mat.albedo_color = col
