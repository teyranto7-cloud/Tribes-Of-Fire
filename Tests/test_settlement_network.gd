extends SceneTree
## Real ENet commands; fixture materials/positions isolate transactions and wiring.
var game
var server := false
var restoring := false
var role := "merchant"
var port := 24567
var soak_seconds := 0.0
var checks := 0
var failed := 0
var pending_id := 0
var pending := ""
var received := false
var serial := 0
var inspected := 0
var done := false
var latencies:Array=[]
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--soak-seconds="): soak_seconds=float(arg.trim_prefix("--soak-seconds="))
		if arg.begins_with("--port="): port=int(arg.trim_prefix("--port="))
		if arg == "--server": server = true
		elif arg == "--settlement-restore": restoring = true
		elif arg.begins_with("--settlement-role="): role = arg.trim_prefix("--settlement-role=")
	call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failed += 1; push_error(text)
func event(kind: String, data: Dictionary) -> void:
	if server: return
	if kind == "settlement_order":
		print("SETTLEMENT_DELIVERY role=",role," order=",data.get("order",0)," action=",data["action"]," connected=",game.session._client_connected())
		game.request_command(data["action"], data["data"])
		if data.get("duplicate", false): game.request_command(data["action"], data["data"])
	elif kind == "settlement_inspect":
		call_deferred("inspect_client", data)
	elif kind == "settlement_reconnect": call_deferred("reconnect")
	elif kind == "settlement_done" and not done:
		done = true; call_deferred("client_done", data)
func reconnect() -> void:
	await game.return_to_menu();await create_timer(0.2).timeout;game.join_game("127.0.0.1",port)

func inspect_client(data: Dictionary) -> void:
	await create_timer(0.35).timeout
	check(game.runtime.trade_view.size() == int(data["offers"]), "Recipient-filtered trade snapshot")
	check(game.runtime.ping_view.size() == int(data["pings"]), "Recipient-filtered team ping")
	inspected += 1
func client_done(data: Dictionary) -> void:
	await create_timer(0.45).timeout
	for item in data["inventory"]: check(game.inventory.count(item) == int(data["inventory"][item]), "Replicated inventory " + item)
	if not restoring:
		check(inspected > 0, "Privacy inspection actually executed")
		var ally_messages: Array = game.runtime.messages.filter(func(row): return row.get("text") == "SETTLEMENT_ALLIES")
		check((not ally_messages.is_empty()) == (role != "enemy"), "Alliance message authorization")
	check(game.runtime.grid.nodes.size() >= 3 and game.runtime.grid.motors.size() == 1, "Replicated power graph and installed motor")
	print("SETTLEMENT_CLIENT_PASS role=", role, " checks=", checks, " failed=", failed)
	await game.quit_game(0 if failed == 0 else 1, false)
func order(id: int, action: String, data: Dictionary = {}, duplicate: bool = false) -> void:
	pending_id = id; pending = action; received = false; serial += 1
	if action.begins_with("trade_") or action.begins_with("energy_"): data["request_id"] = "settlement-%d" % serial
	game.session.notify(id, "settlement_order", {"action": action, "data": data, "duplicate": duplicate,"order":serial})
	var sent_at:=Time.get_ticks_msec()
	var until := sent_at + 15000
	while not received and Time.get_ticks_msec() < until: await process_frame
	latencies.append(Time.get_ticks_msec()-sent_at)
	if not received: print("ORDER_TIMEOUT order=",serial," peer=",id," action=",action," metrics=",JSON.stringify(game.session.metrics()))
	check(received, "Real client command arrived: " + action)
	await physics_frame; await physics_frame; await create_timer(0.15).timeout
func prepare(at: Vector3) -> void:
	for z in range(floori(at.z / 16) - 1, floori(at.z / 16) + 2):
		for x in range(floori(at.x / 16) - 1, floori(at.x / 16) + 2):
			if not game.world._chunks.has(Vector2i(x, z)): game.world.make_chunk(x * 16, z * 16)
func finish(ids: Array) -> void:
	check(game.save_game(), "Authoritative world persisted")
	for id in ids:
		game.session.notify(id, "settlement_done", {"inventory": game.inventories[id].items})
	await create_timer(1.5).timeout
	print("SETTLEMENT_NETWORK CHECKS=%d FAILED=%d" % [checks, failed])
	await game.quit_game(0 if failed == 0 else 1, false)
