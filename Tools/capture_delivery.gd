extends SceneTree
## Real window input and framebuffers; fixture inventories are only for UI validation.
var game
var checks := 0
var failed := 0
var captures: Array = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	print("DELIVERY_GUI ","PASS " if ok else "FAIL ",message)
	if not ok: failed += 1; push_error(message)
func frames(n: int = 4) -> void:
	for i in range(n): await process_frame
func key(code: int) -> void:
	var event := InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true
	Input.parse_input_event(event);await frames()
	event=event.duplicate();event.pressed=false;Input.parse_input_event(event);await frames()
func find_button(node: Node, text: String):
	if node is Button and node.text==text:return node
	for child in node.get_children():
		var result=find_button(child,text)
		if result!=null:return result
	return null
func click(button: Control) -> void:
	var at: Vector2=button.get_global_rect().get_center();Input.warp_mouse(at);await frames(2)
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=at;event.global_position=at;event.pressed=down
		Input.parse_input_event(event);await frames()
func capture(name: String) -> void:
	await frames();await RenderingServer.frame_post_draw
	var picture:=root.get_texture().get_image()
	check(picture.get_size()==root.size,"Captured pixels match actual window "+name)
	var path:="res://builds/delivery/screenshots/"+name+".png"
	check(picture.save_png(path)==OK,"Saved "+name);captures.append(path)
func run() -> void:
	if DisplayServer.get_name()=="headless":printerr("Display required");quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/delivery/screenshots"))
	game=load("res://Scenes/Main.tscn").instantiate();game.save_folder="user://delivery-capture";root.add_child(game)
	while not game.ready_world:await process_frame
	game.localization.select("pt_BR");game.graphics.begin_edit();game.graphics.choose_preset(0);game.graphics.preview(game.world,root,game.player)
	game.new_game(718991);game.runtime.command(1,"appearance",preload("res://Character/Appearance.gd").DEFAULT.duplicate(true))
	game.player.set_physics_process(false)
	for item in ["wood","stone","fiber","plank","log"]:game.inventory.add(item,20)
	game.runtime._add_workshop("sawmill",Vector3(0,game.world.terrain_height(0,4),4),game.runtime.key(1))
	var machine=game.runtime.workshops[-1];machine.machine["recipe"]="sawmill_planks"
	machine.machine["input"]={};machine.machine["output"]={};machine.machine["progress"]=0
	game.player.position=machine.position+Vector3(0,0.2,2)
	root.disable_3d=true
	game.hud.show_panel("");await key(KEY_E)
	check(game.hud.mode=="factory","E opens an actual production station")
	var supply=find_button(game.hud.column,"Abastecer 1 ciclo")
	check(supply!=null,"Production has a functional supply control")
	if supply!=null:
		var before:int=game.inventory.count("log");await click(supply)
		check(game.inventory.count("log")==before-1,"Mouse click supplies exactly one cycle")
		await create_timer(6.5).timeout
		var collect=find_button(game.hud.column,"Retirar produção")
		var planks:int=game.inventory.count("plank")
		check(collect!=null and int(machine.machine["output"].get("plank",0))>=6,"Timed production creates actual outputs")
		if collect!=null:await click(collect)
		check(game.inventory.count("plank")==planks+6,"Mouse click collects produced planks")
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(800,600)]:
		root.size=dimensions;await frames(12)
		check(root.get_visible_rect().size==Vector2(dimensions),"Native responsive viewport "+str(dimensions))
		game.hud.show_panel("");await key(KEY_I)
		check(game.hud.mode=="inventory","I opens backpack "+str(dimensions))
		check(game.hud.panel.get_global_rect().end.x<=dimensions.x+1,"Panel stays inside window "+str(dimensions))
		await capture("inventory-%dx%d"%[dimensions.x,dimensions.y]);await key(KEY_I)
		check(game.hud.mode=="","I closes backpack "+str(dimensions))
		await key(KEY_M);check(game.hud.mode=="map","M opens navigation "+str(dimensions))
		await capture("map-%dx%d"%[dimensions.x,dimensions.y]);await key(KEY_M)
	root.size=Vector2i(1280,720);await frames(10)
	game.hud.show_panel("");root.disable_3d=false;await create_timer(1).timeout
	await capture("world-1280x720")
	var file:=FileAccess.open("res://builds/delivery/gui-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failed":failed,"captures":captures,"method":"Xorg/Mesa llvmpipe, actual window pixels and Input.parse_input_event keys/mouse. UI interactions disable 3D drawing only; world capture enables 3D. Fixture items for UI; authoritative resource collection is independently tested in phase3 ENet."},"\t"));file.close()
	print("DELIVERY_GUI CHECKS=%d FAILED=%d"%[checks,failed]);await game.quit_game(0 if failed==0 else 1,false)
