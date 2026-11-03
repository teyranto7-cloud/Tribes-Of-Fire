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
	picture.save_png("res://builds/screenshots/v3/" + name + ".png")
	print("CAPTURE ", name)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/screenshots/v3"))
	game = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.save_folder = "user://capture-v3-world"
	while not game.ready_world: await process_frame
	game.hud.show_panel("language")
	await capture("01-languages")
	game.localization.select("pt_BR")
	game.hud.show_panel("menu")
	await capture("02-menu")
	game.new_game()
	game.hud.show_panel("character")
	await capture("03-character-creator")
	var data: Dictionary = preload("res://Character/Appearance.gd").DEFAULT.duplicate(true)
	data["name"] = "Arani"
	data["eye_color"] = 4
	data["hair"] = 3
	game.runtime.command(1, "appearance", data)
	game.set_controls(false)
	game.player.set_physics_process(false)
	game.menu_camera.position = game.player.position + Vector3(1.5, 1.4, -3.2)
	game.menu_camera.look_at(game.player.position + Vector3.UP * 0.85)
	game.menu_camera.current = true
	game.clock.elapsed = 800
	await capture("04-custom-character")
	game.localization.select("ja")
	game.hud.show_panel("settings")
	await capture("05-japanese")
	game.hud.show_panel("graphics")
	await capture("06-graphics")
	game.hud.show_panel("inventory")
	await capture("07-inventory")
	game.hud.show_panel("")
	game.quit_game()
