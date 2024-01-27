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
@export var directs_animations : bool = false
@export var animation_players : Array[AnimationPlayer]
@export var active_anim : String = "activate"
@export var deactive_anim : String = "deactivate"

## Running Variables
var player : Player = null
var proximity : bool = false
var activated : bool = false


func _ready():
	if start_active:
		activated = true
		emit_signal("activate")


func call_activate():
	activated = true
	emit_signal("activate")
	if directs_animations and animation_players.size() > 0:
		for anim in animation_players:
			if anim.has_animation(active_anim):
				anim.play(active_anim)


func call_deactivate():
	activated = false
	emit_signal("deactivate")
	if directs_animations and animation_players.size() > 0:
		for anim in animation_players:
			if anim.has_animation(deactive_anim):
				anim.play(deactive_anim)


func _on_proxim_body_entered(body):
	print("Interactable Proxim Entered")
	if player_only:
		if body.is_in_group("Player") and body is Player:
			player = body
			proximity = true
			if interactable_type == Interact_Type.PRESSURE:
				call_activate()
			else:
				player.proximity_interactable(self)
	else:
		proximity = true


func _on_proxim_body_exited(body):
	if proximity:
		proximity = false
		if body == player:
			if interactable_type == Interact_Type.PRESSURE:
				call_deactivate()
			else:
				player.out_of_range_interactable(self)
			player = null


func interact_command():
	if interactable_type == Interact_Type.LEVER:
		if activated:
			call_deactivate()
		else:
			call_activate()
	if interactable_type == Interact_Type.BUTTON \
	and !activated:
		call_activate()
