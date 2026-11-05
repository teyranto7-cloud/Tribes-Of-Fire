extends RefCounted
## All costs, revisions, permissions, collision and refunds execute on authority.
const Catalog = preload("res://Building/Catalog.gd")
const Placement = preload("res://Building/Placement.gd")
var game
var last_error: String = ""
func deny(reason: String) -> bool: last_error=reason; return false
func territory_allows(actor: String, at: Vector3) -> bool:
	for id in game.world.structure_registry.nearby(at,16):
		var row: Dictionary=game.world.structure_registry.records[id]
		if row["kind"]=="totem" and not game.runtime.tribes.can_build(row["owner"],actor): return false
	return true
func can_interact(row: Dictionary, actor: String) -> bool:
	var owner: String=row.get("owner","")
	if owner.is_empty() or game.runtime.tribes.can_build(owner,actor) or not row.get("locked",true): return true
	if row.get("allow_allies",false):
		var a: String=game.runtime.tribes.tribe_of(owner); var b: String=game.runtime.tribes.tribe_of(actor)
		return not a.is_empty() and not b.is_empty() and game.runtime.tribes.relations.get(game.runtime.tribes.pair_key(a,b),{}).get("status","")=="allied"
	return false
func can_manage(row: Dictionary, actor: String) -> bool:
	if row["owner"].is_empty(): return false
	if row["owner"]==actor: return true
	var tribe: String=game.runtime.tribes.tribe_of(row["owner"])
	return not tribe.is_empty() and game.runtime.tribes.tribes.get(tribe,{}).get("leader","")==actor
func preview(id: int, kind: String, turn: int, options: Dictionary={}, ignore_id: int=0) -> Dictionary:
	var is_station:bool=game.runtime.Catalog.station_ids().has(kind)
	var site:Dictionary=Placement.station(game.world,game.players[id],turn,options) if is_station else Placement.evaluate(game.world,game.players[id],kind,turn,options,ignore_id)
	if is_station: site["supports"]=[]
	var tier: String=options.get("tier","wood"); var cost:Dictionary=game.runtime.Balance.section("building")["costs"].get(kind,{}) if is_station else Catalog.cost(kind,tier)
	if tier=="wood" and ignore_id==0:
		for item in game.runtime.Catalog.ids():
			if game.runtime.Catalog.get_item(item).get("place","")==kind and game.inventories[id].count(item)>0: cost={item:1}; break
	site["cost"]=cost
	if not site["valid"]: return site
	if kind=="door_leaf" and site["supports"].is_empty(): site["valid"]=false; site["reason"]="frame"; return site
	var actor: String=game.runtime.key(id)
	if not territory_allows(actor,site["position"]): site["valid"]=false; site["reason"]="ownership"; return site
	for parent in site["supports"]:
		if not game.runtime.tribes.can_build(game.world.structure_registry.records[parent]["owner"],actor): site["valid"]=false; site["reason"]="ownership"; return site
	var strict: bool=bool(game.server_rules.get("structural_support",false))
	if strict and Catalog.piece(kind).get("snap_family","") in ["roof","deck"] and not Catalog.piece(kind).get("grounded",false):
		if site["supports"].is_empty():
			if Catalog.piece(kind).get("snap_family","")=="roof" or absf(site["position"].y-game.world.terrain_height(site["position"].x,site["position"].z))>.5: site["valid"]=false; site["reason"]="support"; return site
		else:
			var parent: int=site["supports"][0]; var depth:=0
			while game.world.structure_registry.records.has(parent):
				var row: Dictionary=game.world.structure_registry.records[parent]
				if Catalog.piece(row["kind"]).get("grounded",false) or Catalog.piece(row["kind"]).get("snap_family","") in ["wall","pillar"]: break
				depth+=1
				if depth>2: site["valid"]=false; site["reason"]="support"; return site
				if row.get("supports",[]).is_empty(): break
				parent=int(row["supports"][0])
	if ignore_id>0:
		var descendants: Array=game.world.structure_registry.dependants(ignore_id)
		for parent in site["supports"]:
			if parent in descendants: site["valid"]=false; site["reason"]="support"; return site
	else:
		for item in cost:
			if game.inventories[id].count(item)<int(cost[item]): site["valid"]=false; site["reason"]="cost"; return site
	return site
