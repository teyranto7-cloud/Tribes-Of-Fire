extends SceneTree
const Codec = preload("res://Communication/ADPCM.gd")
const Store = preload("res://Persistence/Store.gd")
const CommunicationPanel = preload("res://UI/CommunicationPanel.gd")
var checks: int = 0
var failed: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failed += 1
		push_error(message)
func run() -> void:
	var game = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.save_folder = "user://voice-regression/%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	while not game.ready_world:
		await process_frame
	game.new_game()
	game.set_process(false)
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	var voice = game.runtime.voice
	voice.set_process(false)
	voice.muted.clear()
	voice.enabled = true # Receive-only opt-in: never start AudioStreamMicrophone.
	game.hud.show_panel("communication")
	var samples := PackedFloat32Array()
	samples.resize(640)
	for i in range(640):
		samples[i] = sin(i * 0.1) * 0.2
	var packet := Codec.encode(samples)
	for i in range(5):
		voice.receive(-1, i + 1, packet, "test")
	var available: int = voice.receivers[-1]["playback"].get_frames_available()
	var before: int = voice.played_samples
	voice._process(0.1)
	check(available >= 3200 and voice.played_samples - before == 3200 and voice.receivers[-1]["queue"].is_empty(), "A 10 FPS frame drains all five buffered audio packets when the generator has space")
	check(not voice.microphone.playing, "Playback regression uses synthetic packets and never starts a physical microphone")
	voice.testing = true
	game.hud.show_panel("pause")
	await process_frame
	check(not voice.testing, "Closing the communication panel ends local microphone test mode")
	check(not voice.receivers.has(-1), "Closing the panel stops queued local loopback playback")
	check(voice.enabled, "Closing a test preserves previously explicit voice activation")
	game.hud.show_panel("communication")
	for child in game.hud.column.get_children():
		if child.get_script() == CommunicationPanel:
			child.set("_test_auto_enabled", true)
	voice.testing = true
	game.hud.show_panel("pause")
	await process_frame
	check(not voice.testing and not voice.enabled, "Closing a test restores disabled voice when activation was temporary")
	voice.enabled = true
	voice.receive(1, 100, packet, "private")
	var identity: String = game.runtime.key(1)
	voice.muted[identity] = true
	before = voice.played_samples
	voice._process(0.1)
	check(not voice.receivers.has(1) and voice.played_samples == before, "Muting an existing speaker stops its already queued playback")
	voice.stop()
	check(voice.receivers.is_empty() and not voice.microphone.playing, "Disabling voice releases all playback streams")
	game.runtime.audio.stop()
	print("VOICE_REGRESSION CHECKS=%d FAILED=%d" % [checks, failed])
	await game.quit_game(0 if failed == 0 else 1,false)
