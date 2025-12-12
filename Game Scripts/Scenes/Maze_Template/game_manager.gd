extends Node

# Audio players
var lose_health_sound: AudioStreamPlayer
var defeat_sound: AudioStreamPlayer
var victory_sound: AudioStreamPlayer

# ==================== QUIZ SYSTEM ====================
# Quiz data
var current_question : String = ""
var current_answers : Array = []
var correct_answer_index : int = -1

# Quiz state
var is_quiz_loaded : bool = false
var is_quiz_answered : bool = false

# API Game Data
var api_game_data : Dictionary = {}
var api_questions_pool : Array = []
var current_question_index : int = 0
var is_using_api_data : bool = false
var total_correct_answers : int = 0
var game_score : int = 0

# ==================== LIVES SYSTEM ====================
@export var max_lives : int = 3
var current_lives : int = 3

# Invincibility untuk prevent spam damage
var is_invincible : bool = false
var invincibility_duration : float = 2.0

# ==================== SIGNALS ====================
signal quiz_data_loaded(question, answers)
signal answer_checked(is_correct)
signal lives_changed(new_lives)
signal game_over_triggered
signal next_question_ready(quiz_data)
signal all_questions_completed

# ==================== READY ====================
func _ready():
	# Initialize audio players
	_setup_audio_players()
	
	# Initialize lives
	current_lives = max_lives
	
	# Reset invincibility state
	is_invincible = false
	
	print("🎮 GameManager initialized")
	print("💚 Lives: ", current_lives, "/", max_lives)

func _setup_audio_players():
	"""Setup all audio players"""
	# Lose Health Sound
	lose_health_sound = AudioStreamPlayer.new()
	lose_health_sound.name = "LoseHealthSound"
	var lose_health_stream = load("res://Assets/Audio/Audio_Lose-Health.mp3")
	if lose_health_stream:
		lose_health_sound.stream = lose_health_stream
	add_child(lose_health_sound)
	
	# Defeat Sound
	defeat_sound = AudioStreamPlayer.new()
	defeat_sound.name = "DefeatSound"
	var defeat_stream = load("res://Assets/Audio/Audio_Defeat.mp3")
	if defeat_stream:
		defeat_sound.stream = defeat_stream
	add_child(defeat_sound)
	
	# Victory Sound
	victory_sound = AudioStreamPlayer.new()
	victory_sound.name = "VictorySound"
	var victory_stream = load("res://Assets/Audio/Audio_Victory.mp3")
	if victory_stream:
		victory_sound.stream = victory_stream
	add_child(victory_sound)
	
	print("🔊 Audio players initialized")

# Detect ketika scene tree berubah (autoload method)
func _notification(what):
	if what == NOTIFICATION_ENTER_TREE:
		_check_and_reset_on_scene_load()

func _check_and_reset_on_scene_load():
	# Tunggu 1 frame agar scene sudah loaded
	await get_tree().process_frame
	
	var current_scene = get_tree().current_scene
	if current_scene:
		var scene_name = current_scene.name
		var scene_path = current_scene.scene_file_path
		
		print("🔄 Current scene: ", scene_name)
		print("📂 Scene path: ", scene_path)
		
		# Reset lives saat masuk ke game scene (Maze)
		if "Maze" in scene_name or "Maze" in scene_path or "Level" in scene_name:
			reset_lives()
			reset_quiz()
			print("✅ Lives reset for new game session")
		
		# Reset lives saat kembali ke Main Menu
		elif "Main_Menu" in scene_name or "Main_Menu" in scene_path or "MainMenu" in scene_name:
			reset_lives()
			reset_quiz()
			print("✅ Lives reset at Main Menu")

# ==================== QUIZ FUNCTIONS ====================
func load_quiz(question: String, answers: Array, correct_index: int):
	current_question = question
	current_answers = answers
	correct_answer_index = correct_index
	is_quiz_loaded = true
	is_quiz_answered = false
	
	print("📝 Quiz loaded: ", question)
	print("✅ Correct answer index: ", correct_index)
	
	# Emit signal
	quiz_data_loaded.emit(question, answers)

