extends Area2D

var is_locked = true
var _completing = false  # guards against re-entry while a mint is in flight

# Animation
@onready var door_sprite: AnimatedSprite2D = $DoorSprite


func _ready():
	body_entered.connect(_on_body_entered)
	
	# Start with closed door animation
	if door_sprite:
		door_sprite.play("closed")

func unlock():
	is_locked = false
	
	# Play door open animation
	if door_sprite:
		door_sprite.play("open")
	
	## Optional: Keep ColorRect for backward compatibility
	#if has_node("ColorRect"):
		#$ColorRect.color = Color.GREEN

func lock():
	is_locked = true
	
	# Play door close animation
	if door_sprite:
		door_sprite.play("closed")
	
	## Optional: Keep ColorRect for backward compatibility
	#if has_node("ColorRect"):
		#$ColorRect.color = Color.RED

func _on_body_entered(body):
	if body.is_in_group("player") and not is_locked and not _completing:
		_completing = true

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

			# Mint NFT if wallet connected — surface the outcome to the player
			# instead of firing and forgetting. mint_campaign_nft returns
			# true only on a confirmed on-chain mint.
			if GameState.wallet_connected:
				var metadata = BugData.get_bug_metadata(GameState.current_bug)
				show_status_notice("Minting Bug #%d NFT…" % GameState.current_bug, false)
				var minted = await SolanaManager.mint_campaign_nft(GameState.current_bug, metadata)
				if minted:
					show_status_notice("NFT minted! ✅", false)
				else:
					# covers both mint rejection and API/fetch failure
					show_status_notice("Mint unavailable — progress saved locally ⚠️", true)
				await get_tree().create_timer(1.5).timeout

			# These scene changes run inside the body_entered PHYSICS callback.
			# Freeing CollisionObjects mid-callback is illegal in Godot, so
			# defer them to the idle frame.
			if GameState.current_bug >= 20:
				# Campaign complete!
				get_tree().change_scene_to_file.call_deferred("res://Scene/campaign_complete.tscn")
			else:
				# Go to next bug
				GameState.current_bug += 1
				get_tree().call_deferred("reload_current_scene")
		else:
			# Free play mode - just restart (deferred: physics callback)
			get_tree().call_deferred("reload_current_scene")

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

# Transient on-screen notice for mint status and fetch failures, so the
# player is never left staring at a silent screen. Green for info, red for
# errors. Auto-dismisses; safe to call from a physics callback (adds to the
# scene tree root, not this Area2D).
func show_status_notice(msg: String, is_error: bool):
	var label = Label.new()
	label.text = msg
	label.add_theme_font_size_override("font_size", 26)
	label.modulate = Color(1.0, 0.5, 0.5) if is_error else Color(0.6, 1.0, 0.6)
	label.position = Vector2(340, 40)
	label.z_index = 200
	get_tree().root.add_child(label)
	var timer = get_tree().create_timer(4.0)
	timer.timeout.connect(func():
		if is_instance_valid(label):
			label.queue_free()
	)
