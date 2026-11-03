extends Node
## The same authoritative simulation powers solo, listen host and dedicated server.
const WorldScript = preload("res://World/World.gd")
const PlayerScript = preload("res://Player/Player.gd")
const Inventory = preload("res://Core/Inventory.gd")
const Clock = preload("res://World/Clock.gd")
const WeatherModel = preload("res://Weather/Weather.gd")
const ExposureModel = preload("res://Weather/Exposure.gd")
const Store = preload("res://Persistence/Store.gd")
const HUDScript = preload("res://UI/HUD.gd")
const SessionScript = preload("res://Networking/Session.gd")
const RuntimeScript = preload("res://Game/Runtime.gd")
const Localization = preload("res://Localization/Manager.gd")
const GraphicsSettings = preload("res://Graphics/Settings.gd")
const Journal = preload("res://Game/Journal.gd")
const ServerConfig = preload("res://Networking/ServerConfig.gd")
const Diagnostics = preload("res://Game/Diagnostics.gd")

var world
var player
var hud
var session
var runtime
var localization
var graphics
var diagnostics
var survival
var chat_ui
var inventory = Inventory.new()
var exposure = ExposureModel.new()
var clock = Clock.new()
var weather = WeatherModel.new()
var players: Dictionary = {}
var inventories: Dictionary = {}
var exposures: Dictionary = {}
var saved: Dictionary = {}
var ready_world: bool = false
var running: bool = false
var tool: int = 1
var quality: int = 1
var vsync: bool = true
var sound: bool = true
var sensitivity: float = 0.003
var camera_smoothing: bool = true
var autosave: float = 0.0
var snapshot_timer: float = 0.0
var save_folder: String = "user://world"
var commands: Array[Dictionary] = []
var menu_camera: Camera3D
var world_signature: int = 0
var cli: Dictionary = {}
var smoke_elapsed: float = 0.0
var snapshots_received: int = 0
var auto_appearance_sent: bool = false
var smoke_origin: Vector3
var smoke_seen: bool = false
var smoke_action_sent: bool = false
var smoke_attack_timer: float = 0.0
var smoke_progress: float = 0.0
var smoke_moved: bool = false
var smoke_completed: bool = false
var quitting: bool = false
var settings_manager
var journal = Journal.new()
var server_rules: Dictionary = ServerConfig.defaults()
var build_piece: String = ""
var build_rotation: int = 0
var _stream_timer: float = 0.0
var _journal_timer: float = 0.0
var _startup_error: String = ""
var _last_wall_usec: int = Time.get_ticks_usec()

func _ready() -> void:
	get_tree().auto_accept_quit = false
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		cli[parts[0]] = parts[1] if parts.size() > 1 else "true"
	save_folder = str(cli.get("save-dir", save_folder))
	diagnostics = Diagnostics.new()
	localization = Localization.new()
	settings_manager = get_node("/root/Settings")
	graphics = settings_manager.graphics
	_load_server_rules()
	if cli.has("safe") or cli.has("reset-graphics"):
		graphics.pending = GraphicsSettings.DEFAULTS.duplicate(true)
		graphics.choose_preset(0)
		graphics.pending["fps"] = 30
		graphics.applied = graphics.pending.duplicate(true)
		diagnostics.record("safe_graphics")
	install_inputs()
	load_settings()
	world = WorldScript.new()
	add_child(world)
	session = SessionScript.new()
	session.name = "Session"
	add_child(session)
	session.peer_joined.connect(_spawn_player)
	session.peer_left.connect(_remove_player)
	session.intent_received.connect(_receive_intent)
	session.action_received.connect(func(id: int, action: String): commands.append({"id": id, "action": action}))
	session.state_received.connect(_receive_state)
	session.failed.connect(_network_failure)
	session.admin_requested.connect(_admin_action)
	session.command_received.connect(func(id: int, command: String, data: Dictionary): commands.append({"id": id, "command": command, "data": data}))
	hud = HUDScript.new()
	hud.game = self
	add_child(hud)
	var settings := ConfigFile.new()
	settings.load("user://settings.cfg")
	hud.language = maxi(0, localization.CODES.find(localization.locale))
	menu_camera = Camera3D.new()
	menu_camera.position = Vector3(13, 9, 15)
	add_child(menu_camera)
	menu_camera.look_at(Vector3(0, 2, -4))
	menu_camera.current = true
	await world.generate(Callable(hud, "loading"))
	if quitting:
		return
	graphics.apply_current(world, get_viewport())
	runtime = RuntimeScript.new()
	runtime.name = "Runtime"
	add_child(runtime)
	runtime.configure(self)
	load_audio_levels()
	chat_ui = preload("res://UI/ChatWidget.gd").new()
	add_child(chat_ui)
	chat_ui.configure(self)
	var performance := preload("res://UI/PerformanceOverlay.gd").new()
	add_child(performance)
	performance.configure(self)
	ready_world = true
	saved = Store.load_world(save_folder)
	hud.show_panel("language" if not localization.chosen and DisplayServer.get_name() != "headless" else "menu")
	diagnostics.record("world_ready")
	if cli.has("server") or OS.has_feature("dedicated_server"):
		_start_host(int(server_rules["port"]), true)
		if not running:
			await quit_game(1, false)
			return
	elif cli.has("join"):
		join_game(str(cli["join"]), int(cli.get("port", 24567)), str(cli.get("password", "")))
	elif cli.has("continue"):
		load_game()
	elif cli.has("play"):
		new_game(int(cli.get("seed",-1)))
	print("GAME_READY role=%s Godot=%s" % [session.role, Engine.get_version_info()["string"]])

