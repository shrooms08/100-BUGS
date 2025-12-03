extends Area2D

signal pressed
signal player_entered_button
signal player_exited_button

var is_pressed = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		if not is_pressed:
			is_pressed = true
			emit_signal("pressed")
			# Visual feedback
			$ColorRect.color = Color.GREEN
		
		# Notify MainRoom player is on button
		emit_signal("player_entered_button")

func _on_body_exited(body):
	if body.is_in_group("player"):
		# Notify MainRoom player left button
		emit_signal("player_exited_button")
