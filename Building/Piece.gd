extends StaticBody3D
## Each modular piece owns its collision, state and appearance; the server owns commands.
const Shapes = preload("res://World/Shapes.gd")
const KINDS := ["lantern","torch","raft","foundation", "floor", "wall", "window", "door", "roof", "stairs", "fence", "bed", "chest", "garden", "totem"]
var replica_target := Vector3.ZERO
var replica_yaw: float = 0.0
var structure_id: int = 0
var kind: String = "foundation"
var owner_key: String = ""
var hp: int = 100
var open: bool = false
var storage: Dictionary = {}
var bound_to: String = ""
var crop: String = ""
var growth: float = 0.0
var water: float = 0.0
var hinge: Node3D
var plants: Array[Node3D] = []
var _lid: Node3D

func setup(record: Dictionary) -> void:
	structure_id = int(record["id"])
	kind = str(record["kind"])
	owner_key = str(record.get("owner", ""))
	var p: Array = record["position"]
	position = Vector3(p[0], p[1], p[2])
	rotation.y = int(record.get("rotation", 0)) * PI * 0.5
	hp = int(record.get("hp", 100))
	storage = record.get("storage", {}).duplicate(true)
	bound_to = str(record.get("bound_to", ""))
	add_to_group("building_piece")
	add_to_group(kind)
	_build()
	set_open(bool(record.get("open", false)))
	replica_target=position;replica_yaw=rotation.y

func _box(size: Vector3, at: Vector3, tint: Color, solid: bool = true) -> void:
	Shapes.box(self, size, at, tint)
	if solid:
		var shape := BoxShape3D.new()
		shape.size = size
		Shapes.collider(self, shape, at)

