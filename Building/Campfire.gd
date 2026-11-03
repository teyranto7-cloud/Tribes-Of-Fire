extends Node3D

const Shapes = preload("res://World/Shapes.gd")
const Balance = preload("res://Game/Balance.gd")
static var crackle: AudioStreamWAV
var flames: Array[MeshInstance3D] = []
var light: OmniLight3D
var age: float = 0.0
var fuel: float = 300.0
var lit: bool = true
var sound: AudioStreamPlayer3D
var embers: CPUParticles3D
var smoke: CPUParticles3D

func _ready() -> void:
	fuel = Balance.number("fire", "initial_fuel", 300.0)
	for i in range(10):
		var angle := i / 10.0 * TAU
		var stone := Shapes.sphere(self, 0.18, Vector3(cos(angle) * 0.6, 0.13, sin(angle) * 0.6), Color("#687074"))
		stone.scale = Vector3(1.1, 0.65, 0.85)
	for i in range(3):
		var log_mesh := Shapes.cylinder(self, 0.095, 0.85, Vector3(0, 0.2, 0), Color("#493225"))
		log_mesh.rotation = Vector3(PI / 2.0, i * PI / 3.0, 0)
	for i in range(5):
		var flame := Shapes.sphere(self, 0.16, Vector3(sin(i * 2.0) * 0.18, 0.5, cos(i * 2.0) * 0.18), Color("#ffb64a") if i % 2 == 0 else Color("#ff7138"), 2.3)
		flames.append(flame)
	var body := StaticBody3D.new()
	add_child(body)
	var shape := CylinderShape3D.new()
	shape.radius = 0.65
	shape.height = 0.25
	Shapes.collider(body, shape, Vector3(0, 0.125, 0))
	light = OmniLight3D.new()
	light.position.y = 0.85
	light.omni_range = 8.0
	light.light_color = Color("#ffbd79")
	light.light_energy = 3.0
	add_child(light)
	embers = make_particles(22, 1.6, Color("#ffb54f"), 0.035, true)
	embers.initial_velocity_min = 0.8
	embers.initial_velocity_max = 1.6
	embers.gravity = Vector3(0.05, 0.3, 0)
	smoke = make_particles(16, 3.2, Color(0.36, 0.36, 0.33, 0.18), 0.2, false)
	smoke.position.y = 0.8
	smoke.gravity = Vector3(0.1, 0.18, 0)
	smoke.initial_velocity_min = 0.3
	smoke.initial_velocity_max = 0.7
	sound = AudioStreamPlayer3D.new()
	sound.bus = "Ambient"
	sound.stream = make_crackle()
	sound.unit_size = 4.0
	sound.max_distance = 18.0
	sound.volume_db = -23.0
	add_child(sound)
	sound.play()
	_refresh_burning()

func make_particles(count: int, lifetime: float, color: Color, radius: float, glowing: bool) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = count
	p.lifetime = lifetime
	p.position.y = 0.55
	p.direction = Vector3.UP
	p.spread = 22
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2
	sphere.radial_segments = 4
	sphere.rings = 3
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if glowing else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if glowing:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 2
	sphere.material = m
	p.mesh = sphere
	add_child(p)
	return p

func set_quality(value: int) -> void:
	light.shadow_enabled = value >= 2
	embers.amount = [8, 16, 24, 36][clampi(value, 0, 3)]
	smoke.emitting = value > 0

static func make_crackle() -> AudioStreamWAV:
	if crackle != null:
		return crackle
	var rng := RandomNumberGenerator.new()
	rng.seed = 92147
	var pcm := PackedByteArray()
	var frames := 44100
	pcm.resize(frames * 2)
	var filtered := 0.0
	for i in range(frames):
		filtered = lerpf(filtered, rng.randf_range(-1.0, 1.0), 0.18)
		var pop := rng.randf_range(-0.7, 0.7) if rng.randf() < 0.003 else 0.0
		pcm.encode_s16(i * 2, int(clampf(filtered + pop, -1, 1) * 14000))
	crackle = AudioStreamWAV.new()
	crackle.format = AudioStreamWAV.FORMAT_16_BITS
	crackle.mix_rate = 22050
	crackle.data = pcm
	crackle.loop_mode = AudioStreamWAV.LOOP_FORWARD
	crackle.loop_end = frames
	return crackle

func _process(delta: float) -> void:
	if not lit:
		return
	age += delta
	for i in range(flames.size()):
		var pulse := sin(age * (7.0 + i) + i)
		flames[i].scale = Vector3(0.8, 1.5 + pulse * 0.5, 0.8)
		flames[i].position.y = 0.5 + pulse * 0.08
	light.light_energy = 2.8 + sin(age * 13.0) * 0.2

func advance(delta: float, raining: bool, covered: bool) -> void:
	if not lit or not is_finite(delta) or delta <= 0:
		return
	fuel = maxf(0.0, fuel - delta * (Balance.number("fire", "rain_drain", 4.0) if raining and not covered else 1.0))
	if fuel <= 0.0 or (raining and not covered):
		lit = false
		_refresh_burning()

func add_fuel(amount: float) -> bool:
	var maximum := Balance.number("fire", "max_fuel", 3600.0)
	if not is_finite(amount) or amount <= 0 or fuel >= maximum:
		return false
	fuel = minf(maximum, fuel + amount)
	lit = true
	_refresh_burning()
	return true

func restore_state(state: Dictionary) -> void:
	fuel = clampf(float(state.get("fuel", fuel)), 0, Balance.number("fire", "max_fuel", 3600.0))
	lit = bool(state.get("lit", fuel > 0)) and fuel > 0
	_refresh_burning()

func state() -> Dictionary:
	return {"position": [position.x, position.y, position.z], "fuel": fuel, "lit": lit}

func _refresh_burning() -> void:
	for flame in flames: flame.visible = lit
	if light != null: light.light_energy = 2.8 if lit else 0.0
	if embers != null: embers.emitting = lit
	if smoke != null: smoke.emitting = lit
	if sound != null:
		if lit and not sound.playing: sound.play()
		elif not lit and sound.playing: sound.stop()
