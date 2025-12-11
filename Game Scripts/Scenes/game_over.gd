extends Node

@onready var click_sound = $ClickSound

func _on_button_pressed() -> void:
	# Play button click sound
	if click_sound:
		click_sound.play()
	
	# Wait sebentar untuk audio feedback (0.2 detik)
	var tree = get_tree()
	if tree:
		await tree.create_timer(0.2).timeout
		tree.change_scene_to_file("res://Game Scenes/Main_Menu/Main_Menu.tscn")
	else:
		push_error("SceneTree not available!")
