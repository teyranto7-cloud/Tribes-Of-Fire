extends Node
## Bounded positional pool and separate music/ambience/UI buses.
var game
var pool: Array[AudioStreamPlayer3D] = []
var cursor: int = 0
var ui: AudioStreamPlayer
var wind: AudioStreamPlayer
var music: Array[AudioStreamPlayer] = []
var gains: Array[float] = [0.0, 0.0]
var current: int = 0
var theme: String = ""
var combat_left: float = 0.0
var step_positions: Dictionary = {}
var step_distance: Dictionary = {}
var cache: Dictionary = {}
func configure(value) -> void:
	game = value
	for i in range(16):
		var player := AudioStreamPlayer3D.new()
		player.bus = "Effects"
		player.max_distance = 24
		player.unit_size = 3
		game.add_child(player)
		pool.append(player)
	ui = AudioStreamPlayer.new()
	ui.bus = "UI"
	ui.volume_db = -20
	add_child(ui)
	wind = AudioStreamPlayer.new()
	wind.bus = "Ambient"
	wind.volume_db = -25
	wind.stream = stream("wind", true)
	add_child(wind)
	for i in range(2):
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		add_child(player)
		music.append(player)
	game.world.rain_audio.bus = "Ambient"
	game.world.thunder_audio.bus = "Effects"
func stream(kind: String, loop: bool = false) -> AudioStreamWAV:
	if not cache.has(kind):
		var value = load("res://Assets/Audio/%s.wav" % kind) as AudioStreamWAV
		if value == null: return null
		if loop:
			value.loop_mode = AudioStreamWAV.LOOP_FORWARD
			value.loop_end = int(value.get_length() * value.mix_rate)
		cache[kind] = value
	return cache[kind]
func play(kind: String, at: Vector3) -> void:
	if game.graphics.applied.get("captions",false) and game.hud != null and kind in ["wood","stone","combat","damage","pickup","build"]:
		game.hud.notify_message(TranslationServer.translate({"wood":"Wood cutting","stone":"Mining","combat":"Impact","damage":"Pain","pickup":"Item collected","build":"Building"}[kind]))
	if game.session.role == "dedicated" or not is_instance_valid(game.player) or game.player.position.distance_to(at) > 24: return
	var player := pool[cursor]
	cursor = (cursor + 1) % pool.size()
	player.stop()
	player.stream = stream(kind)
	player.position = at
	player.volume_db = -17 if not kind.begins_with("step") else -24
	player.play()
func click() -> void:
	ui.stream = stream("ui")
	ui.play()
func _process(delta: float) -> void:
	if game == null or game.quitting: return
	if game.session.role == "dedicated":
		for player in music: player.stop()
		wind.stop()
		return
	combat_left = maxf(0, combat_left - delta)
	var next := "menu"
	if game.player != null and game.running:
		if game.player.attack_time > 0 and game.player.action_kind.is_empty(): combat_left = 8
		next = "creation" if game.player.creation_pending else ("combat_music" if combat_left > 0 else ("night" if game.clock.daylight() < 0.1 else "exploration"))
		if not wind.playing: wind.play()
	else:
		wind.stop()
	if next != theme:
		theme = next
		current = 1 - current
		music[current].stop()
		music[current].stream = stream(theme, true)
		music[current].play()
	for i in range(2):
		gains[i] = move_toward(gains[i], 1.0 if i == current else 0.0, delta * 0.65)
		music[i].volume_db = linear_to_db(maxf(0.0001, gains[i] * 0.12))
func _physics_process(_delta: float) -> void:
	if game == null or not game.running or game.player == null or game.session.role == "dedicated": return
	for id in game.players:
		var body = game.players[id]
		if body.creation_pending or body.vitals.hp <= 0 or body.position.distance_to(game.player.position) > 24: continue
		var previous: Vector3 = step_positions.get(id, body.position)
		var moved: float = Vector2(body.position.x - previous.x, body.position.z - previous.z).length()
		step_positions[id] = body.position
		if moved > 3: continue
		step_distance[id] = float(step_distance.get(id, 0)) + moved
		if float(step_distance[id]) > (1.2 if body.stamina > 98 else 1.6):
			step_distance[id] = 0.0
			var h: float = game.world.terrain_height(body.position.x, body.position.z)
			var surface := "water" if h < -2.7 else ("sand" if h < -2.1 else ("dirt" if Vector2(body.position.x, body.position.z).length() < 5 else "grass"))
			play("step_" + surface, body.position)
func stop() -> void:
	set_process(false)
	set_physics_process(false)
	for player in [ui,wind]+music+pool:
		if not is_instance_valid(player): continue
		# Stop the underlying loop before releasing the node's stream. Rapid
		# world reloads can otherwise leave its mixer playback holding the WAV.
		if player.has_stream_playback(): player.get_stream_playback().stop()
		player.stop()
		player.stream=null
	cache.clear()
