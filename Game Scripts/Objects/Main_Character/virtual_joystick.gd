extends Control

# Joystick properties
@export var joystick_radius : float = 60.0
@export var knob_radius : float = 30.0
@export var dead_zone : float = 10.0

# Internal variables
var is_pressed : bool = false
var knob_position : Vector2 = Vector2.ZERO
var output_vector : Vector2 = Vector2.ZERO

# Touch index
var current_touch_index : int = -1

# Visual elements
var background : Control
var knob : Control

func _ready():
	# Only show on mobile/touch devices
	if not _is_mobile_platform():
		visible = false
		return
	
	# Setup visual elements
	_setup_visuals()
	
	# Position joystick at bottom-left
	position = Vector2(100, get_viewport().get_visible_rect().size.y - 150)
	
	print("🕹️ Virtual Joystick initialized for mobile")

func _is_mobile_platform() -> bool:
	# Check if running on mobile or has touch screen
	var os_name = OS.get_name()
	return os_name in ["Android", "iOS", "Web"] or DisplayServer.is_touchscreen_available()

func _setup_visuals():
	# Create background circle
	background = Control.new()
	background.name = "Background"
	background.custom_minimum_size = Vector2(joystick_radius * 2, joystick_radius * 2)
	background.position = -Vector2(joystick_radius, joystick_radius)
	add_child(background)
	
	# Create knob circle
	knob = Control.new()
	knob.name = "Knob"
	knob.custom_minimum_size = Vector2(knob_radius * 2, knob_radius * 2)
	knob.position = -Vector2(knob_radius, knob_radius)
	add_child(knob)

func _draw():
	if not _is_mobile_platform():
		return
	
	# Draw background (semi-transparent dark circle)
	draw_circle(Vector2.ZERO, joystick_radius, Color(0.1, 0.1, 0.1, 0.5))
	draw_arc(Vector2.ZERO, joystick_radius, 0, TAU, 32, Color(0.3, 0.3, 0.3, 0.8), 2.0)
	
	# Draw knob (lighter circle)
	var knob_pos = knob_position
	draw_circle(knob_pos, knob_radius, Color(0.5, 0.5, 0.5, 0.7))
	draw_arc(knob_pos, knob_radius, 0, TAU, 32, Color(0.8, 0.8, 0.8, 0.9), 2.0)
	
	# Draw direction indicator
	if is_pressed and output_vector.length() > 0.1:
		draw_line(Vector2.ZERO, knob_pos, Color(1.0, 1.0, 1.0, 0.6), 2.0)

func _input(event):
	if not _is_mobile_platform():
		return
	
	# Handle touch events
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch):
	var local_pos = get_global_transform().affine_inverse() * event.position
	
	if event.pressed:
		# Check if touch is within joystick area
		if local_pos.length() <= joystick_radius:
			is_pressed = true
			current_touch_index = event.index
			_update_knob_position(local_pos)
	else:
		# Release if this is our touch
		if event.index == current_touch_index:
			_release_joystick()

func _handle_drag(event: InputEventScreenDrag):
	if is_pressed and event.index == current_touch_index:
		var local_pos = get_global_transform().affine_inverse() * event.position
		_update_knob_position(local_pos)

func _update_knob_position(pos: Vector2):
	# Clamp position to joystick radius
	var clamped_pos = pos
	if pos.length() > joystick_radius:
		clamped_pos = pos.normalized() * joystick_radius
	
	knob_position = clamped_pos
	
	# Calculate output vector
	if knob_position.length() > dead_zone:
		output_vector = knob_position.normalized() * ((knob_position.length() - dead_zone) / (joystick_radius - dead_zone))
		output_vector = output_vector.limit_length(1.0)
	else:
		output_vector = Vector2.ZERO
	
	queue_redraw()

func _release_joystick():
	is_pressed = false
	current_touch_index = -1
	knob_position = Vector2.ZERO
	output_vector = Vector2.ZERO
	queue_redraw()

func get_output() -> Vector2:
	return output_vector

func is_active() -> bool:
	return is_pressed
