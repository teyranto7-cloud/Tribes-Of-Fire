extends RefCounted
## Original assemblies, batched by material; moving joints stay separate.
const S = preload("res://World/Shapes.gd")
const WOOD = Color("#825b3c")
const EDGE = Color("#b18a56")
const IRON = Color("#46555a")
const COPPER = Color("#c48b58")
const STONE = Color("#77796b")

static func table(parent: Node3D, metal: bool = false) -> void:
	for x in [-0.65, 0.65]:
		for z in [-0.35, 0.35]: S.beam(parent, Vector3(x, 0.04, z), Vector3(x * 0.9, 1.02, z), 0.075, IRON if metal else WOOD)
	for i in range(5): S.box(parent, Vector3(1.7, 0.12, 0.19), Vector3(0, 1.02, (i - 2) * 0.2), EDGE if i % 2 else WOOD)
	S.beam(parent, Vector3(-0.7, 0.36, -0.35), Vector3(0.7, 0.36, -0.35), 0.055, IRON)

static func gear(parent: Node3D, at: Vector3, radius: float) -> Node3D:
	var pivot := Node3D.new(); pivot.position = at; parent.add_child(pivot)
	var disk := S.cylinder(pivot, radius * 0.8, 0.12, Vector3.ZERO, IRON); disk.rotation.x = PI / 2
	for i in range(12):
		var a := TAU * i / 12.0
		var tooth := S.box(pivot, Vector3(radius * 0.28, radius * 0.25, 0.15), Vector3(cos(a) * radius, sin(a) * radius, 0), COPPER)
		tooth.rotation.z = a
	S.beam(pivot, Vector3(0, 0, -0.16), Vector3(0, 0, 0.18), radius * 0.19, EDGE)
	S.consolidate(pivot); return pivot

static func pot(parent: Node3D, at: Vector3, radius: float = 0.25) -> void:
	S.sculpted(parent, at, Vector3(radius * 2, radius * 1.4, radius * 2), IRON, "body")
	S.cylinder(parent, radius * 0.9, 0.035, at + Vector3.UP * radius * 0.7, Color("#654e36"))
	for side in [-1, 1]: S.beam(parent, at + Vector3(side * radius, 0.02, 0), at + Vector3(side * radius * 1.4, 0.12, 0), 0.025, COPPER)

