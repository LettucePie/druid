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
	set("parameters/mobile/movement_speed_blend/blend_position", movement)


func set_mobile(value : bool):
	mobile = value
	var state_machine = get("parameters/playback")
	if mobile:
		state_machine.travel("mobile")
	else:
		state_machine.travel("stationary")


func start_attack(chain_number : int):
	print("ANIMTREE: Starting Attack: ", chain_number)
	var anim_playback = get("parameters/stationary/playback")
	if mobile:
		anim_playback = get("parameters/mobile/attack_chain/playback")
	print("TargetPlayback.is_playing == ", anim_playback.is_playing())
	anim_playback.start("attack_" + str(chain_number))


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
