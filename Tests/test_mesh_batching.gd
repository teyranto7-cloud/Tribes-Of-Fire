extends SceneTree
## Mixing primitive indexed meshes and authored unindexed meshes must be lossless.
const Shapes = preload("res://World/Shapes.gd")
var checks := 0
var failed := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failed += 1; push_error(label)
func triangle_count(mesh: Mesh) -> int:
	var total := 0
	for i in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(i)
		var indices: Variant = arrays[Mesh.ARRAY_INDEX]
		total += (indices.size() if indices is PackedInt32Array and not indices.is_empty() else arrays[Mesh.ARRAY_VERTEX].size()) / 3
	return total
func _initialize() -> void:
	for reversed_order in [false, true]:
		var assembly := Node3D.new()
		for primitive in ([false, true] if reversed_order else [true, false]):
			if primitive: Shapes.cylinder(assembly, 0.2, 0.8, Vector3(0, 0.4, 0), Color.WHITE)
			else: Shapes.sculpted(assembly, Vector3(0.5, 1, 0), Vector3(0.8, 0.4, 0.5), Color.WHITE, "body")
		var before := 0
		for child in assembly.get_children(): before += triangle_count(child.mesh)
		Shapes.consolidate(assembly)
		var after := 0
		for child in assembly.get_children(): after += triangle_count(child.mesh)
		print("BATCH_TRIANGLES order=",reversed_order," before=",before," after=",after)
		check(before == after, "Batch preserves indexed and unindexed triangles in either insertion order")
		check(assembly.get_child_count() == 1, "Matching materials consolidate into one draw surface")
		var arrays: Array = assembly.get_child(0).mesh.surface_get_arrays(0)
		check(arrays[Mesh.ARRAY_NORMAL].size() == arrays[Mesh.ARRAY_VERTEX].size(), "Every final vertex retains a normal")
		check(arrays[Mesh.ARRAY_TEX_UV].size() == arrays[Mesh.ARRAY_VERTEX].size(), "Every final vertex retains UVs")
		assembly.free()
	print("MESH_BATCHING CHECKS=%d FAILED=%d" % [checks,failed])
	quit(0 if failed == 0 else 1)
