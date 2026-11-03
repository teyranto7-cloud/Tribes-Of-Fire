extends SceneTree
## Migrate a real local world to a dedicated server, retaining its owner identity.
var game
var stage := "seed"
var start_usec := Time.get_ticks_usec()
var finishing := false
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--qa-stage="): stage = arg.trim_prefix("--qa-stage=")
	call_deferred("start")
func start() -> void:
	game = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(game)
func _process(_delta: float) -> bool:
	if finishing: return false
	if Time.get_ticks_usec() - start_usec > 20000000:
		finishing = true
		printerr("HOST_MIGRATION_FAIL stage=", stage, " timeout")
		if game != null: game.quit_game(1, false)
		else: quit(1)
		return false
	if game == null or not game.ready_world or not game.running: return false
	if stage == "seed" and game.player != null:
		finishing = true
		game.runtime.command(1, "appearance", preload("res://Character/Appearance.gd").DEFAULT.duplicate(true))
		game.inventory.add("wood", 37)
		game.runtime.command(1, "tribe_create", {"name": "Migration tribe"})
		assert(game.runtime.tribes.tribe_of("1") != "")
		assert(game.snapshot().get("host_identity", "").length() == 64)
		print("HOST_MIGRATION_SEED_PASS inventory=37 bound_owner=true")
		game.quit_game()
	elif stage == "server":
		for id in game.players:
			finishing = true
			var key: String = game.session.player_key(id)
			if key != "1" or game.inventories[id].count("wood") != 37 or game.runtime.tribes.tribe_of(key) == "":
				printerr("HOST_MIGRATION_FAIL server key=", key, " inventory=", game.inventories[id].count("wood"))
				game.quit_game(1, false)
			else: finish_server()
	elif stage == "owner" and game.player != null and game.inventory.count("wood") == 37:
		var key: String = game.session.player_key(game.session.local_id)
		if key != "1" or game.runtime.tribes.tribe_of(key) == "": return false
		finishing = true
		print("HOST_MIGRATION_OWNER_PASS inventory=37 tribe=true profile=1")
		game.quit_game()
	return false
func finish_server() -> void:
	await create_timer(2).timeout
	print("HOST_MIGRATION_SERVER_PASS inventory=37 tribe=true profile=1")
	game.quit_game()
