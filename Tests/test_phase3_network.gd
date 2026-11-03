extends SceneTree
const Catalog=preload("res://Items/Catalog.gd")
var game
var actor:int=0
var body
var inv
var failed:=0
var checks:=0
var sequence:=0
var server:bool=false
var restore_mode:bool=false
var observer:bool=false
var finished:bool=false
var port:int=24567
var pending_command:String=""
var received:bool=false
func _initialize()->void:
	var args:=OS.get_cmdline_user_args();server="--server" in args;restore_mode="--phase3-restore" in args;observer="--phase3-observer" in args
	for arg in args:
		if arg.begins_with("--port="):port=int(arg.trim_prefix("--port="))
	call_deferred("start")
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:
		failed+=1;push_error(message)
		if game!=null and server:
			print("DEBUG_INVENTORY ",JSON.stringify(inv.items)," QUEUE ",JSON.stringify(game.runtime.activities.queue(actor)))
			var snapshot:Dictionary=game.snapshot()
			print("REJECTED_COMMANDS ",game.session.rejected_commands)
			print("SNAPSHOT_VALID ",preload("res://Persistence/Store.gd").valid(snapshot))
			for field in ["players","animals","workshops","drops","resource_regrowth","farming","craft_queue"]:
				var copy:Dictionary=snapshot.duplicate(true)
				if field=="players":copy["players"]={}
				else:copy.erase(field)
				print("VALID_WITHOUT ",field,"=",preload("res://Persistence/Store.gd").valid(copy))
		game.quit_game(1,false)
func start()->void:
	create_timer(150).timeout.connect(func():push_error("Phase3 network timeout");quit(1))
	game=load("res://Scenes/Main.tscn").instantiate();root.add_child(game)
	game.session.event_received.connect(event)
	game.session.command_received.connect(func(id,command,_data):
		if id==actor and command==pending_command:received=true)
	while not game.ready_world or not game.running:await process_frame
	if not server:
		while game.player==null or game.player.creation_pending:await process_frame
		print("PHASE3_CLIENT_READY observer=",observer);return
	game.server_rules["difficulty"]="peaceful"
	while game.players.is_empty():await process_frame
	actor=game.players.keys()[0]
	while game.players[actor].creation_pending:await process_frame
	body=game.players[actor];body.set_physics_process(false);inv=game.inventories[actor]
	await create_timer(0.5).timeout
	if restore_mode:await restore_run()
	else:await cycles()
func event(kind:String,data:Dictionary)->void:
	if server:return
	if kind=="phase3_order":
		if data["command"]=="attack":game.session.send_action("attack")
		else:
			game.request_command(data["command"],data["data"])
			if data.get("duplicate",false):game.request_command(data["command"],data["data"])
	elif kind=="phase3_reconnect":call_deferred("reconnect")
	elif kind=="phase3_done":call_deferred("client_done")
func reconnect()->void:
	await game.return_to_menu();await create_timer(0.1).timeout;game.join_game("127.0.0.1",port)
func client_done()->void:
	if finished:return
	finished=true;await create_timer(0.3).timeout
	if observer:
		check(game.runtime.workshops.size()>=5,"Observer sees replicated stations")
	else:check(game.inventory.count("copper_pickaxe")==1,"Client receives its crafted superior tool")
	print("PHASE3_CLIENT_PASS observer=",observer," checks=",checks," failed=",failed)
	game.quit_game(0 if failed==0 else 1,false)
func order(command:String,data:Dictionary={},duplicate:bool=false,advance:bool=true)->void:
	received=false;pending_command=command
	game.session.notify(actor,"phase3_order",{"command":command,"data":data,"duplicate":duplicate})
	var deadline:=Time.get_ticks_msec()+8000
	while not received and Time.get_ticks_msec()<deadline:await process_frame
	check(received,"Client command arrives: "+command)
	await physics_frame;await physics_frame
	await create_timer(0.11).timeout
	pending_command=""
	if advance:game.runtime._tick_activities(30)
func prepare(at:Vector3)->void:
	game.world.update_streaming([at])
	for z in range(floori(at.z/16)-1,floori(at.z/16)+2):
		for x in range(floori(at.x/16)-1,floori(at.x/16)+2):
			if not game.world._chunks.has(Vector2i(x,z)):game.world.make_chunk(x*16,z*16)
func gather(kind:String,amount:int,tool:String="")->void:
	if not tool.is_empty():
		for i in range(36):
			if inv.serialize()["slots"][i].get("id")==tool:await order("equip",{"slot":i});break
	var before:int=inv.count(kind)
	for i in range(game.runtime.mining.nodes.size()):
		if game.runtime.mining.resource_kind(i)!=kind:continue
		var node=game.runtime.mining.nodes[i]
		body.position=node.position+Vector3(0,0.2,0.95);body.rotation.y=0;body.yaw=0;prepare(body.position)
		await physics_frame;await physics_frame;game.runtime.mining._refresh(i)
		for attempt in range(40):
			body.stamina=100;body.attack_time=0;game.runtime.mining._cooldowns.erase(body.get_instance_id())
			await order("interact")
			if inv.count(kind)>=before+amount:return
			if game.runtime.mining.stocks[i]<=0:break
	check(false,"Network collection failed for "+kind)
