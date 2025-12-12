extends Node

@onready var click_sound = $ClickSound
@onready var defeat_sound = $DefeatSound

func _ready():
	# Play defeat sound immediately when scene loads
	if defeat_sound:
		defeat_sound.play()

func _on_button_pressed() -> void:
	# Play button click sound
	if click_sound:
		click_sound.play()
	
	# Wait for audio feedback (0.2 seconds)
	var tree = get_tree()
	if tree:
		await tree.create_timer(0.2).timeout
		
		if OS.has_feature("web"):
			# Refresh page - will automatically go to React main menu
			JavaScriptBridge.eval("window.parent.location.reload();")
		else:
			# Fallback for testing in editor
			tree.quit()
	else:
		push_error("SceneTree not available!")
