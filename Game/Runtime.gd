extends Node
const Catalog = preload("res://Items/Catalog.gd")
## Gameplay orchestration. Main keeps the legacy loop; modules own their rules.
const Needs = preload("res://Survival/Survival.gd")
const Tribes = preload("res://Tribes/System.gd")
const Channels = preload("res://Communication/Channels.gd")
const Voice = preload("res://Communication/Voice.gd")
const Appearance = preload("res://Character/Appearance.gd")
const Mining = preload("res://Mining/System.gd")
const Workshop = preload("res://Building/Workshop.gd")
const Combat = preload("res://Combat/Rules.gd")
const Wildlife = preload("res://Animals/Director.gd")
const Audio = preload("res://Audio/Manager.gd")
const Store = preload("res://Persistence/Store.gd")
const Balance = preload("res://Game/Balance.gd")
const Profile = preload("res://Progression/Profile.gd")
const Activities = preload("res://Crafting/Activities.gd")
var progression: Dictionary = {}
var activities = Activities.new()
var tribe_research: Dictionary = {}
var farming: Dictionary = {}
var _fish_cooldowns: Dictionary = {}
var _activities_usec: int = Time.get_ticks_usec()
var game
var building = preload("res://Building/Service.gd").new()
var resource_seed: int = -1
var tribes = Tribes.new()
var channels = Channels.new()
var voice
var needs: Dictionary = {}
var channel_state: Dictionary = {"groups": {}, "calls": {}, "invitation": {}, "blocked": []}
var messages: Array[Dictionary] = []
var mining
var workshops: Array = []
var _workshop_signature: int = 0
var _mine_signature: int = 0
var message_counter: int = 0
var drops: Array = []
var _drop_signature: int = 0
var combat = Combat.new()
var pvp_blocked: int = 0
var pvp_damage: int = 0
var wildlife
var _initial_animals: Array = []
var audio
const PowerGrid = preload("res://Energy/Grid.gd")
var grid = PowerGrid.new()
var automation = preload("res://Building/Automation.gd").new()
var energy_view: String = ""
var energy_visuals
var _energy_left: float = 0
var factory_view: Dictionary = {}
var exchange = preload("res://Trading/Exchange.gd").new()
var team_pings = preload("res://Communication/TeamPings.gd").new()
var trade_view: Array = []
var ping_view: Array = []
signal message_added(data: Dictionary)
func configure(value) -> void:
	game = value
	building.game = game
	game.world.structure_loaded.connect(func(piece):
		var id:=str(piece.structure_id)
		if piece.kind=="garden" and farming.has(id): piece.set_crop(farming[id]["crop"],farming[id]["growth"],farming[id]["water"]))
	energy_visuals = preload("res://Energy/Presentation.gd").new(); energy_visuals.game = game; game.world.add_child(energy_visuals)
	voice = Voice.new()
	add_child(voice)
	voice.configure(game)
	audio = Audio.new()
	add_child(audio)
	audio.configure(game)
	game.session.event_received.connect(_event)
	game.session.voice_requested.connect(_route_voice)
	mining = Mining.new()
	game.world.add_child(mining)
	mining.setup(game.world)
	wildlife = Wildlife.new()
	game.world.add_child(wildlife)
	wildlife.setup(game.world)
	_initial_animals = wildlife.capture().duplicate(true)
	wildlife.damage_requested.connect(_animal_damage)
	var source := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.25
	source.mesh = sphere
	source.position = Vector3(4, game.world.terrain_height(4, 4) + 0.15, 4)
	source.material_override = preload("res://World/Shapes.gd").material(Color("#60a9b0"))
	source.add_to_group("potable_source")
	game.world.add_child(source)

func spawn(id: int, record: Dictionary) -> void:
	needs[id] = Needs.new()
	progression[id] = Profile.new()
	if record.get("progression") is Dictionary: progression[id].restore(record["progression"])
	activities.restore(id, record.get("craft_queue", []))
	activities.requests[id]=record.get("craft_requests",[]).duplicate()
	if record.get("survival") is Dictionary:
		needs[id].restore(record["survival"])
	var body = game.players[id]
	body.auto_respawn = false
	if record.get("appearance") is Dictionary:
		body.set_appearance(record["appearance"])
		body.creation_pending = false
	else:
		body.creation_pending = game.session.role == "dedicated" or (DisplayServer.get_name() != "headless" and game.cli.is_empty())
	body.visible = not body.creation_pending
	if record.get("inventory_state") is Dictionary:
		game.inventories[id].restore(record["inventory_state"])
	body.vitals.regen_block_left = float(record.get("regen_block_left", 0))
	body.respawned.connect(func():
		if needs.has(id):
			needs[id].reset())

func key(id: int) -> String:
	return game.session.player_key(id) if game.session.is_authority() else str(game.players[id].get_meta("key", ""))
func peer(identity: String) -> int:
	for id in game.players:
		if key(id) == identity:
			return id
	return 0
func positions() -> Dictionary:
	var result: Dictionary = {}
	for id in game.players:
		if not game.players[id].creation_pending:
			result[key(id)] = game.players[id].position
	return result
func player_record(id: int) -> Dictionary:
	var result := {"survival": needs[id].state(), "inventory_state": game.inventories[id].serialize(), "regen_block_left": game.players[id].vitals.regen_block_left}
	result["progression"] = progression[id].state() if progression.has(id) else Profile.new().state()
	result["craft_queue"] = activities.queue(id).duplicate(true)
	result["craft_requests"] = activities.requests.get(id,[]).duplicate()
	if not game.players[id].creation_pending:
		result["appearance"] = game.players[id].appearance.duplicate(true)
	return result
func save_state() -> Dictionary:
	var records: Array = []
	for station in workshops:
		records.append({"kind": station.kind, "position": [station.position.x, station.position.y, station.position.z], "owner": station.owner_key, "machine": station.machine.duplicate(true), "building":station.building.duplicate(true)})
	var dropped: Array = []
	for drop in drops:
		dropped.append({"id": drop.get_meta("id"), "count": drop.get_meta("count"), "durability": drop.get_meta("durability", 100), "position": [drop.position.x, drop.position.y, drop.position.z]})
	return {"automation": automation.routes.duplicate(true), "energy_grid": grid.state(), "tribes": tribes.state(), "communication": channels.state(), "mining": mining.capture(), "resource_regrowth": mining.regrowth.duplicate(), "workshops": records, "drops": dropped, "animals": wildlife.capture(), "tribe_research": tribe_research.duplicate(true), "farming": farming.duplicate(true)}
