extends Node

var current_bug = 1

# Campaign progress
var campaign_unlocked_bugs = [1]
var campaign_completed_bugs = []
var campaign_mode = false

# Wallet connection (NEW)
var wallet_connected = false
var wallet_address = ""
var wallet_type = ""  # "phantom", "solflare", etc.

# Save/Load functions
func save_progress():
	var save_data = {
		"unlocked": campaign_unlocked_bugs,
		"completed": campaign_completed_bugs,
		"wallet_address": wallet_address,  # NEW
		"wallet_type": wallet_type  # NEW
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
		wallet_address = save_data.get("wallet_address", "")  # NEW
		wallet_type = save_data.get("wallet_type", "")  # NEW
		
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

# Wallet functions (NEW)
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
