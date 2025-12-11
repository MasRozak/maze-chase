extends CharacterBody2D

# Kecepatan pergerakan karakter
@export var speed: float = 150.0

# Variabel @onready untuk mengakses AnimatedSprite2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	# Tambahkan ke group "player" agar bisa dideteksi oleh ghost
	add_to_group("player")
	print("🎮 Player added to group 'player'")

func _physics_process(delta: float):
	# 1. Dapatkan arah input
	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# 2. Hitung velocity
	if direction:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	# 3. Pindahkan karakter
	move_and_slide()

	# 4. Logika Animasi dan Flip H
	if direction.x != 0 or direction.y != 0:
		# Jika karakter bergerak (ada input)

		if direction.y < 0:
			# Bergerak ke atas (North)
			animated_sprite_2d.play("Running_North")
		elif direction.y > 0:
			# Bergerak ke bawah (South, menggunakan animasi East)
			animated_sprite_2d.play("Running_East")
		else:
			# Bergerak horizontal saja
			animated_sprite_2d.play("Running_East")

		# Logika untuk flip horizontal (Hanya jika bergerak kiri/kanan)
		if direction.x < 0:
			# Ke kiri: flip sprite secara horizontal
			animated_sprite_2d.flip_h = true
		elif direction.x > 0:
			# Ke kanan: pastikan sprite tidak ter-flip
			animated_sprite_2d.flip_h = false
			
	else:
		# Jika karakter diam, hentikan animasi atau mainkan animasi "Idle" jika ada
		animated_sprite_2d.stop()
		# Jika Anda punya animasi idle, ganti baris di atas dengan:
		# animated_sprite_2d.play("Idle")