func run() -> void:
	create_timer(soak_seconds+110).timeout.connect(func(): push_error("Settlement network deadline"); quit(1))
	game = load("res://Scenes/Main.tscn").instantiate(); root.add_child(game)
	game.session.event_received.connect(event)
	game.session.command_received.connect(func(id, action, _data):
		if id == pending_id and action == pending: received = true)
	while not game.ready_world or not game.running: await process_frame
	if not server:
		while game.player == null or game.player.creation_pending: await process_frame
		var appearance: Dictionary = game.player.appearance.duplicate(true); appearance["name"] = role
		game.request_command("appearance", appearance)
		print("SETTLEMENT_CLIENT_READY ", role); return
	game.server_rules["difficulty"] = "peaceful"
	var ids: Dictionary = {}
	while ids.size() < (1 if restoring else 3):
		for id in game.players:
			var name: String = game.players[id].appearance["name"]
			if name in ["merchant", "buyer", "enemy"]: ids[name] = id
		await process_frame
	var a: int = ids["merchant"]
	if restoring:
		check(game.runtime.grid.nodes.size() == 3 and game.runtime.grid.links.size() == 2 and game.runtime.grid.motors == [0] and game.runtime.automation.routes.size()==1, "Dedicated restart restores graph and automated production route")
		check(game.runtime.exchange.offers.is_empty(), "Restart cannot resurrect completed offers")
		await finish(ids.values()); return
	var b: int = ids["buyer"]; var enemy: int = ids["enemy"]
	for id in ids.values(): game.players[id].set_physics_process(false)
	var body = game.players[a]; var inv = game.inventories[a]
	var start := Vector3(0, game.world.terrain_height(0, 0) + 0.2, 0)
	body.position = start; game.players[b].position = start + Vector3(1.6, 0, 0); game.players[enemy].position = start + Vector3(-3, 0, 0)
	inv.add("wood", 8); game.inventories[b].add("stone", 5)
	await physics_frame; await physics_frame
	var wood: int = inv.count("wood"); var stone: int = game.inventories[b].count("stone")
	await order(a, "trade_offer", {"target": game.runtime.key(b), "give": "wood", "amount": 4, "want": "stone", "quantity": 2}, true)
	check(game.runtime.exchange.offers.size() == 1 and inv.count("wood") == wood, "Duplicate offer is immutable and unpaid until acceptance")
	for id in ids.values(): game.session.notify(id, "settlement_inspect", {"offers": 0 if id == enemy else 1, "pings": 0})
	await create_timer(0.5).timeout
	var uid: String = game.runtime.exchange.offers.keys()[0]
	await order(b, "trade_accept", {"id": uid}, true)
	check(inv.count("wood") == wood - 4 and game.inventories[b].count("stone") == stone - 2 and game.inventories[b].count("wood") == 4, "Real network trade exactly once")
	await order(a,"trade_offer",{"target":game.runtime.key(b),"give":"wood","amount":1,"want":"stone","quantity":1})
	var before_disconnect: Dictionary=inv.items.duplicate()
	var old_peer := b
	game.session.notify(b,"settlement_reconnect",{})
	var deadline := Time.get_ticks_msec()+10000
	while (game.players.has(old_peer) or game.players.values().filter(func(player):return player.appearance["name"]=="buyer").is_empty()) and Time.get_ticks_msec()<deadline: await process_frame
	for candidate in game.players:
		if game.players[candidate].appearance["name"]=="buyer": b=candidate
	ids["buyer"]=b
	check(b!=old_peer and game.players.has(b),"Trade recipient reconnects with a new real peer ID")
	check(game.runtime.exchange.offers.is_empty() and inv.items==before_disconnect,"Disconnect cancels pending offer without losing items")
	game.players[b].set_physics_process(false);game.players[b].position=start+Vector3(1.6,0,0)
	for id in ids.values(): await order(id, "tribe_create", {"name": "Realm " + game.players[id].appearance["name"]})
	var ta: String = game.runtime.tribes.tribe_of(game.runtime.key(a)); var tb: String = game.runtime.tribes.tribe_of(game.runtime.key(b))
	await order(a, "tribe_alliance", {"target": tb}); await order(b, "tribe_accept_alliance", {"target": ta})
	await order(a, "team_ping", {"position": [0, 0]})
	await order(a, "chat", {"channel": "allies", "target": "", "text": "SETTLEMENT_ALLIES"})
	check(game.network_state(enemy)["team_pings"].is_empty() and game.network_state(b)["team_pings"].size() == 1, "Server excludes enemy from ping snapshot")
	for id in ids.values(): game.session.notify(id, "settlement_inspect", {"offers": 0, "pings": 0 if id == enemy else 1})
	var river = game.world.sampler.watershed
	var wheel := Vector3(river.center(50) + river.width(50) * 0.8, game.world.water_level + 1, 50)
	var bank := Vector3(wheel.x + 4, 0, 50); bank.y = game.world.terrain_height(bank.x, bank.z)
	prepare(bank); body.position = bank + Vector3.UP * 0.2; body.yaw = PI / 2; body.rotation.y = PI / 2
	inv.add("waterwheel", 1)
	await physics_frame; await physics_frame
	await order(a, "build", {"piece": "waterwheel", "rotation": 0})
	check(game.runtime.grid.nodes.size() == 1 and inv.count("waterwheel") == 0, "Player builds wheel from a kit near a real river")
	for entry in [["electric_lamp", 0.0], ["power_pole", 5.0]]:
		var at: Vector3 = bank + Vector3(0, 0, entry[1]); at.y = game.world.terrain_height(at.x, at.z)
		body.position = at + Vector3(0, 0.2, 4); body.yaw = 0; body.rotation.y = 0; inv.add(entry[0], 1)
		await physics_frame; await order(a, "build", {"piece": entry[0], "rotation": 0})
	check(game.runtime.grid.nodes.size() == 3, "Player places lamp and pole from kits")
	inv.add("wire", 20); body.position = bank + Vector3.UP * 0.2
	await order(a, "energy_connect", {"a": "n2", "b": "n1"}, true)
	check(game.runtime.grid.links.size() == 1, "Duplicate cable command installs one paid cable")
	game.runtime._add_workshop("sawmill", bank + Vector3(0, 0, -4), game.runtime.key(a)); inv.add("motor", 1)
	body.position = game.runtime.workshops[0].position + Vector3(0, 0.2, 2)
	await physics_frame; await physics_frame
	await order(a, "energy_install", {"station": 0}, true)
	check(inv.count("motor") == 0 and game.runtime.grid.motors == [0], "Motor installation is server-owned and charged once")
	await order(a, "energy_connect", {"a": "w0", "b": "n2"}, true)
	check(game.runtime.grid.links.size() == 2, "Machine wired to generation network")
	game.runtime.grid.evaluate(game.world, game.runtime.workshops, game.runtime.tribes)
	check(game.runtime.grid.powered.get("w0", false), "Network machine receives power")
	var machine = game.runtime.workshops[0]; machine.machine["recipe"] = "sawmill_planks"; machine.machine["input"] = {"log": 1}
	await create_timer(4.5).timeout
	check(int(machine.machine["output"].get("plank", 0)) == 6, "Powered production advances in real server time")
	game.runtime._add_workshop("carpenter",bank+Vector3(3,0,-4),game.runtime.key(a))
	var destination=game.runtime.workshops[1]
	var clear_site:=false
	for offset in [Vector3(3,0,0),Vector3(0,0,-4),Vector3(4,0,-3),Vector3(2,0,-5),Vector3(5,0,1)]:
		destination.position=game.runtime.workshops[0].position+offset
		destination.position.y=game.world.terrain_height(destination.position.x,destination.position.z)
		await physics_frame;await physics_frame
		var ray:=PhysicsRayQueryParameters3D.create(game.runtime.workshops[0].position+Vector3.UP*0.75,destination.position+Vector3.UP*0.75,1,[game.runtime.workshops[0].get_rid(),destination.get_rid()])
		var hit:Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(ray)
		if hit.is_empty():clear_site=true;break
		print("CONVEYOR_FIXTURE_BLOCKED ",hit["collider"].get_class()," at ",hit["position"])
	check(clear_site,"Choose an unobstructed conveyor site on actual generated terrain")
	game.runtime.workshops[1].machine["recipe"]="wall_kit";game.runtime.workshops[1].machine["input"]={"rope":4}
	inv.add("conveyor",1)
	await order(a,"factory_route",{"from":0,"to":1,"item":"plank"},true)
	check(game.runtime.automation.routes.size()==1 and inv.count("conveyor")==0,"One paid conveyor is installed despite a repeated network request")
	await create_timer(10).timeout
	check(int(game.runtime.workshops[1].machine["output"].get("wall_kit",0))==1,"Real-time conveyor feeds carpenter and creates a usable wall kit")
	if soak_seconds>0 and failed==0: await soak(ids)
	await finish(ids.values())

