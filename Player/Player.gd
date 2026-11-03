extends CharacterBody3D
## Authority runs physics; clients submit intent and render server snapshots.
## All meshes are original procedural geometry, with no external assets.

const Balance = preload("res://Game/Balance.gd")
const Vitals = preload("res://Core/Vitals.gd")
const Appearance = preload("res://Character/Appearance.gd")
const INTENT_TIMEOUT := 0.35
const WALK_SPEED := 4.0
const RUN_SPEED := 7.0

signal respawned

var action_kind: String = ""
var action_left: float = 0.0
var swimming: bool = false
var first_person: bool = false
var invert_y: bool = false
var respawn_position := Vector3.ZERO
var world: Node3D
var vitals = Vitals.new()
var stamina: float = 100.0
var enabled: bool = false
var local_control: bool = true
var authoritative: bool = true
var yaw: float = 0.0
var pitch: float = -0.24
var sensitivity: float = 0.003
var attack_time: float = 0.0
var death_left: float = 0.0
var auto_respawn: bool = true
var blocking: bool = false
var crouching: bool = false
var dodging: float = 0.0
var dodge_cooldown: float = 0.0
var appearance: Dictionary = Appearance.DEFAULT.duplicate(true)
var creation_pending: bool = false
var zoom: float = 4.8
var camera_smoothing: bool = true
var _camera_yaw: float = 0.0
var body_shape: CollisionShape3D
var _dodge_direction := Vector3.ZERO
var visual_equipment: Dictionary = {"hand": "axe", "offhand": "", "armor": ""}

var boat: Node3D
var rig: Node3D
var arm: SpringArm3D
var camera: Camera3D
var avatar: Node3D
var torso: Node3D
var head: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_knee: Node3D
var right_knee: Node3D
var left_arm: Node3D
var axe_arm: Node3D
var axe: Node3D
var label: Label3D

var _move := Vector2.ZERO
var _sprint: bool = false
var _jump: bool = false
var _intent_age: float = 0.0
var _stride: float = 0.0
var _age: float = 0.0
var _landing: float = 0.0
var _hurt: float = 0.0
var _last_hp: int = 100
var _remote_target := Vector3.ZERO
var _remote_yaw: float = 0.0
var _remote_initialized: bool = false
var _remote_grounded: bool = true
var _remote_velocity := Vector3.ZERO
var _airborne: bool = false
var _swing: float = 0.0
var _materials: Dictionary = {}


func _ready() -> void:
	collision_layer = 2
	collision_mask = 7
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(48.0)
	var collider := CollisionShape3D.new()
	body_shape = collider
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.31
	capsule.height = 1.82
	collider.shape = capsule
	collider.position.y = 0.91
	add_child(collider)
	arm = SpringArm3D.new()
	arm.position.y = 1.48
	arm.spring_length = 4.8
	arm.margin = 0.18
	arm.collision_mask = 1
	arm.add_excluded_object(get_rid())
	add_child(arm)
	camera = Camera3D.new()
	camera.fov = 70.0
	camera.near = 0.08
	camera.far = 160.0
	arm.add_child(camera)
	camera.current = local_control
	arm.rotation.x = pitch
	label = Label3D.new()
	label.position.y = 2.15
	label.font_size = 32
	label.pixel_size = 0.007
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 8
	label.modulate = Color("#f8e3b6")
	label.text = name
	label.visible = not local_control
	add_child(label)
	_remote_target = position
	_last_hp = vitals.hp
	set_appearance(appearance, true)

func set_appearance(data: Dictionary, force: bool = false) -> void:
	if Appearance.valid(data) and (force or hash(data) != hash(appearance)):
		Appearance.apply(self, data)


func _mat(key: String, color: Color, roughness: float = 0.85) -> StandardMaterial3D:
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = roughness
		_materials[key] = material
	return _materials[key]


