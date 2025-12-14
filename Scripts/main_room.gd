extends Node2D

var fake_button = null
var fake_deadly_buttons = []
var death_zones = []
var clones = []
var mirror_clone = null

# Timer variables
var button_teleport_enabled = false
var button_teleport_timer = 0.0
var button_positions = []

var floor_flicker_enabled = false
var floor_flicker_timer = 0.0
var platform_group_a_solid = true

var velocity_chaos_enabled = false
var velocity_chaos_timer = 0.0

var platform_shuffle_enabled = false
var platform_shuffle_timer = 0.0
var platform_positions = []
var platforms_to_shuffle = []

var camera_drift_enabled = false
var camera_drift_speed = 50.0

# New bug variables
var give_up_active = false
var no_input_timer = 0.0
var reverse_button = false
var camera_follows_player = false

# Bug #8: Stay on It
var stay_on_button_active = false
var stay_on_button_timer = 0.0
var player_on_button = false

func _input(event):
	pass
	#if event is InputEventKey and event.pressed:
		#match event.keycode:
			#KEY_1: change_bug(1)
			# ... etc

func change_bug(new_bug: int):
	GameState.current_bug = new_bug
	get_tree().paused = false
	apply_bug(GameState.current_bug)
	update_bug_label()
	get_tree().reload_current_scene()

func update_bug_label():
	var bug_names = {
		1: "Plain and Simple",
		2: "Ghost Wall",
		3: "Low Gravity",
		4: "Slippery Floor",
		5: "Invisible Button",
		6: "Play with Gravity",
		7: "Hitbox Offset",
		8: "Stay on It",  # UPDATED
		9: "Save Jumps",
		10: "Floor Flicker",
		11: "Just Give Up",
		12: "Gravity Fails",
		13: "Swapped Controls",
		14: "Time Delay",
		15: "Velocity Chaos",
		16: "Chaos Shuffle",
		17: "Alternative Controls",
		18: "Blind Camera",
		19: "Don't Touch It",
		20: "Upside Down"
	}
	$UI/BugLabel.text = "Bug #%d: %s" % [GameState.current_bug, bug_names.get(GameState.current_bug, "Unknown")]

func _ready():
	MusicManager.play_gameplay_music()
	
	$ButtonPlatform/Button.pressed.connect(_on_button_pressed)
	$ButtonPlatform/Button.player_entered_button.connect(_on_player_entered_button)
	$ButtonPlatform/Button.player_exited_button.connect(_on_player_exited_button)
	apply_bug(GameState.current_bug)
	update_bug_label()

func _on_button_pressed():
	if not reverse_button and not stay_on_button_active:
		$Door.unlock()

func _on_reverse_button_pressed():
	$Door.is_locked = true
	if $Door.has_node("ColorRect"):
		$Door.get_node("ColorRect").color = Color.RED

func _on_player_entered_button():
	player_on_button = true

func _on_player_exited_button():
	player_on_button = false

func apply_bug(bug_id: int):
	reset_to_normal()
	
	match bug_id:
		1: bug_01_plain_simple()
		2: bug_02_ghost_wall()
		3: bug_03_low_gravity()
		4: bug_04_slippery_floor()
		5: bug_05_invisible_button()
		6: bug_06_play_with_gravity()
		7: bug_07_hitbox_offset()
		8: bug_08_stay_on_it()  # UPDATED
		9: bug_09_save_jumps()
		10: bug_10_floor_flicker()
		11: bug_11_just_give_up()
		12: bug_12_gravity_fails()
		13: bug_13_swapped_controls()
		14: bug_14_time_delay()
		15: bug_15_velocity_chaos()
		16: bug_16_chaos_shuffle()
		17: bug_17_alternative_controls()
		18: bug_18_blind_camera()
		19: bug_19_dont_touch_it()
		20: bug_20_upside_down()
		_: bug_01_plain_simple()

