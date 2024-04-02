extends AnimationTree

@onready var anim : AnimationPlayer = get_node(anim_player)

var player_move : float = 0.0
var mobile : bool = false

var override_anim : String = ""


func set_player_move(movement : float):
	player_move = movement
	if movement > 0.1:
		set_mobile(true)
	else:
		set_mobile(false)
	## Assign Movement input Length to movement_speed_blend
	set("parameters/movement/blend_position", movement)


func set_mobile(value : bool):
	mobile = value
	set("parameters/stationary_or/blend_amount", int(value))
	if value:
		## Reset Stationary StateMachine
		pass
#		get("parameters/stationary/playback").start("Start")
	else:
		## Reset Mobile StateMachine(s)
		pass
#		get("parameters/attack_chain/playback").start("Start")


func start_attack(chain_number : int):
#	var anim_playback = get("parameters/stationary/playback")
#	if mobile:
#		anim_playback = get("parameters/attack_chain/playback")
#	print("ANIMTREE: Starting Attack: ", chain_number, " in playback: ", anim_playback)
#	print(anim_playback, ".is_playing == ", anim_playback.is_playing())
#	anim_playback.start("attack_" + str(chain_number))
	
	## Oh okay, so let's try syncing animations on both stationary and mobile.
	get("parameters/stationary/playback").start("attack_" + str(chain_number))
	get("parameters/attack_chain/playback").start("attack_" + str(chain_number))
	print("Dang... I have to blend this in somehow... ugh")


####
####
####


func force_play(animation : String):
	if active and anim.has_animation(animation):
		override_anim = animation
		active = false
		anim.play(animation)


func _on_animation_player_animation_finished(anim_name):
	pass # Replace with function body.
