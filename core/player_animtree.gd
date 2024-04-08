extends AnimationTree
class_name AnimTreeTool

@onready var anim : AnimationPlayer = get_node(anim_player)

@export var actions : PackedStringArray = []
@export var movements : PackedStringArray = []

var player_move : float = 0.0
var mobile : bool = false
var player_action : String = ""
var performing : bool = false

var override_anim : String = ""


func _ready():
	if !self.animation_started.is_connected(_on_animation_started):
		self.animation_started.connect(_on_animation_started)
	if !self.animation_finished.is_connected(_on_animation_finished):
		self.animation_finished.connect(_on_animation_finished)


## Sets the movement value for the BlendSpace1D that flucuates between \
## idling, walking, and running
func set_player_move(movement : float):
	player_move = movement
	if movement > 0.1:
		set_mobile(true)
	else:
		set_mobile(false)
	## Assign Movement input Length to movement_speed_blend
	set("parameters/movement/blend_position", movement)


## Enables or Disables the blending of Movement animations into current action
func set_mobile(value : bool):
	mobile = value
	set("parameters/blend_movement/blend_amount", int(value))


## Signal Receiver: Animations that are started by the Animation Tree get \
## passed to here. Goal is to mark them as the current player action, and \
## set the performing state.
func _on_animation_started(anim_name):
	print("AnimationTree Started Animation: ", anim_name)
	print(anim_name, " is action: ", actions.has(anim_name), " | is movement: ", movements.has(anim_name))
	start_action(anim_name)


## extension of _on_animation_started that's extracted for flexible calling.
func start_action(action_name : String):
	print("AnimationTree Starting Animation Action: ", action_name)
	player_action = action_name
	set_performing(true)


## Signal Receiver: Once player action animations are finished, clear the \
## current player action, and updated the performing state.
func _on_animation_finished(anim_name):
	print("AnimationTree Finished Animation: ", anim_name)
	if player_action == anim_name:
		set_performing(false)
		player_action = ""


## Controls whether we are performing an action, and reflects that in the \
## movement blending filter. If not performing action, we get the full    \
## unfiltered movement animation.
func set_performing(value : bool):
	performing = value
	tree_root.get_node("blend_movement").filter_enabled = value


####
####
####


## Override function
func force_play(animation : String):
	if active and anim.has_animation(animation):
		override_anim = animation
		active = false
		anim.play(animation)
		start_action(animation)


func _on_animation_player_animation_finished(anim_name):
	if !active and override_anim != "":
		override_anim = ""
		active = true
#		_on_animation_finished(anim_name)



