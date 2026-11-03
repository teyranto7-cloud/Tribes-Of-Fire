extends RefCounted
## Original ring-modelled anatomy. Rigid surfaces are merged per joint/material.
const Shapes = preload("res://World/Shapes.gd")

static func pivot(parent: Node3D, at: Vector3, label: String = "") -> Node3D:
	var node := Node3D.new()
	if label != "": node.name = label
	node.position = at
	parent.add_child(node)
	return node

static func part(parent: Node3D, at: Vector3, size: Vector3, material: Material, kind: String = "body", variant: int = 0) -> MeshInstance3D:
	var mesh := Shapes.sculpted(parent, at, size, Color.WHITE, kind, variant)
	mesh.material_override = material
	return mesh

static func build(player, data: Dictionary) -> void:
	var palette = load("res://Character/Appearance.gd")
	var skin: Color = palette.SKIN[int(data["skin"])]
	var hair_color: Color = palette.HAIR[int(data["hair_color"])]
	var skin_mat: Material = player._mat("skin", skin)
	var shade: Material = player._mat("skin_shadow", skin.darkened(0.25))
	var hair_mat: Material = player._mat("hair", hair_color)
	player._mat("hair_highlight", hair_color.lightened(0.1))
	var leather: Material = player._mat("leather", Color("#5f412d"))
	var trim: Material = player._mat("trim", Color("#b38d57"))
	var eyes: Material = player._mat("eye", palette.EYES[int(data["eye_color"])])
	var whites: Material = player._mat("eye_white", Color("#efdfbd"))
	var iron: Material = player._mat("iron", Color("#81908d"), 0.6)
	var cloth := ShaderMaterial.new()
	cloth.shader = preload("res://Assets/Shaders/hide.gdshader")
	cloth.set_shader_parameter("style", int(data["clothing"]))
	player._materials["tunic"] = cloth
	player.avatar = pivot(player, Vector3.ZERO, "Avatar")
	player.avatar.scale = Vector3(1.15 * float(data["volume"]), float(data["height"]) / 1.98, 1.07)
	player.torso = pivot(player.avatar, Vector3(0,0.94,0), "Torso")
	player.torso.scale.x = float(data["shoulders"]) * (0.94 if int(data["body"]) == 1 else 1.0)
	var torso = player.torso
	# Waist, rib cage and shoulder planes follow a single coherent silhouette.
	var shell := [[-0.20,0.28,0.18,0,0],[-0.05,0.25,0.16,0,0],[0.16,0.25,0.17,0,0],[0.37,0.32,0.19,0,0],[0.48,0.24,0.14,0,0]]
	var body := Shapes.mesh(torso, Shapes.sculpted_mesh(shell, 9), Vector3.ZERO, Color.WHITE)
	body.material_override = cloth
	var neck := part(torso,Vector3(0,0.52,0),Vector3(0.19,0.19,0.17),skin_mat,"body")
	neck.rotation.x = -0.1
	part(torso,Vector3(0,0.05,-0.015),Vector3(0.58,0.085,0.39),leather,"body")
	part(torso,Vector3(0,0.05,-0.20),Vector3(0.09,0.08,0.025),trim,"head")
	for i in range(8):
		var a := float(i) / 8 * TAU
		var flap := part(torso,Vector3(sin(a)*0.26,-0.21,cos(a)*0.17),Vector3(0.17,0.18+sin(i*1.7)*0.04,0.04),cloth,"fur",i)
		flap.rotation.y = a
	var sling := part(torso,Vector3(0.10,0.29,-0.18),Vector3(0.06,0.53,0.045),leather,"body")
	sling.rotation.z = -0.44
	for side in [-1.0,1.0]:
		var tie := Shapes.beam(torso,Vector3(side*0.13,0.42,-0.18),Vector3(side*0.08,0.23,-0.205),0.012,Color("#bda77b"))
		tie.material_override = trim
	player.head = pivot(torso,Vector3(0,0.72,-0.015),"Head")
	player.head.scale = Vector3(float(data["face"])*1.13,1.08,1.04)
	part(player.head,Vector3(0,0.015,0),Vector3(0.39,0.45,0.35),skin_mat,"head")
	part(player.head,Vector3(0,-0.115,-0.035),Vector3(0.29,0.15,0.26),skin_mat,"head")
	for side in [-1.0,1.0]:
		part(player.head,Vector3(side*0.195,-0.005,0),Vector3(0.075,0.13,0.07)*float(data["ears"]),skin_mat,"head")
		var eye_size := Vector3(0.087,0.055,0.035)*float(data["eye_size"])
		eye_size.y *= [1.0,0.8,1.2][int(data["eyes"])]
		part(player.head,Vector3(side*0.078*float(data["eye_spacing"]),0.027,-0.165),eye_size,whites,"head")
		part(player.head,Vector3(side*0.078*float(data["eye_spacing"]),0.025,-0.183),eye_size*Vector3(0.43,0.75,0.6),eyes,"head")
		var brow := part(player.head,Vector3(side*0.078,0.078,-0.17),Vector3(0.10,0.022,0.035),hair_mat,"body")
		brow.rotation.z = -side*0.12
	part(player.head,Vector3(0,-0.023,-0.19),Vector3(0.07,0.11,0.10)*float(data["nose"]),skin_mat,"head")
	part(player.head,Vector3(0,-0.125,-0.17),Vector3(0.105*float(data["mouth"]),0.018,0.025),shade,"body")
	_hair(player.head,data,hair_mat)
	player.left_leg = _leg(player.avatar,Vector3(-0.145,0.82,0),cloth,skin_mat,leather)
	player.right_leg = _leg(player.avatar,Vector3(0.145,0.82,0),cloth,skin_mat,leather)
	player.left_knee = player.left_leg.get_node("Knee")
	player.right_knee = player.right_leg.get_node("Knee")
	player.left_arm = _arm(torso,Vector3(-0.30,0.44,0),cloth,skin_mat,leather)
	player.axe_arm = _arm(torso,Vector3(0.30,0.44,0),cloth,skin_mat,leather)
	player.axe = pivot(player.axe_arm,Vector3(0.015,-0.56,-0.08),"Axe")
	var handle := part(player.axe,Vector3(0,-0.06,0),Vector3(0.045,0.59,0.045),leather,"body")
	handle.rotation.x = 0.18
	var axe_head := part(player.axe,Vector3(-0.085,-0.30,-0.02),Vector3(0.28,0.20,0.075),iron,"stone")
	axe_head.rotation.z = -0.18
	part(player.axe,Vector3(-0.20,-0.30,-0.02),Vector3(0.07,0.22,0.04),iron,"leaf")

