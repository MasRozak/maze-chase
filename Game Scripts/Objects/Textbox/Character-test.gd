extends Area2D

@onready var game_manager: Node = get_node_or_null("/root/GameManager")

# Audio players
var correct_sound: AudioStreamPlayer
var incorrect_sound: AudioStreamPlayer

@export var target_level : PackedScene
var answer_text : String = ""
var answer_index : int = -1

# Label untuk menampilkan jawaban
var answer_label : Label = null
var answer_panel : Panel = null

# Determine if this is top or bottom corner
var is_top_corner : bool = false

# Flag untuk mencegah multiple triggers
var is_processing_answer : bool = false

func _ready():
	# Setup audio players
	_setup_audio_players()
	
	# PENTING: Reset monitoring setiap kali scene restart
	monitoring = true
	monitorable = true
	is_processing_answer = false
	
	# Validasi GameManager
	if not game_manager:
		game_manager = get_node_or_null("../../GameManager")
		if not game_manager:
			push_error("GameManager not found! Please check node path.")
	
	# Detect position untuk menentukan top/bottom
	detect_corner_position()
	
	# Buat label untuk menampilkan jawaban
	create_answer_label()
	
	# PENTING: Jangan connect di code karena sudah connect di scene (.tscn)
	# Double connection menyebabkan masalah saat export
	
	print("🔄 Finish area initialized - monitoring: ", monitoring, " answer_index: ", answer_index)

func _setup_audio_players():
	"""Setup audio players for correct/incorrect answers"""
	# Correct sound
	correct_sound = AudioStreamPlayer.new()
	correct_sound.name = "CorrectSound"
	var correct_stream = load("res://Assets/Audio/Audio_Correct.mp3")
	if correct_stream:
		correct_sound.stream = correct_stream
	add_child(correct_sound)
	
	# Incorrect sound (using lose health sound for now)
	incorrect_sound = AudioStreamPlayer.new()
	incorrect_sound.name = "IncorrectSound"
	var incorrect_stream = load("res://Assets/Audio/Audio_Lose-Health.mp3")
	if incorrect_stream:
		incorrect_sound.stream = incorrect_stream
	add_child(incorrect_sound)
	
	print("🔊 Character-test audio players initialized")

func detect_corner_position():
	# Deteksi apakah corner ini di atas atau bawah
	# Jika Y position < 400 (setengah layar), maka top corner
	is_top_corner = global_position.y < 400
	
	# Sembunyikan collision shape visual (bundaran merah/kuning)
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape:
		collision_shape.visible = false

