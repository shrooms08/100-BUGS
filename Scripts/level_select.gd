extends Node2D

func _ready():
	GameState.load_progress()
	generate_bug_buttons()
	
	# Connect wallet button if it exists
	if has_node("WalletPanel/WalletButton"):
		$WalletPanel/WalletButton.pressed.connect(_on_wallet_button_pressed)
		update_wallet_ui()
	
	# Enable mobile touch
	enable_mobile_touch()
	
	# Debug
	print("Level select loaded")
	print("Mobile detected: ", check_if_mobile())

func check_if_mobile() -> bool:
	"""Detect if on mobile device"""
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

func enable_mobile_touch():
	"""Configure all buttons for mobile touch"""
	var is_mobile = check_if_mobile()
	
	if is_mobile or OS.has_feature("web"):
		print("Configuring level select for mobile")
		
		# Wait one frame for buttons to be created
		await get_tree().process_frame
		
		# Fix all bug buttons in grid
		if has_node("BugGrid"):
			var bug_grid = $BugGrid
			for child in bug_grid.get_children():
				if child is Button:
					child.mouse_filter = Control.MOUSE_FILTER_STOP
					child.focus_mode = Control.FOCUS_NONE
					# Make buttons bigger for mobile
					if child.custom_minimum_size.x < 150:
						child.custom_minimum_size = Vector2(200, 120)
					print("Bug button configured: ", child.text)
		
		# Fix wallet button
		if has_node("WalletPanel/WalletButton"):
			var wallet_btn = $WalletPanel/WalletButton
			wallet_btn.mouse_filter = Control.MOUSE_FILTER_STOP
			wallet_btn.focus_mode = Control.FOCUS_NONE
			if wallet_btn.custom_minimum_size.x < 200:
				wallet_btn.custom_minimum_size = Vector2(250, 70)
			print("Wallet button configured")

