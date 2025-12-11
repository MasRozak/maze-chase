extends Node

@onready var finish1 = $Textbox/Finish
@onready var finish2 = $Textbox/Finish2
@onready var finish3 = $Textbox/Finish3
@onready var finish4 = $Textbox/Finish4

# Lives UI - menggunakan UI yang sudah ada di scene
@onready var hearts_container = $UI/Hearths/HBoxContainer if has_node("UI/Hearths/HBoxContainer") else null
var heart_nodes : Array = []

# API Service
var api_service : Node = null
var game_id : String = "b2d7d178-53c0-45de-be43-7478e26d9705"  # Ganti dengan game ID yang sesuai

# Loading state
var is_loading : bool = false
var loading_label : Label = null

func _ready():
	# Delay sedikit untuk memastikan semua node ready
	await get_tree().process_frame
	
	# IMPORTANT: Reset EVERYTHING ketika scene dimuat (fresh start)
	if GameManager:
		# Reset quiz progress BEFORE loading new data
		GameManager.reset_quiz()
		GameManager.reset_lives()
		print("🔄 GameManager reset: Lives and Quiz progress cleared")
		print("💚 Lives reset to max when entering maze")
	
	# Setup Lives UI dengan UI yang sudah ada
	setup_existing_lives_ui()
	
	# Connect to GameManager signal
	if GameManager:
		if not GameManager.lives_changed.is_connected(_on_lives_changed):
			GameManager.lives_changed.connect(_on_lives_changed)
		print("💚 Lives UI connected to GameManager")

	# Disable debug hints untuk Web export
	if OS.has_feature("web"):
		get_tree().debug_collisions_hint = false
		get_tree().debug_navigation_hint = false
	
	# Setup API Service
	setup_api_service()
	
	# Fetch game data dari API
	fetch_game_data_from_api()

func setup_api_service():
	"""Initialize API service"""
	var api_script = load("res://Game Scripts/Scenes/Maze_Template/api_service.gd")
	api_service = api_script.new()
	add_child(api_service)
	
	# Connect signals
	api_service.game_data_loaded.connect(_on_game_data_loaded)
	api_service.game_data_error.connect(_on_game_data_error)
	
	print("🌐 API Service initialized")

func fetch_game_data_from_api():
	"""Fetch game data dari API"""
	is_loading = true
	show_loading_indicator()
	
	print("🌐 Fetching game data for ID: ", game_id)
	api_service.fetch_game_data(game_id)

func _on_game_data_loaded(game_data: Dictionary):
	"""Callback ketika game data berhasil dimuat dari API"""
	print("✅ Game data loaded from API!")
	is_loading = false
	hide_loading_indicator()
	
	# IMPORTANT: Load data ke GameManager (ini akan auto-reset progress)
	GameManager.load_api_game_data(game_data)
	
	# Verify reset berhasil
	var progress = GameManager.get_progress_info()
	print("📊 Initial Progress after load: Question ", progress["current_question"], "/", progress["total_questions"], " | Score: ", progress["score"])
	
	# Connect signal untuk all questions completed
	if not GameManager.all_questions_completed.is_connected(_on_all_questions_completed):
		GameManager.all_questions_completed.connect(_on_all_questions_completed)
	
	# Setup quiz pertama
	setup_new_quiz_from_api()

func _on_all_questions_completed():
	"""Callback ketika semua pertanyaan sudah dijawab benar"""
	print("🎉🎉🎉 CONGRATULATIONS! ALL QUESTIONS COMPLETED! 🎉🎉🎉")
	
	# Show completion screen
	show_completion_screen()