func _mesh(parent: Node3D, mesh: Mesh, at: Vector3,
		material: StandardMaterial3D, scale_value: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = at
	node.scale = scale_value
	parent.add_child(node)
	return node


func _ellipsoid(parent: Node3D, at: Vector3, size: Vector3,
		material: StandardMaterial3D, segments: int = 16) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = segments
	mesh.rings = 8
	return _mesh(parent, mesh, at, material, size)


func _taper(parent: Node3D, at: Vector3, bottom: float, top: float,
		height: float, material: StandardMaterial3D, flatten: float = 1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = 12
	return _mesh(parent, mesh, at, material, Vector3(1.0, 1.0, flatten))


func _pivot(parent: Node3D, at: Vector3) -> Node3D:
	var node := Node3D.new()
	node.position = at
	parent.add_child(node)
	return node


func set_local(value: bool) -> void:
	local_control = value
	if is_instance_valid(camera):
		camera.current = value
	if is_instance_valid(label):
		label.visible = not value


func _unhandled_input(event: InputEvent) -> void:
	if local_control and enabled and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 0.4, 1.5, 8.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 0.4, 1.5, 8.0)
	if local_control and enabled and event is InputEventMouseMotion \
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * sensitivity
		pitch = clampf(pitch - event.relative.y * sensitivity * (-1 if invert_y else 1), -0.95, 0.48)


func input_intent() -> Dictionary:
	var move := Vector2.ZERO
	var sprint := false
	var jump := false
	var active: bool = local_control and enabled and death_left <= 0 and vitals.hp > 0 and not creation_pending
	if active:
		move = Input.get_vector("left", "right", "forward", "back")
		sprint = Input.is_action_pressed("sprint")
		jump = Input.is_action_just_pressed("jump")
	return {"move": [move.x, move.y], "yaw": yaw, "jump": jump, "sprint": sprint,
		"crouch": active and Input.is_action_pressed("crouch"), "block": active and Input.is_action_pressed("block"), "dodge": active and Input.is_action_just_pressed("dodge")}


func set_intent(data: Dictionary) -> void:
	if vitals.hp <= 0 or creation_pending:
		_clear_intent()
		return
	var raw: Variant = data.get("move", [0.0, 0.0])
	var move := Vector2.ZERO
	if raw is Vector2:
		move = raw
	elif raw is Array and raw.size() == 2 and _finite_number(raw[0]) and _finite_number(raw[1]):
		move = Vector2(float(raw[0]), float(raw[1]))
	if not is_finite(move.x) or not is_finite(move.y):
		return
	_move = move.limit_length(1.0)
	var heading: Variant = data.get("yaw", yaw)
	if _finite_number(heading):
		yaw = wrapf(float(heading), -PI, PI)
	_sprint = data.get("sprint", false) == true
	crouching = data.get("crouch", false) == true
	blocking = data.get("block", false) == true and stamina > 2
	if data.get("dodge", false) == true and dodge_cooldown <= 0 and stamina >= 20:
		dodging = 0.45
		dodge_cooldown = 1.3
		stamina -= 20
		_dodge_direction = global_basis * Vector3(_move.x, 0, _move.y) if _move.length() > 0.1 else -global_basis.z
	# Preserve a press until the next server physics tick consumes it.
	_jump = _jump or data.get("jump", false) == true
	_intent_age = 0.0

func _clear_intent() -> void:
	_move = Vector2.ZERO
	_sprint = false
	_jump = false
	blocking = false
	crouching = false
	dodging = 0.0
	_dodge_direction = Vector3.ZERO


func _finite_number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))


