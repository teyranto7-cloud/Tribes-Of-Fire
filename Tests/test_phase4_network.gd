extends "res://Tests/test_settlement_network.gd"
## Construction scenarios use fixture materials/positions; commands cross real ENet.
const Buildings = preload("res://Building/Catalog.gd")
func point(x:float,z:float) -> Vector3: return Vector3(x,game.world.terrain_height(x,z),z)
func options(at:Vector3,snap:bool=false) -> Dictionary: return {"position":[at.x,at.y,at.z],"grid":false,"snap":snap,"tier":"wood"}
func newest() -> Dictionary:
	game.world._sync_structure_records(); return game.world.structure_registry.records[game.world.structure_registry.next_id-1].duplicate(true)
func edit_data(row:Dictionary,op:String,fields:Dictionary={}) -> Dictionary:
	var data:Dictionary={"id":row["id"],"revision":row.get("revision",1),"op":op,"request_id":"phase4-%d"%Time.get_ticks_usec()}; data.merge(fields)
	if op=="demolish":
		game.world._sync_structure_records()
		var ids:Array=[int(row["id"])]+(game.world.structure_registry.dependants(int(row["id"])) if fields.get("cascade",false) else [])
		data["expected"]=ids.map(func(uid):return [uid,int(game.world.structure_registry.records.get(uid,{}).get("revision",row.get("revision",1)))])
	return data
func client_done(data: Dictionary) -> void:
	await create_timer(.6).timeout
	for item in data["inventory"]: check(game.inventory.count(item)==int(data["inventory"][item]),"Final inventory replicated "+item)
	for expected in data["structures"]:
		var row:Dictionary=game.world.structure_registry.records.get(int(expected["id"]),{})
		check(not row.is_empty(),"Expected structure replicated")
		if row.is_empty(): continue
		for field in ["kind","owner","tier","revision","name","paint"]: check(row.get(field)==expected.get(field),"Shared structure field "+field)
		check(game.world.structure_registry.point(row).distance_to(game.world.structure_registry.point(expected))<.001,"Shared position without ghost state")
	check(game.world.structure_registry.records.size()==data["structures"].size(),"Deleted structure absent from client")
	check(game.runtime.workshops.size()==data["workshops"].size(),"Station count replicated")
	for i in range(data["workshops"].size()):
		var expected:Dictionary=data["workshops"][i]; var station=game.runtime.workshops[i]
		check(station.kind==expected["kind"] and int(station.building.get("rotation",0))==int(expected["building"]["rotation"]) and int(station.building.get("revision",1))==int(expected["building"]["revision"]),"Relocated station orientation/revision replicated")
		var p:Array=expected["position"]; check(station.position.distance_to(Vector3(p[0],p[1],p[2]))<.001,"Relocated station position replicated")
	print("PHASE4_CLIENT_PASS role=",role," checks=",checks," failed=",failed)
	await game.quit_game(0 if failed==0 else 1,false)
func finish(ids:Array) -> void:
	check(game.save_game(),"Modular world persisted by dedicated server")
	if not restoring:
		var proof:=FileAccess.open(game.save_folder.path_join("phase4-proof.json"),FileAccess.WRITE)
		proof.store_string(JSON.stringify({"structures":game.world.building_records(),"next":game.world.structure_registry.next_id,"workshops":game.runtime.save_state()["workshops"]})); proof.close()
	for id in ids:
		var station_view:Array=game.runtime.save_state()["workshops"]
		for station in station_view: station.erase("machine")
		game.session.notify(id,"settlement_done",{"inventory":game.inventories[id].items,"structures":game.world.building_records(game.players[id].position),"workshops":station_view})
	await create_timer(2).timeout
	print("PHASE4_NETWORK CHECKS=%d FAILED=%d"%[checks,failed])
	await game.quit_game(0 if failed==0 else 1,false)
