extends SceneTree
const Store = preload("res://Persistence/Store.gd")
const Catalog = preload("res://Items/Catalog.gd")
var game
var checks := 0
var failed := 0
var base: Vector3
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failed+=1;push_error(label)
func _initialize() -> void:call_deferred("run")
func wall(owner: String, hp: int=100):
	return game.world.add_structure("wall",base+Vector3(0,0,-1.7),0,owner,-1,{"hp":hp,"tier":"wood","revision":1,"supports":[]})
func swing() -> void:
	game.player.stamina=100;game.player.attack_time=0;game.runtime.combat.tick(2)
	game.runtime.command(1,"combat",{"kind":"light"})
func run() -> void:
	check(not preload("res://Networking/Session.gd").valid_command("combat",{"kind":"light","damage":9999}),"Network refuses client-supplied structural damage")
	game=load("res://Scenes/Main.tscn").instantiate();game.save_folder="user://structure-combat/%d"%Time.get_ticks_usec();root.add_child(game)
	while not game.ready_world:await process_frame
	game.new_game(718991);game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false)
	game.runtime.command(1,"appearance",preload("res://Character/Appearance.gd").DEFAULT.duplicate(true))
	game.world.restore_buildings([])
	for tree in game.world.trees:tree.set_felled(true,true)
	base=Vector3(0,game.world.terrain_height(0,0),0);game.player.position=base+Vector3.UP*.2;game.player.yaw=0;game.player.rotation.y=0
	var own:String=game.runtime.key(1);var enemy:="enemy-fixture";var tribes=game.runtime.tribes
	var target=wall(enemy);var uid:int=target.structure_id
	await physics_frame;await physics_frame
	game.server_rules["pvp"]="off";swing();check(target.hp==100,"PvP off protects player structures")
	game.server_rules["pvp"]="war";swing();check(target.hp==100,"War mode does not allow neutral raiding")
	game.server_rules["pvp"]="on";swing()
	var damage:int=Catalog.damage("axe")
	check(target.hp==100-damage and int(target.record_extra["revision"])==2,"Actual combat ray damages one structure by server weapon statistics")
	game.runtime.command(1,"combat",{"kind":"light"});check(target.hp==100-damage,"Attack cooldown prevents duplicate damage")
	var snapshot:Dictionary=game.snapshot();check(Store.valid(snapshot) and Store.save_world(snapshot,game.save_folder)=="","Damaged integrity persists through validated disk save")
	var saved:=Store.load_world(game.save_folder);game.world.restore(saved);target=game.world.get_structure(uid,true)
	check(target.hp==100-damage,"Reload restores damaged integrity rather than resetting HP")
	game.player.authoritative=false;swing();check(target.hp==100-damage,"Non-authoritative body cannot apply damage");game.player.authoritative=true
	var before:int=target.hp;game.player.position+=Vector3(0,0,8);swing();check(target.hp==before,"Server weapon reach prevents distant structural damage");game.player.position=base+Vector3.UP*.2
	var shield=game.world.add_structure("wall",base+Vector3(0,0,-.8),0,own)
	await physics_frame;await physics_frame;swing();check(target.hp==before and shield.hp==100,"Owned wall blocks attacking through to enemy behind it")
	game.world.remove_structure(shield.structure_id);await physics_frame;await physics_frame
	tribes.command(own,"tribe_create",{"name":"Brasa"});tribes.command(own,"tribe_invite",{"target":enemy});tribes.command(enemy,"tribe_accept",{})
	swing();check(target.hp==before,"Friendly fire protection applies to tribal buildings")
	tribes.command(enemy,"tribe_leave",{});swing();check(target.hp==before,"Five-minute departure protection also protects former member buildings")
	for protection in tribes.protections:protection["until"]=Time.get_unix_time_from_system()-1
	tribes.command(enemy,"tribe_create",{"name":"Pedra"})
	var a:String=tribes.tribe_of(own);var b:String=tribes.tribe_of(enemy);var pair:String=tribes.pair_key(a,b)
	tribes.relations[pair]={"status":"allied","request":"","requested_by":"","until":0.0};swing();check(target.hp==before,"Allied structures cannot be attacked")
	tribes.relations[pair]={"status":"neutral","request":"","requested_by":"","until":Time.get_unix_time_from_system()+3600};swing();check(target.hp==before,"Alliance-break truce protects buildings too")
	tribes.relations[pair]={"status":"war","request":"","requested_by":"","until":0.0};game.server_rules["pvp"]="war";swing();check(target.hp==before-damage,"Declared war permits damage once all protections expire")
	game.world.restore_buildings([]);await physics_frame;await physics_frame
	game.server_rules["structural_support"]=true
	var support=wall(enemy,1);var parent:int=support.structure_id
	var roof=game.world.add_structure("roof",base+Vector3(0,0,-1.7),0,enemy,-1,{"supports":[parent]});var roof_id:int=roof.structure_id
	await physics_frame;await physics_frame;swing()
	check(not game.world.structure_registry.records.has(parent) and not game.world.structure_registry.records.has(roof_id),"Destroyed last support collapses dependent roof in strict mode")
	check(Store.valid(game.snapshot()),"Collapse leaves no dangling support references")
	support=wall(enemy,1);parent=support.structure_id
	var alternative=game.world.add_structure("wall",base+Vector3(4,0,-1.7),0,enemy)
	roof=game.world.add_structure("roof",base+Vector3(0,0,-1.7),0,enemy,-1,{"supports":[parent,alternative.structure_id]});roof_id=roof.structure_id
	await physics_frame;await physics_frame;swing()
	check(game.world.structure_registry.records.has(roof_id) and game.world.structure_registry.records[roof_id]["supports"]==[alternative.structure_id],"Alternate intact support prevents roof collapse and removes broken edge")
	game.world.restore_buildings([]);await physics_frame;await physics_frame
	support=wall(enemy,1);parent=support.structure_id
	game.runtime._add_workshop("sawmill",support.position+Vector3.UP*3,enemy)
	await physics_frame;await physics_frame;swing()
	check(game.world.structure_registry.records.has(parent) and support.hp==1,"Industrial support cannot strand filled machinery during combat")
	game.runtime.workshops[0].queue_free();game.runtime.workshops.clear()
	await physics_frame;await physics_frame;swing()
	check(not game.world.structure_registry.records.has(parent),"Removing industrial load permits support destruction")
	game.world.restore_buildings([]);await physics_frame;await physics_frame
	support=wall(enemy,1);parent=support.structure_id
	var chest=game.world.add_structure("chest",base+Vector3(0,3.5,-1.7),0,enemy,-1,{"supports":[parent],"storage":{"iron_pickaxe":1,"wood":3},"storage_wear":{"iron_pickaxe":34},"locked":true,"paid_cost":{"wood":8}});var chest_id:int=chest.structure_id
	await physics_frame;await physics_frame;swing();chest=game.world.get_structure(chest_id)
	check(chest!=null and chest.hp==0 and chest.storage.get("wood")==3 and chest.storage_wear.get("iron_pickaxe")==34,"Collapsed full chest becomes one loot container with exact contents and tool wear")
	check(chest.collision_layer==0 and chest.record_extra.get("locked")==false and chest.record_extra.get("paid_cost",{}).is_empty(),"Wreck cannot block passage, stay locked or refund construction again")
	check(absf(chest.position.y-game.world.terrain_height(chest.position.x,chest.position.z)-.05)<.001,"Loot falls to reachable ground instead of floating on removed roof")
	var edit:Dictionary={"id":chest_id,"revision":int(chest.record_extra.get("revision",1)),"op":"repair"}
	check(not game.runtime.building.edit(1,edit),"Destroyed loot cannot be repaired into a free chest")
	check(Store.save_world(game.snapshot(),game.save_folder)=="","Wreckage and remaining loot saved")
	game.world.restore(Store.load_world(game.save_folder));chest=game.world.get_structure(chest_id,true)
	check(chest.hp==0 and chest.storage_wear["iron_pickaxe"]==34,"Wreckage survives reload with wear")
	check(not game.runtime._chest_transfer(1,{"structure":chest_id,"slot":0,"amount":1,"to_chest":true}),"Wreckage is collect-only, not a free new storage chest")
	var count:int=game.inventory.count("iron_pickaxe")
	check(game.runtime._chest_transfer(1,{"structure":chest_id,"slot":0,"amount":1,"to_chest":false,"expected_item":"iron_pickaxe"}),"Enemy can collect destroyed chest loot through actual transfer")
	check(game.inventory.count("iron_pickaxe")==count+1 and int(game.inventory.durability["iron_pickaxe"])==34,"Loot transfer preserves count and existing wear")
	check(not game.runtime._chest_transfer(1,{"structure":chest_id,"slot":0,"amount":1,"to_chest":false,"expected_item":"iron_pickaxe"}),"Replayed pickup cannot take a different remaining item")
	check(game.runtime._chest_transfer(1,{"structure":chest_id,"slot":0,"amount":3,"to_chest":false,"expected_item":"wood"}) and not game.world.structure_registry.records.has(chest_id),"Empty wreckage is removed only after last successful transfer")
	check(Store.valid(game.snapshot()),"Final post-loot snapshot remains valid")
	print("STRUCTURE_COMBAT CHECKS=%d FAILED=%d"%[checks,failed]);await game.quit_game(0 if failed==0 else 1,false)