func create_answer_label():
	# Buat panel background yang LEBIH BESAR
	answer_panel = Panel.new()
	
	# Ukuran panel lebih besar untuk accommodate 50 kata
	var panel_width = 220
	var panel_height = 120
	
	# Deteksi posisi corner untuk menentukan penempatan
	var screen_width = 1152  # Lebar layar game
	var screen_height = 648  # Tinggi layar game
	var is_left = global_position.x < screen_width / 2
	
	# Posisi panel relatif ke sudut layar yang tepat
	if is_top_corner:
		if is_left:
			# Top-left corner
			answer_panel.position = Vector2(10 - global_position.x, 10 - global_position.y)
		else:
			# Top-right corner
			answer_panel.position = Vector2(screen_width - panel_width - 10 - global_position.x, 10 - global_position.y)
	else:
		if is_left:
			# Bottom-left corner
			answer_panel.position = Vector2(10 - global_position.x, screen_height - panel_height - 10 - global_position.y)
		else:
			# Bottom-right corner
			answer_panel.position = Vector2(screen_width - panel_width - 10 - global_position.x, screen_height - panel_height - 10 - global_position.y)
	
	answer_panel.size = Vector2(panel_width, panel_height)
	
	# Style panel dengan StyleBoxFlat
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.1, 0.2, 0.95)  # Dark purple gothic
	style_box.set_border_width_all(3)
	style_box.border_color = Color(0.4, 0.3, 0.5, 0.9)  # Soft purple border
	style_box.set_corner_radius_all(8)
	
	answer_panel.add_theme_stylebox_override("panel", style_box)
	
	# PENTING: Set z_index agar selalu terlihat di depan
	answer_panel.z_index = 100
	
	# PENTING: Set visible dan show
	answer_panel.visible = true
	answer_panel.show()
	
	add_child(answer_panel)
	
	# Buat label dengan autowrap
	answer_label = Label.new()
	answer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	answer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Load Pixelify Sans font dengan error handling yang lebih baik
	var pixelify_font = null
	if ResourceLoader.exists("res://Assets/Fonts/PIXELIFYSANS-VARIABLEFONT_WGHT.TTF"):
		pixelify_font = load("res://Assets/Fonts/PIXELIFYSANS-VARIABLEFONT_WGHT.TTF")
		if pixelify_font:
			answer_label.add_theme_font_override("font", pixelify_font)
	else:
		push_warning("Pixelify Sans font not found! Using default font.")
	
	# Style label dengan font LEBIH KECIL
	answer_label.add_theme_font_size_override("font_size", 16)  # Lebih kecil dari 22
	answer_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1.0))  # Light grayish white
	answer_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.15, 1.0))  # Dark purple outline
	answer_label.add_theme_constant_override("outline_size", 2)
	
	# PENTING: Enable autowrap untuk multi-line
	answer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Position dengan padding
	answer_label.position = Vector2(10, 10)
	answer_label.size = Vector2(panel_width - 20, panel_height - 20)
	
	# Clip text jika terlalu panjang
	answer_label.clip_text = false  # Disable clip karena kita pakai autowrap
	answer_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	
	# PENTING: Set visible dan show
	answer_label.visible = true
	answer_label.show()
	
	answer_panel.add_child(answer_label)
	
	# Debug print
	print("📝 Created answer panel at: ", answer_panel.position)
	print("📝 Panel size: ", answer_panel.size)
	print("📝 Panel visible: ", answer_panel.visible)
	
	# Animasi idle
	create_idle_animation()
	
	# Buat StaticBody2D untuk blok ghost
	create_blocking_body()

func create_blocking_body():
	# Buat StaticBody2D sebagai invisible wall untuk ghost
	var static_body = StaticBody2D.new()
	static_body.collision_layer = 2  # Layer 2 untuk obstacle
	static_body.collision_mask = 0   # Tidak perlu detect apapun
	
	# Copy collision shape dari Area2D
	var area_collision = get_node_or_null("CollisionShape2D")
	if area_collision and area_collision.shape:
		var body_collision = CollisionShape2D.new()
		body_collision.shape = area_collision.shape
		body_collision.position = area_collision.position
		static_body.add_child(body_collision)
	
	add_child(static_body)

func create_idle_animation():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(answer_panel, "scale", Vector2.ONE * 1.03, 1.0).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(answer_panel, "scale", Vector2.ONE, 1.0).set_ease(Tween.EASE_IN_OUT)

func set_answer(text: String, index: int):
	answer_text = text
	answer_index = index
	
	if answer_label:
		answer_label.text = text
		print("📝 Answer set: [", index, "] ", text)
		print("📝 Label visible: ", answer_label.visible)
		print("📝 Panel visible: ", answer_panel.visible)

