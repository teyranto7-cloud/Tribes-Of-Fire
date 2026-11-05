extends RefCounted
## One physical lane moves at most one item per second, on the authority.
const Catalog = preload("res://Items/Catalog.gd")
const Factory = preload("res://Building/Factory.gd")
var routes: Array = []

func add(from: int, to: int, item: String, actor: String, inventory, workshops: Array, tribes, world = null) -> bool:
	if from == to or from < 0 or to < 0 or from >= workshops.size() or to >= workshops.size() or routes.size() >= 32: return false
	if workshops[from].retired() or workshops[to].retired(): return false
	if not tribes.can_build(workshops[from].owner_key, actor) or not tribes.can_build(workshops[to].owner_key, actor): return false
	if workshops[from].position.distance_to(workshops[to].position) > 8: return false
	if not Factory.definition(workshops[from].kind, workshops[from].machine).get("output", {}).has(item): return false
	if not Factory.definition(workshops[to].kind, workshops[to].machine).get("input", {}).has(item): return false
	if routes.any(func(row): return int(row["from"]) == from and int(row["to"]) == to and row["item"] == item): return false
	if world!=null:
		var query:=PhysicsRayQueryParameters3D.create(workshops[from].position+Vector3.UP*0.75,workshops[to].position+Vector3.UP*0.75,1,[workshops[from].get_rid(),workshops[to].get_rid()])
		if not world.get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return false
	if not inventory.consume("conveyor", 1): return false
	routes.append({"from": from, "to": to, "item": item, "owner": actor, "elapsed": 0.0})
	return true

func remove(from: int, to: int, item: String, actor: String, inventory, tribes) -> bool:
	for row in routes:
		if int(row["from"]) == from and int(row["to"]) == to and row["item"] == item:
			if not tribes.can_build(row["owner"], actor) or not inventory.add("conveyor", 1): return false
			routes.erase(row); return true
	return false

func active(row: Dictionary, workshops: Array, grid, tribes) -> bool:
	var from: int = row["from"]; var to: int = row["to"]
	if from >= workshops.size() or to >= workshops.size() or not from in grid.motors or not grid.powered.get("w%d" % from, false): return false
	if workshops[from].retired() or workshops[to].retired(): return false
	if not tribes.can_build(workshops[from].owner_key, row["owner"]) or not tribes.can_build(workshops[to].owner_key, row["owner"]): return false
	var target: Dictionary = workshops[to].machine["input"]
	if not Factory.definition(workshops[to].kind, workshops[to].machine).get("input", {}).has(row["item"]): return false
	return int(workshops[from].machine["output"].get(row["item"], 0)) > 0 and int(target.get(row["item"], 0)) < 9999 and (target.has(row["item"]) or target.values().filter(func(count): return int(count)>0).size() < 8)

func advance(delta: float, workshops: Array, grid, tribes) -> void:
	if not is_finite(delta) or delta <= 0: return
	for row in routes:
		if not active(row, workshops, grid, tribes): row["elapsed"] = 0.0; continue
		row["elapsed"] = minf(10, float(row["elapsed"]) + minf(delta, 10))
		while row["elapsed"] >= 1 and active(row, workshops, grid, tribes):
			var source: Dictionary = workshops[int(row["from"])].machine["output"]
			var target: Dictionary = workshops[int(row["to"])].machine["input"]
			for empty_item in target.keys():
				if int(target[empty_item])<=0:target.erase(empty_item)
			source[row["item"]] = int(source[row["item"]]) - 1
			target[row["item"]] = int(target.get(row["item"], 0)) + 1
			row["elapsed"] -= 1
		if not active(row, workshops, grid, tribes): row["elapsed"] = 0.0

static func valid(data: Variant, station_count: int) -> bool:
	if not data is Array or data.size() > 32: return false
	var seen: Dictionary = {}
	for row in data:
		if not row is Dictionary or row.size() != 5: return false
		for field in ["from", "to"]:
			var n: Variant = row.get(field)
			if not (n is int or n is float) or not is_finite(float(n)) or n != floorf(n) or n < 0 or n >= station_count: return false
		if row["from"] == row["to"] or not row.get("item") is String or not Catalog.known(row["item"]): return false
		if not row.get("owner") is String or row["owner"].is_empty() or row["owner"].length() > 128: return false
		var elapsed: Variant = row.get("elapsed")
		if not (elapsed is int or elapsed is float) or not is_finite(float(elapsed)) or elapsed < 0 or elapsed >= 1: return false
		var uid := "%d:%d:%s" % [row["from"], row["to"], row["item"]]
		if seen.has(uid): return false
		seen[uid] = true
	return true
