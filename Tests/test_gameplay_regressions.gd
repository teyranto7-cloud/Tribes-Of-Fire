extends SceneTree
## Isolated rules and real physics fixtures; no user world or network is touched.
const Inventory = preload("res://Core/Inventory.gd")
const Catalog = preload("res://Items/Catalog.gd")
const Needs = preload("res://Survival/Survival.gd")
const Player = preload("res://Player/Player.gd")
const Mining = preload("res://Mining/System.gd")
const Director = preload("res://Animals/Director.gd")
const Animal = preload("res://Animals/Animal.gd")
var checks: int = 0
var failed: int = 0
var physics_completed: bool = false

class FlatWorld:
	extends Node3D
	func terrain_height(_x: float, _z: float) -> float:
		return 0.0
	func half_extent() -> float:
		return 60.0
	func has_terrain_at(_at: Vector3) -> bool:
		return true

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func find_slot(inventory, id: String) -> int:
	var state: Dictionary = inventory.serialize()
	for index in range(36):
		if state["slots"][index].get("id", "") == id:
			return index
	return -1

func inventory_regressions() -> void:
	var inventory := Inventory.new()
	inventory.wear_equipment("hand", 60)
	var dropped: Dictionary = inventory.take_slot(find_slot(inventory, "axe"), 1)
	check(dropped.get("durability") == 40 and inventory.count("axe") == 0,
		"Dropping the last tool carries its current durability")
	check(inventory.add(dropped["id"], dropped["count"], dropped["durability"])
		and inventory.durability["axe"] == 40,
		"Picking up the dropped tool does not repair it")
	check(inventory.add("axe", 1, 90) and inventory.durability["axe"] == 40,
		"Receiving a better spare cannot repair the carried type")
	check(inventory.add("axe", 1, 25) and inventory.durability["axe"] == 25,
		"Mixed worn copies conservatively preserve the lower shared durability")
	var before: Dictionary = inventory.serialize()
	check(not inventory.add("axe", 1, 101) and inventory.serialize() == before,
		"Invalid pickup durability cannot mutate inventory")
	var restored := Inventory.new()
	restored.restore(inventory.serialize())
	check(restored.durability["axe"] == 25 and Inventory.valid_state(restored.serialize()),
		"Transferred wear survives inventory serialization")
	var spare := Inventory.new()
	spare.add("axe", 1)
	spare.wear_equipment("hand", 100)
	check(spare.count("axe") == 1 and spare.equipped_item() == "" and spare.durability["axe"] == 100,
		"Breaking one copy clears equipment and leaves the spare usable")
	check(spare.equip(find_slot(spare, "axe")), "The spare can be equipped")
	spare.wear_equipment("hand", 1)
	check(spare.count("axe") == 1 and spare.durability["axe"] == 99,
		"One use of a spare does not destroy a fresh tool")

func cooking_regressions() -> void:
	var inventory := Inventory.new()
	inventory.add("raw_meat", 1)
	for id in Catalog.ids():
		if id in ["axe", "raw_meat", "cooked_meat"]:
			continue
		if inventory.serialize()["slots"].all(func(slot): return not slot.is_empty()):
			break
		inventory.add(id, 1)
	check(inventory.serialize()["slots"].all(func(slot): return not slot.is_empty()),
		"Fixture fills all slots with distinct real items")
	var needs := Needs.new()
	var before: Dictionary = inventory.serialize()
	check(not needs.cook(inventory, false) and inventory.serialize() == before,
		"Cooking without heat preserves every slot")
	check(needs.cook(inventory, true) and inventory.count("raw_meat") == 0
		and inventory.count("cooked_meat") == 1,
		"The consumed final raw-meat stack supplies room for cooked meat")
	var blocked := Inventory.new()
	blocked.add("raw_meat", 2)
	for id in Catalog.ids():
		if id in ["axe", "raw_meat", "cooked_meat"]:
			continue
		if blocked.serialize()["slots"].all(func(slot): return not slot.is_empty()):
			break
		blocked.add(id, 1)
	before = blocked.serialize()
	check(not needs.cook(blocked, true) and blocked.serialize() == before,
		"A full inventory with remaining raw meat rolls back failed cooking")

