extends Node3D
const Balance = preload("res://Game/Balance.gd")
const Animal = preload("res://Animals/Animal.gd")
signal damage_requested(peer_id: int, amount: int)
var world
var authority: bool = true
var animals: Array = []
var navigation := AStarGrid2D.new()
var _navigation_hash: int = 0
var _layout_hash: int = 0
var cell_size: float = 2.0
const TEMPERAMENT := {"rabbit":"passive","deer":"passive","fox":"passive","boar":"neutral","bear":"neutral","wolf":"predator"}
func setup(value) -> void:
	world = value
	navigation.region = Rect2i(-30, -30, 60, 60)
	navigation.cell_size = Vector2(2, 2)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for i in range(12):
		var kind: String = Animal.SPECIES.keys()[i % 6]
		var angle := i * 2.399
		var p := Vector3(sin(angle) * (18 + i * 1.7), 0, cos(angle) * (18 + i * 1.7))
		if i == 0: p = Vector3(10, 0, -7)
		p.y = world.terrain_height(p.x, p.z) + 0.05
		var animal := Animal.new()
		add_child(animal)
		animal.setup(i, kind, p, authority)
		animals.append(animal)
	rebuild_navigation()
	for animal in animals:
		if navigation.is_point_solid(cell(animal.position)):
			for dx in [-2, 0, 2, 4, -4]:
				var trial: Vector3 = animal.position + Vector3(dx, 0, 2)
				if not navigation.is_point_solid(cell(trial)):
					trial.y = world.terrain_height(trial.x, trial.z) + 0.05
					animal.position = trial
					animal.home = trial
					break
func cell(p: Vector3) -> Vector2i:
	var low: Vector2i = navigation.region.position
	var high: Vector2i = navigation.region.end - Vector2i.ONE
	return Vector2i(clampi(roundi(p.x / cell_size), low.x, high.x), clampi(roundi(p.z / cell_size), low.y, high.y))
func rebuild_navigation() -> void:
	navigation.fill_solid_region(navigation.region, false)
	for z in range(navigation.region.position.y, navigation.region.end.y):
		for x in range(navigation.region.position.x, navigation.region.end.x):
			if world.terrain_height(x * cell_size, z * cell_size) < -2.5:
				navigation.set_point_solid(Vector2i(x, z), true)
	for tree in world.trees:
		if not tree.felled: navigation.set_point_solid(cell(tree.position), true)
	for shelter in world.shelters:
		navigation.set_point_solid(cell(shelter.position), true)
	_navigation_hash = hash([world.cut_ids(), world.shelter_positions()])
