extends Node3D
const Balance = preload("res://Game/Balance.gd")
const Shapes = preload("res://World/Shapes.gd")
const Catalog=preload("res://Items/Catalog.gd")
var visibility_left:float=0.0
var world
var regrowth: Array = []
var nodes: Array[StaticBody3D] = []
var stocks: Array[int] = []
var hits: Array[int] = []
var _cooldowns: Dictionary = {}
func setup(value) -> void:
	world = value
	for i in range(Catalog.database()["resource_nodes"].size()):
		var kind: String = resource_kind(i)
		var p := Vector3(4, 0, -1) if i == 0 else Vector3(sin(i * 2.4) * (8 + i * 1.6), 0, cos(i * 2.4) * (8 + i * 1.6))
		if i == 9:
			p = Vector3(-4, 0, 1)
		p.y = world.terrain_height(p.x, p.z)
		var body := StaticBody3D.new()
		body.position = p
		add_child(body)
		var color := Color("#747a78")
		if kind in ["berries", "fiber", "herb", "petals"]:
			color = Color("#456e40")
		elif kind != "stone":
			color = Color.from_hsv(float(i % 9) / 9, 0.3, 0.6)
		var base := Shapes.sphere(body, 0.55, Vector3(0, 0.4, 0), color)
		base.scale = Vector3(1.1, 0.8, 1.0)
		for j in range(5):
			var gem := Shapes.sphere(body, 0.13 if kind == "berries" else 0.19, Vector3(sin(j * 2.4) * 0.35, 0.55, cos(j * 2.4) * 0.35), Color("#ab4944") if kind == "berries" else color.lightened(0.16))
			gem.scale.y = 1.3
		if kind in ["herb","petals","fiber"]:
			base.hide()
			for child in body.get_children():
				if child is MeshInstance3D: child.hide()
			for j in range(5):
				var stem_at:=Vector3(sin(j*2.4)*0.22,0.25,cos(j*2.4)*0.22)
				Shapes.cylinder(body,0.018,0.5,stem_at,Color("#52784d"))
				for side in [-1,1]:
					var leaf=Shapes.sculpted(body,stem_at+Vector3(side*0.10,0.02,0),Vector3(0.14,0.22,0.04),Color("#6d9e51"),"leaf")
					leaf.rotation.z=side*0.7
				if kind!="fiber":
					for petal in range(5):
						var a:=float(petal)*TAU/5
						var flower=Shapes.sphere(body,0.065,stem_at+Vector3(cos(a)*0.06,0.28,sin(a)*0.06),Color("#ad83c6") if kind=="herb" else Color("#f1bf64"))
						flower.scale.y=0.3
		# Hidden placeholder meshes must not be baked back into the live plant.
		for child in body.get_children():
			if child is MeshInstance3D and not child.visible: child.free()
		Shapes.consolidate(body)
		var label:=Label3D.new()
		label.text=preload("res://Items/Catalog.gd").display_name(kind)
		label.position.y=1.15;label.font_size=30;label.pixel_size=0.007
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=false
		label.visibility_range_end=12
		body.add_child(label)
		var shape := SphereShape3D.new()
		shape.radius = 0.56
		Shapes.collider(body, shape, Vector3(0, 0.4, 0))
		nodes.append(body)
		stocks.append(8)
		hits.append(0)
		regrowth.append(0.0)
func closest(body: Node3D, reach: float = 3.0, facing: bool = false, hand_only: bool = false) -> int:
	var chosen := -1
	for i in range(nodes.size()):
		if hand_only and Catalog.gathering(resource_kind(i)).get("tool","")!="hand":continue
		var offset := nodes[i].global_position - body.global_position
		if stocks[i] <= 0 or not nodes[i].visible or offset.length() > reach:
			continue
		if facing and offset.normalized().dot(-body.global_basis.z) < 0.3:
			continue
		reach = offset.length()
		chosen = i
	return chosen