func install_inputs() -> void:
	var keys := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D,
		"sprint": KEY_SHIFT, "jump": KEY_SPACE, "inventory": KEY_I,
		"menu": KEY_ESCAPE, "save": KEY_F5, "load": KEY_F9,
		"view": KEY_F4, "rotate_build": KEY_R, "world_map": KEY_M, "axe": KEY_1, "build": KEY_2, "shelter": KEY_3, "interact": KEY_E,
		"quick4":KEY_4,"quick5":KEY_5,"quick6":KEY_6,"quick7":KEY_7,"quick8":KEY_8,"quick9":KEY_9,
		"crouch": KEY_C, "dodge": KEY_Q, "heavy": KEY_F, "push_to_talk": KEY_V, "chat": KEY_ENTER}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)
	var backpack_alias := InputEventKey.new()
	backpack_alias.physical_keycode = KEY_TAB
	InputMap.action_add_event("inventory", backpack_alias)
	if not InputMap.has_action("use"):
		InputMap.add_action("use")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("use", click)
	if not InputMap.has_action("block"):
		InputMap.add_action("block")
	var guard := InputEventMouseButton.new()
	guard.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("block", guard)
	preload("res://UI/ControlsPanel.gd").load_bindings()

func _empty_world(seed_value: int = -1) -> Dictionary:
	if seed_value < 0:
		var entropy := Crypto.new().generate_random_bytes(4)
		seed_value = (int(entropy.decode_u32(0)) if entropy.size()==4 else Time.get_ticks_usec()) & 0x7fffffff
	seed_value=seed_value & 0x7fffffff
	var description := {"seed":seed_value,"generator":3,"size":1536}
	var sampler=WorldScript.Terrain.new(description)
	var loot: Array = []
	for place in sampler.locations:
		var at: Vector3=place["position"]+Vector3(1,0,1)
		loot.append({"id":int(place["id"]),"kind":"chest","position":[at.x,at.y,at.z],"rotation":0,"owner":"","hp":100,"open":false,"storage":{"berries":4,"fiber":4,"stone":4}})
	return {"version":4,"seed":seed_value,"world":description,"players":{},"cut":[],"fires":[],"structures":loot,
		"shelters":[],"phase":450.0,"weather":WeatherModel.new().serialize()}

func _begin_authority(data: Dictionary) -> bool:
	var error: String = Store.acquire_lock(save_folder)
	if error != "":
		hud.notify_message(error)
		push_error(error)
		return false
	_clear_players()
	_reset_communication()
	saved = data.duplicate(true)
	world.configure_world(data.get("world", {"seed": 1337, "generator": 0, "size": 128}))
	graphics.apply_current(world, get_viewport())
	journal.records.clear()
	journal.shared_cache.clear()
	world.restore(data)
	runtime.restore(data)
	if not cli.has("server-config"):
		for field in data.get("rules", {}):
			if field in server_rules: server_rules[field] = data["rules"][field]
	clock.day_seconds = float(server_rules["day_minutes"]) * 60
	clock.night_seconds = float(server_rules["night_minutes"]) * 60
	clock.elapsed = float(data.get("phase", 450.0))
	weather.restore(data.get("weather", {}))
	running = true
	_last_wall_usec = Time.get_ticks_usec()
	runtime._activities_usec = _last_wall_usec
	autosave = 0.0
	return true

func new_game(seed_value: int = -1) -> void:
	session.offline()
	if _begin_authority(_empty_world(seed_value)):
		_spawn_player(1)
		if player == null: return
		hud.show_panel("character" if player.creation_pending else "")

func host_game(port: int = 24567, password: String = "") -> void:
	server_rules["password"] = password
	_start_host(port, false)

func _start_host(port: int, dedicated: bool) -> void:
	var opened: Dictionary = Store.open_world(save_folder, true)
	if not opened["error"].is_empty():
		hud.notify_message(opened["error"])
		printerr("PERSISTENCE_REFUSED ", opened["error"])
		return
	var data: Dictionary = opened["data"]
	if data.is_empty():
		data = _empty_world(int(server_rules["seed"]) if cli.has("seed") or cli.has("server-config") else -1)
		server_rules["seed"] = data["seed"]
	if not _begin_authority(data):
		return
	server_rules["port"] = port
	var configuration_error: String = session.configure_server(server_rules, save_folder.path_join("moderation.json"))
	if not configuration_error.is_empty() or not _startup_error.is_empty():
		_network_failure(configuration_error if not configuration_error.is_empty() else _startup_error)
		Store.release_lock(save_folder)
		return
	clock.day_seconds = float(server_rules["day_minutes"]) * 60
	clock.night_seconds = float(server_rules["night_minutes"]) * 60
	var error: int = session.host_game(port, int(server_rules["max_players"]), dedicated)
	if error != OK:
		running = false
		Store.release_lock(save_folder)
		_network_failure(error_string(error))
		return
	session.set_world_owner(str(saved.get("host_identity", "")) if dedicated else session.local_identity_hash())
	if not dedicated:
		_spawn_player(1)
		if player == null: return
	hud.show_panel("character" if player != null and player.creation_pending else "")
	print("SERVER_LISTENING port=%d dedicated=%s" % [port, dedicated])

