extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -600.0
var gravity = 1000.0
var FRICTION = 1.0
var hitbox_offset = Vector2.ZERO

# Bug variables
var jump_disabled_after_first = false
var has_jumped_once = false
var controls_reversed = false
var input_delay = 0.0
var input_queue = []
var speed_multiplier = 1.0

# New bug variables
var gravity_switches_on_jump = false
var current_gravity_direction = 1  # 1 = down, -1 = up
var limited_jumps = false
var jumps_remaining = 3
var gravity_flips_on_land = false
var last_on_floor = false
var use_alternative_controls = false

# Animation
@onready var bug: AnimatedSprite2D = $Bug

# Touch controls (for mobile)
var touch_controls = null

func _ready():
	if bug:
		bug.play("idle")
	
	print("=== PLAYER INIT ===")
	
	# Try to find touch controls in scene
	touch_controls = get_node_or_null("/root/TouchControls")
	
	if touch_controls:
		print("Player found TouchControls!")
		print("   TouchControls visible: ", touch_controls.visible)
	else:
		print("Player CANNOT find TouchControls!")
		print("   Checking if it exists in tree...")
		
		# Try alternative search
		var autoloads = get_tree().root.get_children()
		for node in autoloads:
			print("   Found autoload: ", node.name)
			if node.name == "TouchControls":
				touch_controls = node
				print("   Found it!")
				break
	
	print("=== PLAYER READY ===")

