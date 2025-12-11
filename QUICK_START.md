# 🚀 Quick Start - API Integration

## 3 Steps to Get Started

### 1️⃣ Configure API URL
Open: `Game Scripts/Scenes/Maze_Template/api_service.gd`

```gdscript
# Line 4 - Change this!
const BASE_URL = "https://your-api-domain.com"
```

**Examples:**
- Local: `http://localhost:3000`
- Production: `https://api.yoursite.com`

---

### 2️⃣ Set Game ID
Open: `Game Scripts/Scenes/Maze_Template/maze_part_final.gd`

```gdscript
# Line 14 - Change this!
var game_id : String = "your-game-id-here"
```

Get game ID dari database atau API response.

---

### 3️⃣ Run & Test
1. Press F5 di Godot
2. Check console output
3. Look for:
   ```
   ✅ Game data loaded successfully!
   📝 Questions count: X
   ```

---

## ✅ Done! 

Your game now fetches questions from API!

### What Happens:
1. Game starts → Shows loading indicator
2. Fetches data from API
3. Displays questions from API
4. If API fails → Uses fallback questions

---

## 🔧 Optional: Add Authentication

If your API needs auth token:

Open: `Game Scripts/Scenes/Maze_Template/api_service.gd`

```gdscript
# Line 47 - Add this line:
var headers = [
    "Content-Type: application/json",
    "Accept: application/json",
    "Authorization: Bearer YOUR_TOKEN_HERE"  # Add this!
]
```

---

## 📖 Need More Info?

- **Full Setup Guide:** See `API_SETUP_README.md`
- **Testing Guide:** See `TESTING_GUIDE.md`
- **Implementation Details:** See `IMPLEMENTATION_SUMMARY.md`

---

## ❓ Troubleshooting

### Issue: CORS Error (Web Export)
**Fix:** Enable CORS on your backend server

### Issue: 404 Not Found
**Fix:** Check BASE_URL and game_id are correct

### Issue: No Questions Loading
**Fix:** Check API response format (see API_SETUP_README.md)

---

## 🎮 Test Without Backend

Want to test without API first?

Open: `maze_part_final.gd`, change line 30:

```gdscript
# Comment out API fetch:
# fetch_game_data_from_api()

# Use static questions instead:
setup_new_quiz()
```

This will use the hardcoded questions for testing.

---

**That's it! You're ready to go! 🎉**
