extends SceneTree
var game
var checks:=0
func _initialize()->void:call_deferred("run")
func capture(name:String)->void:
	await create_timer(0.4).timeout;await RenderingServer.frame_post_draw
	var picture:=root.get_texture().get_image()
	if picture==null or picture.is_empty():push_error("Empty phase3 screenshot");quit(1);return
	if picture.save_png("res://builds/screenshots/phase3/"+name+".png")!=OK:quit(1);return
	checks+=1
func run()->void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/screenshots/phase3"))
	game=load("res://Scenes/Main.tscn").instantiate();root.add_child(game)
	while not game.ready_world:await process_frame
	game.save_folder="user://phase3-capture/%d"%OS.get_process_id()
	game.localization.select("pt_BR");game.graphics.begin_edit();game.graphics.choose_preset(0);game.graphics.preview(game.world,root,game.player)
	game.new_game(718991);game.runtime.command(1,"appearance",preload("res://Character/Appearance.gd").DEFAULT.duplicate(true))
	for id in ["wood","stone","fiber","plank"]:game.inventory.add(id,20)
	game.inventory.add("log",3)
	game.runtime._add_workshop("sawmill",Vector3(0,game.world.terrain_height(0,4),4),game.runtime.key(1))
	var machine=game.runtime.workshops[-1]
	machine.machine["recipe"]="sawmill_planks";machine.machine["input"]={"log":2}
	game.player.position=machine.position+Vector3(0,0.2,2);game.player.set_physics_process(false)
	for dimensions in [Vector2i(1280,720),Vector2i(960,540)]:
		root.content_scale_size=Vector2i.ZERO;root.size=dimensions;await process_frame
		game.hud.show_panel("inventory");await process_frame
		for node in game.hud.column.get_children():
			if node.get_script()==preload("res://UI/InventoryPanel.gd"):
				node.get_child(0).current_tab=1;node.search.text="tábuas";node._refresh_recipes()
		await capture("crafting-%dx%d"%[dimensions.x,dimensions.y])
		game.runtime.factory_view={"station":0,"kind":"sawmill","state":machine.machine.duplicate(true)}
		game.hud.show_panel("factory");await capture("station-%dx%d"%[dimensions.x,dimensions.y])
	print("PHASE3_RENDER CHECKS=%d FAILED=0"%checks);game.quit_game(0,false)
