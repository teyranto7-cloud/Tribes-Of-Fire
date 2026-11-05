extends "res://Tests/test_settlement_network.gd"
## Two real clients exercise authority; materials and positions are fixtures.
var impacts := 0
func point(x: float,z: float) -> Vector3:return Vector3(x,game.world.terrain_height(x,z),z)
func event(kind: String,data: Dictionary) -> void:
	if kind=="building_impact":impacts+=1
	super.event(kind,data)
func client_done(data: Dictionary) -> void:
	await create_timer(.6).timeout
	for item in data["inventory"]:check(game.inventory.count(item)==int(data["inventory"][item]),"Authoritative inventory replicated "+item)
	check(game.runtime.workshops.size()==3 and game.runtime.workshops[0].retired(),"Removed workshop ID remains retired on client")
	check(game.runtime.workshops[0].collision_layer==0 and game.runtime.workshops[0].get_child_count()==0,"Removed machine has no invisible model or collision")
	check(game.runtime.workshops[1].kind=="carpenter" and game.runtime.workshops[2].kind=="workbench","Other machine IDs and new slot replicated without reindexing")
	check(game.runtime.grid.motors.is_empty(),"Motor removal replicated")
	check(not game.runtime.grid.nodes.has(data["deleted_device"]),"Deleted power device absent on client")
	check(not game.world.structure_registry.records.has(int(data["destroyed_wall"])),"Destroyed wall absent on client")
	check(not game.world.structure_registry.records.has(int(data["destroyed_roof"])),"Collapsed roof absent on client")
	var wreck=game.world.get_structure(int(data["wreck"]),true)
	check(wreck!=null and wreck.hp==0 and wreck.collision_layer==0,"Persistent wreckage represented without intact chest collider")
	if wreck!=null:check(wreck.storage.get("wood")==3,"Unlocked wreck contents replicated to recipient")
	if not restoring:check(impacts>0,"Reliable structure impact event reached this real client")
	print("LIFECYCLE_CLIENT_PASS role=",role," checks=",checks," failed=",failed)
	await game.quit_game(0 if failed==0 else 1,false)
func finish(ids: Array) -> void:
	check(game.save_game(),"Lifecycle state persisted by dedicated server")
	var proof:Dictionary=game.get_meta("lifecycle_proof",{})
	for id in ids:
		var data:Dictionary=proof.duplicate(true);data["inventory"]=game.inventories[id].items
		game.session.notify(id,"settlement_done",data)
	await create_timer(2).timeout
	print("LIFECYCLE_NETWORK CHECKS=%d FAILED=%d"%[checks,failed]);await game.quit_game(0 if failed==0 else 1,false)
