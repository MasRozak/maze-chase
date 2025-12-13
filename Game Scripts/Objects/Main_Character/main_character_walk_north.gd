extends CharacterBody2D

# Kecepatan pergerakan karakter
@export var speed: float = 150.0

# Variabel @onready untuk mengakses AnimatedSprite2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# Virtual joystick reference
var joystick: Control = null

func _ready() -> void:
	# Tambahkan ke group "player" agar bisa dideteksi oleh ghost
	add_to_group("player")
	print("🎮 Player added to group 'player'")
	
	# Cari joystick di scene
	await get_tree().process_frame
	joystick = get_tree().current_scene.get_node_or_null("CanvasLayer/VirtualJoystick")
	if joystick:
		print("🕹️ Virtual Joystick connected to player")

func _physics_process(delta: float) -> void:
	# 1. Dapatkan arah input (keyboard/gamepad atau joystick virtual)
	var direction: Vector2 = Vector2.ZERO
	
	# Prioritaskan virtual joystick jika aktif di mobile
	if joystick and joystick.has_method("get_output"):
		var joystick_input = joystick.get_output()
		if joystick_input.length() > 0.1:
			direction = joystick_input
		else:
			# Fallback ke keyboard jika joystick tidak digunakan
			direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	else:
		# Keyboard/gamepad input
		direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# 2. Hitung velocity
	if direction:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	# 3. Pindahkan karakter
	move_and_slide()

	# 4. Logika Animasi (jika ada AnimatedSprite2D)
	if animated_sprite_2d:
		if direction.x != 0 or direction.y != 0:
			# Jika karakter bergerak
			if direction.y < 0:
				# Bergerak ke atas (North)
				animated_sprite_2d.play("default")
			elif direction.y > 0:
				# Bergerak ke bawah (South)
				animated_sprite_2d.play("default")
			else:
				# Bergerak horizontal saja
				animated_sprite_2d.play("default")

			# Logika untuk flip horizontal
			if direction.x < 0:
				animated_sprite_2d.flip_h = true
			elif direction.x > 0:
				animated_sprite_2d.flip_h = false
		else:
			# Jika karakter diam
			animated_sprite_2d.stop()
