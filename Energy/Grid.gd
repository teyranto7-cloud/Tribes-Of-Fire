extends RefCounted
## Authoritative bounded graph. Installed motors pause without real river power.
const KINDS := ["waterwheel", "power_pole", "electric_lamp"]
const MOTOR_KINDS := ["sawmill", "loom", "crusher", "concrete_mixer"]
const MAX_NODES := 128
const MAX_LINKS := 256
var nodes: Dictionary = {}
var links: Array = []
var motors: Array = []
var next_id: int = 1
var powered: Dictionary = {}
var meters: Dictionary = {}

func state() -> Dictionary:
	return {"nodes": nodes.duplicate(true), "links": links.duplicate(true), "motors": motors.duplicate(), "next_id": next_id}

func restore(data: Dictionary) -> void:
	nodes = data.get("nodes", {}).duplicate(true); links = data.get("links", []).duplicate(true)
	motors = data.get("motors", []).map(func(index): return int(index)); next_id = int(data.get("next_id", 1))
	for row in nodes.values():
		var p: Array = row["position"]
		var at := Vector3(p[0],p[1],p[2])
		row["position"]=[at.x,at.y,at.z]
	for link in links: link["wire"] = int(link["wire"])
	powered.clear(); meters.clear()

static func wheel_current(world, at: Vector3) -> float:
	var river = world.sampler.watershed
	if river == null or not world.contains_position(at) or absf(at.x - river.center(at.z)) > river.width(at.z) * 0.9: return 0
	if world.water_level - world.terrain_height(at.x, at.z) < 0.8 or river.is_crossing(at.z): return 0
	return river.current(at.z)

static func placement(world, body, kind: String, ignore: Array=[]) -> Dictionary:
	var at: Vector3 = body.position - body.global_basis.z * 4.0
	at.y = world.water_level + 1.0 if kind == "waterwheel" else world.terrain_height(at.x, at.z)
	var valid: bool = world.contains_position(at) and at.y>=-30 and at.y<=120
	if kind == "waterwheel": valid = valid and wheel_current(world, at) > 0
	else:
		valid = valid and at.y > world.water_level + 0.3
		for offset in [Vector2(0.6, 0), Vector2(0, 0.6)]:
			valid = valid and absf(world.terrain_height(at.x + offset.x, at.z + offset.y) - at.y) < 0.5
	var volume := PhysicsShapeQueryParameters3D.new()
	var shape := BoxShape3D.new();shape.size=Vector3(2.8,2.4,2.4) if kind=="waterwheel" else Vector3(0.6,2.8,0.6)
	volume.shape=shape;volume.transform=Transform3D(Basis.IDENTITY,at+Vector3.UP*(0.4 if kind=="waterwheel" else 1.4));volume.collision_mask=3;volume.exclude=[body.get_rid()]+ignore
	for hit in world.get_world_3d().direct_space_state.intersect_shape(volume,32):
		if not hit["collider"].is_in_group("terrain"):valid=false
	return {"valid": valid, "position": at, "rotation": 0}

func add(kind: String, at: Vector3, owner: String) -> String:
	if kind not in KINDS or nodes.size() >= MAX_NODES or next_id > 1000000: return ""
	var uid := "n%d" % next_id; next_id += 1
	nodes[uid] = {"kind": kind, "position": [at.x, at.y, at.z], "owner": owner, "enabled": true}
	return uid

func endpoint(uid: String, workshops: Array) -> Dictionary:
	if nodes.has(uid): return nodes[uid]
	if uid.begins_with("w") and uid.substr(1).is_valid_int():
		var index := int(uid.substr(1))
		if index >= 0 and index < workshops.size() and index in motors:
			var station = workshops[index]
			if station.retired(): return {}
			return {"owner": station.owner_key, "position": [station.position.x, station.position.y, station.position.z], "enabled": true, "kind": "motor"}
	return {}

func point(uid: String, workshops: Array) -> Vector3:
	var row := endpoint(uid, workshops)
	if row.is_empty(): return Vector3.ZERO
	var p: Array = row["position"]
	return Vector3(p[0], p[1] + (2.8 if row["kind"] == "power_pole" else 1.7), p[2])

func link_ports(a: String, b: String, actor: String, inventory, world, workshops: Array, tribes) -> bool:
	var left := endpoint(a, workshops); var right := endpoint(b, workshops)
	if a == b or left.is_empty() or right.is_empty() or links.size() >= MAX_LINKS: return false
	if not tribes.can_build(left["owner"], actor) or not tribes.can_build(right["owner"], actor): return false
	if links.any(func(row): return (row["a"] == a and row["b"] == b) or (row["a"] == b and row["b"] == a)): return false
	var start := point(a, workshops); var finish := point(b, workshops)
	var distance := start.distance_to(finish)
	if distance > 18 or distance < 0.5: return false
	for i in range(1, 8):
		var at := start.lerp(finish, i / 8.0)
		if world.terrain_height(at.x, at.z) > at.y - 0.15: return false
	var wire := maxi(1, ceili(distance / 6.0))
	if not inventory.consume("wire", wire): return false
	links.append({"a": a, "b": b, "owner": actor, "wire": wire})
	return true