func generate_bug_buttons():
	var bug_names = {
		1: "Plain and Simple",
		2: "Go Back",
		3: "Weightless",
		4: "SLIPPERY!",
		5: "Don't trust your eyes",
		6: "What's wrong with gravity?",
		7: "Displaced",
		8: "Wait on it!",
		9: "Limited Resources",
		10: "Now you see it...",
		11: "Just Give Up",
		12: "Which way is down?",
		13: "Mirror World",
		14: "LAG",
		15: "Turbulence",
		16: "CHAOS",
		17: "New keys",
		18: "Blind",
		19: "Don't Touch It",
		20: "Inverted"
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
	print("Playing bug: ", bug_id)
	
	# Play sound if available
	if SfxManager:
		SfxManager._on_button_pressed()
	
	GameState.current_bug = bug_id
	GameState.campaign_mode = true
	get_tree().change_scene_to_file("res://Scene/main_room.tscn")

# Wallet UI functions
func _on_wallet_button_pressed():
	print("Wallet button pressed")
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
	"""Show popup to choose wallet"""
	print(" Showing wallet selection...")
	
	# Check which wallets are available
	var available = GameState.check_wallets_available()
	
	var popup = create_wallet_popup(available)
	add_child(popup)

func create_wallet_popup(available_wallets: Dictionary) -> Control:
	"""Create wallet selection popup"""
	var popup = Panel.new()
	popup.position = Vector2(400, 250)
	popup.size = Vector2(480, 350)
	popup.z_index = 100
	
	# Title
	var title = Label.new()
	title.text = "Select Wallet"
	title.position = Vector2(20, 20)
	title.add_theme_font_size_override("font_size", 24)
	popup.add_child(title)
	
	# Phantom button
	var phantom_btn = Button.new()
	phantom_btn.name = "PhantomButton"
	phantom_btn.text = "Phantom Wallet"
	if not available_wallets.get("phantom", false):
		phantom_btn.text += " (Not Installed)"
		phantom_btn.disabled = true
	phantom_btn.position = Vector2(40, 80)
	phantom_btn.size = Vector2(400, 50)
	phantom_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	phantom_btn.focus_mode = Control.FOCUS_NONE
	phantom_btn.pressed.connect(func(): connect_phantom_wallet(popup))
	popup.add_child(phantom_btn)
	
	# Solflare button
	var solflare_btn = Button.new()
	solflare_btn.name = "SolflareButton"
	solflare_btn.text = "Solflare Wallet"
	if not available_wallets.get("solflare", false):
		solflare_btn.text += " (Not Installed)"
		solflare_btn.disabled = true
	solflare_btn.position = Vector2(40, 150)
	solflare_btn.size = Vector2(400, 50)
	solflare_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	solflare_btn.focus_mode = Control.FOCUS_NONE
	solflare_btn.pressed.connect(func(): connect_solflare_wallet(popup))
	popup.add_child(solflare_btn)
	
	# Info text
	if not available_wallets.get("phantom", false) and not available_wallets.get("solflare", false):
		var info = Label.new()
		info.name = "InfoLabel"
		info.text = "Please install a Solana wallet:\n• Phantom: phantom.app\n• Solflare: solflare.com"
		info.position = Vector2(40, 220)
		info.add_theme_font_size_override("font_size", 14)
		popup.add_child(info)
	
	# Connecting label (initially hidden)
	var connecting_label = Label.new()
	connecting_label.name = "ConnectingLabel"
	connecting_label.text = "Connecting..."
	connecting_label.position = Vector2(40, 220)
	connecting_label.size = Vector2(400, 50)
	connecting_label.add_theme_font_size_override("font_size", 16)
	connecting_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	connecting_label.hide()
	popup.add_child(connecting_label)
	
	# Cancel button
	var cancel_btn = Button.new()
	cancel_btn.name = "CancelButton"
	cancel_btn.text = "Cancel"
	cancel_btn.position = Vector2(40, 280)
	cancel_btn.size = Vector2(400, 50)
	cancel_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	cancel_btn.focus_mode = Control.FOCUS_NONE
	cancel_btn.pressed.connect(func(): popup.queue_free())
	popup.add_child(cancel_btn)
	
	return popup

func connect_phantom_wallet(popup: Control):
	"""Connect to Phantom wallet - REAL"""
	print(" Connecting to Phantom...")
	
	# Hide buttons and show connecting message
	var phantom_btn = popup.get_node_or_null("PhantomButton")
	var solflare_btn = popup.get_node_or_null("SolflareButton")
	var cancel_btn = popup.get_node_or_null("CancelButton")
	var info_label = popup.get_node_or_null("InfoLabel")
	
	if phantom_btn:
		phantom_btn.hide()
	if solflare_btn:
		solflare_btn.hide()
	if cancel_btn:
		cancel_btn.hide()
	if info_label:
		info_label.hide()
	
	# Show connecting message
	var connecting_label = popup.get_node("ConnectingLabel")
	connecting_label.text = "Connecting to Phantom..."
	connecting_label.modulate = Color.WHITE
	connecting_label.show()
	
	# Call the REAL connection function
	var success = await GameState.connect_wallet_phantom()
	
	if success:
		print(" Phantom connected!")
		update_wallet_ui()
		popup.queue_free()
	else:
		print(" Failed to connect Phantom")
		connecting_label.text = "Connection failed.\nPlease try again."
		connecting_label.modulate = Color(1, 0.5, 0.5)
		# Show buttons again
		if phantom_btn:
			phantom_btn.show()
		if solflare_btn:
			solflare_btn.show()
		if cancel_btn:
			cancel_btn.show()

func connect_solflare_wallet(popup: Control):
	"""Connect to Solflare wallet - REAL"""
	print(" Connecting to Solflare...")
	
	# Hide buttons and show connecting message
	var phantom_btn = popup.get_node_or_null("PhantomButton")
	var solflare_btn = popup.get_node_or_null("SolflareButton")
	var cancel_btn = popup.get_node_or_null("CancelButton")
	var info_label = popup.get_node_or_null("InfoLabel")
	
	if phantom_btn:
		phantom_btn.hide()
	if solflare_btn:
		solflare_btn.hide()
	if cancel_btn:
		cancel_btn.hide()
	if info_label:
		info_label.hide()
	
	# Show connecting message
	var connecting_label = popup.get_node("ConnectingLabel")
	connecting_label.text = "Connecting to Solflare..."
	connecting_label.modulate = Color.WHITE
	connecting_label.show()
	
	var success = await GameState.connect_wallet_solflare()
	
	if success:
		print(" Solflare connected!")
		update_wallet_ui()
		popup.queue_free()
	else:
		print(" Failed to connect Solflare")
		connecting_label.text = "Connection failed.\nPlease try again."
		connecting_label.modulate = Color(1, 0.5, 0.5)
		# Show buttons again
		if phantom_btn:
			phantom_btn.show()
		if solflare_btn:
			solflare_btn.show()
		if cancel_btn:
			cancel_btn.show()

# Fallback touch handler
func _input(event):
	"""Direct touch detection if buttons don't respond"""
	if event is InputEventScreenTouch and event.pressed:
		var touch_pos = event.position
		print("Touch detected at: ", touch_pos)
		
		# Check bug buttons
		if has_node("BugGrid"):
			for child in $BugGrid.get_children():
				if child is Button and child.visible and not child.disabled:
					if button_contains_touch(child, touch_pos):
						print("Bug button touched: ", child.text)
						child.emit_signal("pressed")
						return
		
		# Check wallet button
		if has_node("WalletPanel/WalletButton"):
			var wallet_btn = $WalletPanel/WalletButton
			if button_contains_touch(wallet_btn, touch_pos):
				print("Wallet button touched")
				_on_wallet_button_pressed()
				return

func button_contains_touch(button: Control, touch_pos: Vector2) -> bool:
	"""Check if touch overlaps button"""
	if not button or not button.visible:
		return false
	var button_rect = button.get_global_rect()
	return button_rect.has_point(touch_pos)
