# daily_challenge.gd
extends Node2D

var current_bug_id = 1
var time_until_reset = 0

func _ready():
	# Fetch today's bug from API
	var bug_id = await SolanaManager.get_todays_bug()
	current_bug_id = bug_id
	
	print("Today's bug: #", bug_id)
	
	# Display bug info
	update_ui()
	
	# Start countdown timer
	start_countdown()
	
	# Connect buttons
	$PlayButton.pressed.connect(_on_play_pressed)
	$BackButton.pressed.connect(_on_back_pressed)

func update_ui():
	# Get bug metadata
	var metadata = BugData.get_bug_metadata(current_bug_id)
	
	$BugTitle.text = metadata.name
	$BugDescription.text = metadata.description
	#$DifficultyLabel.text = "Difficulty: " + metadata.difficulty
	
	# Show bug image if you have one
	if metadata.has("image_path"):
		$BugImage.texture = load(metadata.image_path)

func start_countdown():
	# Calculate time until midnight UTC
	var now = Time.get_unix_time_from_system()
	var today_midnight = floor(now / 86400) * 86400
	var tomorrow_midnight = today_midnight + 86400
	time_until_reset = tomorrow_midnight - now
	
	# Update countdown every second
	while time_until_reset > 0:
		update_countdown_display()
		await get_tree().create_timer(1.0).timeout
		time_until_reset -= 1

func update_countdown_display():
	var time_remaining = int(time_until_reset)  # Convert to int first!
	var hours = int(time_remaining / 3600)
	var minutes = int((time_remaining % 3600) / 60)
	var seconds = int(time_remaining % 60)
	
	$CountdownLabel.text = "New challenge in: %02d:%02d:%02d" % [hours, minutes, seconds]

func _on_play_pressed():
	# Load the daily bug level
	GameState.current_bug_id = current_bug_id
	GameState.start_daily_challenge()  # Flag for special handling
	get_tree().change_scene_to_file("res://Scene/main_room.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")