func reset_to_normal():
	if has_node("Player"):
		$Player.gravity = 980.0
		$Player.FRICTION = 1.0
		$Player.hitbox_offset = Vector2.ZERO
		$Player.jump_disabled_after_first = false
		$Player.controls_reversed = false
		$Player.input_delay = 0.0
		$Player.speed_multiplier = 1.0
		$Player.gravity_switches_on_jump = false
		$Player.current_gravity_direction = 1
		$Player.limited_jumps = false
		$Player.jumps_remaining = 3
		$Player.gravity_flips_on_land = false
		$Player.use_alternative_controls = false
		$Player.scale.y = 1
	
	if has_node("GameCamera"):
		$GameCamera.zoom = Vector2(1, 1)
		$GameCamera.offset = Vector2.ZERO
		$GameCamera.rotation_degrees = 0
		$GameCamera.position = Vector2(640, 360)
	
	if has_node("LeftWall"):
		$LeftWall.collision_layer = 1
		$LeftWall.collision_mask = 1
	
	if has_node("ButtonPlatform/Button"):
		$ButtonPlatform/Button.visible = true
		$ButtonPlatform/Button.position = Vector2(-15, -20)
		$ButtonPlatform/Button.set_process_mode(Node.PROCESS_MODE_INHERIT)
		if $ButtonPlatform/Button.pressed.is_connected(_on_reverse_button_pressed):
			$ButtonPlatform/Button.pressed.disconnect(_on_reverse_button_pressed)
		if not $ButtonPlatform/Button.pressed.is_connected(_on_button_pressed):
			$ButtonPlatform/Button.pressed.connect(_on_button_pressed)
	
	if has_node("Ground"):
		$Ground.collision_layer = 1
		$Ground.collision_mask = 1
	
	for platform in get_tree().get_nodes_in_group("group a"):
		if platform is StaticBody2D:
			platform.collision_layer = 1
			platform.collision_mask = 1
			if platform.has_node("ColorRect"):
				platform.get_node("ColorRect").modulate.a = 1.0
	
	for platform in get_tree().get_nodes_in_group("group b"):
		if platform is StaticBody2D:
			platform.collision_layer = 1
			platform.collision_mask = 1
			if platform.has_node("ColorRect"):
				platform.get_node("ColorRect").modulate.a = 1.0
	
	if fake_button != null:
		fake_button.queue_free()
		fake_button = null
	
	for btn in fake_deadly_buttons:
		btn.queue_free()
	fake_deadly_buttons.clear()
	
	for zone in death_zones:
		zone.queue_free()
	death_zones.clear()
	
	if mirror_clone != null:
		mirror_clone.queue_free()
		mirror_clone = null
	
	for clone in clones:
		clone.queue_free()
	clones.clear()
	
	button_teleport_enabled = false
	floor_flicker_enabled = false
	velocity_chaos_enabled = false
	platform_shuffle_enabled = false
	camera_drift_enabled = false
	give_up_active = false
	no_input_timer = 0.0
	reverse_button = false
	camera_follows_player = false
	stay_on_button_active = false
	stay_on_button_timer = 0.0
	player_on_button = false
	get_tree().paused = false

