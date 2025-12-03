extends Node2D

func _ready():
	# Load campaign progress
	GameState.load_progress()
	
	# Connect buttons
	$StartButton.pressed.connect(_on_start_pressed)
	$WalletPanel/WalletButton.pressed.connect(_on_wallet_button_pressed)
	
	# Update wallet UI
	update_wallet_ui()

func _on_start_pressed():
	get_tree().change_scene_to_file("res://Scene/level_select.tscn")

func _on_wallet_button_pressed():
	if GameState.wallet_connected:
		# Disconnect wallet
		disconnect_wallet()
	else:
		# Show wallet selection popup
		show_wallet_selection()

func update_wallet_ui():
	if GameState.wallet_connected:
		# Show connected state
		$WalletPanel/WalletStatus.text = "Connected: " + GameState.get_short_address()
		$WalletPanel/WalletButton.text = "DISCONNECT"
		$WalletPanel/WalletButton.modulate = Color(1, 0.5, 0.5)  # Red tint
	else:
		# Show disconnected state
		$WalletPanel/WalletStatus.text = "No Wallet Connected"
		$WalletPanel/WalletButton.text = "CONNECT WALLET"
		$WalletPanel/WalletButton.modulate = Color.WHITE

func disconnect_wallet():
	GameState.disconnect_wallet()
	update_wallet_ui()
	print("Wallet disconnected")

func show_wallet_selection():
	# Create popup for wallet selection
	var popup = create_wallet_popup()
	add_child(popup)

func create_wallet_popup() -> Control:
	# Create modal popup
	var popup = Panel.new()
	popup.position = Vector2(400, 250)
	popup.size = Vector2(480, 300)
	popup.z_index = 100
	
	# Title
	var title = Label.new()
	title.text = "Select Wallet"
	title.position = Vector2(20, 20)
	title.add_theme_font_size_override("font_size", 24)
	popup.add_child(title)
	
	# Phantom button
	var phantom_btn = Button.new()
	phantom_btn.text = "Phantom Wallet"
	phantom_btn.position = Vector2(40, 80)
	phantom_btn.size = Vector2(400, 50)
	phantom_btn.pressed.connect(func(): connect_phantom_wallet(popup))
	popup.add_child(phantom_btn)
	
	# Solflare button
	var solflare_btn = Button.new()
	solflare_btn.text = "Solflare Wallet"
	solflare_btn.position = Vector2(40, 150)
	solflare_btn.size = Vector2(400, 50)
	solflare_btn.pressed.connect(func(): connect_solflare_wallet(popup))
	popup.add_child(solflare_btn)
	
	# Cancel button
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.position = Vector2(40, 220)
	cancel_btn.size = Vector2(400, 50)
	cancel_btn.pressed.connect(func(): popup.queue_free())
	popup.add_child(cancel_btn)
	
	return popup

func connect_phantom_wallet(popup: Control):
	# TODO: Actual Phantom wallet connection (placeholder for now)
	print("Connecting to Phantom...")
	
	# PLACEHOLDER: Simulate successful connection
	var fake_address = "7xKX" + str(randi() % 1000) + "..." + str(randi() % 1000)
	GameState.connect_wallet(fake_address, "phantom")
	
	update_wallet_ui()
	popup.queue_free()
	
	print("Phantom wallet connected: ", fake_address)

func connect_solflare_wallet(popup: Control):
	# TODO: Actual Solflare wallet connection (placeholder for now)
	print("Connecting to Solflare...")
	
	# PLACEHOLDER: Simulate successful connection
	var fake_address = "9zKY" + str(randi() % 1000) + "..." + str(randi() % 1000)
	GameState.connect_wallet(fake_address, "solflare")
	
	update_wallet_ui()
	popup.queue_free()
	
	print("Solflare wallet connected: ", fake_address)