static func build(parent: Node3D, kind: String) -> Array[Node3D]:
	var rotors: Array[Node3D] = []
	match kind:
		"furnace", "smelter", "kitchen":
			for level in range(4):
				for i in range(8):
					var a: float = TAU * (i + (0.5 if level % 2 else 0)) / 8
					S.sculpted(parent, Vector3(cos(a) * 0.54, 0.18 + level * 0.27, sin(a) * 0.4), Vector3(0.42, 0.32, 0.30), STONE.lightened(level * 0.025), "stone", i)
			S.cylinder(parent, 0.19, 1.3, Vector3(0.4, 1.5, 0.2), IRON)
			if kind == "kitchen": pot(parent, Vector3(-0.2, 1.12, 0), 0.29)
			elif kind == "smelter": pot(parent, Vector3(-0.18, 1.2, 0), 0.4)
			else:
				S.box(parent, Vector3(0.6, 0.18, 0.1), Vector3(0, 0.54, -0.5), IRON)
				for x in [-0.18, 0, 0.18]: S.beam(parent, Vector3(x, 0.34, -0.56), Vector3(x, 0.66, -0.56), 0.018, IRON)
		"cooking_fire":
			for i in range(10):
				var a := TAU * i / 10
				S.sculpted(parent, Vector3(cos(a) * 0.6, 0.14, sin(a) * 0.6), Vector3(0.3, 0.24, 0.3), STONE, "stone", i)
			for i in range(3):
				var a := TAU * i / 3
				S.beam(parent, Vector3(cos(a) * 0.6, 0, sin(a) * 0.6), Vector3(0, 1.5, 0), 0.045, WOOD)
			pot(parent, Vector3(0, 0.7, 0), 0.27)
			for x in [-0.18, 0, 0.18]: S.sculpted(parent, Vector3(x, 0.25, 0), Vector3(0.22, 0.45, 0.2), Color("#e9a34a"), "stone")
		"anvil":
			S.cylinder(parent, 0.4, 0.7, Vector3(0, 0.35, 0), WOOD)
			S.mesh(parent, S.sculpted_mesh([[-0.3,0.45,0.28,0,0],[-0.23,0.4,0.25,0,0],[-0.18,0.22,0.17,0,0],[0.14,0.24,0.16,0.03,0],[0.2,0.48,0.28,0,0],[0.31,0.5,0.28,-0.08,0]],4), Vector3(0,0.95,0), IRON)
			S.beam(parent, Vector3(-0.35, 1.16, 0), Vector3(-0.85, 1.17, 0), 0.12, IRON)
		"tannery", "loom":
			for x in [-0.65, 0.65]:
				S.beam(parent, Vector3(x, 0, 0.1), Vector3(x, 1.85, 0), 0.07, WOOD)
				S.beam(parent, Vector3(x, 0, -0.4), Vector3(x, 0.8, 0.05), 0.065, WOOD)
			for y in [0.2, 1.75]: S.beam(parent, Vector3(-0.72, y, 0), Vector3(0.72, y, 0), 0.065, EDGE)
			if kind == "loom":
				for i in range(15): S.beam(parent, Vector3(-0.51 + i * 0.073, 0.3, 0), Vector3(-0.51 + i * 0.073, 1.7, 0), 0.008, Color("#dbcc9c"))
				S.box(parent, Vector3(1.03, 0.65, 0.035), Vector3(0, 0.65, -0.025), Color("#698a78"))
				rotors.append(gear(parent, Vector3(0.8, 0.65, 0), 0.2))
			else: S.sculpted(parent, Vector3(0, 1.05, 0), Vector3(1.05, 1.2, 0.06), Color("#b1976c"), "body")
		"crusher", "concrete_mixer":
			for x in [-0.55, 0.55]: S.beam(parent, Vector3(x, 0.1, 0), Vector3(x, 1.0, 0), 0.09, IRON)
			S.box(parent, Vector3(1.45, 0.12, 1.0), Vector3(0, 0.3, 0), WOOD)
			var pivot := Node3D.new(); pivot.position = Vector3(0, 1.12, 0); parent.add_child(pivot)
			var drum := S.cylinder(pivot, 0.5, 0.8, Vector3.ZERO, Color("#877b5b")); drum.rotation.x = PI / 2
			for z in [-0.4, 0.4]: S.beam(pivot, Vector3(0, 0, z - 0.04), Vector3(0, 0, z + 0.04), 0.52, IRON)
			S.consolidate(pivot); rotors.append(pivot)
			if kind == "crusher":
				S.sculpted(parent, Vector3(0, 1.7, 0), Vector3(1.3, 0.65, 0.85), STONE, "body")
				for i in range(3): S.sculpted(parent, Vector3((i - 1) * 0.2, 1.9, 0), Vector3(0.3, 0.3, 0.3), STONE, "stone", i)
		_:
			table(parent, kind in ["mechanical_workshop", "electrical_bench", "advanced_workshop"])
			match kind:
				"sawmill":
					rotors.append(gear(parent, Vector3(0, 1.15, 0), 0.38))
					S.beam(parent, Vector3(-0.7, 1.17, -0.29), Vector3(0.7, 1.17, -0.29), 0.16, WOOD)
					for x in [-0.65, 0.65]: S.beam(parent, Vector3(x, 1.16, 0.35), Vector3(x, 1.16, -0.35), 0.065, IRON)
				"carpenter", "workbench":
					S.box(parent, Vector3(0.7, 0.1, 0.32), Vector3(-0.15, 1.14, 0), EDGE)
					S.beam(parent, Vector3(-0.6, 1.16, -0.3), Vector3(0.2, 1.16, -0.1), 0.025, IRON)
					if kind == "carpenter":
						for x in [-0.7, 0.7]: S.beam(parent, Vector3(x, 1.0, 0.3), Vector3(x, 1.6, 0.3), 0.04, IRON)
						S.box(parent, Vector3(1.5, 0.1, 0.14), Vector3(0, 1.6, 0.3), WOOD)
				"mason":
					S.sculpted(parent, Vector3(-0.15, 1.25, 0), Vector3(0.8, 0.38, 0.6), STONE, "stone")
					S.beam(parent, Vector3(0.45, 1.1, -0.3), Vector3(0.5, 1.45, -0.3), 0.03, IRON)
				"alchemy":
					for i in range(4):
						S.cylinder(parent, 0.10, 0.23 + i * 0.04, Vector3(-0.5 + i * 0.3, 1.25, 0.2), Color("#8ba48b") if i % 2 else Color("#ba976b"))
						S.cylinder(parent, 0.07, 0.04, Vector3(-0.5 + i * 0.3, 1.4 + i * 0.02, 0.2), WOOD)
					pot(parent, Vector3(0.2, 1.2, -0.22), 0.15)
				"electrical_bench":
					for x in [-0.4, 0.1, 0.45]: S.cylinder(parent, 0.15, 0.3, Vector3(x, 1.25, 0), COPPER)
					S.box(parent, Vector3(0.5, 0.12, 0.35), Vector3(0, 1.15, -0.22), Color("#547265"))
				"mechanical_workshop", "advanced_workshop":
					rotors.append(gear(parent, Vector3(-0.35, 1.4, 0.15), 0.28)); rotors.append(gear(parent, Vector3(0.25, 1.45, 0.15), 0.23))
					if kind == "advanced_workshop": S.box(parent, Vector3(0.7, 0.55, 0.12), Vector3(0, 1.65, 0.4), Color("#4d756e"))
	S.consolidate(parent)
	return rotors