func _process(delta):
	# Camera follow for Bug #18
	if camera_follows_player and has_node("GameCamera") and has_node("Player"):
		$GameCamera.position = $Player.position
	
	# Bug #8: Stay on It timer
	if stay_on_button_active:
		if player_on_button:
			stay_on_button_timer += delta
			
			#if has_node("UI/BugLabel"):
				#$UI/BugLabel.text = "Bug #8: Stay on It [%.1f/5.0s]" % stay_on_button_timer
			
			if stay_on_button_timer >= 5.0:
				$Door.unlock()
				stay_on_button_active = false
				update_bug_label()
		else:
			stay_on_button_timer = 0.0
	
	# Bug #11: Just Give Up timer
	if give_up_active:
		if Input.is_anything_pressed():
			no_input_timer = 0.0
		else:
			no_input_timer += delta
			if no_input_timer >= 10.0:
				$Door.unlock()
				give_up_active = false
	
	if button_teleport_enabled:
		button_teleport_timer += delta
		if button_teleport_timer >= 3.0:
			button_teleport_timer = 0.0
			teleport_button()
	
	if floor_flicker_enabled:
		floor_flicker_timer += delta
		if floor_flicker_timer >= 2.0:
			floor_flicker_timer = 0.0
			toggle_platforms()
	
	if velocity_chaos_enabled:
		velocity_chaos_timer += delta
		if velocity_chaos_timer >= 1.0:
			velocity_chaos_timer = 0.0
			randomize_player_speed()
	
	if platform_shuffle_enabled:
		platform_shuffle_timer += delta
		if platform_shuffle_timer >= 4.0:
			platform_shuffle_timer = 0.0
			shuffle_platforms()
	
	if camera_drift_enabled:
		if has_node("GameCamera"):
			$GameCamera.offset.x += camera_drift_speed * delta
	
	for clone in clones:
		if has_node("Player"):
			var direction_vec = ($Player.position - clone.position).normalized()
			clone.position += direction_vec * 50 * delta

# ========== BUGS 1-10 ==========

func bug_01_plain_simple():
	pass

func bug_02_ghost_wall():
	$LeftWall.collision_layer = 0
	$LeftWall.collision_mask = 0
	$ButtonPlatform/Button.position = Vector2(-680, 340)
	$ButtonPlatform/Button.visible = false
	
	fake_button = preload("res://Scene/button.tscn").instantiate()
	fake_button.position = Vector2(640, 175)
	add_child(fake_button)
	
	if fake_button.pressed.is_connected(_on_button_pressed):
		fake_button.pressed.disconnect(_on_button_pressed)

func bug_03_low_gravity():
	$Player.gravity = 490.0

func bug_04_slippery_floor():
	$Player.FRICTION = 0.009

func bug_05_invisible_button():
	$ButtonPlatform/Button.visible = false

func bug_06_play_with_gravity():
	$Player.gravity_switches_on_jump = true
	$Player.current_gravity_direction = 1

func bug_07_hitbox_offset():
	$Player.hitbox_offset = Vector2(20, 0)

func bug_08_stay_on_it():
	stay_on_button_active = true
	stay_on_button_timer = 0.0
	player_on_button = false
	# Disconnect normal instant-press behavior
	if $ButtonPlatform/Button.pressed.is_connected(_on_button_pressed):
		$ButtonPlatform/Button.pressed.disconnect(_on_button_pressed)

func bug_09_save_jumps():
	$Player.limited_jumps = true
	$Player.jumps_remaining = 3

func bug_10_floor_flicker():
	floor_flicker_enabled = true
	floor_flicker_timer = 0.0
	platform_group_a_solid = true
	toggle_platforms()

# ========== BUGS 11-15 ==========

func bug_11_just_give_up():
	give_up_active = true
	no_input_timer = 0.0
	$Door.is_locked = true

func bug_12_gravity_fails():
	$Player.gravity_flips_on_land = true
	$Player.current_gravity_direction = 1

func bug_13_swapped_controls():
	$Player.controls_reversed = true

func bug_14_time_delay():
	$Player.input_delay = 1.0

func bug_15_velocity_chaos():
	velocity_chaos_enabled = true
	velocity_chaos_timer = 0.0

# ========== BUGS 16-20 ==========

func bug_16_chaos_shuffle():
	start_platform_shuffle()

func bug_17_alternative_controls():
	$Player.use_alternative_controls = true

func bug_18_blind_camera():
	if has_node("GameCamera"):
		$GameCamera.zoom = Vector2(4, 4)
		camera_follows_player = true

func bug_19_dont_touch_it():
	reverse_button = true
	$Door.unlock()
	
	if $ButtonPlatform/Button.pressed.is_connected(_on_button_pressed):
		$ButtonPlatform/Button.pressed.disconnect(_on_button_pressed)
	$ButtonPlatform/Button.pressed.connect(_on_reverse_button_pressed)