func show_completion_screen():
	"""Show layar selesai dengan score final"""
	await get_tree().process_frame
	
	var progress = GameManager.get_progress_info()
	
	# Create completion overlay
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 250
	canvas_layer.name = "CompletionLayer"
	add_child(canvas_layer)
	
	# Background overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(overlay)
	
	# Completion panel
	var panel = Panel.new()
	panel.position = Vector2(276, 124)
	panel.custom_minimum_size = Vector2(600, 400)
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.15, 0.1, 0.98)
	style_box.set_border_width_all(4)
	style_box.border_color = Color(0.3, 0.8, 0.3, 1.0)
	style_box.set_corner_radius_all(16)
	panel.add_theme_stylebox_override("panel", style_box)
	
	canvas_layer.add_child(panel)
	
	# VBoxContainer for content
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 30
	vbox.offset_top = 30
	vbox.offset_right = -30
	vbox.offset_bottom = -30
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	# Load font
	var font = null
	var font_path = "res://Assets/Fonts/PIXELIFYSANS-VARIABLEFONT_WGHT.TTF"
	if ResourceLoader.exists(font_path):
		font = ResourceLoader.load(font_path, "Font")
	
	# Title label
	var title_label = Label.new()
	title_label.text = "🎉 SELAMAT! 🎉"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font:
		title_label.add_theme_font_override("font", font)
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	vbox.add_child(title_label)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Semua Pertanyaan Terjawab!"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font:
		subtitle.add_theme_font_override("font", font)
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color(0.9, 0.9, 0.8, 1.0))
	vbox.add_child(subtitle)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	# Score info
	var score_label = Label.new()
	score_label.text = "Total Score: %d" % progress["score"]
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font:
		score_label.add_theme_font_override("font", font)
	score_label.add_theme_font_size_override("font_size", 36)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
	vbox.add_child(score_label)
	
	# Questions info
	var questions_label = Label.new()
	questions_label.text = "Jawaban Benar: %d / %d" % [progress["correct_answers"], progress["total_questions"]]
	questions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font:
		questions_label.add_theme_font_override("font", font)
	questions_label.add_theme_font_size_override("font_size", 20)
	questions_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9, 1.0))
	vbox.add_child(questions_label)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer2)
	
	# Button container
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 30)
	vbox.add_child(button_container)
	
	# Main Menu button
	var menu_button = Button.new()
	menu_button.text = "Main Menu"
	menu_button.custom_minimum_size = Vector2(150, 50)
	if font:
		menu_button.add_theme_font_override("font", font)
	menu_button.add_theme_font_size_override("font_size", 18)
	menu_button.pressed.connect(_on_menu_button_pressed)
	button_container.add_child(menu_button)
	
	# Play Again button
	var play_button = Button.new()
	play_button.text = "Main Lagi"
	play_button.custom_minimum_size = Vector2(150, 50)
	if font:
		play_button.add_theme_font_override("font", font)
	play_button.add_theme_font_size_override("font_size", 18)
	play_button.pressed.connect(_on_play_again_pressed)
	button_container.add_child(play_button)
	
	# Animation
	panel.modulate.a = 0
	panel.scale = Vector2(0.5, 0.5)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.5)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _on_menu_button_pressed():
	"""Handle klik tombol Main Menu"""
	GameManager.reset_quiz()
	get_tree().change_scene_to_file("res://Game Scenes/Main_Menu/Main_Menu.tscn")

func _on_play_again_pressed():
	"""Handle klik tombol Main Lagi"""
	print("🔄 Play Again pressed - Resetting everything...")
	
	# Reset semua progress
	GameManager.reset_quiz()
	GameManager.reset_lives()
	
	# Reload scene
	get_tree().reload_current_scene()

func _on_game_data_error(error_message: String):
	"""Callback ketika ada error saat fetch API"""
	push_error("❌ API Error: " + error_message)
	is_loading = false
	hide_loading_indicator()
	
	# Show error message to user
	show_error_message(error_message)
	
	# Fallback ke static questions
	print("⚠️ Falling back to static questions...")
	setup_new_quiz()

