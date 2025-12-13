extends Area2D

var is_locked = true

func _ready():
	body_entered.connect(_on_body_entered)

func unlock():
	is_locked = false
	if has_node("ColorRect"):
		$ColorRect.color = Color.GREEN

func _on_body_entered(body):
	if body.is_in_group("player") and not is_locked:
		# DAILY CHALLENGE MODE
		if GameState.is_daily_challenge:
			print("🎲 Daily challenge completed!")
			await GameState.complete_daily_challenge(GameState.current_bug)
			
			# Show completion screen with time
			show_daily_completion_screen()
			return
		
		# CAMPAIGN MODE
		if GameState.campaign_mode:
			# Mark bug as completed locally
			GameState.complete_bug(GameState.current_bug)
			
			# Mint NFT if wallet connected
			if GameState.wallet_connected:
				# Get full metadata for this bug from BugData
				var metadata = BugData.get_bug_metadata(GameState.current_bug)
				SolanaManager.mint_campaign_nft(GameState.current_bug, metadata)
			
			# Check if this was the last bug
			if GameState.current_bug >= 20:
				# Campaign complete!
				get_tree().change_scene_to_file("res://Scenes/CampaignComplete.tscn")
			else:
				# Go to next bug
				GameState.current_bug += 1
				get_tree().reload_current_scene()
		else:
			# Free play mode - just restart
			get_tree().reload_current_scene()

func show_daily_completion_screen():
	# Create popup showing completion time and tier
	var popup = Panel.new()
	popup.position = Vector2(300, 200)
	popup.size = Vector2(600, 400)
	popup.z_index = 100
	get_tree().root.add_child(popup)
	
	# Title
	var title = Label.new()
	title.text = "DAILY CHALLENGE COMPLETE!"
	title.position = Vector2(150, 30)
	title.add_theme_font_size_override("font_size", 32)
	popup.add_child(title)
	
	# Time
	var time_label = Label.new()
	var formatted_time = GameState.format_time(GameState.daily_completion_time)
	time_label.text = "Time: " + formatted_time
	time_label.position = Vector2(200, 120)
	time_label.add_theme_font_size_override("font_size", 24)
	popup.add_child(time_label)
	
	# Tier
	var tier = GameState.get_time_tier(GameState.daily_completion_time)
	var tier_label = Label.new()
	tier_label.text = "Tier: " + tier
	tier_label.position = Vector2(200, 170)
	tier_label.add_theme_font_size_override("font_size", 24)
	popup.add_child(tier_label)
	
	# Set tier color
	match tier:
		"Gold":
			tier_label.modulate = Color(1.0, 0.84, 0.0)  # Gold
		"Silver":
			tier_label.modulate = Color(0.75, 0.75, 0.75)  # Silver
		"Bronze":
			tier_label.modulate = Color(0.8, 0.5, 0.2)  # Bronze
		"Participant":
			tier_label.modulate = Color.WHITE
	
	# NFT Status
	var nft_label = Label.new()
	if GameState.wallet_connected:
		nft_label.text = "🎨 NFT Minting..."
	else:
		nft_label.text = "💰 Connect wallet to mint NFT"
	nft_label.position = Vector2(180, 220)
	nft_label.add_theme_font_size_override("font_size", 18)
	popup.add_child(nft_label)
	
	# Continue button
	var continue_btn = Button.new()
	continue_btn.text = "CONTINUE"
	continue_btn.position = Vector2(200, 300)
	continue_btn.size = Vector2(200, 60)
	continue_btn.pressed.connect(func(): 
		popup.queue_free()
		get_tree().change_scene_to_file("res://Scene/main_menu.tscn")
	)
	popup.add_child(continue_btn)
	