func join_game(address: String, port: int = 24567, password: String = "") -> void:
	auto_appearance_sent=false
	if running and session.is_authority():
		if not save_game():
			return
		Store.release_lock(save_folder)
	_clear_players()
	_reset_communication()
	running = false
	hud.loading(hud.t("Conectando…", "Connecting…"))
	var error: int = session.join_game(address, port, password)
	if error != OK:
		_network_failure(error_string(error))

func _network_failure(message: String) -> void:
	if diagnostics != null:
		diagnostics.record("network_failure")
	running = false
	commands.clear()
	if session != null:
		session.close()
	_clear_players()
	_reset_communication()
	saved = Store.load_world(save_folder)
	set_controls(false)
	hud.show_panel("menu")
	hud.notify_message(message)
	printerr("NETWORK_FAILURE ", message)

func _clear_players() -> void:
	for body in players.values():
		remove_child(body)
		body.queue_free()
	players.clear()
	inventories.clear()
	exposures.clear()
	if runtime != null:
		runtime.needs.clear()
		runtime.progression.clear()
		runtime.activities.queues.clear()
		runtime.activities.actions.clear()
		runtime.combat.cooldowns.clear()
		runtime.combat.dodge_cooldowns.clear()
		if runtime.mining != null: runtime.mining._cooldowns.clear()
		if runtime.audio != null:
			runtime.audio.step_positions.clear()
			runtime.audio.step_distance.clear()
	player = null
	menu_camera.current = true

func _reset_communication() -> void:
	if runtime != null:
		runtime.reset_local_communication()
	if chat_ui != null:
		chat_ui.reset_session()

func _spawn_player(id: int) -> void:
	if players.has(id) or not running:
		return
	if session.is_authority():
		var known: Dictionary = saved.get("players", {}).duplicate()
		for existing in players:
			known[session.player_key(existing)] = true
		var identity: String = session.player_key(id)
		if not known.has(identity) and (known.size() >= Store.MAX_PLAYERS or not Store.profile_room(snapshot())):
			var reason := "Limite de perfis salvos atingido / Saved player profile limit reached."
			if id == 1:
				Store.release_lock(save_folder)
				_network_failure(reason)
			else:
				session.reject_peer(id, reason)
			return
	var body = PlayerScript.new()
	body.name = "Player_%d" % id
	body.world = world
	body.camera_smoothing = camera_smoothing
	body.authoritative = session.is_authority()
	body.local_control = id == session.local_id and session.role != "dedicated"
	add_child(body)
	body.set_local(body.local_control)
	var record_key: String = session.player_key(id) if session.is_authority() else str(id)
	var record: Dictionary = saved.get("players", {}).get(record_key, {})
	var origin: Array = record.get("position", [float(players.size()) * 1.5, world.terrain_height(float(players.size()) * 1.5, 0) + 0.2, 0])
	body.position = Vector3(origin[0], origin[1], origin[2])
	if record.is_empty() and int(world.descriptor()["generator"]) >= 3: body.position = world.sampler.spawn_point(players.size())
	body.vitals.hp = int(record.get("hp", 100))
	body.set_meta("death_handled", record.get("death_handled",false)==true)
	body.vitals.regen_delay = _config_number(float(cli.get("regen-delay", "6")), 6, 0, 60)
	body.vitals.quiet_seconds = float(record.get("quiet_seconds", 0.0))
	players[id] = body
	inventories[id] = Inventory.new()
	if record.has("inventory"):
		inventories[id].restore(record["inventory"])
	exposures[id] = ExposureModel.new()
	if record.has("exposure"):
		exposures[id].restore(record["exposure"])
	runtime.spawn(id, record)
	journal.restore(session.player_key(id), record.get("journal", {}))
	body.set_meta("key", session.player_key(id))
	body.respawn_position = world.bed_spawn(session.player_key(id))
	graphics.apply_camera(body)
	body.camera.fov = _config_number(settings_manager.read("input","fov",70),70,45,110)
	body.invert_y = _config_bool(settings_manager.read("input","invert_y",false),false)
	body.respawned.connect(func():
		if exposures.has(id):
			exposures[id].reset()
			exposures[id].wetness = 0.0)
	if body.local_control:
		player = body
		inventory = inventories[id]
		exposure = exposures[id]
		survival = runtime.needs[id]
		body.enabled = hud.mode == ""
	print("PLAYER_JOINED id=%d count=%d" % [id, players.size()])
	if session.is_authority():
		runtime.publish_channels.call_deferred()

