extends Node2D

# References to UI elements
@onready var start_button: Button = $StartButton
@onready var daily_button: Button = $DailyButton
@onready var wallet_button: Button = $WalletPanel/WalletButton

func _ready():
	# Start background music
	if MusicManager:
		MusicManager.play_menu_music()
	
	# Connect buttons
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	
	if daily_button:
		daily_button.pressed.connect(_on_daily_pressed)
	
	if wallet_button:
		wallet_button.pressed.connect(_on_wallet_pressed)
	
	# Update wallet button text
	update_wallet_ui()
	
	# MOBILE FIX: Enable touch mode on buttons
	enable_mobile_touch()
	
	# Debug info
	print("Main menu loaded")
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
	"""Ensure buttons work on mobile touch screens"""
	var is_mobile = check_if_mobile()
	
	print("Enabling mobile touch. Is mobile: ", is_mobile)
	
	if is_mobile or OS.has_feature("web"):
		if start_button:
			start_button.mouse_filter = Control.MOUSE_FILTER_STOP
			start_button.focus_mode = Control.FOCUS_NONE
			if start_button.custom_minimum_size.x < 200:
				start_button.custom_minimum_size = Vector2(300, 80)
			print("Start button configured: ", start_button.global_position, " Size: ", start_button.size)
		
		if daily_button:
			daily_button.mouse_filter = Control.MOUSE_FILTER_STOP
			daily_button.focus_mode = Control.FOCUS_NONE
			if daily_button.custom_minimum_size.x < 200:
				daily_button.custom_minimum_size = Vector2(300, 80)
			print("Daily button configured: ", daily_button.global_position, " Size: ", daily_button.size)
		
		if wallet_button:
			wallet_button.mouse_filter = Control.MOUSE_FILTER_STOP
			wallet_button.focus_mode = Control.FOCUS_NONE
			if wallet_button.custom_minimum_size.x < 200:
				wallet_button.custom_minimum_size = Vector2(250, 70)
			print("Wallet button configured: ", wallet_button.global_position, " Size: ", wallet_button.size)

func _on_start_pressed():
	print("Start button pressed")
	if SfxManager:
		SfxManager._on_button_pressed()
	
	get_tree().change_scene_to_file("res://Scene/level_select.tscn")

func _on_daily_pressed():
	print("Daily button pressed")
	if SfxManager:
		SfxManager._on_button_pressed()
	
	get_tree().change_scene_to_file("res://Scene/daily_challenge.tscn")

func _on_wallet_pressed():
	print("Wallet button pressed")
	if SfxManager:
		SfxManager._on_button_pressed()
	
	# Toggle wallet connection
	if GameState.wallet_connected:
		disconnect_wallet()
	else:
		show_wallet_selection()

# ==========================================
# REAL WALLET CONNECTION
# ==========================================

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
		print("Solflare connected!")
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

func disconnect_wallet():
	"""Disconnect wallet"""
	print(" Disconnecting wallet...")
	
	GameState.disconnect_wallet()
	update_wallet_ui()
	
	print(" Wallet disconnected!")

func update_wallet_ui():
	"""Update wallet button text"""
	if wallet_button:
		if GameState.wallet_connected:
			var short_addr = GameState.get_short_address()
			wallet_button.text = "Connected: " + short_addr
		else:
			wallet_button.text = "Connect Wallet"

# ==========================================
# TOUCH INPUT FALLBACK
# ==========================================

func _input(event):
	"""Fallback touch handling in case buttons don't respond"""
	if event is InputEventScreenTouch and event.pressed:
		var touch_pos = event.position
		print("Touch detected at: ", touch_pos)
		
		check_button_touch(start_button, touch_pos, _on_start_pressed)
		check_button_touch(daily_button, touch_pos, _on_daily_pressed)
		check_button_touch(wallet_button, touch_pos, _on_wallet_pressed)

func check_button_touch(button: Button, touch_pos: Vector2, callback: Callable):
	"""Check if touch position overlaps button and call callback"""
	if not button or not button.visible:
		return
	
	var button_rect = button.get_global_rect()
	
	print("Checking button: ", button.name)
	print("  Button rect: ", button_rect)
	print("  Touch pos: ", touch_pos)
	print("  Contains touch: ", button_rect.has_point(touch_pos))
	
	if button_rect.has_point(touch_pos):
		print("Button touched: ", button.name)
		callback.call()
