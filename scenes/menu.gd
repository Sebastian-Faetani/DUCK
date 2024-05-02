extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/StartButton.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_level.tscn")


func _on_options_button_pressed():
	pass
	#var options = load("res://icon.svg").instance()
	#get_tree().current_scene.add_child(options)

func _on_credits_button_pressed():
	get_tree().change_scene_to_file("res://scenes/creditos.tscn")

func _on_extras_button_pressed():
	pass # Replace with function body.

func _on_quit_button_pressed():
	get_tree().quit()
