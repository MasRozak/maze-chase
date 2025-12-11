extends Node

# ==================== API CONFIG ====================
# Copy file ini dan rename ke api_config.gd (jangan commit yang ori ke git)
# Atau langsung edit values di bawah

# DEVELOPMENT
const DEV_BASE_URL = "http://localhost:3000"
const DEV_GAME_ID = "test-game-id-123"

# PRODUCTION  
const PROD_BASE_URL = "https://api.yoursite.com"
const PROD_GAME_ID = "b2d7d178-53c0-45de-be43-7478e26d9705"

# CURRENT ENVIRONMENT
enum Environment { DEV, PROD }
const CURRENT_ENV = Environment.DEV  # Change to PROD for production

# ==================== HELPER FUNCTIONS ====================
static func get_base_url() -> String:
	if CURRENT_ENV == Environment.DEV:
		return DEV_BASE_URL
	else:
		return PROD_BASE_URL

static func get_game_id() -> String:
	if CURRENT_ENV == Environment.DEV:
		return DEV_GAME_ID
	else:
		return PROD_GAME_ID

static func is_dev_mode() -> bool:
	return CURRENT_ENV == Environment.DEV

static func print_config():
	print("==================== API CONFIG ====================")
	print("Environment: ", "DEV" if is_dev_mode() else "PROD")
	print("Base URL: ", get_base_url())
	print("Game ID: ", get_game_id())
	print("===================================================")
