extends Node3D

@onready var anim : AnimationPlayer = $spider_model_0_1/AnimationPlayer
var legs : Array = []
var legs_left : Array = []
var legs_right : Array = []
var found_legs : bool = false

var walking : bool = false
var speed : float = 0.5

func _ready():
	legs.clear()
	legs_left.clear()
	legs_right.clear()
	for child in $spider_model_0_1/SpiderArmature.get_children():
		if child.name.contains("leg_"):
			legs.append(child)
			if child.name.contains("leg_l"):
				legs_left.append(child)
			if child.name.contains("leg_r"):
				legs_right.append(child)
	if legs.size() >= 8:
		found_legs = true


func _process(delta):
	if found_legs and walking:
		pass
		# I think a proc walk cycle could be fun.
		# just make an array of rotation instructions.
		# an offset list of the left legs and right legs maybe?


func walk(speed : float):
	if speed > 0.8:
		if anim.current_animation != "fast_bob":
			anim.play("fast_bob")
	else:
		if anim.current_animation != "slow_bob":
			anim.play("slow_bob")
	if speed >= 0.1:
		walking = true
	else:
		stop()


func stop():
	if walking:
		walking = false