func unlink_ports(index: int, actor: String, inventory, tribes) -> bool:
	if index < 0 or index >= links.size() or not tribes.can_build(links[index]["owner"], actor): return false
	if not inventory.add("wire", int(links[index]["wire"])): return false
	links.remove_at(index); return true

func evaluate(world, workshops: Array, tribes) -> void:
	powered.clear(); meters.clear()
	var graph: Dictionary = {}
	for uid in nodes: graph[uid] = []
	for index in motors:
		if int(index) < workshops.size(): graph["w%d" % int(index)] = []
	for link in links:
		var a: String = link["a"]; var b: String = link["b"]
		var left := endpoint(a, workshops); var right := endpoint(b, workshops)
		if not graph.has(a) or not graph.has(b) or left.is_empty() or right.is_empty(): continue
		# Leaving a tribe revokes cross-owner use immediately, without deleting saves.
		if not tribes.can_build(left["owner"], link["owner"]) or not tribes.can_build(right["owner"], link["owner"]): continue
		if (left["kind"]=="power_pole" and not left["enabled"]) or (right["kind"]=="power_pole" and not right["enabled"]): continue
		graph[a].append(b); graph[b].append(a)
	var visited: Dictionary = {}
	for root in graph:
		if visited.has(root): continue
		var queue: Array = [root]; var component: Array = []; var supply := 0.0; var demand := 0.0
		while not queue.is_empty():
			var uid: String = queue.pop_back()
			if visited.has(uid): continue
			visited[uid] = true; component.append(uid)
			var row := endpoint(uid, workshops)
			if row.get("enabled", false):
				if row["kind"] == "waterwheel":
					var p: Array = row["position"]
					supply += clampf(wheel_current(world, Vector3(p[0], p[1], p[2])) * 90, 0, 150)
				elif row["kind"] == "electric_lamp": demand += 6
				elif row["kind"] == "motor": demand += 40
			queue.append_array(graph[uid])
		for uid in component:
			powered[uid] = supply > 0 and demand <= supply and endpoint(uid, workshops).get("enabled", false)
			meters[uid] = {"generation": supply, "demand": demand, "overload": demand > supply}

static func valid(data: Variant, extent: float, station_count: int) -> bool:
	if not data is Dictionary or data.size() != 4 or not data.get("nodes") is Dictionary or not data.get("links") is Array or not data.get("motors") is Array: return false
	if data["nodes"].size() > MAX_NODES or data["links"].size() > MAX_LINKS or data["motors"].size() > 32: return false
	if not _integer(data.get("next_id"), 1, 1000001): return false
	var endpoints: Dictionary = {}
	for uid in data["nodes"]:
		if not uid is String or not uid.begins_with("n") or not uid.substr(1).is_valid_int() or int(uid.substr(1)) < 1 or int(uid.substr(1)) >= data["next_id"]: return false
		var row: Variant = data["nodes"][uid]
		if not row is Dictionary or row.size()<4 or row.size()>6 or row.get("kind") not in KINDS or not row.get("enabled") is bool: return false
		for field in row:
			if field not in ["kind","position","owner","enabled","revision","paid_cost"]: return false
		if not _integer(row.get("revision",1),1,1000000000): return false
		var paid:Variant=row.get("paid_cost",{})
		if not paid is Dictionary or paid.size()>16:return false
		for item in paid:
			if not item is String or not preload("res://Items/Catalog.gd").known(item) or not _integer(paid[item],1,9999):return false
		if not row.get("owner") is String or row["owner"].length() > 128 or row["owner"].is_empty(): return false
		var p: Variant = row.get("position")
		if not p is Array or p.size() != 3: return false
		for i in range(3):
			if not (p[i] is int or p[i] is float) or not is_finite(float(p[i])) or absf(float(p[i])) > (120 if i == 1 else extent): return false
		endpoints[uid] = true
	for index in data["motors"]:
		if not _integer(index, 0, station_count - 1) or endpoints.has("w%d" % int(index)): return false
		endpoints["w%d" % int(index)] = true
	var seen: Dictionary = {}
	for link in data["links"]:
		if not link is Dictionary or link.size() != 4 or not link.get("a") is String or not link.get("b") is String: return false
		if link["a"] == link["b"] or not endpoints.has(link["a"]) or not endpoints.has(link["b"]): return false
		var pair: String = (link["a"] + ":" + link["b"]) if link["a"] < link["b"] else (link["b"] + ":" + link["a"])
		if seen.has(pair) or not link.get("owner") is String or link["owner"].length() > 128 or not _integer(link.get("wire"), 1, 3): return false
		seen[pair] = true
	return true

static func _integer(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value == floorf(value) and value >= low and value <= high