func _physics_process(delta: float) -> void:
	_age += delta
	action_left = maxf(0, action_left - delta)
	if action_left == 0: action_kind = ""
	if avatar != null: avatar.visible = not (first_person and local_control)
	if vitals.hp <= 0:
		_clear_intent()
		velocity.x = 0.0
		velocity.z = 0.0
	dodging = maxf(0, dodging - delta)
	dodge_cooldown = maxf(0, dodge_cooldown - delta)
	attack_time = maxf(0, attack_time - delta)
	if is_instance_valid(arm):
		arm.rotation.x = lerp_angle(arm.rotation.x, pitch, 1 - exp(-delta * 12)) if camera_smoothing else pitch
		arm.spring_length = lerpf(arm.spring_length, 0.0 if first_person else zoom, 1 - exp(-delta * 10)) if camera_smoothing else (0.0 if first_person else zoom)
		_camera_yaw = lerp_angle(_camera_yaw, yaw, 1 - exp(-delta * 14)) if camera_smoothing else yaw
		arm.rotation.y = _camera_yaw - rotation.y
	if not authoritative:
		if _remote_initialized:
			position = position.lerp(_remote_target, 1.0 - exp(-16.0 * delta))
			rotation.y = yaw if local_control else lerp_angle(rotation.y, _remote_yaw, 1.0 - exp(-14.0 * delta))
		_animate(delta, Vector2(_remote_velocity.x, _remote_velocity.z).length(), _remote_grounded)
		return
	if is_instance_valid(boat) and vitals.hp>0:
		_sail(delta);return
	if world != null and world.has_method("has_terrain_at") and not world.has_terrain_at(position) and world.terrain_height(position.x,position.z) > world.water_level:
		velocity=Vector3.ZERO
		return
	_intent_age += delta
	if _intent_age > INTENT_TIMEOUT:
		_move = Vector2.ZERO
		_sprint = false
		_jump = false
	if vitals.hp <= 0 and death_left <= 0:
		death_left = 1.2
	if death_left > 0:
		death_left -= delta
		_move = Vector2.ZERO
		_jump = false
		if death_left <= 0 and auto_respawn:
			respawn()
		elif not auto_respawn:
			death_left = maxf(0.01, death_left)
	rotation.y = yaw
	var direction := global_basis * Vector3(_move.x, 0, _move.y)
	if dodging > 0:
		direction = _dodge_direction
	var sprint: bool = _sprint and stamina > 1.0 and _move.length_squared() > 0.01 and death_left <= 0
	var speed: float = Balance.number("player", "sprint_speed", RUN_SPEED) if sprint else Balance.number("player", "walk_speed", WALK_SPEED)
	if crouching or blocking:
		speed *= 0.5
	if dodging > 0:
		speed = 9.0
	stamina = clampf(stamina + (-14.0 if sprint else (-6.0 if blocking else 18.0)) * delta, 0.0, 100.0)
	if stamina < 2:
		blocking = false
	if crouching:
		body_shape.shape.height = 1.14
		body_shape.position.y = 0.57
	elif body_shape.shape.height < 1.5:
		var standing := CapsuleShape3D.new()
		standing.radius = 0.3
		standing.height = 1.76
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = standing
		query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3.UP * 0.95)
		query.collision_mask = 7
		query.exclude = [get_rid()]
		if get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			body_shape.shape.height = 1.82
			body_shape.position.y = 0.91
		else:
			crouching = true
	arm.position.y = lerpf(arm.position.y, 1.03 if crouching else 1.48, 1 - exp(-delta * 12))
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 24.0)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 24.0)
	swimming = world != null and "water_level" in world and position.y + 0.9 < world.water_level
	var grounded: bool = is_on_floor()
	if swimming:
		velocity.x *= 0.65
		velocity.z *= 0.65
		velocity.y = clampf((world.water_level - position.y - 0.65) * 3, -2, 2)
		if _jump: velocity.y = 3
	elif not grounded:
		velocity.y -= Balance.number("player", "gravity", 20) * delta
	elif _jump and death_left <= 0:
		velocity.y = Balance.number("player", "jump_velocity", 7)
	_jump = false
	var falling_speed: float = velocity.y
	move_and_slide()
	if is_on_floor() and not grounded:
		_landing = minf(0.3, absf(falling_speed) * 0.025)
		if falling_speed < -14.0:
			vitals.damage(mini(90, int((-falling_speed - 14.0) * 3.0)))
	var extent: float = world.half_extent() if world != null and world.has_method("half_extent") else 60.0
	if extent <= 60:
		position.x = clampf(position.x, -extent, extent)
		position.z = clampf(position.z, -extent, extent)
	elif maxf(absf(position.x), absf(position.z)) > extent - 8:
		var current := -Vector3(position.x, 0, position.z).normalized() * 8
		velocity.x = current.x
		velocity.z = current.z
	if position.y < -15.0:
		vitals.damage(100)
	_animate(delta, Vector2(velocity.x, velocity.z).length(), is_on_floor())


