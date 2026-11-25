extends Node
## The game's music (22 Nov 2026 in CLAUDE.md, delivered 25 Nov 2026): Matilde's track, played once
## by this autoload and never stopped, so it keeps playing across every scene change (menu,
## creation, main game, failure). It loops forever: MP3 import does not loop reliably in the web
## export, so this script restarts the track itself on "finished" instead of relying on the
## stream's own loop flag.
const TRACK := "res://assets/audio/music.mp3"

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.stream = load(TRACK)
	_player.bus = "Master"
	# Keep playing while every other gameplay sound might later be paused with the game (settings,
	# failure screen): music is independent of the game clock.
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_player.finished.connect(_restart)
	add_child(_player)
	_player.play()


func _restart() -> void:
	_player.play()
