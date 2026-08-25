class_name SfxManager
extends RefCounted

var _events := SfxEvents.new()
var _players: Array[AudioStreamPlayer] = []
var _cursor: int = 0
var hit_sfx: AudioStreamWAV
var heavy_sfx: AudioStreamWAV
var ultimate_sfx: AudioStreamWAV
var down_sfx: AudioStreamWAV
var core_sfx: AudioStreamWAV
var tower_sfx: AudioStreamWAV

func setup(parent: Node) -> void:
	for index in range(8):
		var player := AudioStreamPlayer.new()
		player.name = "ImpactSfx%d" % index
		parent.add_child(player)
		_players.append(player)
	hit_sfx = _make_stream(185.0, 0.075, 0.22)
	heavy_sfx = _make_stream(105.0, 0.14, 0.52)
	ultimate_sfx = _make_stream(72.0, 0.24, 0.38)
	down_sfx = _make_stream(48.0, 0.34, 0.60)
	core_sfx = _make_stream(255.0, 0.10, 0.12)
	tower_sfx = _make_stream(92.0, 0.16, 0.18)

func play_id(sound_id: String, volume_db: float = -5.0) -> void:
	_events.play(sound_id, volume_db, 0.04)

func play(stream: AudioStreamWAV, volume_db: float = -5.0) -> void:
	if stream == null or _players.is_empty():
		return
	var player := _players[_cursor]
	_cursor = (_cursor + 1) % _players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 0.96 + 0.025 * float(_cursor % 4)
	player.play()

func process_events(world, local_slot: int, last_event_id: int) -> Dictionary:
	var new_last := last_event_id
	var hit_pause := 0
	for event in world.event_log.events:
		var event_id := int(event["event_id"])
		if event_id <= last_event_id:
			continue
		new_last = event_id
		hit_pause = _events.handle(world, event, local_slot, hit_pause)
	return {"last_event_id": new_last, "hit_pause": hit_pause}

func _make_stream(frequency: float, duration: float, noise_mix: float) -> AudioStreamWAV:
	var mix_rate := 22050
	var sample_count := maxi(1, roundi(duration * mix_rate))
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for sample in range(sample_count):
		var t := float(sample) / float(mix_rate)
		var progress := float(sample) / float(sample_count)
		var envelope := pow(1.0 - progress, 2.4)
		var pitch_drop := frequency * (1.0 - progress * 0.42)
		var tone := sin(TAU * pitch_drop * t)
		var grit := sin(TAU * (frequency * 7.13) * t + sin(t * 913.0))
		var value := clampf((tone * (1.0 - noise_mix) + grit * noise_mix) * envelope * 0.72, -1.0, 1.0)
		pcm.encode_s16(sample * 2, roundi(value * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = pcm
	return stream