func restore(data: Dictionary) -> void:
	exchange.offers.clear()
	team_pings.entries.clear()
	mining.reposition()
	wildlife.configure_world()
	tribes = Tribes.new()
	tribes.restore(data.get("tribes", {}))
	channels.restore(data.get("communication", {}))
	var resource_state: Array = data.get("mining", [])
	if resource_state.is_empty():
		resource_state.resize(mining.nodes.size())
		resource_state.fill(8)
	mining.restore(resource_state)
	mining.restore_regrowth(data.get("resource_regrowth", []))
	tribe_research = data.get("tribe_research", {}).duplicate(true)
	farming = data.get("farming", {}).duplicate(true)
	_restore_workshops(data.get("workshops", []))
	grid.restore(data.get("energy_grid", {}))
	automation.routes=data.get("automation",[]).duplicate(true)
	grid.evaluate(game.world, workshops, tribes)
	_restore_drops(data.get("drops", []))
	wildlife.restore(data.get("animals", _fresh_animals()), true)
func _restore_workshops(records: Array) -> void:
	while workshops.size()>records.size():workshops.pop_back().queue_free()
	for i in range(records.size()):
		var record:Dictionary=records[i];var p:Array=record["position"]
		var at:=Vector3(p[0],p[1],p[2])
		if i<workshops.size():
			var old=workshops[i]
			if old.kind!=record["kind"] or old.owner_key!=record["owner"] or old.position!=at:
				old.queue_free();var fresh:=Workshop.new();game.world.add_child(fresh)
				fresh.setup(record["kind"],at,record["owner"]);workshops[i]=fresh
		else:_add_workshop(record["kind"],at,record["owner"])
		workshops[i].machine=record.get("machine",preload("res://Building/Factory.gd").empty()).duplicate(true)
		workshops[i].building=record.get("building",{"rotation":0,"revision":1}).duplicate(true)
		workshops[i].rotation.y=int(workshops[i].building.get("rotation",0))*PI*.5

func _add_workshop(kind: String, at: Vector3, owner: String) -> void:
	var station := Workshop.new()
	game.world.add_child(station)
	station.setup(kind, at, owner)
	workshops.append(station)
func apply_state(data: Dictionary) -> void:
	grid.restore(data.get("energy_grid", {}))
	automation.routes=data.get("automation",[]).duplicate(true)
	tribes.restore(data.get("tribes", {}))
	tribe_research = data.get("tribe_research", {}).duplicate(true)
	farming = data.get("farming", {}).duplicate(true)
	_update_crop_visuals()
	wildlife.restore(data.get("animals", []), false)
	var mining_data: Array = data.get("mining", [])
	if hash(mining_data) != _mine_signature:
		mining.restore(mining_data)
		_mine_signature = hash(mining_data)
	var station_data: Array = data.get("workshops", [])
	if hash(station_data) != _workshop_signature:
		_restore_workshops(station_data)
		_workshop_signature = hash(station_data)
	grid.evaluate(game.world, workshops, tribes)
	for index in range(workshops.size()): workshops[index].powered = not index in grid.motors or grid.powered.get("w%d"%index,false)
	var dropped: Array = data.get("drops", [])
	if hash(dropped) != _drop_signature:
		_restore_drops(dropped)
		_drop_signature = hash(dropped)

func _restore_drops(records: Array) -> void:
	for drop in drops:
		drop.queue_free()
	drops.clear()
	for record in records:
		var p: Array = record["position"]
		_add_drop(record["id"], int(record["count"]), Vector3(p[0], p[1], p[2]), int(record.get("durability", 100)))
func _add_drop(item: String, count: int, at: Vector3, wear: int = 100) -> void:
	var drop := RigidBody3D.new()
	drop.mass = 0.3
	drop.collision_layer = 8
	drop.collision_mask = 1
	drop.freeze = not game.session.is_authority()
	drop.position = at
	drop.set_meta("id", item)
	drop.set_meta("count", count)
	drop.set_meta("durability", clampi(wear, 0, 100))
	game.world.add_child(drop)
	var shapes = preload("res://World/Shapes.gd")
	var definition:=Catalog.get_item(item)
	var model=load(definition.get("pickup_model","res://Items/WorldPickup.gd"))
	model.build(drop,definition)
	var label:=Label3D.new();label.text=Catalog.display_name(item)+" ×%d"%count;label.position.y=0.65
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.font_size=24;label.pixel_size=0.006;label.visibility_range_end=8;drop.add_child(label)
	var collision := SphereShape3D.new()
	collision.radius = 0.18
	shapes.collider(drop, collision, Vector3.UP * 0.2)
	drops.append(drop)
func stations(body) -> Array:
	var result: Array = []
	if game.world.warmth_at(body.position):
		result.append("campfire")
	for station in workshops:
		if _station_accessible(int(game.players.find_key(body)),station):
			result.append_array(Catalog.station(station.kind).get("provides",[station.kind]))
	return result
func tick(delta: float) -> void:
	wildlife.tick(delta, game.players, game.session.is_authority())
	if game.session.is_authority():
		team_pings.advance(delta, positions().keys())
		exchange.expire(positions().keys(), Time.get_unix_time_from_system())
		var now := Time.get_ticks_usec()
		var activity_delta := maxf(0, float(now - _activities_usec) / 1000000.0)
		_activities_usec = now
		_tick_activities(activity_delta)
		_tick_drop_physics()
		mining.tick_regrowth()
		_tick_farming(activity_delta)
		_energy_left -= delta
		if _energy_left <= 0: _energy_left = 0.25; grid.evaluate(game.world, workshops, tribes)
		for index in range(workshops.size()):
			var station = workshops[index]
			station.powered = not index in grid.motors or grid.powered.get("w%d"%index,false)
			if station.powered: preload("res://Building/Factory.gd").advance(station.machine,station.kind,activity_delta * (1.5 if index in grid.motors else 1.0))
		automation.advance(activity_delta,workshops,grid,tribes)
		combat.tick(delta)
		for id in needs:
			if game.players.has(id) and not game.players[id].creation_pending:
				game.players[id].set_equipment(game.inventories[id].equipment)

func reset_local_communication() -> void:
	exchange.offers.clear()
	trade_view.clear()
	team_pings.entries.clear()
	team_pings.cooldowns.clear()
	ping_view.clear()
	channel_state = {"groups": {}, "calls": {}, "invitation": {}, "blocked": []}
	messages.clear()
	message_counter = 0
	channels = Channels.new()
	tribes = Tribes.new()
	progression.clear()
	activities = Activities.new()
	_fish_cooldowns.clear()
	_activities_usec = Time.get_ticks_usec()
	if voice != null:
		voice.stop()
func safe(id: int) -> bool:
	return needs.has(id) and needs[id].is_safe() and game.players[id].attack_time <= 0 and not game.players[id].blocking and game.players[id].dodging <= 0
