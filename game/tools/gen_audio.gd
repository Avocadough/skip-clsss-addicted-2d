extends SceneTree
## Renders every sound in the game to a .wav under assets/audio/.
##
## The synthesis used to run at start-up inside audio_manager.gd. Baking it to
## files instead means the sounds are real assets you can open, inspect or
## replace, and the game no longer spends time generating them on every launch.
##   Godot.exe --headless --path game --script res://tools/gen_audio.gd

const OUT := "res://assets/audio/"
const SFX_RATE := 22050
const MUS_RATE := 11025

var _rng := RandomNumberGenerator.new()

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
		var env: float = minf(1.0, t * 120.0) * exp(-decay * t)
		buf[idx] += _osc(wave, phase) * vol * env

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

func _to_stream(buf: PackedFloat32Array, rate: int) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.stereo = false
	s.data = bytes
	return s

func _save(stream: AudioStreamWAV, name: String) -> void:
	var path := ProjectSettings.globalize_path(OUT + name + ".wav")
	var err := stream.save_to_wav(path)
	if err != OK:
		push_error("could not write %s (%d)" % [path, err])
	else:
		var secs := float(stream.data.size() / 2) / stream.mix_rate
		print("  %-18s %5.2fs  %6.1f KB" % [name + ".wav", secs, stream.data.size() / 1024.0])