func _on_body_entered(body: Node2D) -> void:
	# Prevent multiple simultaneous triggers
	if is_processing_answer:
		print("⚠️ Already processing answer, ignoring duplicate trigger")
		return
	
	if body.name != "Main_Character":
		return
	
	# Validasi GameManager
	if not game_manager:
		push_error("GameManager not found!")
		return
	
	# Validasi answer_index
	if answer_index == -1:
		push_error("Answer index not set!")
		return
	
	# Set flag untuk mencegah multiple triggers
	is_processing_answer = true
	set_deferred("monitoring", false)
	
	print("🎯 Player entered answer area: ", answer_text)
	print("🎯 Checking answer index: ", answer_index)
	print("🎯 GameManager correct_answer_index: ", game_manager.correct_answer_index)
	
	# Check answer
	var is_correct = false
	if game_manager.has_method("check_answer"):
		is_correct = game_manager.check_answer(answer_index)
	else:
		push_error("GameManager doesn't have check_answer method!")
		is_processing_answer = false
		set_deferred("monitoring", true)
		return
	
	if is_correct:
		await handle_correct_answer(body)
	else:
		await handle_wrong_answer(body)

func handle_correct_answer(body: Node2D):
	print("✅ BENAR! Jawaban: ", answer_text)
	
	# PENTING: Aktifkan invincibility agar ghost tidak damage
	if game_manager.has_method("activate_invincibility"):
		game_manager.activate_invincibility()
		print("🛡️ Player invincible during correct answer transition")
	elif game_manager.has("is_invincible"):
		game_manager.is_invincible = true
		print("🛡️ Player invincible set directly")
	
	# Notifikasi semua ghost untuk berhenti chase
	notify_ghosts_stop_chase()
	
	show_success_effect()
	play_success_sound()
	
	var tree = get_tree()
	if tree:
		await tree.create_timer(2.0).timeout
		
		if target_level:
			var result = tree.change_scene_to_packed(target_level)
			if result != OK:
				push_error("Failed to change scene to target_level: ", result)
				tree.change_scene_to_file("res://Game Scenes/Main_Menu/Main_Menu.tscn")
		else:
			tree.change_scene_to_file("res://Game Scenes/Main_Menu/Main_Menu.tscn")
	else:
		push_error("SceneTree not found!")

func handle_wrong_answer(body: Node2D):
	print("❌ SALAH! Jawaban: ", answer_text)
	
	# Kurangi lives karena jawaban salah
	print("💔 Attempting to lose life...")
	
	if game_manager and game_manager.has_method("lose_life"):
		var result = game_manager.lose_life()
		print("💔 lose_life() returned: ", result)
	else:
		push_error("Cannot call lose_life on GameManager!")
	
	show_fail_effect()
	play_fail_sound()
	
	var tree = get_tree()
	if not tree:
		push_error("SceneTree not found!")
		is_processing_answer = false
		set_deferred("monitoring", true)
		return
	
	# Wait before teleport
	await tree.create_timer(1.5).timeout
	
	# Teleport player
	teleport_to_center(body)
	
	# Play death animation SETELAH teleport
	play_death_animation(body)
	
	# Wait untuk death animation
	await tree.create_timer(2.0).timeout
	
	# PENTING: Reset quiz state untuk jawaban baru
	if game_manager and game_manager.has_method("generate_random_quiz"):
		print("🔄 Generating new quiz after wrong answer...")
		var new_quiz_data = game_manager.generate_random_quiz()
		
		if new_quiz_data and new_quiz_data.has("answers"):
			# Update semua finish dengan jawaban baru
			update_all_finish_answers(new_quiz_data)
		else:
			push_error("Invalid quiz data returned!")
	else:
		# Fallback: setidaknya reset is_quiz_answered
		if "is_quiz_answered" in game_manager:
			game_manager.is_quiz_answered = false
			print("🔄 Reset is_quiz_answered to allow re-answering")
	
	# Reset deactivate invincibility jika masih aktif
	if "is_invincible" in game_manager:
		game_manager.is_invincible = false
	
	# PENTING: Re-enable monitoring dan reset flag
	is_processing_answer = false
	set_deferred("monitoring", true)
	print("🔄 Finish area re-enabled for next attempt")