func _remove_player(id: int) -> void:
	if not players.has(id):
		return
	# Retain disconnected state in the current server snapshot; IDs are session-scoped.
	if session.is_authority():
		if not saved.has("players"):
			saved["players"] = {}
		saved["players"][session.player_key(id)] = _player_record(id)
	var body = players[id]
	var instance: int = body.get_instance_id()
	runtime.combat.cooldowns.erase(instance)
	runtime.combat.dodge_cooldowns.erase(instance)
	runtime.mining._cooldowns.erase(instance)
	runtime.audio.step_positions.erase(id)
	runtime.audio.step_distance.erase(id)
	runtime.channels.disconnected(session.player_key(id))
	runtime.needs.erase(id)
	runtime.progression.erase(id)
	runtime.activities.remove_player(id)
	remove_child(body)
	body.queue_free()
	players.erase(id)
	inventories.erase(id)
	exposures.erase(id)
	if session.is_authority():
		runtime.publish_channels.call_deferred()
	print("PLAYER_LEFT id=%d" % id)

func _receive_intent(id: int, intent: Dictionary) -> void:
	if running and session.is_authority() and players.has(id):
		if not players[id].creation_pending:
			players[id].set_intent(intent)

func _receive_action(id: int, action: String) -> void:
	if not running or not session.is_authority():
		return
	if id == 1 and action.begins_with("weather_") and OS.is_debug_build() and cli.has("developer"):
		weather.set_weather(action.trim_prefix("weather_"))
		return
	if id == 1 and action == "save":
		save_game()
		return
	if not players.has(id):
		return
	var body = players[id]
	var inv = inventories[id]
	if body.creation_pending:
		return
	if body.vitals.hp <= 0:
		return
	match action:
		"attack":
			if inv.equipped_item()=="shovel":
				runtime.command(id,"dig",{});return
			if Inventory.Catalog.tool(inv.equipped_item())=="pickaxe":
				runtime.command(id, "mine", {})
				return
			if inv.equipped_item() != "axe" or world.nearest_tree(body) == null:
				runtime.command(id, "combat", {"kind": "ranged" if inv.equipped_item() == "bow" else "light"})
				return
			runtime.harvest_tree(id)
		"craft_fire":
			runtime.command(id, "craft", {"recipe": "campfire"})
		"craft_shelter":
			runtime.command(id, "craft", {"recipe": "shelter"})
		"place_fire", "place_shelter":
			var kind := "shelter" if action == "place_shelter" else "campfire"
			var place: Dictionary = world.placement(body, kind)
			if place["valid"] and inv.consume(kind, 1):
				if kind == "shelter":
					world.add_shelter(place["position"])
				else:
					world.add_fire(place["position"])

func _player_record(id: int) -> Dictionary:
	var body = players[id]
	var record := {"position": [body.position.x, body.position.y, body.position.z],
		"inventory": inventories[id].items.duplicate(), "hp": body.vitals.hp,
		"quiet_seconds": body.vitals.quiet_seconds, "exposure": exposures[id].state()}
	record.merge(runtime.player_record(id), true)
	record["journal"] = journal.serialize(session.player_key(id))
	record["death_handled"] = body.get_meta("death_handled",false)==true
	return record

func snapshot() -> Dictionary:
	var records: Dictionary = saved.get("players", {}).duplicate(true)
	for id in players:
		records[session.player_key(id)] = _player_record(id)
	var description: Dictionary = world.descriptor()
	var data := {"version": 4, "seed": description["seed"], "world": description, "players": records,
		"rules": _saved_rules(), "structures": world.building_records(), "resource_timers": world.resource_timers.duplicate(), "fire_states": world.fire_states(), "fishing": world.fish_states(), "terrain_changes": world.sampler.changes.duplicate(true), "cut": world.cut_ids(),
		"fires": world.fire_positions(), "shelters": world.shelter_positions(),
		"phase": clock.elapsed, "weather": weather.serialize()}
	data.merge(runtime.save_state(), true)
	var owner: String = session.local_identity_hash() if session.role in ["offline", "host"] else str(saved.get("host_identity", ""))
	if not owner.is_empty():
		data["host_identity"] = owner
	return data

func network_state(recipient_id: int = 0) -> Dictionary:
	if recipient_id == 0 and session.role == "offline": recipient_id = 1
	var bodies: Dictionary = {}
	for id in players:
		var state: Dictionary = players[id].export_state()
		state["key"] = session.player_key(id)
		if id == recipient_id:
			state["inventory"] = inventories[id].items.duplicate()
			state["inventory_state"] = inventories[id].serialize()
			state["survival"] = runtime.needs[id].state()
			state["exposure"] = exposures[id].state()
			state["progression"] = runtime.progression[id].state()
			state["craft_queue"] = runtime.activities.queue(id).duplicate(true)
			state["activity"] = runtime.activities.action_state(id)
			state["is_admin"] = session.is_admin(id)
			state["journal"] = journal.serialize(session.player_key(id))
			state["shared_markers"] = journal.visible_markers(session.player_key(id), runtime.tribes).filter(func(marker): return marker.get("foreign", false))
		bodies[str(id)] = state
	var building_data: Array = world.building_records()
	for record in building_data:
		if not runtime.tribes.can_build(record["owner"], session.player_key(recipient_id)):
			record.erase("storage")
			record.erase("storage_wear")
	var data := {"players": bodies, "world": world.descriptor(), "structures": building_data,
		"resource_timers": world.resource_timers.duplicate(), "fire_states": world.fire_states(), "fishing": world.fish_states(),
		"terrain_changes": world.sampler.changes.duplicate(true), "cut": world.cut_ids(), "fires": world.fire_positions(), "shelters": world.shelter_positions(),
		"phase": clock.elapsed, "weather": weather.serialize(), "rules": _saved_rules()}
	data.merge(runtime.save_state(), true)
	for station in data.get("workshops",[]):
		if not runtime.tribes.can_build(station["owner"],session.player_key(recipient_id)): station.erase("machine")
	data.erase("communication")
	return data