func command(id: int, action: String, data: Dictionary) -> void:
	if not game.session.is_authority() or not game.running or not game.players.has(id):
		return
	var body = game.players[id]
	var inv = game.inventories[id]
	var identity := key(id)
	if action in ["inventory_move", "inventory_drop"] and data.has("expected"):
		var slot_index := int(data.get("from", -1) if action == "inventory_move" else data.get("slot", -1))
		var slots: Array = inv.serialize()["slots"]
		if slot_index < 0 or slot_index >= slots.size() or slots[slot_index].get("id", "") != data["expected"].get("id", "") or int(slots[slot_index].get("count", 0)) != int(data["expected"].get("count", -1)):
			_notify(id, false)
			return
	building.last_error=""
	var receipt := ""
	if action in ["station_move","build","structure_edit","craft_cancel","station_select","station_load","station_refund","factory_load","factory_take","trade_offer","trade_accept","trade_cancel","energy_connect","energy_disconnect","energy_toggle","energy_install","factory_route","factory_unroute"]:
		receipt=Activities.operation_receipt(action,str(data.get("request_id","")))
		if not receipt.is_empty() and receipt in activities.requests.get(id,[]): return
	var accepted := false
	if action == "appearance":
		if not Appearance.valid(data) or str(data.get("name", "")).to_lower() in ["admin", "server", "system"]:
			_notify(id, false)
			return
		body.set_appearance(data)
		body.creation_pending = false
		body.show()
		if id == game.session.local_id:
			game.hud.show_panel("")
		accepted = true
	elif body.creation_pending:
		return
	elif action.begins_with("tribe_"):
		if action in ["tribe_invite", "tribe_kick", "tribe_leader"] and peer(str(data.get("target", ""))) == 0:
			return
		var before := tribes.state()
		accepted = tribes.command(identity, action, data)
		if accepted and not Store.payload_fits(game.snapshot()):
			tribes.restore(before)
			accepted = false
		if accepted and action in ["tribe_war","tribe_break_alliance","tribe_accept_peace","tribe_accept_alliance"]:
			for recipient in game.players:game.session.notify(recipient,"notice",{"key":tribes.tribes.get(tribes.tribe_of(identity),{}).get("name","")+" · "+action.trim_prefix("tribe_")})
		publish_channels()
	elif action.begins_with("group_") or action.begins_with("call_") or action == "block":
		var before := channels.state()
		var before_calls: Dictionary = channels.calls.duplicate(true)
		var before_invites: Dictionary = channels.invitations.duplicate(true)
		accepted = channels.command(identity, action, data, positions().keys(), tribes)
		if accepted and not Store.payload_fits(game.snapshot()):
			channels.restore(before)
			channels.calls = before_calls
			channels.invitations = before_invites
			accepted = false
		publish_channels()
	elif action == "chat":
		var text := str(data.get("text", "")).strip_edges()
		if game.session.is_muted(id) or not channels.allow_text(identity, text):
			_notify(id, false)
			return
		var channel := str(data.get("channel", "global"))
		var targets := channels.recipients(identity, channel, str(data.get("target", "")), positions(), tribes)
		for recipient in targets:
			game.session.notify(peer(recipient), "chat", {"sender": body.appearance["name"], "key": identity, "channel": channel, "text": text, "timestamp": Time.get_unix_time_from_system()})
		return
	elif action == "respawn" and body.vitals.hp <= 0:
		body.respawn_position = game.world.bed_spawn(identity)
		body.respawn()
		accepted = true
	elif body.vitals.hp <= 0:
		return
	else:
		match action:
			"factory_route", "factory_unroute":
				var source: int=data["from"]
				if source>=0 and source<workshops.size() and _station_accessible(id,workshops[source]):
					if action=="factory_route": accepted=automation.add(source,int(data["to"]),data["item"],identity,inv,workshops,tribes,game.world)
					else: accepted=automation.remove(source,int(data["to"]),data["item"],identity,inv,tribes)
			"energy_connect", "energy_disconnect", "energy_toggle", "energy_install": accepted = _energy_command(id, action, data)
			"team_ping":
				accepted = team_pings.create(identity, Vector2(data["position"][0], data["position"][1]), body.position, game.journal.serialize(identity), tribes, Time.get_unix_time_from_system())
			"trade_offer", "trade_accept", "trade_cancel": accepted = _trade_command(id, action, data)
			"combat":
				var kind := str(data.get("kind", "light"))
				if kind == "light" and inv.equipped_item() == "bow":
					kind = "ranged"
				if kind in ["light", "heavy", "ranged"]:
					var result: Dictionary = combat.try_attack(body, inv, kind == "heavy", kind == "ranged")
					if result.get("ok", false):
						var target_body = combat.select_target(body, game.players.values() + wildlife.animals, float(result["range"]))
						if target_body != null:
							if target_body in wildlife.animals:
								wildlife.hit(target_body, int(result["damage"]), id)
							else:
								var target_id: int = game.players.find_key(target_body)
								if (game.server_rules["pvp"] == "on" or (game.server_rules["pvp"]=="war" and tribes.at_war(tribes.tribe_of(identity),tribes.tribe_of(key(target_id))))) and tribes.can_damage(identity, key(target_id)):
									var dealt: int = Combat.mitigate(int(result["damage"]), game.inventories[target_id], target_body.blocking, target_body.dodging > 0)
									target_body.vitals.damage(dealt)
									pvp_damage += dealt
								else:
									pvp_blocked += 1
						accepted = true
			"eat":
				var item:=str(data.get("item","berries"))
				var stats:Dictionary=Catalog.get_item(item).get("statistics",{})
				if float(stats.get("heal",0))>0:
					if body.vitals.hp<100 and inv.consume(item,1):
						body.vitals.hp=mini(100,body.vitals.hp+int(stats["heal"]));accepted=true
						if float(stats.get("thirst",0))>0:needs[id].drink(float(stats["thirst"]))
				else: accepted = needs[id].eat(inv,item)
				if accepted: body.play_action("eat",0.9)
			"cook": accepted = _enqueue_craft(id, "cooked_meat")
			"drink":
				if inv.count("water") > 0 and needs[id].thirst < 100:
					if inv.transact({"water":1},{"water_container":1}):accepted = needs[id].drink()
				else:
					for source in get_tree().get_nodes_in_group("potable_source"):
						if source.global_position.distance_to(body.position) < 3 and _clear_interaction(body, source.global_position + Vector3.UP * 0.2):
							accepted = needs[id].drink()
			"craft": accepted = _enqueue_craft(id, str(data.get("recipe", "")), str(data.get("request_id", "")))
			"equip": accepted = inv.equip(int(data.get("slot", -1)))
			"unequip": accepted = inv.unequip(str(data.get("equipment", "hand")))
			"inventory_sort": accepted = inv.organize()
			"inventory_move": accepted = inv.move_slot(int(data.get("from", -1)), int(data.get("to", -1)), int(data.get("amount", 9999)))
			"interact": accepted = _interact(id)
			"craft_cancel": accepted = activities.cancel(id, int(data.get("index", -1)), inv, str(data.get("job_uid","")))
			"research": accepted = _research(id, str(data.get("technology", "")))
			"repair": accepted = _repair(id, int(data.get("slot", -1)))
			"chest_transfer": accepted = _chest_transfer(id, data)
			"refuel": accepted = _refuel(id)
			"plant": accepted = _plant(id, int(data.get("structure", -1)), str(data.get("crop", "")))
			"harvest_crop": accepted = _harvest_crop(id, int(data.get("structure", -1)))
			"fish": accepted = _fish(id)
			"tame": accepted = wildlife.tame(body, inv, identity)
			"map_mark", "map_remove": accepted = game.journal.command(identity, action, data, tribes)
			"inventory_drop":
				if drops.size() < 128:
					var taken: Dictionary = inv.take_slot(int(data.get("slot", -1)), int(data.get("amount", 1)))
					if not taken.is_empty():
						var at: Vector3 = body.position - body.global_basis.z
						at.y = game.world.terrain_height(at.x, at.z) + 0.1
						_add_drop(taken["id"], taken["count"], at, int(taken.get("durability", 100)))
						accepted = true
			"factory_load", "factory_take", "station_refund": accepted = _factory_command(id,action,int(data["station"]))
			"station_load": accepted = _factory_command(id,"factory_load",int(data["station"]),int(data["amount"]))
			"station_select": accepted = _select_station_recipe(id,int(data["station"]),str(data["recipe"]))
			"dig": accepted = _start_dig(id)
			"mine": accepted = _start_mining(id, false)
			"station_move": accepted = building.move_station(id,data)
			"structure_edit": accepted = building.edit(id,data)
			"build":
				var kind := str(data.get("piece", ""))
				if kind in PowerGrid.KINDS:
					accepted = _build_energy(id,kind)
					if accepted: activities.remember_request(id,receipt)
					_notify(id,accepted); return
				if preload("res://Building/Catalog.gd").known(kind):
					accepted=building.build(id,kind,int(data.get("rotation",0)),data.get("options",{}))
					if accepted:
						activities.remember_request(id,receipt); body.play_action("build",.75); progression[id].award("building",8); game.journal.record_event(identity,"build")
					_notify(id,accepted); return
				var cost: Dictionary = Balance.section("building").get("costs", {}).get(kind, {})
				for item in Catalog.ids():
					if Catalog.get_item(item).get("place","")==kind and inv.count(item)>0:cost={item:1};break
				if not cost.is_empty():
					var site: Dictionary = game.world.placement(body, kind, int(data.get("rotation", 0)),data.get("options",{}))
					if site["valid"] and _territory_allows(identity, site["position"]) and (not Catalog.station_ids().has(kind) or workshops.size()<32) and inv.transact(cost, {}):
						if Catalog.station_ids().has(kind):
							_add_workshop(kind,site["position"],identity)
							workshops[-1].machine["recipe"]=str(Catalog.station(kind)["default_recipe"])
							workshops[-1].building["rotation"]=int(data.get("rotation",0)); workshops[-1].rotation.y=int(data.get("rotation",0))*PI*.5
						else: game.world.add_structure(kind, site["position"], int(data.get("rotation",0)), identity)
						body.play_action("build", 0.75)
						progression[id].award("building", Balance.number("progression", "build_xp", 8))
						game.journal.record_event(identity, "build")
						accepted = true
	if accepted:
		activities.remember_request(id,receipt)
		var sound: String = {"craft": "craft", "build": "build", "mine": "stone", "interact": "pickup", "combat": "combat"}.get(action, "pickup")
		emit_sound(sound, body.position)
	_notify(id, accepted)
