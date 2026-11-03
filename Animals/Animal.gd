extends CharacterBody3D
## Original articulated procedural animals. These meshes remain development art.
const Shapes = preload("res://World/Shapes.gd")
static var sound_cache:Dictionary={}
const SPECIES := {
	"rabbit": {"hp": 18, "speed": 4.8, "scale": 0.38, "damage": 0, "range": 0.0, "color": "#bba993", "loot": {"raw_meat": 1, "leather": 1}},
	"deer": {"hp": 45, "speed": 5.5, "scale": 1.0, "damage": 0, "range": 0.0, "color": "#9b7550", "loot": {"raw_meat": 3, "leather": 2, "bone": 1}},
	"boar": {"hp": 65, "speed": 3.2, "scale": 0.8, "damage": 8, "range": 1.5, "color": "#625141", "loot": {"raw_meat": 3, "leather": 2}},
	"fox": {"hp": 28, "speed": 4.5, "scale": 0.55, "damage": 5, "range": 1.2, "color": "#b6743e", "loot": {"raw_meat": 1, "leather": 2}},
	"wolf": {"hp": 60, "speed": 4.0, "scale": 0.85, "damage": 10, "range": 1.7, "color": "#7e8886", "loot": {"raw_meat": 2, "leather": 2, "bone": 1}},
	"bear": {"hp": 150, "speed": 2.8, "scale": 1.35, "damage": 10, "range": 2.2, "color": "#5b4536", "loot": {"raw_meat": 5, "leather": 4, "bone": 2}}
}
var owner_key: String = ""
var loyalty: float = 0.0
var provoked_until: float = 0.0
var respawn_at: float = 0.0
var animal_id: int = 0
var species: String = "deer"
var authoritative: bool = true
var hp: int = 45
var harvested: bool = false
var state: String = "idle"
var home := Vector3.ZERO
var age: float = 0.0
var attack_left: float = 0.0
var special: bool = false
var decision_left: float = 0.0
var intent := Vector3.ZERO
var path: PackedVector3Array = PackedVector3Array()
var path_index: int = 0
var flee_left: float = 0.0
var target_peer: int = 0
var avatar: Node3D
var legs: Array[Node3D] = []
var head: Node3D
var indicator: Label3D
var sound: AudioStreamPlayer3D
var hurt: float = 0.0
var _replica_position := Vector3.ZERO
var _replica_yaw: float = 0.0
var _has_replica: bool = false
var _last_sound: float = -10.0

func setup(id: int, kind: String, at: Vector3, authority: bool) -> void:
	animal_id = id
	species = kind if SPECIES.has(kind) else "deer"
	authoritative = authority
	hp = int(SPECIES[species]["hp"])
	position = at
	home = at
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	floor_snap_length = 0.4
	var s := float(SPECIES[species]["scale"])
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28 * s
	capsule.height = maxf(capsule.radius * 2, 1.1 * s)
	Shapes.collider(self, capsule, Vector3(0, capsule.height * 0.5, 0))
	_build_model(s)
	indicator = Label3D.new()
	indicator.position = Vector3(0, 1.65 * s, 0)
	indicator.font_size = 38
	indicator.pixel_size = 0.008
	indicator.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	indicator.outline_size = 8
	indicator.modulate = Color("#ffbe6e")
	add_child(indicator)
	sound = AudioStreamPlayer3D.new()
	sound.bus = "Vocalizations"
	sound.stream = animal_sound(species)
	sound.volume_db = -23
	sound.max_distance = 22
	add_child(sound)

