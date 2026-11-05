extends SceneTree
var game
var checks:=0
var failed:=0
func check(ok:bool,text:String) -> void:
	checks+=1
	if not ok:failed+=1;push_error(text)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	game=load("res://Scenes/Main.tscn").instantiate();game.save_folder="user://phase4-raft/%d"%Time.get_ticks_usec();root.add_child(game)
	while not game.ready_world:await process_frame
	game.new_game(718991);game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false)
	game.runtime.command(1,"appearance",preload("res://Character/Appearance.gd").DEFAULT.duplicate(true));game.world.set_process(false)
	for tree in game.world.trees:tree.set_felled(true,true)
	game.inventory.add("plank",8);game.inventory.add("rope",3)
	game.player.position=Vector3(0,game.world.terrain_height(0,0)+.2,0);game.player.yaw=0;game.player.rotation.y=0
	await physics_frame;await physics_frame
	check(not game.runtime.building.preview(1,"raft",0)["valid"],"Raft blueprint refuses dry ground")
	var river=game.world.sampler.watershed
	game.player.position=Vector3(river.center(50)+4,game.world.water_level+.3,50);game.player.yaw=PI/2;game.player.rotation.y=PI/2
	await physics_frame;await physics_frame
	var site:Dictionary=game.runtime.building.preview(1,"raft",0)
	check(site["valid"] and absf(site["position"].y-game.world.water_level-.12)<.01,"Raft preview follows water surface rather than river bed")
	check(game.runtime.building.build(1,"raft",0,{}),"Raft remains constructible through the real building command service")
	check(game.inventory.count("plank")==0 and game.inventory.count("rope")==0,"Raft consumes its exact preserved cost")
	check(preload("res://Persistence/Store.gd").valid(game.snapshot()),"Constructed raft remains compatible with world persistence")
	game.inventory.add("wood",4)
	var before:Dictionary=game.inventory.serialize();var position_before:Vector3=game.player.position
	game.player.position=Vector3(0,119,0);await physics_frame;await physics_frame
	var high:Dictionary=game.runtime.building.preview(1,"wall",0,{"position":[0,123,-4],"snap":false,"grid":false})
	check(not high["valid"],"A reachable but unsavable height is refused before any debit")
	check(game.inventory.serialize()==before,"Invalid boundary preview changes no inventory")
	game.player.position=position_before
	print("PHASE4_RAFT CHECKS=%d FAILED=%d"%[checks,failed]);await game.quit_game(0 if failed==0 else 1,false)
