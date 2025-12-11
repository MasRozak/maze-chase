# 🧪 Testing API Integration

## Quick Start Testing

### 1. Test dengan Mock API (Tanpa Server)

Jika belum ada backend server, bisa test dengan mock data dulu:

Edit `maze_part_final.gd`, tambahkan fungsi test ini:

```gdscript
func test_with_mock_data():
    """Test dengan mock data tanpa API call"""
    var mock_game_data = {
        "id": "test-123",
        "name": "Test Game",
        "description": "Testing game",
        "score_per_question": 10,
        "countdown": 10,
        "questions": [
            {
                "question_text": "Test Question 1?",
                "question_index": 0,
                "answers": [
                    {"answer_text": "Answer A (Correct)", "answer_index": 0},
                    {"answer_text": "Answer B", "answer_index": 1},
                    {"answer_text": "Answer C", "answer_index": 2},
                    {"answer_text": "Answer D", "answer_index": 3}
                ]
            }
        ]
    }
    
    # Load mock data
    GameManager.load_api_game_data(mock_game_data)
    setup_new_quiz_from_api()
```

Panggil fungsi ini di `_ready()` untuk test tanpa API.

### 2. Test dengan JSON Server (Simple Mock API)

Install json-server untuk quick testing:

```bash
npm install -g json-server
```

Buat file `db.json`:

```json
{
  "game": {
    "success": true,
    "statusCode": 200,
    "data": {
      "id": "test-game",
      "name": "Test Game",
      "description": "Testing",
      "score_per_question": 10,
      "countdown": 10,
      "questions": [
        {
          "question_text": "Test Question 1?",
          "question_index": 0,
          "answers": [
            {"answer_text": "Correct Answer (Correct)", "answer_index": 0},
            {"answer_text": "Wrong Answer 1", "answer_index": 1},
            {"answer_text": "Wrong Answer 2", "answer_index": 2},
            {"answer_text": "Wrong Answer 3", "answer_index": 3}
          ]
        },
        {
          "question_text": "Test Question 2?",
          "question_index": 1,
          "answers": [
            {"answer_text": "Wrong Answer A", "answer_index": 0},
            {"answer_text": "Correct Answer B (Correct)", "answer_index": 1},
            {"answer_text": "Wrong Answer C", "answer_index": 2},
            {"answer_text": "Wrong Answer D", "answer_index": 3}
          ]
        }
      ]
    }
  }
}
```

Start server:

```bash
json-server --watch db.json --port 3000
```

Access at: `http://localhost:3000/game`

Update `api_service.gd`:
```gdscript
const BASE_URL = "http://localhost:3000"
const API_ENDPOINT = "/game"  # Ganti endpoint untuk json-server
```

### 3. Test dengan Real API

#### a. Update Configuration

Edit `api_service.gd`:
```gdscript
const BASE_URL = "http://your-backend-url:port"
```

Edit `maze_part_final.gd`:
```gdscript
var game_id : String = "your-actual-game-id"
```

#### b. Test Connection

Tambahkan test function di `maze_part_final.gd`:

```gdscript
func test_api_connection():
    """Test API connection"""
    print("🧪 Testing API connection...")
    
    # Simple HTTP test
    var http = HTTPRequest.new()
    add_child(http)
    
    http.request_completed.connect(func(result, response_code, headers, body):
        print("🧪 Test result:")
        print("  - Result: ", result)
        print("  - Response code: ", response_code)
        print("  - Body: ", body.get_string_from_utf8())
    )
    
    var test_url = BASE_URL + "/health"  # Health check endpoint
    http.request(test_url)
```

## 🐛 Debugging Tips

### Enable Verbose Logging

Edit `api_service.gd`, tambahkan di awal `_on_request_completed`:

```gdscript
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
    # Verbose logging
    print("=" * 50)
    print("📡 HTTP REQUEST COMPLETED")
    print("=" * 50)
    print("Result Code: ", result)
    print("HTTP Code: ", response_code)
    print("Headers: ", headers)
    print("Body Length: ", body.size())
    print("Body Content: ", body.get_string_from_utf8())
    print("=" * 50)
    
    # ... rest of function
```