func tick(delta: float, players: Dictionary, authoritative: bool) -> void:
	authority = authoritative
	if authority: configure_world()
	if authority and _navigation_hash != hash([world.cut_ids(), world.shelter_positions()]):
		rebuild_navigation()
	for animal in animals:
		animal.authoritative = authority
		var nearest = null
		var distance := INF
		var peer := 0
		for id in players:
			var player = players[id]
			if player.vitals.hp <= 0 or player.creation_pending: continue
			var d: float = player.position.distance_to(animal.position)
			if d < distance:
				distance = d
				nearest = player
				peer = int(id)
		animal.visual_tick(delta, distance)
		if not authority: continue
		if animal.hp <= 0:
			if animal.respawn_at <= 0: animal.respawn_at=Time.get_unix_time_from_system()+Balance.number("animals","respawn_seconds",600)
			if Time.get_unix_time_from_system()>=animal.respawn_at:
				animal.hp=int(Animal.SPECIES[animal.species]["hp"]);animal.harvested=false;animal.respawn_at=0
				animal.position=animal.home;animal.avatar.rotation=Vector3.ZERO;animal.state="idle";animal.collision_layer=4;animal.show()
			continue
		var temperament: String = TEMPERAMENT[animal.species]
		var provoked: bool = Time.get_ticks_msec()/1000.0 < animal.provoked_until
		if temperament=="neutral" and provoked:
			nearest = players.get(animal.target_peer)
			distance = animal.position.distance_to(nearest.position) if nearest!=null else INF
		var hostile: bool = animal.owner_key.is_empty() and (temperament=="predator" or (temperament=="neutral" and provoked))
		if nearest != null:
			var view := PhysicsRayQueryParameters3D.create(animal.position+Vector3.UP*0.7,nearest.position+Vector3.UP,1)
			if not world.get_world_3d().direct_space_state.intersect_ray(view).is_empty():
				nearest=null;distance=INF
		if animal.state=="windup" and not hostile: animal.state="idle";animal.attack_left=0
		animal.attack_left = maxf(0, animal.attack_left - delta)
		animal.flee_left = maxf(0, animal.flee_left - delta)
		animal.decision_left -= delta
		if distance > 60:
			animal.intent = Vector3.ZERO
			continue
		var spec: Dictionary = Animal.SPECIES[animal.species]
		if animal.state == "windup":
			animal.intent = Vector3.ZERO
			if animal.attack_left <= 0:
				if nearest != null and distance <= float(spec["range"]) + 0.45:
					var query := PhysicsRayQueryParameters3D.create(animal.position + Vector3.UP * 0.7, nearest.position + Vector3.UP, 1)
					if world.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
						damage_requested.emit(peer, mini(20, 20 if animal.special else int(spec["damage"])))
				animal.state = "chase"
				animal.attack_left = 2.4
		elif nearest != null and hostile and distance <= float(spec["range"]) and animal.attack_left <= 0:
			animal.state = "windup"
			animal.special = animal.species == "bear" and int(animal.age * 10) % 13 == 0
			animal.attack_left = 1.15 if animal.special else 0.65
			animal.intent = Vector3.ZERO
		elif animal.decision_left <= 0:
			animal.decision_left = 0.35 if distance < 25 else 1.5
			var goal: Vector3 = animal.home
			if not animal.owner_key.is_empty():
				animal.state="follow"
				for owner in players.values():
					if str(owner.get_meta("key",""))==animal.owner_key: goal=owner.position + Vector3(2,0,2)
			elif nearest != null and not hostile and animal.owner_key.is_empty() and distance < 10:
				animal.state = "flee"
				goal = animal.position + (animal.position - nearest.position).normalized() * 10
			elif nearest != null and hostile and distance < 14 and animal.position.distance_to(animal.home) < 22:
				animal.state = "chase"
				goal = nearest.position
			else:
				animal.state = "wander"
				goal += Vector3(sin(animal.age * 0.13 + animal.animal_id), 0, cos(animal.age * 0.11 + animal.animal_id)) * 6
			var start := cell(animal.position)
			var end := cell(goal)
			if navigation.is_point_solid(end):
				end = cell(animal.home)
			animal.path = PackedVector3Array()
			if not navigation.is_point_solid(end):
				var occupied := navigation.is_point_solid(start)
				navigation.set_point_solid(start, false)
				var path := navigation.get_id_path(start, end, true)
				navigation.set_point_solid(start, occupied)
				for point in path:
					animal.path.append(Vector3(point.x * cell_size, world.terrain_height(point.x * cell_size, point.y * cell_size), point.y * cell_size))
			animal.path_index = 1 if animal.path.size() > 1 else 0
		if animal.state != "windup":
			if animal.path_index < animal.path.size():
				var offset: Vector3 = animal.path[animal.path_index] - animal.position
				offset.y = 0
				if offset.length() < 0.6:
					animal.path_index += 1
				else:
					animal.intent = offset.normalized()
			else:
				animal.intent = Vector3.ZERO
		if world.has_terrain_at(animal.position): animal.simulate(delta)
func capture() -> Array:
	return animals.map(func(animal): return animal.capture())
func restore(data: Array, authoritative: bool = true) -> void:
	if not valid_state(data): return
	authority = authoritative
	while animals.size()>data.size():animals.pop_back().queue_free()
	while animals.size()<data.size():
		var id:int=animals.size();var record:Dictionary=data[id]
		var animal:=Animal.new();add_child(animal)
		var p:Array=record["position"]
		animal.setup(id,Animal.SPECIES.keys()[id%6],Vector3(p[0],p[1],p[2]),authoritative)
		animals.append(animal)
	for record in data:
		animals[int(record["id"])].authoritative = authoritative
		animals[int(record["id"])].apply_snapshot(record)