func soak(ids: Dictionary) -> void:
	var start := Time.get_ticks_msec()
	var samples: Array=[]
	for id in ids.values():
		game.inventories[id].add("berries",60);game.inventories[id].add("water",30)
	while float(Time.get_ticks_msec()-start)/1000.0<soak_seconds:
		await create_timer(minf(60.0,soak_seconds-float(Time.get_ticks_msec()-start)/1000.0)).timeout
		for id in ids.values():
			await order(id,"eat",{"item":"berries"});await order(id,"drink",{})
		check(preload("res://Persistence/Store.gd").valid(game.snapshot()),"Long session snapshot valid")
		check(game.save_game(),"Long session save succeeds")
		samples.append({"seconds":float(Time.get_ticks_msec()-start)/1000.0,"memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"nodes":root.get_tree().get_node_count(),"chunks":game.world._chunks.size(),"players":game.players.size(),"hour":game.clock.hour()})
		print("SOAK_SAMPLE ",JSON.stringify(samples[-1]))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/settlement"))
	var file:=FileAccess.open("res://builds/settlement/soak.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"command_roundtrip_ms":latencies,"duration_requested":soak_seconds,"samples":samples,"method":"Real-time dedicated server with three ENet clients; fixtures for materials and frozen player positions. Normal survival, clock, weather, production, network snapshots and saving active; not a human playtest or load test."},"  "));file.close()
