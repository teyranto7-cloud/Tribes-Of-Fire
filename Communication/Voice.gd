extends Node
## Capture is opt-in. Audio packets use the separate unreliable ENet channel.
const Codec = preload("res://Communication/ADPCM.gd")
var game
var enabled: bool = false
var open_microphone: bool = false
var testing: bool = false
var volume: float = 0.8
var threshold: float = 0.025
var channel: String = "proximity"
var target: String = ""
var transmitting: bool = false
var level: float = 0.0
var muted: Dictionary = {}
var individual_volume: Dictionary = {}
var status: String = ""
var capture: AudioEffectCapture
var microphone: AudioStreamPlayer
var queued := PackedFloat32Array()
var receivers: Dictionary = {}
var sequence: int = 0
var encoded_bytes: int = 0
var played_samples: int = 0
var captured_packets: int = 0
var _resample_phase: float = 0.0
var _clock: float = 0.0

func configure(value) -> void:
	game = value
	var config := ConfigFile.new()
	if config.load("user://voice.cfg") == OK:
		volume = _setting_number(config.get_value("voice", "volume", 0.8), 0.8, 0, 1)
		threshold = _setting_number(config.get_value("voice", "threshold", 0.025), 0.025, 0.001, 0.2)
		var stored: Variant = config.get_value("voice", "muted", {})
		if stored is Dictionary and stored.size() <= 1024:
			for identity in stored:
				if identity is String and identity.length() <= 128 and stored[identity] is bool:
					muted[identity] = stored[identity]
		var levels: Variant = config.get_value("voice", "individual_volume", {})
		if levels is Dictionary and levels.size() <= 1024:
			for identity in levels:
				if identity is String and identity.length() <= 128:
					individual_volume[identity] = _setting_number(levels[identity], 1, 0, 2)
	# Deliberately do not restore microphone activation on a later launch.
	game.session.voice_received.connect(receive)
	for bus_name in ["Music", "Ambient", "Effects", "UI", "Vocalizations", "Voice", "VoiceCapture"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	var bus := AudioServer.get_bus_index("VoiceCapture")
	AudioServer.set_bus_mute(bus, true)
	capture = AudioEffectCapture.new()
	capture.buffer_length = 0.5
	AudioServer.add_bus_effect(bus, capture)
	microphone = AudioStreamPlayer.new()
	microphone.bus = "VoiceCapture"
	microphone.stream = AudioStreamMicrophone.new()
	add_child(microphone)

func set_enabled(value: bool) -> void:
	enabled = value
	transmitting = false
	queued.clear()
	if enabled:
		if AudioServer.get_input_device_list().is_empty():
			status = "No microphone available"
			enabled = false
			return
		microphone.play()
	else:
		microphone.stop()
		testing = false
		for id in receivers.keys():
			_drop_receiver(id)
	capture.clear_buffer()

func stop_test() -> void:
	# A local loopback test must not keep diverting PTT after its panel is closed.
	testing = false
	queued.clear()
	if capture != null:
		capture.clear_buffer()
	_drop_receiver(-1)

func _drop_receiver(id: int) -> void:
	if not receivers.has(id):
		return
	var output = receivers[id]["player"]
	if is_instance_valid(output):
		output.stop()
		output.queue_free()
	receivers.erase(id)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("voice", "volume", volume)
	config.set_value("voice", "threshold", threshold)
	config.set_value("voice", "muted", muted)
	config.set_value("voice", "individual_volume", individual_volume)
	config.save("user://voice.cfg")

static func _setting_number(value: Variant, fallback: float, minimum: float, maximum: float) -> float:
	return clampf(float(value), minimum, maximum) if (value is float or value is int) and is_finite(float(value)) else fallback

func _process(delta: float) -> void:
	_clock += delta
	transmitting = false
	if enabled and capture != null:
		var frames := capture.get_frames_available()
		if frames > 0:
			# Drain the bounded capture ring even when the render rate is below 12 FPS.
			var input := capture.get_buffer(mini(frames, maxi(4096, int(AudioServer.get_mix_rate() * 0.5))))
			var ratio := 16000.0 / AudioServer.get_mix_rate()
			level = 0.0
			for frame in input:
				var mono := (frame.x + frame.y) * 0.5
				level = maxf(level, absf(mono))
				_resample_phase += ratio
				if _resample_phase >= 1.0:
					_resample_phase -= 1.0
					queued.append(clampf(mono, -1, 1))
		var controls_active: bool = game.player != null and game.player.enabled
		var active := testing or (open_microphone and level >= threshold) or (controls_active and Input.is_action_pressed("push_to_talk"))
		if not active:
			queued.clear()
		while active and queued.size() >= 640:
			var packet := Codec.encode(queued.slice(0, 640))
			captured_packets += 1
			queued = queued.slice(640)
			sequence = (sequence + 1) % 1000000000
			if testing:
				receive(-1, sequence, packet, "test")
			elif game.running and game.player != null and not game.player.creation_pending:
				game.session.send_voice(sequence, packet, channel, target)
				encoded_bytes += packet.size()
				transmitting = true
	for id in receivers.keys():
		var receiver: Dictionary = receivers[id]
		if id >= 0 and (not game.players.has(id) or _clock - float(receiver["last"]) > 5.0):
			_drop_receiver(id)
			continue
		var identity: String = game.runtime.key(id) if id >= 0 and game.players.has(id) else str(id)
		if bool(muted.get(identity, false)):
			_drop_receiver(id)
			continue
		var output = receiver["player"]
		var gain := volume * float(individual_volume.get(identity, 1.0))
		if receiver["channel"] in ["local", "proximity"] and game.player != null and game.players.has(id):
			output.position = game.players[id].position + Vector3.UP * 1.4
			gain *= proximity_gain(game.player.position.distance_to(game.players[id].position))
		output.volume_db = linear_to_db(maxf(0.0001, gain))
		var playback: AudioStreamGeneratorPlayback = receiver["playback"]
		var queue: Array = receiver["queue"]
		if queue.is_empty() or (not receiver["started"] and queue.size() < 2 and _clock - float(receiver["last"]) < 0.08):
			continue
		receiver["started"] = true
		# At 10 FPS the mixer needs 2–3 packets per render frame, rather than one.
		# The existing queue limit of five packets bounds both work and latency.
		while not queue.is_empty():
			var samples: PackedVector2Array = queue[0]
			if playback.get_frames_available() < samples.size() or not playback.push_buffer(samples):
				break
			queue.pop_front()
			played_samples += samples.size()

static func proximity_gain(distance: float, maximum: float = 30.0) -> float:
	if not is_finite(distance) or distance >= maximum:
		return 0.0
	if distance <= 5:
		return 1.0
	var value := clampf(1.0 - (distance - 5) / maxf(0.01, maximum - 5), 0, 1)
	return value * value

func receive(id: int, seq: int, packet: PackedByteArray, voice_channel: String) -> void:
	var identity: String = game.runtime.key(id) if id >= 0 and game.players.has(id) else str(id)
	if not enabled or bool(muted.get(identity, false)):
		return
	if receivers.has(id) and seq <= int(receivers[id]["sequence"]):
		return
	var samples := Codec.decode(packet)
	if samples.is_empty():
		return
	var spatial: bool = voice_channel in ["local", "proximity"]
	if receivers.has(id) and (receivers[id]["player"] is AudioStreamPlayer3D) != spatial:
		receivers[id]["player"].stop()
		receivers[id]["player"].queue_free()
		receivers.erase(id)
	if not receivers.has(id):
		if receivers.size() >= 32:
			return
		var output = AudioStreamPlayer3D.new() if voice_channel in ["local", "proximity"] else AudioStreamPlayer.new()
		var stream := AudioStreamGenerator.new()
		stream.mix_rate = 16000
		stream.buffer_length = 0.24
		output.stream = stream
		output.bus = "Voice"
		if output is AudioStreamPlayer3D:
			output.max_distance = 30.0
			output.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
		game.add_child(output)
		output.play()
		receivers[id] = {"player": output, "playback": output.get_stream_playback(), "queue": [], "sequence": -1, "last": _clock, "started": false, "channel": voice_channel}
	var receiver: Dictionary = receivers[id]
	var missing := mini(2, maxi(0, seq - int(receiver["sequence"]) - 1)) if int(receiver["sequence"]) >= 0 else 0
	for i in range(missing):
		var silence := PackedVector2Array()
		silence.resize(640)
		receiver["queue"].append(silence)
	receiver["sequence"] = seq
	receiver["last"] = _clock
	receiver["channel"] = voice_channel
	receiver["queue"].append(samples)
	while receiver["queue"].size() > 5:
		receiver["queue"].pop_front()

func stop() -> void:
	set_enabled(false)

func _exit_tree() -> void:
	if microphone != null and capture != null:
		stop()
		var bus := AudioServer.get_bus_index("VoiceCapture")
		if bus >= 0:
			for i in range(AudioServer.get_bus_effect_count(bus) - 1, -1, -1):
				if AudioServer.get_bus_effect(bus, i) == capture:
					AudioServer.remove_bus_effect(bus, i)
