extends Parallax2D

# Auto-scroll settings
@export var scroll_speed: Vector2 = Vector2(30, 0)  # Horizontal scroll speed
@export var enable_auto_scroll: bool = true

#func _ready():
	# Optional: Set scroll base offset
	#scroll_base_offset = Vector2.ZERO

func _process(delta):
	if enable_auto_scroll:
		# Auto-scroll clouds to the right
		scroll_offset += scroll_speed * delta
		
		# Optional: Reset after certain distance to prevent overflow
		if scroll_offset.x > 10000:
			scroll_offset.x = 0