func _animate(delta: float, speed: float, grounded: bool) -> void:
	if not is_instance_valid(avatar):
		return
	if vitals.hp < _last_hp:
		_hurt = 0.35
	_last_hp = vitals.hp
	_hurt = maxf(0.0, _hurt - delta)
	_landing = move_toward(_landing, 0.0, delta * 1.3)
	var movement: float = clampf(speed / 4.0, 0.0, 1.4)
	_stride += delta * speed * 2.3
	var target_swing: float = sin(_stride) * minf(movement, 1.1) * 0.65 if grounded else 0.15
	_swing = lerpf(_swing, target_swing, 1.0 - exp(-18.0 * delta))
	var blend:float=1.0-exp(-14.0*delta)
	left_leg.rotation.x = lerp_angle(left_leg.rotation.x,_swing if grounded else -0.35,blend)
	right_leg.rotation.x = lerp_angle(right_leg.rotation.x,-_swing if grounded else 0.35,blend)
	left_knee.rotation.x = maxf(0, -_swing) * 0.65 if grounded else 0.65
	right_knee.rotation.x = maxf(0, _swing) * 0.65 if grounded else 0.8
	left_arm.rotation.x = -_swing * 0.65 if grounded else -0.4
	var attack_phase: float = 1.0 - attack_time / 0.55
	var strike: float = sin(attack_phase * PI) * 2.1 if attack_time > 0 else 0.0
	axe_arm.rotation.x = _swing * 0.4 - strike
	axe_arm.rotation.z = -0.08 - strike * 0.15
	left_arm.rotation.z = 0.08
	avatar.position.y = (absf(sin(_stride)) * 0.035 * movement if grounded else 0.0) - _landing * 0.35
	torso.rotation.x = -0.045 * movement - sin(_hurt * 24.0) * _hurt * 0.25
	torso.rotation.z = sin(_stride * 0.5) * movement * 0.025
	if crouching:
		avatar.position.y -= 0.25
		torso.rotation.x += 0.22
	if blocking:
		left_arm.rotation.x = -1.1
	torso.scale.y = 1.0 + sin(_age * 2.2) * 0.008
	head.rotation.y = sin(_age * 0.7) * 0.035 * (1.0 - minf(1.0, movement))
	if swimming:
		torso.rotation.x = -0.35
		left_arm.rotation.x = sin(_age*5)*0.8
		axe_arm.rotation.x = -sin(_age*5)*0.8
		left_leg.rotation.x = sin(_age*6)*0.25
		right_leg.rotation.x = -sin(_age*6)*0.25
	if is_instance_valid(boat):
		left_leg.rotation.x=-1.2;right_leg.rotation.x=-1.2
		left_knee.rotation.x=1.5;right_knee.rotation.x=1.5
		left_arm.rotation.x=-0.7+sin(_age*4)*0.35;axe_arm.rotation.x=-0.7-sin(_age*4)*0.35
	if vitals.hp <= 0:
		avatar.rotation.z = move_toward(avatar.rotation.z, -1.3, delta * 3.0)
		avatar.position.y = -0.1
	else:
		avatar.rotation.z = move_toward(avatar.rotation.z, 0.0, delta * 6.0)


func attack() -> bool:
	if not authoritative or vitals.hp <= 0 or attack_time > 0 or stamina < 8.0 or blocking or dodging > 0:
		return false
	attack_time = 0.55
	stamina -= 8.0
	return true


func respawn() -> void:
	boat=null
	set_meta("death_handled",false)
	_clear_intent()
	attack_time = 0.0
	dodge_cooldown = 0.0
	_intent_age = INTENT_TIMEOUT
	var y := 1.6
	if is_instance_valid(world) and world.has_method("terrain_height"):
		y = float(world.terrain_height(0.0, 0.0)) + 0.2
	position = respawn_position if respawn_position != Vector3.ZERO else Vector3(0, y, 0)
	velocity = Vector3.ZERO
	vitals.hp = 100
	vitals.quiet_seconds = 0.0
	vitals.regen_block_left = 0.0
	stamina = 100.0
	death_left = 0.0
	_hurt = 0.0
	respawned.emit()


