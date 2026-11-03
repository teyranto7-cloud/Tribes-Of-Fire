extends SceneTree
## Real rendered menu evidence; use Xvfb/Mesa on machines without a display.
var game
var checks := 0
var failed := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failed += 1; push_error(message)
func capture(name: String) -> void:
	await create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	check(picture != null and not picture.is_empty(), "Viewport renders " + name)
	if picture != null and not picture.is_empty():
		check(picture.save_png("res://builds/screenshots/phase2/" + name + ".png") == OK, "Screenshot saved")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/screenshots/phase2"))
	game = load("res://Scenes/Main.tscn").instantiate()
	game.save_folder = "user://phase2-capture/%d" % OS.get_process_id()
	root.add_child(game)
	while not game.ready_world: await process_frame
	game.localization.select("pt_BR")
	game.new_game(718991)
	game.runtime.command(1, "appearance", preload("res://Character/Appearance.gd").DEFAULT.duplicate(true))
	game.inventory.add("wood", 28); game.inventory.add("stone", 12); game.inventory.add("fiber", 8)
	game.inventory.add("herb", 2); game.inventory.add("berries", 6); game.inventory.add("silver_ingot", 3)
	game.journal.explore(game.session.player_key(1), game.player.position, game.world.descriptor(), 0.5)
	for dimensions in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(960, 540)]:
		root.content_scale_size = Vector2i.ZERO
		root.size = dimensions
		await process_frame
		game.hud.show_panel("inventory")
		await process_frame; await process_frame
		var panel
		for child in game.hud.column.get_children():
			if child.get_script() == preload("res://UI/InventoryPanel.gd"): panel = child
		check(panel != null, "Inventory visible at " + str(dimensions))
		if panel != null:
			check(panel.slot_grid.get_global_rect().end.x <= game.hud.panel.get_global_rect().end.x, "Inventory grid fits menu width")
		await capture("inventory-%dx%d" % [dimensions.x, dimensions.y])
		if panel != null: panel.get_child(0).current_tab = 1
		await capture("crafting-%dx%d" % [dimensions.x, dimensions.y])
		game.hud.show_panel("map")
		await capture("map-%dx%d" % [dimensions.x, dimensions.y])
	print("PHASE2_RENDER CHECKS=%d FAILED=%d renderer=%s" % [checks, failed, RenderingServer.get_video_adapter_name()])
	game.quit_game(0 if failed == 0 else 1, false)