func check_answer(answer_index: int) -> bool:
	print("🔍 === CHECK_ANSWER CALLED ===")
	print("🔍 is_quiz_loaded: ", is_quiz_loaded)
	print("🔍 is_quiz_answered: ", is_quiz_answered)
	print("🔍 answer_index: ", answer_index)
	print("🔍 correct_answer_index: ", correct_answer_index)
	
	if not is_quiz_loaded:
		push_error("Quiz not loaded!")
		return false
	
	if is_quiz_answered:
		push_warning("Quiz already answered!")
		print("⚠️ Returning false because quiz was already answered")
		return false
	
	var is_correct = (answer_index == correct_answer_index)
	is_quiz_answered = true
	
	print("🎯 Answer checked: ", answer_index, " | Correct: ", is_correct)
	print("🔍 is_quiz_answered now set to: ", is_quiz_answered)
	
	# Emit signal
	answer_checked.emit(is_correct)
	
	return is_correct

func get_current_question() -> String:
	return current_question

func get_current_answers() -> Array:
	return current_answers

func get_correct_answer_index() -> int:
	return correct_answer_index

func reset_quiz():
	current_question = ""
	current_answers = []
	correct_answer_index = -1
	is_quiz_loaded = false
	is_quiz_answered = false
	
	# Reset API progress
	current_question_index = 0
	total_correct_answers = 0
	game_score = 0
	
	print("🔄 Quiz reset")
	print("📊 Progress reset: 0/", api_questions_pool.size() if not api_questions_pool.is_empty() else 0, " | Score: 0")

# ==================== API QUIZ FUNCTIONS ====================
func load_api_game_data(game_data: Dictionary):
	"""Load game data dari API"""
	api_game_data = game_data
	is_using_api_data = true
	
	# IMPORTANT: Reset progress ketika load game data baru
	current_question_index = 0
	total_correct_answers = 0
	game_score = 0
	
	# Parse questions
	var questions = game_data.get("questions", [])
	api_questions_pool = []
	
	for question_data in questions:
		var question_text = question_data.get("question_text", "")
		var answers_data = question_data.get("answers", [])
		
		# Sort answers by answer_index
		answers_data.sort_custom(func(a, b): return a.get("answer_index", 0) < b.get("answer_index", 0))
		
		# Extract answer texts dan cari yang benar
		var answer_texts = []
		var correct_index = -1
		
		for i in range(answers_data.size()):
			var answer = answers_data[i]
			var answer_text = answer.get("answer_text", "")
			
			# Check if this is the correct answer
			if "(Correct)" in answer_text or "(correct)" in answer_text:
				correct_index = i
				answer_text = answer_text.replace("(Correct)", "").replace("(correct)", "").strip_edges()
			
			answer_texts.append(answer_text)
		
		# Jika tidak ada marker correct, assume index 0
		if correct_index == -1:
			push_warning("⚠️ No correct answer marker for: " + question_text)
			correct_index = 0
		
		api_questions_pool.append({
			"question": question_text,
			"answers": answer_texts,
			"correct": correct_index,
			"original_index": question_data.get("question_index", 0)
		})
	
	# Sort by original question_index
	api_questions_pool.sort_custom(func(a, b): return a.get("original_index", 0) < b.get("original_index", 0))
	
	print("✅ API Game Data loaded!")
	print("📝 Game: ", game_data.get("name", "Unknown"))
	print("📝 Questions: ", api_questions_pool.size())
	print("📝 Score per question: ", game_data.get("score_per_question", 0))
	print("📝 Countdown: ", game_data.get("countdown", 0))