func _build() -> void:
	var wood := Color("#78583d")
	var edge := Color("#4e3e2b")
	match kind:
		"lantern","torch":
			var height:float=1.45 if kind=="torch" else 0.55
			Shapes.cylinder(self,0.06,height,Vector3(0,height/2,0),wood)
			Shapes.sculpted(self,Vector3(0,height,0),Vector3(0.22,0.35,0.22),Color("#ffbb66"),"leaf").material_override=Shapes.material(Color("#ffb457"),1.8)
			var light:=OmniLight3D.new();light.position.y=height;light.light_color=Color("#ffd09b");light.light_energy=1.5;light.omni_range=7;add_child(light)
			if kind=="lantern":
				for x in [-0.13,0.13]:
					for z in [-0.13,0.13]:_box(Vector3(0.025,0.36,0.025),Vector3(x,height,z),edge,false)
		"raft":
			for x in range(7):
				var log_mesh=Shapes.cylinder(self,0.17,3.8,Vector3((x-3)*0.33,0,0),wood)
				log_mesh.rotation.x=PI/2
			_box(Vector3(2.5,0.12,0.18),Vector3(0,0.15,-1.2),edge,false)
			_box(Vector3(2.5,0.12,0.18),Vector3(0,0.15,1.2),edge,false)
			var floor_shape:=BoxShape3D.new();floor_shape.size=Vector3(2.4,0.35,3.8)
			Shapes.collider(self,floor_shape,Vector3.ZERO)
			Shapes.beam(self,Vector3(1.2,0.3,0.8),Vector3(1.8,-0.25,-0.5),0.05,edge)
		"foundation", "floor":
			for i in range(8): _box(Vector3(0.48, 0.25, 4.0), Vector3(-1.75 + i * 0.5, 0.13, 0), wood.lightened(i % 3 * 0.025), false)
			var shape := BoxShape3D.new(); shape.size = Vector3(4, 0.25, 4)
			Shapes.collider(self, shape, Vector3(0, 0.13, 0))
			if kind == "foundation":
				for x in [-1.65, 1.65]:
					for z in [-1.65, 1.65]: _box(Vector3(0.25, 0.7, 0.25), Vector3(x, -0.15, z), edge)
			add_to_group("rain_roof")
		"wall":
			for i in range(10): _box(Vector3(0.38, 3, 0.16), Vector3(-1.8 + i * 0.4, 1.75, 0), wood.lightened(i % 3 * 0.025), false)
			_box(Vector3(4, 3, 0.18), Vector3(0, 1.75, 0), wood, true)
			_box(Vector3(4.1, 0.16, 0.25), Vector3(0, 0.35, 0), edge)
			_box(Vector3(4.1, 0.16, 0.25), Vector3(0, 3.15, 0), edge)
		"window":
			_box(Vector3(4, 1, 0.2), Vector3(0, 0.75, 0), wood)
			_box(Vector3(4, 0.7, 0.2), Vector3(0, 2.9, 0), wood)
			for x in [-1.45, 1.45]: _box(Vector3(1.1, 1.3, 0.2), Vector3(x, 1.9, 0), wood)
			_box(Vector3(2, 0.1, 0.4), Vector3(0, 1.25, 0), edge)
		"door":
			for x in [-1.4, 1.4]: _box(Vector3(1.2, 3, 0.22), Vector3(x, 1.75, 0), wood)
			_box(Vector3(1.6, 0.5, 0.22), Vector3(0, 3.0, 0), wood)
			hinge = Node3D.new(); hinge.position = Vector3(-0.8, 0.25, 0); add_child(hinge)
			var panel := StaticBody3D.new(); hinge.add_child(panel)
			for i in range(4): Shapes.box(panel, Vector3(0.38, 2.5, 0.14), Vector3(0.2 + i * 0.4, 1.25, 0), wood.lightened(i * 0.02))
			var shape := BoxShape3D.new(); shape.size = Vector3(1.6, 2.5, 0.18)
			Shapes.collider(panel, shape, Vector3(0.8, 1.25, 0))
			Shapes.box(panel, Vector3(0.1, 0.1, 0.2), Vector3(1.4, 1.2, -0.15), edge)
		"roof":
			_box(Vector3(4.2, 0.25, 4.2), Vector3(0, 3.4, 0), Color("#736347"))
			for i in range(10): Shapes.box(self, Vector3(0.42, 0.12, 4.25), Vector3(-1.9 + i * 0.42, 3.55, 0), Color("#8d7c52").lightened(i % 2 * 0.05))
			add_to_group("rain_roof")
		"stairs":
			for i in range(8): _box(Vector3(2, 0.4, 0.5), Vector3(0, 0.2 + i * 0.4, 1.75 - i * 0.5), wood)
		"fence":
			for x in [-1.9, 1.9]: _box(Vector3(0.2, 1.6, 0.2), Vector3(x, 0.8, 0), edge)
			for y in [0.55, 1.15]: _box(Vector3(4, 0.18, 0.15), Vector3(0, y, 0), wood)
		"bed":
			_box(Vector3(1.25, 0.32, 2), Vector3(0, 0.25, 0), wood)
			Shapes.box(self, Vector3(1.2, 0.16, 1.9), Vector3(0, 0.5, 0), Color("#af9562"))
			Shapes.box(self, Vector3(1.0, 0.15, 0.4), Vector3(0, 0.62, -0.65), Color("#bfac80"))
		"chest":
			_box(Vector3(1.5, 0.8, 0.9), Vector3(0, 0.45, 0), wood)
			_lid = Node3D.new(); _lid.position = Vector3(0, 0.85, 0.45); add_child(_lid)
			Shapes.box(_lid, Vector3(1.55, 0.18, 0.95), Vector3(0, 0, -0.45), edge)
			for x in [-0.5, 0.5]: Shapes.box(self, Vector3(0.12, 0.85, 0.95), Vector3(x, 0.45, 0), edge)
		"garden":
			_box(Vector3(3.8, 0.12, 3.8), Vector3(0, 0.08, 0), Color("#514331"), false)
			for side in [-1, 1]:
				_box(Vector3(4, 0.2, 0.16), Vector3(0, 0.16, side * 1.95), wood)
				_box(Vector3(0.16, 0.2, 4), Vector3(side * 1.95, 0.16, 0), wood)
			for z in range(3):
				for x in range(3):
					var plant := Node3D.new(); plant.position = Vector3(-1.2 + x * 1.2, 0.15, -1.2 + z * 1.2); add_child(plant)
					Shapes.cylinder(plant, 0.035, 0.65, Vector3.UP * 0.3, Color("#638449"))
					for i in range(3):
						var leaf := Shapes.box(plant, Vector3(0.45, 0.035, 0.16), Vector3(0.1, 0.25 + i * 0.12, 0), Color("#749547")); leaf.rotation.y = i * 2.1
					plant.hide(); plants.append(plant)
		"totem":
			_box(Vector3(0.7, 2.8, 0.7), Vector3(0, 1.4, 0), edge)
			for y in [0.8, 1.6, 2.4]:
				Shapes.box(self, Vector3(1.2, 0.5, 0.85), Vector3(0, y, 0), Color("#b47847"))
				for x in [-0.3, 0.3]: Shapes.box(self, Vector3(0.12, 0.12, 0.1), Vector3(x, y + 0.05, -0.46), Color("#272f29"))

func set_open(value: bool) -> void:
	open = value
	if hinge != null: hinge.rotation.y = -PI * 0.55 if open else 0.0
	if _lid != null: _lid.rotation.x = -PI * 0.4 if open else 0.0

func set_crop(value: String, progress: float, moisture: float) -> void:
	crop = value; growth = clampf(progress, 0, 1); water = clampf(moisture, 0, 1)
	for plant in plants:
		plant.visible = not crop.is_empty()
		plant.scale = Vector3.ONE * lerpf(0.15, 1.0, growth)

func get_record() -> Dictionary:
	var result := {"id": structure_id, "kind": kind, "position": [position.x, position.y, position.z],
		"rotation": posmod(roundi(rotation.y / (PI * 0.5)), 4), "owner": owner_key, "hp": hp, "open": open}
	if kind == "chest": result["storage"] = storage.duplicate(true)
	if kind == "bed": result["bound_to"] = bound_to
	return result

func _process(delta: float) -> void:
	if kind=="raft" and not is_multiplayer_authority():
		position=position.lerp(replica_target,1-exp(-12*delta))
		rotation.y=lerp_angle(rotation.y,replica_yaw,1-exp(-12*delta))