func setup_new_quiz_from_api():
	"""Setup quiz dari API data"""
	# CRITICAL: Tunggu 2 frames untuk memastikan semua finish._ready() selesai
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Get next question dari API
	var quiz_data = GameManager.get_next_api_question()
	
	if quiz_data.is_empty():
		push_error("❌ No quiz data from API!")
		# Fallback ke static
		setup_new_quiz()
		return
	
	# Validasi finish nodes
	if not validate_finish_nodes():
		push_error("Finish nodes tidak ditemukan!")
		return
	
	# Assign jawaban ke setiap finish
	var answers = quiz_data["answers"]
	
	print("📝 Setting answers to finish nodes...")
	finish1.set_answer(answers[0], 0)
	finish2.set_answer(answers[1], 1)
	finish3.set_answer(answers[2], 2)
	finish4.set_answer(answers[3], 3)
	
	# Tampilkan pertanyaan
	display_question(quiz_data["question"])
	
	# Update progress UI
	update_progress_display()
	
	print("✅ Quiz setup complete (from API)!")
	print("A: ", answers[0])
	print("B: ", answers[1])
	print("C: ", answers[2])
	print("D: ", answers[3])

func load_next_question_from_api():
	"""Load pertanyaan selanjutnya dari API (dipanggil dari finish.gd)"""
	print("🔄 Loading next question from API...")
	
	# Remove old question panel
	remove_question_panel()
	
	# Wait sebentar
	await get_tree().process_frame
	
	# Check apakah masih ada pertanyaan
	if not GameManager.has_more_questions():
		print("🎉 No more questions! Game completed!")
		return
	
	# Get next question
	var quiz_data = GameManager.get_next_api_question()
	
	if quiz_data.is_empty():
		push_error("❌ No quiz data from API!")
		return
	
	# Validasi finish nodes
	if not validate_finish_nodes():
		push_error("Finish nodes tidak ditemukan!")
		return
	
	# Reset semua finish nodes monitoring
	reset_all_finish_nodes()
	
	# Assign jawaban baru ke setiap finish
	var answers = quiz_data["answers"]
	
	print("📝 Setting NEW answers to finish nodes...")
	finish1.set_answer(answers[0], 0)
	finish2.set_answer(answers[1], 1)
	finish3.set_answer(answers[2], 2)
	finish4.set_answer(answers[3], 3)
	
	# Tampilkan pertanyaan baru
	display_question(quiz_data["question"])
	
	# Update progress UI
	update_progress_display()
	
	var progress = GameManager.get_progress_info()
	print("✅ Next question loaded!")
	print("📊 Progress: Question ", progress["current_question"], "/", progress["total_questions"])
	print("🏆 Score: ", progress["score"])

func reset_all_finish_nodes():
	"""Reset semua finish nodes untuk menerima answer baru"""
	var finish_nodes = [finish1, finish2, finish3, finish4]
	for node in finish_nodes:
		if node and node.has_method("reset_for_new_question"):
			node.reset_for_new_question()
		elif node:
			# Manual reset jika method tidak ada
			if "is_processing_answer" in node:
				node.is_processing_answer = false
			node.set_deferred("monitoring", true)
	print("🔄 All finish nodes reset for new question")

func remove_question_panel():
	"""Remove existing question panel"""
	var question_layer = get_node_or_null("QuestionLayer")
	if question_layer:
		question_layer.queue_free()
		print("🗑️ Old question panel removed")

