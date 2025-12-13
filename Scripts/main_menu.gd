extends Node2D

func _ready():
	# Test API connection when game starts
	print("🚀 Starting game...")
	
	var connected = await SolanaManager.test_connection()
	if connected:
		print("✅ Ready to mint NFTs!")
		# Show success indicator (optional)
		if has_node("WalletPanel/APIStatus"):
			$WalletPanel/APIStatus.text = "● API Connected"
			$WalletPanel/APIStatus.modulate = Color.GREEN
	else:
		print("⚠️  API not connected - NFT minting disabled")
		print("   Make sure server is running: npm start")
		# Show warning indicator (optional)
		if has_node("WalletPanel/APIStatus"):
			$WalletPanel/APIStatus.text = "● API Offline"
			$WalletPanel/APIStatus.modulate = Color.RED
	
	# Load campaign progress
	GameState.load_progress()
	
	# Connect buttons
	$StartButton.pressed.connect(_on_start_pressed)
	$DailyButton.pressed.connect(_on_daily_pressed)  # NEW
	$WalletPanel/WalletButton.pressed.connect(_on_wallet_button_pressed)
	
	# Update UI
	update_wallet_ui()
	update_daily_ui()  # NEW

func _on_start_pressed():
	get_tree().change_scene_to_file("res://Scene/level_select.tscn")

# NEW: Daily Challenge
func _on_daily_pressed():
	print("🎲 Opening Daily Challenge...")
	get_tree().change_scene_to_file("res://Scene/daily_challenge.tscn")

func _on_wallet_button_pressed():
	if GameState.wallet_connected:
		disconnect_wallet()
	else:
		show_wallet_selection()

func update_wallet_ui():
	if GameState.wallet_connected:
		$WalletPanel/WalletStatus.text = "Connected: " + GameState.get_short_address()
		$WalletPanel/WalletButton.text = "DISCONNECT"
		$WalletPanel/WalletButton.modulate = Color(1, 0.5, 0.5)
	else:
		$WalletPanel/WalletStatus.text = "No Wallet Connected"
		$WalletPanel/WalletButton.text = "CONNECT WALLET"
		$WalletPanel/WalletButton.modulate = Color.WHITE

# NEW: Update daily challenge button
func update_daily_ui():
	if not has_node("DailyButton"):
		return
	
	var today = Time.get_datetime_dict_from_system()
	var day_text = "%02d/%02d/%d" % [today.month, today.day, today.year]
	
	# Update date label if it exists
	if has_node("DailyButton/DateLabel"):
		$DailyButton/DateLabel.text = "TODAY: " + day_text
	
	# Calculate time until reset
	var time_until_reset = get_time_until_reset()
	var hours = int(time_until_reset / 3600)
	var minutes = int((time_until_reset % 3600) / 60)
	
	if has_node("DailyButton/TimerLabel"):
		$DailyButton/TimerLabel.text = "Resets in: %02d:%02d" % [hours, minutes]

# NEW: Calculate seconds until midnight UTC
func get_time_until_reset() -> int:
	var now = Time.get_unix_time_from_system()
	var today_midnight = floor(now / 86400) * 86400
	var tomorrow_midnight = today_midnight + 86400
	return int(tomorrow_midnight - now)

func disconnect_wallet():
	GameState.disconnect_wallet()
	update_wallet_ui()
	print("🔌 Wallet disconnected")

func show_wallet_selection():
	var popup = create_wallet_popup()
	add_child(popup)

func create_wallet_popup() -> Control:
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
	phantom_btn.text = "🦊 Phantom Wallet"
	phantom_btn.position = Vector2(40, 80)
	phantom_btn.size = Vector2(400, 50)
	phantom_btn.pressed.connect(func(): connect_phantom_wallet(popup))
	popup.add_child(phantom_btn)
	
	# Solflare button
	var solflare_btn = Button.new()
	solflare_btn.text = "☀️ Solflare Wallet"
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
	print("🦊 Connecting to Phantom...")
	
	var fake_address = "7xKX" + str(randi() % 1000) + "..." + str(randi() % 1000)
	GameState.connect_wallet(fake_address, "phantom")
	
	update_wallet_ui()
	popup.queue_free()
	
	print("✅ Phantom wallet connected: ", fake_address)

func connect_solflare_wallet(popup: Control):
	print("☀️ Connecting to Solflare...")
	
	var fake_address = "9zKY" + str(randi() % 1000) + "..." + str(randi() % 1000)
	GameState.connect_wallet(fake_address, "solflare")
	
	update_wallet_ui()
	popup.queue_free()
	
	print("✅ Solflare wallet connected: ", fake_address)
