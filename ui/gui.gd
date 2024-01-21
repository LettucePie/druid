extends Control


var current_form : String = "Human"


func set_current_form(new_form : String):
	current_form = new_form
	update_info()


func update_info():
	$PanelContainer/current_form.text = "Current Form: " + current_form

