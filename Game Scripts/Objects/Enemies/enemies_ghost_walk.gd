extends CharacterBody2D

# GameManager reference (menggunakan autoload)
var game_manager: Node = null

# Movement settings
@export var base_speed : float = 50.0
@export var chase_speed : float = 80.0
@export var detection_range : float = 300.0
@export var wander_enabled : bool = true

# References
var player : CharacterBody2D = null
var current_speed : float = base_speed

# States
enum GhostState { IDLE, WANDER, CHASE, FLEE }
var current_state : GhostState = GhostState.WANDER

# Wander behavior
var wander_direction : Vector2 = Vector2.ZERO
var wander_timer : float = 0.0
var wander_change_interval : float = 2.0

# Restricted zones (corners + center spawn)
var restricted_zones = [
	Rect2(0, 0, 150, 150),        # Top-left corner
	Rect2(1000, 0, 150, 150),     # Top-right corner
	Rect2(0, 550, 150, 150),      # Bottom-left corner
	Rect2(1000, 550, 150, 150),   # Bottom-right corner
	Rect2(450, 250, 250, 150)     # Center spawn area (lebih besar)
]

# Animation (optional)
@onready var animated_sprite = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

# Area2D untuk collision detection
@onready var detection_area = $Area2D if has_node("Area2D") else null

func _ready():
	# Add to enemies group
	add_to_group("enemies")
	
	# Get GameManager autoload
	game_manager = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	if not game_manager:
		push_warning("GameManager not found! Ghost damage disabled.")
	else:
		print("✅ GameManager connected successfully")
	
	# Connect Area2D signal jika ada
	if detection_area:
		if not detection_area.body_entered.is_connected(_on_body_entered):
			detection_area.body_entered.connect(_on_body_entered)
		print("👻 Ghost Area2D connected")
		print("👻 Area2D Collision Layer: ", detection_area.collision_layer)
		print("👻 Area2D Collision Mask: ", detection_area.collision_mask)
	else:
		push_warning("Ghost Area2D not found! Collision detection disabled.")
	
	# Cari player menggunakan group
	player = get_tree().get_first_node_in_group("player")
	
	# Jika tidak ada, coba cari berdasarkan nama
	if not player:
		player = get_tree().get_root().find_child("Main_Character", true, false)
	
	if player:
		print("✅ Player found: ", player.name)
	else:
		push_warning("Player not found! Ghost will wander randomly.")
	
	# Set random wander direction
	randomize_wander_direction()
	
	# Set initial state
	if player:
		current_state = GhostState.WANDER
	else:
		current_state = GhostState.IDLE

func _physics_process(delta):
	# Update wander timer
	wander_timer += delta
	
	# Determine behavior based on state
	match current_state:
		GhostState.IDLE:
			handle_idle()
		GhostState.WANDER:
			handle_wander(delta)
		GhostState.CHASE:
			handle_chase(delta)
		GhostState.FLEE:
			handle_flee(delta)
	
	# Check if we should change state
	update_state()
	
	# Save old position before moving
	var old_position = global_position
	
	# Move the ghost
	move_and_slide()
	
	# Check if entered restricted zone
	if is_in_restricted_zone(global_position):
		# Revert to old position
		global_position = old_position
		velocity = Vector2.ZERO
		
		# Move away from restricted zone
		escape_restricted_zone()
	
	# TAMBAHAN: Manual collision check sebagai backup
	check_manual_collision()
	
	# Update animation
	update_animation()

# 🆕 TAMBAHAN: Manual collision check
func check_manual_collision():
	if not player or not game_manager:
		return
	
	# Check distance to player
	var distance = global_position.distance_to(player.global_position)
	
	# Jika sangat dekat (overlap), trigger damage
	if distance < 30.0:  # Adjust threshold sesuai ukuran sprite
		if not game_manager.get_is_invincible():
			print("💥 Manual collision detected! Distance: ", distance)
			on_catch_player(player)

func handle_idle():
	velocity = Vector2.ZERO

func handle_wander(delta):
	# Change direction periodically
	if wander_timer >= wander_change_interval:
		randomize_wander_direction()
		wander_timer = 0.0
	
	# Move in wander direction
	velocity = wander_direction * base_speed

