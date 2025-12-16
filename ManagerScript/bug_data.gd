extends Node

# Bug metadata database for all 20 bugs
# Each bug has: name, description, image_uri, difficulty

func get_bug_metadata(bug_id: int) -> Dictionary:
	var bug_data = {
		1: {
			"name": "Bug #1: Plain and Simple",
			"description": "The journey begins. Everything seems normal... for now.",
			"image_uri": "ipfs://bafkreidksax7r3inqjpxuaitbhq5h6mhmrd5yp2dvirac6kcixn5h2bc5u",
			"difficulty": "Tutorial"
		},
		2: {
			"name": "Bug #2: Go Back",
			"description": "Sometimes you need to return. Walls aren't always what they seem.",
			"image_uri": "ipfs://bafkreiaeniawxwuxdsp423uadjnqefb4tfhxsokk3fmxbm4oanh744pkg4",
			"difficulty": "Easy"
		},
		3: {
			"name": "Bug #3: Weightless",
			"description": "The air feels different here. Lighter. Floatier. Wrong.",
			"image_uri": "ipfs://bafybeia47jxwxy2jyhkh4fx3lqs3w6xyownidnsxl2zudpxn25bjdgxuee",
			"difficulty": "Easy"
		},
		4: {
			"name": "Bug #4: SLIPPERY!",
			"description": "Every. Step. Slides. Control is an illusion.",
			"image_uri": "ipfs://bafkreidglf6xcsuv2kc3kst2leoi5irnupwi5bodgdps63ebl3q2f64rba",
			"difficulty": "Easy"
		},
		5: {
			"name": "Bug #5: Don't trust your eyes",
			"description": "What you see isn't always what exists. Look beyond the visible.",
			"image_uri": "ipfs://bafkreihrq5jos7j4ywz2tbwidpgvxstflebk5tsrkro4d74rjbkpjydlre",
			"difficulty": "Easy"
		},
		6: {
			"name": "Bug #6: What's wrong with gravity?",
			"description": "Up is down. Down is up. Reality bends to your will... or does it?",
			"image_uri": "ipfs://bafkreiaiaeztojz2zifzeoboodbkmh3ttaact2nu4owl6xoahajoaw44mi",
			"difficulty": "Medium"
		},
		7: {
			"name": "Bug #7: Displaced",
			"description": "You're not quite where you think you are. Trust the feeling, not the eyes.",
			"image_uri": "ipfs://bafkreifituhnz72lkcnopiykenx2pxnpobnq25uymlnw737zlz64eaddmq",
			"difficulty": "Medium"
		},
		8: {
			"name": "Bug #8: Wait on it!",
			"description": "Patience isn't just a virtue. It's the only way forward.",
			"image_uri": "ipfs://bafkreicafs5iaeqpszugydw63phrxdnm2wamordomq2m5zo4coxp2uxs2e",
			"difficulty": "Medium"
		},
		9: {
			"name": "Bug #9: Limited Resources",
			"description": "Three jumps. That's all you get. Make them count.",
			"image_uri": "ipfs://bafkreifnpova6euslxcjc4qt342yj7xm35meffisjv5l7gzgobydbihg5i",
			"difficulty": "Medium"
		},
		10: {
			"name": "Bug #10: Now you see it...",
			"description": "The ground flickers between existence and void. Time your steps carefully.",
			"image_uri": "ipfs://bafkreihbf5zpusuy7sr3pbcadsnr7pv6m2n3mkojiejug5nqvnpjtizo4y",
			"difficulty": "Medium"
		},
		11: {
			"name": "Bug #11: Just Give Up",
			"description": "The hardest challenge: do nothing. Fight every instinct.",
			"image_uri": "ipfs://bafkreiectjgrw3wlcaui3wuqyr76pqnlgjrzvefwd3xv62n4b3wx7avvqu",
			"difficulty": "Hard"
		},
		12: {
			"name": "Bug #12: Which way is down?",
			"description": "Gravity has lost its mind. You're about to lose yours too.",
			"image_uri": "ipfs://bafybeidmav6rw2syg24clihsy6if5thefix5vpxroc3qytj23ygcggckf4",
			"difficulty": "Hard"
		},
		13: {
			"name": "Bug #13: Mirror World",
			"description": "Left is right. Right is left. Your brain will hate you.",
			"image_uri": "ipfs://bafybeievvrgmobe2jlkeb64uy4fb5cxwflur4qroc2ff2hlwmpguczrvsm",
			"difficulty": "Hard"
		},
		14: {
			"name": "Bug #14: LAG",
			"description": "Your commands arrive... eventually. Plan ahead. Way ahead.",
			"image_uri": "ipfs://bafybeieie7c6ngufwme3kdvmpgczhkhdstxat2q56shlh3luni5h3wlcwi",
			"difficulty": "Hard"
		},
		15: {
			"name": "Bug #15: Turbulence",
			"description": "Speed fluctuates wildly. Slow. Fast. Slower. Faster. Chaos.",
			"image_uri": "ipfs://bafybeigqctlkzxegdjs7g7zrx26a2earv2iec526ebcdxqvfkefpvdcmxi",
			"difficulty": "Hard"
		},
		16: {
			"name": "Bug #16: CHAOS",
			"description": "Everything moves. Nothing is stable. Order collapses. Adapt or die.",
			"image_uri": "ipfs://bafybeiccyra57ybpcjh7pwv7jrfsxdvrlxtsmdrja46ovplkjit6lamtqa",
			"difficulty": "Legendary"
		},
		17: {
			"name": "Bug #17: New keys",
			"description": "Forget your training. These controls are... different.",
			"image_uri": "ipfs://bafkreicv3x5oxudf3xhmh3au2pxskv553gmt4sd46rz5olyzhq5zjiyjzq",
			"difficulty": "Legendary"
		},
		18: {
			"name": "Bug #18: Blind",
			"description": "Your eyes are useless here. Trust your instincts. Feel the path.",
			"image_uri": "ipfs://bafybeiev4kewgkn55oxue5sxj6ba3als6aac5kn3jemzwqxeumpbsz4tau",
			"difficulty": "Legendary"
		},
		19: {
			"name": "Bug #19: Don't Touch It",
			"description": "The button screams to be pressed. Resist. Resist. RESIST.",
			"image_uri": "ipfs://bafkreigeczhxubituavuixhatujxvqd4d5rdhowoqor2ofyktkpb4ynsey",
			"difficulty": "Legendary"
		},
		20: {
			"name": "Bug #20: Inverted",
			"description": "The world has flipped. Sky is ground. Ground is sky. Your mind must follow.",
			"image_uri": "ipfs://bafybeib67p4i37uynpcibbtuoeuqcksx2rdmqh6z3qatfsd6h2zezxqdku",
			"difficulty": "Legendary"
		}
	}
	
	return bug_data.get(bug_id, {
		"name": "Unknown Bug",
		"description": "A mysterious anomaly in the system.",
		"image_uri": "ipfs://bafkreidksax7r3inqjpxuaitbhq5h6mhmrd5yp2dvirac6kcixn5h2bc5u",
		"difficulty": "Unknown"
	})

# Get color for difficulty tier
func get_difficulty_color(difficulty: String) -> Color:
	match difficulty:
		"Tutorial":
			return Color(0.2, 0.8, 0.2)  # Green
		"Easy":
			return Color(0.3, 0.6, 1.0)  # Blue
		"Medium":
			return Color(1.0, 0.8, 0.2)  # Yellow
		"Hard":
			return Color(1.0, 0.4, 0.2)  # Orange
		"Legendary":
			return Color(0.9, 0.2, 0.9)  # Purple/Pink
		_:
			return Color(0.5, 0.5, 0.5)  # Gray

# Get all bug IDs (useful for iteration)
func get_all_bug_ids() -> Array:
	return range(1, 21)  # 1 to 20

# Check if bug ID is valid
func is_valid_bug_id(bug_id: int) -> bool:
	return bug_id >= 1 and bug_id <= 20