func build(id: int, kind: String, turn: int, options: Dictionary) -> bool:
	var site:=preview(id,kind,turn,options)
	if not site["valid"]: return deny(site["reason"])
	if game.world.structure_registry.next_id>1000000: return deny("limit")
	if not game.inventories[id].transact(site["cost"],{}): return deny("cost")
	var tier: String=options.get("tier","wood")
	game.world.add_structure(kind,site["position"],site["rotation"],game.runtime.key(id),-1,{"hp":Catalog.maximum_hp(tier),"tier":tier,"mirror":options.get("mirror",false),"paint":0,"name":"","locked":true,"allow_allies":false,"supports":site["supports"],"revision":1,"paid_cost":Catalog.salvage_basis(kind,site["cost"])})
	return true
static func valid_edit(data: Dictionary) -> bool:
	if not Catalog.numeric(data.get("id"),1,1000000) or data["id"]!=floorf(data["id"]) or not Catalog.numeric(data.get("revision"),1,1000000000) or data["revision"]!=floorf(data["revision"]): return false
	var op: Variant=data.get("op"); var fields: Array=["id","revision","op"]
	match op:
		"repair": pass
		"upgrade":
			fields.append("tier")
			if not data.get("tier") is String or not data["tier"] in Catalog.tiers(): return false
		"move":
			fields.append_array(["rotation","options"])
			if not Catalog.numeric(data.get("rotation"),0,3) or data["rotation"]!=floorf(data["rotation"]) or not data.get("options") is Dictionary or not Catalog.valid_options(data["options"]): return false
		"demolish":
			fields.append_array(["confirm","cascade","expected"])
			if data.get("confirm")!=true or not data.get("cascade") is bool: return false
			if not data.get("expected") is Array or data["expected"].is_empty() or data["expected"].size()>24: return false
			var ids:Dictionary={}
			for pair in data["expected"]:
				if not pair is Array or pair.size()!=2 or not Catalog.numeric(pair[0],1,1000000) or pair[0]!=floorf(pair[0]) or ids.has(int(pair[0])) or not Catalog.numeric(pair[1],1,1000000000) or pair[1]!=floorf(pair[1]): return false
				ids[int(pair[0])]=true
		"configure":
			fields.append_array(["name","paint","locked","allow_allies"])
			if not data.get("name") is String or data["name"].strip_edges().length()>40 or data["name"].contains("\n") or data["name"].contains("\r") or data["name"].to_utf8_buffer().has(0): return false
			if not Catalog.numeric(data.get("paint"),0,5) or data["paint"]!=floorf(data["paint"]) or not data.get("locked") is bool or not data.get("allow_allies") is bool: return false
		_: return false
	if data.size()!=fields.size(): return false
	for key in fields:
		if not data.has(key): return false
	return true
