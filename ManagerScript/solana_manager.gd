extends Node

# API base URL — single source of truth.
# On web builds it comes from window.API_CONFIG.BASE_URL (config.js), the
# same value wallet.js uses. On desktop there is no browser config, so we
# fall back to this constant (edit for local desktop testing only).
const DESKTOP_API_FALLBACK = "http://localhost:3100"

var _api_base_cache := ""

func _ready():
	print("🚀 Solana Manager initialized - running health check...")
	test_connection()

func api_base() -> String:
	if _api_base_cache != "":
		return _api_base_cache
	if OS.has_feature("web"):
		var url = JavaScriptBridge.eval("(window.API_CONFIG && window.API_CONFIG.BASE_URL) || ''", true)
		if url != null and str(url) != "":
			_api_base_cache = str(url).rstrip("/")
			return _api_base_cache
		push_warning("window.API_CONFIG.BASE_URL not set — using desktop fallback")
	_api_base_cache = DESKTOP_API_FALLBACK.rstrip("/")
	return _api_base_cache

# ==================== CAMPAIGN MODE ====================

# Mint a campaign NFT. Web only — the browser wallet signs the
# server-built transaction (see wallet.js -> window.mintCampaignNFT).
# Returns true on confirmed mint, false otherwise.
func mint_campaign_nft(bug_id: int, metadata: Dictionary) -> bool:
	if not GameState.wallet_connected:
		print("ERROR: No wallet connected")
		return false

	if not OS.has_feature("web"):
		print("⚠️  Minting is only available in the web build (needs a browser wallet)")
		return false

	var name = metadata.get("name", "Unknown Bug")
	var image_uri = metadata.get("image_uri", "")

	print("🎨 Minting Campaign NFT: bug #%d (%s)" % [bug_id, name])

	JavaScriptBridge.eval("window._mintResult = null;", true)
	JavaScriptBridge.eval("""
		(async () => {
			try {
				await window.mintCampaignNFT(%BUG_ID%, '%NAME%', '%IMAGE_URI%', '%WALLET%');
			} catch (error) {
				window._mintResult = JSON.stringify({ success: false, error: String(error) });
			}
		})();
	""".replace("%BUG_ID%", str(bug_id))
		.replace("%NAME%", _js_escape(name))
		.replace("%IMAGE_URI%", _js_escape(image_uri))
		.replace("%WALLET%", _js_escape(GameState.wallet_address)), true)

	# Poll for the result. Minting includes a wallet popup and confirmation,
	# so allow up to 90s (450 * 0.2s) before giving up.
	var max_attempts = 450
	var attempt = 0
	while attempt < max_attempts:
		await get_tree().create_timer(0.2).timeout
		var result_str = JavaScriptBridge.eval("window._mintResult", true)
		if result_str != null and str(result_str) != "null" and str(result_str) != "":
			var result = JSON.parse_string(str(result_str))
			JavaScriptBridge.eval("window._mintResult = null;", true)
			if result == null:
				print("❌ Mint returned unparseable result")
				return false
			if result.get("success", false):
				print("✅ NFT minted: ", result.get("nftAddress", ""))
				if result.has("solscanUrl"):
					print("   ", result.get("solscanUrl", ""))
				return true
			if result.get("alreadyMinted", false):
				print("ℹ️  Bug already minted for this wallet")
				return false
			print("❌ Mint failed: ", result.get("error", "Unknown error"))
			return false
		attempt += 1

	print("❌ Mint timed out")
	return false

# Check whether the player has completed a bug on-chain.
func has_completed_bug(bug_id: int) -> bool:
	if not GameState.wallet_connected:
		return GameState.is_bug_completed(bug_id)

	var url = api_base() + "/has-completed-bug/" + GameState.wallet_address + "/" + str(bug_id)
	var data = await _get_json(url)
	if data != null and data.get("success", false):
		return data.get("completed", false)
	# fall back to local state on network failure
	return GameState.is_bug_completed(bug_id)

# Get the player's on-chain campaign progress. Returns a Dictionary
# ({completedBugs, totalCompleted}) or null on failure.
func get_player_progress():
	if not GameState.wallet_connected:
		print("ERROR: No wallet connected")
		return null

	var url = api_base() + "/player-progress/" + GameState.wallet_address
	var data = await _get_json(url)
	if data != null and data.get("success", false):
		return {
			"completedBugs": data.get("completedBugs", []),
			"totalCompleted": data.get("totalCompleted", 0)
		}
	print("❌ Failed to get player progress")
	return null

# Get campaign statistics. Returns a Dictionary or null on failure.
func get_campaign_stats(campaign_id: int = 2):
	var url = api_base() + "/campaign-stats/" + str(campaign_id)
	var data = await _get_json(url)
	if data != null and data.get("success", false):
		return data
	print("❌ Failed to get campaign stats")
	return null

# ==================== DAILY CHALLENGE ====================

# Get today's on-chain daily bug. Returns the bug id (1-20), or 0 if the
# daily bug is not available on-chain yet (never requested/consumed).
func get_todays_bug() -> int:
	var url = api_base() + "/daily-bug"
	var data = await _get_json(url)
	if data != null and data.get("success", false):
		if data.get("available", false):
			var bug_id = int(data.get("bugId", 0))
			print("✅ Today's bug: #", bug_id)
			return bug_id
		print("ℹ️  Daily bug not available yet: ", data.get("reason", "unknown"))
		return 0
	print("❌ Failed to reach daily-bug endpoint")
	return 0

# Daily-challenge leaderboard has no on-chain/server backend yet.
# Return an empty list and say so honestly rather than faking entries.
func get_daily_leaderboard(_bug_id: int) -> Array:
	print("ℹ️  Daily leaderboard is not available yet")
	return []

# Submitting a daily completion has no backend yet — report honestly.
func submit_daily_completion(_bug_id: int, _completion_time: float) -> bool:
	print("ℹ️  Daily completion submission is not available yet")
	return false

# Minting a distinct daily-challenge NFT has no backend yet.
func mint_daily_challenge_nft(_bug_id: int, _completion_time: float, _tier: String) -> bool:
	print("ℹ️  Daily challenge NFT minting is not available yet")
	return false

# ==================== HELPERS ====================

func test_connection() -> bool:
	var data = await _get_json(api_base() + "/health")
	if data != null:
		print("✅ API connection successful (", data.get("mode", "?"), ")")
		return true
	print("❌ API connection failed")
	return false

# GET a URL and parse JSON. Returns the parsed Dictionary, or null on any
# network / parse / non-200 failure.
func _get_json(url: String):
	var http = HTTPRequest.new()
	add_child(http)
	var err = http.request(url)
	if err != OK:
		print("❌ HTTP request failed to start: ", err)
		http.queue_free()
		return null
	var response = await http.request_completed
	http.queue_free()
	# response = [result, response_code, headers, body]
	if response[1] != 200:
		return null
	var json = JSON.new()
	if json.parse(response[3].get_string_from_utf8()) != OK:
		return null
	return json.data

func _js_escape(s: String) -> String:
	return s.replace("\\", "\\\\").replace("'", "\\'")