func _receive_state(data: Dictionary) -> void:
	if session.is_authority() or not ready_world:
		return
	snapshots_received += 1
	running = true
	world.configure_world(data.get("world", {"seed": 1337, "generator": 0, "size": 128}))
	var signature: int = hash([data.get("terrain_changes",{}),data["cut"], data["fires"], data["shelters"], data.get("structures", []), data.get("fire_states", []), data.get("fishing", [])])
	if signature != world_signature:
		world.restore(data)
		world_signature = signature
	for field in data.get("rules",{}):
		if field in server_rules: server_rules[field]=data["rules"][field]
	clock.day_seconds=float(server_rules["day_minutes"])*60
	clock.night_seconds=float(server_rules["night_minutes"])*60
	clock.elapsed = float(data["phase"])
	weather.restore(data["weather"])
	runtime.apply_state(data)
	var ids: Array = []
	for key in data["players"]:
		var id := int(key)
		ids.append(id)
		if not players.has(id):
			_spawn_player(id)
		players[id].apply_state(data["players"][key])
		if data["players"][key].has("inventory_state"):
			inventories[id].restore(data["players"][key]["inventory_state"])
		players[id].set_meta("key", data["players"][key].get("key", ""))
		if id == session.local_id:
			session.set_local_profile_key(str(data["players"][key].get("key", "")))
		if id == session.local_id:
			var private: Dictionary = data["players"][key]
			session.local_admin = private.get("is_admin",false)==true
			runtime.needs[id].restore(private.get("survival", {}))
			exposures[id].restore(private.get("exposure", {}))
			runtime.progression[id].restore(private.get("progression", {}))
			runtime.activities.restore(id, private.get("craft_queue", []))
			journal.restore(session.player_key(id), private.get("journal", {}))
			journal.shared_cache[session.player_key(id)] = private.get("shared_markers", [])
	for id in players.keys():
		if not id in ids:
			_remove_player(id)
	if snapshots_received==1:
		smoke_elapsed=0.0;_last_wall_usec=Time.get_ticks_usec()
	if player != null:
		if player.creation_pending:
			if DisplayServer.get_name() == "headless" and not auto_appearance_sent:
				auto_appearance_sent=true
				session.send_command("appearance", PlayerScript.Appearance.DEFAULT.duplicate(true))
			elif DisplayServer.get_name() != "headless" and hud.mode != "character":
				hud.show_panel("character")
		elif hud.mode in ["loading", "character"]:
			hud.show_panel("")

func save_game() -> bool:
	if not running:
		return true
	if not session.is_authority():
		hud.notify_message(hud.t("O servidor salva o mundo.", "The server saves the world."))
		return false
	var data := snapshot()
	var error: String = Store.save_world(data, save_folder)
	if error != "":
		hud.notify_message(error)
		push_error(error)
		diagnostics.record("save_failed", {"reason": error})
		return false
	saved = data
	diagnostics.record("save_complete", {"players": data["players"].size()})
	autosave = 0.0
	hud.notify_message(hud.t("Progresso salvo.", "Progress saved."))
	return true

func load_game() -> void:
	if session.role != "offline":
		hud.notify_message(hud.t("Carregamento manual disponível no modo solo.", "Manual loading is available in solo mode."))
		return
	var opened: Dictionary = Store.open_world(save_folder, false)
	if not opened["error"].is_empty():
		hud.notify_message(opened["error"])
		return
	var data: Dictionary = opened["data"]
	if _begin_authority(data):
		_spawn_player(1)
		if player == null: return
		hud.show_panel("character" if player.creation_pending else "")

func set_controls(active: bool) -> void:
	active = active and running and player != null and not player.creation_pending and player.vitals.hp > 0
	if hud != null:
		active = active and hud.mode == ""
	if chat_ui != null and chat_ui.panel != null:
		active = active and not chat_ui.panel.visible
	if player != null:
		player.enabled = active
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if active and player != null else Input.MOUSE_MODE_VISIBLE
	if world != null and world.preview != null:
		world.preview.hide()

func set_quality(value: int) -> void:
	graphics.begin_edit()
	graphics.choose_preset(clampi(value + 1, 0, 4))
	graphics.apply_to(world, get_viewport(), player)
	quality = clampi(value, 0, 3)

func set_fps(value: int) -> void:
	graphics.begin_edit()
	graphics.set_pending("fps", clampi(value, 0, 240))
	graphics.apply_to(world, get_viewport(), player)

func set_resolution(size: Vector2i) -> void:
	graphics.begin_edit()
	graphics.set_pending("resolution", size)
	graphics.apply_to(world, get_viewport(), player)

func set_sensitivity(value: float) -> void:
	sensitivity = clampf(value, 0.0005, 0.01)
	save_settings()