func edit(id: int, data: Dictionary) -> bool:
	data=data.duplicate(true); data.erase("request_id")
	if not valid_edit(data): return deny("invalid")
	game.world._sync_structure_records()
	var uid:=int(data["id"]); var row:Dictionary=game.world.structure_registry.records.get(uid,{}).duplicate(true)
	if row.is_empty(): return deny("stale")
	if game.world.structure_registry.point(row).distance_to(game.players[id].position)>9: return deny("reach")
	var actor: String=game.runtime.key(id); var inv=game.inventories[id]
	if int(row.get("revision",1))!=int(data["revision"]) or int(data["revision"])>=1000000000: return deny("stale")
	if not territory_allows(actor,game.world.structure_registry.point(row)): return deny("ownership")
	if (data["op"] in ["repair","upgrade"] and not game.runtime.tribes.can_build(row["owner"],actor)) or (data["op"] not in ["repair","upgrade"] and not can_manage(row,actor)): return deny("ownership")
	var piece=game.world.get_structure(uid)
	if piece==null or not game.runtime._clear_interaction(game.players[id],piece.position+Vector3.UP*.7,piece.collision_rids()): return deny("visibility")
	match data["op"]:
		"repair":
			var maximum:=Catalog.maximum_hp(row.get("tier","wood"))
			if int(row["hp"])>=maximum: return deny("intact")
			var cost:=Catalog.cost(row["kind"],row.get("tier","wood"))
			for item in cost: cost[item]=maxi(1,ceili(float(cost[item])*.25))
			if not inv.transact(cost,{}): return deny("cost")
			row["hp"]=mini(maximum,int(row["hp"])+ceili(maximum*.25))
		"upgrade":
			var tier: String=data["tier"]
			if Catalog.tiers().find(tier)<=Catalog.tiers().find(row.get("tier","wood")): return deny("material")
			var cost:=Catalog.cost(row["kind"],tier)
			if cost.is_empty() or not inv.transact(cost,{}): return deny("cost")
			var ratio:=float(row["hp"])/Catalog.maximum_hp(row.get("tier","wood"))
			row["tier"]=tier; row["hp"]=maxi(1,roundi(ratio*Catalog.maximum_hp(tier)))
			var paid: Dictionary=row.get("paid_cost",{}).duplicate()
			for item in cost: paid[item]=int(paid.get(item,0))+int(cost[item])
			row["paid_cost"]=paid
		"configure":
			for field in ["name","paint","locked","allow_allies"]: row[field]=data[field]
			row["name"]=str(row["name"]).strip_edges()
		"move","demolish":
			var dependants: Array=game.world.structure_registry.dependants(uid)
			if data["op"]=="move" and not dependants.is_empty(): return deny("dependants")
			var ids: Array=[uid]
			if data["op"]=="demolish":
				if not dependants.is_empty() and not data["cascade"]: return deny("dependants")
				ids.append_array(dependants)
				if ids.size()>24: return deny("limit")
				if data["expected"].size()!=ids.size(): return deny("stale")
				for pair in data["expected"]:
					if int(pair[0]) not in ids or int(game.world.structure_registry.records[int(pair[0])].get("revision",1))!=int(pair[1]): return deny("stale")
			var refund:= {}
			for target in ids:
				var affected: Dictionary=game.world.structure_registry.records[target]
				if not can_manage(affected,actor): return deny("ownership")
				for count in affected.get("storage",{}).values():
					if int(count)>0: return deny("contents")
				if game.runtime.farming.has(str(target)) or affected["kind"]=="raft": return deny("contents")
				var point: Vector3=game.world.structure_registry.point(affected)
				for station in game.runtime.workshops:
					if Vector2(station.position.x-point.x,station.position.z-point.z).length()<2.2 and station.position.y>point.y+.1 and station.position.y<point.y+4: return deny("dependants")
				for device in game.runtime.grid.nodes.values():
					var p:=Vector3(device["position"][0],device["position"][1],device["position"][2])
					if Vector2(p.x-point.x,p.z-point.z).length()<2.2 and p.y>point.y+.1 and p.y<point.y+4: return deny("dependants")
				for body in game.players.values():
					if (body.boat!=null and body.boat==game.world.get_structure(target)) or (Vector2(body.position.x-point.x,body.position.z-point.z).length()<2 and body.position.y>point.y+.1 and body.position.y<point.y+4): return deny("occupied")
				for item in affected.get("paid_cost",{}): refund[item]=int(refund.get(item,0))+floori(float(affected["paid_cost"][item])*.5)
			for item in refund.keys():
				if refund[item]<=0: refund.erase(item)
			if data["op"]=="demolish":
				if not inv.transact({},refund): return deny("capacity")
				for target in ids: game.world.remove_structure(target)
				for body in game.players.values(): body.respawn_position=game.world.bed_spawn(game.runtime.key(game.players.find_key(body)))
				return true
			var options: Dictionary=data["options"].duplicate(true); options["tier"]=row.get("tier","wood"); options["mirror"]=row.get("mirror",false)
			var site:=preview(id,row["kind"],int(data["rotation"]),options,uid)
			if not site["valid"]: return deny(site["reason"])
			row["position"]=[site["position"].x,site["position"].y,site["position"].z]; row["rotation"]=site["rotation"]; row["supports"]=site["supports"]
	row["revision"]=int(row.get("revision",1))+1
	game.world.replace_structure(row)
	for peer_id in game.players: game.players[peer_id].respawn_position=game.world.bed_spawn(game.runtime.key(peer_id))
	return true
