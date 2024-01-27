extends Node3D


func _on_interactable_lever_activate():
	$base/handle_joint.rotation_degrees.z = -30


func _on_interactable_lever_deactivate():
	$base/handle_joint.rotation_degrees.z = 30
