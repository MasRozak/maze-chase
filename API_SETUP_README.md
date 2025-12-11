# 🌐 API Integration Setup - Maze Chase Game

## 📋 Overview
Game ini sekarang sudah terintegrasi dengan API untuk mengambil pertanyaan dan jawaban secara dinamis.

## 🔧 Konfigurasi API

### 1. Atur URL API
Edit file: `Game Scripts/Scenes/Maze_Template/api_service.gd`

```gdscript
# Line 4-5: Ganti dengan URL API kamu
const BASE_URL = "https://your-api-domain.com"  # ⚠️ GANTI INI!
```

**Contoh:**
- Development: `http://localhost:3000`
- Production: `https://api.yoursite.com`

### 2. Atur Game ID
Edit file: `Game Scripts/Scenes/Maze_Template/maze_part_final.gd`

```gdscript
# Line 14: Ganti dengan Game ID yang sesuai
var game_id : String = "b2d7d178-53c0-45de-be43-7478e26d9705"  # ⚠️ GANTI INI!
```

Game ID didapat dari database atau ketika create game baru.

### 3. Authentication (Opsional)
Jika API memerlukan authentication token, edit file `api_service.gd`:

```gdscript
# Line 47-48: Uncomment dan tambahkan token
var headers = [
    "Content-Type: application/json",
    "Accept: application/json",
    "Authorization: Bearer YOUR_TOKEN_HERE"  # Tambahkan line ini
]
```

## 📡 Format API Response

API harus mengembalikan response dengan format berikut:

```json
{
    "success": true,
    "statusCode": 200,
    "message": "Get public game successfully",
    "data": {
        "id": "game-uuid",
        "name": "Game Name",
        "description": "Game Description",
        "score_per_question": 10,
        "countdown": 10,
        "questions": [
            {
                "question_text": "Your question here?",
                "question_index": 0,
                "answers": [
                    {
                        "answer_text": "Answer 1 (Correct)",
                        "answer_index": 0
                    },
                    {
                        "answer_text": "Answer 2",
                        "answer_index": 1
                    },
                    {
                        "answer_text": "Answer 3",
                        "answer_index": 2
                    },
                    {
                        "answer_text": "Answer 4",
                        "answer_index": 3
                    }
                ]
            }
        ]
    }
}
```

### ⚠️ Important Notes:
1. **Correct Answer Marker**: Jawaban yang benar harus mengandung text `(Correct)` atau `(correct)` di `answer_text`
2. **Answer Index**: Sistem akan otomatis sort answers berdasarkan `answer_index`
3. **Question Index**: Questions akan diurutkan berdasarkan `question_index`

## 🎮 How It Works

### Flow Diagram:
```
1. Game Start (maze_part_final.gd)
   ↓
2. Setup API Service
   ↓
3. Fetch Game Data (api_service.gd)
   ↓
4. Show Loading Indicator
   ↓
5. API Response Received
   ↓
6. Parse & Load to GameManager
   ↓
7. Setup Quiz from API Data
   ↓
8. Display Question & Answers
```

### Fallback System:
Jika API gagal atau error:
- System akan otomatis menggunakan **static questions** yang ada di `game_manager.gd`
- User akan melihat error message selama 5 detik
- Game tetap bisa dimainkan dengan fallback questions

## 🧪 Testing

### Test dengan CORS (Web Export)
Jika test di browser dan kena CORS error:

1. **Backend**: Enable CORS di server
```javascript
// Express.js example
app.use(cors({
    origin: ['http://localhost:*', 'https://yourdomain.com']
}));
```

2. **Godot Export**: Pastikan export settings sudah benar
   - Project > Export > Web (Runnable)
   - Enable "Use Custom HTML Shell" jika perlu

### Test Lokal (Desktop)
Desktop build tidak kena CORS restriction, bisa langsung test ke localhost API.

## 📝 Files Modified

1. **api_service.gd** (NEW) - Handles HTTP requests
2. **game_manager.gd** (MODIFIED) - Added API data handling
3. **maze_part_final.gd** (MODIFIED) - Integrated API fetching

## 🔍 Debug Tips

### Print Statements:
Game sudah dilengkapi debug prints:
- `🌐` = API operations
- `✅` = Success
- `❌` = Errors
- `⚠️` = Warnings

### Check Console:
```
🌐 Fetching game data for ID: xxx
✅ Game data loaded from API!
📝 Game: Apin gimang
📝 Questions: 3
```

### Common Issues:

1. **CORS Error**
   - Solution: Enable CORS di backend
   
2. **404 Not Found**
   - Check `BASE_URL` sudah benar
   - Check `game_id` valid
   
3. **JSON Parse Error**
   - Validate API response format
   - Check response structure matches expected format

4. **No Questions Loaded**
   - Check `questions` array tidak kosong
   - Check correct answer markers ada

## 🚀 Production Deployment

### Checklist sebelum deploy:
- [ ] Ganti `BASE_URL` dengan production URL
- [ ] Test API response di production
- [ ] Pastikan CORS sudah setup correct
- [ ] Test game di production environment
- [ ] Verify loading indicator & error handling works
- [ ] Check fallback system works jika API down

## 💡 Tips

1. **Multiple Games**: Bisa ganti `game_id` untuk load different game
2. **Dynamic Game ID**: Bisa pass game_id dari menu atau URL parameter
3. **Cache Questions**: Consider caching API response untuk reduce API calls
4. **Retry Logic**: Bisa tambah retry mechanism di `api_service.gd`

## 📞 Support

Jika ada masalah, check:
1. Console output untuk debug messages
2. Network tab di browser DevTools (untuk Web export)
3. Godot debugger untuk desktop testing

---

**Happy Coding! 🎮🚀**
