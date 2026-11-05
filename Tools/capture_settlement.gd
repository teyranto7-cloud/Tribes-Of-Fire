extends "res://Tools/capture_audit.gd"
## Actual framebuffers and mouse/keyboard input; materials and gallery are fixtures.
func capture(name: String) -> void:
	await frames(); await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	check(picture.get_size() == root.size, "Actual window size " + name)
	var path := "res://builds/settlement/ui/" + name + ".png"
	check(picture.save_png(path) == OK, "Saved " + name); captures.append(path)
func click(button: Control) -> void:
	await frames(8)
	await super.click(button)

func run() -> void:
	if DisplayServer.get_name() == "headless": quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/settlement/ui"))
	game = load("res://Scenes/Main.tscn").instantiate(); game.save_folder = "user://settlement-ui"; root.add_child(game)
	while not game.ready_world: await process_frame
	game.localization.select("pt_BR"); game.hud.show_panel("menu"); root.disable_3d = true
	await capture("main-menu-1280x720")
	game.graphics.begin_edit(); game.graphics.choose_preset(0); game.graphics.preview(game.world, root, game.player)
	game.new_game(718991); game.runtime.command(1, "appearance", preload("res://Character/Appearance.gd").DEFAULT.duplicate(true)); game.player.set_physics_process(false)
	var catalog = preload("res://Items/Catalog.gd")
	for item in ["wood", "stone", "gear", "iron_ingot", "plank", "wire", "glass", "cloth"]: game.inventory.add(item, 20)
	var at := Vector3(0, game.world.terrain_height(0, 0) + 0.2, 0)
	game.player.position = at
	game.runtime._add_workshop("mechanical_workshop", at + Vector3(0, -0.2, 2), game.runtime.key(1))
	game.hud.show_panel("inventory")
	var bag
	for child in game.hud.column.get_children():
		if child.get_script() == preload("res://UI/InventoryPanel.gd"): bag = child
	bag.get_child(0).current_tab = 1; bag.search.text = "roda"; bag._refresh_recipes(); await frames(8)
	check(not bag.recipes["waterwheel"].disabled, "Waterwheel recipe exposes real obtainable materials and station")
	var iron: int = game.inventory.count("iron_ingot"); await click(bag.recipes["waterwheel"])
	check(game.inventory.count("iron_ingot") == iron - 6, "Craft click reserves wheel materials exactly once")
	await create_timer(6.5).timeout
	check(game.inventory.count("waterwheel") == 1, "Timed crafting creates a usable wheel kit")
	await capture("energy-crafting-1280x720")
	game.settings_manager.write_sections({"quickbar": {"slot1": "waterwheel"}}); game.hud.show_panel("")
	await key(KEY_1); check(game.build_piece == "waterwheel", "Keyboard shortcut selects a data-defined build kit")
	game.build_piece = ""
	game.session._keys[2] = "2".repeat(64); game._spawn_player(2); game.players[2].set_physics_process(false)
	var visitor:Dictionary=preload("res://Character/Appearance.gd").DEFAULT.duplicate(true);visitor["name"]="Visitante";game.runtime.command(2,"appearance",visitor)
	game.players[2].position = at + Vector3(1.6, 0, 0); game.inventories[2].add("stone", 8)
	await physics_frame; await physics_frame
	game.hud.show_panel("trade")
	var trade
	for child in game.hud.column.get_children():
		if child.get_script() == preload("res://UI/TradePanel.gd"): trade = child
	trade.give.select(trade.item_ids.find("wood")); trade.want.select(trade.item_ids.find("stone")); trade.amount.value = 4; trade.quantity.value = 2; trade._refresh()
	var wood: int = game.inventory.count("wood"); await click(trade.send)
	check(game.runtime.exchange.offers.size() == 1 and game.inventory.count("wood") == wood, "Mouse creates an unpaid, consent-based trade offer")
	await capture("trade-offer-1280x720")
	if not game.runtime.exchange.offers.is_empty(): game.runtime.command(2, "trade_accept", {"id": game.runtime.exchange.offers.keys()[0]})
	check(game.inventory.count("wood") == wood - 4, "Accepting counterpart executes the offered trade")
	game.runtime.tribes.command(game.runtime.key(1), "tribe_create", {"name": "Vale da Brasa"})
	game.hud.show_panel("map")
	var map
	for child in game.hud.column.get_children():
		if child.get_script() == preload("res://UI/WorldMap.gd"): map = child
	await click(map.canvas)
	var ping = find_button(game.hud.column, "Enviar ping à tribo e aliados · 20 s")
	if ping != null:
		ping.grab_focus(); await frames(); await key(KEY_ENTER)
	check(game.runtime.team_pings.entries.size() == 1, "Map button sends a server-owned discovered-position ping")
	await capture("team-ping-map-1280x720")
	for resolution in [Vector2i(1920, 1080), Vector2i(800, 600)]:
		root.size = resolution; await frames(8); game.hud.show_panel("inventory"); await frames(8)
		check(root.get_visible_rect().encloses(game.hud.panel.get_global_rect()), "Inventory fits " + str(resolution))
		await capture("inventory-%dx%d" % [resolution.x, resolution.y])
	root.size = Vector2i(1280, 720); game.hud.show_panel(""); await frames(8)
	root.disable_3d = false; game.set_physics_process(false); game.hud.hide(); game.chat_ui.set_process(false); game.chat_ui.hide()
	var stage := Node3D.new(); game.world.add_child(stage); stage.position = Vector3(0, 20, 15)
	var floor_shape := PlaneMesh.new(); floor_shape.size = Vector2(27, 18)
	preload("res://World/Shapes.gd").mesh(stage, floor_shape, Vector3(0, -0.02, 4.5), Color("#6f715b"))
	var index := 0
	for kind in catalog.station_ids():
		var assembly := Node3D.new(); assembly.position = Vector3((index % 6 - 2.5) * 4, 0, (index / 6) * 4.5); stage.add_child(assembly)
		preload("res://Building/WorkshopVisuals.gd").build(assembly, kind)
		var title := Label3D.new(); title.text = catalog.display_name(kind); title.position.y = 2.5; title.font_size = 24; title.pixel_size = 0.006; title.billboard = BaseMaterial3D.BILLBOARD_ENABLED; assembly.add_child(title)
		index += 1
	var camera := Camera3D.new(); game.world.add_child(camera); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.size = 24; camera.position = Vector3(16, 42, 42); camera.look_at(stage.position + Vector3(0, 0, 4.5)); camera.current = true
	await frames(16); await capture("workshops-gallery")
	camera.size=12;camera.position=stage.position+Vector3(11,7,10);camera.look_at(stage.position+Vector3(6,0.8,0))
	await capture("workshops-forge-closeup")
	camera.position=stage.position+Vector3(-6,7,14);camera.look_at(stage.position+Vector3(-5,0.8,4.5))
	await capture("workshops-loom-closeup")
	check(index == 17, "All 17 station silhouettes render in the review gallery")
	stage.queue_free(); await frames()
	var river = game.world.sampler.watershed
	var wheel := Vector3(river.center(90) + river.width(90) * 0.8, game.world.water_level + 1, 90)
	var bank := Vector3(wheel.x + 4, 0, 90); bank.y = game.world.terrain_height(bank.x, bank.z)
	for z in range(4, 8):
		for x in range(floori(bank.x / 16) - 1, floori(bank.x / 16) + 2):
			if not game.world._chunks.has(Vector2i(x, z)): game.world.make_chunk(x * 16, z * 16)
	game.runtime.grid.add("waterwheel", wheel, game.runtime.key(1)); game.runtime.grid.add("power_pole", bank, game.runtime.key(1)); game.runtime.grid.add("electric_lamp", bank + Vector3(0, 0, 3), game.runtime.key(1))
	game.runtime._add_workshop("sawmill", bank + Vector3(0, 0, -4), game.runtime.key(1)); game.runtime._add_workshop("carpenter", bank + Vector3(3, 0, -4), game.runtime.key(1))
	game.runtime.workshops[1].machine["recipe"] = "sawmill_planks"; game.runtime.workshops[1].machine["input"] = {"log": 5}; game.runtime.workshops[1].machine["output"] = {"plank": 6}
	game.runtime.workshops[2].machine["recipe"] = "wall_kit"; game.runtime.workshops[2].machine["input"] = {"rope": 4}
	game.runtime.grid.motors = [1]
	game.runtime.grid.links = [{"a": "n1", "b": "n2", "owner": game.runtime.key(1), "wire": 1}, {"a": "n2", "b": "n3", "owner": game.runtime.key(1), "wire": 1}, {"a": "n2", "b": "w1", "owner": game.runtime.key(1), "wire": 1}]
	game.runtime.grid.evaluate(game.world, game.runtime.workshops, game.runtime.tribes)
	game.runtime.automation.routes = [{"from": 1, "to": 2, "item": "plank", "owner": game.runtime.key(1), "elapsed": 0.5}]
	game.runtime.energy_visuals.rebuild()
	game.clock.elapsed = 2100; game.world.illuminate(game.clock)
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE; camera.fov = 65; camera.position = bank + Vector3(13, 9, 14); camera.look_at(bank + Vector3(-2, 1, -1))
	await frames(16)
	var extra:Array=[]
	for i in range(4):
		var light:=OmniLight3D.new();game.world.add_child(light);light.global_position=camera.global_position+Vector3(i+1,0,0)
		var uid:String="light-budget-%d"%i;extra.append(uid);game.runtime.energy_visuals.lights[uid]=light;game.runtime.grid.powered[uid]=true
	game.runtime.energy_visuals._left=0;game.runtime.energy_visuals._process(0.3)
	var shown:int=0
	for uid in extra:
		if game.runtime.energy_visuals.lights[uid].visible:shown+=1
	check(shown==2,"Very Low enables two nearest electric lights instead of the first built lights")
	for uid in extra:
		game.runtime.energy_visuals.lights[uid].queue_free();game.runtime.energy_visuals.lights.erase(uid);game.runtime.grid.powered.erase(uid)
	game.runtime.energy_visuals._left=0;await frames(6)
	await capture("river-powered-workshop-night")
	check(game.runtime.grid.powered.get("n3", false), "Night scene lamp has real generator power")
	game.player.position = at; game.hud.show(); game.chat_ui.set_process(true); game.chat_ui.show(); game.hud.show_panel("")
	camera.position = at + Vector3(5, 4, 7); camera.look_at(at + Vector3.UP)
	await capture("vitals-hud-1280x720")
	game.clock.elapsed=450;game.world.illuminate(game.clock)
	game.hud.hide();game.chat_ui.set_process(false);game.chat_ui.hide()
	camera.position=at+Vector3(1.2,1.8,-3.5);camera.look_at(at+Vector3.UP)
	await capture("character-complete-closeup")
	game.player.play_action("mine",3.0)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/settlement/ui/animation"))
	var animation_ok:=true
	for i in range(12):
		await create_timer(0.15).timeout;await RenderingServer.frame_post_draw
		animation_ok=animation_ok and root.get_texture().get_image().save_png("res://builds/settlement/ui/animation/%03d.png"%i)==OK
	check(animation_ok,"Twelve actual articulated mining-animation frames saved")
	var file := FileAccess.open("res://builds/settlement/ui/report.json", FileAccess.WRITE); file.store_string(JSON.stringify({"checks": checks, "failed": failed, "captures": captures, "method": "Actual window input and framebuffer; isolated fixture materials, second player, gallery and powered night scene. ENet separately tests command authority."}, "  ")); file.close()
	print("SETTLEMENT_GUI CHECKS=%d FAILED=%d" % [checks, failed])
	await game.quit_game(0 if failed == 0 else 1, false)
