extends Node2D

func _ready():
	$BackButton.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	GameState.campaign_mode = false
	get_tree().change_scene_to_file("res://Scene/main_room.tscn")