static func _leg(parent: Node3D, at: Vector3, cloth: Material, skin: Material, leather: Material) -> Node3D:
	var hip := pivot(parent,at)
	part(hip,Vector3(0,-0.14,0),Vector3(0.19,0.33,0.22),cloth,"body")
	var knee := pivot(hip,Vector3(0,-0.35,0),"Knee")
	part(knee,Vector3(0,-0.08,0),Vector3(0.16,0.25,0.17),skin,"body")
	part(knee,Vector3(0,-0.25,0),Vector3(0.17,0.19,0.19),leather,"body")
	part(knee,Vector3(0,-0.37,-0.075),Vector3(0.20,0.16,0.34),leather,"head")
	return hip

static func _arm(parent: Node3D, at: Vector3, cloth: Material, skin: Material, leather: Material) -> Node3D:
	var arm := pivot(parent,at)
	part(arm,Vector3(0,-0.065,0),Vector3(0.23,0.22,0.25),cloth,"fur")
	part(arm,Vector3(0,-0.23,0),Vector3(0.16,0.29,0.18),skin,"body")
	part(arm,Vector3(0,-0.40,-0.015),Vector3(0.14,0.25,0.16),skin,"body")
	part(arm,Vector3(0,-0.44,-0.02),Vector3(0.15,0.10,0.18),leather,"body")
	part(arm,Vector3(0,-0.56,-0.025),Vector3(0.13,0.15,0.12),skin,"head")
	part(arm,Vector3(-0.06,-0.53,-0.045),Vector3(0.07,0.08,0.07),skin,"head")
	return arm

static func _hair(head: Node3D, data: Dictionary, material: Material) -> void:
	var style := int(data["hair"])
	part(head,Vector3(0,0.15,0.025),Vector3(0.41,0.24,0.36),material,"fur",style)
	for i in range(7 if style != 6 else 11):
		var angle := float(i) / 7 * TAU
		var location := Vector3(sin(angle)*0.14,0.19,cos(angle)*0.11)
		var lock := part(head,location,Vector3(0.12,0.17+[0.0,0.04,0.18,0.02,0.12,0.01,0.08,0.20,0.23][style],0.10),material,"fur",i)
		lock.rotation.z = sin(angle)*0.45
		if style in [2,4,7,8]:
			lock.position.z += 0.10
			lock.position.y -= 0.10
		if style in [3,4] and i > 3:
			lock.position = Vector3(0,0.15-(i-4)*0.10,0.19)
		if style == 5 and absf(location.x)>0.1: lock.hide()
	if int(data["beard"])>0:
		var beard := part(head,Vector3(0,-0.13,-0.10),Vector3(0.24,0.10+int(data["beard"])*0.045,0.20),material,"fur",style)
		if int(data["beard"]) == 5: beard.scale = Vector3(0.20,0.035,0.05)
