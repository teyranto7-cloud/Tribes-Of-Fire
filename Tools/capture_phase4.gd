extends "res://Tools/capture_audit.gd"
## Real pixels/input. Materials, camera and the labelled material gallery are fixtures.
const Buildings = preload("res://Building/Catalog.gd")
func panel():
	for child in game.hud.column.get_children():
		if child.get_script()==preload("res://UI/BuildPanel.gd"): return child
	return null
func click(button:Control) -> void:
	await frames(8); await super.click(button)
func capture(name:String) -> void:
	await frames(5); await RenderingServer.frame_post_draw
	var picture:=root.get_texture().get_image(); var path:="res://builds/phase4/screenshots/"+name+".png"
	check(picture.get_size()==root.size,"Framebuffer size "+name)
	check(picture.save_png(path)==OK,"Real screenshot "+name); captures.append(path)
func run() -> void:
	if DisplayServer.get_name()=="headless":quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/phase4/screenshots"))
	game=load("res://Scenes/Main.tscn").instantiate(); game.save_folder="user://phase4-ui"; root.add_child(game)
	while not game.ready_world: await process_frame
	game.localization.select("pt_BR"); game.graphics.begin_edit(); game.graphics.choose_preset(0); game.graphics.preview(game.world,root,game.player)
	game.new_game(718991); game.runtime.command(1,"appearance",preload("res://Character/Appearance.gd").DEFAULT.duplicate(true)); game.player.set_physics_process(false)
	game.player.position=Vector3(0,game.world.terrain_height(0,0)+.2,0); game.player.yaw=0; game.player.rotation.y=0
	for item in ["wood","stone","plank","nail","fiber","brick"]:game.inventory.add(item,40)
	for tree in game.world.trees:
		if tree.position.length()<18:tree.set_felled(true,true)
	root.disable_3d=true; await key(KEY_B)
	check(game.hud.mode=="construction","B opens modular building menu")
	var browser=panel(); browser.search.text="fundação"; browser.refresh(); await frames(8)
	check(browser.listing.get_child_count()==4,"Search filters to square and triangular foundations")
	var star:Button=browser.listing.get_child(0).get_child(0); await click(star)
	check("foundation" in preload("res://Settings/ConfigStore.gd").read("building","favourites",[]),"Mouse favourite persists with other preferences")
	await capture("catalogue-1280x720")
	var choose=find_button(browser,"Fundação quadrada · 100 HP"); check(choose!=null,"Selectable real square foundation")
	if choose!=null:await click(choose)
	check(game.hud.mode=="" and game.build_piece=="foundation","Selection opens world placement")
	await key(KEY_R); await key(KEY_PAGEUP)
	check(game.build_rotation==1 and is_equal_approx(game.build_options["height"],.25),"Rotation and height use keyboard actions")
	await key(KEY_PAGEDOWN)
	root.disable_3d=false; await frames(8)
	check(game.world.preview.mesh is ArrayMesh and game.world.preview.visible,"Ghost displays the piece geometry")
	await capture("foundation-ghost-green")
	var count:int=game.inventory.count("wood")
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new(); event.button_index=MOUSE_BUTTON_LEFT; event.position=root.size/2; event.pressed=pressed; Input.parse_input_event(event); await frames(5)
	var paid:Array=game.world.building_records().filter(func(row):return row["kind"]=="foundation" and not row.get("paid_cost",{}).is_empty())
	check(paid.size()==1 and game.inventory.count("wood")==count-6,"World mouse click builds once and pays once")
	check(not game.runtime.building.preview(1,"foundation",game.build_rotation,game.build_options)["valid"],"Existing foundation causes red collision preview")
	await capture("foundation-ghost-red")
	await key(KEY_ESCAPE); check(game.build_piece.is_empty(),"Escape cancels construction without opening another action")
	root.disable_3d=true; await key(KEY_B); browser=panel(); browser.get_child(0).current_tab=1; await frames(8)
	if not paid.is_empty():
		var id:int=paid[0]["id"]
		browser.details.get_child(1).text="Casa da Brasa"
		var save=find_button(browser,"Salvar nome e aparência"); await click(save); await frames(8)
		check(game.world.structure_registry.records[id].get("name")=="Casa da Brasa","Mouse saves a real object name")
		await click(find_button(browser,"Atualizar")); await frames(8)
		var demolish=find_button(browser,"Demolir…"); demolish.grab_focus(); await frames(8); await key(KEY_ENTER)
		var dialogs:Array=browser.find_children("*","ConfirmationDialog",true,false)
		check(not dialogs.is_empty() and dialogs[0].visible,"Demolition opens a confirmation window")
		await key(KEY_ESCAPE); check(game.world.structure_registry.records.has(id),"Cancel confirmation preserves object and materials")
	for resolution in [Vector2i(1920,1080),Vector2i(800,600)]:
		root.size=resolution; await frames(10); game.hud.show_panel("construction"); await frames(8)
		check(root.get_visible_rect().encloses(game.hud.panel.get_global_rect()),"Building menu fits "+str(resolution)); await capture("catalogue-%dx%d"%[resolution.x,resolution.y])
	root.size=Vector2i(1280,720); game.hud.show_panel(""); game.hud.hide(); game.chat_ui.set_process(false); game.chat_ui.hide(); game.player.hide()
	game.set_process(false); game.set_physics_process(false); game.world.set_process(false); root.disable_3d=false
	var stage:=Node3D.new(); game.world.add_child(stage)
	var floor_mesh:=PlaneMesh.new(); floor_mesh.size=Vector2(36,12); preload("res://World/Shapes.gd").mesh(stage,floor_mesh,Vector3(0,23.99,0),Color("#a2a790"))
	for i in range(Buildings.tiers().size()):
		var tier:String=Buildings.tiers()[i]
		game.world.add_structure("wall",Vector3((i-2.5)*4.8,24,0),0,game.runtime.key(1),9000+i,{"tier":tier,"hp":Buildings.maximum_hp(tier)})
		var title:=Label3D.new(); title.text=Buildings.tier_title(tier); title.position=Vector3((i-2.5)*4.8,28.1,0); title.billboard=BaseMaterial3D.BILLBOARD_ENABLED; title.font_size=32; title.pixel_size=.005; stage.add_child(title)
	var camera:=Camera3D.new(); game.world.add_child(camera); camera.position=Vector3(0,31,26); camera.look_at(Vector3(0,25.7,0)); camera.current=true; camera.fov=45
	await capture("six-materials-gallery-fixture")
	var samples:Array=[]; var deadline:=Time.get_ticks_msec()+4000; var previous:=Time.get_ticks_usec()
	while Time.get_ticks_msec()<deadline:
		await process_frame; var now:=Time.get_ticks_usec(); samples.append(float(now-previous)/1000); previous=now
	samples.sort()
	var sum_ms:=0.0
	for ms in samples: sum_ms+=ms
	var report:Dictionary={"checks":checks,"failed":failed,"screenshots":captures,"method":"Native mouse/keyboard for B/select/build/favourite/rotation/height/name/confirmation cancel; fixture inventory and gallery, actual framebuffer; three resolutions.","renderer":RenderingServer.get_video_adapter_name(),"performance":{"method":"Four-second fixed material gallery on software/cloud renderer, simulation frozen; not gameplay or target hardware.","frames":samples.size(),"fps":samples.size()*1000/sum_ms,"frame_p95_ms":samples[mini(samples.size()-1,ceili(samples.size()*.95)-1)],"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"nodes":get_node_count(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}}
	var file:=FileAccess.open("res://builds/phase4/gui-report.json",FileAccess.WRITE); file.store_string(JSON.stringify(report,"\t")); file.close()
	print("PHASE4_GUI CHECKS=%d FAILED=%d"%[checks,failed]); await game.quit_game(0 if failed==0 else 1,false)