func toggle(id: int, piece) -> bool:
	if not can_interact(piece.get_record(),game.runtime.key(id)): return false
	var opening:Array=Catalog.piece(piece.kind).get("door",[])
	if opening.is_empty(): return false
	var shape:=BoxShape3D.new(); shape.size=Vector3(opening[0],opening[1],.2) if piece.kind!="hatch" else Vector3(opening[0],.2,opening[1])
	var query:=PhysicsShapeQueryParameters3D.new(); query.shape=shape; query.collision_mask=2
	var swing:int=int(piece.record_extra.get("door_swing",-1))
	if not piece.open and piece.kind!="hatch": swing=1 if piece.to_local(game.players[id].global_position).z>=0 else -1
	for step in range(7):
		var hinge:=Basis(Vector3.BACK if piece.kind=="hatch" else Vector3.UP,float(step)/6*(PI*.5 if piece.kind=="hatch" else swing*PI*.55))
		var center:=Vector3(float(opening[0])/2,0 if piece.kind=="hatch" else float(opening[1])/2,0)
		query.transform=piece.global_transform*Transform3D(hinge,piece.hinge.position+hinge*center)
		if not game.world.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(): return false
	if piece.kind!="hatch": piece.record_extra["door_swing"]=swing
	return game.world.toggle_door(piece.structure_id)
static func valid_station_move(data: Dictionary) -> bool:
	return data.size()==4 and Catalog.numeric(data.get("station"),0,31) and data["station"]==floorf(data["station"]) and Catalog.numeric(data.get("revision"),1,1000000000) and data["revision"]==floorf(data["revision"]) and Catalog.numeric(data.get("rotation"),0,3) and data["rotation"]==floorf(data["rotation"]) and data.get("options") is Dictionary and Catalog.valid_options(data["options"])
func station_move_reason(id: int, index: int) -> String:
	if index<0 or index>=game.runtime.workshops.size(): return "stale"
	var station=game.runtime.workshops[index]
	if not can_manage({"owner":station.owner_key},game.runtime.key(id)): return "ownership"
	if station.position.distance_to(game.players[id].position)>9: return "reach"
	if index in game.runtime.grid.motors: return "contents"
	for link in game.runtime.grid.links:
		if link["a"]=="w%d"%index or link["b"]=="w%d"%index: return "contents"
	for route in game.runtime.automation.routes:
		if int(route["from"])==index or int(route["to"])==index: return "contents"
	for buffer in ["input","output"]:
		for count in station.machine.get(buffer,{}).values():
			if int(count)>0: return "contents"
	for queue in game.runtime.activities.queues.values():
		for job in queue:
			if game.runtime.Catalog.recipe(job["recipe"]).get("station")==station.kind: return "contents"
	return ""
func preview_station(id: int, index: int, turn: int, options: Dictionary) -> Dictionary:
	var station=game.runtime.workshops[index]
	var site:=Placement.station(game.world,game.players[id],turn,options,station)
	if not territory_allows(game.runtime.key(id),site["position"]): site["valid"]=false; site["reason"]="ownership"
	return site
func move_station(id: int, data: Dictionary) -> bool:
	data=data.duplicate(true); data.erase("request_id")
	if not valid_station_move(data): return deny("invalid")
	var index:=int(data["station"]); var reason:=station_move_reason(id,index)
	if not reason.is_empty(): return deny(reason)
	var station=game.runtime.workshops[index]
	if int(station.building.get("revision",1))!=int(data["revision"]) or data["revision"]>=1000000000: return deny("stale")
	if not game.runtime._clear_interaction(game.players[id],station.position+Vector3.UP,[station.get_rid()]): return deny("visibility")
	var site:=preview_station(id,index,int(data["rotation"]),data["options"])
	if not site["valid"]: return deny(site["reason"])
	station.position=site["position"]; station.rotation.y=int(site["rotation"])*PI*.5; station.building={"rotation":int(site["rotation"]),"revision":int(data["revision"])+1}
	return true
