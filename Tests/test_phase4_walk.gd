extends SceneTree
var game
var checks:=0
var failed:=0
func check(ok:bool,text:String) -> void:
	checks+=1
	if not ok:failed+=1;push_error(text)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	game=load("res://Scenes/Main.tscn").instantiate();game.save_folder="user://phase4-walk/%d"%Time.get_ticks_usec();root.add_child(game)
	while not game.ready_world:await process_frame
	game.new_game(718991);game.set_process(false);game.set_physics_process(false);game.world.set_process(false)
	game.runtime.command(1,"appearance",preload("res://Character/Appearance.gd").DEFAULT.duplicate(true));game.player.local_control=false
	var floor_node:=StaticBody3D.new();game.world.add_child(floor_node)
	var floor_shape:=BoxShape3D.new();floor_shape.size=Vector3(18,.2,18);preload("res://World/Shapes.gd").collider(floor_node,floor_shape,Vector3(0,19.9,0))
	for entry in [["stairs",0.0],["ramp",5.0]]:
		game.player.set_physics_process(false);game.player.position=Vector3(entry[1],20.2,2);game.player.velocity=Vector3.ZERO
		game.world.add_structure(entry[0],Vector3(entry[1],20,-2),0,game.runtime.key(1))
		await physics_frame;await physics_frame
		game.player.set_physics_process(true);var maximum_y:float=game.player.position.y;var frames:=0
		for i in range(240):
			game.player.set_intent({"move":[0,-1],"yaw":0,"jump":false,"sprint":false});await physics_frame
			maximum_y=maxf(maximum_y,game.player.position.y);frames+=1
			if game.player.position.z< -3.6:break
		check(game.player.position.z< -3.5 and maximum_y>22.8,"Walk up "+entry[0]+" without jumping")
		check(game.player.vitals.hp==100,"Traversal preserves health "+entry[0])
		print("PHASE4_WALK_SAMPLE kind=",entry[0]," frames=",frames," end=",game.player.position," maximum_y=",maximum_y)
	game.player.set_physics_process(false)
	print("PHASE4_WALK CHECKS=%d FAILED=%d"%[checks,failed]);await game.quit_game(0 if failed==0 else 1,false)
