extends "res://Tools/capture_audit.gd"
## Actual input and pixels; resources/machines are clearly fixture setup.
func panel():
	for child in game.hud.column.get_children():
		if child.get_script()==preload("res://UI/BuildPanel.gd"):return child
	return null
func press(button:Control) -> void:
	check(button!=null,"Requested functional button exists")
	if button==null:return
	button.grab_focus();await frames(12)
	var parents:Array=[];var current=button.get_parent()
	while current!=null and not current is Window:
		if current is ScrollContainer:parents.append(current)
		current=current.get_parent()
	for scroll in parents:scroll.ensure_control_visible(button);await frames(8)
	var window:=button.get_window()
	if window==root:await click(button)
	else:
		# Embedded popup controls use their own viewport coordinates.
		var at:Vector2=button.get_global_rect().get_center()+Vector2(window.position)
		Input.warp_mouse(at)
		for down in [true,false]:
			var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=at;event.global_position=at;event.pressed=down;Input.parse_input_event(event);await frames(4)
	await frames(15)
func capture(name:String) -> void:
	await frames(6);await RenderingServer.frame_post_draw
	var picture:=root.get_texture().get_image();var path:="res://builds/lifecycle/screenshots/"+name+".png"
	check(picture.save_png(path)==OK,"Real framebuffer saved "+name);captures.append(path)
func run() -> void:
	if DisplayServer.get_name()=="headless":quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/lifecycle/screenshots"))
	game=load("res://Scenes/Main.tscn").instantiate();game.save_folder="user://lifecycle-ui";root.add_child(game)
	while not game.ready_world:await process_frame
	game.localization.select("pt_BR");game.graphics.begin_edit();game.graphics.choose_preset(0);game.graphics.preview(game.world,root,game.player)
	game.new_game(718991);game.runtime.command(1,"appearance",preload("res://Character/Appearance.gd").DEFAULT.duplicate(true));game.player.set_physics_process(false)
	game.world.restore_buildings([])
	for tree in game.world.trees:
		if tree.position.length()<20:tree.set_felled(true,true)
	game.player.position=Vector3(0,game.world.terrain_height(0,0)+.2,0);game.player.yaw=0;game.player.rotation.y=0
	game.runtime._add_workshop("sawmill",Vector3(0,game.world.terrain_height(0,-3),-3),game.runtime.key(1))
	game.runtime.workshops[0].building["paid_cost"]={"plank":8,"iron_ingot":2};game.runtime.grid.motors=[0]
	root.disable_3d=true;await key(KEY_B);var browser=panel();browser.get_child(0).current_tab=1;await frames(15)
	check(browser.nearby.item_count==1,"Management selects actual nearby machine")
	await press(find_button(browser,"Retirar motor (devolve 1 motor)…"))
	var dialogs:Array=browser.find_children("*","ConfirmationDialog",true,false)
	check(not dialogs.is_empty() and dialogs[0].visible,"Motor removal opens real confirmation")
	if not dialogs.is_empty():await press(dialogs[0].get_ok_button())
	check(game.runtime.grid.motors.is_empty() and game.inventory.count("motor")==1,"Mouse confirmation returns exactly one installed motor")
	await frames(20);await capture("industry-manager-1280x720")
	await press(find_button(browser,"Demolir bancada (restitui 50%)…"))
	dialogs=browser.find_children("*","ConfirmationDialog",true,false)
	check(not dialogs.is_empty() and dialogs[0].visible,"Industrial demolition opens confirmation")
	await key(KEY_ESCAPE)
	check(not game.runtime.workshops[0].retired(),"Cancel preserves machine and paid materials")
	await press(find_button(browser,"Demolir bancada (restitui 50%)…"));dialogs=browser.find_children("*","ConfirmationDialog",true,false)
	if not dialogs.is_empty():await press(dialogs[0].get_ok_button())
	check(game.runtime.workshops[0].retired() and game.inventory.count("plank")==4 and game.inventory.count("iron_ingot")==1,"Mouse demolition removes actual machine and refunds once")
	for resolution in [Vector2i(1920,1080),Vector2i(800,600)]:
		root.size=resolution;await frames(10);game.hud.show_panel("construction");await frames(10)
		check(root.get_visible_rect().encloses(game.hud.panel.get_global_rect()),"Industrial menu fits "+str(resolution));await capture("industry-%dx%d"%[resolution.x,resolution.y])
	root.size=Vector2i(1280,720);root.disable_3d=false;game.hud.show_panel("")
	var origin:=Vector3(0,game.world.terrain_height(0,-1.7),-1.7)
	var wall=game.world.add_structure("wall",origin,0,"enemy-fixture",-1,{"hp":1,"tier":"wood"});var uid:int=wall.structure_id
	game.world.add_structure("roof",origin,0,"enemy-fixture",-1,{"supports":[uid]})
	game.server_rules["pvp"]="on";game.server_rules["structural_support"]=true
	await frames(10);await capture("before-destruction-fixture")
	game.player.attack_time=0;game.player.stamina=100;game.runtime.combat.tick(2)
	# A real left click enters Main -> server combat ray -> destruction.
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=root.size/2;event.pressed=down;Input.parse_input_event(event);await frames(1)
	check(not game.world.structure_registry.records.has(uid),"World mouse click destroys the structure through actual combat")
	await capture("physical-debris-fixture")
	check(preload("res://Building/Debris.gd").live>0,"Rendered physical debris is instantiated with bounded lifetime")
	await create_timer(3.3).timeout
	check(preload("res://Building/Debris.gd").live==0,"Debris frees bodies after lifetime")
	var file:=FileAccess.open("res://builds/lifecycle/gui-report.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failed":failed,"screenshots":captures,"renderer":RenderingServer.get_video_adapter_name(),"method":"Actual mouse/keyboard and framebuffer; fixture resources and machine; industrial confirmations/cancel/refund, three resolutions, combat and physical debris."},"\t"));file.close()
	print("LIFECYCLE_GUI CHECKS=%d FAILED=%d"%[checks,failed]);await game.quit_game(0 if failed==0 else 1,false)
