extends SceneTree
const MainScene = preload("res://Scenes/Main.tscn")
const Store = preload("res://Persistence/Store.gd")
const Controls = preload("res://UI/ControlsPanel.gd")
const MainScript = preload("res://Main.gd")
var checks: int = 0
var failed: int = 0
var game

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var folder := "user://ui-regressions/%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	game = MainScene.instantiate()
	game.save_folder = folder.path_join("world")
	root.add_child(game)
	while not game.ready_world:
		await process_frame
	game.new_game()
	game.set_process(false)
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	var invalid_settings := ConfigFile.new()
	invalid_settings.set_value("video", "quality", {"bad": true})
	invalid_settings.set_value("video", "fps", "not a number")
	invalid_settings.set_value("input", "sensitivity", [0.001])
	invalid_settings.set_value("input", "camera_smoothing", {"bad": true})
	invalid_settings.set_value("video", "vsync", {"bad": true})
	invalid_settings.set_value("audio", "sound", {"bad": true})
	var invalid_path := folder.path_join("invalid-settings.cfg")
	check(invalid_settings.save(invalid_path) == OK, "Malformed preferences are isolated from real user files")
	game.load_settings(invalid_path)
	check(game.quality == 1 and Engine.max_fps == 60 and is_equal_approx(game.sensitivity, 0.003),
		"Wrong numeric preference types fall back without aborting initialization")
	check(game.camera_smoothing and game.vsync and game.sound,
		"Wrong boolean preference types use safe defaults")
	check(MainScript._config_number(INF, 60, 0, 240) == 60 and MainScript._config_number(NAN, 60, 0, 240) == 60,
		"Non-finite numeric preferences cannot reach rendering settings")
	check(MainScript._config_number({"bad": true}, 0, 0, 5) == 0 and MainScript._config_bool([], true),
		"Legacy UI and boolean configuration helpers reject incompatible types")

	# Exercise input before GUI focus navigation consumes arrow keys.
	game.hud.show_panel("controls")
	var panel
	for child in game.hud.column.get_children():
		if child.get_script() == Controls:
			panel = child
	check(panel != null, "Controls panel exists in the real HUD")
	var original_events: Array = InputMap.action_get_events("forward").duplicate()
	InputMap.action_erase_events("forward")
	var initial := InputEventKey.new()
	initial.physical_keycode = KEY_W
	InputMap.action_add_event("forward", initial)
	if panel != null:
		panel.config_path = folder.path_join("controls.cfg")
		await process_frame
		panel.buttons["forward"].grab_focus()
		panel.buttons["forward"].pressed.emit()
		var press := InputEventKey.new()
		press.keycode = KEY_UP
		press.physical_keycode = KEY_UP
		press.pressed = true
		Input.parse_input_event(press)
		await process_frame
		var binding: InputEvent = InputMap.action_get_events("forward")[0]
		check(panel.waiting == "" and binding is InputEventKey and binding.physical_keycode == KEY_UP,
			"Focused button cannot consume the key being rebound")
		var release: InputEventKey = press.duplicate()
		release.pressed = false
		Input.parse_input_event(release)
		InputMap.action_erase_events("forward")
		for event in original_events:
			InputMap.action_add_event("forward", event)
		Controls.load_bindings(panel.config_path)
		binding = InputMap.action_get_events("forward")[0]
		check(binding is InputEventKey and binding.physical_keycode == KEY_UP,
			"Rebound key reloads from the isolated settings file")
	InputMap.action_erase_events("forward")
	for event in original_events:
		InputMap.action_add_event("forward", event)
	game.hud.show_panel("")

	# Every distance must have a continuous handoff between detailed and coarse trees.
	for preset in range(6):
		for distance in [30.0, 55.0, 105.0]:
			var config: Dictionary = game.graphics.DEFAULTS.duplicate(true)
			config["preset"] = preset
			config["view_distance"] = distance
			game.world.apply_graphics(config)
			var tree = game.world.trees[0]
			var end: float = tree.detail_meshes[0].visibility_range_end
			var begin: float = tree.distant_meshes[0].visibility_range_begin
			check(begin <= end and begin < distance and tree.distant_meshes[0].visibility_range_end == distance,
				"No invisible tree band at preset %d distance %.0f" % [preset, distance])
	game.graphics.apply_current(game.world, root, game.player)

	game.chat_ui.open()
	game.hud.show_panel("inventory")
	game.hud.show_panel("")
	check(game.chat_ui.panel.visible and not game.player.enabled,
		"Closing a menu cannot reactivate movement while chat remains open")
	Input.action_press("forward")
	var intent: Dictionary = game.player.input_intent()
	check(intent["move"] == [0.0, 0.0], "Chat blocks actual movement intentions")
	Input.action_release("forward")
	game.chat_ui.hide_chat()
	check(game.player.enabled, "Closing chat restores controls when the journey is active")

	check(game.save_game(), "Saved solo journey is available before connection failure")
	game.player.vitals.hp = 0
	Store.release_lock(game.save_folder)
	game.session.role = "client"
	game._network_failure("simulated connection failure for regression test")
	await process_frame
	await process_frame
	check(not game.running and game.player == null and game.players.is_empty() and game.session.role == "offline",
		"Disconnect clears stale player state and restores the offline session")
	check(game.hud.mode == "menu", "A dead disconnected player cannot trap the main menu in the death screen")
	game.load_game()
	check(game.running and game.player != null and game.player.vitals.hp == 100,
		"Continue restores the saved solo journey after a failed connection")

	print("UI_REGRESSIONS CHECKS=%d FAILED=%d" % [checks, failed])
	game.quit_game(0 if failed == 0 else 1, false)