func _physics_process(delta):
	# Bug #6: Play with Gravity (gravity switches on jump press)
	if gravity_switches_on_jump:
		# Apply gravity in current direction
		if not is_on_floor() and not is_on_ceiling():
			velocity.y += gravity * current_gravity_direction * delta
		
		# Check for jump press to switch gravity
		var jump_input = false
		if controls_reversed:
			jump_input = Input.is_action_just_pressed("ui_right")
		elif use_alternative_controls:
			jump_input = Input.is_key_pressed(KEY_W)
		else:
			jump_input = Input.is_action_just_pressed("ui_accept")
			# Add touch support
			if touch_controls and touch_controls.is_jump_pressed():
				jump_input = true
				print("Touch jump for gravity flip!")
		
		if jump_input:
			current_gravity_direction *= -1  # Flip gravity
			velocity.y = JUMP_VELOCITY * current_gravity_direction * -1
			has_jumped_once = true
	
	# Bug #12: Gravity Fails (gravity flips on ANY collision)
	elif gravity_flips_on_land:
		# Check if we're touching something this frame
		if get_slide_collision_count() > 0 and not last_on_floor:
			# Just collided, flip gravity
			current_gravity_direction *= -1
			last_on_floor = true
		elif get_slide_collision_count() == 0:
			# Not touching anything
			last_on_floor = false
		
		# Apply gravity in current direction
		velocity.y += gravity * current_gravity_direction * delta
	
	# Normal gravity
	else:
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			if not jump_disabled_after_first:
				has_jumped_once = false
	
	# Handle jump check
	var can_jump = is_on_floor()
	if jump_disabled_after_first and has_jumped_once:
		can_jump = false
	
	# Get input based on control scheme
	var direction = 0.0
	var jump_pressed = false
	
	# Bug #17: Alternative Controls (A/W/D instead of arrows)
	if use_alternative_controls:
		if Input.is_key_pressed(KEY_A):
			direction = -1.0
		if Input.is_key_pressed(KEY_D):
			direction = 1.0
		jump_pressed = Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_W)
		
		# Add touch support for alternative controls
		if touch_controls:
			var touch_dir = touch_controls.get_direction()
			if touch_dir != 0:
				direction = touch_dir
				print("Touch direction (Alt): ", direction)
			if touch_controls.is_jump_pressed():
				jump_pressed = true
				print("Touch jump (Alt)!")
	
	# Bug #13: Swapped Controls
	elif controls_reversed:
		# LEFT key = move RIGHT
		if Input.is_action_pressed("ui_left"):
			direction = 1.0
		# RIGHT key = JUMP
		if Input.is_action_just_pressed("ui_right") and can_jump:
			jump_pressed = true
		# JUMP key (Space) = move LEFT
		if Input.is_action_pressed("ui_accept"):
			direction = -1.0
		
		# Touch controls with reversed logic
		if touch_controls:
			var touch_dir = touch_controls.get_direction()
			if touch_dir != 0:
				direction = -touch_dir  # Reverse touch input too!
				print("Touch direction (Reversed): ", direction)
			if touch_controls.is_jump_pressed() and can_jump:
				jump_pressed = true
				print("Touch jump (Reversed)!")
	
	# Bug #14: Time Delay
	elif input_delay > 0:
		# Queue input for delayed processing
		var current_input = Input.get_axis("ui_left", "ui_right")
		
		# Add touch input to queue
		if touch_controls:
			var touch_dir = touch_controls.get_direction()
			if touch_dir != 0:
				current_input = touch_dir
				print("Touch queued (Delayed): ", current_input)
		
		input_queue.append({
			"time": Time.get_ticks_msec() / 1000.0,
			"input": current_input
		})
		
		# Process old inputs
		var current_time = Time.get_ticks_msec() / 1000.0
		for queued in input_queue:
			if current_time - queued.time >= input_delay:
				direction = queued.input
				input_queue.erase(queued)
				break
		
		# Normal jump (not delayed)
		jump_pressed = Input.is_action_just_pressed("ui_accept")
		if touch_controls and touch_controls.is_jump_pressed():
			jump_pressed = true
			print("Touch jump (Delayed)!")
	
	# Normal controls
	else:
		direction = Input.get_axis("ui_left", "ui_right")
		jump_pressed = Input.is_action_just_pressed("ui_accept")
		
		# Add touch controls support for normal controls
		if touch_controls:
			var touch_dir = touch_controls.get_direction()
			if touch_dir != 0:
				direction = touch_dir
				print("TOUCH DIRECTION: ", direction)
			
			if touch_controls.is_jump_pressed():
				jump_pressed = true
				print("TOUCH JUMP!")
	
	# Apply jump with Bug #9: Save Jumps (limited jumps)
	if jump_pressed and can_jump:
		if limited_jumps:
			if jumps_remaining > 0:
				if gravity_switches_on_jump or gravity_flips_on_land:
					velocity.y = JUMP_VELOCITY * current_gravity_direction * -1
				else:
					velocity.y = JUMP_VELOCITY
				has_jumped_once = true
				jumps_remaining -= 1
				print("JUMP! Remaining: ", jumps_remaining)
		else:
			if gravity_switches_on_jump or gravity_flips_on_land:
				velocity.y = JUMP_VELOCITY * current_gravity_direction * -1
			else:
				velocity.y = JUMP_VELOCITY
			has_jumped_once = true
			print("JUMP!")
	
	# Apply speed multiplier (Bug #15: Velocity Chaos)
	var current_speed = SPEED * speed_multiplier
	
	if direction != 0:
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * FRICTION)
	
	move_and_slide()
	
	# Apply hitbox offset (Bug #7)
	if hitbox_offset != Vector2.ZERO:
		$CollisionShape2D.position = hitbox_offset
	else:
		$CollisionShape2D.position = Vector2.ZERO
	
	# Update animations
	update_animation(direction)

func update_animation(direction: float):
	if not bug:
		return
	
	# Flip sprite based on direction
	if direction > 0:
		bug.flip_h = false
	elif direction < 0:
		bug.flip_h = true
	
	# Flip sprite vertically based on gravity direction (Bug #6, #12)
	if gravity_switches_on_jump or gravity_flips_on_land:
		if current_gravity_direction == -1:
			# Gravity is upward - flip sprite upside down
			bug.flip_v = true
		else:
			# Gravity is normal - sprite right side up
			bug.flip_v = false
	else:
		# Normal gameplay - no vertical flip
		bug.flip_v = false
	
	# Play appropriate animation
	if not is_on_floor():
		# In air - play jump animation
		if bug.animation != "jump":
			bug.play("jump")
	elif direction != 0:
		# Moving - play walk animation
		if bug.animation != "walk":
			bug.play("walk")
	else:
		# Standing still - play idle animation
		if bug.animation != "idle":
			bug.play("idle")

func die():
	position = Vector2(84, 538)
	velocity = Vector2.ZERO
	has_jumped_once = false
	input_queue.clear()
	jumps_remaining = 3  # Reset jumps on death
	current_gravity_direction = 1  # Reset gravity direction
	last_on_floor = false
	
	# Reset animation to idle and reset flips
	if bug:
		bug.play("idle")
		bug.flip_v = false  # Reset vertical flip
