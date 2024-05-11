extends Node
class_name Player_Animator 
## Migrate core/player_animtree.gd to here, reduce anim clutter from player.gd
## Revisit often

#### Animation Trees and Player Nodes
@onready var player : Player = get_parent()
@onready var human_tree : AnimationTree = $human_animtree
@onready var wolf_tree : AnimationTree = $wolf_animtree
##
@export var human_anim : AnimationPlayer = null
@export var wolf_anim : AnimationPlayer = null


## Lists
var trees : Array = []
var anims : Array = []
## For when queuing animations, if these are active, ignore.
var low_priority_animations : PackedStringArray = []


## Dynamics
var form : Player.Form = Player.Form.HUMAN
var current_tree : AnimationTree = human_tree
var current_anim : AnimationPlayer = null
var state_machine : AnimationNodeStateMachine = null
var playback : AnimationNodeStateMachinePlayback = null
var blends_stature : bool = true
var movement_target : String = "parameters/movement/blend_position"
var player_move : float = 0.0
var mobile : bool = false


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
	state_machine = current_tree.tree_root
	playback = current_tree.get("parameters/playback")


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
	for a in trees:
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
	state_machine = current_tree.tree_root
	playback = current_tree.get("parameters/playback")


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


## Auto Advance Expression does not work well... at least in current config.
## This is going to be the main avenue for playing animations.
## Here we clarify animation name conversions, or other bonus effects per form.
func play(animation : String):
	print("Playing Animation ", animation)
	if state_machine.has_node(animation):
		playback.start(animation)
	else:
		print("State Machine missing animation-action ", animation, "!!!")
		if current_anim.has_animation(animation):
			print("Backup plan! Using AnimPlayer")
			current_anim.play(animation)
		else:
			print("Animation ", animation, " COMPLETELY UNAVAILABLE")


func queue(animation : String, at_end : bool):
	print("Queuing Animation ", animation, " at end = ", at_end)
	print("Fill this out lol")


## Signal Receiver
func _on_animation_started(anim_name):
	print("AnimationTree Started Animation: ", anim_name)



## Signal Receiver
func _on_animation_finished(anim_name):
	print("AnimationTree Finished Animation: ", anim_name)
	if anim_name == "jump" and !player.is_on_floor():
		play("fall")