func save_settings() -> void:
	if settings_manager == null: settings_manager = get_node_or_null("/root/Settings")
	if settings_manager == null: return
	var levels: Dictionary = {}
	for bus in ["Master", "Music", "Ambient", "Effects", "UI", "Vocalizations", "Voice"]:
		var index := AudioServer.get_bus_index(bus)
		if index >= 0: levels[bus] = db_to_linear(AudioServer.get_bus_volume_db(index))
	var sections := {"input": {"sensitivity": sensitivity, "camera_smoothing": camera_smoothing}, "audio": {"sound": sound}, "audio_levels": levels}
	if hud != null: sections["ui"] = {"language": hud.language}
	if not settings_manager.write_sections(sections):
		push_warning(settings_manager.last_error)

func load_settings(path: String = "user://settings.cfg") -> void:
	var config := ConfigFile.new()
	config.load(path)
	quality = clampi(int(graphics.applied.get("preset", 2)) - 1, 0, 3)
	sensitivity = _config_number(config.get_value("input", "sensitivity", 0.003), 0.003, 0.0005, 0.01)
	camera_smoothing = _config_bool(config.get_value("input", "camera_smoothing", true), true)
	vsync = bool(graphics.applied["vsync"])
	sound = _config_bool(config.get_value("audio", "sound", true), true)
	AudioServer.set_bus_mute(0, not sound)
	Engine.max_fps = int(graphics.applied["fps"])

func craft_fire() -> void:
	session.send_action("craft_fire")

func craft_shelter() -> void:
	session.send_action("craft_shelter")

func request_weather(value: String) -> void:
	session.send_action("weather_" + value)

func use_tool() -> void:
	if not build_piece.is_empty():
		request_command("build", {"piece": build_piece, "rotation": build_rotation})
		return
	session.send_action({1: "attack", 2: "place_fire", 3: "place_shelter"}.get(tool, "attack"))

func _unhandled_input(event: InputEvent) -> void:
	if not ready_world or player == null or (event is InputEventKey and event.echo):
		return
	if player.creation_pending:
		return
	if event.is_action_pressed("view") and hud.mode=="":
		player.first_person=not player.first_person
		return
	if event.is_action_pressed("world_map"):
		hud.show_panel("map" if hud.mode == "" else "")
		return
	if event.is_action_pressed("rotate_build") and hud.mode == "":
		build_rotation = (build_rotation + 1) % 4
		return
	if event.is_action_pressed("interact") and hud.mode == "":
		request_command("interact", {})
		return
	if event.is_action_pressed("heavy") and hud.mode == "":
		request_command("combat", {"kind": "heavy"})
		return
	if event.is_action_pressed("menu"):
		hud.show_panel("pause" if hud.mode == "" else "")
	elif event.is_action_pressed("inventory"):
		hud.show_panel("" if hud.mode == "inventory" else "inventory")
	elif event.is_action_pressed("save"):
		save_game()
	elif event.is_action_pressed("load"):
		load_game()
	elif hud.mode == "":
		if event.is_action_pressed("axe"):
			use_quick_slot(0)
		elif event.is_action_pressed("build"):
			use_quick_slot(1)
		elif event.is_action_pressed("shelter"):
			use_quick_slot(2)
		elif event.is_action_pressed("use"):
			use_tool()
		else:
			for i in range(3,9):
				if event.is_action_pressed("quick%d" % (i+1)): use_quick_slot(i)

func _physics_process(delta: float) -> void:
	if not running or quitting:
		return
	if player != null:
		if "sensitivity" in player:
			player.sensitivity = sensitivity
		var intent: Dictionary = player.input_intent()
		if cli.has("smoke-client"):
			var destination := Vector3(3, 0, -1) if str(cli["smoke-client"]) == "2" else Vector3(0, 0, -4)
			var offset := Vector2(destination.x - player.position.x, destination.z - player.position.z)
			var movement := offset.normalized() if offset.length() > 0.3 else Vector2.ZERO
			intent = {"move": [movement.x, movement.y], "yaw": 0.0, "jump": false, "sprint": false}
			smoke_progress += delta
		session.send_intent(intent)
	runtime.tick(delta)
	if session.is_authority():
		while not commands.is_empty():
			var command: Dictionary = commands.pop_front()
			if command.has("command"):
				runtime.command(command["id"], command["command"], command["data"])
			else:
				_receive_action(command["id"], command["action"])

