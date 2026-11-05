extends RefCounted

static var materials: Dictionary = {}

static func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var key := "%s:%s" % [color.to_html(), glow]
	if materials.has(key):
		return materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.86
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	materials[key] = m
	return m

static func mesh(parent: Node3D, shape: Mesh, at: Vector3, color: Color, glow: float = 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = shape
	node.material_override = material(color, glow)
	node.position = at
	parent.add_child(node)
	return node

static func box(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return mesh(parent, shape, at, color)

static func sphere(parent: Node3D, radius: float, at: Vector3, color: Color, glow: float = 0.0) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0
	shape.radial_segments = 12
	shape.rings = 6
	return mesh(parent, shape, at, color, glow)

static func cylinder(parent: Node3D, radius: float, height: float, at: Vector3, color: Color) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius * 0.85
	shape.bottom_radius = radius * 1.15
	shape.height = height
	shape.radial_segments = 9
	return mesh(parent, shape, at, color)

static func collider(parent: CollisionObject3D, shape: Shape3D, at: Vector3) -> CollisionShape3D:
	var node := CollisionShape3D.new()
	node.shape = shape
	node.position = at
	parent.add_child(node)
	return node

static func beam(parent: Node3D, start: Vector3, end: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var result := cylinder(parent, radius, start.distance_to(end), (start + end) * 0.5, color)
	result.quaternion = Quaternion(Vector3.UP, (end - start).normalized())
	return result

static func consolidate(parent: Node3D) -> void:
	# Bake static local transforms, preserving every triangle and material.
	# Moving joints and collision nodes are deliberately left alone.
	var surfaces: Dictionary = {}
	var used_materials: Dictionary = {}
	var originals: Array[MeshInstance3D] = []
	for child in parent.get_children():
		if not child is MeshInstance3D or child.mesh == null:
			continue
		originals.append(child)
		for index in range(child.mesh.get_surface_count()):
			var material: Material = child.material_override if child.material_override != null else child.mesh.surface_get_material(index)
			var key: int = material.get_instance_id() if material != null else 0
			if not surfaces.has(key):
				var surface := SurfaceTool.new()
				surface.begin(Mesh.PRIMITIVE_TRIANGLES)
				surfaces[key] = surface
				used_materials[key] = material
			# A SurfaceTool cannot mix indexed primitives and unindexed authored
			# triangles: once indices exist, the latter become unreferenced vertices.
			# Normalize before appending, then re-index the completed material batch.
			var expanded := SurfaceTool.new()
			expanded.create_from(child.mesh, index)
			expanded.deindex()
			surfaces[key].append_from(expanded.commit(), 0, child.transform)
	for child in originals:
		parent.remove_child(child)
		child.free()
	for key in surfaces:
		var merged := MeshInstance3D.new()
		surfaces[key].index()
		merged.mesh = surfaces[key].commit()
		merged.material_override = used_materials[key]
		parent.add_child(merged)

static var sculpted_meshes: Dictionary = {}

static func sculpted_mesh(profile: Array, sides: int = 8, variation: int = 0) -> ArrayMesh:
	# Each ring is [height, half-width, half-depth, offset-x, offset-z].
	# Hand-authored profiles produce silhouettes; there are no sphere primitives.
	var key := str([profile, sides, variation])
	if sculpted_meshes.has(key): return sculpted_meshes[key]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	for ring_index in range(profile.size()):
		var ring: Array = []
		var p: Array = profile[ring_index]
		for side in range(sides):
			var angle := float(side) / sides * TAU
			var irregular := 1.0 + sin(side * 2.3 + ring_index * 1.9 + variation) * 0.045
			ring.append(Vector3(cos(angle) * float(p[1]) * irregular + float(p[3]), float(p[0]), sin(angle) * float(p[2]) * irregular + float(p[4])))
		rings.append(ring)
	for r in range(rings.size() - 1):
		for side in range(sides):
			var next := (side + 1) % sides
			for v in [rings[r][side], rings[r][next], rings[r + 1][side], rings[r][next], rings[r + 1][next], rings[r + 1][side]]:
				surface.set_color(Color.WHITE)
				surface.set_uv(Vector2(atan2(v.z, v.x) / TAU + 0.5, v.y + 0.5))
				surface.add_vertex(v)
	for top in [false, true]:
		var index: int = rings.size() - 1 if top else 0
		var center := Vector3(float(profile[index][3]), float(profile[index][0]), float(profile[index][4]))
		for side in range(sides):
			var next := (side + 1) % sides
			for v in ([center, rings[index][side], rings[index][next]] if top else [center, rings[index][next], rings[index][side]]):
				surface.set_color(Color.WHITE)
				surface.set_uv(Vector2(v.x + 0.5, v.z + 0.5))
				surface.add_vertex(v)
	surface.generate_normals()
	var result: ArrayMesh = surface.commit()
	sculpted_meshes[key] = result
	return result

static func sculpted(parent: Node3D, at: Vector3, size: Vector3, color: Color, kind: String = "stone", variation: int = 0) -> MeshInstance3D:
	var profile: Array
	match kind:
		"head": profile = [[-0.5,0.23,0.24,0,0.01],[-0.30,0.42,0.39,0,-0.05],[0.08,0.49,0.43,0,0],[0.35,0.42,0.36,0,0.02],[0.49,0.25,0.24,0,0.01]]
		"body": profile = [[-0.5,0.35,0.35,0,0],[-0.28,0.43,0.42,0,0],[0.16,0.50,0.44,0,-0.02],[0.42,0.43,0.35,0,-0.01],[0.5,0.30,0.28,0,0]]
		"leaf": profile = [[-0.5,0.04,0.01,0,0],[-0.16,0.45,0.06,0,0],[0.14,0.5,0.04,0.03,0],[0.5,0.015,0.01,0.08,0]]
		"fur": profile = [[-0.5,0.42,0.33,0,0],[-0.3,0.5,0.38,0,0],[0.22,0.44,0.35,0,0],[0.5,0.24,0.22,0,0]]
		_: profile = [[-0.45,0.25,0.28,0,0],[-0.25,0.48,0.38,-0.035,0],[0.18,0.46,0.45,0.025,0.01],[0.44,0.24,0.30,0.02,0]]
	var node := mesh(parent, sculpted_mesh(profile, 8 if kind != "leaf" else 5, variation % 5), at, color)
	node.scale = size
	return node

static func tapered_branch(parent: Node3D, start: Vector3, end: Vector3, base: float, tip: float, color: Color, variation: int = 0) -> MeshInstance3D:
	var profile := [[-0.5,1.0,1.0,0,0],[-0.18,0.91,0.88,0.10,0.04],[0.20,0.74,0.74,-0.04,0.03],[0.5,tip / maxf(base,0.001),tip / maxf(base,0.001),0,0]]
	var node := mesh(parent, sculpted_mesh(profile, 7, variation % 4), (start + end) * 0.5, color)
	node.scale = Vector3(base, start.distance_to(end), base)
	node.quaternion = Quaternion(Vector3.UP, (end - start).normalized())
	return node
