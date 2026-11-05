extends SceneTree
const Catalog = preload("res://Building/Catalog.gd")
const Registry = preload("res://Building/Registry.gd")
const Geometry = preload("res://Building/Geometry.gd")
const Store = preload("res://Persistence/Store.gd")
const Session = preload("res://Networking/Session.gd")
var checks:=0
var failed:=0
var game
func check(value: bool, message: String) -> void:
	checks+=1
	if not value: failed+=1; push_error(message)
func _initialize() -> void: call_deferred("run")
func row(id: int, x: float, z: float) -> Dictionary:
	return {"id":id,"kind":"wall","position":[x,2.0,z],"rotation":0,"hp":100,"open":false,"owner":"fixture","revision":1}
func at(x:float,z:float) -> Vector3: return Vector3(x,game.world.terrain_height(x,z),z)
func options(p:Vector3,snap:bool=false) -> Dictionary: return {"position":[p.x,p.y,p.z],"grid":false,"snap":snap,"tier":"wood"}
func latest() -> Dictionary:
	game.world._sync_structure_records(); return game.world.structure_registry.records[game.world.structure_registry.next_id-1].duplicate(true)
func edit(record:Dictionary,op:String,fields:Dictionary={}) -> bool:
	var data:Dictionary={"id":record["id"],"revision":record.get("revision",1),"op":op}; data.merge(fields)
	if op=="demolish":
		game.world._sync_structure_records()
		var ids:Array=[int(record["id"])]+(game.world.structure_registry.dependants(int(record["id"])) if fields.get("cascade",false) else [])
		data["expected"]=ids.map(func(uid):return [uid,int(game.world.structure_registry.records.get(uid,{}).get("revision",record.get("revision",1)))])

	return game.runtime.building.edit(1,data)
