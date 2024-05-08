extends Node
class_name Player_Animator

#### Animation Trees and Player Nodes
@onready var human_tree : AnimationTree = $human_animtree
@onready var wolf_tree : AnimationTree = $wolf_animtree
##
@export var human_anim : AnimationPlayer = null
@export var wolf_anim : AnimationPlayer = null

var form : Player.Form = Player.Form.HUMAN

# Called when the node enters the scene tree for the first time.
func _ready():
	## Checkups
	if human_anim == null and human_tree != null:
		human_anim = human_tree.anim_player
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
