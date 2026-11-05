extends SceneTree
const Store = preload("res://Persistence/Store.gd")
const Session = preload("res://Networking/Session.gd")
var game
var checks := 0
var failed := 0
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failed += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func data(index: int, op: String) -> Dictionary:
	return {"station":index,"revision":int(game.runtime.workshops[index].building.get("revision",1)),"op":op,"confirm":true}
func run() -> void:
	check(Session.valid_command("industry_edit",{"station":0,"revision":1,"op":"demolish","confirm":true,"request_id":"one"}),"Confirmed industrial command accepted")
	check(not Session.valid_command("industry_edit",{"station":0,"revision":1,"op":"demolish","confirm":false}),"Unconfirmed demolition rejected")
	check(not Session.valid_command("industry_edit",{"station":0,"revision":1,"op":"refund","confirm":true}),"Client cannot choose refund")
	game=load("res://Scenes/Main.tscn").instantiate();game.save_folder="user://industry-lifecycle/%d"%Time.get_ticks_usec();root.add_child(game)
	while not game.ready_world: await process_frame
	game.new_game(718991);game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false)
	game.runtime.command(1,"appearance",preload("res://Character/Appearance.gd").DEFAULT.duplicate(true))
	game.world.restore_buildings([])
	for tree in game.world.trees: tree.set_felled(true,true)
	var at:=Vector3(0,game.world.terrain_height(0,0),0)
	game.player.position=at+Vector3.UP*.2
	var owner:String=game.runtime.key(1)
	game.runtime._add_workshop("sawmill",at+Vector3(0,0,-3),owner)
	game.runtime._add_workshop("carpenter",at+Vector3(4,0,-3),owner)
	var machine=game.runtime.workshops[0];var survivor=game.runtime.workshops[1]
	machine.building["paid_cost"]={"plank":8,"stone":3}
	game.inventory.add("motor",1)
	await physics_frame;await physics_frame
	game.runtime.command(1,"energy_install",{"station":0,"request_id":"install-once"})
	check(0 in game.runtime.grid.motors and game.inventory.count("motor")==0,"Install consumes a real motor")
	var remove:=data(0,"remove_motor");var demolition:=data(0,"demolish")
	check(not game.runtime.industry.edit(1,demolition),"Demolition refuses installed motor")
	game.runtime.grid.links=[{"a":"w0","b":"n1","owner":owner,"wire":1}]
	check(not game.runtime.industry.edit(1,remove) and game.inventory.count("motor")==0,"Connected motor cannot be removed or refunded")
	game.runtime.grid.links.clear()
	game.runtime.automation.routes=[{"from":0,"to":1,"item":"plank","owner":owner,"elapsed":0.0}]
	check(not game.runtime.industry.edit(1,remove),"Active conveyor must be disconnected first")
	game.runtime.automation.routes.clear()
	var full:=preload("res://Core/Inventory.gd").new()
	var slots:Array=[]
	for i in range(36):slots.append({"id":"axe","count":1})
	full.restore({"slots":slots,"equipment":{"hand":"axe","offhand":"","armor":""},"durability":{"axe":100}})
	var original=game.inventories[1];game.inventories[1]=full
	check(not game.runtime.industry.edit(1,remove) and 0 in game.runtime.grid.motors,"Full inventory leaves installed motor intact")
	game.inventories[1]=original
	remove["request_id"]="motor-return-once";game.runtime.command(1,"industry_edit",remove);game.runtime.command(1,"industry_edit",remove)
	check(not 0 in game.runtime.grid.motors and game.inventory.count("motor")==1,"Replayed removal returns exactly one motor")
	check(not game.runtime.industry.edit(1,demolition),"Old demolition revision cannot execute after motor change")
	demolition=data(0,"demolish")
	machine.machine["input"]={"log":2}
	check(not game.runtime.industry.edit(1,demolition) and machine.machine["input"]["log"]==2,"Input content preserved on refused demolition")
	machine.machine["input"].clear();machine.machine["output"]={"plank":2}
	check(not game.runtime.industry.edit(1,demolition),"Output must be collected first")
	machine.machine["output"].clear();machine.machine["progress"]=.1
	check(not game.runtime.industry.edit(1,demolition),"Unfinished work prevents silent progress loss")
	machine.machine["progress"]=0
	var old_owner:String=machine.owner_key;machine.owner_key="other"
	check(not game.runtime.industry.edit(1,demolition),"Stranger cannot demolish another machine")
	machine.owner_key=old_owner
	var original_position:Vector3=game.player.position;game.player.position+=Vector3(30,0,0)
	check(not game.runtime.industry.edit(1,demolition),"Server rejects demolition out of reach")
	game.player.position=original_position
	game.inventories[1]=full
	check(not game.runtime.industry.edit(1,demolition) and not machine.retired(),"Full inventory prevents industrial demolition atomically")
	game.inventories[1]=original
	var before:int=game.inventory.count("plank");var stone:int=game.inventory.count("stone")
	demolition["request_id"]="demolition-once"
	game.runtime.command(1,"industry_edit",demolition);game.runtime.command(1,"industry_edit",demolition)
	check(machine.retired() and machine.collision_layer==0 and machine.get_child_count()==0,"Demolished workshop has no collider, model or production")
	check(game.inventory.count("plank")==before+4 and game.inventory.count("stone")==stone+1,"Refund is exactly 50 percent rounded down and delivered once")
	check(game.runtime.workshops.size()==2 and game.runtime.workshops[1]==survivor,"Removing slot zero never reindexes another machine")
	check(not game.runtime._station_accessible(1,machine) and not game.runtime._factory_command(1,"factory_load",0),"Old station command cannot act on retired slot")
	game.runtime._add_workshop("workbench",at+Vector3(-3,0,-3),owner)
	check(game.runtime.workshops.size()==3 and game.runtime.workshops[0].retired(),"New machine receives a fresh slot instead of recycling old target")
	var grid=game.runtime.grid
	var device:String=grid.add("power_pole",Vector3(0,game.world.terrain_height(0,-5),-5),owner)
	grid.nodes[device]["paid_cost"]={"wood":6,"wire":3};grid.nodes[device]["revision"]=1
	game.runtime.energy_visuals.rebuild();await physics_frame;await physics_frame
	var move:Dictionary={"id":device,"revision":1,"op":"move","confirm":true,"request_id":"device-move"}
	var site:Dictionary=game.runtime.industry.preview_device(1,device)
	check(site["valid"],"Device relocation preview checks actual physics and terrain")
	var initial:Dictionary=game.inventory.serialize()
	game.runtime.command(1,"device_edit",move);game.runtime.command(1,"device_edit",move)
	check(int(grid.nodes[device]["revision"])==2 and game.inventory.serialize()==initial,"Device moves with same ID, no cost or free kit, replay ignored")
	await physics_frame;await physics_frame
	var remove_device:Dictionary={"id":device,"revision":2,"op":"demolish","confirm":true,"request_id":"device-remove"}
	check(not game.runtime.industry.edit_device(1,{"id":device,"revision":1,"op":"demolish","confirm":true}),"Old electrical revision refused")
	grid.links=[{"a":device,"b":"w1","owner":owner,"wire":1}]
	check(not game.runtime.industry.edit_device(1,remove_device),"Live cable blocks device removal")
	grid.links.clear();game.inventories[1]=full
	check(not game.runtime.industry.edit_device(1,remove_device) and grid.nodes.has(device),"Full inventory preserves device on failed refund")
	game.inventories[1]=original
	var wood:int=game.inventory.count("wood");var wire:int=game.inventory.count("wire")
	game.runtime.command(1,"device_edit",remove_device);game.runtime.command(1,"device_edit",remove_device)
	check(not grid.nodes.has(device) and game.inventory.count("wood")==wood+3 and game.inventory.count("wire")==wire+1,"Electrical demolition refunds exact half once and removes device")
	var replacement:String=grid.add("power_pole",Vector3(4,game.world.terrain_height(4,0),0),owner)
	check(replacement!=device,"Deleted electrical IDs are never recycled")
	var snapshot:Dictionary=game.snapshot()
	check(Store.valid(snapshot),"Retired station and paid-cost extension pass full save schema")
	check(Store.save_world(snapshot,game.save_folder)=="","Real disk save succeeds")
	var saved:=Store.load_world(game.save_folder)
	game.runtime.restore(saved)
	check(game.runtime.workshops[0].retired() and game.runtime.workshops[0].get_child_count()==0 and game.runtime.workshops[1].kind=="carpenter","Reload retains retirement, other IDs and no invisible active collider")
	var invalid:Dictionary=saved.duplicate(true);invalid["energy_grid"]["motors"]=[0]
	check(not Store.valid(invalid),"Schema rejects motor pointing at removed machine")
	invalid=saved.duplicate(true);invalid["automation"]=[{"from":0,"to":1,"item":"plank","owner":owner,"elapsed":0.0}]
	check(not Store.valid(invalid),"Schema rejects conveyor pointing at removed machine")
	invalid=saved.duplicate(true);invalid["workshops"][0]["machine"]["output"]={"plank":1}
	check(not Store.valid(invalid),"Schema rejects hidden content inside retired slot")
	print("INDUSTRY_LIFECYCLE CHECKS=%d FAILED=%d"%[checks,failed])
	await game.quit_game(0 if failed==0 else 1,false)
