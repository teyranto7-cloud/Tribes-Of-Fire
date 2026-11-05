extends Node3D
const S = preload("res://World/Shapes.gd")
var game
var devices: Dictionary = {}
var rotors: Dictionary = {}
var lights: Dictionary = {}
var belt_payloads: Array = []
var _signature: int = -1
var _left: float = 0
var _visible_lights: Array = []

func _process(delta: float) -> void:
	if game == null: return
	_left -= delta
	if _left <= 0:
		_left = 0.25
		var signature: int = hash([game.runtime.grid.state(), game.runtime.automation.routes.map(func(row):return [row["from"],row["to"],row["item"],row["owner"]])])
		if signature != _signature: _signature = signature; rebuild()
		if DisplayServer.get_name()!="headless":
			var camera:=get_viewport().get_camera_3d()
			var focus:Vector3=camera.global_position if camera!=null else Vector3.ZERO
			var candidates:Array=lights.keys().filter(func(uid):return game.runtime.grid.powered.get(uid,false) and lights[uid].global_position.distance_squared_to(focus)<8100)
			candidates.sort_custom(func(a,b):return lights[a].global_position.distance_squared_to(focus)<lights[b].global_position.distance_squared_to(focus))
			var budget:int=[2,4,8][clampi(int(game.world.graphics_config.get("lighting",1)),0,2)]
			_visible_lights=candidates.slice(0,budget)
	if DisplayServer.get_name() == "headless": return
	for uid in rotors:
		if game.runtime.grid.nodes[uid]["enabled"] and preload("res://Energy/Grid.gd").wheel_current(game.world, devices[uid].position) > 0: rotors[uid].rotation.z += delta * 0.7
	for i in range(belt_payloads.size()):
		if i>=game.runtime.automation.routes.size(): break
		var row: Dictionary=game.runtime.automation.routes[i]
		var payload: Node3D=belt_payloads[i]
		payload.visible=game.runtime.automation.active(row,game.runtime.workshops,game.runtime.grid,game.runtime.tribes)
		if payload.visible:
			var a: Vector3=game.runtime.workshops[int(row["from"])].position
			var b: Vector3=game.runtime.workshops[int(row["to"])].position
			payload.position=a.lerp(b,float(row["elapsed"]))+Vector3.UP*0.9
	for uid in lights:
		lights[uid].visible = game.running and game.runtime.grid.powered.get(uid, false) and uid in _visible_lights

