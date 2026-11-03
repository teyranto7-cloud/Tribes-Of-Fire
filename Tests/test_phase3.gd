extends SceneTree
const Catalog=preload("res://Items/Catalog.gd")
const Inventory=preload("res://Core/Inventory.gd")
const Factory=preload("res://Building/Factory.gd")
const Session=preload("res://Networking/Session.gd")
var checks:=0
var failed:=0
var game
var inv
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failed+=1;push_error(message)
func _initialize()->void:call_deferred("run")
func prepare(at:Vector3)->void:
	for z in range(floori(at.z/16)-1,floori(at.z/16)+2):
		for x in range(floori(at.x/16)-1,floori(at.x/16)+2):
			if not game.world._chunks.has(Vector2i(x,z)):game.world.make_chunk(x*16,z*16)
func gather(kind:String,amount:int,tool:String="")->void:
	if not tool.is_empty():
		for i in range(36):
			if inv.serialize()["slots"][i].get("id")==tool:inv.equip(i);break
	var before:int=inv.count(kind)
	for index in range(game.runtime.mining.nodes.size()):
		if game.runtime.mining.resource_kind(index)!=kind:continue
		var node=game.runtime.mining.nodes[index]
		prepare(node.position)
		game.player.position=node.position+Vector3(0,0.2,1.6)
		await physics_frame;await physics_frame
		for attempt in range(40):
			game.runtime.mining._cooldowns.erase(game.player.get_instance_id());game.player.stamina=100
			game.runtime.mining.mine(game.player,inv,index,tool.is_empty())
			if inv.count(kind)>=before+amount:return
			if game.runtime.mining.stocks[index]<=0:break
	check(false,"Could not gather "+kind)
func near_station(kind:String)->void:
	for station in game.runtime.workshops:
		if station.kind==kind:
			game.player.position=station.position+Vector3(0,0.2,2);return
func craft(id:String,request:String="")->void:
	var data:=Catalog.recipe(id)
	if data["station"]!="hand":near_station(data["station"])
	check(game.runtime._enqueue_craft(1,id,request),"Enqueue "+id)
	game.runtime._tick_activities(float(data["time"])+0.1)
	check(game.runtime.activities.queue(1).is_empty(),"Complete "+id)
func place(kind:String)->void:
	var count:int=game.runtime.workshops.size() if Catalog.station_ids().has(kind) else game.world.structures.size()
	for z in [12,24,36,48]:
		for x in [-36,-24,-12,0,12,24,36]:
			game.player.position=Vector3(x,game.world.terrain_height(x,z)+0.2,z);game.player.yaw=0;game.player.rotation.y=0
			prepare(game.player.position)
			await physics_frame;await physics_frame
			var site:Dictionary=game.world.placement(game.player,kind,0)
			if not site["valid"]:continue
			game.runtime.command(1,"build",{"piece":kind,"rotation":0})
			var after:int=game.runtime.workshops.size() if Catalog.station_ids().has(kind) else game.world.structures.size()
			if after>count:check(true,"Placed "+kind);return
	check(false,"Cannot place "+kind)