func get_next_api_question() -> Dictionary:
	"""Get next question dari API data secara berurutan"""
	if api_questions_pool.is_empty():
		push_error("❌ No API questions available!")
		return {}
	
	# Get question by current index (loop jika sudah habis)
	var question_data = api_questions_pool[current_question_index % api_questions_pool.size()]
	
	# Increment index untuk next question
	current_question_index += 1
	
	# Shuffle jawaban
	var shuffled_data = shuffle_answers(question_data)
	
	# Load ke current quiz state
	current_question = shuffled_data["question"]
	current_answers = shuffled_data["answers"]
	correct_answer_index = shuffled_data["correct"]
	is_quiz_loaded = true
	is_quiz_answered = false
	
	print("=== API QUESTION LOADED ===")
	print("Question #", current_question_index, ": ", current_question)
	print("Correct answer index: ", correct_answer_index)
	print("===========================")
	
	return shuffled_data

func get_api_game_info() -> Dictionary:
	"""Get informasi game dari API data"""
	return {
		"name": api_game_data.get("name", ""),
		"description": api_game_data.get("description", ""),
		"score_per_question": api_game_data.get("score_per_question", 10),
		"countdown": api_game_data.get("countdown", 10),
		"total_questions": api_questions_pool.size()
	}

func get_total_questions() -> int:
	"""Get total jumlah pertanyaan"""
	return api_questions_pool.size()

func get_current_question_number() -> int:
	"""Get nomor pertanyaan saat ini (1-based)"""
	return current_question_index

func has_more_questions() -> bool:
	"""Check apakah masih ada pertanyaan lagi"""
	return current_question_index < api_questions_pool.size()

func is_all_questions_answered() -> bool:
	"""Check apakah semua pertanyaan sudah dijawab benar"""
	return total_correct_answers >= api_questions_pool.size()

func on_correct_answer():
	"""Called when player answers correctly"""
	total_correct_answers += 1
	
	# Add score
	var score_per_q = api_game_data.get("score_per_question", 10)
	game_score += score_per_q
	
	print("🎯 Correct answers: ", total_correct_answers, "/", api_questions_pool.size())
	print("🏆 Score: ", game_score)
	
	# Check if all questions completed
	if is_all_questions_answered():
		print("🎉 ALL QUESTIONS COMPLETED!")
		# Play victory sound
		if victory_sound:
			victory_sound.play()
		all_questions_completed.emit()
		return true  # Game selesai
	
	return false  # Masih ada pertanyaan lagi

func get_progress_info() -> Dictionary:
	"""Get current progress info"""
	return {
		"current_question": current_question_index,
		"total_questions": api_questions_pool.size(),
		"correct_answers": total_correct_answers,
		"score": game_score
	}

# Generate quiz random dan return data
func generate_random_quiz() -> Dictionary:
	var questions_data = [
		{
			"question": "Apa ibukota Indonesia?",
			"answers": ["Jakarta", "Bandung", "Surabaya", "Medan"],
			"correct": 0
		},
		{
			"question": "Berapa hasil 5 x 8?",
			"answers": ["35", "40", "45", "50"],
			"correct": 1
		},
		{
			"question": "Planet terbesar di tata surya?",
			"answers": ["Mars", "Bumi", "Jupiter", "Saturnus"],
			"correct": 2
		},
		{
			"question": "Siapa presiden pertama Indonesia?",
			"answers": ["Soeharto", "Soekarno", "Habibie", "Megawati"],
			"correct": 1
		},
		{
			"question": "Berapa jumlah provinsi di Indonesia?",
			"answers": ["32", "34", "36", "38"],
			"correct": 3
		},
		{
			"question": "Kenapa Dimas Ganteng Banget?",
			"answers": ["Rajin skinkeran", "Rajin mandi ,bersedekah, dan sholat", "Terlalu Jago", "Pro player anjay mabar"],
			"correct": 1
		}
	]
	
	# Pilih pertanyaan random
	var random_quiz = questions_data[randi() % questions_data.size()]
	
	# Shuffle jawaban
	var shuffled_data = shuffle_answers(random_quiz)
	
	# Simpan data quiz saat ini
	current_question = shuffled_data["question"]
	current_answers = shuffled_data["answers"]
	correct_answer_index = shuffled_data["correct"]
	is_quiz_loaded = true
	is_quiz_answered = false  # PENTING: Reset agar bisa dijawab lagi
	
	print("=== NEW QUIZ GENERATED ===")
	print("Question: ", current_question)
	print("Correct answer index: ", correct_answer_index)
	print("Answers: ", current_answers)
	print("is_quiz_answered reset to: ", is_quiz_answered)
	print("========================")
	
	return shuffled_data

