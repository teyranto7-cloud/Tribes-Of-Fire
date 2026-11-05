extends RefCounted
## Damage has no client-supplied amount/target: it uses the validated attack ray.
const Catalog = preload("res://Building/Catalog.gd")
var game

func allowed(actor: String, owner: String) -> bool:
	if owner.is_empty(): return true
	var mode: String = game.server_rules.get("pvp", "off")
	var tribes = game.runtime.tribes
	if mode == "off" or not tribes.can_damage(actor, owner): return false
	return mode == "on" or tribes.at_war(tribes.tribe_of(actor), tribes.tribe_of(owner))

func strike(id: int, attack: Dictionary) -> bool:
	if not game.session.is_authority() or not game.players.has(id) or not attack.get("ok", false): return false
	var body = game.players[id]
	var start: Vector3 = body.global_position + Vector3.UP
	var finish: Vector3 = start - body.global_basis.z * float(attack["range"])
	game.world.ensure_structures(body.position)
	var query := PhysicsRayQueryParameters3D.create(start, finish, 1, [body.get_rid()])
	var hit: Dictionary = game.world.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return false
	var piece = hit["collider"]
	while piece != null and not piece.is_in_group("building_piece"): piece = piece.get_parent()
	if piece == null or piece.hp <= 0 or piece.kind == "raft" or not allowed(game.runtime.key(id), piece.owner_key): return false
	var damage := clampi(int(attack["damage"]), 1, 35)
	var row: Dictionary = piece.get_record()
	row["hp"] = maxi(0, int(row["hp"]) - damage)
	row["revision"] = mini(1000000000, int(row.get("revision", 1)) + 1)
	if row["hp"]==0 and industrial_support(collapse_ids(int(row["id"]))):
		# Until industrial combat exists, do not strand filled machines in mid-air.
		row["hp"]=1
		game.session.notify(id,"notice",{"key":Catalog.reason("industrial_support")})
	if row["hp"] > 0:
		piece.hp = row["hp"]; piece.record_extra["revision"] = row["revision"]
		game.world.structure_registry.put(row)
		impact(game.world.structure_registry.point(row), row.get("tier", "wood"), false, int(row["id"]))
	else: destroy(row)
	return true

func collapse_ids(root: int) -> Dictionary:
	var registry=game.world.structure_registry
	var removed:Dictionary={root:true}
	if not game.server_rules.get("structural_support",false):return removed
	var children:Dictionary={};var remaining:Dictionary={};var pending:Array=[root]
	for uid in registry.records:
		var parents:Array=registry.records[uid].get("supports",[]);remaining[uid]=parents.size()
		for parent in parents:
			if not children.has(int(parent)):children[int(parent)]=[]
			children[int(parent)].append(uid)
	while not pending.is_empty():
		var parent:int=pending.pop_back()
		for child in children.get(parent,[]):
			remaining[child]-=1
			if remaining[child]==0 and not removed.has(child):removed[child]=true;pending.append(child)
	return removed

func industrial_support(removed: Dictionary) -> bool:
	var registry=game.world.structure_registry
	for uid in removed:
		var at:Vector3=registry.point(registry.records[uid])
		var points:Array=[]
		for station in game.runtime.workshops:
			if not station.retired():points.append(station.position)
		for device in game.runtime.grid.nodes.values():points.append(Vector3(device["position"][0],device["position"][1],device["position"][2]))
		for point in points:
			if Vector2(point.x-at.x,point.z-at.z).length()<2.2 and point.y>at.y+.1 and point.y<at.y+4:return true
	return false

func destroy(root: Dictionary) -> void:
	game.world._sync_structure_records()
	var registry = game.world.structure_registry
	var removed:Dictionary=collapse_ids(int(root["id"]))
	# Detach surviving alternate supports before removing any parent.
	for uid in registry.records.keys():
		if removed.has(uid): continue
		var row: Dictionary = registry.records[uid].duplicate(true)
		if not row.get("supports",[]).any(func(parent):return removed.has(int(parent))):continue
		row["supports"] = row.get("supports", []).filter(func(parent): return not removed.has(int(parent)))
		row["revision"] = mini(1000000000, int(row.get("revision", 1)) + 1)
		registry.put(row)
		var piece = game.world.get_structure(uid)
		if piece != null: piece.record_extra["supports"] = row["supports"]; piece.record_extra["revision"] = row["revision"]
	for uid in removed:
		var row: Dictionary = registry.records[uid].duplicate(true)
		var at: Vector3 = registry.point(row)
		impact(at, row.get("tier", "wood"), true, uid)
		if row["kind"] == "chest" and row.get("storage", {}).values().any(func(count): return int(count) > 0):
			# Loot remains a single canonical container: no pickup-capacity loss.
			row["hp"] = 0; row["supports"] = []; row["paid_cost"] = {}; row["locked"] = false; row["open"] = true
			row["position"][1] = game.world.terrain_height(at.x, at.z) + .05
			row["revision"] = mini(1000000000, int(row.get("revision", 1)) + 1)
			game.world.replace_structure(row)
		else:
			game.runtime.farming.erase(str(uid))
			game.world.remove_structure(uid)
	for peer in game.players:
		game.players[peer].respawn_position = game.world.bed_spawn(game.runtime.key(peer))

func impact(at: Vector3, tier: String, destroyed: bool, uid: int) -> void:
	for id in game.players:
		if game.players[id].position.distance_to(at) < 96:
			game.session.notify(id, "building_impact", {"position":[at.x,at.y,at.z], "tier":tier, "destroyed":destroyed, "id":uid})