func export_state() -> Dictionary:
	return {
		"position": [position.x, position.y, position.z],
		"velocity": [velocity.x, velocity.y, velocity.z],
		"yaw": yaw, "hp": vitals.hp, "stamina": stamina,
		"attack_time": attack_time, "grounded": is_on_floor(),
		"boat": boat.structure_id if is_instance_valid(boat) else 0, "appearance": appearance, "creation_pending": creation_pending,
		"blocking": blocking, "crouching": crouching, "dodging": dodging,
		"equipment": visual_equipment, "action_kind": action_kind, "action_left": action_left, "swimming": swimming,
	}


func apply_state(data: Dictionary) -> void:
	var p: Variant = data.get("position", [])
	if not p is Array or p.size() != 3:
		return
	for value in p:
		if not _finite_number(value):
			return
	_remote_target = Vector3(float(p[0]), float(p[1]), float(p[2]))
	if not _remote_initialized or position.distance_squared_to(_remote_target) > 64.0:
		position = _remote_target
	_remote_initialized = true
	_remote_yaw = float(data.get("yaw", 0.0))
	if not local_control:
		yaw = _remote_yaw
	vitals.hp = clampi(int(data.get("hp", 100)), 0, 100)
	if data.get("appearance") is Dictionary:
		set_appearance(data["appearance"])
	boat=world.get_structure(int(data.get("boat",0))) if world!=null and world.has_method("get_structure") else null
	creation_pending = bool(data.get("creation_pending", false))
	visible = not creation_pending
	blocking = bool(data.get("blocking", false))
	crouching = bool(data.get("crouching", false))
	dodging = clampf(float(data.get("dodging", 0)), 0, 0.55)
	if data.get("equipment") is Dictionary:
		set_equipment(data["equipment"])
	stamina = clampf(float(data.get("stamina", 100)), 0.0, 100.0)
	attack_time = clampf(float(data.get("attack_time", 0)), 0.0, 0.55)
	var kind := str(data.get("action_kind", ""))
	var remaining := clampf(float(data.get("action_left", 0)), 0, 30)
	if kind != action_kind or remaining > action_left + 0.3: play_action(kind, remaining)
	swimming = bool(data.get("swimming", false))
	_remote_grounded = data.get("grounded", true) == true
	var v: Variant = data.get("velocity", [0, 0, 0])
	if v is Array and v.size() == 3:
		_remote_velocity = Vector3(float(v[0]), float(v[1]), float(v[2]))

func set_equipment(data: Dictionary, force: bool = false) -> void:
	if not force and data == visual_equipment:
		return
	visual_equipment = {"hand": str(data.get("hand", "axe")), "offhand": str(data.get("offhand", "")), "armor": str(data.get("armor", ""))}
	preload("res://Character/Equipment.gd").apply(self, visual_equipment)

func play_action(kind: String, seconds: float) -> void:
	if seconds <= 0 or not is_finite(seconds): return
	action_kind = kind
	action_left = minf(30, seconds)
	if is_instance_valid(rig) and rig.has_method("start_action"): rig.start_action(kind, seconds)

func _sail(delta: float) -> void:
	_intent_age+=delta
	if _intent_age>0.5:_clear_intent()
	boat.rotation.y-=_move.x*delta*0.8
	var next:Vector3=boat.position-boat.global_basis.z*(-_move.y)*5.0*delta
	if world.contains_position(next) and world.terrain_height(next.x,next.z)<world.water_level-0.65:
		var query:=PhysicsRayQueryParameters3D.create(boat.position+Vector3.UP*0.5,next+Vector3.UP*0.5,1,[boat.get_rid(),get_rid()])
		if get_world_3d().direct_space_state.intersect_ray(query).is_empty():boat.position=next
	boat.position.y=world.water_level+0.12
	position=boat.position+Vector3.UP*0.25;velocity=Vector3.ZERO
	yaw=boat.rotation.y;rotation.y=yaw
	_animate(delta,0,true)
