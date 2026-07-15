extends Node
class_name AudioManager

## ── Placeholder Audio Manager ─────────────────────────────────────────────
## Generates runtime placeholder sounds for BBQ Hero using procedural
## AudioStreamWAV. No external audio files needed during development.
##
## Replace these with real audio assets before release.

## Audio buses
const BUS_AMBIENT: String = "Ambient"
const BUS_SFX: String = "SFX"

## Audio players — created on demand
var _ambient_player: AudioStreamPlayer2D = null
var _sfx_player: AudioStreamPlayer2D = null

## Generated placeholder streams
var _stream_fire_crackle: AudioStreamWAV = null
var _stream_sizzle: AudioStreamWAV = null
var _stream_ambient: AudioStreamWAV = null
var _stream_ui_click: AudioStreamWAV = null
var _stream_ui_success: AudioStreamWAV = null
var _stream_meat_done: AudioStreamWAV = null

func _ready() -> void:
	_generate_placeholder_sounds()
	_setup_players()


func _generate_placeholder_sounds() -> void:
	## Fire crackle — short low-frequency noise bursts
	_stream_fire_crackle = _generate_noise(0.15, 800.0, 0.3)
	
	## Sizzle — higher frequency noise
	_stream_sizzle = _generate_noise(0.3, 3000.0, 0.2)
	
	## Ambient — gentle low hum (60 Hz + harmonics)
	_stream_ambient = _generate_tone_mixed(60.0, 2.0, [120.0, 180.0], 0.12)
	_stream_ambient.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	## UI click — short beep
	_stream_ui_click = _generate_tone(800.0, 0.05, 0.4)
	
	## UI success — rising tone
	_stream_ui_success = _generate_sweep(400.0, 800.0, 0.15, 0.5)
	
	## Meat done — chime
	_stream_meat_done = _generate_tone_mixed(523.0, 0.2, [659.0, 784.0], 0.4)


func _setup_players() -> void:
	## Ambient player (looping, lower priority)
	_ambient_player = AudioStreamPlayer2D.new()
	_ambient_player.name = "AmbientPlayer"
	_ambient_player.bus = BUS_AMBIENT
	_ambient_player.stream = _stream_ambient
	_ambient_player.volume_db = -18.0
	add_child(_ambient_player)
	
	## SFX player (one-shot sounds)
	_sfx_player = AudioStreamPlayer2D.new()
	_sfx_player.name = "SFXPlayer"
	_sfx_player.bus = BUS_SFX
	_sfx_player.volume_db = -6.0
	add_child(_sfx_player)


## ── Public Playback API ───────────────────────────────────────────────────

func play_ambient() -> void:
	if _ambient_player and not _ambient_player.playing:
		_ambient_player.play()

func stop_ambient() -> void:
	if _ambient_player and _ambient_player.playing:
		_ambient_player.stop()

func play_fire_crackle() -> void:
	_play_sfx(_stream_fire_crackle)

func play_sizzle() -> void:
	_play_sfx(_stream_sizzle)

func play_ui_click() -> void:
	_play_sfx(_stream_ui_click)

func play_ui_success() -> void:
	_play_sfx(_stream_ui_success)

func play_meat_done() -> void:
	_play_sfx(_stream_meat_done)


func _play_sfx(stream: AudioStreamWAV) -> void:
	if not _sfx_player or not stream:
		return
	_sfx_player.stream = stream
	_sfx_player.play()


## ── Sound Generation ──────────────────────────────────────────────────────

func _generate_tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	"""Generate a pure sine wave at given frequency."""
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	
	var sample_count = int(stream.mix_rate * duration)
	if sample_count < 1:
		sample_count = 1
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t = float(i) / stream.mix_rate
		var env = 1.0
		# Fade in/out to avoid clicks
		if i < 100:
			env = float(i) / 100.0
		if i > sample_count - 100:
			env = float(sample_count - i) / 100.0
		var sample = sin(2.0 * PI * freq * t) * volume * env * 32767.0
		data.encode_s16(i * 2, int(clamp(sample, -32768.0, 32767.0)))
	
	stream.data = data
	return stream


func _generate_tone_mixed(freq: float, duration: float, harmonics: Array, volume: float) -> AudioStreamWAV:
	"""Generate a tone with added harmonics for richness."""
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	
	var sample_count = int(stream.mix_rate * duration)
	if sample_count < 1:
		sample_count = 1
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	var all_freqs = [freq] + harmonics
	
	for i in range(sample_count):
		var t = float(i) / stream.mix_rate
		var env = 1.0
		if i < 100:
			env = float(i) / 100.0
		if i > sample_count - 100:
			env = float(sample_count - i) / 100.0
		
		var sample_val = 0.0
		for j in range(all_freqs.size()):
			var f = all_freqs[j]
			var amp = 1.0 / (j + 1)  # Fundamental loudest, harmonics quieter
			sample_val += sin(2.0 * PI * f * t) * amp
		
		sample_val = sample_val / all_freqs.size() * volume * env * 32767.0
		data.encode_s16(i * 2, int(clamp(sample_val, -32768.0, 32767.0)))
	
	stream.data = data
	return stream


func _generate_noise(duration: float, cutoff_hz: float, volume: float) -> AudioStreamWAV:
	"""Generate filtered white noise (simple RC approximation)."""
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	
	var sample_count = int(stream.mix_rate * duration)
	if sample_count < 1:
		sample_count = 1
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	var rc = 1.0 / (cutoff_hz * 2.0 * PI)
	var dt = 1.0 / stream.mix_rate
	var alpha = dt / (rc + dt)
	var prev: float = 0.0
	
	for i in range(sample_count):
		var t = float(i) / stream.mix_rate
		var env = 1.0
		if i < 100:
			env = float(i) / 100.0
		if i > sample_count - 100:
			env = float(sample_count - i) / 100.0
		
		# White noise
		var white = randf_range(-1.0, 1.0)
		# Simple low-pass filter
		var filtered = prev + alpha * (white - prev)
		prev = filtered
		
		var sample = filtered * volume * env * 32767.0
		data.encode_s16(i * 2, int(clamp(sample, -32768.0, 32767.0)))
	
	stream.data = data
	return stream


func _generate_sweep(start_freq: float, end_freq: float, duration: float, volume: float) -> AudioStreamWAV:
	"""Generate a frequency sweep (rising tone)."""
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	
	var sample_count = int(stream.mix_rate * duration)
	if sample_count < 1:
		sample_count = 1
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t = float(i) / stream.mix_rate
		var progress = float(i) / sample_count
		var freq = start_freq + (end_freq - start_freq) * progress
		
		var env = 1.0
		if i < 100:
			env = float(i) / 100.0
		if i > sample_count - 100:
			env = float(sample_count - i) / 100.0
		
		var sample = sin(2.0 * PI * freq * t) * volume * env * 32767.0
		data.encode_s16(i * 2, int(clamp(sample, -32768.0, 32767.0)))
	
	stream.data = data
	return stream
