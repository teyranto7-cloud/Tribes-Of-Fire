extends SceneTree
const Shapes=preload("res://World/Shapes.gd")
const Catalog=preload("res://Items/Catalog.gd")
const Terrain=preload("res://World/Terrain.gd")
const Factory=preload("res://Building/Factory.gd")
const Tribes=preload("res://Tribes/System.gd")
const Store=preload("res://Persistence/Store.gd")
var game
var checks:=0
var failed:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failed+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var mesh:=Shapes.sculpted_mesh([[-0.5,0.5,0.5,0,0],[0.5,0.5,0.5,0,0]],8)
	var arrays:=mesh.surface_get_arrays(0);var outward:=0.0
	for i in range(arrays[Mesh.ARRAY_VERTEX].size()):outward+=arrays[Mesh.ARRAY_VERTEX][i].dot(arrays[Mesh.ARRAY_NORMAL][i])
	check(outward>0,"Sculpted characters, animals and plants have outward faces")
	var source:Dictionary={"axe":true,"raw_fish":true,"water":true}
	for species in preload("res://Animals/Animal.gd").SPECIES.values():
		for item in species["loot"]:source[item]=true
	for i in range(8):
		for item in Catalog.RECIPES:
			if Catalog.recipe(item)["cost"].keys().all(func(k):return source.has(k)):source[item]=true
	game=load("res://Scenes/Main.tscn").instantiate();game.save_folder="user://playability/%d"%Time.get_ticks_usec();root.add_child(game)
	while not game.ready_world:await process_frame
	game.new_game(718991);game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false)
	var body=game.player;var inv=game.inventory
	check(game.world.half_extent()==768,"New continent is1536m wide")
	check(game.world.sampler.locations.size()==10,"World contains eight distinct regional monuments plus cave and ruins")
	check(int(game._empty_world(9223372036854775807)["seed"])<=2147483647,"Oversized custom seeds normalize into the persistent31-bit range")
	check(game.runtime.wildlife.animals.size()==96,"New worlds distribute96 animals across the expanded continent")
	var generator=game.world.sampler
	for z in [-500.0,-300.0,-100.0,100.0,300.0,500.0]:
		check(generator.height(generator.river_x(z),z)<game.world.water_level-2.0,"Main river has navigable depth at z=%s"%z)
	check(preload("res://Networking/ServerConfig.gd").normalize({"pvp":"war"})["error"].is_empty(),"War-only PvP mode is accepted by authoritative configuration")
	var old=Terrain.new({"seed":1337,"generator":0,"size":128})
	check(is_equal_approx(old.height(7,-5),Terrain.legacy_height(7,-5)),"Historical terrain remains exact")
	for index in range(game.runtime.mining.nodes.size()):source[game.runtime.mining.resource_kind(index)]=true
	for pass_index in range(8):
		for item in Catalog.RECIPES:
			if Catalog.recipe(item)["cost"].keys().all(func(k):return source.has(k)):source[item]=true
	for item in Catalog.ids():check(source.has(item),"Item has an obtainable gather/hunt/fish/water/craft route: "+item)
	check(game.runtime.mining.resource_kind(12)=="stone" and game.runtime.mining.resource_kind(22)=="herb","Historical resource IDs retain meaning and plants have new stable IDs")
	inv.add("fiber",3);inv.add("herb",1)
	check(game.runtime._enqueue_craft(1,"bandage"),"Medicinal herbs enter a real crafting job")
	game.runtime._tick_activities(3)
	check(inv.count("bandage")==1 and inv.count("herb")==0,"Medicine craft consumes inputs and produces an item")
	body.vitals.hp=50;game.runtime.command(1,"eat",{"item":"bandage"})
	check(body.vitals.hp==70 and inv.count("bandage")==0,"Medicine consumes one item and heals actual server health")
	inv.add("wood",30);inv.add("stone",30);inv.add("fiber",30)
	game.hud.show_panel("inventory");await process_frame
	var panel
	for node in game.hud.column.get_children():
		if node.get_script()==preload("res://UI/InventoryPanel.gd"):panel=node
	check(panel!=null and panel.recipes.size()==Catalog.RECIPES.size(),"Crafting shows every recipe, including locked recipes")
	if panel!=null:
		panel._refresh_recipes()
		check(not panel.recipes["pickaxe"].disabled and panel.recipes["steel_sword"].disabled,"Craft buttons reflect actual materials and research")
		panel.search.text=Catalog.display_name("bandage").to_lower();panel._refresh_recipes()
		check(panel.recipes["bandage"].visible and not panel.recipes["steel_sword"].visible,"Recipe search works with localized item names")
	game.hud.show_panel("")
	var start:=Vector3(-8,game.world.terrain_height(-8,-12),-12)
	body.position=start+Vector3(0,0.2,2)
	var before:float=game.world.terrain_height(start.x,start.z)
	check(game.world.dig(start),"Digging changes the authoritative terrain")
	await process_frame;await process_frame;await physics_frame
	check(is_equal_approx(game.world.terrain_height(start.x,start.z),before-0.5),"Digging lowers terrain by0.5m")
	var ray:=PhysicsRayQueryParameters3D.create(start+Vector3.UP*3,start-Vector3.UP*5,1,[body.get_rid()])
	var hit:Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and absf(hit["position"].y-(before-0.5))<0.05,"Digging updates collision as well as appearance")
	var at:=Vector3(-6,game.world.terrain_height(-6,5),5)
	game.runtime._add_workshop("sawmill",at,game.runtime.key(1));body.position=at+Vector3(0,0.2,2)
	await physics_frame
	var index:int=game.runtime.workshops.size()-1;var machine=game.runtime.workshops[index]
	var wood:int=inv.count("wood")
	check(game.runtime._factory_command(1,"factory_load",index),"A real sawmill accepts resources from the owner")
	check(inv.count("wood")==wood-5 and machine.machine["input"]["wood"]==5,"Factory loading conserves exact resources")
	Factory.advance(machine.machine,"sawmill",6)
	check(machine.machine["output"]["plank"]==2 and machine.machine["input"]["wood"]==4,"Machine produces independently over time")
	var planks:int=inv.count("plank")
	check(game.runtime._factory_command(1,"factory_take",index) and inv.count("plank")==planks+2,"Factory outputs can be collected")
	check(not game.runtime._factory_command(1,"factory_take",index),"Factory output cannot be duplicated")
	game.runtime._restore_workshops(game.runtime.save_state()["workshops"])
	check(game.runtime.workshops[index]==machine,"Replicated factory updates preserve moving model nodes")
	var z:=100.0;var x:float=generator.river_x(z)
	var raft=game.world.add_structure("raft",Vector3(x,game.world.water_level+0.12,z),0,game.runtime.key(1))
	body.position=raft.position+Vector3(2,0.6,0);await physics_frame
	check(game.runtime._interact(1) and body.boat==raft,"A player can board a physical raft")
	var boat_before:Vector3=raft.position
	body.set_intent({"move":[0,-1],"yaw":0.0})
	for frame in range(10):body._sail(0.02)
	check(raft.position.distance_to(boat_before)>0.2,"Server movement intents propel the raft on the river")
	check(game.runtime._interact(1) and body.boat==null,"A player can disembark")
	body.boat=raft;body.vitals.hp=0;body.respawn()
	check(body.boat==null,"Respawning releases the raft instead of teleporting the player back onto it")
	var tribes:=Tribes.new();tribes.command("a","tribe_create",{"name":"Ember"},1000);tribes.command("b","tribe_create",{"name":"River"},1000)
	var ta:=tribes.tribe_of("a");var tb:=tribes.tribe_of("b")
	check(not tribes.command("outsider","tribe_war",{"target":tb},1000),"Only a tribe leader can declare diplomacy")
	check(tribes.command("a","tribe_alliance",{"target":tb},1000) and tribes.command("b","tribe_accept_alliance",{"target":ta},1001),"Alliances require both leaders")
	check(not tribes.can_damage("a","b",1002) and not tribes.can_damage("b","a",1002),"Allied damage is blocked in both directions")
	check(tribes.command("a","tribe_break_alliance",{"target":tb},1010) and not tribes.command("a","tribe_war",{"target":tb},1020),"Breaking an alliance enforces a one-hour truce")
	check(not tribes.can_damage("a","b",4609) and tribes.command("a","tribe_war",{"target":tb},4610),"War only begins after the full truce")
	check(tribes.at_war(ta,tb) and Tribes.valid_state(tribes.state()),"War state is persistent and validated")
	game.clock.elapsed=900;game.world.illuminate(game.clock);var day:float=game.world.sun.light_energy
	game.clock.elapsed=2100;game.world.illuminate(game.clock)
	check(day>game.world.sun.light_energy and game.world.moon.light_energy>0,"World has a functional day/night light cycle")
	var save:Dictionary=game.snapshot()
	check(Store.valid(save),"Expanded world, machines, raft and terrain edits form a valid save")
	check(Store.save_world(save,game.save_folder)=="","New systems can actually be saved")
	var loaded:Dictionary=Store.load_world(game.save_folder)
	check(loaded.get("terrain_changes")==game.world.sampler.changes and loaded.get("world",{}).get("size")==1536,"Reload preserves seed, map dimensions and excavated terrain")
	check(loaded.get("workshops",[]).back().get("machine",{}).get("input",{}).get("wood")==4,"Factory input and progress survive save/load")
	print("PLAYABILITY CHECKS=%d FAILED=%d"%[checks,failed])
	await game.quit_game(1 if failed else 0,false)