func _notify(id: int, accepted: bool) -> void:
	game.session.notify(id, "notice", {"key": "Action completed" if accepted else (preload("res://Building/Catalog.gd").reason(building.last_error) if not building.last_error.is_empty() else "Action unavailable")})

func _trade_command(id: int, action: String, data: Dictionary) -> bool:
	var identity := key(id)
	if action == "trade_cancel": return exchange.cancel(identity, str(data["id"]))
	var other_key := str(data.get("target", ""))
	if action == "trade_accept":
		var offer: Dictionary = exchange.offers.get(str(data["id"]), {})
		if offer.is_empty() or offer["to"] != identity: return false
		other_key = offer["from"]
	var other := peer(other_key)
	if other == 0 or other == id or game.players[other].vitals.hp <= 0 or game.players[other].creation_pending: return false
	if identity in channels.blocked.get(other_key, []) or other_key in channels.blocked.get(identity, []): return false
	if game.players[id].position.distance_to(game.players[other].position) > 6.0 or not _clear_interaction(game.players[id], game.players[other].position + Vector3.UP, [game.players[other].get_rid()]): return false
	if action == "trade_offer":
		return exchange.create(identity, other_key, data["give"], int(data["amount"]), data["want"], int(data["quantity"]), game.inventories[id], Time.get_unix_time_from_system())
	var accepted: bool = exchange.accept(identity, str(data["id"]), game.inventories[other], game.inventories[id], Time.get_unix_time_from_system())
	if accepted: game.session.notify(other, "notice", {"key": "Trade completed"})
	return accepted

func _clear_interaction(body, at: Vector3, exclude: Array = []) -> bool:
	var query := PhysicsRayQueryParameters3D.create(body.global_position + Vector3.UP, at, 1, [body.get_rid()] + exclude)
	return game.world.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
func publish_channels() -> void:
	for id in game.players:
		game.session.notify(id, "channels", channels.public_state(key(id)))
func _event(kind: String, data: Dictionary) -> void:
	if game.quitting: return
	if kind=="energy":
		energy_view = str(data.get("id", "")); game.hud.show_panel("energy"); return
	if kind=="factory":
		var changed:bool=factory_view.get("station",-1)!=data.get("station",-1)
		factory_view=data.duplicate(true)
		if changed or game.hud.mode!="factory": game.hud.show_panel("factory")
		return
	if kind == "chat":
		messages.append(data)
		message_counter += 1
		if messages.size() > 200:
			messages.pop_front()
		message_added.emit(data)
		audio.click()
	elif kind == "admin":
		game.hud.notify_message(TranslationServer.translate("Action completed" if data.get("ok",false) else "Action unavailable"))
	elif kind == "storage":
		channel_state["storage"] = data
		if game.hud.mode != "storage": game.hud.show_panel("storage")
	elif kind == "channels":
		var storage: Dictionary = channel_state.get("storage", {})
		channel_state = data.duplicate(true)
		if not storage.is_empty(): channel_state["storage"] = storage
	elif kind == "notice":
		game.hud.notify_message(game.localization.text(str(data["key"])))
	elif kind == "sound":
		var p: Array = data["position"]
		audio.play(data["kind"], Vector3(p[0], p[1], p[2]))
