extends Node

# API Configuration
const API_URL = "http://localhost:3000"
const COLLECTION_ADDRESS = "3ZQPh5QRLuGfNhY3hbCC8e5AYiLEaWaFoYVxdvTpz9gi"

# ==================== CAMPAIGN MODE ====================

# Campaign NFT minting
func mint_campaign_nft(bug_id: int, metadata: Dictionary):
	if not GameState.wallet_connected:
		print("ERROR: No wallet connected")
		return false
	
	print("🎨 Minting Campaign NFT via API:")
	print("  - Wallet: ", GameState.wallet_address)
	print("  - Bug ID: ", bug_id)
	print("  - Name: ", metadata.get("name", "Unknown Bug"))
	print("  - Description: ", metadata.get("description", ""))
	print("  - Image URI: ", metadata.get("image_uri", ""))
	print("  - Difficulty: ", metadata.get("difficulty", "Unknown"))
	print("  - Collection: ", COLLECTION_ADDRESS)
	
	# Create HTTP request
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_mint_nft_completed)
	
	# Prepare request body
	var body = {
		"wallet": GameState.wallet_address,
		"bugId": bug_id,
		"name": metadata.get("name", "Unknown Bug"),
		"description": metadata.get("description", ""),
		"imageUri": metadata.get("image_uri", ""),
		"difficulty": metadata.get("difficulty", "Unknown"),
		"collectionAddress": COLLECTION_ADDRESS
	}
	
	var headers = ["Content-Type: application/json"]
	var error = http.request(
		API_URL + "/mint-campaign-nft",
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)
	
	if error != OK:
		print("❌ HTTP Request failed: ", error)
		http.queue_free()
		return false
	
	# Wait for response
	await http.request_completed
	return true

func _on_mint_nft_completed(result, response_code, headers, body):
	var http_node = get_node_or_null("HTTPRequest")
	if http_node:
		http_node.queue_free()
	
	if response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		
		if parse_result == OK:
			var response = json.data
			if response.get("success", false):
				print("✅ Campaign NFT minted successfully!")
				print("   NFT Address: ", response.get("nftAddress", ""))
				print("   Transaction: ", response.get("transaction", ""))
			else:
				print("❌ Mint failed: ", response.get("error", "Unknown error"))
		else:
			print("❌ Failed to parse JSON response")
	else:
		print("❌ API returned error code: ", response_code)
		print("   Response: ", body.get_string_from_utf8())

# Check if player has completed a bug in campaign
func has_completed_bug(bug_id: int) -> bool:
	if not GameState.wallet_connected:
		return GameState.is_bug_completed(bug_id)
	
	print("🔍 Checking if bug #", bug_id, " is completed via API...")
	
	# Create HTTP request
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = API_URL + "/has-completed-bug/" + GameState.wallet_address + "/" + str(bug_id)
	var error = http.request(url)
	
	if error != OK:
		print("❌ HTTP Request failed: ", error)
		http.queue_free()
		return GameState.is_bug_completed(bug_id)
	
	# Wait for response
	var response = await http.request_completed
	http.queue_free()
	
	if response[1] == 200:
		var json = JSON.new()
		var parse_result = json.parse(response[3].get_string_from_utf8())
		
		if parse_result == OK:
			var data = json.data
			var completed = data.get("completed", false)
			print("   Result: ", "Completed" if completed else "Not completed")
			return completed
	
	# Fallback to local state
	return GameState.is_bug_completed(bug_id)

# Get player progress for entire campaign
func get_player_progress():
	if not GameState.wallet_connected:
		print("ERROR: No wallet connected")
		return null
	
	print("📊 Getting player progress from API...")
	
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = API_URL + "/player-progress/" + GameState.wallet_address
	var error = http.request(url)
	
	if error != OK:
		print("❌ HTTP Request failed: ", error)
		http.queue_free()
		return null
	
	var response = await http.request_completed
	http.queue_free()
	
	if response[1] == 200:
		var json = JSON.new()
		var parse_result = json.parse(response[3].get_string_from_utf8())
		
		if parse_result == OK:
			var data = json.data
			print("✅ Player progress retrieved")
			return data.get("progress")
	
	print("❌ Failed to get player progress")
	return null

