extends Node

# ==================== API CONFIGURATION ====================
# IMPORTANT: Ganti dengan URL API kamu
const BASE_URL = "http://localhost:4000"  # Ganti dengan domain API kamu
const API_ENDPOINT = "/api/game/game-type/maze-chase/%s/play/public"

# ==================== SIGNALS ====================
signal game_data_loaded(game_data)
signal game_data_error(error_message)

# ==================== HTTP CLIENT ====================
var http_request: HTTPRequest = null

func _ready():
	# Create HTTP Request node
	http_request = HTTPRequest.new()
	add_child(http_request)
	
	# Connect signal untuk response
	if not http_request.request_completed.is_connected(_on_request_completed):
		http_request.request_completed.connect(_on_request_completed)
	
	print("🌐 API Service initialized")

# ==================== FETCH GAME DATA ====================
func fetch_game_data(game_id: String):
	if game_id.is_empty():
		push_error("❌ Game ID is empty!")
		game_data_error.emit("Game ID tidak boleh kosong")
		return
	
	# Build URL
	var url = BASE_URL + (API_ENDPOINT % game_id)
	
	print("🌐 Fetching game data from: ", url)
	
	# Konfigurasi headers (jika diperlukan)
	var headers = [
		"Content-Type: application/json",
		"Accept: application/json"
	]
	
	# Jika API memerlukan authentication token, tambahkan di sini:
	# headers.append("Authorization: Bearer YOUR_TOKEN")
	
	# Make GET request
	var error = http_request.request(url, headers, HTTPClient.METHOD_GET)
	
	if error != OK:
		push_error("❌ HTTP Request error: ", error)
		game_data_error.emit("Gagal membuat request ke server")

# ==================== HANDLE RESPONSE ====================
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print("📡 Request completed with code: ", response_code)
	
	# Check if request was successful
	if result != HTTPRequest.RESULT_SUCCESS:
		var error_msg = "Request gagal dengan result code: " + str(result)
		push_error("❌ " + error_msg)
		game_data_error.emit(error_msg)
		return
	
	# Check HTTP response code
	if response_code != 200:
		var error_msg = "HTTP error " + str(response_code)
		push_error("❌ " + error_msg)
		game_data_error.emit(error_msg)
		return
	
	# Parse JSON response
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		var error_msg = "Gagal parsing JSON response"
		push_error("❌ " + error_msg)
		game_data_error.emit(error_msg)
		return
	
	var response = json.data
	
	# Validate response structure
	if not response.has("success") or not response["success"]:
		var error_msg = "API response tidak success"
		push_error("❌ " + error_msg)
		game_data_error.emit(error_msg)
		return
	
	if not response.has("data"):
		var error_msg = "API response tidak memiliki data"
		push_error("❌ " + error_msg)
		game_data_error.emit(error_msg)
		return
	
	# Extract game data
	var game_data = response["data"]
	
	print("✅ Game data loaded successfully!")
	print("📝 Game name: ", game_data.get("name", "Unknown"))
	print("📝 Questions count: ", game_data.get("questions", []).size())
	
	# Emit signal dengan game data
	game_data_loaded.emit(game_data)

# ==================== PARSE QUESTIONS ====================
# Parse questions dari API response ke format yang digunakan GameManager
func parse_questions_to_quiz_format(api_game_data: Dictionary) -> Array:
	var questions = api_game_data.get("questions", [])
	var formatted_questions = []
	
	for question_data in questions:
		var question_text = question_data.get("question_text", "")
		var answers_data = question_data.get("answers", [])
		
		# Sort answers by answer_index
		answers_data.sort_custom(func(a, b): return a.get("answer_index", 0) < b.get("answer_index", 0))
		
		# Extract answer texts
		var answer_texts = []
		var correct_index = -1
		
		for i in range(answers_data.size()):
			var answer = answers_data[i]
			var answer_text = answer.get("answer_text", "")
			answer_texts.append(answer_text)
			
			# Check if this is the correct answer (contains "Correct" in text)
			if "(Correct)" in answer_text or "(correct)" in answer_text:
				correct_index = i
				# Remove the "(Correct)" marker dari text
				answer_texts[i] = answer_text.replace("(Correct)", "").replace("(correct)", "").strip_edges()
		
		# Jika tidak ada marker "(Correct)", assume answer_index 0 adalah yang benar
		if correct_index == -1:
			push_warning("⚠️ No correct answer marker found for question: " + question_text)
			correct_index = 0
		
		formatted_questions.append({
			"question": question_text,
			"answers": answer_texts,
			"correct": correct_index
		})
	
	print("✅ Parsed ", formatted_questions.size(), " questions from API")
	return formatted_questions
