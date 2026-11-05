extends RefCounted
## Original family silhouettes, batched by material; matching items share geometry.
static func build(parent: Node3D, item: Dictionary) -> void:
	if DisplayServer.get_name() == "headless": return
	var shapes=preload("res://World/Shapes.gd")
	var type:String=item.get("type","materials")
	var color:Color={"wood":Color("#936737"),"tools":Color("#a6b9bc"),"armor":Color("#a4a9ad"),"food":Color("#9baa55"),"electrical":Color("#c18c55"),"mechanical":Color("#969c99")}.get(type,Color("#b39761"))
	var assembly := Node3D.new(); parent.add_child(assembly)
	var id: String = item.get("id", "")
	var tool: String = item.get("statistics", {}).get("tool", "")
	if item.get("equipment_slot", "") == "hand":
		shapes.beam(assembly, Vector3(-0.24, 0.15, -0.1), Vector3(0.24, 0.15, 0.1), 0.025, Color("#977047"))
		if tool == "pickaxe": shapes.beam(assembly, Vector3(0.13, 0.15, -0.12), Vector3(0.28, 0.15, 0.3), 0.045, color)
		else: shapes.sculpted(assembly, Vector3(0.22, 0.16, 0.1), Vector3(0.27, 0.08, 0.19), color, "body")
	elif type == "armor": shapes.sculpted(assembly, Vector3(0, 0.18, 0), Vector3(0.4, 0.34, 0.25), color, "body")
	elif type == "wood" or id in ["wood", "stick", "plank", "log"]:
		for i in range(3):
			if id == "plank": shapes.box(assembly, Vector3(0.5, 0.055, 0.17), Vector3(0, 0.08 + i * 0.06, 0), color.lightened(i * 0.05))
			else: shapes.beam(assembly, Vector3(-0.25, 0.1 + i * 0.05, (i - 1) * 0.09), Vector3(0.25, 0.1 + i * 0.05, (i - 1) * 0.09 + 0.04), 0.055, Color("#977047"))
	elif id in ["herb", "flower", "fiber"]:
		for i in range(5):
			var tip := Vector3(sin(i * 2.4) * 0.15, 0.25, cos(i * 2.4) * 0.15)
			shapes.beam(assembly, Vector3.ZERO, tip, 0.009, Color("#68875c"))
			shapes.sculpted(assembly, tip, Vector3(0.1, 0.04, 0.13), Color("#b69aab") if id == "flower" else Color("#93a86b"), "leaf")
	elif type == "food":
		for i in range(3): shapes.sculpted(assembly, Vector3(sin(i * 2.1) * 0.12, 0.13, cos(i * 2.1) * 0.1), Vector3(0.18, 0.18, 0.18), Color("#b47c63"), "stone", i)
	elif id.ends_with("ingot"):
		for i in range(2): shapes.sculpted(assembly, Vector3(0, 0.09 + i * 0.1, 0), Vector3(0.4, 0.1, 0.2), color, "body")
	elif type in ["construction", "stations", "mechanical", "electrical"] or not item.get("place", "").is_empty():
		shapes.box(assembly, Vector3(0.36, 0.24, 0.3), Vector3(0, 0.15, 0), Color("#977047"))
		for x in [-0.14, 0.14]: shapes.box(assembly, Vector3(0.035, 0.26, 0.32), Vector3(x, 0.15, 0), color)
	else: shapes.sculpted(assembly, Vector3(0, 0.15, 0), Vector3(0.32, 0.28, 0.3), color, "stone", hash(id) % 13)
	shapes.consolidate(assembly)