func near(kind:String)->void:
	for station in game.runtime.workshops:
		if station.kind==kind:body.position=station.position+Vector3(0,0.2,2);prepare(body.position);return
func craft(id:String,duplicate:bool=false)->void:
	var definition:=Catalog.recipe(id)
	if definition["station"]!="hand":near(definition["station"])
	sequence+=1
	var request:="network-%d"%sequence
	var before:Dictionary=inv.items.duplicate()
	await order("craft",{"recipe":id,"request_id":request},duplicate)
	for output in definition["outputs"]:
		var expected:int=int(before.get(output,0))-int(definition["cost"].get(output,0))+int(definition["outputs"][output])
		check(inv.count(output)==expected,"Network craft delivers once: "+id+" reason="+game.runtime.craft_reason(actor,id))
func place(kind:String)->void:
	var previous:int=game.runtime.workshops.size() if Catalog.station_ids().has(kind) else game.world.structures.size()
	for z in [12,24,36,48]:
		for x in [-36,-24,-12,0,12,24,36]:
			body.position=Vector3(x,game.world.terrain_height(x,z)+0.2,z);body.rotation.y=0;body.yaw=0;prepare(body.position)
			await physics_frame;await physics_frame
			if not game.world.placement(body,kind,0)["valid"]:continue
			await order("build",{"piece":kind,"rotation":0})
			var current:int=game.runtime.workshops.size() if Catalog.station_ids().has(kind) else game.world.structures.size()
			if current>previous:check(true,"Network placement "+kind);return
	check(false,"Network cannot place "+kind)
func cycles()->void:
	# Initial stock comes exclusively from real resource nodes through client commands.
	await gather("wood",40);print("NET_GATHER_WOOD_DONE");await gather("stone",30);await gather("fiber",12);await gather("clay",10)
	await craft("axe",true);await craft("workbench");await place("workbench")
	for i in range(9):await craft("plank")
	for i in range(4):await craft("rope")
	await craft("carpenter");await place("carpenter");await craft("wall_kit");await place("wall");await craft("chest_kit");await place("chest")
	await craft("pickaxe");await gather("copper_ore",8,"pickaxe")
	await craft("cooking_fire");await place("cooking_fire");print("NET_BEFORE_CHARCOAL ",JSON.stringify(inv.items))
	for i in range(4):await craft("charcoal")
	await craft("furnace");await place("furnace")
	for i in range(4):await craft("copper_ingot_charcoal")
	await craft("anvil");await place("anvil");await gather("copper_ore",6,"pickaxe")
	for i in range(3):await craft("copper_ingot_charcoal")
	await craft("stick");await craft("copper_pickaxe");await gather("iron_ore",2,"copper_pickaxe")
	check(inv.count("iron_ore")>=2,"Crafted copper tool mines iron over network")
	await order("craft",{"recipe":"rope","request_id":"disconnect-paid"},false,false)
	check(game.runtime.activities.queue(actor).size()==1,"Escrow paid before disconnect")
	var identity:String=game.session.player_key(actor);var old:=actor
	game.session.notify(actor,"phase3_reconnect",{})
	var deadline:=Time.get_ticks_msec()+10000
	while Time.get_ticks_msec()<deadline:
		var found:=0
		for id in game.players:
			if id!=old and game.session.player_key(id)==identity:found=id
		if found>0:actor=found;break
		await process_frame
	check(actor!=old,"Real reconnect changes peer ID")
	body=game.players[actor];body.set_physics_process(false);inv=game.inventories[actor]
	check(game.runtime.activities.queue(actor).size()==1,"Paid job survives transport reconnect")
	var before:int=inv.count("rope");await order("craft",{"recipe":"rope","request_id":"disconnect-paid"},true)
	check(inv.count("rope")==before+1 and game.runtime.activities.queue(actor).is_empty(),"Replay after reconnect cannot duplicate paid craft")
	await order("craft",{"recipe":"rope","request_id":"restart-paid"},false,false)
	check(game.save_game() and game.runtime.activities.queue(actor).size()==1,"Server saves paid queue and both cycles")
	await finish_server()
func restore_run()->void:
	var identity:String=game.session.player_key(actor)
	var paid_record:Dictionary=game.saved["players"][identity]
	var base:int=paid_record["inventory"].get("rope",0)
	check(inv.count("copper_pickaxe")==1 and game.runtime.workshops.size()==5,"Clean server restart restores both production cycles")
	check(paid_record.get("craft_queue",[]).size()==1,"On-disk snapshot restores paid escrow")
	check(inv.count("rope") in [base,base+1],"Elapsed online time may complete only the paid job")
	await order("craft",{"recipe":"rope","request_id":"restart-paid"},true)
	check(inv.count("rope")==base+1 and game.runtime.activities.queue(actor).is_empty(),"Restarted job completes once and rejects replay")
	check(game.save_game(),"Restored production state saves")
	await finish_server()
func finish_server()->void:
	for id in game.players:game.session.notify(id,"phase3_done",{})
	print("PHASE3_NETWORK CHECKS=%d FAILED=%d restore=%s"%[checks,failed,str(restore_mode)])
	# Stop the clock before the last paid job can complete; quit saves its escrow.
	game.quitting=true
	await create_timer(0.5).timeout;game.quitting=false
	game.quit_game(0 if failed==0 else 1,true)
