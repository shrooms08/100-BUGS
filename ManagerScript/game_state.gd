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

# Daily Challenge
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
		"last_daily_completed": last_daily_completed
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
		last_daily_completed = save_data.get("last_daily_completed", "")
		
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

# ==========================================
# REAL WALLET CONNECTION FUNCTIONS
# ==========================================

func connect_wallet_phantom():
	"""Connect to Phantom wallet - REAL BLOCKCHAIN"""
	print("🔵Attempting Phantom connection...")
	
	if OS.has_feature("web"):
		# Check if Phantom is installed
		var has_phantom = JavaScriptBridge.eval("window.solana && window.solana.isPhantom", true)
		
		if not has_phantom:
			print(" Phantom wallet not installed")
			return false
		
		# Initialize connection result storage
		JavaScriptBridge.eval("window._phantomConnectionResult = null;", true)
		
		# Call JavaScript wallet connection and store result
		JavaScriptBridge.eval("""
			(async () => {
				try {
					const result = await window.connectPhantom();
					window._phantomConnectionResult = result;
					console.log('Phantom connection result stored:', result);
				} catch (error) {
					console.error('Phantom error:', error);
					window._phantomConnectionResult = JSON.stringify({
						success: false,
						error: error.message || "Connection failed"
					});
				}
			})();
		""", true)
		
		# Poll for connection result (max 10 seconds)
		var max_attempts = 50
		var attempt = 0
		while attempt < max_attempts:
			await get_tree().create_timer(0.2).timeout
			
			var result_str = JavaScriptBridge.eval("window._phantomConnectionResult", true)
			if result_str and result_str != "null":
				var result = JSON.parse_string(result_str)
				if result:
					if result.get("success", false):
						wallet_connected = true
						wallet_address = result.get("address", "")
						wallet_type = "phantom"
						save_progress()
						print(" Phantom connected:", wallet_address)
						# Clean up
						JavaScriptBridge.eval("window._phantomConnectionResult = null;", true)
						return true
					else:
						print(" Phantom connection failed: ", result.get("error", "Unknown error"))
						JavaScriptBridge.eval("window._phantomConnectionResult = null;", true)
						return false
			
			attempt += 1
		
		# Timeout - check wallet state as fallback
		var state_str = JavaScriptBridge.eval("JSON.stringify(window.walletState)", true)
		if state_str:
			var state = JSON.parse_string(state_str)
			if state and state.get("connected", false) and state.get("provider") == "phantom":
				wallet_connected = true
				wallet_address = state.get("address", "")
				wallet_type = "phantom"
				save_progress()
				print(" Phantom connected (fallback check):", wallet_address)
				return true
		
		print(" Phantom connection timeout")
		JavaScriptBridge.eval("window._phantomConnectionResult = null;", true)
		return false
	else:
		# Desktop testing - fake connection
		wallet_connected = true
		wallet_address = "G253T2aiwYAoTT45a4W26HCfwn9EP3FJsanG9bCV6t4M"
		wallet_type = "phantom"
		save_progress()
		print(" Fake Phantom connected (desktop)")
		return true

func connect_wallet_solflare():
	"""Connect to Solflare wallet - REAL BLOCKCHAIN"""
	print(" Attempting Solflare connection...")
	
	if OS.has_feature("web"):
		# Check if Solflare is installed
		var has_solflare = JavaScriptBridge.eval("window.solflare && window.solflare.isSolflare", true)
		
		if not has_solflare:
			print(" Solflare wallet not installed")
			return false
		
		# Initialize connection result storage
		JavaScriptBridge.eval("window._solflareConnectionResult = null;", true)
		
		# Call JavaScript wallet connection and store result
		JavaScriptBridge.eval("""
			(async () => {
				try {
					const result = await window.connectSolflare();
					window._solflareConnectionResult = result;
					console.log('Solflare connection result stored:', result);
				} catch (error) {
					console.error('Solflare error:', error);
					window._solflareConnectionResult = JSON.stringify({
						success: false,
						error: error.message || "Connection failed"
					});
				}
			})();
		""", true)
		
		# Poll for connection result (max 10 seconds)
		var max_attempts = 50
		var attempt = 0
		while attempt < max_attempts:
			await get_tree().create_timer(0.2).timeout
			
			var result_str = JavaScriptBridge.eval("window._solflareConnectionResult", true)
			if result_str and result_str != "null":
				var result = JSON.parse_string(result_str)
				if result:
					if result.get("success", false):
						wallet_connected = true
						wallet_address = result.get("address", "")
						wallet_type = "solflare"
						save_progress()
						print(" Solflare connected:", wallet_address)
						# Clean up
						JavaScriptBridge.eval("window._solflareConnectionResult = null;", true)
						return true
					else:
						print(" Solflare connection failed: ", result.get("error", "Unknown error"))
						JavaScriptBridge.eval("window._solflareConnectionResult = null;", true)
						return false
			
			attempt += 1
		
		# Timeout - check wallet state as fallback
		var state_str = JavaScriptBridge.eval("JSON.stringify(window.walletState)", true)
		if state_str:
			var state = JSON.parse_string(state_str)
			if state and state.get("connected", false) and state.get("provider") == "solflare":
				wallet_connected = true
				wallet_address = state.get("address", "")
				wallet_type = "solflare"
				save_progress()
				print(" Solflare connected (fallback check):", wallet_address)
				return true
		
		print(" Solflare connection timeout")
		JavaScriptBridge.eval("window._solflareConnectionResult = null;", true)
		return false
	else:
		# Desktop testing
		wallet_connected = true
		wallet_address = "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU"
		wallet_type = "solflare"
		save_progress()
		print(" Fake Solflare connected (desktop)")
		return true

func disconnect_wallet():
	"""Disconnect wallet"""
	print(" Disconnecting wallet...")
	
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.disconnectWallet()", true)
	
	wallet_connected = false
	wallet_address = ""
	wallet_type = ""
	save_progress()
	
	print(" Wallet disconnected")

func check_wallets_available() -> Dictionary:
	"""Check which wallets are installed"""
	if OS.has_feature("web"):
		var result_str = JavaScriptBridge.eval("JSON.stringify(window.checkWallets())", true)
		if result_str:
			var wallets = JSON.parse_string(result_str)
			print("Available wallets:", wallets)
			return wallets
	return {"phantom": false, "solflare": false}

# Legacy function - redirects to new functions
func connect_wallet(address: String, type: String):
	"""Legacy function for backwards compatibility"""
	wallet_connected = true
	wallet_address = address
	wallet_type = type
	save_progress()

func get_short_address() -> String:
	if wallet_address.length() > 10:
		return wallet_address.substr(0, 4) + "..." + wallet_address.substr(wallet_address.length() - 4, 4)
	return wallet_address

# ==========================================
# DAILY CHALLENGE FUNCTIONS
# ==========================================

func start_daily_challenge():
	is_daily_challenge = true
	campaign_mode = false
	daily_start_time = Time.get_ticks_msec()
	print(" Daily challenge started!")

func complete_daily_challenge(bug_id: int):
	if not is_daily_challenge:
		return
	
	# Calculate completion time
	daily_completion_time = (Time.get_ticks_msec() - daily_start_time) / 1000.0
	var today = get_today_string()
	
	print(" Daily challenge completed!")
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