func mine(body, inventory, id: int, hand: bool = false, ground_reward: bool = false) -> bool:
	if id < 0 or id >= nodes.size() or not body.authoritative or body.vitals.hp <= 0 or body.position.distance_to(nodes[id].position) > 3.0 or stocks[id] <= 0:
		return false
	var query := PhysicsRayQueryParameters3D.create(body.global_position + Vector3.UP,
		nodes[id].global_position + Vector3.UP * 0.6, 1)
	query.exclude = [body.get_rid(), nodes[id].get_rid()]
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		return false
	var kind: String = resource_kind(id)
	var rule:=Catalog.gathering(kind)
	if rule.is_empty():return false
	if hand and rule["tool"]!="hand":
		return false
	if not hand and (Catalog.tool(inventory.equipped_item())!="pickaxe" or Catalog.harvest_power(inventory.equipped_item())<int(rule.get("required_power",1))):
		return false
	var now := Time.get_ticks_msec()
	var key: int = body.get_instance_id()
	if now < int(_cooldowns.get(key, 0)) or body.stamina < 8:
		return false
	if not ground_reward and not inventory.can_add(kind, 1):
		return false
	_cooldowns[key] = now + int(Balance.number("gathering", "iron_pickaxe_action_seconds" if inventory.equipped_item() == "iron_pickaxe" else "pickaxe_action_seconds", 0.65) * 1000)
	body.stamina -= 8
	body.attack_time = 0.55
	if not hand:
		inventory.wear_equipment("hand", 1)
	hits[id]+=1 if hand else maxi(1,Catalog.harvest_power(inventory.equipped_item()))
	if hits[id]<int(rule.get("hardness",1)):return false
	hits[id]=0
	if not ground_reward: inventory.add(kind, 1)
	stocks[id] -= 1
	if stocks[id] == 0: regrowth[id] = Time.get_unix_time_from_system() + float(rule.get("regrow_seconds",600))
	_refresh(id)
	return true
func capture() -> Array:
	return stocks.duplicate()
func restore(data: Array) -> void:
	if data.size() < 22 or data.size() > stocks.size():
		return
	for i in range(data.size()):
		if not (data[i] is int or data[i] is float) or data[i] < 0 or data[i] > 8 or data[i] != floorf(data[i]):
			return
	for i in range(data.size()):
		stocks[i] = int(data[i])
		_refresh(i)
func _refresh(i: int) -> void:
	nodes[i].visible = stocks[i] > 0 and (not world.has_method("has_terrain_at") or world.has_terrain_at(nodes[i].position))
	nodes[i].collision_layer = 1 if stocks[i] > 0 else 0

func restore_regrowth(values: Array) -> void:
	if values.size() < 22 or values.size() > stocks.size(): return
	for value in values:
		if not (value is int or value is float) or not is_finite(float(value)) or value < 0 or value > 4102444800: return
	for i in range(values.size()): regrowth[i] = float(values[i])
func tick_regrowth() -> void:
	for i in range(regrowth.size()):
		if float(regrowth[i]) > 0 and Time.get_unix_time_from_system() >= float(regrowth[i]):
			regrowth[i] = 0.0; stocks[i] = 8; _refresh(i)
func reposition() -> void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=int(world.descriptor()["seed"]) if world.has_method("descriptor") else 1337
	var extent:float=world.half_extent()*0.80 if world.has_method("half_extent") else 48.0
	for i in range(nodes.size()):
		var node=nodes[i]
		if i>=22:
			var radius:float=10.0+float(i-22)*0.5 if i<32 else rng.randf_range(22,extent)
			var angle:float=float(i)*2.39996
			node.position=Vector3(cos(angle)*radius,0,sin(angle)*radius)
		if int(world.descriptor()["generator"]) >= 3 and i >= 32:
			var kind := resource_kind(i)
			if kind in ["rare_ore","gold_ore","silver_ore","sulfur"]:
				var cave: Vector3 = world.sampler.locations[0]["position"]
				node.position = cave + Vector3(sin(i*2.4)*14,0,cos(i*2.4)*14)
			elif kind in ["clay","herb","petals","soil"]:
				var z := rng.randf_range(-500,500)
				node.position = Vector3(world.sampler.river_x(z)+world.sampler.watershed.width(z)+rng.randf_range(10,25),0,z)
		if world.has_method("descriptor") and world.descriptor()["generator"]>=2:
			for attempt in range(80):
				if world.terrain_height(node.position.x,node.position.z)>-2.0: break
				node.position.x+=2.0
		node.position.y=world.terrain_height(node.position.x,node.position.z)
func resource_kind(id: int) -> String:
	var records:Array=Catalog.database().get("resource_nodes",[])
	return str(records[id]) if id>=0 and id<records.size() else ""

func _process(delta: float) -> void:
	visibility_left-=delta
	if visibility_left>0:return
	visibility_left=0.3
	for i in range(nodes.size()):_refresh(i)
