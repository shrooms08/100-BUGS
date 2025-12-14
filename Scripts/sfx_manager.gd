extends Node

@onready var button_click = $ButtonClick

func _ready():
	# Connect to all buttons in the game
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node):
	# Check if it's a button
	if node is Button:
		# Connect click sound to this button
		if not node.pressed.is_connected(_on_button_pressed):
			node.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	button_click.play()

# Manual play functions for other sounds
func play_click():
	button_click.play()
