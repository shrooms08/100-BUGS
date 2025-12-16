extends Area2D

signal pressed
signal player_entered_button
signal player_exited_button

var is_pressed = false

# Animation
@onready var button_sprite: AnimatedSprite2D = $ButtonSprite


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Start with unpressed button animation
	if button_sprite:
		button_sprite.play("unpressed")

func _on_body_entered(body):
	if body.is_in_group("player"):
		if not is_pressed:
			is_pressed = true
			
			# Play button press animation
			if button_sprite:
				button_sprite.play("pressed")
			
			emit_signal("pressed")
			
			## Optional: Keep ColorRect for backward compatibility
			#if has_node("ColorRect"):
				#$ColorRect.color = Color.GREEN
		
		# Notify MainRoom player is on button
		emit_signal("player_entered_button")

func _on_body_exited(body):
	if body.is_in_group("player"):
		# Notify MainRoom player left button
		emit_signal("player_exited_button")

func reset():
	"""Reset button to unpressed state"""
	is_pressed = false
	
	if button_sprite:
		button_sprite.play("unpressed")
	
	if has_node("ColorRect"):
		$ColorRect.color = Color.WHITE