func run() -> void:
	check(Catalog.ids().size()==39 and Catalog.tiers().size()==6,"39 stable pieces / six materials")
	for kind in Catalog.ids():
		check(not Catalog.title(kind).is_empty(),"Localized piece "+kind)
		for tier in Catalog.piece(kind).get("tiers",Catalog.tiers()):
			check(not Catalog.cost(kind,tier).is_empty(),"Obtainable cost "+kind+"/"+tier)
	for kind in ["foundation_triangle","ramp","roof_slope"]:
		for mirror in [false,true]:
			var mesh:=Geometry.prism_mesh(kind,mirror); var a:=mesh.surface_get_arrays(0)
			var vertices:PackedVector3Array=a[Mesh.ARRAY_VERTEX]; var normals:PackedVector3Array=a[Mesh.ARRAY_NORMAL]
			var outward:=true
			for i in range(0,vertices.size(),3):
				if (vertices[i+1]-vertices[i]).cross(vertices[i+2]-vertices[i]).dot(normals[i])>=0: outward=false
			check(outward,"Clockwise visible faces and outward normals "+kind+str(mirror))
	var registry:=Registry.new()
	for i in range(3000): registry.put(row(i+1,(i%100)*8-400,floori(i/100.0)*16-240))
	check(registry.records.size()==3000 and registry.chunks.size()>300,"3000 structures indexed across chunks")
	check(registry.nearby(Vector3.ZERO,40).size()<100,"Spatial lookup limits active region")
	var saved: Array=registry.all_records(); var next:int=registry.next_id
	registry.erase(3000); registry.put(row(registry.next_id,0,0)); check(registry.records.has(3001),"Deleted IDs are never recycled")
	registry.load_records(saved,next); check(registry.all_records()==saved,"Exact chunk-record reload")
	check(Session.valid_command("build",{"piece":"foundation_triangle","rotation":1,"options":{"tier":"stone","mirror":true,"height":.25}}),"Expanded network build accepted")
	check(not Session.valid_command("build",{"piece":"wall","rotation":0,"options":{"height":NAN}}),"NaN build height refused")
	check(not Session.valid_command("build",{"piece":"wall","rotation":0,"options":{"cost":{}}}),"Client cannot supply construction cost")
	check(not Session.valid_command("structure_edit",{"id":1,"revision":1,"op":"demolish","confirm":false,"cascade":true}),"Demolition requires explicit confirmation")
	game=load("res://Scenes/Main.tscn").instantiate(); game.save_folder="user://phase4/%d"%Time.get_ticks_usec(); root.add_child(game)
	while not game.ready_world: await process_frame
	game.new_game(718991); game.set_process(false); game.set_physics_process(false); game.player.set_physics_process(false)
	game.runtime.command(1,"appearance",preload("res://Character/Appearance.gd").DEFAULT.duplicate(true))
	game.world.restore_buildings([])
	for tree in game.world.trees.duplicate(): game.world.remove_child(tree); tree.queue_free()
	game.world.trees.clear(); game.world._tree_nodes.clear()
	game.world.set_process(false); game.player.position=at(0,0)+Vector3.UP*.2; game.player.rotation.y=0
	for item in ["wood","stone","fiber","plank","nail","iron_ingot","concrete","brick"]: game.inventory.add(item,100)
	await physics_frame; await physics_frame
	var before:Dictionary=game.inventory.serialize()
	check(not game.runtime.building.build(1,"modular_chair",0,options(game.player.position)),"Server prevents placing inside a character")
	check(game.inventory.serialize()==before,"Rejected placement costs nothing")
	var pending_id:int=game.world.structure_registry.next_id
	var pending:Dictionary=row(pending_id,0,-4); var pending_at:=at(0,-4); pending["position"]=[pending_at.x,pending_at.y,pending_at.z]
	game.world.structure_registry.put(pending)
	check(game.world.get_structure(pending_id)==null,"Fixture structure exists canonically before its mesh is installed")
	var overlapped:bool=game.runtime.building.build(1,"wall",0,options(pending_at))
	check(not overlapped,"Unloaded canonical structure still prevents overlapping construction")
	if overlapped: game.world.remove_structure(game.world.structure_registry.next_id-1)
	game.world.remove_structure(pending_id); await physics_frame; await physics_frame
	game.server_rules["structural_support"]=true
	check(not game.runtime.building.preview(1,"roof",0,options(at(0,-4)))["valid"] or game.runtime.building.preview(1,"roof",0,options(at(0,-4)))["supports"].is_empty(),"Unsnapped roof has no forged parent")
	check(not game.runtime.building.build(1,"roof",0,options(at(0,-4))),"Strict mode refuses suspended roof")
	check(game.runtime.building.build(1,"foundation",0,options(at(0,-4))),"Build real paid foundation")
	var foundation:=latest(); await physics_frame; await physics_frame
	var wall_options:=options(at(0,-6),true)
	var site:Dictionary=game.runtime.building.preview(1,"wall",0,wall_options)
	check(site["valid"] and int(foundation["id"]) in site["supports"],"Context snap connects wall to foundation")
	check(game.runtime.building.build(1,"wall",0,wall_options),"Build wall at socket")
	var wall:=latest(); await physics_frame; await physics_frame
	check(game.runtime.building.build(1,"roof",0,options(at(0,-4),true)),"Wall supports a real roof in strict mode")
	var roof:=latest(); await physics_frame; await physics_frame
	check(wall["id"] in roof.get("supports",[]),"Roof stores persistent wall dependency")
	var upper_options:Dictionary={"height":3.25,"snap":true,"grid":false}
	var upper:Dictionary=game.runtime.building.preview(1,"floor",0,upper_options)
	check(absf(upper["position"].y-float(wall["position"][1])-3.2)<.01,"Snapping to upper floor does not apply the height offset twice")
	var registry_live=game.world.structure_registry
	check(registry_live.dependants(foundation["id"]).size()==2,"Transitive dependencies are predictable")
	check(not edit(foundation,"move",{"rotation":0,"options":options(at(4,-4))}),"Moving a supporting foundation is refused")
	check(not edit(foundation,"demolish",{"confirm":true,"cascade":false}),"Single demolition cannot silently remove dependants")
	var quote:Dictionary={"id":foundation["id"],"revision":1,"op":"demolish","confirm":true,"cascade":true,"expected":[[foundation["id"],1],[wall["id"],1],[roof["id"],1]]}
	check(edit(wall,"configure",{"name":"Changed after quote","paint":0,"locked":true,"allow_allies":false}),"Another edit can change a dependent while demolition dialog is open")
	check(not game.runtime.building.edit(1,quote) and game.runtime.building.last_error=="stale","Demolition refuses changed dependency versions instead of destroying an unapproved set")
	check(game.runtime.building.build(1,"modular_chair",0,options(at(-4,-1))),"Decoration supports free placement")
	var chair:=latest(); var chair_id:int=chair["id"]; var count_before:int=game.inventory.count("wood")
	await physics_frame; await physics_frame
	check(edit(chair,"move",{"rotation":1,"options":options(at(-4,3))}),"Relocation validates new site without giving a free kit")
	chair=registry_live.records[chair_id].duplicate(true)
	check(chair["id"]==chair_id and chair["rotation"]==1 and game.inventory.count("wood")==count_before,"Move retains ID and paid inventory exactly")
	check(not edit(chair.duplicate(true),"move",{"rotation":0,"options":options(at(700,700))}),"Relocation cannot teleport beyond reach")
	check(edit(chair,"configure",{"name":"Banco do rio","paint":2,"locked":true,"allow_allies":false}),"Name and appearance have an authoritative operation")
	check(not edit(chair,"configure",{"name":"stale","paint":0,"locked":false,"allow_allies":true}),"Concurrent stale edit is rejected")
	await physics_frame; await physics_frame
	chair=registry_live.records[chair_id].duplicate(true)
	check(edit(chair,"upgrade",{"tier":"stone"}),"Upgrade consumes a coherent higher-tier cost")
	chair=registry_live.records[chair_id].duplicate(true)
	check(chair["tier"]=="stone" and chair["hp"]==400,"Tier changes actual resistance")
	await physics_frame; await physics_frame
	var node=game.world.get_structure(chair_id); node.hp=200
	chair=node.get_record(); check(edit(chair,"repair"),"Repair consumes resources and restores health")
	check(registry_live.records[chair_id]["hp"]==300,"Repair restores exactly one quarter of tier maximum")
	check(game.runtime.building.build(1,"chest",0,options(at(4,1))),"Build a real storage piece")
	var chest:=latest(); var chest_node=game.world.get_structure(chest["id"]); chest_node.storage={"wood":3}
	await physics_frame; await physics_frame
	check(not edit(chest,"move",{"rotation":0,"options":options(at(4,4))}) and game.runtime.building.last_error=="contents","Chest contents prevent relocation")
	check(not edit(chest,"demolish",{"confirm":true,"cascade":false}),"Chest contents prevent demolition loss")
	chest_node.storage.clear()
	var snapshot:Dictionary=game.snapshot()
	check(Store.valid(snapshot),"Extended save schema accepts real world")
	var bad:=snapshot.duplicate(true); bad["structures"][0]["supports"]=[bad["structures"][0]["id"]]
	check(not Store.valid(bad),"Self dependency cannot enter save")
	bad=snapshot.duplicate(true); bad["structure_next_id"]=1; check(not Store.valid(bad),"Stale ID counter cannot recycle IDs after restart")
	check(game.save_game(),"Save modular base to disk")
	var loaded:=Store.load_world(game.save_folder)
	game.world.restore(loaded)
	check(game.world.building_records()==snapshot["structures"],"Reload preserves IDs, material, paint, names, supports and content")
	await physics_frame; await physics_frame
	check(edit(foundation,"demolish",{"confirm":true,"cascade":true}),"Confirmed dependency demolition succeeds atomically")
	check(not registry_live.records.has(foundation["id"]) and not registry_live.records.has(wall["id"]) and not registry_live.records.has(roof["id"]),"Cascade removes exactly the foundation, wall and roof")
	var refund_count:int=game.inventory.count("wood")
	check(not edit(foundation,"demolish",{"confirm":true,"cascade":true}) and game.inventory.count("wood")==refund_count,"Demolition replay cannot refund twice")
	await physics_frame; await physics_frame
	game.inventory.add("wall_kit",1)
	check(game.runtime.building.build(1,"wall",0,options(at(0,-6))),"A crafted wall kit remains usable in the modular system")
	var kit_wall:=latest(); await physics_frame; await physics_frame
	check(kit_wall.get("paid_cost",{}).get("plank",0)==4,"Kit records its actual recipe inputs as salvage basis")
	var planks:int=game.inventory.count("plank")
	check(edit(kit_wall,"demolish",{"confirm":true,"cascade":false}) and game.inventory.count("plank")==planks+2,"Kit construction refunds half its ingredients, not zero or a free whole kit")
	await physics_frame; await physics_frame
	game.inventory.restore({"axe":1,"limestone":2,"clay":1,"sand":5,"gravel":4,"water":2,"iron_ingot":2})
	game.runtime._add_workshop("furnace",at(2,2),game.runtime.key(1))
	game.runtime._add_workshop("concrete_mixer",at(-2,2),game.runtime.key(1))
	await physics_frame; await physics_frame
	check(game.runtime._enqueue_craft(1,"cement"),"Limestone/clay/sand reserve once at a real furnace")
	game.runtime._tick_activities(3.1)
	check(game.inventory.count("cement")==2 and game.inventory.count("limestone")==0 and game.inventory.count("sand")==4,"Furnace finishes two cement with exact input costs")
	for i in range(2):
		check(game.runtime._enqueue_craft(1,"concrete"),"Cement/water/sand/aggregate enter the real mixer")
		game.runtime._tick_activities(3.1)
	check(game.inventory.count("concrete")==4 and game.inventory.count("gravel")==0 and game.inventory.count("water")==0 and game.inventory.count("water_container")==2,"Mixer conserves concrete ingredients and returns empty containers")
	game.server_rules["structural_support"]=false
	var concrete_options:=options(at(0,-4)); concrete_options["tier"]="concrete"
	check(game.runtime.building.build(1,"wall",0,concrete_options),"Processed concrete and iron build reinforced wall")
	check(latest()["hp"]==1000 and game.inventory.count("concrete")==0 and game.inventory.count("iron_ingot")==0,"Reinforced construction has real cost and resistance")
	var inv_before:Dictionary=game.inventory.serialize(); var full:Dictionary=inv_before.duplicate(true)
	full["equipment"]={"hand":"","offhand":"","armor":""}
	for i in range(36): full["slots"][i]={"id":"stone","count":99}
	game.inventory.restore(full)
	chest=game.world.get_structure(chest["id"]).get_record()
	var full_before:Dictionary=game.inventory.serialize()
	check(not edit(chest,"demolish",{"confirm":true,"cascade":false}) and game.runtime.building.last_error=="capacity","Full backpack blocks demolition before removing the piece")
	check(game.world.structure_registry.records.has(chest["id"]) and game.inventory.serialize()==full_before,"Failed refund leaves both structure and inventory intact")
	game.inventory.restore(inv_before)
	var station=game.runtime.workshops[0]
	station.machine["input"]={"limestone":1}
	var relocate:Dictionary={"station":0,"revision":1,"rotation":1,"options":options(at(2,-1))}
	check(not game.runtime.building.move_station(1,relocate),"Station must be emptied before relocation")
	station.machine["input"].clear()
	var inventory_before:Dictionary=game.inventory.serialize()
	check(game.runtime.building.move_station(1,relocate),"Empty disconnected station relocates through authority")
	check(station.position.distance_to(at(2,-1))<.01 and station.building["revision"]==2 and game.inventory.serialize()==inventory_before,"Station keeps index, inventory and real orientation")
	check(not game.runtime.building.move_station(1,relocate),"Stale station relocation is rejected")
	game.runtime.grid.motors=[0]
	check(not game.runtime.building.station_move_reason(1,0).is_empty(),"Installed industrial motor blocks unsafe relocation")
	game.runtime.grid.motors=[]
	check(game.save_game(),"Save relocated industrial station")
	var station_save:=Store.load_world(game.save_folder)
	game.runtime.restore(station_save)
	check(game.runtime.workshops[0].building["rotation"]==1 and game.runtime.workshops[0].building["revision"]==2,"Station orientation/revision survive disk reload")
	var garden=game.world.add_structure("garden",at(100,100),0,game.runtime.key(1)); var garden_id:int=garden.structure_id
	game.runtime.farming[str(garden_id)]={"crop":"berries","growth":.25,"water":.5,"planted_at":Time.get_unix_time_from_system()}
	game.world._stream_structures([Vector3.ZERO]); game.runtime._tick_farming(1)
	check(game.runtime.farming.has(str(garden_id)),"Unloading a garden must not erase its crop")
	if game.runtime.farming.has(str(garden_id)): check(float(game.runtime.farming[str(garden_id)]["growth"])>.25,"Unloaded crop continues server-side growth")
	game.world._stream_structures([at(100,100)]); game.world._install_structures(8)
	garden=game.world.get_structure(garden_id)
	check(garden!=null and garden.crop=="berries","Reloaded garden restores visible crop state")
	game.runtime.farming.clear()
	var all_rows:Array=[]
	for i in range(3000): all_rows.append(row(1000+i,(i%100)*8-400,floori(i/100.0)*16-240))
	game.world.restore_buildings(all_rows,4000)
	check(game.world.building_records().size()==3000 and game.world.structures.size()<100,"3000 records load with bounded initial mesh/collider installation")
	game.world._stream_structures([Vector3(300,2,200)]); game.world._install_structures(8)
	check(game.world.building_records().size()==3000,"Changing active chunks never deletes canonical structures")
	check(game.world.building_records(Vector3.ZERO).size()==game.world.structure_registry.nearby(Vector3.ZERO,96).size() and game.world.building_records(Vector3.ZERO).size()<300,"Network sends nearby structures rather than the whole continent")
	check(Store.valid(game.snapshot()),"Thousands of structures remain within validated snapshot bounds")
	check(game.save_game(),"Write 3000 structures to real alternating snapshots")
	var bulk:=Store.load_world(game.save_folder)
	check(bulk.get("structures",[]).size()==3000,"Read all 3000 structures from disk")
	var bulk_expected:Array=game.world.building_records()
	game.world.restore(bulk)
	check(game.world.building_records()==bulk_expected and game.world.structure_registry.next_id==4000,"Disk reload preserves all chunk records and next persistent ID")
	print("PHASE4 CHECKS=%d FAILED=%d"%[checks,failed])
	await game.quit_game(0 if failed==0 else 1,false)