### Check Network in Godot

Di Godot Editor:
1. Run game
2. Open "Debugger" tab
3. Go to "Network Profiler"
4. Lihat semua HTTP requests

### Browser DevTools (Web Export)

Jika export ke HTML5:
1. Open game di browser
2. F12 untuk DevTools
3. Tab "Network" untuk lihat requests
4. Tab "Console" untuk lihat print statements

## 🔧 Common Issues & Solutions

### Issue 1: CORS Error (Web Export)
```
Access to XMLHttpRequest at 'http://api.com' from origin 'http://localhost' has been blocked by CORS
```

**Solution:**
Backend harus enable CORS. Contoh Express.js:

```javascript
const cors = require('cors');
app.use(cors({
    origin: '*',  // Or specify your domain
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    credentials: true
}));
```

### Issue 2: Connection Timeout
```
❌ HTTP Request error: 7 (RESULT_CONNECTION_ERROR)
```

**Solution:**
- Check BASE_URL correct
- Check server running
- Check firewall/antivirus
- Try ping server dari terminal

### Issue 3: JSON Parse Error
```
❌ Gagal parsing JSON response
```

**Solution:**
- Print response body untuk see actual content
- Validate JSON di jsonlint.com
- Check API returning proper JSON headers

### Issue 4: 404 Not Found
```
❌ HTTP error 404
```

**Solution:**
- Check endpoint path correct
- Check game_id valid
- Test endpoint di Postman/Thunder Client first

### Issue 5: Empty Questions Array
```
❌ No quiz data from API!
```

**Solution:**
- Check `data.questions` tidak empty di response
- Check JSON structure match expected format
- Add validation di `load_api_game_data()`

## 📊 Test Checklist

### Pre-Testing
- [ ] API server running
- [ ] BASE_URL configured
- [ ] game_id configured
- [ ] CORS enabled (for web)

### API Tests
- [ ] GET request successful (200)
- [ ] Response has correct structure
- [ ] Questions array not empty
- [ ] Answers have correct markers
- [ ] Question text displays correctly
- [ ] Answer text displays correctly

### Game Tests
- [ ] Loading indicator shows
- [ ] Loading indicator hides after load
- [ ] Questions display correctly
- [ ] Answers display in correct positions
- [ ] Correct answer detection works
- [ ] Wrong answer detection works
- [ ] Next question loads correctly
- [ ] Game completes properly

### Error Tests
- [ ] Network error shows error message
- [ ] 404 error shows error message
- [ ] Invalid JSON shows error message
- [ ] Fallback to static questions works
- [ ] Error message auto-closes

## 🎯 Performance Testing

### Check Load Times

Tambahkan timing di `maze_part_final.gd`:

```gdscript
var api_start_time : float = 0.0

func fetch_game_data_from_api():
    api_start_time = Time.get_ticks_msec()
    # ... existing code

func _on_game_data_loaded(game_data: Dictionary):
    var load_time = Time.get_ticks_msec() - api_start_time
    print("⏱️ API load time: ", load_time, " ms")
    # ... existing code
```

**Target Times:**
- Local API: < 100ms
- Remote API: < 500ms
- Timeout if > 10s

### Optimize for Web

Untuk HTML5 export:
1. Use HTTPRequest dengan timeout
2. Show loading indicator immediately
3. Cache responses jika possible
4. Preload questions if allowed

## 🚀 Advanced Testing

### Load Testing

Test dengan multiple concurrent players:

```bash
# Using Apache Bench
ab -n 100 -c 10 http://your-api/game/game-id/play/public
```

### Stress Testing

Test dengan banyak questions:
- 10 questions = Normal
- 50 questions = Heavy
- 100+ questions = Extreme

Monitor:
- Memory usage
- Load time
- Response time

---

**Good luck with testing! 🧪✨**