func run()->void:
	for id in Catalog.ids():
		var row:=Catalog.get_item(id)
		check(row["id"]==id and row["weight"]>=0 and row["stack"]>=1,"Permanent item metadata")
		check(not row["name"].get("pt_BR","").is_empty() and not row["description"].is_empty(),"Localized names and descriptions")
		check(ResourceLoader.exists(row["icon"]) and ResourceLoader.exists(row["pickup_model"]),"Usable icon and world model")
	for id in Catalog.RECIPES:
		var row:=Catalog.recipe(id)
		check(row["time"]>0 and not row["cost"].is_empty() and not row["outputs"].is_empty(),"Complete recipe definition")
		for item in row["cost"]:check(Catalog.known(item) and row["cost"][item]>0,"Known positive recipe input")
		for item in row["outputs"]:check(Catalog.known(item) and row["outputs"][item]>0,"Known positive recipe output")
	var slots:=Inventory.new();slots.add("wood",120)
	check(slots.count("wood")==120 and slots.serialize()["slots"].filter(func(s):return s.get("id")=="wood").size()==2,"Resource stacks obey declared maximum")
	game=load("res://Scenes/Main.tscn").instantiate();root.add_child(game)
	while not game.ready_world:await process_frame
	game.save_folder="user://phase3/%d-%d"%[OS.get_process_id(),Time.get_ticks_usec()]
	game.new_game(718991);game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false);inv=game.inventory
	var empty_state:Dictionary=inv.serialize()
	check(game.runtime.craft_reason(1,"axe").begins_with("Missing materials:") and not game.runtime._enqueue_craft(1,"axe") and inv.serialize()==empty_state,"Missing basic materials cannot debit inventory")
	var ore=game.runtime.mining.nodes[2];prepare(ore.position);game.player.position=ore.position+Vector3(0,0.2,1.5)
	await physics_frame;await physics_frame
	var stock_before:int=game.runtime.mining.stocks[2]
	check(not game.runtime.mining.mine(game.player,inv,2,true) and game.runtime.mining.stocks[2]==stock_before,"Ore rejects collection with the wrong tool")
	await gather("wood",40);await gather("stone",30);await gather("fiber",12);await gather("clay",10)
	var prior:Dictionary=inv.serialize()
	check(not game.runtime._enqueue_craft(1,"steel_sword") and inv.serialize()==prior,"Missing material/unlock cannot charge inventory")
	await craft("axe","initial-axe")
	check(inv.count("axe")==2,"Gathered materials produce an actual axe")
	prior=inv.serialize()
	check(not game.runtime._enqueue_craft(1,"axe","initial-axe") and inv.serialize()==prior,"Double request cannot debit or craft twice")
	await craft("workbench");await place("workbench")
	for i in range(9):await craft("plank")
	for i in range(4):await craft("rope")
	await craft("carpenter");await place("carpenter")
	await craft("wall_kit");await place("wall")
	await craft("chest_kit");await place("chest")
	check(inv.count("wall_kit")==0 and inv.count("chest_kit")==0,"Placed wall and chest consume crafted kits once")
	await craft("pickaxe");await gather("copper_ore",8,"pickaxe")
	await craft("cooking_fire");await place("cooking_fire")
	for i in range(4):await craft("charcoal")
	await craft("furnace");await place("furnace")
	for i in range(4):await craft("copper_ingot_charcoal")
	await craft("anvil");await place("anvil")
	# Anvil uses four ingots; gather and process enough additional metal.
	if inv.count("copper_ingot")<3:
		await gather("copper_ore",6,"pickaxe")
		for i in range(3):await craft("copper_ingot_charcoal")
	await craft("stick");await craft("copper_pickaxe")
	await gather("iron_ore",2,"copper_pickaxe")
	check(inv.count("iron_ore")>=2 and Catalog.harvest_power("copper_pickaxe")>Catalog.harvest_power("pickaxe"),"Second cycle yields a usable superior tool")
	check(game.save_game(),"Both production cycles persist")
	var saved_inventory:Dictionary=inv.serialize();game.load_game();game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false);inv=game.inventory
	check(inv.serialize()==saved_inventory and game.runtime.workshops.size()==5,"Reload preserves cycle results and stations")
	near_station("carpenter");await physics_frame
	check(game.runtime._enqueue_craft(1,"vase")==false,"Station restriction enforced")
	# Paid job and dedup history survive disconnect and a later world reload.
	check(game.runtime._enqueue_craft(1,"rope","resume-job"),"Paid queue created before disconnect")
	game._remove_player(1);game._spawn_player(1);game.player.set_physics_process(false);inv=game.inventory
	check(game.runtime.activities.queue(1).size()==1 and not game.runtime._enqueue_craft(1,"rope","resume-job"),"Disconnect restores escrow and rejects replay")
	check(game.save_game(),"Paid queue saves")
	game.load_game();game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false);inv=game.inventory
	check(game.runtime.activities.queue(1).size()==1,"Paid queue reloads")
	var before:int=inv.count("rope");game.runtime._tick_activities(10);game.runtime._tick_activities(10)
	check(inv.count("rope")==before+1,"Saved job completes exactly once")
	# Full inventory: partial multi-output delivery rolls back, then succeeds once.
	var full:=Inventory.new();full.add("log",1)
	for id in Catalog.ids():
		if id in ["log","plank","stick"]:continue
		if full.serialize()["slots"].all(func(s):return not s.is_empty()):break
		full.add(id,1)
	game.inventory=full;game.inventories[1]=full
	game.runtime._add_workshop("sawmill",Vector3(4,game.world.terrain_height(4,4),4),game.runtime.key(1));near_station("sawmill")
	check(game.runtime._enqueue_craft(1,"sawmill_planks","multi-output"),"Escrow reserves log atomically")
	game.runtime._tick_activities(10)
	check(full.count("plank")==0 and full.count("stick")==0 and game.runtime.activities.queue(1).size()==1,"Full inventory cannot receive partial outputs")
	for id in full.items.keys():
		if id not in ["axe","plank","stick"] and full.count(id)>0:full.consume(id,full.count(id));break
	game.runtime._tick_activities(10);game.runtime._tick_activities(10)
	check(full.count("plank")==6 and full.count("stick")==2 and game.runtime.activities.queue(1).is_empty(),"Freeing space delivers all outputs once")
	# Pickup streaming cannot make a valid world unsaveable.
	var remote:=Vector3(500,-50,500)
	game.runtime._add_drop("stone",1,remote)
	game.runtime._tick_drop_physics()
	var drop=game.runtime.drops[-1]
	check(drop.freeze and drop.position.y>=game.world.terrain_height(500,500),"Unloaded pickups freeze above the sampled floor")
	prepare(drop.position);game.runtime._tick_drop_physics()
	check(not drop.freeze,"Pickup physics resumes when terrain is ready")
	# Cancellation is all-or-nothing when escrow cannot fit.
	var escrow_inventory:=Inventory.new();escrow_inventory.add("wood",2);escrow_inventory.add("stone",3)
	for id in Catalog.ids():
		if id in ["wood","stone"]:continue
		if escrow_inventory.serialize()["slots"].all(func(s):return not s.is_empty()):break
		escrow_inventory.add(id,1)
	var jobs=preload("res://Crafting/Activities.gd").new()
	check(jobs.enqueue(1,"axe",escrow_inventory,"cancel-once"),"Cancellation reserves its inputs")
	var extra:Array=[]
	for id in Catalog.ids():
		if id not in ["wood","stone"] and escrow_inventory.count(id)==0 and extra.size()<2:
			if escrow_inventory.add(id,1):extra.append(id)
	var escrow_before:Dictionary=escrow_inventory.serialize()
	check(not jobs.cancel(1,0,escrow_inventory) and jobs.queue(1).size()==1 and escrow_inventory.serialize()==escrow_before,"Full inventory cannot lose or partially refund escrow")
	for id in extra:escrow_inventory.consume(id,1)
	check(jobs.cancel(1,0,escrow_inventory) and escrow_inventory.count("wood")==2 and escrow_inventory.count("stone")==3,"Cancellation refunds every material once")
	check(not jobs.cancel(1,0,escrow_inventory) and not jobs.enqueue(1,"axe",escrow_inventory,"cancel-once"),"Cancelled request cannot be replayed")
	# Station input/output storage survives independent production and reload.
	var stock:=Inventory.new();stock.add("wood",10);game.inventory=stock;game.inventories[1]=stock
	near_station("workbench");var station_index:=0
	check(game.runtime._select_station_recipe(1,station_index,"plank"),"Select a station recipe")
	var at_station:Vector3=game.player.position;game.player.position.x+=30
	check(not game.runtime._factory_command(1,"factory_load",station_index,1) and stock.count("wood")==10,"Remote station loading cannot debit inputs")
	game.player.position=at_station
	game.session._keys[2]="phase3-other";game._spawn_player(2);game.players[2].set_physics_process(false);game.players[2].position=at_station
	check(not game.runtime._station_accessible(2,game.runtime.workshops[station_index]),"Station inventory enforces ownership")
	game._remove_player(2);game.session._keys.erase(2)
	check(game.runtime._factory_command(1,"factory_load",station_index,1) and stock.count("wood")==9,"Station loading charges inputs once")
	var machine:Dictionary=game.runtime.workshops[station_index].machine
	Factory.advance(machine,"workbench",30)
	check(machine["output"].get("plank")==2 and machine["progress"]==0,"Starved station cannot bank idle time")
	check(game.runtime._factory_command(1,"factory_take",station_index) and not game.runtime._factory_command(1,"factory_take",station_index),"Stored station output is collected once")
	check(game.runtime._factory_command(1,"factory_load",station_index,1),"Refill persisted station")
	check(game.save_game(),"Station input inventory saves")
	game.load_game();game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false)
	check(game.runtime.workshops[station_index].machine["input"].get("wood")==1,"Station inputs and recipe survive reload")
	for kind in Catalog.station_ids():
		check(Session.valid_command("build",{"piece":kind}),"Every station is constructible through protocol")
		var state:=Factory.empty();var default:String=str(Catalog.station(kind).get("default_recipe",""))
		check(not default.is_empty(),"Every station has corresponding recipes")
		state["recipe"]=default;check(Factory.valid(state,kind),"Station inventory persists with selected recipe")
	print("PHASE3 CHECKS=%d FAILED=%d"%[checks,failed]);game.quit_game(0 if failed==0 else 1,false)