func _process(delta: float) -> void:
	if not ready_world or quitting:
		return
	var now := Time.get_ticks_usec()
	var wall_delta := maxf(0, float(now - _last_wall_usec) / 1000000.0)
	_last_wall_usec = now
	if session.is_authority():
		clock.advance(wall_delta)
		weather.advance(wall_delta)
		if running:
			var state: Dictionary = weather.state()
			world.tick_world(wall_delta, true, bool(state["raining"]))
			for id in players:
				if players[id].vitals.hp<=0 and not players[id].get_meta("death_handled",false): _drop_death_items(id)
				if not players[id].creation_pending:
					runtime.needs[id].advance(wall_delta, players[id].vitals)
					exposures[id].advance(wall_delta, bool(state["raining"]), world.is_sheltered(players[id]), players[id].vitals, world.warmth_at(players[id].position), runtime.safe(id))
	_stream_timer += wall_delta
	_journal_timer += wall_delta
	if _stream_timer >= 0.25:
		_stream_timer = 0.0
		var foci: Array = []
		for id in players:
			if session.is_authority() or id == session.local_id: foci.append(players[id].position)
		if foci.is_empty(): foci.append(Vector3.ZERO)
		world.update_streaming(foci)
	if running and session.is_authority() and _journal_timer >= 0.5:
		for id in players:
			journal.explore(session.player_key(id), players[id].position, world.descriptor(), _journal_timer)
		_journal_timer = 0.0
	world.apply_weather(weather.state())
	world.illuminate(clock)
	_run_cli_checks(wall_delta)
	if not running or quitting:
		return
	if session.is_authority():
		autosave += wall_delta
		snapshot_timer += delta
		if autosave >= 45.0:
			autosave = 0.0
			save_game()
		if snapshot_timer >= 0.1:
			snapshot_timer = 0.0
			for id in session.accepted_peers:
				session.send_snapshot(id, network_state(id))
	world.preview.visible = player != null and hud.mode == "" and (not build_piece.is_empty() or tool in [2, 3]) and (not build_piece.is_empty() or inventory.count("shelter" if tool == 3 else "campfire") > 0)
	if world.preview.visible:
		var place: Dictionary = world.placement(player, build_piece if not build_piece.is_empty() else ("shelter" if tool == 3 else "campfire"), build_rotation)
		world.preview.position = place["position"]
		world.preview.scale = Vector3(3.6, 1, 3.6) if tool == 3 else Vector3.ONE
		world.preview.material_override.albedo_color = Color(0.3, 1, 0.55, 0.45) if place["valid"] else Color(1, 0.25, 0.2, 0.45)

func _run_cli_checks(delta: float) -> void:
	if quitting:
		return
	smoke_elapsed += delta
	if cli.has("smoke-client") and player != null:
		if not smoke_seen:
			smoke_origin = player.position
			smoke_seen = true
		if Vector2(player.position.x - smoke_origin.x, player.position.z - smoke_origin.z).length() > 1.0:
			smoke_moved = true
		if smoke_progress >= 2.0:
			smoke_attack_timer -= delta
			if smoke_attack_timer <= 0.0:
				session.send_action("attack")
				smoke_action_sent = true
				smoke_attack_timer = 0.65
		if smoke_progress > 4 and int(smoke_elapsed*2) != int((smoke_elapsed-delta)*2):
			request_command("interact", {})
		var collected := 0
		for inv in inventories.values():
			collected += inv.count("wood")
		if not smoke_completed and players.size() >= 2 and snapshots_received >= 30 and smoke_moved and smoke_action_sent and not world.cut_ids().is_empty() :
			print("MULTIPLAYER_SMOKE_OK client=%s players=%d snapshots=%d moved=true shared_tree=true wood=%d" % [cli["smoke-client"], players.size(), snapshots_received, collected])
			# Keep the peer present so the other client can verify the same shared state.
			smoke_completed = true
	if cli.has("quit-after-seconds") and smoke_elapsed >= float(cli["quit-after-seconds"]):
		quit_game()
	if cli.has("smoke-client") and smoke_elapsed > 20.0:
		printerr("MULTIPLAYER_SMOKE_FAILED snapshots=%d players=%d moved=%s" % [snapshots_received, players.size(), smoke_moved])
		Store.release_lock(save_folder)
		get_tree().quit(1)

func quit_game(exit_code: int = 0, save_progress: bool = true) -> void:
	if quitting:
		return
	if save_progress and session != null and session.is_authority() and not save_game():
		return
	quitting = true
	if world != null:
		world.cancel_generation()
	save_settings()
	if diagnostics != null:
		diagnostics.record("shutdown", {"role": session.role if session != null else "starting"})
	Store.release_lock(save_folder)
	var audio_playbacks: Array[WeakRef] = []
	_collect_audio_playbacks(self,audio_playbacks)
	if runtime != null:
		if runtime.audio != null: runtime.audio.stop()
		if runtime.voice != null: runtime.voice.stop()
	_stop_audio(self,true)
	if session != null:
		await session.graceful_leave()
	# Let queued emitter deletion and cancellation of an in-flight world
	# generation coroutine finish before checking mixer-owned references.
	await get_tree().process_frame
	# The mixer owns playback references asynchronously. Wait for their actual
	# release instead of assuming a fixed delay is sufficient under CPU load.
	var audio_started := Time.get_ticks_msec()
	var audio_deadline := audio_started+2000
	while audio_playbacks.any(func(playback): return playback.get_ref()!=null) and Time.get_ticks_msec()<audio_deadline:
		await get_tree().create_timer(0.02).timeout
	var audio_pending := audio_playbacks.filter(func(playback): return playback.get_ref()!=null).size()
	if diagnostics != null:
		diagnostics.record("audio_shutdown",{"elapsed_ms":Time.get_ticks_msec()-audio_started,"pending":audio_pending})
	if audio_pending>0: push_warning("Audio mixer did not release %d playback(s) before shutdown deadline." % audio_pending)
	get_tree().quit(exit_code)

