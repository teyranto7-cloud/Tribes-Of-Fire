extends SceneTree
## A repeatable fixed-scene renderer sample, never a target-hardware certification.
var game
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Benchmark requires a real rendering display; headless FPS is not a GPU result.")
		quit(1)
		return
	game = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.save_folder = "user://benchmark-%d" % Time.get_ticks_usec()
	while not game.ready_world:
		await process_frame
	game.new_game()
	game.player.set_physics_process(false)
	game.runtime.command(1, "appearance", preload("res://Character/Appearance.gd").DEFAULT.duplicate(true))
	game.hud.show_panel("")
	game.set_controls(false)
	game.menu_camera.position = Vector3(13, 9, 15)
	game.menu_camera.look_at(Vector3(0, 2, -4))
	game.menu_camera.current = true
	game.world.add_fire(Vector3(0, game.world.height_at(0, 0), -2))
	var results: Array = []
	for tier in [0, 2, 4]:
		game.graphics.begin_edit()
		game.graphics.choose_preset(tier)
		game.graphics.pending["fps"] = 0
		game.graphics.pending["vsync"] = false
		game.graphics.preview(game.world, root, game.player)
		for scene in ["day", "night", "storm"]:
			game.clock.elapsed = 2100 if scene == "night" else 800
			game.weather.condition = "storm" if scene == "storm" else "clear"
			game.weather.current = game.weather.PRESETS[game.weather.condition].duplicate()
			await create_timer(1.0).timeout
			var frames: Array[float] = []
			var draw_calls := 0.0
			var cpu := 0.0
			var physics := 0.0
			var memory := 0
			var started := Time.get_ticks_usec()
			var last := started
			while Time.get_ticks_usec() - started < 4000000:
				await RenderingServer.frame_post_draw
				var now := Time.get_ticks_usec()
				frames.append(float(now - last) / 1000)
				last = now
				draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
				cpu += Performance.get_monitor(Performance.TIME_PROCESS) * 1000
				physics += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000
				memory = maxi(memory, OS.get_static_memory_usage())
			var elapsed := float(Time.get_ticks_usec() - started) / 1000000
			frames.sort()
			var result := {"preset": game.graphics.PRESET_NAMES_EN[tier], "scene": scene, "samples": frames.size(), "elapsed_s": elapsed,
				"average_fps": frames.size() / elapsed, "p50_ms": frames[int(frames.size() * 0.5)], "p95_ms": frames[int(frames.size() * 0.95)],
				"average_process_ms": cpu / frames.size(), "average_physics_ms": physics / frames.size(),
				"average_draw_calls": draw_calls / frames.size(), "godot_static_peak_bytes": memory, "gpu_time_ms": null}
			results.append(result)
			print("BENCHMARK ", JSON.stringify(result))
	var report := {"version": ProjectSettings.get_setting("application/config/version"), "godot": Engine.get_version_info()["string"],
		"os": OS.get_name(), "hardware": game.graphics.hardware(), "resolution": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"reference_hardware_verified": false, "method": "Fixed camera, 1 s warmup and 4 s rendering sample per scene, no FPS limit. Short diagnostic sample; GPU timers unavailable.", "results": results}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/reports"))
	var output := FileAccess.open("res://builds/reports/benchmark.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	game.quit_game()