func _route_voice(id: int, sequence: int, packet: PackedByteArray, channel: String, target: String) -> void:
	if not game.session.is_authority() or not game.running or not game.players.has(id) or game.players[id].creation_pending or game.players[id].vitals.hp <= 0:
		return
	if preload("res://Communication/ADPCM.gd").decode(packet).is_empty():
		return
	for recipient in channels.recipients(key(id), channel, target, positions(), tribes, true):
		var destination := peer(recipient)
		if destination != 0 and destination != id:
			game.session.relay_voice(destination, id, sequence, packet, channel)

func _animal_damage(id: int, amount: int) -> void:
	if game.session.is_authority() and game.players.has(id):
		if game.server_rules.get("difficulty","normal")=="peaceful": return
		var body = game.players[id]
		body.vitals.damage(Combat.mitigate(clampi(amount, 0, 20), game.inventories[id], body.blocking, body.dodging > 0))
		emit_sound("damage", body.position)

func emit_sound(kind: String, at: Vector3) -> void:
	for id in game.players:
		if game.players[id].position.distance_to(at) <= 24:
			game.session.notify(id, "sound", {"kind": kind, "position": [at.x, at.y, at.z]})

func harvest_tree(id: int) -> bool:
	if not game.players.has(id) or activities.actions.has(id): return false
	var body = game.players[id]
	if Catalog.tool(game.inventories[id].equipped_item()) != "axe": return false
	var tree = game.world.nearest_tree(body)
	if tree == null or not body.attack(): return false
	var duration := Balance.number("gathering", "tree_action_seconds", 0.65)
	if not activities.start_action(id,"tree",duration,{"tree":tree.tree_id}): return false
	body.play_action("gather",duration)
	emit_sound("wood",body.position)
	return true

func _tick_activities(delta: float) -> void:
	for id in activities.queues.keys():
		if not game.players.has(id) or game.players[id].vitals.hp<=0: continue
		var entries: Array = activities.queues[id]
		if entries.is_empty(): continue
		var job: Dictionary = entries[0]
		var definition: Dictionary = preload("res://Items/Catalog.gd").recipe(job["recipe"])
		var required: String = definition.get("station","hand")
		if required != "hand" and not required in stations(game.players[id]): continue
		job["remaining"] = maxf(0,float(job["remaining"])-delta)
		if job["remaining"]<=0 and game.inventories[id].add_many(definition["outputs"]):
			entries.pop_front()
			progression[id].award("cooking" if job["recipe"] in ["cooked_meat","cooked_fish"] else "crafting",Balance.number("progression","cook_xp" if job["recipe"] in ["cooked_meat","cooked_fish"] else "craft_xp",5))
			game.journal.record_event(key(id),"craft")
			emit_sound("craft",game.players[id].position)
	for id in activities.actions.keys():
		if not game.players.has(id) or game.players[id].vitals.hp<=0:
			activities.actions.erase(id); continue
		var job: Dictionary = activities.actions[id]
		job["remaining"] = maxf(0,float(job["remaining"])-delta)
		if job["remaining"]>0: continue
		activities.actions.erase(id)
		var body = game.players[id]
		var inv = game.inventories[id]
		var meta: Dictionary = job["metadata"]
		match job["kind"]:
			"dig":
				var target:Vector3=meta["position"]
				if inv.equipped_item()=="shovel" and body.position.distance_to(target)<4 and inv.can_add("soil",1) and game.world.dig(target):
					inv.add("soil",1);inv.wear_equipment("hand",1);body.stamina=maxf(0,body.stamina-8)
			"tree":
				var tree = game.world.nearest_tree(body)
				if tree == null or tree.tree_id != meta["tree"] or Catalog.tool(inv.equipped_item())!="axe" or drops.size()>=128: continue
				var loot:Dictionary=Catalog.database()["trees"][tree.species]["outputs"]
				if drops.size()+loot.size()>128:continue
				var power:int=Catalog.harvest_power(inv.equipped_item())
				inv.wear_equipment("hand",1)
				if tree.hit(power):
					game.world.record_tree_cut(tree.tree_id)
					for item in loot:_add_drop(item,maxi(1,roundi(int(loot[item])*float(game.server_rules["resource_rate"]))),tree.position+Vector3.UP*0.3)
					progression[id].award("gathering",Balance.number("progression","gather_xp",4))
					game.journal.record_event(key(id),"gather",4)
			"pickup":
				for drop in drops:
					if drop.get_instance_id()!=int(meta["drop"]) or body.position.distance_to(drop.position)>2.8 or not _clear_interaction(body,drop.position+Vector3.UP*0.2): continue
					if inv.add(drop.get_meta("id"),drop.get_meta("count"),drop.get_meta("durability",100)):
						drops.erase(drop);drop.queue_free();emit_sound("pickup",body.position)
					break
			"mine":
				var index: int = int(meta["resource"])
				if drops.size()<128 and mining.mine(body,inv,index,bool(meta["hand"]),true):
					_add_drop(mining.resource_kind(index),1,mining.nodes[index].position+Vector3.UP*0.4)
					progression[id].award("gathering",Balance.number("progression","gather_xp",4))
			"corpse":
				var animal = wildlife.animals[int(meta["animal"])]
				if animal.hp>0 or animal.harvested or body.position.distance_to(animal.position)>3 or not _clear_interaction(body,animal.position+Vector3.UP*0.6,[animal.get_rid()]): continue
				var loot: Dictionary = wildlife.Animal.SPECIES[animal.species]["loot"]
				if drops.size()+loot.size()>128: continue
				animal.harvested=true;animal.hide()
				for item in loot: _add_drop(item,int(loot[item]),animal.position+Vector3.UP*0.3)
				progression[id].award("hunting",Balance.number("progression","hunt_xp",10))
				game.journal.record_event(key(id),"hunt")
			"fish":
				var fish_id:=int(meta.get("fish",-1))
				if fish_id>=0 and fish_id<game.world.fishes.size() and _near_water(body) and inv.equipped_item()=="spear" and body.position.distance_to(game.world.fishes[fish_id].position)<7 and game.world.fishes[fish_id].stock>0 and inv.add("raw_fish",1):
					game.world.fishes[fish_id].take()
					progression[id].award("fishing",Balance.number("progression","fishing_xp",6))
					game.journal.record_event(key(id),"fish")

func _enqueue_craft(id: int, recipe: String, request_id: String = "") -> bool:
	var definition: Dictionary = preload("res://Items/Catalog.gd").recipe(recipe)
	if definition.is_empty(): return false
	var reason:=craft_reason(id,recipe)
	if not reason.is_empty():
		game.session.notify(id,"notice",{"key":reason})
		return false
	if not activities.enqueue(id,recipe,game.inventories[id],request_id): return false
	game.players[id].play_action("craft",float(definition.get("time",2.5)))
	return true
