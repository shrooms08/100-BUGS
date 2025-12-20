extends CanvasLayer

# Virtual button states
var left_pressed = false
var right_pressed = false
var jump_pressed = false

# Button nodes - Change type to Node2D (works for all)
@onready var left_button = $Control/LeftButton
@onready var jump_button = $Control/JumpButton
@onready var right_button = $Control/RightButton

func _ready():
	var is_mobile = check_if_mobile()
	
	print("=== TOUCH CONTROLS INIT ===")
	print("Mobile: ", is_mobile)
	
	if not is_mobile:
		visible = false
		return
	
	visible = true
	print("✅ Controls visible and ready")
	
	# DEBUG: Print button info
	if left_button:
		print("Left button found: ", left_button.get_class())
		print("  Position: ", left_button.global_position)
	if right_button:
		print("Right button found: ", right_button.get_class())
		print("  Position: ", right_button.global_position)
	if jump_button:
		print("Jump button found: ", jump_button.get_class())
		print("  Position: ", jump_button.global_position)

func check_if_mobile() -> bool:
	if OS.has_feature("mobile"):
		return true
	if DisplayServer.is_touchscreen_available():
		return true
	if OS.has_feature("web"):
		var user_agent = JavaScriptBridge.eval("navigator.userAgent", true)
		if user_agent != null:
			var ua_str = str(user_agent).to_lower()
			if "mobile" in ua_str or "android" in ua_str or "iphone" in ua_str:
				return true
	return false

# DIRECT TOUCH DETECTION - NO SIGNALS NEEDED!
func _input(event):
	if event is InputEventScreenTouch:
		var touch_pos = event.position
		
		if event.pressed:
			print("👆 TOUCH DOWN at: ", touch_pos)
			check_buttons_touched(touch_pos, true)
		else:
			print("👆 TOUCH UP at: ", touch_pos)
			check_buttons_touched(touch_pos, false)

func check_buttons_touched(touch_pos: Vector2, is_pressed: bool):
	# Check left button
	if left_button and is_point_in_button(left_button, touch_pos):
		left_pressed = is_pressed
		print("🔵 LEFT: ", left_pressed)
		return
	
	# Check right button
	if right_button and is_point_in_button(right_button, touch_pos):
		right_pressed = is_pressed
		print("🔴 RIGHT: ", right_pressed)
		return
	
	# Check jump button
	if jump_button and is_point_in_button(jump_button, touch_pos):
		jump_pressed = is_pressed
		print("🟢 JUMP: ", jump_pressed)
		return

func is_point_in_button(button: Node, point: Vector2) -> bool:
	if not button or not button.visible:
		return false
	
	# Get button rect - works for both Control and Node2D
	var button_rect: Rect2
	
	if button is Control:
		button_rect = button.get_global_rect()
	elif button is Node2D:
		# For Node2D, calculate rect manually
		var pos = button.global_position
		var size = Vector2(100, 100)  # Default size
		if button.has_method("get_size"):
			size = button.get_size()
		button_rect = Rect2(pos, size)
	else:
		return false
	
	var contains = button_rect.has_point(point)
	
	if contains:
		print("   ✅ Hit button: ", button.name)
		print("   Button rect: ", button_rect)
		print("   Touch point: ", point)
	
	return contains

# Helper functions for player
func is_left_pressed() -> bool:
	return left_pressed

func is_right_pressed() -> bool:
	return right_pressed

func is_jump_pressed() -> bool:
	return jump_pressed

func get_direction() -> float:
	var direction = 0.0
	if left_pressed:
		direction -= 1.0
	if right_pressed:
		direction += 1.0
	return direction
