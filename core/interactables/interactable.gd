extends Node3D
class_name Interactable

## Signals
signal activate()
signal deactivate()

## Setup and Configure
enum Interact_Type {LEVER, BUTTON, PRESSURE}
@export var interactable_type : Interact_Type
@export var player_only : bool = true
@export var start_active : bool = false

## Running Variables
var player : Player = null
var proximity : bool = false
var activated : bool = false


func _ready():
	if start_active:
		activated = true
		emit_signal("activate")


func _on_proxim_body_entered(body):
	print("Interactable Proxim Entered")
	if player_only:
		if body.is_in_group("Player") and body is Player:
			player = body
			proximity = true
			if interactable_type == Interact_Type.PRESSURE:
				activated = true
				emit_signal("activate")
			else:
				player.proximity_interactable(self)
	else:
		proximity = true


func _on_proxim_body_exited(body):
	if proximity:
		proximity = false
		if body == player:
			if interactable_type == Interact_Type.PRESSURE:
				activated = false
				emit_signal("deactivate")
			else:
				player.out_of_range_interactable(self)
			player = null


func interact_command():
	if interactable_type == Interact_Type.LEVER:
		if activated:
			activated = false
			emit_signal("deactivate")
		else:
			activated = true
			emit_signal("activate")
	if interactable_type == Interact_Type.BUTTON \
	and !activated:
		activated = true
		emit_signal("activate")
