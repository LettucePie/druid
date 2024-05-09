extends Node
class_name Player_Animator 
## Migrate core/player_animtree.gd to here, reduce anim clutter from player.gd
## Revisit often

#### Animation Trees and Player Nodes
@onready var human_tree : AnimationTree = $human_animtree
@onready var wolf_tree : AnimationTree = $wolf_animtree
##
@export var human_anim : AnimationPlayer = null
@export var wolf_anim : AnimationPlayer = null



## Lists
var trees : Array = []
var anims : Array = []


## Dynamics
var form : Player.Form = Player.Form.HUMAN
var current_tree : AnimationTree = human_tree
var current_anim : AnimationPlayer = null
var blends_stature : bool = true
var movement_target : String = "parameters/movement/blend_position"
var player_move : float = 0.0
var mobile : bool = false
var player_action : String = ""
var performing : bool = false
var override_anim : String = ""


func _ready():
	## Checkups
	if human_anim == null and human_tree != null:
		human_anim = get_node(human_tree.anim_player)
	if wolf_anim == null and wolf_tree != null:
		wolf_anim = get_node(wolf_tree.anim_player)
	call_deferred("populate_lists")
	call_deferred("connect_signals")
	## Set Currents
	current_tree = human_tree
	current_anim = human_anim


## Creates lists of anim_trees and anim_players for iteration
func populate_lists():
	## Clean
	trees.clear()
	anims.clear()
	## Build
	trees = [
		human_tree,
		wolf_tree
	]
	anims = [
		human_anim,
		wolf_anim
	]


## Connects all the animation start and end signals
func connect_signals():
	for a in anims:
		print(a)
		if a.animation_started.is_connected(_on_animation_started) == false:
			a.animation_started.connect(_on_animation_started)
		if a.animation_finished.is_connected(_on_animation_finished) == false:
			a.animation_finished.connect(_on_animation_finished)


## Setup current_tree and current_anim to the desired form.
## also can be used for setting flags and parameters like 'blends_stature'
func set_form(new_form : Player.Form):
	for tree in trees:
		tree.active = false
	form = new_form
	if form == Player.Form.HUMAN:
		current_tree = human_tree
		current_anim = human_anim
		blends_stature = true
	elif form == Player.Form.SPIDER:
		print("Update upon Spider form addition")
		current_tree = human_tree
		current_anim = human_anim
		blends_stature = true
	elif form == Player.Form.RAT:
		print("Update upon Rat form addition")
		current_tree = human_tree
		current_anim = human_anim
		blends_stature = true
	elif form == Player.Form.WOLF:
		current_tree = wolf_tree
		current_anim = wolf_anim
		blends_stature = false
	current_tree.active = true



## Sets the movement value for the BlendSpace1D that flucuates between \
## idling, walking, and running
func set_player_move(movement : float):
	player_move = movement
	if blends_stature:
		if movement > 0.1:
			set_mobile(true)
		else:
			set_mobile(false)
	## Assign Movement input Length to movement_speed_blend
	current_tree.set(movement_target, movement)


## Enables or Disables the blending of Movement animations into current action
func set_mobile(value : bool):
	mobile = value
	current_tree.set("parameters/blend_movement/blend_amount", int(value))


## Signal Receiver: Animations that are started by the Animation Tree get \
## passed to here. Goal is to mark them as the current player action, and \
## set the performing state.
func _on_animation_started(anim_name):
	print("AnimationTree Started Animation: ", anim_name)
#	print(anim_name, " is action: ", actions.has(anim_name), " | is movement: ", movements.has(anim_name))
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
	if blends_stature:
		current_tree.tree_root.get_node("blend_movement").filter_enabled = value


####
####
####


## Override function
func force_play(animation : String):
	if current_tree.active and current_anim.has_animation(animation):
		override_anim = animation
		current_tree.active = false
		current_anim.play(animation)
		start_action(animation)


func _on_animation_player_animation_finished(anim_name):
	if !current_tree.active and override_anim != "":
		override_anim = ""
		current_tree.active = true
#		_on_animation_finished(anim_name)
