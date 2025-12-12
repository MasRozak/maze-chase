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
	# Force landscape orientation on mobile
	if OS.has_feature("web"):
		_force_landscape_orientation()
	
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
	
	# For Web platform, check via JavaScript if it's actually mobile
	if os_name == "Web":
		return _is_mobile_web()
	
	# For native platforms
	return os_name in ["Android", "iOS"] or DisplayServer.is_touchscreen_available()

func _is_mobile_web() -> bool:
	"""Detect if running on mobile browser using JavaScript"""
	var js_code = """
		(function() {
			// Check user agent for mobile devices
			var userAgent = navigator.userAgent || navigator.vendor || window.opera;
			
			// Check for mobile keywords
			var isMobile = /android|webos|iphone|ipad|ipod|blackberry|iemobile|opera mini/i.test(userAgent);
			
			// Also check for touch support
			var hasTouch = ('ontouchstart' in window) || (navigator.maxTouchPoints > 0);
			
			// Check screen size (mobile usually < 768px width)
			var isSmallScreen = window.innerWidth < 768;
			
			return isMobile || (hasTouch && isSmallScreen);
		})();
	"""
	var result = JavaScriptBridge.eval(js_code)
	return result == true

func _force_landscape_orientation():
	"""Force landscape orientation on mobile web"""
	var js_code = """
		(function() {
			try {
				// Try to lock screen orientation to landscape
				if (screen.orientation && screen.orientation.lock) {
					screen.orientation.lock('landscape').catch(function(err) {
						console.log('Screen orientation lock failed:', err);
					});
				}
				
				// Add CSS to suggest landscape
				var style = document.createElement('style');
				style.textContent = '@media screen and (orientation: portrait) { body::before { content: "Please rotate your device to landscape mode"; position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); background: rgba(0,0,0,0.9); color: white; padding: 20px; border-radius: 10px; z-index: 9999; text-align: center; } }';
				document.head.appendChild(style);
			} catch(e) {
				console.log('Orientation lock not supported:', e);
			}
		})();
	"""
	JavaScriptBridge.eval(js_code)
	print("📱 Forced landscape orientation for mobile web")

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