func box_body(parent: Node3D, size: Vector3, at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	return body

func physics_regressions() -> void:
	var world := FlatWorld.new()
	root.add_child(world)
	box_body(world, Vector3(120, 0.2, 120), Vector3(0, -0.1, 0))
	var player := Player.new()
	player.world = world
	player.local_control = false
	player.auto_respawn = false
	world.add_child(player)
	player.set_physics_process(false)
	var mining := Mining.new()
	world.add_child(mining)
	mining.setup(world)
	player.position = Vector3(4, 0.1, 1)
	player.rotation = Vector3.ZERO
	var wall := box_body(world, Vector3(2, 3, 0.2), Vector3(4, 1.5, 0))
	await physics_frame
	await physics_frame
	var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP,
		mining.nodes[0].global_position + Vector3.UP * 0.6, 1)
	var hit: Dictionary = world.get_world_3d().direct_space_state.intersect_ray(query)
	check(hit.get("collider") == wall, "Mining fixture has a real blocking wall")
	var inventory := Inventory.new()
	check(not mining.mine(player, inventory, 0, true) and inventory.count("stone") == 0
		and mining.stocks[0] == 8 and player.stamina == 100,
		"A wall prevents mining and preserves stock, stamina and inventory")
	wall.position.x = 30
	await physics_frame
	await physics_frame
	check(mining.mine(player, inventory, 0, true) and inventory.count("stone") == 1
		and mining.stocks[0] == 7, "Removing the wall allows the same reachable resource")
	check(not mining.mine(player, inventory, 0, true) and mining.stocks[0] == 7,
		"Rejected repeat mining respects the cooldown")
	var own_bus := AudioServer.get_bus_index("Vocalizations") < 0
	if own_bus:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Vocalizations")
	var director := Director.new()
	world.add_child(director)
	director.world = world
	var corpse := Animal.new()
	world.add_child(corpse)
	corpse.setup(0, "rabbit", Vector3(0, 0, 1), true)
	corpse.receive_damage(100)
	director.animals = [corpse]
	player.position = Vector3(0, 0.1, 3)
	wall.position = Vector3(0, 1.5, 2)
	await physics_frame
	await physics_frame
	query = PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP,
		corpse.global_position + Vector3.UP * 0.6, 1)
	hit = world.get_world_3d().direct_space_state.intersect_ray(query)
	check(hit.get("collider") == wall, "Harvest fixture has a real blocking wall")
	check(not director.harvest(player, inventory) and not corpse.harvested
		and inventory.count("raw_meat") == 0, "A corpse cannot be looted through the wall")
	wall.position.x = 30
	await physics_frame
	await physics_frame
	check(director.harvest(player, inventory) and inventory.count("raw_meat") == 1
		and corpse.harvested, "Removing the wall permits corpse loot")
	check(not director.harvest(player, inventory) and inventory.count("raw_meat") == 1,
		"The corpse still grants loot only once")
	player.position = Vector3(0, 0.1, 5)
	player.velocity = Vector3(2, 0, -4)
	player.vitals.hp = 0
	player.set_intent({"move": [1, 1], "yaw": 0.0, "dodge": true, "block": true, "sprint": true})
	check(player.dodging == 0 and not player.blocking,
		"Dead input cannot activate dodge or defense")
	var before := player.position
	for frame in range(10):
		player._physics_process(1.0 / 60.0)
		await physics_frame
	check(Vector2(player.position.x - before.x, player.position.z - before.z).length() < 0.0001,
		"A dead player has no planar movement even with prior velocity")
	player.dodging = 0.3
	player.blocking = true
	player.crouching = true
	player.attack_time = 0.4
	player.respawn()
	check(player.vitals.hp == 100 and player.dodging == 0 and not player.blocking
		and not player.crouching and player.attack_time == 0 and player.velocity == Vector3.ZERO,
		"Respawn clears transient movement and combat state")
	world.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	if own_bus:
		AudioServer.remove_bus(AudioServer.get_bus_index("Vocalizations"))
	physics_completed = true

func run() -> void:
	inventory_regressions()
	cooking_regressions()
	await physics_regressions()
	check(physics_completed, "All isolated physics regression cases completed")
	print("GAMEPLAY_REGRESSIONS CHECKS=%d FAILED=%d" % [checks, failed])
	quit(0 if failed == 0 else 1)
