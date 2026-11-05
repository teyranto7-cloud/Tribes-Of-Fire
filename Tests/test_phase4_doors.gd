extends SceneTree
const Store=preload("res://Persistence/Store.gd")
var game
var checks:=0
var failed:=0
func check(ok:bool,text:String) -> void:
	checks+=1
	if not ok:failed+=1;push_error(text)
func _initialize() -> void:call_deferred("run")
func point(x:float,z:float) -> Vector3:return Vector3(x,game.world.terrain_height(x,z),z)
func options(at:Vector3,snap:bool=false) -> Dictionary:return {"position":[at.x,at.y,at.z],"grid":false,"snap":snap}
func run() -> void:
	game=load("res://Scenes/Main.tscn").instantiate();game.save_folder="user://phase4-doors/%d"%Time.get_ticks_usec();root.add_child(game)
	while not game.ready_world:await process_frame
	game.new_game(718991);game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false)
	game.runtime.command(1,"appearance",preload("res://Character/Appearance.gd").DEFAULT.duplicate(true));game.world.restore_buildings([]);game.world.set_process(false)
	for tree in game.world.trees:tree.set_felled(true,true)
	game.player.position=point(0,0)+Vector3.UP*.2;game.inventory.add("wood",80)
	await physics_frame;await physics_frame
	check(not game.runtime.building.build(1,"door_leaf",0,options(point(0,-4))),"Separate door leaf requires a frame")
	check(game.runtime.building.build(1,"door_frame",0,options(point(0,-4))),"Independent door frame can be built")
	var frame_id:int=game.world.structure_registry.next_id-1
	check(game.runtime.building.build(1,"door_leaf",0,options(point(0,-4),true)),"Door leaf snaps into the frame")
	var leaf_id:int=game.world.structure_registry.next_id-1;var leaf=game.world.get_structure(leaf_id)
	check(frame_id in leaf.get_record().get("supports",[]),"Door leaf retains frame dependency")
	await physics_frame;await physics_frame
	game.player.position=point(0,-1.5)+Vector3.UP*.2;await physics_frame;await physics_frame
	check(game.world.structure_near(game.player)==leaf,"Interaction selects leaf rather than same-position frame")
	game.runtime.command(1,"interact",{})
	check(leaf.open and int(leaf.record_extra.get("door_swing",0))==1,"Actual interaction opens a closed door away from the front player")
	game.player.position=point(0,-6.5)+Vector3.UP*.2;await physics_frame;await physics_frame
	game.runtime.command(1,"interact",{});check(not leaf.open,"Actual interaction closes from the safe side")
	game.runtime.command(1,"interact",{});check(leaf.open and int(leaf.record_extra.get("door_swing",0))==-1,"Door also opens away from a player behind it")
	game.player.position=point(0,-4)+Vector3.UP*.2;await physics_frame;await physics_frame
	check(not game.runtime.building.toggle(1,leaf) and leaf.open,"Closing cannot trap a character inside the opening")
	check(game.save_game(),"Opened door and swing direction save to disk")
	var loaded:=Store.load_world(game.save_folder);check(not loaded.is_empty(),"Opened door passes JSON validation after reload")
	game.world.restore(loaded);leaf=game.world.get_structure(leaf_id)
	check(leaf!=null and leaf.open and is_equal_approx(leaf.hinge.rotation.y,-PI*.55),"Reload restores the actual open collider pose")
	var triangle_at:=point(8,-4);var found:=false
	for candidate in [Vector2(8,-4),Vector2(-8,-4),Vector2(8,4),Vector2(12,0),Vector2(-12,0)]:
		triangle_at=point(candidate.x,candidate.y);game.player.position=point(candidate.x,candidate.y+4)+Vector3.UP*.2
		await physics_frame;await physics_frame
		if game.runtime.building.preview(1,"foundation_triangle",0,options(triangle_at))["valid"] and game.runtime.building.preview(1,"foundation_triangle",2,options(triangle_at))["valid"]:found=true;break
	check(found,"Find clear reachable terrain for both triangular halves")
	check(game.runtime.building.build(1,"foundation_triangle",0,options(triangle_at)),"Triangular foundation has a usable physical shape")
	await physics_frame;await physics_frame
	check(game.runtime.building.build(1,"foundation_triangle",2,options(triangle_at)),"Complementary triangles share a seam without false collision")
	print("PHASE4_DOORS CHECKS=%d FAILED=%d"%[checks,failed]);await game.quit_game(0 if failed==0 else 1,false)