func _collect_audio_playbacks(node: Node, playbacks: Array[WeakRef]) -> void:
	if (node is AudioStreamPlayer or node is AudioStreamPlayer3D) and node.has_stream_playback():
		playbacks.append(weakref(node.get_stream_playback()))
	for child in node.get_children(): _collect_audio_playbacks(child,playbacks)

func _stop_audio(node: Node, dispose: bool = false) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer3D:
		if node.has_stream_playback(): node.get_stream_playback().stop()
		node.stop()
		node.stream = null
	for child in node.get_children():
		_stop_audio(child,dispose)
	if dispose and (node is AudioStreamPlayer or node is AudioStreamPlayer3D): node.queue_free()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and session != null:
		quit_game()

func request_command(command: String, data: Dictionary = {}) -> void:
	if command=="craft" and not data.has("request_id"):
		data=data.duplicate(true);data["request_id"]="%d-%d"%[OS.get_process_id(),Time.get_ticks_usec()]
	session.send_command(command, data)

func load_audio_levels() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") != OK: return
	for bus in ["Master", "Music", "Ambient", "Effects", "UI", "Vocalizations", "Voice"]:
		var index := AudioServer.get_bus_index(bus)
		var level: Variant = config.get_value("audio_levels", bus, 1.0)
		if index >= 0 and (level is int or level is float) and is_finite(float(level)):
			AudioServer.set_bus_volume_db(index, linear_to_db(clampf(float(level), 0.0001, 1.0)))

func select_building(kind: String) -> void:
	build_piece = kind
	build_rotation = 0
	hud.show_panel("")

func return_to_menu() -> bool:
	if running and session.is_authority() and not save_game(): return false
	if session.role == "client": await session.graceful_leave()
	else: session.close()
	Store.release_lock(save_folder)
	running = false
	commands.clear()
	_clear_players()
	_reset_communication()
	saved = Store.load_world(save_folder)
	hud.show_panel("menu")
	return true

func _saved_rules() -> Dictionary:
	var result: Dictionary = {}
	for field in ["pvp", "death_loss", "day_minutes", "night_minutes", "resource_rate", "difficulty"]:
		result[field] = server_rules[field]
	return result

func _load_server_rules() -> void:
	if cli.has("server-config"):
		var loaded: Dictionary = ServerConfig.load_file(str(cli["server-config"]))
		_startup_error = loaded["error"]
		if _startup_error.is_empty(): server_rules = loaded["data"]
	for field in ["port", "max-players", "seed"]:
		if cli.has(field): server_rules[field.replace("-", "_")] = int(cli[field])
	for field in ["pvp", "password", "name", "difficulty"]:
		if cli.has(field): server_rules[field] = str(cli[field])
	var normalized: Dictionary = ServerConfig.normalize(server_rules)
	if not normalized["error"].is_empty(): _startup_error = normalized["error"]
	else: server_rules = normalized["data"]

func _admin_action(_id: int, action: String, data: Dictionary) -> void:
	if not session.is_authority(): return
	match action:
		"save": save_game()
		"shutdown": quit_game()
		"set_rule":
			var candidate: Dictionary = server_rules.duplicate(true)
			candidate[str(data.get("rule", ""))] = data.get("value")
			var checked: Dictionary = ServerConfig.normalize(candidate)
			if checked["error"].is_empty():
				server_rules = checked["data"]
				clock.day_seconds = float(server_rules["day_minutes"]) * 60
				clock.night_seconds = float(server_rules["night_minutes"]) * 60
				save_game()

static func _config_number(value: Variant, fallback: float, minimum: float, maximum: float) -> float:
	if not (value is int or value is float) or not is_finite(float(value)): return fallback
	return clampf(float(value), minimum, maximum)
static func _config_bool(value: Variant, fallback: bool) -> bool:
	return value if value is bool else fallback

func _drop_death_items(id: int) -> void:
	var body=players[id]
	body.set_meta("death_handled",true)
	var fraction: float = server_rules.get("death_loss",0.0)
	if fraction<=0: return
	var slots: Array = inventories[id].serialize()["slots"]
	for index in range(slots.size()):
		if slots[index].is_empty() or runtime.drops.size()>=128: continue
		var quantity := ceili(int(slots[index]["count"])*fraction)
		var taken: Dictionary = inventories[id].take_slot(index,quantity)
		if taken.is_empty(): continue
		var at: Vector3=body.position
		at.y=world.terrain_height(at.x,at.z)+0.4
		runtime._add_drop(taken["id"],taken["count"],at,int(taken.get("durability",100)))

func use_quick_slot(index: int) -> void:
	if index < 0 or index >= 9 or player == null or hud.mode != "": return
	var item: String = preload("res://UI/Quickbar.gd").item_for(self,index)
	if inventory.count(item) < 1:
		hud.notify_message(hud.t("Você não possui esse item.","You do not have this item.")); return
	if item in ["campfire","shelter"]:
		tool = 2 if item == "campfire" else 3; build_piece=""; return
	if item == "water": request_command("drink",{}); return
	var slots: Array = inventory.serialize()["slots"]
	for i in range(slots.size()):
		if slots[i].get("id") == item:
			if not Inventory.Catalog.get_item(item).get("equipment_slot","").is_empty():
				request_command("equip",{"slot":i});tool=1;build_piece=""
			else: request_command("eat",{"item":item})
			return