func ellipsoid(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := Shapes.sculpted(parent, at, size, color, "body", animal_id)
	return mesh

func _build_model(size: float) -> void:
	avatar = Node3D.new()
	avatar.scale = Vector3.ONE * size
	add_child(avatar)
	var color := Color(SPECIES[species]["color"])
	var dark := color.darkened(0.28)
	var fur := color.lightened(0.14)
	var broad := species in ["bear", "boar"]
	var deer := species == "deer"
	var body_height := 0.92 if deer else 0.62
	ellipsoid(avatar, Vector3(0, body_height, 0.08), Vector3(0.72 if broad else 0.48, 0.72 if broad else 0.56, 1.15), color)
	ellipsoid(avatar, Vector3(0, body_height + 0.06, -0.34), Vector3(0.70 if broad else 0.43, 0.66, 0.65), fur)
	for side in [-1.0, 1.0]:
		for z in [-0.36, 0.43]:
			var leg := Node3D.new()
			leg.position = Vector3(side * (0.24 if broad else 0.19), body_height - 0.1, z)
			avatar.add_child(leg)
			var length := 0.78 if deer else 0.48
			Shapes.cylinder(leg, 0.095 if broad else 0.06, length, Vector3(0, -length / 2, 0), dark)
			ellipsoid(leg, Vector3(0, -length, -0.045), Vector3(0.20 if broad else 0.14, 0.13, 0.25), dark)
			legs.append(leg)
	head = Node3D.new()
	head.position = Vector3(0, body_height + (0.42 if deer else 0.15), -0.56)
	avatar.add_child(head)
	if deer:
		Shapes.beam(avatar, Vector3(0, body_height, -0.35), head.position, 0.16, color)
	ellipsoid(head, Vector3.ZERO, Vector3(0.48 if broad else 0.34, 0.48, 0.46), fur)
	var muzzle_length := 0.40 if species in ["wolf", "fox", "boar"] else 0.25
	ellipsoid(head, Vector3(0, -0.075, -0.28), Vector3(0.33 if broad else 0.23, 0.22, muzzle_length), fur.lightened(0.08))
	ellipsoid(head, Vector3(0, -0.045, -0.26 - muzzle_length * 0.48), Vector3(0.14, 0.11, 0.07), Color("#292a27"))
	for side in [-1.0, 1.0]:
		ellipsoid(head, Vector3(side * 0.16, 0.07, -0.16), Vector3(0.07, 0.07, 0.04), Color("#232b27"))
		var ears := Vector3(0.13, 0.50 if species == "rabbit" else 0.25, 0.14)
		var ear := ellipsoid(head, Vector3(side * 0.19, 0.27, 0.01), ears, color)
		ear.rotation.z = side * -0.24
		if deer:
			Shapes.beam(head, Vector3(side * 0.12, 0.23, 0.01), Vector3(side * 0.25, 0.83, 0.09), 0.035, Color("#a99a7e"))
			Shapes.beam(head, Vector3(side * 0.20, 0.57, 0.06), Vector3(side * 0.42, 0.70, -0.05), 0.025, Color("#a99a7e"))
		if species == "boar":
			Shapes.beam(head, Vector3(side * 0.17, -0.15, -0.38), Vector3(side * 0.22, 0.02, -0.44), 0.035, Color("#d7ccb0"))
	var tail := ellipsoid(avatar, Vector3(0, body_height + 0.03, 0.79), Vector3(0.15, 0.17, 0.55 if species in ["wolf", "fox"] else 0.18), fur)
	if species == "fox":
		tail.material_override = Shapes.material(Color("#d9cbb1"))
	if species == "bear":
		ellipsoid(avatar, Vector3(0, 0.98, -0.18), Vector3(0.78, 0.52, 0.8), dark)

func visual_tick(delta: float, distance: float = 0.0) -> void:
	age += delta
	hurt = maxf(0, hurt - delta)
	if not authoritative and _has_replica:
		position = position.lerp(_replica_position, 1 - exp(-12 * delta))
		rotation.y = lerp_angle(rotation.y, _replica_yaw, 1 - exp(-12 * delta))
	if avatar == null:return
	visible=distance<85 and not harvested
	if distance>65:return
	if hp <= 0:
		avatar.rotation.z = move_toward(avatar.rotation.z, 1.35, delta * 2.6)
		indicator.text = ""
		visible = not harvested
		return
	var speed := Vector2(velocity.x, velocity.z).length() if authoritative else (1.5 if state in ["wander", "flee", "chase"] else 0.0)
	for i in range(legs.size()):
		legs[i].rotation.x = sin(age * (8 if state == "flee" else 5.5) + (PI if i in [1, 2] else 0.0)) * minf(0.65, speed * 0.14)
	avatar.position.y = sin(age * 3) * 0.012 + sin(hurt * 35) * hurt * 0.1
	head.rotation.x = sin(age * 1.2) * 0.04 - (0.22 if state == "windup" else 0.0)
	indicator.text = "!!" if state == "windup" and special else ("!" if state == "windup" else "")
	if state in ["chase", "windup"] and age - _last_sound > 4.0:
		_last_sound = age
		if sound != null:
			sound.play()

func simulate(delta: float) -> void:
	if not authoritative or hp <= 0:
		return
	var speed := float(SPECIES[species]["speed"])
	if state not in ["flee", "chase"]:
		speed *= 0.38
	var desired := intent * speed
	velocity.x = move_toward(velocity.x, desired.x, delta * 8)
	velocity.z = move_toward(velocity.z, desired.z, delta * 8)
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = -0.2
	if intent.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-intent.x, -intent.z), minf(1, delta * 7))
	move_and_slide()
	var extent: float = get_parent().world.half_extent() - 1
	position.x = clampf(position.x, -extent, extent)
	position.z = clampf(position.z, -extent, extent)

func receive_damage(amount: int) -> bool:
	if not authoritative or amount <= 0 or hp <= 0:
		return false
	hp = maxi(0, hp - amount)
	hurt = 0.3
	flee_left = 8.0
	if hp <= 0:
		state = "dead"
		intent = Vector3.ZERO
		velocity = Vector3.ZERO
		collision_layer = 0
	return true

func capture() -> Dictionary:
	return {"id": animal_id, "species": species, "position": [position.x, position.y, position.z],
		"home": [home.x, home.y, home.z], "yaw": rotation.y, "hp": hp,
		"harvested": harvested, "state": state, "age": age, "attack_left": attack_left, "owner": owner_key, "loyalty": loyalty, "respawn_at": respawn_at}

func apply_snapshot(data: Dictionary) -> void:
	var p: Array = data["position"]
	_replica_position = Vector3(p[0], p[1], p[2])
	if not _has_replica:
		position = _replica_position
	_has_replica = true
	_replica_yaw = float(data["yaw"])
	hp = int(data["hp"])
	harvested = bool(data["harvested"])
	state = str(data["state"])
	owner_key = str(data.get("owner",""))
	loyalty = clampf(float(data.get("loyalty",0)),0,100)
	respawn_at = float(data.get("respawn_at",0))
	attack_left = float(data["attack_left"])
	var h: Array = data["home"]
	home = Vector3(h[0], h[1], h[2])
	if authoritative:
		position = _replica_position
		rotation.y = _replica_yaw
		age = float(data["age"])
	collision_layer = 4 if hp > 0 else 0
	visible = not harvested

static func animal_sound(kind: String) -> AudioStreamWAV:
	if sound_cache.has(kind):return sound_cache[kind]
	var data := PackedByteArray()
	var frames := 8000
	data.resize(frames * 2)
	var frequency := 100.0 if kind == "bear" else (210.0 if kind == "wolf" else 360.0)
	for i in range(frames):
		var t := i / 22050.0
		var amplitude := sin(PI * float(i) / frames)
		var sample := sin(TAU * t * (frequency + sin(t * 15) * 18)) * 0.2
		data.encode_s16(i * 2, int(sample * amplitude * 16000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	sound_cache[kind]=stream
	return stream