func rebuild() -> void:
	for child in get_children(): remove_child(child); child.queue_free()
	devices.clear(); rotors.clear(); lights.clear(); belt_payloads.clear()
	var grid = game.runtime.grid
	for uid in grid.nodes:
		var row: Dictionary = grid.nodes[uid]; var p: Array = row["position"]
		var body := StaticBody3D.new(); body.position = Vector3(p[0], p[1], p[2]); add_child(body); devices[uid] = body
		var shape := BoxShape3D.new(); shape.size = Vector3(0.4, 2.5, 0.4) if row["kind"] != "waterwheel" else Vector3(2.8, 2.4, 2.4)
		S.collider(body, shape, Vector3.UP * (1.25 if row["kind"] != "waterwheel" else 0.4))
		if DisplayServer.get_name() == "headless": continue
		var assembly := Node3D.new(); body.add_child(assembly)
		if row["kind"] == "waterwheel":
			for x in [-1.15, 1.15]: S.beam(assembly, Vector3(x, -1, 0.25), Vector3(x, 1.1, 0.25), 0.12, Color("#805c3d"))
			var wheel := Node3D.new(); wheel.rotation.y=PI/2; assembly.add_child(wheel); rotors[uid] = wheel
			S.beam(assembly,Vector3(-1.3,0,0),Vector3(1.3,0,0),0.11,Color("#575b51"))
			S.beam(assembly,Vector3(0,0.8,0.3),Vector3(0,1.7,0),0.07,Color("#a88453"))
			for z in [-0.3, 0.3]:
				for i in range(12):
					var a := TAU * i / 12
					var b := TAU * (i + 1) / 12
					S.beam(wheel, Vector3(cos(a), sin(a), z), Vector3(cos(b), sin(b), z), 0.09, Color("#a07c50"))
					S.beam(wheel, Vector3.ZERO, Vector3(cos(a), sin(a), z), 0.045, Color("#6c553d"))
			for i in range(12):
				var a := TAU * i / 12
				var paddle := S.box(wheel, Vector3(0.28, 0.11, 0.85), Vector3(cos(a) * 1.02, sin(a) * 1.02, 0), Color("#97734a")); paddle.rotation.z = a - PI / 2
			S.consolidate(wheel)
		else:
			S.beam(assembly, Vector3.ZERO, Vector3(0, 2.8, 0), 0.09, Color("#806045"))
			S.beam(assembly, Vector3(-0.3, 2.65, 0), Vector3(0.3, 2.65, 0), 0.06, Color("#aa8757"))
			if row["kind"] == "electric_lamp":
				S.box(assembly, Vector3(0.32, 0.37, 0.3), Vector3(0, 2.42, 0), Color("#d4b77c"))
				var light := OmniLight3D.new(); light.position.y = 2.35; light.light_color = Color("#ffdb9b"); light.light_energy = 1.5; light.omni_range = 9; body.add_child(light); lights[uid] = light
			else:
				for x in [-0.23, 0.23]: S.cylinder(assembly, 0.07, 0.12, Vector3(x, 2.75, 0), Color("#a9c0b5"))
		S.consolidate(assembly)
		var title := Label3D.new(); title.text = preload("res://Items/Catalog.gd").display_name(row["kind"])
		title.position.y = 3.1; title.font_size = 24; title.pixel_size = 0.006; title.billboard = BaseMaterial3D.BILLBOARD_ENABLED; title.visibility_range_end = 9; body.add_child(title)
		for mesh in assembly.get_children():
			if mesh is GeometryInstance3D: mesh.visibility_range_end = 90
	if DisplayServer.get_name() != "headless":
		var wires := Node3D.new(); add_child(wires)
		for link in grid.links:
			var a: Vector3 = grid.point(link["a"], game.runtime.workshops); var b: Vector3 = grid.point(link["b"], game.runtime.workshops)
			S.beam(wires, a, b, 0.015, Color("#3f443c"))
		S.consolidate(wires)

	for row in game.runtime.automation.routes:
		if int(row["from"])>=game.runtime.workshops.size() or int(row["to"])>=game.runtime.workshops.size(): continue
		var a: Vector3=game.runtime.workshops[int(row["from"])].position
		var b: Vector3=game.runtime.workshops[int(row["to"])].position
		var distance: float=a.distance_to(b)
		var belt:=StaticBody3D.new();belt.position=(a+b)*0.5+Vector3.UP*0.75;belt.rotation.y=atan2((b-a).x,(b-a).z);add_child(belt)
		var collision:=BoxShape3D.new();collision.size=Vector3(0.6,0.16,distance);S.collider(belt,collision,Vector3.ZERO)
		if DisplayServer.get_name()=="headless": continue
		S.box(belt,Vector3(0.55,0.09,distance),Vector3.ZERO,Color("#546158"))
		for x in [-0.32,0.32]:
			S.beam(belt,Vector3(x,0,-distance*0.5),Vector3(x,0,distance*0.5),0.045,Color("#ad9162"))
			for z in [-distance*0.4,distance*0.4]:S.beam(belt,Vector3(x,-0.75,z),Vector3(x,0,z),0.055,Color("#665743"))
		S.consolidate(belt)
		var payload:=Node3D.new();add_child(payload);payload.scale=Vector3.ONE*0.65
		preload("res://Items/WorldPickup.gd").build(payload,preload("res://Items/Catalog.gd").get_item(row["item"]))
		belt_payloads.append(payload)
