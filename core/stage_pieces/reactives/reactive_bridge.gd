extends Node3D

@export var start_active : bool = false
var active : bool = false

func _ready():
	active = start_active
	if active:
		_on_activate()
	else:
		_on_deactivate()


func _on_activate():
	print("Bridge Activated")
	active = true
	$mesh.visible = true
	$mesh.process_mode = Node.PROCESS_MODE_INHERIT


func _on_deactivate():
	active = false
	$mesh.visible = false
	$mesh.process_mode = Node.PROCESS_MODE_DISABLED
