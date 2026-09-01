extends Node
## Every sound in the game is synthesised at start-up, so the build ships no
## audio files and still gets the "Lo-fi Chiptune" soundscape the design asks
## for. SFX run at 22 kHz; the music loop is deliberately 11 kHz — the crunch
## is part of the lo-fi look.

const SFX_RATE := 22050
const MUS_RATE := 11025
const VOICES := 8

var _sfx: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _music_player: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 20260901
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
	_build_sfx()
	_music_player.stream = _build_music()

# ---------------------------------------------------------------- synthesis --
func _osc(wave: String, phase: float) -> float:
	match wave:
		"sine":  return sin(phase * TAU)
		"tri":   return 4.0 * absf(phase - floorf(phase + 0.5)) - 1.0
		"saw":   return 2.0 * (phase - floorf(phase + 0.5))
		"noise": return _rng.randf_range(-1.0, 1.0)
		_:       return 1.0 if fposmod(phase, 1.0) < 0.5 else -1.0   # square

## Appends one note onto `buf` starting at sample `at`.
func _note(buf: PackedFloat32Array, rate: int, at: int, freq: float, dur: float,
		wave: String, vol: float, decay: float = 6.0, freq_end: float = -1.0) -> void:
	var n := int(dur * rate)
	var phase := 0.0
	for i in n:
		var idx := at + i
		if idx < 0 or idx >= buf.size():
			continue
		var t := float(i) / rate
		var f := freq if freq_end < 0.0 else lerpf(freq, freq_end, float(i) / maxf(n, 1))
		phase += f / rate
		# quick attack, exponential decay
		var env: float = minf(1.0, t * 120.0) * exp(-decay * t)
		buf[idx] += _osc(wave, phase) * vol * env

func _to_stream(buf: PackedFloat32Array, rate: int, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		var v := int(clampf(buf[i], -1.0, 1.0) * 32000.0)
		bytes.encode_s16(i * 2, v)
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.stereo = false
	s.data = bytes
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = buf.size()
	return s

func _blank(seconds: float, rate: int) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * rate))
	b.fill(0.0)
	return b

## One-pole low-pass; gives the synth its soft, tape-like edge.
func _lowpass(buf: PackedFloat32Array, amount: float) -> void:
	var prev := 0.0
	for i in buf.size():
		prev = lerpf(prev, buf[i], amount)
		buf[i] = prev

# ------------------------------------------------------------------- bank ---
func _build_sfx() -> void:
	var b: PackedFloat32Array

	b = _blank(0.20, SFX_RATE)
	_note(b, SFX_RATE, 0, 320.0, 0.18, "square", 0.28, 9.0, 720.0)
	_sfx["jump"] = _to_stream(b, SFX_RATE, false)

	b = _blank(0.16, SFX_RATE)
	_note(b, SFX_RATE, 0, 150.0, 0.10, "square", 0.22, 22.0, 80.0)
	_note(b, SFX_RATE, 0, 400.0, 0.06, "noise", 0.10, 34.0)
	_sfx["land"] = _to_stream(b, SFX_RATE, false)

	b = _blank(0.07, SFX_RATE)
	_note(b, SFX_RATE, 0, 900.0, 0.05, "noise", 0.05, 60.0)
	_sfx["step"] = _to_stream(b, SFX_RATE, false)

	b = _blank(0.40, SFX_RATE)
	_note(b, SFX_RATE, 0, 523.25, 0.10, "tri", 0.26, 9.0)
	_note(b, SFX_RATE, int(0.07 * SFX_RATE), 659.25, 0.10, "tri", 0.26, 9.0)
	_note(b, SFX_RATE, int(0.14 * SFX_RATE), 783.99, 0.20, "tri", 0.28, 7.0)
	_sfx["pickup"] = _to_stream(b, SFX_RATE, false)

	b = _blank(0.42, SFX_RATE)
	_note(b, SFX_RATE, 0, 880.0, 0.13, "square", 0.20, 11.0)
	_note(b, SFX_RATE, int(0.16 * SFX_RATE), 1174.66, 0.22, "square", 0.20, 9.0)
	_sfx["alert"] = _to_stream(b, SFX_RATE, false)

	b = _blank(0.55, SFX_RATE)
	_note(b, SFX_RATE, 0, 660.0, 0.5, "saw", 0.24, 5.0, 160.0)
	_note(b, SFX_RATE, 0, 331.0, 0.5, "square", 0.14, 5.0, 80.0)
	_sfx["spotted"] = _to_stream(b, SFX_RATE, false)

	# School bell: a few inharmonic partials with a long tail.
	b = _blank(2.2, SFX_RATE)
	for strike in 2:
		var at := int(strike * 0.75 * SFX_RATE)
		for partial in [1.0, 2.76, 5.40, 8.93]:
			_note(b, SFX_RATE, at, 523.0 * partial, 1.4, "sine", 0.13 / partial, 2.4)
	_sfx["bell"] = _to_stream(b, SFX_RATE, false)

	b = _blank(1.5, SFX_RATE)
	var win_notes := [523.25, 659.25, 783.99, 1046.50, 1318.51]
	for i in win_notes.size():
		_note(b, SFX_RATE, int(i * 0.11 * SFX_RATE), win_notes[i], 0.55, "tri", 0.24, 4.0)
	_sfx["win"] = _to_stream(b, SFX_RATE, false)

	b = _blank(1.3, SFX_RATE)
	var lose_notes := [392.0, 329.63, 261.63, 196.0]
	for i in lose_notes.size():
		_note(b, SFX_RATE, int(i * 0.16 * SFX_RATE), lose_notes[i], 0.6, "square", 0.20, 4.0)
	_sfx["lose"] = _to_stream(b, SFX_RATE, false)

	b = _blank(0.12, SFX_RATE)
	_note(b, SFX_RATE, 0, 740.0, 0.08, "square", 0.16, 22.0)
	_sfx["click"] = _to_stream(b, SFX_RATE, false)

	b = _blank(0.09, SFX_RATE)
	_note(b, SFX_RATE, 0, 1100.0, 0.06, "square", 0.10, 30.0)
	_sfx["move"] = _to_stream(b, SFX_RATE, false)

	b = _blank(0.35, SFX_RATE)
	_note(b, SFX_RATE, 0, 300.0, 0.05, "noise", 0.12, 40.0)
	_note(b, SFX_RATE, int(0.08 * SFX_RATE), 523.0, 0.25, "tri", 0.20, 7.0, 784.0)
	_sfx["unlock"] = _to_stream(b, SFX_RATE, false)

	b = _blank(0.30, SFX_RATE)
	_note(b, SFX_RATE, 0, 200.0, 0.28, "noise", 0.09, 9.0)
	_lowpass(b, 0.06)
	_sfx["hide"] = _to_stream(b, SFX_RATE, false)

	b = _blank(0.06, SFX_RATE)
	_note(b, SFX_RATE, 0, 620.0, 0.045, "square", 0.09, 40.0)
	_sfx["blip"] = _to_stream(b, SFX_RATE, false)

	b = _blank(0.5, SFX_RATE)
	_note(b, SFX_RATE, 0, 180.0, 0.45, "sine", 0.22, 5.0, 120.0)
	_note(b, SFX_RATE, 0, 900.0, 0.10, "noise", 0.07, 20.0)
	_sfx["throw"] = _to_stream(b, SFX_RATE, false)

	b = _blank(0.6, SFX_RATE)
	for i in 3:
		_note(b, SFX_RATE, int(i * 0.13 * SFX_RATE), 1046.5, 0.12, "square", 0.13, 16.0)
	_sfx["tick"] = _to_stream(b, SFX_RATE, false)

