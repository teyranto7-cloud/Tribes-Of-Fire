extends SceneTree
var game
func _initialize() -> void:
	call_deferred("run")
func capture(name: String) -> void:
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	if picture == null or picture.is_empty():
		quit(1)
		return
	picture.save_png("res://builds/screenshots/v5/" + name + ".png")
	print("CAPTURE ", name)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/screenshots/v5"))
	game = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.save_folder = "user://capture-v5-world"
	while not game.ready_world: await process_frame
	game.hud.show_panel("language")
	await capture("01-languages")
	game.localization.select("pt_BR")
	game.hud.show_panel("menu")
	await capture("02-menu")
	game.graphics.choose_preset(2)
	game.graphics.apply_to(game.world,root,game.player)
	game.new_game(718991)
	game.hud.show_panel("character")
	await capture("03-character-creator")
	var data: Dictionary = preload("res://Character/Appearance.gd").DEFAULT.duplicate(true)
	data["name"] = "Arani"
	data["eye_color"] = 4
	data["hair"] = 3
	game.runtime.command(1, "appearance", data)
	game.set_controls(false)
	# Let gravity settle the real character before freezing the inspection pose.
	await create_timer(0.7).timeout
	game.player.set_physics_process(false)
	game.menu_camera.position = game.player.position + Vector3(1.5, 1.4, -3.2)
	game.menu_camera.look_at(game.player.position + Vector3.UP * 0.85)
	game.menu_camera.current = true
	game.clock.elapsed = 800
	await capture("04-custom-character")
	game.hud.show_panel("")
	await capture("05-world-day")
	game.clock.elapsed=2100
	game.world.add_fire(game.player.position+Vector3(1.5,0,-1.5))
	await capture("06-world-night")
	game.clock.elapsed=800
	game.localization.select("pt_BR")
	game.hud.show_panel("settings")
	await capture("05-settings")
	game.hud.show_panel("graphics")
	await capture("06-graphics")
	game.hud.show_panel("inventory")
	await capture("07-inventory")
	game.hud.show_panel("inventory")
	game.inventory.add("wood",30);game.inventory.add("stone",30);game.inventory.add("fiber",30)
	for node in game.hud.column.get_children():
		if node.get_script()==preload("res://UI/InventoryPanel.gd"):node.get_child(0).current_tab=1
	await capture("08-crafting")
	game.hud.show_panel("")
	var z:=100.0;var x:float=game.world.sampler.river_x(z)
	var raft=game.world.add_structure("raft",Vector3(x,game.world.water_level+0.12,z),0,game.runtime.key(1))
	game.player.position=raft.position+Vector3(2,0.5,0);game.runtime._interact(1);game.player._sail(0)
	game.world.update_streaming([game.player.position])
	game.menu_camera.position=raft.position+Vector3(9,7,11);game.menu_camera.look_at(raft.position)
	await create_timer(1).timeout
	await capture("09-river-raft")
	game.menu_camera.position=Vector3(30,62,100);game.menu_camera.look_at(Vector3(0,0,0))
	await capture("10-continent")
	game.hud.show_panel("")
	game.quit_game()