func shuffle_answers(quiz_data: Dictionary) -> Dictionary:
	var answers = quiz_data["answers"].duplicate()
	var correct_answer = answers[quiz_data["correct"]]
	
	# Shuffle array
	answers.shuffle()
	
	# Find new index of correct answer
	var new_correct_idx = answers.find(correct_answer)
	
	return {
		"question": quiz_data["question"],
		"answers": answers,
		"correct": new_correct_idx
	}

# Reshuffle jawaban SAJA tanpa ganti pertanyaan
func reshuffle_current_quiz() -> Dictionary:
	if not is_quiz_loaded:
		push_error("No quiz loaded to reshuffle!")
		return {}
	
	# Ambil jawaban yang benar (text-nya)
	var correct_answer_text = current_answers[correct_answer_index]
	
	# Shuffle jawaban
	current_answers.shuffle()
	
	# Cari index baru dari jawaban yang benar
	correct_answer_index = current_answers.find(correct_answer_text)
	
	# Reset is_quiz_answered agar bisa dijawab lagi
	is_quiz_answered = false
	
	print("=== QUIZ RESHUFFLED (Same Question) ===")
	print("Question: ", current_question)
	print("New correct answer index: ", correct_answer_index)
	print("Reshuffled answers: ", current_answers)
	print("is_quiz_answered reset to: ", is_quiz_answered)
	print("=======================================")
	
	return {
		"question": current_question,
		"answers": current_answers,
		"correct": correct_answer_index
	}

# ==================== LIVES FUNCTIONS ====================
func lose_life():
	print("💔 === LOSE_LIFE CALLED ===")
	print("💔 Is invincible: ", is_invincible)
	print("💔 Current lives before: ", current_lives)
	
	if is_invincible:
		print("🛡️ Player is invincible, no damage taken")
		return current_lives
	
	if current_lives > 0:
		current_lives -= 1
		print("💔 Life lost! Lives remaining: ", current_lives, "/", max_lives)
		
		# Play lose health sound
		if lose_health_sound:
			lose_health_sound.play()
		
		print("💔 Emitting lives_changed signal with value: ", current_lives)
		
		# Emit signal
		lives_changed.emit(current_lives)
		print("💔 Signal emitted successfully")
		
		# Activate invincibility
		activate_invincibility()
		
		# Check game over
		if current_lives <= 0:
			trigger_game_over()
	
	return current_lives

func gain_life():
	if current_lives < max_lives:
		current_lives += 1
		print("💚 Life gained! Lives: ", current_lives, "/", max_lives)
		
		# Emit signal
		lives_changed.emit(current_lives)
	else:
		print("💚 Lives already at maximum!")

func reset_lives():
	current_lives = max_lives
	is_invincible = false
	print("🔄 Lives reset to: ", current_lives, "/", max_lives)
	
	# Emit signal
	lives_changed.emit(current_lives)

func get_lives() -> int:
	return current_lives

func get_max_lives() -> int:
	return max_lives

func set_max_lives(new_max: int):
	max_lives = new_max
	if current_lives > max_lives:
		current_lives = max_lives

# ==================== INVINCIBILITY ====================
func activate_invincibility():
	is_invincible = true
	print("🛡️ Invincibility activated for ", invincibility_duration, " seconds")
	
	# Timer untuk deactivate
	var tree = get_tree()
	if tree:
		await tree.create_timer(invincibility_duration).timeout
		is_invincible = false
		print("🛡️ Invincibility ended")
	else:
		# Fallback jika tree null
		is_invincible = false
		push_warning("SceneTree not available for invincibility timer")

func set_invincibility_duration(duration: float):
	invincibility_duration = duration

func get_is_invincible() -> bool:
	return is_invincible

