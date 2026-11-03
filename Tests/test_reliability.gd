extends SceneTree
const Scene = preload("res://Scenes/Main.tscn")
const Store = preload("res://Persistence/Store.gd")
const Inventory = preload("res://Core/Inventory.gd")
const Catalog = preload("res://Items/Catalog.gd")
const Session = preload("res://Networking/Session.gd")
var checks: int = 0
var failed: int = 0
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var folder := "user://reliability/%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var game = Scene.instantiate()
	game.save_folder = folder.path_join("world")
	root.add_child(game)
	while not game.ready_world: await process_frame
	game.new_game()
	game.set_process(false)
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.runtime.wildlife.set_process(false)
	for animal in game.runtime.wildlife.animals: animal.set_physics_process(false)
	game.runtime.command(1, "group_create", {"name": "Old group", "kind": "group"})
	check(game.runtime.channel_state["groups"].size() == 1, "Group creation reaches the local client presentation")
	game.new_game()
	game.player.set_physics_process(false)
	await process_frame
	check(game.runtime.channels.groups.is_empty() and game.runtime.channel_state["groups"].is_empty(), "New world removes old groups from both authority and HUD state")
	game.inventory.wear_equipment("hand", 60)
	var selected := -1
	for i in range(36):
		if game.inventory.serialize()["slots"][i].get("id", "") == "axe": selected = i
	game.runtime.command(1, "inventory_drop", {"slot": selected, "amount": 1})
	check(game.runtime.drops.size() == 1 and game.runtime.drops[0].get_meta("durability") == 40, "Real drop carries worn equipment metadata")
	var snapshot: Dictionary = game.snapshot()
	check(Store.valid(snapshot) and Store.save_world(snapshot, game.save_folder) == "", "Worn bag is accepted by the version-three save schema")
	var loaded := Store.load_world(game.save_folder)
	check(loaded["drops"][0].get("durability") == 40, "Worn bag metadata survives checksum and reload")
	game.runtime._restore_drops(loaded["drops"])
	game.runtime.command(1, "interact", {})
	game.runtime._tick_activities(0.6)
	check(game.inventory.count("axe") == 1 and game.inventory.durability["axe"] == 40 and game.runtime.drops.is_empty(), "Picking the actual restored bag cannot repair the axe")
	var invalid := snapshot.duplicate(true)
	invalid["drops"][0]["durability"] = 101
	check(not Store.valid(invalid), "Save rejects out-of-range bag wear")

	var bad_folder := folder.path_join("corrupt")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(bad_folder))
	for name in ["world.a.json", "world.b.json"]:
		var file := FileAccess.open(bad_folder.path_join(name), FileAccess.WRITE)
		file.store_string("damaged snapshot; preserve me")
		file.close()
	var refused := Store.open_world(bad_folder, true)
	check(not refused["error"].is_empty() and refused["data"].is_empty(), "Host refuses existing corrupt slots instead of making a new world")
	check(FileAccess.get_file_as_string(bad_folder.path_join("world.a.json")) == "damaged snapshot; preserve me" and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(bad_folder.path_join(".writer-lock"))), "Corrupt snapshots remain untouched and failed opening releases its own lock")
	var blocked_folder := folder.path_join("blocked")
	check(Store.save_world(snapshot, blocked_folder) == "", "Create a valid lock fixture")
	Store.release_lock(blocked_folder)
	var blocker := ProjectSettings.globalize_path(blocked_folder.path_join(".writer-lock"))
	DirAccess.make_dir_absolute(blocker)
	refused = Store.open_world(blocked_folder, true)
	check(not refused["error"].is_empty() and refused["data"].is_empty(), "Snapshot cannot be selected before acquiring a competing writer lock")
	DirAccess.remove_absolute(blocker)
	var opened := Store.open_world(blocked_folder, false)
	check(opened["error"] == "" and not opened["data"].is_empty(), "World opens after its lock is available")
	Store.release_lock(blocked_folder)

	var full := Inventory.new()
	for id in Catalog.ids(): full.add(id, 1)
	var record: Dictionary = game._player_record(1)
	record["inventory"] = full.items.duplicate()
	record["inventory_state"] = full.serialize()
	var historical := snapshot.duplicate(true)
	historical["players"] = {}
	for i in range(Store.MAX_PLAYERS): historical["players"]["profile_%d" % i] = record.duplicate(true)
	check(Store.valid(historical) and Store.payload_fits(historical), "Maximum legal historical profiles fit the supported persistence budget")
	var large_folder := folder.path_join("large")
	check(Store.save_world(historical, large_folder) == "" and Store.load_world(large_folder).get("players", {}).size() == Store.MAX_PLAYERS, "Large legal history really writes and restores every profile")
	Store.release_lock(large_folder)

	var session := Session.new()
	session.role = "dedicated"
	var token := "a".repeat(64)
	var owner := token.sha256_text()
	session.set_world_owner(owner)
	check(session.profile_key_for_identity(owner) == "1", "Known owner reclaims the host profile on a dedicated server")
	check(session.profile_key_for_identity("b".repeat(64).sha256_text()) != "1", "A guest cannot claim the former host profile")
	check(session.profile_key_for_identity(owner.sha256_text()) != "1", "Sending the public identity hash as a token cannot impersonate its owner")
	session._keys[42] = "1"
	check(session.profile_key_for_identity(owner) == "", "The host profile cannot occupy two simultaneous sessions")
	session._keys.clear()
	session.role = "host"
	check(session.profile_key_for_identity(owner) == "", "An active listen host cannot be duplicated remotely")
	session.role = "dedicated"
	session.set_world_owner("")
	check(session.profile_key_for_identity(owner) == owner, "Legacy unbound worlds never assign host ownership to the first client")
	session.free()

	game.player.set_physics_process(false)
	game.weather.condition = "heavy_rain"
	game.weather.current = game.weather.PRESETS["heavy_rain"].duplicate()
	game.exposure.reset()
	game.player.position = Vector3(0, game.world.height_at(0, 0) + 0.1, 0)
	var old_fps := Engine.max_fps
	var old_steps := Engine.max_physics_steps_per_frame
	Engine.max_fps = 5
	Engine.max_physics_steps_per_frame = 8
	var start := Time.get_ticks_usec()
	game._last_wall_usec = start
	var phase: float = game.clock.elapsed
	game.set_process(true)
	while Time.get_ticks_usec() - start < 3000000: await process_frame
	game.set_process(false)
	var simulated: float = game.clock.elapsed - phase
	var exposed: float = game.exposure.exposure_seconds
	var wall := float(Time.get_ticks_usec() - start) / 1000000
	check(absf(simulated - wall) < 0.35 and absf(exposed - wall) < 0.35, "Day and rain follow monotonic time even when Godot caps process and physics delta at five FPS")
	Engine.max_fps = old_fps
	Engine.max_physics_steps_per_frame = old_steps
	print("RELIABILITY CHECKS=%d FAILED=%d" % [checks, failed])
	await game.quit_game(0 if failed == 0 else 1,false)
