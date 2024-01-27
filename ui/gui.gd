extends Control

class_name Gui

var current_form : String = "Human"
var current_popup : String = ""


func set_current_form(new_form : String):
	current_form = new_form
	update_info()


func set_current_popup(popup : String):
	current_popup = popup
	update_info()


func update_info():
	$current_form_panel/current_form.text = "Current Form: " + current_form
	if current_popup == "":
		$popup_control.hide()
	else:
		$popup_control.show()
		$popup_control/popup_label.text = current_popup

