extends RefCounted
const Shapes = preload("res://World/Shapes.gd")
static func apply(player, data: Dictionary) -> void:
	var rig = player.avatar.get_node_or_null("CharacterRig")
	if rig == null:
		return
	rig.attachments[8].visible = data.get("hand", "axe") == "axe"
	for index in [0, 6, 7]:
		var old = rig.attachments[index].get_node_or_null("Equipment")
		if old != null:
			rig.attachments[index].remove_child(old)
			old.queue_free()
	var hand := Node3D.new()
	hand.name = "Equipment"
	hand.position = Vector3(0, -0.55, -0.08)
	rig.attachments[7].add_child(hand)
	var id: String = data.get("hand", "axe")
	var iron := Color("#a2aead")
	if id.begins_with("copper"): iron = Color("#bb865c")
	elif id.begins_with("bronze"): iron = Color("#a79955")
	elif id.begins_with("stone"): iron = Color("#727f79")
	if id in ["pickaxe", "iron_pickaxe"]:
		Shapes.cylinder(hand, 0.025, 0.6, Vector3(0, -0.12, 0), Color("#765437"))
		for i in range(5):
			var x := (i - 2) * 0.105
			var head := Shapes.sphere(hand, 0.07, Vector3(x, -0.34 + x * x, 0), iron)
			head.scale = Vector3(1.2, 0.65, 0.6)
	elif id == "bow":
		for i in range(8):
			var a := float(i) / 8 * PI
			var b := float(i + 1) / 8 * PI
			Shapes.beam(hand, Vector3(sin(a) * 0.23, cos(a) * 0.45, 0), Vector3(sin(b) * 0.23, cos(b) * 0.45, 0), 0.025, Color("#8a633c"))
		Shapes.beam(hand, Vector3(0, 0.45, 0), Vector3(0, -0.45, 0), 0.006, Color("#c6c1a0"))
	elif id != "" and id != "axe":
		Shapes.cylinder(hand, 0.028, 0.25, Vector3(0, 0.05, 0), Color("#685038"))
		Shapes.box(hand, Vector3(0.23, 0.035, 0.065), Vector3(0, -0.08, 0), iron)
		var blade := CylinderMesh.new()
		blade.radial_segments = 4
		blade.height = 0.75 if id != "spear" else 1.4
		blade.top_radius = 0.065
		blade.bottom_radius = 0.005
		Shapes.mesh(hand, blade, Vector3(0, -0.45, 0), iron)
	if data.get("offhand", "") == "shield":
		var shield := Node3D.new()
		shield.name = "Equipment"
		rig.attachments[6].add_child(shield)
		var disk := Shapes.cylinder(shield, 0.30, 0.075, Vector3(0, -0.4, -0.12), Color("#795338"))
		disk.rotation.x = PI / 2
		Shapes.sphere(shield, 0.09, Vector3(0, -0.4, -0.18), iron)
	if data.get("armor", "") != "":
		var armor := Node3D.new()
		armor.name = "Equipment"
		rig.attachments[0].add_child(armor)
		var chest := Shapes.sphere(armor, 0.3, Vector3(0, 0.25, -0.03), Color("#805a38") if data["armor"] == "leather_armor" else iron)
		chest.scale = Vector3(1.05, 0.92, 0.7)