func teleport_to_center(player: Node2D):
	var tree = get_tree()
	if not tree:
		push_error("SceneTree not found in teleport_to_center!")
		return
	
	var spawn_point = tree.get_first_node_in_group("spawn_point")
	var center_position : Vector2
	
	if spawn_point:
		center_position = spawn_point.global_position
		print("📍 Teleporting to spawn point: ", center_position)
	else:
		# Default center position, lebih ke bawah dan ke kanan lagi
		center_position = Vector2(620, 360)  # Lebih ke kanan (+40) dan bawah (+44)
		print("📍 Teleporting to default center: ", center_position)
	
	create_teleport_effect(player.global_position)
	player.global_position = center_position
	
	await tree.create_timer(0.1).timeout
	create_teleport_effect(center_position)

func show_success_effect():
	var label = Label.new()
	label.text = "✓ CORRECT!"
	
	# Load font dengan error handling
	if ResourceLoader.exists("res://Assets/Fonts/PIXELIFYSANS-VARIABLEFONT_WGHT.TTF"):
		var pixelify_font = load("res://Assets/Fonts/PIXELIFYSANS-VARIABLEFONT_WGHT.TTF")
		if pixelify_font:
			label.add_theme_font_override("font", pixelify_font)
	
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color.GREEN)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	
	label.size = Vector2(250, 60)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.z_index = 100
	
	# Posisi di tengah layar (576x324 adalah center dari 1152x648)
	label.position = Vector2(576 - global_position.x - (label.size.x / 2), 324 - global_position.y - (label.size.y / 2))
	
	add_child(label)
	
	# Animasi
	label.modulate.a = 0
	label.scale = Vector2.ZERO
	
	var original_pos = label.position
	label.position.y += 30
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	tween.tween_property(label, "position", original_pos, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE * 1.4, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	tween.set_parallel(false)
	tween.tween_interval(1.2)
	tween.tween_property(label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(label.queue_free)
	
	# Glow effect
	var tween2 = create_tween()
	tween2.set_loops(3)
	tween2.tween_property(answer_panel, "modulate", Color.GREEN, 0.2)
	tween2.tween_property(answer_panel, "modulate", Color.WHITE, 0.2)

func show_fail_effect():
	var label = Label.new()
	label.text = "✗ WRONG!"
	
	# Load font dengan error handling
	if ResourceLoader.exists("res://Assets/Fonts/PIXELIFYSANS-VARIABLEFONT_WGHT.TTF"):
		var pixelify_font = load("res://Assets/Fonts/PIXELIFYSANS-VARIABLEFONT_WGHT.TTF")
		if pixelify_font:
			label.add_theme_font_override("font", pixelify_font)
	
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color.RED)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	
	label.size = Vector2(250, 60)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.z_index = 100
	
	# Posisi di tengah layar (576x324 adalah center dari 1152x648)
	label.position = Vector2(576 - global_position.x - (label.size.x / 2), 324 - global_position.y - (label.size.y / 2))
	
	add_child(label)
	
	# Animasi
	label.modulate.a = 0
	label.scale = Vector2.ZERO
	
	var original_pos = label.position
	label.position.y += 30
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	tween.tween_property(label, "position", original_pos, 0.3).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "scale", Vector2.ONE * 1.4, 0.3).set_trans(Tween.TRANS_BACK)
	
	tween.set_parallel(false)
	
	# Shake
	var orig_x = original_pos.x
	for i in range(8):
		tween.tween_property(label, "position:x", orig_x + 25, 0.04)
		tween.tween_property(label, "position:x", orig_x - 25, 0.04)
	tween.tween_property(label, "position:x", orig_x, 0.04)
	
	tween.tween_interval(0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(label.queue_free)
	
	# Flash effect
	var tween2 = create_tween()
	tween2.set_loops(4)
	tween2.tween_property(answer_panel, "modulate", Color.RED, 0.08)
	tween2.tween_property(answer_panel, "modulate", Color.WHITE, 0.08)

func create_teleport_effect(pos: Vector2):
	var particles = CPUParticles2D.new()
	var parent = get_parent()
	if not parent:
		push_error("Cannot create teleport effect: no parent node!")
		return
	
	parent.add_child(particles)
	particles.global_position = pos
	
	particles.emitting = true
	particles.amount = 50
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.explosiveness = 0.9
	
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 30
	
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.gravity = Vector2(0, 150)
	particles.initial_velocity_min = 150
	particles.initial_velocity_max = 300
	
	particles.scale_amount_min = 5
	particles.scale_amount_max = 10
	
	particles.color = Color.CYAN
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color.CYAN)
	gradient.add_point(0.5, Color.BLUE)
	gradient.add_point(1.0, Color(0, 0, 1, 0))
	particles.color_ramp = gradient
	
	var tree = get_tree()
	if tree:
		await tree.create_timer(1.2).timeout
		if is_instance_valid(particles):
			particles.queue_free()
	else:
		particles.queue_free()