# ------------------------------------------------------------------ music ---
func _build_music() -> AudioStreamWAV:
	# ii-V-I-vi in C — warm, slightly wistful, loops seamlessly.
	var chords := [
		[146.83, 174.61, 220.00, 261.63],   # Dm7
		[196.00, 246.94, 293.66, 349.23],   # G7
		[130.81, 164.81, 196.00, 246.94],   # Cmaj7
		[220.00, 261.63, 329.63, 392.00],   # Am7
	]
	var bpm := 76.0
	var beat := 60.0 / bpm
	var bar := beat * 4.0
	var total := bar * chords.size()
	var buf := _blank(total, MUS_RATE)

	for bar_i in chords.size():
		var chord: Array = chords[bar_i]
		var bar_at := int(bar_i * bar * MUS_RATE)

		# soft pad on every chord tone, re-struck on beats 1 and 3
		for hit in 2:
			var at := bar_at + int(hit * 2.0 * beat * MUS_RATE)
			for f in chord:
				_note(buf, MUS_RATE, at, f, beat * 2.0, "tri", 0.055, 1.5)

		# walking bass, one note per beat
		for b_i in 4:
			var at := bar_at + int(b_i * beat * MUS_RATE)
			var f: float = chord[0] * 0.5
			if b_i == 1:
				f = chord[2] * 0.5
			elif b_i == 3:
				f = chord[1] * 0.5
			_note(buf, MUS_RATE, at, f, beat * 0.9, "sine", 0.19, 2.6)

		# lazy pentatonic lead over the top half of the bar
		var lead := [chord[3] * 2.0, chord[2] * 2.0, chord[3] * 2.0, chord[1] * 2.0]
		for n_i in lead.size():
			if (n_i + bar_i) % 3 == 0:
				continue                       # leave gaps so it breathes
			var at := bar_at + int((0.5 + n_i * 0.75) * beat * MUS_RATE)
			_note(buf, MUS_RATE, at, lead[n_i], beat * 0.6, "square", 0.045, 5.0)

		# brushed hats on the off-beats
		for h_i in 8:
			var at := bar_at + int(h_i * beat * 0.5 * MUS_RATE)
			_note(buf, MUS_RATE, at, 8000.0, 0.05, "noise", 0.030 if h_i % 2 else 0.045, 34.0)

	_lowpass(buf, 0.35)
	# a whisper of vinyl crackle
	for i in buf.size():
		if _rng.randi() % 900 == 0:
			buf[i] += _rng.randf_range(-0.05, 0.05)
	return _to_stream(buf, MUS_RATE, true)

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
	if Game.music_on and not _music_player.playing:
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