func run() -> void:
	create_timer(160).timeout.connect(func():push_error("Phase 4 network deadline");quit(1))
	game=load("res://Scenes/Main.tscn").instantiate(); root.add_child(game)
	game.session.event_received.connect(event)
	game.session.command_received.connect(func(id,action,_data):
		if id==pending_id and action==pending:received=true)
	while not game.ready_world or not game.running: await process_frame
	if not server:
		while game.player==null or game.player.creation_pending: await process_frame
		var appearance:Dictionary=game.player.appearance.duplicate(true); appearance["name"]=role; game.request_command("appearance",appearance)
		print("PHASE4_CLIENT_READY ",role); return
	game.server_rules["difficulty"]="peaceful"; game.server_rules["structural_support"]=true
	var ids:Dictionary={}
	while ids.size()<(1 if restoring else 3):
		for id in game.players:
			var name:String=game.players[id].appearance["name"]
			if name in ["merchant","buyer","enemy"]: ids[name]=id
		await process_frame
	var a:int=ids["merchant"]
	if restoring:
		var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.save_folder.path_join("phase4-proof.json")))
		var normalized=preload("res://Building/Registry.gd").new(); normalized.load_records(proof["structures"],int(proof["next"]))
		check(game.world.building_records()==normalized.all_records(),"Every record including pre-existing ruins survives restart exactly")
		check(game.runtime.workshops.size()==1 and int(game.runtime.workshops[0].building["rotation"])==1 and int(game.runtime.workshops[0].building["revision"])==2,"Moved workshop survives dedicated restart with stable index")
		var rows:Array=game.world.building_records(game.players[a].position).filter(func(row):return not row.get("paid_cost",{}).is_empty())
		check(rows.size()==3,"Restart preserves the three paid remaining structures")
		check(rows.any(func(row):return row["kind"]=="wall" and row.get("tier")=="stone" and row.get("name")=="Muralha do rio"),"Upgrade and name survive dedicated restart")
		check(game.world.structure_registry.next_id>rows.map(func(row):return int(row["id"])).max()+1,"Deleted highest ID is not recycled by restart")
		await finish([a]); return
	var b:int=ids["buyer"]; var enemy:int=ids["enemy"]
	for id in ids.values(): game.players[id].set_physics_process(false)
	for tree in game.world.trees:
		if tree.position.length()<18: tree.set_felled(true,true)
	var body=game.players[a]; body.position=point(0,0)+Vector3.UP*.2; body.yaw=0; body.rotation.y=0
	game.players[b].position=point(5,0)+Vector3.UP*.2; game.players[enemy].position=point(-6,0)+Vector3.UP*.2
	for id in ids.values():
		for item in ["wood","stone","brick","iron_ingot","fiber"]: game.inventories[id].add(item,40)
	await physics_frame; await physics_frame
	var wood:int=game.inventories[a].count("wood")
	await order(a,"build",{"piece":"foundation","rotation":0,"options":options(point(0,-4)),"request_id":"phase4-foundation"},true)
	var foundation:=newest()
	check(foundation["kind"]=="foundation" and game.inventories[a].count("wood")==wood-6,"Replayed build creates one foundation and charges exactly once")
	await order(a,"tribe_create",{"name":"Brasa modular"}); await order(a,"tribe_invite",{"target":game.runtime.key(b)}); await order(b,"tribe_accept")
	await order(b,"build",{"piece":"wall","rotation":0,"options":options(point(0,-6),true),"request_id":"phase4-shared-wall"},true)
	var wall:=newest(); check(wall["kind"]=="wall" and wall["owner"]==game.runtime.key(b),"Second authorized player builds in the same base")
	var before:Dictionary=game.inventories[enemy].serialize(); var size:int=game.world.structure_registry.records.size()
	await order(enemy,"build",{"piece":"wall","rotation":0,"options":options(point(2,-4),true),"request_id":"phase4-enemy"})
	check(game.world.structure_registry.records.size()==size and game.inventories[enemy].serialize()==before,"Enemy cannot attach to an owned base or lose materials on refusal")
	await order(a,"build",{"piece":"roof","rotation":0,"options":options(point(0,-4),true),"request_id":"phase4-roof"})
	var roof:=newest(); check(roof["kind"]=="roof" and int(wall["id"]) in roof.get("supports",[]),"Roof dependency crosses owners in the authorized tribe")
	await order(a,"structure_edit",edit_data(wall,"configure",{"name":"Muralha do rio","paint":2,"locked":true,"allow_allies":false}),true)
	before=game.inventories[b].serialize()
	await order(b,"structure_edit",edit_data(wall,"upgrade",{"tier":"metal"}),true)
	check(game.inventories[b].serialize()==before and game.world.get_structure(wall["id"]).get_record().get("name")=="Muralha do rio","Stale concurrent modification cannot charge or overwrite")
	wall=game.world.get_structure(wall["id"]).get_record(); var stone:int=game.inventories[a].count("stone")
	await order(a,"structure_edit",edit_data(wall,"upgrade",{"tier":"stone"}),true)
	check(game.inventories[a].count("stone")==stone-6 and game.world.get_structure(wall["id"]).get_record()["tier"]=="stone","Authorized leader upgrades another member's wall once")
	game.players[a].position=point(-4,0)+Vector3.UP*.2
	await order(a,"build",{"piece":"chest","rotation":0,"options":options(point(-4,-2)),"request_id":"phase4-chest"})
	var chest:=newest(); var chest_id:int=chest["id"]; var inv=game.inventories[a]; var slot:=-1
	for i in range(36):
		if inv.serialize()["slots"][i].get("id","")=="wood": slot=i; break
	await order(a,"chest_transfer",{"structure":chest_id,"slot":slot,"amount":3,"to_chest":true})
	check(int(game.world.get_structure(chest_id).storage.get("wood",0))==3,"Real transfer puts content in chest")
	chest=game.world.get_structure(chest_id).get_record()
	await order(a,"structure_edit",edit_data(chest,"move",{"rotation":1,"options":options(point(-4,2))}))
	check(game.world.get_structure(chest_id).position.distance_to(point(-4,-2))<.01,"Filled chest relocation refused without losing contents")
	await order(a,"chest_transfer",{"structure":chest_id,"slot":0,"amount":3,"to_chest":false})
	wood=inv.count("wood"); chest=game.world.get_structure(chest_id).get_record()
	var destination:=point(-4,2); var free:=false
	for entry in [Vector2(-4,2),Vector2(-4,4),Vector2(-6,2),Vector2(-6,4)]:
		var candidate:=point(entry.x,entry.y)
		if game.runtime.building.preview(a,"chest",1,options(candidate),chest_id)["valid"]: destination=candidate; free=true; break
	check(free,"Relocation fixture finds a physically clear reachable destination")
	await order(a,"structure_edit",edit_data(chest,"move",{"rotation":1,"options":options(destination)}),true)
	check(game.world.get_structure(chest_id).position.distance_to(destination)<.01 and inv.count("wood")==wood,"Empty chest relocates under same ID, no free kit or extra cost")
	var old_b:int=b; var identity:String=game.runtime.key(b)
	game.session.notify(b,"settlement_reconnect",{})
	var deadline:=Time.get_ticks_msec()+20000
	while Time.get_ticks_msec()<deadline and (game.players.has(old_b) or game.runtime.peer(identity)==0): await process_frame
	b=game.runtime.peer(identity); ids["buyer"]=b
	check(b>0 and b!=old_b,"Builder reconnects with same identity and a new transport peer")
	if b>0: game.players[b].set_physics_process(false)
	check(game.world.get_structure(wall["id"]).owner_key==identity,"Reconnect preserves structure ownership")
	chest=game.world.get_structure(chest_id).get_record(); wood=inv.count("wood")
	await order(a,"structure_edit",edit_data(chest,"demolish",{"confirm":true,"cascade":false}),true)
	check(not game.world.structure_registry.records.has(chest_id) and inv.count("wood")==wood+4,"Confirmed demolition refunds half once despite replay")
	check(game.world.structure_registry.dependants(foundation["id"]).size()==2,"Remaining foundation/wall/roof support graph stays consistent")
	var site:=point(-6,4)
	for p in [Vector2(-6,4),Vector2(-8,4),Vector2(-6,6)]:
		var candidate:=point(p.x,p.y)
		if game.world.placement(game.players[a],"workbench",0,options(candidate))["valid"]: site=candidate; break
	await order(a,"build",{"piece":"workbench","rotation":0,"options":options(site),"request_id":"phase4-station-build"},true)
	check(game.runtime.workshops.size()==1,"Station build is also protected against replay")
	if game.runtime.workshops.size()==1:
		var target:=point(-6,-2); var found:=false
		for p in [Vector2(-6,-2),Vector2(-8,0),Vector2(-8,-2)]:
			var candidate:=point(p.x,p.y)
			if game.runtime.building.preview_station(a,0,1,options(candidate))["valid"]: target=candidate; found=true; break
		check(found,"Station relocation fixture finds clear destination")
		var inventory:Dictionary=inv.serialize()
		await order(a,"station_move",{"station":0,"revision":1,"rotation":1,"options":options(target),"request_id":"phase4-station-move"},true)
		check(game.runtime.workshops[0].position.distance_to(target)<.01 and int(game.runtime.workshops[0].building["revision"])==2 and inv.serialize()==inventory,"Real network station relocation keeps index and grants no items")
	await finish(ids.values())