# ==================== GAME OVER ====================
func trigger_game_over():
	print("☠️ GAME OVER!")
	
	# IMPORTANT: Reset quiz progress before game over
	reset_quiz()
	
	# Go to Game Over scene immediately (sound will play there)
	get_tree().change_scene_to_file("res://Game Scenes/Scenes/Game_Over.tscn")
	
	# Emit signal for compatibility
	game_over_triggered.emit()

func show_game_over_message():
	# Create game over label
	var game_over_label = Label.new()
	game_over_label.text = "GAME OVER"
	
	# Load Pixelify Sans font
	if ResourceLoader.exists("res://Assets/Fonts/PIXELIFYSANS-VARIABLEFONT_WGHT.TTF"):
		var pixelify_font = load("res://Assets/Fonts/PIXELIFYSANS-VARIABLEFONT_WGHT.TTF")
		if pixelify_font:
			game_over_label.add_theme_font_override("font", pixelify_font)
	
	game_over_label.add_theme_font_size_override("font_size", 72)
	game_over_label.add_theme_color_override("font_color", Color.RED)
	game_over_label.add_theme_color_override("font_outline_color", Color.BLACK)
	game_over_label.add_theme_constant_override("outline_size", 8)
	
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Position at center of screen (assuming 1152x648 screen size)
	game_over_label.position = Vector2(576 - 300, 324 - 50)
	game_over_label.size = Vector2(600, 100)
	game_over_label.z_index = 1000
	
	# Add to scene tree
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(game_over_label)
	
	# Animation
	game_over_label.modulate.a = 0
	game_over_label.scale = Vector2.ZERO
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(game_over_label, "modulate:a", 1.0, 0.5)
	tween.tween_property(game_over_label, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func restart_level():
	print("🔄 Restarting level...")
	# Reset semua state sebelum reload
	reset_lives()
	reset_quiz()
	is_invincible = false
	get_tree().reload_current_scene()

func go_to_main_menu():
	print("🏠 Going to main menu...")
	# Reset semua state sebelum ke main menu
	reset_lives()
	reset_quiz()
	is_invincible = false
	get_tree().change_scene_to_file("res://Game Scenes/Main_Menu/Main_Menu.tscn")

# Fungsi untuk dipanggil manual dari scene lain
func start_new_game():
	print("🎮 Starting new game...")
	reset_lives()
	reset_quiz()
	is_invincible = false
	print("✅ Game state reset complete")

# Fungsi untuk load game scene dengan auto-reset
func load_game_scene(scene_path: String):
	print("🎮 Loading game scene: ", scene_path)
	reset_lives()
	reset_quiz()
	is_invincible = false
	get_tree().change_scene_to_file(scene_path)

# ==================== DEBUG ====================
func _input(event):
	# Debug keys (hanya di debug build)
	if OS.is_debug_build():
		if event.is_action_pressed("ui_page_up"):
			gain_life()
		elif event.is_action_pressed("ui_page_down"):
			lose_life()
		elif event.is_action_pressed("ui_home"):
			reset_lives()

func print_status():
	print("================== GAME MANAGER STATUS ==================")
	print("Lives: ", current_lives, "/", max_lives)
	print("Invincible: ", is_invincible)
	print("Quiz Loaded: ", is_quiz_loaded)
	print("Quiz Answered: ", is_quiz_answered)
	print("Current Question: ", current_question)
	print("Correct Answer Index: ", correct_answer_index)
	print("=========================================================")

# ==================== HELPER FUNCTIONS ====================
func check_quiz_loaded() -> bool:
	return is_quiz_loaded

func check_quiz_answered() -> bool:
	return is_quiz_answered

func get_quiz_state() -> Dictionary:
	return {
		"loaded": is_quiz_loaded,
		"answered": is_quiz_answered,
		"question": current_question,
		"answers": current_answers,
		"correct_index": correct_answer_index
	}

func get_lives_state() -> Dictionary:
	return {
		"current": current_lives,
		"max": max_lives,
		"invincible": is_invincible
	}
