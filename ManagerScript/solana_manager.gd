extends Node

# API Configuration
const API_URL = "http://localhost:3000"

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
	print("  - Timestamp: ", Time.get_datetime_string_from_system())
	
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
		"difficulty": metadata.get("difficulty", "Unknown")
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
			else:
				print("❌ Mint failed: ", response.get("error", "Unknown error"))
		else:
			print("❌ Failed to parse JSON response")
	else:
		print("❌ API returned error code: ", response_code)
		print("   Response: ", body.get_string_from_utf8())

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
	
	# TODO: Add daily challenge endpoint to API
	# For now, just simulate
	await get_tree().create_timer(1.0).timeout
	print("✅ Daily Challenge NFT minted successfully!")
	return true

# Get today's daily challenge bug
func get_todays_bug() -> int:
	print("🎲 Fetching today's bug from VRF...")
	
	# TODO: Add VRF endpoint to API
	await get_tree().create_timer(0.5).timeout
	var random_bug = (randi() % 20) + 1
	print("✅ Today's bug: #", random_bug)
	return random_bug

# Submit daily challenge completion
func submit_daily_completion(bug_id: int, completion_time: float):
	if not GameState.wallet_connected:
		print("ERROR: No wallet connected")
		return
	
	print("📊 Submitting daily completion:")
	print("  - Bug #", bug_id)
	print("  - Time: ", completion_time, "s")
	
	# TODO: Add leaderboard endpoint to API
	await get_tree().create_timer(0.5).timeout
	print("✅ Completion submitted to leaderboard!")

# Get daily challenge leaderboard
func get_daily_leaderboard(bug_id: int) -> Array:
	print("📋 Fetching leaderboard for bug #", bug_id)
	
	# TODO: Add leaderboard endpoint to API
	await get_tree().create_timer(0.5).timeout
	var fake_leaderboard = [
		{"wallet": "7xKX123...456", "time": 45.2, "rank": 1},
		{"wallet": "9zYW789...012", "time": 52.8, "rank": 2},
		{"wallet": "3aBC345...678", "time": 61.5, "rank": 3}
	]
	print("✅ Leaderboard fetched: ", fake_leaderboard.size(), " entries")
	return fake_leaderboard

# Check if player has completed a bug in campaign
func has_completed_bug(bug_id: int) -> bool:
	if not GameState.wallet_connected:
		return false
	
	print("🔍 Checking if bug #", bug_id, " is completed via API...")
	
	# Create HTTP request
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = API_URL + "/has-completed-bug/" + GameState.wallet_address + "/" + str(bug_id)
	var error = http.request(url)
	
	if error != OK:
		print("❌ HTTP Request failed: ", error)
		http.queue_free()
		# Fallback to local state
		return GameState.is_bug_completed(bug_id)
	
	# Wait for response
	var response = await http.request_completed
	http.queue_free()
	
	if response[1] == 200:
		var json = JSON.new()
		var parse_result = json.parse(response[3].get_string_from_utf8())
		
		if parse_result == OK:
			var data = json.data
			return data.get("completed", false)
	
	# Fallback to local state
	return GameState.is_bug_completed(bug_id)
