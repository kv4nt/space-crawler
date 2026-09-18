extends Node
## AudioService — Music/SFX через отдельные шины. Процедурная генерация звуков (MVP).

var music_volume: float = 0.7
var sfx_volume: float = 0.8
var sounds_enabled: bool = true

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS := 8

var _streams: Dictionary = {}


func _ready() -> void:
	_setup_buses()
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

	for i in MAX_SFX_PLAYERS:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)

	_generate_streams()


func _setup_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")


func _generate_streams() -> void:
	_streams["tap"] = _make_soft_blip()
	_streams["mine"] = _make_tone(440.0, 0.15, 0.4, true)
	_streams["win"] = _make_chord([523.0, 659.0, 784.0], 0.6, 0.35)
	_streams["lose"] = _make_tone(220.0, 0.5, 0.4, true)
	_streams["warp"] = _make_tone(660.0, 0.25, 0.35)
	_streams["unlock"] = _make_chord([392.0, 494.0, 587.0], 0.3, 0.3)
	_streams["menu_music"] = _make_ambient(90.0, 8.0, 0.15)


func _make_tone(freq: float, duration: float, volume: float, fade_out: bool = false) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in sample_count:
		var t := float(i) / sample_rate
		var envelope := 1.0
		if fade_out:
			envelope = 1.0 - float(i) / sample_count
		var sample := sin(TAU * freq * t) * envelope * volume
		var s16 := int(clampi(sample * 32767.0, -32768.0, 32767.0))
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _make_chord(freqs: Array, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in sample_count:
		var t := float(i) / sample_rate
		var envelope := 1.0 - float(i) / sample_count
		var sample := 0.0
		for f in freqs:
			sample += sin(TAU * f * t)
		sample = sample / freqs.size() * envelope * volume
		var s16 := int(clampi(sample * 32767.0, -32768.0, 32767.0))
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _make_ambient(base_freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in sample_count:
		var t := float(i) / sample_rate
		var lfo := sin(TAU * 0.15 * t) * 0.3 + 0.7
		var sample := (
			sin(TAU * base_freq * t) * 0.4
			+ sin(TAU * base_freq * 1.5 * t) * 0.25
			+ sin(TAU * base_freq * 0.5 * t) * 0.2
		) * lfo * volume
		var s16 := int(clampi(sample * 32767.0, -32768.0, 32767.0))
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _make_soft_blip() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.12
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var volume := 0.26

	for i in sample_count:
		var t := float(i) / sample_rate
		var envelope := exp(-t * 16.0)
		var sample := (
			sin(TAU * 587.0 * t) * 0.55
			+ sin(TAU * 880.0 * t) * 0.35
			+ sin(TAU * 1175.0 * t) * 0.15
		) * envelope * volume
		var s16 := int(clampi(sample * 32767.0, -32768.0, 32767.0))
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func play_sfx(id: StringName) -> void:
	if not _streams.has(id):
		return
	_maybe_vibrate()
	if not sounds_enabled:
		return
	var stream: AudioStream = _streams[id]
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = linear_to_db(sfx_volume)
			p.play()
			return


func _maybe_vibrate() -> void:
	if GameState.vibration_enabled:
		GameState.vibrate_handheld(18)


var _music_hooked := false


func play_music(id: StringName) -> void:
	if not _streams.has(id):
		return
	if not sounds_enabled:
		stop_music()
		return
	_music_player.stream = _streams[id]
	_music_player.volume_db = linear_to_db(music_volume)
	if _music_player.stream is AudioStreamWAV:
		_music_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	if not _music_hooked:
		_music_player.finished.connect(_on_music_finished)
		_music_hooked = true
	_music_player.play()


func _on_music_finished() -> void:
	if _music_player.stream != null:
		_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func set_music_volume(linear: float) -> void:
	music_volume = clampf(linear, 0.0, 1.0)
	_music_player.volume_db = linear_to_db(music_volume)


func set_sfx_volume(linear: float) -> void:
	sfx_volume = clampf(linear, 0.0, 1.0)


func set_sounds_enabled(enabled: bool) -> void:
	sounds_enabled = enabled
	if sounds_enabled:
		if _music_player.stream != null and not _music_player.playing:
			_music_player.volume_db = linear_to_db(music_volume)
			_music_player.play()
		else:
			_music_player.volume_db = linear_to_db(music_volume)
	else:
		stop_music()
	SaveService.save_game()