func hit(animal, amount: int, attacker_peer: int = 0) -> bool:
	if not authority or not animal in animals: return false
	animal.target_peer=attacker_peer
	animal.provoked_until=Time.get_ticks_msec()/1000.0+Balance.number("animals","neutral_provoked",20)
	return animal.receive_damage(amount)
func harvest(body, inventory) -> bool:
	if not authority or body.vitals.hp <= 0: return false
	for animal in animals:
		if animal.hp <= 0 and not animal.harvested and body.position.distance_to(animal.position) < 3:
			var query := PhysicsRayQueryParameters3D.create(body.global_position + Vector3.UP,
				animal.global_position + Vector3.UP * 0.6, 1)
			query.exclude = [body.get_rid(), animal.get_rid()]
			if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
				continue
			if inventory.add_many(Animal.SPECIES[animal.species]["loot"]):
				animal.harvested = true
				animal.hide()
				return true
	return false
static func valid_state(data: Array) -> bool:
	if data.size() not in [12,96]: return false
	var seen: Array = []
	for d in data:
		if not d is Dictionary or not (d.get("id") is int or d.get("id") is float) or d["id"] != floorf(d["id"]) or d["id"] < 0 or d["id"] > 95 or d["id"] in seen or not Animal.SPECIES.has(d.get("species")):
			return false
		seen.append(d["id"])
		if d.has("owner") and (not d["owner"] is String or d["owner"].length()>128): return false
		for field in ["loyalty","respawn_at"]:
			if d.has(field) and (not (d[field] is int or d[field] is float) or not is_finite(float(d[field])) or d[field]<0 or d[field]>(100 if field=="loyalty" else 4102444800)): return false
		if d["species"] != Animal.SPECIES.keys()[int(d["id"]) % 6]: return false
		for field in ["position", "home"]:
			if not d.get(field) is Array or d[field].size() != 3: return false
			for n in d[field]:
				if not (n is int or n is float) or not is_finite(float(n)) or absf(float(n)) > 1200: return false
		for field in ["hp", "yaw", "age", "attack_left"]:
			if not (d.get(field) is int or d.get(field) is float) or not is_finite(float(d[field])): return false
		if d["hp"] < 0 or d["hp"] > int(Animal.SPECIES[d["species"]]["hp"]) or d["hp"] != floorf(d["hp"]) or d["age"] < 0 or d["attack_left"] < 0 or d["attack_left"] > 10 or not d.get("harvested") is bool or d.get("state") not in ["idle", "wander", "flee", "chase", "windup", "dead", "follow", "sleep", "return", "graze"]:
			return false
	return true

func configure_world() -> void:
	var signature: int = hash(world.descriptor())
	if signature==_layout_hash: return
	_layout_hash=signature
	cell_size=2.0 if world.half_extent()<=60 else (8.0 if world.half_extent()>200 else 4.0)
	var radius:=ceili(world.half_extent()/cell_size)
	navigation.region=Rect2i(-radius,-radius,radius*2,radius*2)
	navigation.cell_size=Vector2.ONE*cell_size;navigation.update()
	for animal in animals:
		if world.terrain_height(animal.position.x,animal.position.z)<world.water_level+0.2:
			for index in range(24):
				var trial: Vector3 = animal.home+Vector3(sin(index*2.4)*(4+index),0,cos(index*2.4)*(4+index))
				if world.contains_position(trial) and world.terrain_height(trial.x,trial.z)>world.water_level+0.3:
					animal.position=trial;animal.home=trial;break
		animal.position.y=world.terrain_height(animal.position.x,animal.position.z)+0.05
		animal.home.y=world.terrain_height(animal.home.x,animal.home.z)+0.05
	rebuild_navigation()
func tame(body, inventory, identity: String) -> bool:
	if not authority or body.vitals.hp<=0: return false
	for animal in animals:
		if animal.hp<=0 or not animal.owner_key.is_empty() or animal.position.distance_to(body.position)>3: continue
		var food := "raw_meat" if animal.species in ["wolf","boar"] else "berries"
		if animal.species=="bear" or not inventory.consume(food,Balance.integer("animals","tame_cost",3)): continue
		animal.owner_key=identity;animal.loyalty=75;animal.provoked_until=0;animal.attack_left=0;animal.state="follow"
		body.play_action("tame",0.8)
		return true
	return false