func handle_chase(delta):
	if not player:
		return
	
	# Calculate direction to player
	var direction = (player.global_position - global_position).normalized()
	
	# Move towards player
	velocity = direction * chase_speed

func handle_flee(delta):
	if not player:
		return
	
	# Calculate direction away from player
	var direction = (global_position - player.global_position).normalized()
	
	# Move away from player
	velocity = direction * chase_speed * 1.2

func update_state():
	if not player:
		current_state = GhostState.WANDER
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# State machine
	if distance_to_player <= detection_range:
		# Player is close - chase
		if current_state != GhostState.CHASE:
			current_state = GhostState.CHASE
			current_speed = chase_speed
	else:
		# Player is far - wander
		if current_state != GhostState.WANDER:
			current_state = GhostState.WANDER
			current_speed = base_speed
			randomize_wander_direction()

func randomize_wander_direction():
	# Random direction
	var angle = randf() * TAU  # TAU = 2 * PI
	wander_direction = Vector2(cos(angle), sin(angle))

func is_in_restricted_zone(pos: Vector2) -> bool:
	for zone in restricted_zones:
		if zone.has_point(pos):
			return true
	return false

func escape_restricted_zone():
	# Find nearest restricted zone center
	var nearest_center = get_nearest_restricted_zone_center()
	
	# Move away from it
	var escape_direction = (global_position - nearest_center).normalized()
	
	# Apply escape velocity
	velocity = escape_direction * chase_speed * 1.5
	
	# Force move
	move_and_slide()
	
	# Update wander direction to avoid going back
	wander_direction = escape_direction
	wander_timer = 0.0

func get_nearest_restricted_zone_center() -> Vector2:
	var nearest_center = global_position
	var min_distance = INF
	
	for zone in restricted_zones:
		var center = zone.get_center()
		var distance = global_position.distance_to(center)
		if distance < min_distance:
			min_distance = distance
			nearest_center = center
	
	return nearest_center

func update_animation():
	if not animated_sprite:
		return
	
	# Flip sprite based on direction
	if velocity.x < 0:
		animated_sprite.flip_h = true
	elif velocity.x > 0:
		animated_sprite.flip_h = false
	
	# Play animation based on state
	match current_state:
		GhostState.WANDER:
			animated_sprite.play("Walking")
		GhostState.CHASE:
			animated_sprite.play("Walking")
		GhostState.FLEE:
			animated_sprite.play("Walking")

# Debug visualization (optional)
func _draw():
	if Engine.is_editor_hint():
		return
	
	# Draw detection range (hanya di debug mode)
	if OS.is_debug_build():
		
		# Draw restricted zones
		for zone in restricted_zones:
			var local_zone = Rect2(zone.position - global_position, zone.size)

# Public functions untuk control dari luar
func set_chase_target(target: Node2D):
	player = target
	if target:
		current_state = GhostState.CHASE

func set_speed(new_speed: float):
	base_speed = new_speed
	chase_speed = new_speed * 1.6

func force_idle_state():
	# Paksa ghost untuk idle (dipanggil saat jawaban benar)
	current_state = GhostState.IDLE
	velocity = Vector2.ZERO
	print("👻 Ghost ", name, " forced to IDLE state")

func add_restricted_zone(zone: Rect2):
	restricted_zones.append(zone)

func remove_restricted_zone(zone: Rect2):
	restricted_zones.erase(zone)

func get_distance_to_player() -> float:
	if player:
		return global_position.distance_to(player.global_position)
	return INF

# 🔧 PERBAIKAN: Collision detection dengan player
func _on_body_entered(body):
	print("🔔 Body entered Area2D: ", body.name)
	
	# PENTING: Check invincibility DULU sebelum semua checks
	if game_manager and game_manager.get_is_invincible():
		print("🛡️ Player is invincible, ignoring collision")
		return
	
	# Check multiple conditions
	if body == player:
		print("✅ Player detected by reference!")
		on_catch_player(body)
		return
	
	if body.name == "Main_Character":
		print("✅ Player detected by name!")
		on_catch_player(body)
		return
	
	if body.is_in_group("player"):
		print("✅ Player detected by group!")
		on_catch_player(body)
		return
	
	print("❌ Not the player: ", body.name)