func known_technologies(id: int) -> Array:
	if not progression.has(id): return []
	var result: Array = progression[id].learned.duplicate()
	for technology in tribe_research.get(tribes.tribe_of(key(id)),[]):
		if not technology in result: result.append(technology)
	return result
func _research(id: int, technology: String) -> bool:
	var definitions: Dictionary = Profile.technologies()
	if not definitions.has(technology) or technology in known_technologies(id) or stations(game.players[id]).is_empty(): return false
	var definition: Dictionary = definitions[technology]
	var required: String = definition.get("requires","")
	if not required.is_empty() and not required in known_technologies(id): return false
	if not game.inventories[id].transact(definition["cost"],{}): return false
	var tribe: String = tribes.tribe_of(key(id))
	if tribe.is_empty(): progression[id].learned.append(technology)
	else:
		if not tribe_research.has(tribe): tribe_research[tribe]=[]
		tribe_research[tribe].append(technology)
	progression[id].award("crafting",Balance.number("progression","research_xp",12))
	return true
func _repair(id: int, slot: int) -> bool:
	var inv = game.inventories[id]
	if slot<0 or slot>=36 or stations(game.players[id]).is_empty(): return false
	var row: Dictionary = inv.serialize()["slots"][slot]
	var item: String = row.get("id","")
	if not inv.durability.has(item) or int(inv.durability[item])>=100: return false
	if not inv.transact({"wood":1,"stone":2},{}): return false
	inv.durability[item]=mini(100,int(inv.durability[item])+Balance.integer("crafting","repair_amount",30))
	game.players[id].play_action("craft",0.7)
	return true
func _accessible(id: int, piece) -> bool:
	return piece!=null and game.players[id].position.distance_to(piece.position)<4 and building.can_interact(piece.get_record(),key(id)) and _clear_interaction(game.players[id],piece.position+Vector3.UP*0.7,piece.collision_rids())
func _territory_allows(identity: String, at: Vector3) -> bool:
	return building.territory_allows(identity,at)

func _chest_transfer(id: int, data: Dictionary) -> bool:
	var chest = game.world.get_structure(int(data.get("structure",-1)))
	if not _accessible(id,chest) or chest.kind!="chest": return false
	var inv = game.inventories[id]
	var slot := int(data.get("slot",-1));var amount:=int(data.get("amount",0))
	if amount<1 or amount>9999: return false
	if bool(data.get("to_chest",false)):
		if slot<0 or slot>=36: return false
		var item: String = inv.serialize()["slots"][slot].get("id","")
		if data.has("expected_item") and data["expected_item"] != item: return false
		if item.is_empty() or int(inv.serialize()["slots"][slot].get("count",0))<amount or chest.storage.get(item,0)+amount>9999 or (not chest.storage.has(item) and chest.storage.size()>=24): return false
		var taken: Dictionary = inv.take_slot(slot,amount)
		if taken.is_empty(): return false
		if taken.has("durability"): chest.storage_wear[item] = mini(int(chest.storage_wear.get(item,100)),int(taken["durability"]))
		chest.storage[item]=int(chest.storage.get(item,0))+amount
	else:
		var items: Array = chest.storage.keys();items.sort()
		if slot<0 or slot>=items.size(): return false
		var item: String = items[slot]
		if data.has("expected_item") and data["expected_item"] != item:return false
		if int(chest.storage[item])<amount or not inv.add(item,amount,int(chest.storage_wear.get(item,-1))): return false
		chest.storage[item]=int(chest.storage[item])-amount
		if chest.storage[item]==0: chest.storage.erase(item);chest.storage_wear.erase(item)
	game.session.notify(id,"storage",{"id":chest.structure_id,"storage":chest.storage.duplicate(true)})
	return true
func _refuel(id: int) -> bool:
	for fire in game.world.fires:
		if fire.position.distance_to(game.players[id].position)<3 and fire.fuel<3600 and _clear_interaction(game.players[id],fire.position+Vector3.UP):
			if game.inventories[id].consume("wood",1): return fire.add_fuel(Balance.number("fire","fuel_per_wood",120))
	return false
func _interact(id: int) -> bool:
	var body = game.players[id]
	if is_instance_valid(body.boat):
		body.position=body.boat.position+body.boat.global_basis.x*2+Vector3.UP*0.7
		body.boat=null;return true
	var vessel=game.world.structure_near(body,"raft",3.5)
	if _accessible(id,vessel) and not game.players.values().any(func(other):return other.boat==vessel):
		body.boat=vessel;body.position=vessel.position+Vector3.UP*0.25;body.velocity=Vector3.ZERO;return true
	var piece = game.world.structure_near(body)
	var pickup = nearby_pickup(id)
	if pickup != null and not activities.actions.has(id) and (not _accessible(id,piece) or pickup.position.distance_to(body.position) < piece.position.distance_to(body.position)):
		if activities.start_action(id,"pickup",0.55,{"drop":pickup.get_instance_id()}):
			body.play_action("gather",0.55)
			return true
	if _accessible(id,piece):
		if preload("res://Building/Catalog.gd").piece(piece.kind).has("door"): return building.toggle(id,piece)
		if piece.kind=="bed": piece.bound_to=key(id);body.respawn_position=game.world.bed_spawn(key(id));return true
		if piece.kind=="chest":
			game.session.notify(id,"storage",{"id":piece.structure_id,"storage":piece.storage.duplicate(true)})
			return true
	if activities.actions.has(id): return false
	for animal in wildlife.animals:
		if animal.hp<=0 and not animal.harvested and body.position.distance_to(animal.position)<3:
			if activities.start_action(id,"corpse",1.2,{"animal":animal.animal_id}): body.play_action("gather",1.2);return true
	for uid in energy_visuals.devices:
		var device = energy_visuals.devices[uid]
		if body.position.distance_to(device.position)<4 and tribes.can_build(grid.nodes[uid]["owner"],key(id)) and _clear_interaction(body,device.position+Vector3.UP,[device.get_rid()]):
			game.session.notify(id,"energy",{"id":uid}); return true
	for index in range(workshops.size()):
		var station=workshops[index]
		if _station_accessible(id,station):
			game.session.notify(id,"factory",{"station":index,"kind":station.kind,"state":station.machine.duplicate(true)})
			return true
	if _start_mining(id,Catalog.tool(game.inventories[id].equipped_item())!="pickaxe"): return true
	for source in get_tree().get_nodes_in_group("potable_source"):
		if source.position.distance_to(body.position)<3 and _clear_interaction(body,source.position+Vector3.UP*0.2):
			if game.inventories[id].count("water_container")>0:return game.inventories[id].transact({"water_container":1},{"water":1})
			return needs[id].drink()
	return false