func run() -> void:
	create_timer(150).timeout.connect(func():push_error("Lifecycle network deadline");quit(1))
	game=load("res://Scenes/Main.tscn").instantiate();root.add_child(game);game.session.event_received.connect(event)
	game.session.command_received.connect(func(id,action,_data):
		if id==pending_id and action==pending:received=true)
	while not game.ready_world or not game.running:await process_frame
	if not server:
		while game.player==null or game.player.creation_pending:await process_frame
		var appearance:Dictionary=game.player.appearance.duplicate(true);appearance["name"]=role;game.request_command("appearance",appearance)
		print("LIFECYCLE_CLIENT_READY ",role);return
	game.server_rules["difficulty"]="peaceful";game.server_rules["structural_support"]=true;game.server_rules["pvp"]="on"
	var ids:Dictionary={}
	while ids.size()<(1 if restoring else 2):
		for id in game.players:
			var name:String=game.players[id].appearance["name"]
			if name in ["merchant","buyer"]:ids[name]=id
		await process_frame
	var a:int=ids["merchant"]
	if restoring:
		var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.save_folder.path_join("lifecycle-proof.json")))
		game.set_meta("lifecycle_proof",proof)
		check(game.runtime.workshops.size()==3 and game.runtime.workshops[0].retired(),"Dedicated restart preserves retired IDs")
		check(game.runtime.grid.motors.is_empty() and not game.runtime.grid.nodes.has(proof["deleted_device"]),"Restart does not resurrect refunded motor/device")
		check(not game.world.structure_registry.records.has(int(proof["destroyed_wall"])) and not game.world.structure_registry.records.has(int(proof["destroyed_roof"])) ,"Restart does not resurrect collapsed structures")
		var wreck:Dictionary=game.world.structure_registry.records.get(int(proof["wreck"]),{})
		check(wreck.get("hp")==0 and wreck.get("storage",{}).get("wood")==3,"Restart preserves exact wreck contents")
		await finish([a]);return
	var b:int=ids["buyer"]
	game.world.restore_buildings([])
	for tree in game.world.trees:
		if tree.position.length()<24:tree.set_felled(true,true)
	for id in ids.values():game.players[id].set_physics_process(false)
	var body=game.players[a];body.position=point(0,0)+Vector3.UP*.2;body.yaw=0;body.rotation.y=0
	game.players[b].position=point(6,0)+Vector3.UP*.2
	for item in ["plank","iron_ingot","wood","stone","wire"]:game.inventories[a].add(item,24)
	game.inventories[a].add("motor",1)
	await physics_frame;await physics_frame
	await order(a,"build",{"piece":"sawmill","rotation":0,"options":{"position":[0,point(0,-3).y,-3],"snap":false,"grid":false},"request_id":"lifecycle-build"},true)
	check(game.runtime.workshops.size()==1,"Network builds exactly one paid machine despite replay")
	if game.runtime.workshops.is_empty():await finish(ids.values());return
	var machine=game.runtime.workshops[0]
	game.runtime._add_workshop("carpenter",point(4,-3),game.runtime.key(a))
	await order(a,"energy_install",{"station":0},true)
	check(game.runtime.grid.motors==[0] and game.inventories[a].count("motor")==0,"Network installs one motor")
	var remove:Dictionary={"station":0,"revision":1,"op":"remove_motor","confirm":true,"request_id":"lifecycle-motor"}
	await order(b,"industry_edit",remove)
	check(game.runtime.grid.motors==[0],"Unauthorized real client cannot remove motor")
	await order(a,"industry_edit",remove,true)
	check(game.runtime.grid.motors.is_empty() and game.inventories[a].count("motor")==1,"Network motor refund occurs once")
	machine.machine["output"]={"plank":2}
	var demolish:Dictionary={"station":0,"revision":2,"op":"demolish","confirm":true,"request_id":"lifecycle-demolish"}
	await order(a,"industry_edit",demolish,true)
	check(not machine.retired() and machine.machine["output"].get("plank")==2,"Output-filled machine refuses removal over real network")
	await order(a,"factory_take",{"station":0,"request_id":"lifecycle-take"})
	var planks:int=game.inventories[a].count("plank")
	await order(a,"industry_edit",demolish,true)
	check(machine.retired() and game.inventories[a].count("plank")==planks+4,"Confirmed network demolition refunds recorded cost once")
	check(game.runtime.workshops[1].kind=="carpenter","Other industrial slot remains unchanged")
	await order(a,"factory_load",{"station":0,"request_id":"old-station"})
	check(machine.machine["input"].is_empty(),"Late command cannot reactivate removed machine")
	game.runtime._add_workshop("workbench",point(-4,0),game.runtime.key(a))
	check(game.runtime.workshops.size()==3 and game.runtime.workshops[0].retired(),"New workshop has a fresh persistent slot")
	var device:String=game.runtime.grid.add("power_pole",point(0,-5),game.runtime.key(a))
	game.runtime.grid.nodes[device]["revision"]=1;game.runtime.grid.nodes[device]["paid_cost"]={"wood":6,"wire":3};game.runtime.energy_visuals.rebuild()
	await physics_frame;await physics_frame
	var wood:int=game.inventories[a].count("wood")
	await order(a,"device_edit",{"id":device,"revision":1,"op":"demolish","confirm":true,"request_id":"lifecycle-device"},true)
	check(not game.runtime.grid.nodes.has(device) and game.inventories[a].count("wood")==wood+3,"Electrical demolition travels over ENet and refunds once")
	var support=game.world.add_structure("wall",point(0,-1.7),0,game.runtime.key(b),-1,{"hp":1,"tier":"wood"});var wall_id:int=support.structure_id
	var roof=game.world.add_structure("roof",point(0,-1.7),0,game.runtime.key(b),-1,{"supports":[wall_id]});var roof_id:int=roof.structure_id
	var chest=game.world.add_structure("chest",point(0,-1.7)+Vector3.UP*3.6,0,game.runtime.key(b),-1,{"supports":[wall_id],"storage":{"wood":3},"locked":true});var chest_id:int=chest.structure_id
	await physics_frame;await physics_frame
	body.attack_time=0;body.stamina=100;game.runtime.combat.tick(2)
	await order(a,"combat",{"kind":"light"},true)
	check(not game.world.structure_registry.records.has(wall_id) and not game.world.structure_registry.records.has(roof_id),"Validated network combat destroys wall and unsupported roof")
	chest=game.world.get_structure(chest_id)
	check(chest!=null and chest.hp==0 and chest.storage.get("wood")==3,"Network collapse preserves a lootable persistent wreck")
	var proof:Dictionary={"deleted_device":device,"destroyed_wall":wall_id,"destroyed_roof":roof_id,"wreck":chest_id}
	game.set_meta("lifecycle_proof",proof)
	var file:=FileAccess.open(game.save_folder.path_join("lifecycle-proof.json"),FileAccess.WRITE);file.store_string(JSON.stringify(proof));file.close()
	await finish(ids.values())