# Get campaign statistics
func get_campaign_stats(campaign_id: int = 2):
	print("📊 Getting campaign stats...")
	
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = API_URL + "/campaign-stats/" + str(campaign_id)
	var error = http.request(url)
	
	if error != OK:
		print("❌ HTTP Request failed: ", error)
		http.queue_free()
		return null
	
	var response = await http.request_completed
	http.queue_free()
	
	if response[1] == 200:
		var json = JSON.new()
		var parse_result = json.parse(response[3].get_string_from_utf8())
		
		if parse_result == OK:
			var data = json.data
			print("✅ Campaign stats retrieved")
			return data.get("stats")
	
	print("❌ Failed to get campaign stats")
	return null

# ==================== DAILY CHALLENGE ====================

# Get today's daily challenge bug
func get_todays_bug() -> int:
	print("🎲 Fetching today's bug from API...")
	
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = API_URL + "/daily-bug"
	var error = http.request(url)
	
	if error != OK:
		print("❌ HTTP Request failed: ", error)
		http.queue_free()
		# Fallback to local random
		var random_bug = (randi() % 20) + 1
		print("⚠️  Using fallback random bug: #", random_bug)
		return random_bug
	
	var response = await http.request_completed
	http.queue_free()
	
	if response[1] == 200:
		var json = JSON.new()
		var parse_result = json.parse(response[3].get_string_from_utf8())
		
		if parse_result == OK:
			var data = json.data
			var bug_id = data.get("bugId", 1)
			print("✅ Today's bug: #", bug_id)
			return bug_id
	
	# Fallback
	var random_bug = (randi() % 20) + 1
	print("⚠️  Using fallback random bug: #", random_bug)
	return random_bug

# Daily challenge NFT minting
func mint_daily_challenge_nft(bug_id: int, completion_time: float, tier: String):
	if not GameState.wallet_connected:
		print("ERROR: No wallet connected")
		return false
	
	print("🏆 Minting Daily Challenge NFT:")
	print("  - Wallet: ", GameState.wallet_address)
	print("  - Bug #", bug_id)
	print("  - Time: ", completion_time, "s")
	print("  - Tier: ", tier)
	
	# TODO: Add daily challenge NFT endpoint when dev implements it
	# For now, just simulate success
	await get_tree().create_timer(1.0).timeout
	print("✅ Daily Challenge NFT minted successfully!")
	return true

# Submit daily challenge completion
func submit_daily_completion(bug_id: int, completion_time: float):
	if not GameState.wallet_connected:
		print("ERROR: No wallet connected")
		return
	
	print("📊 Submitting daily completion:")
	print("  - Bug #", bug_id)
	print("  - Time: ", completion_time, "s")
	
	# TODO: Add leaderboard endpoint when dev implements it
	await get_tree().create_timer(0.5).timeout
	print("✅ Completion submitted to leaderboard!")

# Get daily challenge leaderboard
func get_daily_leaderboard(bug_id: int) -> Array:
	print("📋 Fetching leaderboard for bug #", bug_id)
	
	# TODO: Add leaderboard endpoint when dev implements it
	# For now, return mock data
	await get_tree().create_timer(0.5).timeout
	var fake_leaderboard = [
		{"wallet": "7xKX123...456", "time": 45.2, "rank": 1},
		{"wallet": "9zYW789...012", "time": 52.8, "rank": 2},
		{"wallet": "3aBC345...678", "time": 61.5, "rank": 3}
	]
	print("✅ Leaderboard fetched: ", fake_leaderboard.size(), " entries")
	return fake_leaderboard

# ==================== HELPER FUNCTIONS ====================

# Test API connection
func test_connection() -> bool:
	print("🔌 Testing API connection...")
	
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = API_URL + "/health"
	var error = http.request(url)
	
	if error != OK:
		print("❌ Connection test failed: ", error)
		http.queue_free()
		return false
	
	var response = await http.request_completed
	http.queue_free()
	
	if response[1] == 200:
		print("✅ API connection successful!")
		return true
	else:
		print("❌ API returned error code: ", response[1])
		return false
