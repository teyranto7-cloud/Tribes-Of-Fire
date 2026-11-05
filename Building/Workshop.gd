extends StaticBody3D
const MAX_ACTIVE := 32
const MAX_RECORDS := 256
const Shapes = preload("res://World/Shapes.gd")
var machine: Dictionary = preload("res://Building/Factory.gd").empty()
var _wheel: Node3D
var rotors: Array[Node3D] = []
var kind: String = "workbench"
var owner_key: String = ""
var powered: bool = true
var building: Dictionary = {"rotation":0,"revision":1}

func retired() -> bool:
	return bool(building.get("retired", false))

func apply_retired() -> void:
	if not retired(): return
	remove_from_group(kind)
	collision_layer = 0; collision_mask = 0; hide(); set_process(false)
	rotors.clear(); _wheel = null
	for child in get_children():
		remove_child(child); child.queue_free()

static func valid_building(data: Variant) -> bool:
	if not data is Dictionary or data.size() > 4: return false
	const Rules = preload("res://Building/Catalog.gd")
	for field in ["rotation", "revision"]:
		if not Rules.numeric(data.get(field), 0 if field == "rotation" else 1, 3 if field == "rotation" else 1000000000) or data[field] != floorf(data[field]): return false
	for field in data:
		if field not in ["rotation", "revision", "retired", "paid_cost"]: return false
	if data.has("retired") and not data["retired"] is bool: return false
	var cost: Variant = data.get("paid_cost", {})
	if not cost is Dictionary or cost.size() > 16: return false
	for item in cost:
		if not item is String or not preload("res://Items/Catalog.gd").known(item) or not Rules.numeric(cost[item], 1, 9999) or cost[item] != floorf(cost[item]): return false
	return true

func setup(type: String, at: Vector3, key: String) -> void:
	kind = type; owner_key = key; position = at; add_to_group(type)
	var shape := BoxShape3D.new(); shape.size = Vector3(1.7, 1.2, 1.0)
	Shapes.collider(self, shape, Vector3(0, 0.6, 0))
	if DisplayServer.get_name() == "headless": return
	var title := Label3D.new(); title.text = preload("res://Items/Catalog.gd").display_name(type)
	title.position.y = 2.25; title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.font_size = 24; title.pixel_size = 0.006; title.visibility_range_end = 9; add_child(title)
	var assembly := Node3D.new(); add_child(assembly)
	rotors = preload("res://Building/WorkshopVisuals.gd").build(assembly, kind)
	if not rotors.is_empty(): _wheel = rotors[0]
	for child in assembly.get_children():
		if child is GeometryInstance3D: child.visibility_range_end = 90

func _process(delta: float) -> void:
	if rotors.is_empty() or not powered: return
	var recipe := preload("res://Building/Factory.gd").definition(kind, machine)
	if recipe.is_empty() or not recipe["input"].keys().all(func(item): return int(machine["input"].get(item, 0)) >= recipe["input"][item]): return
	for i in range(rotors.size()): rotors[i].rotation.z += delta * (1.8 if i % 2 == 0 else -1.8)
