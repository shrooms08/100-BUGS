extends Node

@onready var menu_music = $MenuMusic
@onready var gameplay_music = $GameplayMusic

var current_track = ""

func _ready():
	# Don't autoplay, wait for scene to call
	menu_music.stop()
	gameplay_music.stop()

func play_menu_music():
	if current_track != "menu":
		gameplay_music.stop()
		menu_music.play()
		current_track = "menu"

func play_gameplay_music():
	if current_track != "gameplay":
		menu_music.stop()
		gameplay_music.play()
		current_track = "gameplay"

func stop_all():
	menu_music.stop()
	gameplay_music.stop()
	current_track = ""

func crossfade_to_gameplay(duration: float = 2.0):
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade out menu
	tween.tween_property(menu_music, "volume_db", -80, duration)
	
	# Fade in gameplay
	gameplay_music.volume_db = -80
	gameplay_music.play()
	tween.tween_property(gameplay_music, "volume_db", -10, duration)
	
	await tween.finished
	menu_music.stop()
	current_track = "gameplay"
