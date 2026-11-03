extends StaticBody3D
## Seven original silhouettes; one bark surface and one foliage surface per LOD.
const Shapes = preload("res://World/Shapes.gd")
const Foliage = preload("res://Assets/Shaders/foliage.gdshader")
const SPECIES := ["oak", "pine", "birch", "fruit", "palm", "burnt", "fallen"]
var tree_id: int
var species: String = "oak"
var hits: int = 0
var felled: bool = false
var crown: Node3D
var fall_tween: Tween
var foliage_material: ShaderMaterial
var detail_meshes: Array[GeometryInstance3D] = []
var distant_meshes: Array[GeometryInstance3D] = []

func setup(id: int, at: Vector3, size: float, tint: Color, kind: String = "oak") -> void:
	tree_id = id
	species = kind if kind in SPECIES else "oak"
	position = at
	crown = Node3D.new()
	add_child(crown)
	var bark := Color("#bfc3ac") if species == "birch" else Color("#674730")
	if species in ["burnt", "fallen"]: bark = Color("#42392f")
	foliage_material = ShaderMaterial.new()
	foliage_material.shader = Foliage
	foliage_material.set_shader_parameter("tint", tint)
	var detail := Node3D.new()
	crown.add_child(detail)
	var top := Vector3(0.12, 4.5, 0.07) * size
	if species == "palm": top = Vector3(0.75, 6.3, 0.1) * size
	Shapes.tapered_branch(detail, Vector3.ZERO, top, 0.24 * size, 0.07 * size, bark, id)
	for i in range(5):
		var angle := i * TAU / 5 + id * 0.31
		Shapes.tapered_branch(detail, Vector3(cos(angle) * 0.73, 0.025, sin(angle) * 0.73) * size, Vector3(0, 0.65, 0) * size, 0.085 * size, 0.13 * size, bark, i)
	if species == "pine":
		for i in range(5):
			_leaf_whorl(detail, Vector3(0, 2.1 + i * 0.65, 0) * size, (1.85 - i * 0.26) * size, 1.0 * size, 9, id + i)
	elif species == "palm":
		for i in range(9):
			var angle := i * TAU / 9
			var end := top + Vector3(cos(angle) * 2.6, -0.65, sin(angle) * 2.6) * size
			Shapes.tapered_branch(detail, top, end, 0.045 * size, 0.012 * size, bark, i)
			for j in range(5):
				var location := top.lerp(end, 0.18 + j * 0.17)
				_leaf(detail, location, Vector3(0.68, 1.25, 0.12) * size, Vector3(PI * 0.47, -angle, 0.45), id + j)
	else:
		for i in range(6):
			var angle := i * TAU / 6 + id * 0.35
			var spread := 1.2 if species != "birch" else 0.9
			var end := Vector3(cos(angle) * spread, 2.75 + i * 0.28, sin(angle) * spread) * size
			Shapes.tapered_branch(detail, Vector3(0, 1.6 + i * 0.21, 0) * size, end, 0.085 * size, 0.025 * size, bark, i)
			if species != "burnt":
				_leaf_whorl(detail, end + Vector3.UP * 0.4 * size, (1.15 if species != "birch" else 0.85) * size, (0.8 if species != "birch" else 1.15) * size, 7, id + i)
		if species != "burnt": _leaf_whorl(detail, top, 1.25 * size, 0.8 * size, 8, id)
		if species == "fruit":
			for i in range(7):
				var apple := Shapes.sculpted(detail, Vector3(sin(i * 2.3), 3.0 + (i % 3) * 0.4, cos(i * 2.3)) * size, Vector3.ONE * 0.18 * size, Color("#bb6138"), "head", i)
				apple.rotation.z = i * 0.2
	if species == "birch":
		for i in range(9):
			var scar := Shapes.box(detail, Vector3(0.3, 0.055, 0.035) * size, Vector3(0, 0.5 + i * 0.36, -0.2) * size, Color("#5b6259"))
			scar.rotation.y = i * 0.7
	Shapes.consolidate(detail)
	for child in detail.get_children():
		if child is GeometryInstance3D: detail_meshes.append(child)
	var far := Node3D.new()
	crown.add_child(far)
	Shapes.tapered_branch(far, Vector3.ZERO, top, 0.21 * size, 0.055 * size, bark, id)
	if species not in ["burnt", "palm"]:
		_leaf_whorl(far, Vector3(0, 3.55, 0) * size, 2.0 * size, 2.1 * size, 7 if species != "pine" else 9, id)
	elif species == "palm": _leaf_whorl(far, top, 2.3 * size, 0.35 * size, 7, id)
	Shapes.consolidate(far)
	for child in far.get_children():
		if child is GeometryInstance3D: distant_meshes.append(child)
	var shape := CylinderShape3D.new()
	shape.radius = 0.29 * size
	shape.height = 3.6 * size
	var collider := Shapes.collider(self, shape, Vector3(0, 1.8 * size, 0))
	if species == "fallen":
		crown.rotation.z = PI * 0.48
		crown.position.y = 0.2 * size
		collider.rotation.z = PI * 0.48
		collider.position = Vector3(-1.65, 0.25, 0) * size
	set_quality(1)

func _leaf(parent: Node3D, at: Vector3, size: Vector3, angles: Vector3, variant: int) -> void:
	var node := Shapes.sculpted(parent, at, size, Color.WHITE, "leaf", variant)
	node.rotation = angles
	node.material_override = foliage_material

func _leaf_whorl(parent: Node3D, at: Vector3, radius: float, height: float, count: int, variant: int) -> void:
	# Broad interlocking leaf fans leave an angular, layered canopy silhouette.
	for i in range(count):
		var angle := float(i) / count * TAU + variant * 0.36
		var location := at + Vector3(cos(angle) * radius * 0.46, sin(i * 2.7 + variant) * height * 0.23, sin(angle) * radius * 0.46)
		_leaf(parent, location, Vector3(radius * 1.25, height, radius * 0.95), Vector3(0.9 + sin(angle) * 0.25, angle, 0.25), variant + i)

func set_quality(value: int) -> void:
	var level := clampi(value, 0, 3)
	var detail_distance := float([22, 32, 45, 60][level])
	var far_distance := float([55, 75, 100, 125][level])
	for node in detail_meshes:
		node.visibility_range_end = detail_distance
		node.visibility_range_end_margin = 2.0
	for node in distant_meshes:
		node.visibility_range_begin = detail_distance
		node.visibility_range_end = far_distance
		node.visibility_range_begin_margin = 2.0
		node.visibility_range_end_margin = 2.0

func set_felled(value: bool, animate: bool = false) -> void:
	if value and animate and not felled:
		hits = 2
		hit()
	else: restore_cut(value)

func restore_cut(value: bool) -> void:
	if is_instance_valid(fall_tween): fall_tween.kill()
	felled = value
	hits = 0
	collision_layer = 0 if value else 1
	crown.visible = not value
	crown.rotation = Vector3(0, 0, PI * 0.48 if species == "fallen" else 0.0)
	crown.position = Vector3(0, 0.2 if species == "fallen" else 0.0, 0)

func hit(power: int = 1) -> bool:
	if felled: return false
	hits += maxi(1,power)
	if hits < int(preload("res://Items/Catalog.gd").database().get("trees",{}).get(species,{}).get("hits",3)): return false
	felled = true
	collision_layer = 0
	fall_tween = create_tween()
	fall_tween.tween_property(crown, "rotation:z", -1.45, 0.9)
	fall_tween.parallel().tween_property(crown, "position:y", -0.2, 0.9)
	fall_tween.tween_callback(func(): crown.hide())
	return true
