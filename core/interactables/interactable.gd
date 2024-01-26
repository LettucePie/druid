extends Node3D
class_name Interactable

## Signals
signal activate()
signal deactivate()

## Setup and Configure
enum Interact_Type {LEVER, BUTTON}
@export var interactable_type : Interact_Type
@export var player_only : bool = true

## Running Variables
var player : Player = null
var proximity : bool = false



func _on_proxim_body_entered(body):
	if player_only:
		if body.is_in_group("Player") and body is Player:
			player = body
			proximity = true
			player.proximity_interactable(self)
	else:
		proximity = true


func _on_proxim_body_exited(body):
	if proximity:
		proximity = false
		if body == player:
			player.out_of_range_interactable(self)
			player = null