func update_progress_display():
	"""Update UI untuk menampilkan progress"""
	var progress = GameManager.get_progress_info()
	
	# Debug log untuk verify progress
	print("📊 Updating progress display: ", progress["current_question"], "/", progress["total_questions"], " | Score: ", progress["score"])
	
	# Check jika progress display sudah ada
	var progress_layer = get_node_or_null("ProgressLayer")
	if progress_layer:
		progress_layer.queue_free()
	
	# Create new progress display
	await get_tree().process_frame
	
	progress_layer = CanvasLayer.new()
	progress_layer.layer = 98
	progress_layer.name = "ProgressLayer"
	add_child(progress_layer)
	
	# Progress panel
	var progress_panel = Panel.new()
	progress_panel.position = Vector2(10, 10)
	progress_panel.custom_minimum_size = Vector2(200, 60)
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	style_box.set_border_width_all(2)
	style_box.border_color = Color(0.4, 0.35, 0.5, 0.9)
	style_box.set_corner_radius_all(8)
	progress_panel.add_theme_stylebox_override("panel", style_box)
	
	progress_layer.add_child(progress_panel)
	
	# Progress label
	var progress_label = Label.new()
	progress_label.text = "Question: %d/%d\nScore: %d" % [
		progress["current_question"],
		progress["total_questions"],
		progress["score"]
	]
	
	# Load font
	var font_path = "res://Assets/Fonts/PIXELIFYSANS-VARIABLEFONT_WGHT.TTF"
	if ResourceLoader.exists(font_path):
		var font = ResourceLoader.load(font_path, "Font")
		if font:
			progress_label.add_theme_font_override("font", font)
	
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75, 1.0))
	progress_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	progress_label.offset_left = 10
	progress_label.offset_top = 8
	progress_label.offset_right = -10
	progress_label.offset_bottom = -8
	
	progress_panel.add_child(progress_label)
	
	print("📊 Progress display updated: ", progress["current_question"], "/", progress["total_questions"])

func setup_new_quiz():
	"""Setup quiz dari static data (fallback)"""
	# CRITICAL: Tunggu 2 frames untuk memastikan semua finish._ready() selesai
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Generate quiz dari GameManager (static)
	var quiz_data = GameManager.generate_random_quiz()
	
	# Validasi finish nodes
	if not validate_finish_nodes():
		push_error("Finish nodes tidak ditemukan!")
		return
	
	# Assign jawaban ke setiap finish
	var answers = quiz_data["answers"]
	
	print("📝 Setting answers to finish nodes...")
	finish1.set_answer(answers[0], 0)
	finish2.set_answer(answers[1], 1)
	finish3.set_answer(answers[2], 2)
	finish4.set_answer(answers[3], 3)
	
	# Tampilkan pertanyaan (optional - buat UI)
	display_question(quiz_data["question"])
	
	print("✅ Quiz setup complete (static)!")
	print("A: ", answers[0])
	print("B: ", answers[1])
	print("C: ", answers[2])
	print("D: ", answers[3])

func validate_finish_nodes() -> bool:
	var all_valid = true
	
	if not finish1:
		push_error("Finish1 not found at: Textbox/Finish")
		all_valid = false
	else:
		print("✅ Finish1 found")
	
	if not finish2:
		push_error("Finish2 not found at: Textbox/Finish2")
		all_valid = false
	else:
		print("✅ Finish2 found")
	
	if not finish3:
		push_error("Finish3 not found at: Textbox/Finish3")
		all_valid = false
	else:
		print("✅ Finish3 found")
	
	if not finish4:
		push_error("Finish4 not found at: Textbox/Finish4")
		all_valid = false
	else:
		print("✅ Finish4 found")
	
	return all_valid