func on_catch_player(player_body):
	if not game_manager:
		push_warning("GameManager not available!")
		return
	
	# Check invincibility
	if game_manager.get_is_invincible():
		print("🛡️ Player is invincible, no damage taken")
		return
	
	print("👻 Ghost caught the player!")
	
	# Animasi hit effect pada player (shake, flash, knockback)
	create_hit_effect(player_body)
	
	# Kurangi lives melalui GameManager
	game_manager.lose_life()
	
	# Play death animation DULU sebelum teleport
	play_death_animation(player_body)
	
	# Wait untuk death animation selesai dengan safety check
	var tree = get_tree()
	if tree and is_inside_tree():
		await tree.create_timer(1.0).timeout
	
	# BARU teleport player ke spawn setelah animasi
	teleport_player_to_spawn(player_body)
	
	# Beri invincibility sementara agar tidak langsung kena lagi
	if player_body and player_body.has_method("set_invincible"):
		player_body.set_invincible(2.0)  # 2 detik invincible
	else:
		push_warning("Cannot create timer - node not in tree")

func teleport_player_to_spawn(player_body):
	# Safety check untuk get_tree()
	var tree = get_tree()
	if not tree:
		push_warning("SceneTree not available for teleport")
		player_body.global_position = Vector2(630, 350)
		return
	
	var spawn_point = tree.get_first_node_in_group("spawn_point")
	
	if spawn_point:
		player_body.global_position = spawn_point.global_position
		print("📍 Player teleported to spawn point")
	else:
		# Default spawn position (kanan bawah sedikit dari center)
		player_body.global_position = Vector2(630, 350)
		print("📍 Player teleported to default spawn (no spawn_point found)")

# Helper function untuk pathfinding sederhana
func get_valid_neighbors(pos: Vector2, tile_size: int = 16) -> Array:
	var neighbors = [
		pos + Vector2(tile_size, 0),
		pos + Vector2(-tile_size, 0),
		pos + Vector2(0, tile_size),
		pos + Vector2(0, -tile_size)
	]
	
	var valid_neighbors = []
	for neighbor in neighbors:
		if not is_in_restricted_zone(neighbor):
			# Check for wall collision (optional - needs tilemap reference)
			valid_neighbors.append(neighbor)
	
	return valid_neighbors

# Optional: Smooth rotation towards movement direction
func smooth_rotation(delta: float, rotation_speed: float = 5.0):
	if velocity.length() > 0:
		var target_rotation = velocity.angle()
		rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)

func play_death_animation(player_body: Node2D):
	# Cari AnimatedSprite2D di player
	var animated_sprite = player_body.get_node_or_null("AnimatedSprite2D")
	
	if animated_sprite and animated_sprite.sprite_frames:
		# Cek apakah animasi "Death_Animation" ada
		if animated_sprite.sprite_frames.has_animation("Death_Animation"):
			print("💀 Playing Death_Animation on player")
			animated_sprite.play("Death_Animation")
		else:
			print("⚠️ Death_Animation not found, available animations:")
			for anim_name in animated_sprite.sprite_frames.get_animation_names():
				print("  - ", anim_name)
	else:
		push_warning("AnimatedSprite2D not found on player for death animation")

func create_hit_effect(player_body: Node2D):
	# 1. Screen shake effect (shake player)
	var original_pos = player_body.global_position
	
	# Knockback effect - dorong player ke arah berlawanan dari ghost
	var knockback_direction = (player_body.global_position - global_position).normalized()
	var knockback_strength = 30.0
	player_body.global_position += knockback_direction * knockback_strength
	
	# 2. Flash effect - modulate warna player
	var original_modulate = player_body.modulate
	
	# Create tween untuk animasi
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Flash red beberapa kali
	for i in range(3):
		tween.tween_property(player_body, "modulate", Color.RED, 0.1)
		tween.tween_property(player_body, "modulate", original_modulate, 0.1)
	
	# 3. Shake effect
	tween.set_parallel(false)
	var shake_strength = 8.0
	for i in range(6):
		var shake_offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
		tween.tween_property(player_body, "global_position", player_body.global_position + shake_offset, 0.05)
	
	print("💥 Hit effect created!")
