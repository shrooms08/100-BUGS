# Create BugMetadata.gd
extends Node

const BUG_METADATA = {
	1: {
		"name": "Bug #1: Plain and Simple",
		"description": "Mastered the basics. Nothing broken here... yet.",
		"image_uri": "https://arweave.net/bug1",
		"difficulty": "Tutorial"
	},
	2: {
		"name": "Bug #2: Ghost Wall",
		"description": "Walked through solid walls to find the hidden button.",
		"image_uri": "https://arweave.net/bug2",
		"difficulty": "Easy"
	},
	3: {
		"name": "Bug #3: Low Gravity",
		"description": "Floated to victory with reduced gravity.",
		"image_uri": "https://arweave.net/bug3",
		"difficulty": "Easy"
	},
	# ... all 20 bugs
	20: {
		"name": "Bug #20: Upside Down",
		"description": "Conquered the world turned on its head.",
		"image_uri": "https://arweave.net/bug20",
		"difficulty": "Legendary"
	}
}

func get_metadata(bug_id: int) -> Dictionary:
	return BUG_METADATA.get(bug_id, {})