func _start_mining(id: int, hand: bool) -> bool:
	var body = game.players[id]
	var index: int = mining.closest(body,3,not hand,hand)
	if index<0 or activities.actions.has(id): return false
	var kind: String = mining.resource_kind(index)
	if hand and Catalog.gathering(kind).get("tool","")!="hand":return false
	if not hand and Catalog.tool(game.inventories[id].equipped_item())!="pickaxe": return false
	if not activities.start_action(id,"mine",0.7,{"resource":index,"hand":hand}): return false
	body.play_action("mine",0.7);return true
func _near_water(body) -> bool:
	for offset in [Vector3(2,0,0),Vector3(-2,0,0),Vector3(0,0,2),Vector3(0,0,-2)]:
		var at: Vector3 = body.position+offset
		if game.world.terrain_height(at.x,at.z)<game.world.water_level and absf(body.position.y-game.world.water_level)<3: return true
	return false
func _fish(id: int) -> bool:
	var body = game.players[id]
	if not _near_water(body) or game.inventories[id].equipped_item()!="spear" or body.stamina<10 or Time.get_ticks_msec()<int(_fish_cooldowns.get(id,0)): return false
	var chosen: int = -1
	var distance: float = 7.0
	for fish in game.world.fishes:
		var current: float = fish.position.distance_to(body.position)
		if fish.stock>0 and current<distance: chosen=fish.fish_id;distance=current
	if chosen<0 or not activities.start_action(id,"fish",Balance.number("fishing","duration",3.5),{"fish":chosen}): return false
	body.stamina-=10;_fish_cooldowns[id]=Time.get_ticks_msec()+6000;body.play_action("fish",3.5);return true
func _plant(id: int, structure_id: int, crop: String) -> bool:
	var piece = game.world.get_structure(structure_id)
	if not _accessible(id,piece) or piece.kind!="garden" or crop!="berries" or farming.has(str(structure_id)): return false
	if not game.inventories[id].consume("berries",1): return false
	farming[str(structure_id)]={"crop":crop,"growth":0.0,"water":0.6,"planted_at":Time.get_unix_time_from_system()}
	_update_crop_visuals();game.journal.record_event(key(id),"plant");return true
func _harvest_crop(id: int, structure_id: int) -> bool:
	var piece = game.world.get_structure(structure_id)
	var record: Dictionary = farming.get(str(structure_id),{})
	if not _accessible(id,piece) or record.is_empty() or record["growth"]<1: return false
	if not game.inventories[id].add("berries",4): return false
	farming.erase(str(structure_id));piece.set_crop("",0,0);return true
func _tick_farming(delta: float) -> void:
	var raining: bool = game.weather.state()["raining"]
	for id in farming.keys():
		var piece = game.world.get_structure(int(id))
		if not game.world.structure_registry.records.has(int(id)) or game.world.structure_registry.records[int(id)]["kind"]!="garden": farming.erase(id);continue
		var row: Dictionary = farming[id]
		row["water"]=clampf(float(row["water"])+delta*(0.01 if raining else -0.001),0,1)
		row["growth"]=minf(1,float(row["growth"])+delta/Balance.number("garden","grow_seconds",180)*(1.5 if raining else (1 if row["water"]>0 else 0.2)))
	_update_crop_visuals()
func _update_crop_visuals() -> void:
	for id in farming:
		var piece = game.world.get_structure(int(id))
		if piece!=null: piece.set_crop(farming[id]["crop"],farming[id]["growth"],farming[id]["water"])

func _fresh_animals() -> Array:
	var records: Array = _initial_animals.duplicate(true)
	if int(game.world.descriptor()["generator"])>=2:
		for i in range(12,96):
			var row:Dictionary=_initial_animals[i%12].duplicate(true)
			row["id"]=i;records.append(row)
	if int(game.world.descriptor()["generator"])==0: return records
	var rng:=RandomNumberGenerator.new();rng.seed=int(game.world.descriptor()["seed"])+707
	for row in records:
		var at:=Vector3.ZERO
		for attempt in range(100):
			var angle: float = rng.randf()*TAU
			var radius: float = 24+int(row["id"])*3 if int(row["id"])<12 else rng.randf_range(160,640)
			at=Vector3(sin(angle)*radius,0,cos(angle)*radius)
			at.y=game.world.terrain_height(at.x,at.z)+0.05
			if at.y>game.world.water_level+0.4: break
		row["position"]=[at.x,at.y,at.z];row["home"]=row["position"].duplicate()
	return records

func craft_reason(id: int, recipe: String) -> String:
	var definition:Dictionary=preload("res://Items/Catalog.gd").recipe(recipe)
	if definition.is_empty() or not game.players.has(id): return "Unknown recipe"
	if activities.queue(id).size()>=5: return "Crafting queue is full"
	if not recipe_unlock_reason(id,recipe).is_empty(): return "Research required in Technology"
	var station:String=definition.get("station","hand")
	if station!="hand" and not station in stations(game.players[id]): return "Stay near the required station: "+station
	for item in definition["cost"]:
		if game.inventories[id].count(item)<int(definition["cost"][item]): return "Missing materials: "+preload("res://Items/Catalog.gd").display_name(item)
	return ""

func _start_dig(id: int) -> bool:
	var body=game.players[id]
	if game.inventories[id].equipped_item()!="shovel" or activities.actions.has(id) or body.stamina<8:return false
	var at:Vector3=body.position-body.global_basis.z*2
	at.y=game.world.terrain_height(at.x,at.z)
	if not _clear_interaction(body,at+Vector3.UP*0.15) or not game.world.contains_position(at):return false
	if not activities.start_action(id,"dig",0.9,{"position":at}):return false
	body.play_action("mine",0.9);return true

func recipe_unlock_reason(id: int, recipe_id: String) -> String:
	var definition:=Catalog.recipe(recipe_id)
	if definition.is_empty() or not game.players.has(id): return "Unknown recipe"
	var known:Array=known_technologies(id)
	if int(definition.get("era",0))>Profile.era(known) or not definition.get("unlocks",[]).all(func(t):return t in known):
		return "Research required in Technology"
	return ""

