extends Node

var current_bug = 1

# Campaign progress
var campaign_unlocked_bugs = [1]
var campaign_completed_bugs = []
var campaign_mode = false

# Wallet connection
var wallet_connected = false
var wallet_address = ""
var wallet_type = ""  # "phantom", "solflare", etc.

# Daily Challenge (NEW)
var is_daily_challenge = false
var daily_start_time = 0
var daily_completion_time = 0.0
var last_daily_completed = ""  # Date string (YYYY-MM-DD)

# Save/Load functions
func save_progress():
	var save_data = {
		"unlocked": campaign_unlocked_bugs,
		"completed": campaign_completed_bugs,
		"wallet_address": wallet_address,
		"wallet_type": wallet_type,
		"last_daily_completed": last_daily_completed  # NEW
	}
	var save_file = FileAccess.open("user://campaign_save.dat", FileAccess.WRITE)
	save_file.store_var(save_data)
	save_file.close()

func load_progress():
	if FileAccess.file_exists("user://campaign_save.dat"):
		var save_file = FileAccess.open("user://campaign_save.dat", FileAccess.READ)
		var save_data = save_file.get_var()
		save_file.close()
		
		campaign_unlocked_bugs = save_data.get("unlocked", [1])
		campaign_completed_bugs = save_data.get("completed", [])
		wallet_address = save_data.get("wallet_address", "")
		wallet_type = save_data.get("wallet_type", "")
		last_daily_completed = save_data.get("last_daily_completed", "")  # NEW
		
		# If we have a saved wallet, mark as connected
		if wallet_address != "":
			wallet_connected = true

func unlock_bug(bug_id: int):
	if bug_id not in campaign_unlocked_bugs:
		campaign_unlocked_bugs.append(bug_id)
		save_progress()

func complete_bug(bug_id: int):
	if bug_id not in campaign_completed_bugs:
		campaign_completed_bugs.append(bug_id)
	
	if bug_id < 20:
		unlock_bug(bug_id + 1)
	
	save_progress()

func is_bug_unlocked(bug_id: int) -> bool:
	return bug_id in campaign_unlocked_bugs

func is_bug_completed(bug_id: int) -> bool:
	return bug_id in campaign_completed_bugs

func reset_campaign():
	campaign_unlocked_bugs = [1]
	campaign_completed_bugs = []
	save_progress()

# Wallet functions
func connect_wallet(address: String, type: String):
	wallet_connected = true
	wallet_address = address
	wallet_type = type
	save_progress()

func disconnect_wallet():
	wallet_connected = false
	wallet_address = ""
	wallet_type = ""
	save_progress()

func get_short_address() -> String:
	if wallet_address.length() > 10:
		return wallet_address.substr(0, 4) + "..." + wallet_address.substr(wallet_address.length() - 4, 4)
	return wallet_address

# Daily Challenge functions (NEW)
func start_daily_challenge():
	is_daily_challenge = true
	campaign_mode = false
	daily_start_time = Time.get_ticks_msec()
	print("🎲 Daily challenge started!")

func complete_daily_challenge(bug_id: int):
	if not is_daily_challenge:
		return
	
	# Calculate completion time
	daily_completion_time = (Time.get_ticks_msec() - daily_start_time) / 1000.0
	var today = get_today_string()
	
	print("✅ Daily challenge completed!")
	print("   Time: %.2f seconds" % daily_completion_time)
	print("   Tier: %s" % get_time_tier(daily_completion_time))
	
	# Mark today as completed
	last_daily_completed = today
	save_progress()
	
	# Submit to leaderboard (if API is connected)
	if wallet_connected:
		await SolanaManager.submit_daily_completion(bug_id, daily_completion_time)
		
		# Mint special daily NFT
		var tier = get_time_tier(daily_completion_time)
		await SolanaManager.mint_daily_challenge_nft(bug_id, daily_completion_time, tier)
	
	is_daily_challenge = false

func has_completed_today() -> bool:
	return last_daily_completed == get_today_string()

func get_today_string() -> String:
	var today = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [today.year, today.month, today.day]

func get_time_tier(time: float) -> String:
	# Define tier thresholds
	if time < 30.0:
		return "Gold"
	elif time < 60.0:
		return "Silver"
	elif time < 120.0:
		return "Bronze"
	else:
		return "Participant"

func format_time(seconds: float) -> String:
	var minutes = int(seconds / 60)
	var secs = int(seconds) % 60
	var millis = int((seconds - int(seconds)) * 100)
	return "%02d:%02d.%02d" % [minutes, secs, millis]

func reset_daily_challenge():
	is_daily_challenge = false
	daily_start_time = 0
	daily_completion_time = 0.0
