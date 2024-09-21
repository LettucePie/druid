extends Node3D

@onready var anim : AnimationPlayer = $spider_model_0_1/AnimationPlayer

const FLEX = PI / 8
const ROTATESPEED = PI / 16
const FLICKSPEED = PI / 6

class Leg:
	var leg_node : Node3D
	var leg_start_y : float
	var leg_front_y : float
	var leg_back_y : float

var legs : Array[Leg] = []
var legs_left : Array[Leg] = []
var legs_right : Array[Leg] = []
var found_legs : bool = false

var left_order : Array = [0, 2, 1, 3]
var right_order : Array = [1, 3, 0, 2]
var current_order : int = 0
var current_legs : Array[Leg] = []

var walking : bool = false
var speed : float = 0.5


func _ready():
	legs.clear()
	legs_left.clear()
	legs_right.clear()
	for child in $spider_model_0_1/SpiderArmature.get_children():
		if child.name.contains("leg_"):
			var new_leg : Leg = Leg.new()
			new_leg.leg_node = child
			new_leg.leg_start_y = child.rotation.y
			if child.name.contains("leg_l"):
				new_leg.leg_front_y = new_leg.leg_start_y - FLEX
				new_leg.leg_back_y = new_leg.leg_start_y + FLEX
				legs_left.append(new_leg)
			if child.name.contains("leg_r"):
				new_leg.leg_front_y = new_leg.leg_start_y + FLEX
				new_leg.leg_back_y = new_leg.leg_start_y - FLEX
				legs_right.append(new_leg)
			legs.append(new_leg)
	if legs.size() >= 8:
		found_legs = true
		_queue_legs()
		_queue_legs()


func _queue_legs():
	print("Queue Legs")
	if current_legs.size() <= 2:
		print("Adding Legs from Order Index: ", current_order)
		current_legs.append(legs_left[left_order[current_order]])
		_flick_leg(legs_left[left_order[current_order]])
		current_legs.append(legs_right[right_order[current_order]])
		_flick_leg(legs_right[right_order[current_order]])
		current_order += 1
		if current_order > 3:
			current_order = 0
	else:
		print("Leg Queue Full")


func _flick_leg(leg : Leg):
	leg.leg_node.rotation.y = leg.leg_front_y


func _process(delta):
	if found_legs and walking:
		print("Walking")
		var finished_legs : Array[Leg] = []
		for leg in current_legs:
			print("Moving Leg: ", leg.leg_node.name)
			leg.leg_node.rotation.y = move_toward(
				leg.leg_node.rotation.y, 
				leg.leg_back_y, 
				ROTATESPEED * speed
			)
			print(" - ", leg.leg_node.name, " rot_y : ", leg.leg_node.rotation.y, "\n - ", leg.leg_back_y)
			if is_equal_approx(leg.leg_node.rotation.y, leg.leg_back_y):
				finished_legs.append(leg)
				print("Leg Finished Journey: ", leg.leg_node.name)
		if finished_legs.size() > 0:
			for finished in finished_legs:
				current_legs.erase(finished)
		_queue_legs()
		
		# I think a proc walk cycle could be fun.
		# just make an array of rotation instructions.
		# an offset list of the left legs and right legs maybe?


func walk(new_speed : float):
	speed = new_speed
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
		speed = 0.0