func display_question(question: String):
	# Print ke console untuk debugging
	print("📝 PERTANYAAN: ", question)
	
	# CRITICAL FIX: Gunakan deferred untuk memastikan scene sudah ready
	await get_tree().process_frame
	
	# Buat CanvasLayer untuk question (UI layer)
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 99
	canvas_layer.name = "QuestionLayer"
	add_child(canvas_layer)
	
	# Buat panel background untuk question
	var question_panel = Panel.new()
	question_panel.position = Vector2(276, 30)  # Center horizontal (1152/2 - 300)
	question_panel.custom_minimum_size = Vector2(600, 80)
	
	# Style panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.1, 0.2, 0.92)  # Dark purple
	style_box.set_border_width_all(3)
	style_box.border_color = Color(0.5, 0.4, 0.6, 1.0)
	style_box.set_corner_radius_all(12)
	question_panel.add_theme_stylebox_override("panel", style_box)
	
	canvas_layer.add_child(question_panel)
	
	# Buat label untuk question
	var label = Label.new()
	label.text = question
	
	# Load Pixelify Sans font - PRELOAD untuk HTML5
	var font_path = "res://Assets/Fonts/PIXELIFYSANS-VARIABLEFONT_WGHT.TTF"
	if ResourceLoader.exists(font_path):
		var pixelify_font = ResourceLoader.load(font_path, "Font")
		if pixelify_font:
			label.add_theme_font_override("font", pixelify_font)
			print("✅ Question font loaded successfully")
		else:
			print("⚠️ Font exists but failed to load for question")
	else:
		print("⚠️ Font not found, using default for question")
	
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8, 1.0))  # Warm light
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.15, 1.0))
	label.add_theme_constant_override("outline_size", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# CRITICAL: Gunakan anchors untuk HTML5 compatibility
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 15
	label.offset_top = 10
	label.offset_right = -15
	label.offset_bottom = -10
	
	# Enable autowrap untuk long questions
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	question_panel.add_child(label)
	
	print("✅ Question panel created and added to CanvasLayer")
	
	# Animasi muncul
	question_panel.modulate.a = 0
	question_panel.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(question_panel, "modulate:a", 1.0, 0.4)
	tween.tween_property(question_panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func setup_existing_lives_ui():
	# Gunakan UI hearts yang sudah ada di scene
	if not hearts_container:
		push_error("Hearts container not found at UI/Hearths/HBoxContainer!")
		# Coba cari manual
		var ui_node = get_node_or_null("UI")
		if ui_node:
			var hearths_node = ui_node.get_node_or_null("Hearths")
			if hearths_node:
				hearts_container = hearths_node.get_node_or_null("HBoxContainer")
				print("💚 Found hearts_container manually")
		
		if not hearts_container:
			push_error("Still cannot find hearts container!")
			return
	
	print("💚 Hearts container found: ", hearts_container)
	
	# Ambil semua heart TextureRect dari container
	heart_nodes.clear()
	for child in hearts_container.get_children():
		print("💚 Found child: ", child.name, " type: ", child.get_class())
		if child is TextureRect:
			heart_nodes.append(child)
			print("💚 Added heart: ", child.name)
	
	print("💚 Total hearts found: ", heart_nodes.size())
	
	# Update display awal
	if GameManager:
		var current_lives = GameManager.get_lives()
		print("💚 Initial lives from GameManager: ", current_lives)
		update_lives_display(current_lives)
	else:
		print("⚠️ GameManager not found!")
		update_lives_display(3)

func update_lives_display(current_lives: int):
	print("💚 === UPDATE LIVES DISPLAY ===")
	print("💚 Current lives: ", current_lives)
	print("💚 Total hearts: ", heart_nodes.size())
	
	if heart_nodes.size() == 0:
		push_error("No hearts found! Cannot update display.")
		return
	
	# Update visibility/modulate of hearts
	for i in range(heart_nodes.size()):
		print("💚 Updating heart ", i, " - should be visible: ", (i < current_lives))
		if i < current_lives:
			# Heart masih ada (visible dengan warna penuh)
			heart_nodes[i].modulate = Color(1, 1, 1, 1.0)
			heart_nodes[i].scale = Vector2.ONE
			print("💚 Heart ", i, " set to VISIBLE")
		else:
			# Heart hilang (sangat transparan)
			heart_nodes[i].modulate = Color(0.3, 0.3, 0.3, 0.3)
			print("💚 Heart ", i, " set to TRANSPARENT")
			
			# Animasi hilang sekali saja
			if heart_nodes[i].scale == Vector2.ONE:
				var tween = create_tween()
				tween.tween_property(heart_nodes[i], "scale", Vector2(1.3, 1.3), 0.15)
				tween.tween_property(heart_nodes[i], "scale", Vector2(0.8, 0.8), 0.15)
	
	print("💚 === UPDATE COMPLETE ===")

func _on_lives_changed(new_lives: int):
	print("💔 Lives changed signal received: ", new_lives)
	update_lives_display(new_lives)
	
	# Flash effect pada hearts container
	if hearts_container:
		var parent_panel = hearts_container.get_parent()
		if parent_panel:
			var tween = create_tween()
			tween.tween_property(parent_panel, "modulate", Color.RED, 0.1)
			tween.tween_property(parent_panel, "modulate", Color.WHITE, 0.1)
			tween.tween_property(parent_panel, "modulate", Color.RED, 0.1)
			tween.tween_property(parent_panel, "modulate", Color.WHITE, 0.1)

# ==================== LOADING INDICATOR ====================
func show_loading_indicator():
	"""Show loading indicator saat fetch API"""
	await get_tree().process_frame
	
	# Create CanvasLayer untuk loading UI
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 200
	canvas_layer.name = "LoadingLayer"
	add_child(canvas_layer)
	
	# Background overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(overlay)
	
	# Loading panel
	var panel = Panel.new()
	panel.position = Vector2(426, 274)  # Center
	panel.custom_minimum_size = Vector2(300, 100)
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.1, 0.2, 0.95)
	style_box.set_border_width_all(3)
	style_box.border_color = Color(0.5, 0.4, 0.6, 1.0)
	style_box.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style_box)
	
	canvas_layer.add_child(panel)
	
	# Loading label
	loading_label = Label.new()
	loading_label.text = "Loading game data..."
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Load font
	var font_path = "res://Assets/Fonts/PIXELIFYSANS-VARIABLEFONT_WGHT.TTF"
	if ResourceLoader.exists(font_path):
		var font = ResourceLoader.load(font_path, "Font")
		if font:
			loading_label.add_theme_font_override("font", font)
	
	loading_label.add_theme_font_size_override("font_size", 20)
	loading_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8, 1.0))
	loading_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_label.offset_left = 10
	loading_label.offset_top = 10
	loading_label.offset_right = -10
	loading_label.offset_bottom = -10
	
	panel.add_child(loading_label)
	
	# Animasi loading
	var tween = create_tween().set_loops()
	tween.tween_property(panel, "modulate:a", 0.6, 0.8)
	tween.tween_property(panel, "modulate:a", 1.0, 0.8)

