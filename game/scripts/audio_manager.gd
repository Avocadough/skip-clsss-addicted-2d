extends Node
## Plays the game's audio, which ships as real .wav files under assets/audio/.
##
## Those files are rendered by tools/audio.gd — a small synthesiser that
## builds the lo-fi chiptune loop and every effect from oscillators. Re-run it
## if you want to change how anything sounds:
##   Godot.exe --headless --path game --script res://tools/audio.gd

const AUDIO_DIR := "res://assets/audio/"
const VOICES := 8

const SFX_NAMES: Array[String] = [
	"jump", "land", "step", "pickup", "alert", "spotted", "bell", "win",
	"lose", "click", "move", "unlock", "hide", "blip", "throw", "tick", "thud",
]

var _sfx: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _music_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_players.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = -12.0
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)

	for name: String in SFX_NAMES:
		var path := AUDIO_DIR + "sfx_" + name + ".wav"
		if ResourceLoader.exists(path):
			_sfx[name] = load(path)
		else:
			push_warning("missing sound: %s (run tools/audio.gd)" % path)

	var music_path := AUDIO_DIR + "music_lofi.wav"
	if ResourceLoader.exists(music_path):
		var music: AudioStreamWAV = load(music_path)
		# The .wav container does not carry loop points through the importer,
		# so the loop is set here instead — the track is written to join
		# cleanly end to start.
		music.loop_mode = AudioStreamWAV.LOOP_FORWARD
		music.loop_begin = 0
		music.loop_end = music.data.size() / 2      # 16-bit mono
		_music_player.stream = music
	else:
		push_warning("missing music: %s (run tools/audio.gd)" % music_path)

# -------------------------------------------------------------------- api ---
func play(name: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not Game.sfx_on or not _sfx.has(name):
		return
	var p := _players[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	p.stream = _sfx[name]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()

func play_music() -> void:
	if Game.music_on and _music_player.stream != null and not _music_player.playing:
		_music_player.play()

func stop_music() -> void:
	_music_player.stop()

func set_music_enabled(on: bool) -> void:
	Game.music_on = on
	if on:
		play_music()
	else:
		stop_music()
	Game.save_game()

func duck_music(db: float) -> void:
	_music_player.volume_db = db
