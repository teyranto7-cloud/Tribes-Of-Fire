extends RefCounted
## Atomic industrial removal. Workshop slots are never recycled or reindexed.
const Catalog = preload("res://Building/Catalog.gd")
const Workshop = preload("res://Building/Workshop.gd")
var game
var last_error := ""

func deny(code: String) -> bool:
	last_error = code
	game.runtime.building.last_error = code
	return false

static func valid(data: Dictionary) -> bool:
	if data.size() != 4 or data.get("op") not in ["remove_motor", "demolish"] or (not data.get("confirm") is bool or data["confirm"] != true): return false
	return Catalog.numeric(data.get("station"), 0, Workshop.MAX_RECORDS - 1) and data["station"] == floorf(data["station"]) and Catalog.numeric(data.get("revision"), 1, 999999999) and data["revision"] == floorf(data["revision"])

func reason(id: int, index: int, operation: String) -> String:
	var runtime = game.runtime
	if not game.players.has(id) or index < 0 or index >= runtime.workshops.size(): return "stale"
	var station = runtime.workshops[index]
	if station.retired(): return "stale"
	if not runtime.building.can_manage({"owner": station.owner_key}, runtime.key(id)): return "ownership"
	if station.position.distance_to(game.players[id].position) > 9: return "reach"
	if not runtime.building.territory_allows(runtime.key(id), station.position): return "ownership"
	if not runtime._clear_interaction(game.players[id], station.position + Vector3.UP, [station.get_rid()]): return "visibility"
	for link in runtime.grid.links:
		if "w%d" % index in [link["a"], link["b"]]: return "connections"
	for route in runtime.automation.routes:
		if index in [int(route["from"]), int(route["to"])]: return "connections"
	if operation == "remove_motor": return "" if index in runtime.grid.motors else "stale"
	if index in runtime.grid.motors: return "motor"
	var moving: String = runtime.building.station_move_reason(id, index)
	if not moving.is_empty(): return moving
	if float(station.machine.get("progress", 0)) > 0: return "contents"
	for body in game.players.values():
		var local: Vector3 = station.to_local(body.position + Vector3.UP * .9)
		if absf(local.x) < 1.2 and absf(local.z) < .9 and local.y > -.8 and local.y < 2.8: return "occupied"
	return ""

func edit(id: int, data: Dictionary) -> bool:
	data = data.duplicate(true); data.erase("request_id")
	if not valid(data): return deny("invalid")
	var index := int(data["station"])
	var blocked := reason(id, index, data["op"])
	if not blocked.is_empty(): return deny(blocked)
	var runtime = game.runtime
	var station = runtime.workshops[index]
	if int(station.building.get("revision", 1)) != int(data["revision"]): return deny("stale")
	var refund := {}
	if data["op"] == "remove_motor": refund["motor"] = 1
	else:
		for item in station.building.get("paid_cost", {}):
			var count := floori(float(station.building["paid_cost"][item]) * .5)
			if count > 0: refund[item] = count
	if not game.inventories[id].transact({}, refund): return deny("capacity")
	station.building["revision"] = int(data["revision"]) + 1
	if data["op"] == "remove_motor": runtime.grid.motors.erase(index)
	else:
		station.building["retired"] = true
		station.building.erase("paid_cost")
		station.machine = preload("res://Building/Factory.gd").empty()
		station.apply_retired()
	runtime.grid.evaluate(game.world, runtime.workshops, runtime.tribes)
	runtime.energy_visuals.rebuild()
	return true

static func valid_device(data: Dictionary) -> bool:
	if data.size()!=4 or data.get("op") not in ["move","demolish"] or (not data.get("confirm") is bool or data["confirm"]!=true): return false
	var uid: Variant=data.get("id")
	return uid is String and uid.begins_with("n") and uid.substr(1).is_valid_int() and int(uid.substr(1))>0 and int(uid.substr(1))<=1000000 and Catalog.numeric(data.get("revision"),1,999999999) and data["revision"]==floorf(data["revision"])

func device_reason(id: int, uid: String) -> String:
	if not game.players.has(id) or not game.runtime.grid.nodes.has(uid): return "stale"
	var row: Dictionary=game.runtime.grid.nodes[uid]
	if not game.runtime.building.can_manage(row,game.runtime.key(id)): return "ownership"
	var at:=Vector3(row["position"][0],row["position"][1],row["position"][2])
	if game.players[id].position.distance_to(at)>9: return "reach"
	if not game.runtime.building.territory_allows(game.runtime.key(id),at): return "ownership"
	for link in game.runtime.grid.links:
		if uid in [link["a"],link["b"]]: return "connections"
	var device=game.runtime.energy_visuals.devices.get(uid)
	if device==null or not game.runtime._clear_interaction(game.players[id],at+Vector3.UP,[device.get_rid()]): return "visibility"
	return ""

func preview_device(id: int, uid: String) -> Dictionary:
	var row: Dictionary=game.runtime.grid.nodes.get(uid,{})
	if row.is_empty(): return {"valid":false,"position":game.players[id].position,"rotation":0,"reason":"stale"}
	var device=game.runtime.energy_visuals.devices.get(uid)
	var site:Dictionary=preload("res://Energy/Grid.gd").placement(game.world,game.players[id],row["kind"],[device.get_rid()] if device!=null else [])
	site["reason"]="ok" if site["valid"] else "collision"
	if not game.runtime.building.territory_allows(game.runtime.key(id),site["position"]):site["valid"]=false;site["reason"]="ownership"
	for other in game.runtime.grid.nodes:
		if other==uid: continue
		var p:Array=game.runtime.grid.nodes[other]["position"]
		if Vector3(p[0],p[1],p[2]).distance_to(site["position"])<2:site["valid"]=false;site["reason"]="collision"
	for station in game.runtime.workshops:
		if not station.retired() and station.position.distance_to(site["position"])<2:site["valid"]=false;site["reason"]="collision"
	return site

func edit_device(id: int, data: Dictionary) -> bool:
	data=data.duplicate(true);data.erase("request_id")
	if not valid_device(data): return deny("invalid")
	var uid: String=data["id"];var blocked:=device_reason(id,uid)
	if not blocked.is_empty(): return deny(blocked)
	var grid=game.runtime.grid;var row:Dictionary=grid.nodes[uid]
	if int(row.get("revision",1))!=int(data["revision"]): return deny("stale")
	if data["op"]=="move":
		var site:=preview_device(id,uid)
		if not site["valid"]: return deny(site["reason"])
		row["position"]=[site["position"].x,site["position"].y,site["position"].z];row["revision"]=int(data["revision"])+1
	else:
		var refund:Dictionary={}
		for item in row.get("paid_cost",{}):
			var count:=floori(float(row["paid_cost"][item])*.5)
			if count>0:refund[item]=count
		if not game.inventories[id].transact({},refund):return deny("capacity")
		grid.nodes.erase(uid)
	grid.evaluate(game.world,game.runtime.workshops,game.runtime.tribes);game.runtime.energy_visuals.rebuild()
	return true
