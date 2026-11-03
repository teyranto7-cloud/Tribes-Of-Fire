extends SceneTree
## Developer capture harness: stages an isolated world for visual review.
## Images are not evidence of performance on target hardware.
const MainScene = preload("res://Scenes/Main.tscn")
const Store = preload("res://Persistence/Store.gd")
var game
var output: String
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	output = ProjectSettings.globalize_path("res://builds/screenshots")
	DirAccess.make_dir_recursive_absolute(output)
	game = MainScene.instantiate()
	root.add_child(game)
	game.save_folder = "user://capture-tests/%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	while not game.ready_world:
		await process_frame
	await capture("01-menu")
	game.new_game()
	game.set_controls(false)
	game.world.add_shelter(Vector3(-4, game.world.height_at(-4, 3), 3))
	game.world.add_fire(Vector3(-4, game.world.height_at(-4, 3.6), 3.6))
	game.clock.elapsed = 800.0
	game.player.yaw = 0.0
	game.player.pitch = -0.20
	await capture("02-day-gameplay")
	game.menu_camera.position = game.player.position + Vector3(0, 1.9, -3.4)
	game.menu_camera.look_at(game.player.position + Vector3.UP * 1.0)
	game.menu_camera.current = true
	await capture("03-character")
	game.menu_camera.position = Vector3(0, 4.0, 0)
	game.menu_camera.look_at(Vector3(-3.5, 2.7, 3))
	game.clock.elapsed = 2120.0
	await capture("04-night-shelter")
	game.clock.elapsed = 1750.0
	game.weather.set_weather("storm")
	game.weather.current = game.weather.PRESETS["storm"].duplicate()
	game.weather.elapsed = 5.0
	await capture("05-storm-shelter")
	game.player.position = Vector3(-4, game.world.height_at(-4, 2.3) + 0.15, 2.3)
	await create_timer(0.3).timeout
	print("CAPTURE_SHELTER_PHYSICS protected=%s" % game.world.is_sheltered(game.player))
	game.menu_camera.position = game.player.position + Vector3(0, 1.65, -3)
	game.menu_camera.look_at(game.player.position + Vector3.UP * 1.0)
	await capture("06-under-roof")
	Store.release_lock(game.save_folder)
	game.running = false
	game.session.close()
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
func capture(label: String) -> void:
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Renderer returned no image: " + label)
		quit(1)
		return
	var error: int = image.save_png(output.path_join(label + ".png"))
	if error != OK:
		push_error("Capture failed: " + error_string(error))
		quit(1)
		return
	print("CAPTURED %s %dx%d" % [label, image.get_width(), image.get_height()])
