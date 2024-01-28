extends Node

@export var player_scene : PackedScene

## Core Variables
@export var stage : Stage
@export var gui : Gui
var player : Player


func gather_core() -> bool:
	var children : Array = get_children()
	var stage_found : bool = false
	var gui_found : bool = false
	if children.size() > 0:
		for child in children:
			if child is Node3D and !stage_found:
				stage_found = true
				stage = child
			if child is Control and !gui_found:
				gui_found = true
				gui = child
	else:
		return false
	return stage_found and gui_found == true


func connect_core() -> bool:
	player.connect("report_current_form", gui.set_current_form)
	player.connect("report_interactive_popup", gui.set_current_popup)
	return true


func _ready():
	var stage_gui_present : bool = false
	if stage == null or gui == null:
		if gather_core():
			stage_gui_present = true
		else:
			print("Failed to find Core Elements")
			get_tree().quit()
	else:
		stage_gui_present = true
	if player_scene != null:
		player = player_scene.instantiate()
		add_child(player)
	else:
		print("Failed to find and instantiate Player Scene")
		get_tree().quit()
	if connect_core():
		print("Core elements signals are connected")
	else:
		print("Failed to connect Core Elements")
		get_tree().quit()
	initialize_player()


func initialize_player():
	player.position = stage.start_point.position
#	player.position = stage.checkpoint_spawns[stage.current_checkpoint].position
	player.set_form_to(player.Form.HUMAN)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