# -------------------------------------------------------------------- sfx ---
func _gen_sfx() -> void:
	print("sound effects:")
	var b: PackedFloat32Array

	b = _blank(0.20, SFX_RATE)
	_note(b, SFX_RATE, 0, 320.0, 0.18, "square", 0.28, 9.0, 720.0)
	_save(_to_stream(b, SFX_RATE), "sfx_jump")

	b = _blank(0.16, SFX_RATE)
	_note(b, SFX_RATE, 0, 150.0, 0.10, "square", 0.22, 22.0, 80.0)
	_note(b, SFX_RATE, 0, 400.0, 0.06, "noise", 0.10, 34.0)
	_save(_to_stream(b, SFX_RATE), "sfx_land")

	b = _blank(0.07, SFX_RATE)
	_note(b, SFX_RATE, 0, 900.0, 0.05, "noise", 0.05, 60.0)
	_save(_to_stream(b, SFX_RATE), "sfx_step")

	b = _blank(0.40, SFX_RATE)
	_note(b, SFX_RATE, 0, 523.25, 0.10, "tri", 0.26, 9.0)
	_note(b, SFX_RATE, int(0.07 * SFX_RATE), 659.25, 0.10, "tri", 0.26, 9.0)
	_note(b, SFX_RATE, int(0.14 * SFX_RATE), 783.99, 0.20, "tri", 0.28, 7.0)
	_save(_to_stream(b, SFX_RATE), "sfx_pickup")

	b = _blank(0.42, SFX_RATE)
	_note(b, SFX_RATE, 0, 880.0, 0.13, "square", 0.20, 11.0)
	_note(b, SFX_RATE, int(0.16 * SFX_RATE), 1174.66, 0.22, "square", 0.20, 9.0)
	_save(_to_stream(b, SFX_RATE), "sfx_alert")

	b = _blank(0.55, SFX_RATE)
	_note(b, SFX_RATE, 0, 660.0, 0.5, "saw", 0.24, 5.0, 160.0)
	_note(b, SFX_RATE, 0, 331.0, 0.5, "square", 0.14, 5.0, 80.0)
	_save(_to_stream(b, SFX_RATE), "sfx_spotted")

	# School bell: a few inharmonic partials with a long tail.
	b = _blank(2.2, SFX_RATE)
	for strike in 2:
		var at := int(strike * 0.75 * SFX_RATE)
		for partial in [1.0, 2.76, 5.40, 8.93]:
			_note(b, SFX_RATE, at, 523.0 * partial, 1.4, "sine", 0.13 / partial, 2.4)
	_save(_to_stream(b, SFX_RATE), "sfx_bell")

	b = _blank(1.5, SFX_RATE)
	var win_notes := [523.25, 659.25, 783.99, 1046.50, 1318.51]
	for i in win_notes.size():
		_note(b, SFX_RATE, int(i * 0.11 * SFX_RATE), win_notes[i], 0.55, "tri", 0.24, 4.0)
	_save(_to_stream(b, SFX_RATE), "sfx_win")

	b = _blank(1.3, SFX_RATE)
	var lose_notes := [392.0, 329.63, 261.63, 196.0]
	for i in lose_notes.size():
		_note(b, SFX_RATE, int(i * 0.16 * SFX_RATE), lose_notes[i], 0.6, "square", 0.20, 4.0)
	_save(_to_stream(b, SFX_RATE), "sfx_lose")

	b = _blank(0.12, SFX_RATE)
	_note(b, SFX_RATE, 0, 740.0, 0.08, "square", 0.16, 22.0)
	_save(_to_stream(b, SFX_RATE), "sfx_click")

	b = _blank(0.09, SFX_RATE)
	_note(b, SFX_RATE, 0, 1100.0, 0.06, "square", 0.10, 30.0)
	_save(_to_stream(b, SFX_RATE), "sfx_move")

	b = _blank(0.35, SFX_RATE)
	_note(b, SFX_RATE, 0, 300.0, 0.05, "noise", 0.12, 40.0)
	_note(b, SFX_RATE, int(0.08 * SFX_RATE), 523.0, 0.25, "tri", 0.20, 7.0, 784.0)
	_save(_to_stream(b, SFX_RATE), "sfx_unlock")

	b = _blank(0.30, SFX_RATE)
	_note(b, SFX_RATE, 0, 200.0, 0.28, "noise", 0.09, 9.0)
	_lowpass(b, 0.06)
	_save(_to_stream(b, SFX_RATE), "sfx_hide")

	b = _blank(0.06, SFX_RATE)
	_note(b, SFX_RATE, 0, 620.0, 0.045, "square", 0.09, 40.0)
	_save(_to_stream(b, SFX_RATE), "sfx_blip")

	b = _blank(0.5, SFX_RATE)
	_note(b, SFX_RATE, 0, 180.0, 0.45, "sine", 0.22, 5.0, 120.0)
	_note(b, SFX_RATE, 0, 900.0, 0.10, "noise", 0.07, 20.0)
	_save(_to_stream(b, SFX_RATE), "sfx_throw")

	b = _blank(0.6, SFX_RATE)
	for i in 3:
		_note(b, SFX_RATE, int(i * 0.13 * SFX_RATE), 1046.5, 0.12, "square", 0.13, 16.0)
	_save(_to_stream(b, SFX_RATE), "sfx_tick")

	# Taking a ball to the head: a deep thump plus the clatter of going down.
	b = _blank(0.8, SFX_RATE)
	_note(b, SFX_RATE, 0, 110.0, 0.45, "sine", 0.42, 6.0, 55.0)
	_note(b, SFX_RATE, 0, 220.0, 0.22, "square", 0.20, 12.0, 90.0)
	_note(b, SFX_RATE, 0, 1200.0, 0.16, "noise", 0.22, 16.0)
	_note(b, SFX_RATE, int(0.18 * SFX_RATE), 320.0, 0.30, "noise", 0.10, 9.0)
	_save(_to_stream(b, SFX_RATE), "sfx_thud")

# ------------------------------------------------------------------ music ---
func _gen_music() -> void:
	print("music:")
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
	var buf := _blank(bar * chords.size(), MUS_RATE)

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
	_save(_to_stream(buf, MUS_RATE), "music_lofi")

func _initialize() -> void:
	_rng.seed = 20260901          # fixed, so rebuilding gives identical files
	print("=== rendering audio for Skip Class Addicted ===")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_gen_sfx()
	_gen_music()
	print("=== done ===")
	quit()
