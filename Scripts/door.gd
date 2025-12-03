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
		# Check if we're in campaign mode
		if GameState.campaign_mode:
			# Mark bug as completed locally
			GameState.complete_bug(GameState.current_bug)
			
			# Mint NFT if wallet connected
			if GameState.wallet_connected:
				# Get full metadata for this bug
				var metadata = get_bug_metadata(GameState.current_bug)
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

func get_bug_metadata(bug_id: int) -> Dictionary:
	var bug_data = {
		1: {
			"name": "Bug #1: Plain and Simple",
			"description": "Mastered the basics. Nothing broken here... yet.",
			"image_uri": "ipfs://bafkreidksax7r3inqjpxuaitbhq5h6mhmrd5yp2dvirac6kcixn5h2bc5u",
			"difficulty": "Tutorial"
		},
		2: {
			"name": "Bug #2: Ghost Wall",
			"description": "Walked through walls to find the hidden button.",
			"image_uri": "ipfs://bafkreiaeniawxwuxdsp423uadjnqefb4tfhxsokk3fmxbm4oanh744pkg4",
			"difficulty": "Easy"
		},
		3: {
			"name": "Bug #3: Low Gravity",
			"description": "Floated to victory with reduced gravity.",
			"image_uri": "ipfs://bafybeia47jxwxy2jyhkh4fx3lqs3w6xyownidnsxl2zudpxn25bjdgxuee",
			"difficulty": "Easy"
		},
		4: {
			"name": "Bug #4: Slippery Floor",
			"description": "Conquered ice physics and sliding chaos.",
			"image_uri": "ipfs://bafkreidglf6xcsuv2kc3kst2leoi5irnupwi5bodgdps63ebl3q2f64rba",
			"difficulty": "Easy"
		},
		5: {
			"name": "Bug #5: Invisible Button",
			"description": "Found what you couldn't see.",
			"image_uri": "ipfs://bafkreihrq5jos7j4ywz2tbwidpgvxstflebk5tsrkro4d74rjbkpjydlre",
			"difficulty": "Easy"
		},
		6: {
			"name": "Bug #6: Play with Gravity",
			"description": "Switched gravity on command.",
			"image_uri": "ipfs://bafkreiaiaeztojz2zifzeoboodbkmh3ttaact2nu4owl6xoahajoaw44mi",
			"difficulty": "Medium"
		},
		7: {
			"name": "Bug #7: Hitbox Offset",
			"description": "Mastered collision that doesn't match reality.",
			"image_uri": "ipfs://bafkreifituhnz72lkcnopiykenx2pxnpobnq25uymlnw737zlz64eaddmq",
			"difficulty": "Medium"
		},
		8: {
			"name": "Bug #8: Stay on It",
			"description": "Held your ground for 5 seconds.",
			"image_uri": "ipfs://bafkreicafs5iaeqpszugydw63phrxdnm2wamordomq2m5zo4coxp2uxs2e",
			"difficulty": "Medium"
		},
		9: {
			"name": "Bug #9: Save Jumps",
			"description": "Reached the goal with only 3 jumps.",
			"image_uri": "ipfs://bafkreifnpova6euslxcjc4qt342yj7xm35meffisjv5l7gzgobydbihg5i",
			"difficulty": "Medium"
		},
		10: {
			"name": "Bug #10: Floor Flicker",
			"description": "Timed your movements through disappearing platforms.",
			"image_uri": "ipfs://bafkreihbf5zpusuy7sr3pbcadsnr7pv6m2n3mkojiejug5nqvnpjtizo4y",
			"difficulty": "Medium"
		},
		11: {
			"name": "Bug #11: Just Give Up",
			"description": "Patience was the key. You did nothing for 10 seconds.",
			"image_uri": "ipfs://bafkreiectjgrw3wlcaui3wuqyr76pqnlgjrzvefwd3xv62n4b3wx7avvqu",
			"difficulty": "Hard"
		},
		12: {
			"name": "Bug #12: Gravity Fails",
			"description": "Survived gravity switching on every collision.",
			"image_uri": "ipfs://bafybeidmav6rw2syg24clihsy6if5thefix5vpxroc3qytj23ygcggckf4",
			"difficulty": "Hard"
		},
		13: {
			"name": "Bug #13: Swapped Controls",
			"description": "Rewired your brain to play backwards.",
			"image_uri": "ipfs://bafybeievvrgmobe2jlkeb64uy4fb5cxwflur4qroc2ff2hlwmpguczrvsm",
			"difficulty": "Hard"
		},
		14: {
			"name": "Bug #14: Time Delay",
			"description": "Played 1 second in the past.",
			"image_uri": "ipfs://bafybeieie7c6ngufwme3kdvmpgczhkhdstxat2q56shlh3luni5h3wlcwi",
			"difficulty": "Hard"
		},
		15: {
			"name": "Bug #15: Velocity Chaos",
			"description": "Adapted to constantly changing speed.",
			"image_uri": "ipfs://bafybeigqctlkzxegdjs7g7zrx26a2earv2iec526ebcdxqvfkefpvdcmxi",
			"difficulty": "Hard"
		},
		16: {
			"name": "Bug #16: Chaos Shuffle",
			"description": "Navigated platforms that moved while you played.",
			"image_uri": "ipfs://bafybeiccyra57ybpcjh7pwv7jrfsxdvrlxtsmdrja46ovplkjit6lamtqa",
			"difficulty": "Legendary"
		},
		17: {
			"name": "Bug #17: Alternative Controls",
			"description": "Learned an entirely new control scheme.",
			"image_uri": "ipfs://bafkreicv3x5oxudf3xhmh3au2pxskv553gmt4sd46rz5olyzhq5zjiyjzq",
			"difficulty": "Legendary"
		},
		18: {
			"name": "Bug #18: Blind Camera",
			"description": "Reached the goal with limited vision.",
			"image_uri": "ipfs://bafybeiev4kewgkn55oxue5sxj6ba3als6aac5kn3jemzwqxeumpbsz4tau",
			"difficulty": "Legendary"
		},
		19: {
			"name": "Bug #19: Don't Touch It",
			"description": "Resisted the button and went straight to the door.",
			"image_uri": "ipfs://bafkreigeczhxubituavuixhatujxvqd4d5rdhowoqor2ofyktkpb4ynsey",
			"difficulty": "Legendary"
		},
		20: {
			"name": "Bug #20: Upside Down",
			"description": "Conquered the world turned on its head.",
			"image_uri": "ipfs://bafybeib67p4i37uynpcibbtuoeuqcksx2rdmqh6z3qatfsd6h2zezxqdku",
			"difficulty": "Legendary"
		}
	}
	
	return bug_data.get(bug_id, {
		"name": "Unknown Bug",
		"description": "A mysterious bug",
		"image_uri": "ipfs://bafkreidksax7r3inqjpxuaitbhq5h6mhmrd5yp2dvirac6kcixn5h2bc5u",
		"difficulty": "Unknown"
	})
