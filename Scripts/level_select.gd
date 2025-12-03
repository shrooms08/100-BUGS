extends Node2D

func _ready():
	GameState.load_progress()
	generate_bug_buttons()
	
	# Connect wallet button if it exists
	if has_node("WalletPanel/WalletButton"):
		$WalletPanel/WalletButton.pressed.connect(_on_wallet_button_pressed)
		update_wallet_ui()

func generate_bug_buttons():
	var bug_names = {
		1: "Plain and Simple",
		2: "Ghost Wall",
		3: "Low Gravity",
		4: "Slippery Floor",
		5: "Invisible Button",
		6: "Play with Gravity",
		7: "Hitbox Offset",
		8: "Stay on It",
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
	
	# Create 20 bug buttons dynamically
	for i in range(1, 21):
		var button = Button.new()
		button.text = "Bug #%d" % i
		button.custom_minimum_size = Vector2(180, 100)
		
		# Check if unlocked
		var is_unlocked = GameState.is_bug_unlocked(i)
		var is_completed = GameState.is_bug_completed(i)
		
		if is_completed:
			button.modulate = Color.GREEN  # Completed = green
		elif is_unlocked:
			button.modulate = Color.WHITE  # Unlocked = white
		else:
			button.modulate = Color.DARK_GRAY  # Locked = gray
			button.disabled = true
		
		# Add bug name as tooltip
		button.tooltip_text = bug_names.get(i, "Bug")
		
		# Connect button press
		var bug_id = i  # Capture in closure
		button.pressed.connect(func(): play_bug(bug_id))
		
		$BugGrid.add_child(button)

func play_bug(bug_id: int):
	GameState.current_bug = bug_id
	GameState.campaign_mode = true
	get_tree().change_scene_to_file("res://Scene/main_room.tscn")

# Wallet UI functions (NEW)
func _on_wallet_button_pressed():
	if GameState.wallet_connected:
		disconnect_wallet()
	else:
		show_wallet_selection()

func update_wallet_ui():
	if has_node("WalletPanel/WalletStatus") and has_node("WalletPanel/WalletButton"):
		if GameState.wallet_connected:
			$WalletPanel/WalletStatus.text = "Connected: " + GameState.get_short_address()
			$WalletPanel/WalletButton.text = "DISCONNECT"
			$WalletPanel/WalletButton.modulate = Color(1, 0.5, 0.5)
		else:
			$WalletPanel/WalletStatus.text = "No Wallet Connected"
			$WalletPanel/WalletButton.text = "CONNECT WALLET"
			$WalletPanel/WalletButton.modulate = Color.WHITE

func disconnect_wallet():
	GameState.disconnect_wallet()
	update_wallet_ui()

func show_wallet_selection():
	var popup = create_wallet_popup()
	add_child(popup)

func create_wallet_popup() -> Control:
	var popup = Panel.new()
	popup.position = Vector2(400, 250)
	popup.size = Vector2(480, 300)
	popup.z_index = 100
	
	var title = Label.new()
	title.text = "Select Wallet"
	title.position = Vector2(20, 20)
	title.add_theme_font_size_override("font_size", 24)
	popup.add_child(title)
	
	var phantom_btn = Button.new()
	phantom_btn.text = "Phantom Wallet"
	phantom_btn.position = Vector2(40, 80)
	phantom_btn.size = Vector2(400, 50)
	phantom_btn.pressed.connect(func(): connect_phantom_wallet(popup))
	popup.add_child(phantom_btn)
	
	var solflare_btn = Button.new()
	solflare_btn.text = "Solflare Wallet"
	solflare_btn.position = Vector2(40, 150)
	solflare_btn.size = Vector2(400, 50)
	solflare_btn.pressed.connect(func(): connect_solflare_wallet(popup))
	popup.add_child(solflare_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.position = Vector2(40, 220)
	cancel_btn.size = Vector2(400, 50)
	cancel_btn.pressed.connect(func(): popup.queue_free())
	popup.add_child(cancel_btn)
	
	return popup

func connect_phantom_wallet(popup: Control):
	print("Connecting to Phantom...")
	var fake_address = "7xKX" + str(randi() % 1000) + "..." + str(randi() % 1000)
	GameState.connect_wallet(fake_address, "phantom")
	update_wallet_ui()
	popup.queue_free()

func connect_solflare_wallet(popup: Control):
	print("Connecting to Solflare...")
	var fake_address = "9zKY" + str(randi() % 1000) + "..." + str(randi() % 1000)
	GameState.connect_wallet(fake_address, "solflare")
	update_wallet_ui()
	popup.queue_free()