func hide_loading_indicator():
	"""Hide loading indicator"""
	var loading_layer = get_node_or_null("LoadingLayer")
	if loading_layer:
		loading_layer.queue_free()

func show_error_message(error_text: String):
	"""Show error message ke user"""
	await get_tree().process_frame
	
	# Create CanvasLayer
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 200
	canvas_layer.name = "ErrorLayer"
	add_child(canvas_layer)
	
	# Background overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(overlay)
	
	# Error panel
	var panel = Panel.new()
	panel.position = Vector2(326, 224)  # Center
	panel.custom_minimum_size = Vector2(500, 200)
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.3, 0.1, 0.1, 0.95)
	style_box.set_border_width_all(3)
	style_box.border_color = Color(0.8, 0.2, 0.2, 1.0)
	style_box.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style_box)
	
	canvas_layer.add_child(panel)
	
	# Error label
	var error_label = Label.new()
	error_label.text = "❌ Error loading game data:\n\n" + error_text + "\n\nUsing fallback questions..."
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Load font
	var font_path = "res://Assets/Fonts/PIXELIFYSANS-VARIABLEFONT_WGHT.TTF"
	if ResourceLoader.exists(font_path):
		var font = ResourceLoader.load(font_path, "Font")
		if font:
			error_label.add_theme_font_override("font", font)
	
	error_label.add_theme_font_size_override("font_size", 18)
	error_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.8, 1.0))
	error_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	error_label.offset_left = 20
	error_label.offset_top = 20
	error_label.offset_right = -20
	error_label.offset_bottom = -20
	
	panel.add_child(error_label)
	
	# Auto close setelah 5 detik
	await get_tree().create_timer(5.0).timeout
	canvas_layer.queue_free()
