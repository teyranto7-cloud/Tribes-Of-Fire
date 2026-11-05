extends SceneTree
const Catalog = preload("res://Items/Catalog.gd")
const Session = preload("res://Networking/Session.gd")
const Factory = preload("res://Building/Factory.gd")
var game
var checks := 0
var failed := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failed += 1; push_error(message)
func send(action: String, data: Dictionary) -> void:
	check(Session.valid_command(action,data),"Protocol accepts identified " + action)
	game.runtime.command(1,action,data)
func run() -> void:
	game=load("res://Scenes/Main.tscn").instantiate();game.save_folder="user://station-transactions/%d"%Time.get_ticks_usec();root.add_child(game)
	while not game.ready_world:await process_frame
	game.new_game(718991);game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false)
	game.runtime.command(1,"appearance",preload("res://Character/Appearance.gd").DEFAULT.duplicate(true))
	game.runtime._add_workshop("workbench",Vector3(0,game.world.terrain_height(0,4),4),game.runtime.key(1))
	var station=game.runtime.workshops[-1];var index:int=game.runtime.workshops.size()-1
	game.player.position=station.position+Vector3(0,0.2,2)
	game.inventory.add("wood",10)
	station.machine["recipe"]="plank"
	await physics_frame;await physics_frame
	var original:Dictionary=Catalog.RECIPES["plank"].duplicate(true)
	Catalog.RECIPES["plank"]["unlocks"]=["knapping"]
	var before:Dictionary=station.machine.duplicate(true)
	check(not game.runtime._select_station_recipe(1,index,"plank") and station.machine==before,"Station selection honors explicit recipe unlocks")
	check(not game.runtime._factory_command(1,"factory_load",index,1) and game.inventory.count("wood")==10,"Locked loading cannot charge resources")
	game.runtime.progression[1].learned.append("knapping")
	check(game.runtime._select_station_recipe(1,index,"plank"),"Learning required technology enables selection")
	Catalog.RECIPES["plank"]=original
	var load:Dictionary={"station":index,"amount":1,"request_id":"load-once"}
	send("station_load",load);send("station_load",load)
	check(game.inventory.count("wood")==9 and station.machine["input"].get("wood")==1,"Repeated load request charges exactly once")
	check(game.save_game(),"Station receipt and loaded inputs save together")
	game._remove_player(1);game._spawn_player(1);game.player.set_physics_process(false);game.player.position=station.position+Vector3(0,0.2,2)
	send("station_load",load)
	check(game.inventory.count("wood")==9 and station.machine["input"]["wood"]==1,"Load receipt survives player reconnection")
	Factory.advance(station.machine,"workbench",10)
	var take:Dictionary={"station":index,"request_id":"take-once"}
	send("factory_take",take)
	check(game.inventory.count("plank")==2 and station.machine["output"].is_empty(),"First collection takes a complete output batch")
	send("station_load",{"station":index,"amount":1,"request_id":"load-next"});Factory.advance(station.machine,"workbench",10)
	send("factory_take",take)
	check(game.inventory.count("plank")==2 and station.machine["output"].get("plank")==2,"Delayed replay cannot collect a later production batch")
	check(game.save_game(),"Completed receipts and uncollected output persist")
	game.load_game();game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false)
	station=game.runtime.workshops[index];game.player.position=station.position+Vector3(0,0.2,2)
	send("factory_take",take)
	check(game.inventory.count("plank")==2 and station.machine["output"].get("plank")==2,"Collection receipt survives a world reload")
	send("factory_take",{"station":index,"request_id":"take-next"})
	check(game.inventory.count("plank")==4,"A new intentional request collects the next batch")
	send("station_load",{"station":index,"amount":1,"request_id":"same-across-actions"})
	send("station_refund",{"station":index,"request_id":"same-across-actions"})
	check(game.inventory.count("wood")==8 and station.machine["input"].is_empty(),"Receipt namespaces preserve refund after loading")
	send("station_refund",{"station":index,"request_id":"same-across-actions"})
	check(game.inventory.count("wood")==8,"Repeated refund does not duplicate resources")
	check(not Session.valid_command("station_load",{"station":index,"amount":1,"request_id":""}),"Empty request identifier is rejected")
	check(not Session.valid_command("station_load",{"station":index,"amount":1,"request_id":"x".repeat(65)}),"Oversized request identifier is rejected")
	# Old queue records acquire stable IDs once; stale cancellation cannot hit the next job.
	var jobs=preload("res://Crafting/Activities.gd").new()
	var inventory=preload("res://Core/Inventory.gd").new();inventory.add("fiber",10)
	check(jobs.enqueue(1,"rope",inventory,"cancel-a") and jobs.enqueue(1,"rope",inventory,"cancel-b"),"Two paid jobs have distinct identities")
	var first_uid:String=jobs.queue(1)[0]["uid"];var second_uid:String=jobs.queue(1)[1]["uid"]
	check(first_uid!=second_uid,"Queue identities are unique")
	jobs.queue(1).pop_front()
	check(not jobs.cancel(1,0,inventory,first_uid) and jobs.queue(1).size()==1,"Completed-job cancellation cannot refund the next job")
	check(jobs.cancel(1,1,inventory,second_uid) and jobs.queue(1).is_empty(),"Stable identity follows a shifted queue index")
	jobs.enqueue(1,"rope",inventory,"legacy")
	var records:Array=jobs.queue(1).duplicate(true);records[0].erase("uid")
	check(jobs.valid_queue(records),"Pre-audit queue records remain valid")
	jobs.restore(2,records);var migrated:String=jobs.queue(2)[0]["uid"]
	var copy:Array=jobs.queue(2).duplicate(true);jobs.restore(2,copy)
	check(jobs.queue(2)[0]["uid"]==migrated,"Legacy job identity survives later restoration")
	copy.append(copy[0].duplicate(true))
	check(not jobs.valid_queue(copy),"Duplicate persisted job identity is rejected")
	check(Session.valid_command("craft_cancel",{"index":0,"job_uid":migrated,"request_id":"cancel"}),"Cancellation identity passes the protocol")
	# A failed full-inventory collection is retryable with the same request ID.
	var full=preload("res://Core/Inventory.gd").new()
	for item in Catalog.ids():
		if item in ["plank","stick"]:continue
		if full.serialize()["slots"].all(func(row):return not row.is_empty()):break
		full.add(item,1)
	game.inventory=full;game.inventories[1]=full
	station.machine["output"]={"plank":2,"stick":1}
	var pending:Dictionary={"station":index,"request_id":"retry-full"}
	var old_state:Dictionary=full.serialize()
	check(game.runtime.station_reason(1,index,"factory_take")=="Inventory is full","Output preview explains insufficient space")
	send("factory_take",pending)
	check(full.serialize()==old_state and station.machine["output"]=={"plank":2,"stick":1},"Blocked multi-output transfer preserves all buffers")
	var freed:int=0
	for item in full.items:
		if full.count(item)>0 and item!="axe":full.consume(item,full.count(item));freed+=1
		if freed==2:break
	send("factory_take",pending)
	check(full.count("plank")==2 and full.count("stick")==1 and station.machine["output"].is_empty(),"Rejected request can succeed after freeing room")
	# Valid legacy buffers with unrelated material must not grow beyond schema capacity.
	station.machine["input"]={}
	for item in Catalog.ids():
		if item=="wood":continue
		station.machine["input"][item]=1
		if station.machine["input"].size()==8:break
	full.add("wood",2);old_state=full.serialize();before=station.machine.duplicate(true)
	check(not game.runtime._factory_command(1,"factory_load",index,1),"Input capacity cannot create an unsaveable ninth item type")
	check(full.serialize()==old_state and station.machine==before,"Capacity rejection is atomic")
	check(Factory.valid(station.machine,"workbench"),"Rejected load leaves the persisted station valid")
	station.machine["input"].clear()
	# The existing station panel reflects the same validation rules without mutation.
	game.runtime.factory_view={"station":index,"kind":"workbench","state":station.machine.duplicate(true)}
	game.hud.show_panel("factory")
	var panel
	for child in game.hud.column.get_children():
		if child.get_script()==preload("res://UI/StationPanel.gd"):panel=child
	check(panel!=null and panel.action_buttons["factory_take"].disabled,"Empty production disables collection")
	if panel!=null:
		var before_ui:Dictionary=full.serialize();panel._refresh()
		check(full.serialize()==before_ui,"UI capacity previews do not mutate player inventory")
	check(game.save_game(),"Audit fixture persists before loading a prior snapshot")
	game.commands.append({"id":1,"command":"tribe_create","data":{"name":"Obsolete intent"}})
	game.load_game();game.player.set_physics_process(false)
	check(game.commands.is_empty(),"Loading a snapshot discards commands from the preceding state")
	print("STATION_TRANSACTIONS CHECKS=%d FAILED=%d"%[checks,failed]);await game.quit_game(0 if failed==0 else 1,false)