func station_reason(id: int, index: int, action: String, cycles: int = 1, recipe_id: String = "") -> String:
	if not game.players.has(id) or index<0 or index>=workshops.size(): return "Station unavailable"
	var station=workshops[index]
	if not _station_accessible(id,station): return "Stay near the required station"
	var state:Dictionary=station.machine
	if action=="station_select":
		var definition:=Catalog.recipe(recipe_id)
		if definition.is_empty() or definition["station"]!=station.kind: return "Unknown recipe"
		var unlock:=recipe_unlock_reason(id,recipe_id)
		if not unlock.is_empty(): return unlock
		if float(state["progress"])>0 or state["input"].values().any(func(n):return n>0): return "Refund station inputs before changing recipe"
		return ""
	var recipe:Dictionary=preload("res://Building/Factory.gd").definition(station.kind,state)
	if recipe.is_empty(): return "Unknown recipe"
	var inv=game.inventories[id]
	if action=="factory_load":
		if cycles<1 or cycles>5: return "Invalid amount"
		var legacy:bool=preload("res://Building/Factory.gd").RECIPES.has(station.kind) and not state.has("recipe")
		if not legacy:
			var unlock:=recipe_unlock_reason(id,str(state.get("recipe",Catalog.station(station.kind).get("default_recipe",""))))
			if not unlock.is_empty(): return unlock
		var keys:Array=state["input"].keys().filter(func(item):return int(state["input"][item])>0)
		for item in recipe["input"]:
			if not item in keys: keys.append(item)
			var required:int=int(recipe["input"][item])*cycles
			if int(state["input"].get(item,0))+required>9999: return "Station input storage is full"
			if inv.count(item)<required: return "Missing materials"
		if keys.size()>mini(8,int(Catalog.station(station.kind).get("capacity",8))): return "Station input storage is full"
		return ""
	var field:String="input" if action=="station_refund" else "output"
	if action not in ["station_refund","factory_take"]: return "Action unavailable"
	var reward:Dictionary={}
	for item in state[field]:
		if int(state[field][item])>0: reward[item]=int(state[field][item])
	if reward.is_empty(): return "No materials to refund" if field=="input" else "No stored output"
	return "" if inv.can_add_many(reward) else "Inventory is full"

func _factory_command(id: int, action: String, index: int, cycles: int = 5) -> bool:
	if not station_reason(id,index,action,cycles).is_empty(): return false
	var station=workshops[index]
	var inv=game.inventories[id]
	if action=="factory_load":
		var recipe:Dictionary=preload("res://Building/Factory.gd").definition(station.kind,station.machine)
		var cost:Dictionary={}
		for item in recipe["input"]: cost[item]=int(recipe["input"][item])*cycles
		if not inv.transact(cost,{}): return false
		for item in station.machine["input"].keys():
			if int(station.machine["input"][item])==0: station.machine["input"].erase(item)
		for item in cost: station.machine["input"][item]=int(station.machine["input"].get(item,0))+cost[item]
	else:
		var field:String="input" if action=="station_refund" else "output"
		var reward:Dictionary={}
		for item in station.machine[field]:
			if int(station.machine[field][item])>0: reward[item]=int(station.machine[field][item])
		if not inv.add_many(reward): return false
		station.machine[field].clear()
		if field=="input": station.machine["progress"]=0.0
	game.session.notify(id,"factory",{"station":index,"kind":station.kind,"state":station.machine.duplicate(true)})
	return true

func _select_station_recipe(id: int, index: int, recipe_id: String) -> bool:
	if not station_reason(id,index,"station_select",1,recipe_id).is_empty(): return false
	var station=workshops[index]
	station.machine["input"].clear()
	station.machine["recipe"]=recipe_id
	game.session.notify(id,"factory",{"station":index,"kind":station.kind,"state":station.machine.duplicate(true)})
	return true

func _tick_drop_physics() -> void:
	for drop in drops:
		var floor_height:float=game.world.terrain_height(drop.position.x,drop.position.z)+0.12
		if drop.position.y<floor_height:drop.position.y=floor_height;drop.linear_velocity=Vector3.ZERO
		var loaded:bool=game.world.has_terrain_at(drop.position)
		if not loaded:
			drop.freeze=true;drop.linear_velocity=Vector3.ZERO
		elif drop.freeze:drop.freeze=false

func _station_accessible(id: int,station) -> bool:
	if station==null or not game.players.has(id) or not Catalog.station_ids().has(station.kind):return false
	var body=game.players[id]
	return body.position.distance_to(station.position)<float(Catalog.station(station.kind).get("reach",4)) and (station.owner_key.is_empty() or tribes.can_build(station.owner_key,key(id))) and _clear_interaction(body,station.position+Vector3.UP,[station.get_rid()])

func nearby_pickup(id: int):
	if not game.players.has(id): return null
	var body = game.players[id]
	var result = null
	var distance := 2.5
	for drop in drops:
		var next_distance: float = body.position.distance_to(drop.position)
		if next_distance < distance and _clear_interaction(body,drop.position+Vector3.UP*0.2):
			result = drop
			distance = next_distance
	return result

func _build_energy(id: int, kind: String) -> bool:
	var site: Dictionary = PowerGrid.placement(game.world, game.players[id], kind)
	if not site["valid"] or grid.nodes.size()>=PowerGrid.MAX_NODES or grid.next_id>1000000 or not _territory_allows(key(id),site["position"]): return false
	for row in grid.nodes.values():
		var p: Array = row["position"]
		if Vector3(p[0],p[1],p[2]).distance_to(site["position"])<2.0: return false
	for station in workshops:
		if station.position.distance_to(site["position"])<2.0: return false
	if not _clear_interaction(game.players[id],site["position"]+Vector3.UP): return false
	if not game.inventories[id].consume(kind,1): return false
	grid.add(kind,site["position"],key(id)); grid.evaluate(game.world,workshops,tribes)
	energy_visuals.rebuild(); return true

func _energy_command(id: int, action: String, data: Dictionary) -> bool:
	var identity := key(id)
	if action=="energy_install":
		var index: int = data["station"]
		if index<0 or index>=workshops.size() or index in grid.motors or workshops[index].kind not in PowerGrid.MOTOR_KINDS or not _station_accessible(id,workshops[index]): return false
		if not game.inventories[id].consume("motor",1): return false
		grid.motors.append(index); grid.evaluate(game.world,workshops,tribes); return true
	var source: String = str(data.get("a",data.get("id","")))
	var row: Dictionary = grid.endpoint(source,workshops)
	if row.is_empty() or not tribes.can_build(row["owner"],identity) or game.players[id].position.distance_to(grid.point(source,workshops))>5: return false
	if action=="energy_connect": return grid.link_ports(source,str(data["b"]),identity,game.inventories[id],game.world,workshops,tribes)
	if action=="energy_toggle": grid.nodes[source]["enabled"]=not grid.nodes[source]["enabled"]; grid.evaluate(game.world,workshops,tribes); return true
	if action=="energy_disconnect":
		for index in range(grid.links.size()):
			var link: Dictionary = grid.links[index]
			if (link["a"]==data["a"] and link["b"]==data["b"]) or (link["a"]==data["b"] and link["b"]==data["a"]): return grid.unlink_ports(index,identity,game.inventories[id],tribes)
	return false