func play_success_sound():
	if correct_sound:
		correct_sound.play()
	print("🔊 Success! Correct answer!")

func play_fail_sound():
	if incorrect_sound:
		incorrect_sound.play()
	print("🔊 Fail! Wrong answer!")

func play_death_animation(player: Node2D):
	if not is_instance_valid(player):
		push_warning("Player node is invalid!")
		return
	
	# Cari AnimatedSprite2D di player
	var animated_sprite = player.get_node_or_null("AnimatedSprite2D")
	
	if animated_sprite and animated_sprite.sprite_frames:
		# Cek apakah animasi "Death_Animation" ada
		if animated_sprite.sprite_frames.has_animation("Death_Animation"):
			print("💀 Playing Death_Animation")
			animated_sprite.play("Death_Animation")
		else:
			print("⚠️ Death_Animation not found, available animations:")
			for anim_name in animated_sprite.sprite_frames.get_animation_names():
				print("  - ", anim_name)
	else:
		push_warning("AnimatedSprite2D not found on player for death animation")

func notify_ghosts_stop_chase():
	# Cari semua ghost di scene
	var tree = get_tree()
	if not tree:
		return
	
	var ghosts = tree.get_nodes_in_group("enemies")
	for ghost in ghosts:
		if is_instance_valid(ghost) and ghost.has_method("force_idle_state"):
			ghost.force_idle_state()
			print("👻 Ghost ", ghost.name, " forced to idle state")

func update_all_finish_answers(quiz_data: Dictionary):
	# Validasi quiz_data
	if not quiz_data.has("answers"):
		push_error("Quiz data missing 'answers' key!")
		return
	
	# Cari semua finish nodes di scene
	var tree = get_tree()
	if not tree:
		push_error("SceneTree not available!")
		return
	
	var maze_node = tree.current_scene
	if not maze_node:
		push_error("Current scene not found!")
		return
	
	# Cari container Textbox
	var textbox = maze_node.get_node_or_null("Textbox")
	if not textbox:
		push_error("Textbox container not found!")
		return
	
	# Update semua finish dengan jawaban baru
	var answers = quiz_data["answers"]
	var finish_nodes = [
		textbox.get_node_or_null("Finish"),
		textbox.get_node_or_null("Finish2"),
		textbox.get_node_or_null("Finish3"),
		textbox.get_node_or_null("Finish4")
	]
	
	for i in range(finish_nodes.size()):
		var finish_node = finish_nodes[i]
		if finish_node and is_instance_valid(finish_node) and finish_node.has_method("set_answer"):
			if i < answers.size():
				finish_node.set_answer(answers[i], i)
				# PENTING: Reset processing flag di node lain juga
				if "is_processing_answer" in finish_node:
					finish_node.is_processing_answer = false
				if "monitoring" in finish_node:
					finish_node.set_deferred("monitoring", true)
				print("🔄 Updated ", finish_node.name, " with answer: ", answers[i])
			else:
				push_error("Not enough answers for finish node ", i)
	
	print("✅ All finish nodes updated with new quiz!")

func _to_string() -> String:
	return "Finish[%s] - Index: %d" % [answer_text, answer_index]
