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


## Attack Chain Stuff
## Pushes commands to play the next attack in chain.
## Auto Advance Expression does not work.
## Keep managing hit frames and interrupts on player.gd and animation timelines.
func start_attack(chain : int):
	print("Starting Attack at chain : ", chain)
	playback.start("attack_" + str(chain))


## Signal Receiver
func _on_animation_started(anim_name):
	print("AnimationTree Started Animation: ", anim_name)



## Signal Receiver
func _on_animation_finished(anim_name):
	print("AnimationTree Finished Animation: ", anim_name)
