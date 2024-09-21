extends Node

@onready var spider : Node3D = $Node3D/spider_node



func _process(delta):
	$Node3D/dial.rotate_y(delta / 2)


func _on_anim_1_pressed():
	spider.walk(0.2)


func _on_anim_2_pressed():
	spider.walk(0.8)