func bug_20_upside_down():
	if has_node("GameCamera"):
		$GameCamera.rotation_degrees = 180
	if has_node("Player"):
		$Player.scale.y = -1
	$Player.controls_reversed = true

# ========== HELPER FUNCTIONS ==========

func start_button_teleport():
	button_teleport_enabled = true
	button_teleport_timer = 0.0
	button_positions = [
		Vector2(640, 175),
		Vector2(400, 490),
		Vector2(640, 590),
		Vector2(880, 490),
	]
	teleport_button()

func teleport_button():
	var random_pos = button_positions[randi() % button_positions.size()]
	$ButtonPlatform/Button.position = random_pos

func toggle_platforms():
	platform_group_a_solid = !platform_group_a_solid
	
	for platform in get_tree().get_nodes_in_group("group a"):
		if platform is StaticBody2D:
			if platform_group_a_solid:
				platform.collision_layer = 1
				platform.collision_mask = 1
				if platform.has_node("ColorRect"):
					platform.get_node("ColorRect").modulate.a = 1.0
			else:
				platform.collision_layer = 0
				platform.collision_mask = 0
				if platform.has_node("ColorRect"):
					platform.get_node("ColorRect").modulate.a = 0.3
	
	for platform in get_tree().get_nodes_in_group("group b"):
		if platform is StaticBody2D:
			if platform_group_a_solid:
				platform.collision_layer = 0
				platform.collision_mask = 0
				if platform.has_node("ColorRect"):
					platform.get_node("ColorRect").modulate.a = 0.3
			else:
				platform.collision_layer = 1
				platform.collision_mask = 1
				if platform.has_node("ColorRect"):
					platform.get_node("ColorRect").modulate.a = 1.0

func spawn_fake_buttons_deadly():
	var fake_positions = [
		Vector2(400, 490),
		Vector2(880, 490)
	]
	
	for pos in fake_positions:
		var fake = preload("res://Scene/spikes.tscn").instantiate()
		fake.position = pos
		add_child(fake)
		fake_deadly_buttons.append(fake)

func randomize_player_speed():
	var multiplier = randf_range(0.5, 2.5)
	$Player.speed_multiplier = multiplier

func start_platform_shuffle():
	platform_shuffle_enabled = true
	platform_shuffle_timer = 0.0
	
	platforms_to_shuffle = []
	platform_positions = []
	
	var platform_names = ["MidLeftPlatform", "ButtonPlatform", "MidRightPlatform"]
	for name in platform_names:
		if has_node(name):
			var platform = get_node(name)
			platforms_to_shuffle.append(platform)
			platform_positions.append(platform.position)

func shuffle_platforms():
	if platforms_to_shuffle.size() == 0:
		return
	
	var temp_pos = platform_positions[0]
	for i in range(platform_positions.size() - 1):
		platform_positions[i] = platform_positions[i + 1]
	platform_positions[platform_positions.size() - 1] = temp_pos
	
	for i in range(platforms_to_shuffle.size()):
		platforms_to_shuffle[i].position = platform_positions[i]

func spawn_death_zones():
	var zone_positions = [
		Vector2(200, 500),
		Vector2(640, 580),
		Vector2(950, 400)
	]
	
	for pos in zone_positions:
		var zone = Area2D.new()
		zone.position = pos
		
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(150, 40)
		collision.shape = shape
		zone.add_child(collision)
		
		var visual = ColorRect.new()
		visual.size = Vector2(150, 40)
		visual.position = Vector2(-75, -20)
		visual.color = Color(1, 0, 0, 0.6)
		zone.add_child(visual)
		
		zone.body_entered.connect(func(body):
			if body.is_in_group("player"):
				body.die()
		)
		
		add_child(zone)
		death_zones.append(zone)

func spawn_multi_clones():
	var enemy = preload("res://Scene/spikes.tscn").instantiate()
	enemy.position = Vector2(640, 400)
	enemy.modulate = Color.RED
	add_child(enemy)
	clones.append(enemy)
