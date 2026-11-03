extends SceneTree
const Tribes = preload("res://Tribes/System.gd")
const Store = preload("res://Persistence/Store.gd")
const Weather = preload("res://Weather/Weather.gd")
var checks: int = 0
var failed: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failed += 1
		push_error(message)

func paired_tribe() -> RefCounted:
	var system := Tribes.new()
	check(system.command("A", "tribe_create", {"name": "Alpha"}, 1000), "Create a tribe")
	check(system.command("A", "tribe_invite", {"target": "B"}, 1000) and system.command("B", "tribe_accept", {}, 1000), "Add a former companion")
	return system

func fill_capacity(system, expiry: float) -> void:
	for index in range(Tribes.MAX_PROTECTIONS):
		system.protections.append({"person": "leaver-%d" % index, "tribe": "old-%d" % index, "members": ["companion-%d" % index], "until": expiry})

func world_state(system) -> Dictionary:
	return {"version": 3, "seed": 1337, "players": {}, "cut": [], "fires": [], "shelters": [], "phase": 450.0, "weather": Weather.new().serialize(), "tribes": system.state()}

func _initialize() -> void:
	var solo := Tribes.new()
	var accepted := true
	for index in range(3000):
		accepted = solo.command("A", "tribe_create", {"name": "Solo"}, 1000) and accepted
		accepted = solo.command("A", "tribe_leave", {}, 1000) and accepted
	check(accepted, "Repeated solo create/leave remains a valid action")
	check(solo.protections.is_empty() and Tribes.valid_state(solo.state()), "Solo exits cannot fill the protection table or invalidate saves")
	var folder := "user://tests/tribes-regression-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	check(Store.valid(world_state(solo)) and Store.save_world(world_state(solo), folder) == "", "Flooded solo history still saves through the real persistence layer")
	check(not Store.load_world(folder).is_empty(), "Flooded solo history reloads")
	Store.release_lock(folder)

	var paired = paired_tribe()
	check(paired.command("A", "tribe_leave", {}, 1000), "Leaving companions succeeds")
	check(not paired.can_damage("A", "B", 1299.999) and not paired.can_damage("B", "A", 1299.999), "Departure protection stays bilateral for the full interval")
	check(paired.can_damage("A", "B", 1300) and paired.can_damage("B", "A", 1300), "Departure protection expires at exactly 300 seconds")
	check(paired.can_damage("A", "C", 1001), "Third parties remain attackable")
	var restored := Tribes.new()
	restored.restore(paired.state())
	check(not restored.can_damage("A", "B", 1001), "V3 restoration preserves live departure protection")

	var expelled = paired_tribe()
	check(expelled.command("A", "tribe_kick", {"target": "B"}, 1000), "Leader can expel a companion")
	check(not expelled.can_damage("A", "B", 1001) and not expelled.can_damage("B", "A", 1001), "Expulsion retains bilateral protection")

	var full = paired_tribe()
	fill_capacity(full, 5000)
	check(Tribes.valid_state(full.state()), "A full active protection table is valid")
	var before: Dictionary = full.state()
	check(not full.command("A", "tribe_leave", {}, 1000) and full.state() == before, "Capacity refusal leaves membership and active protections unchanged")
	check(not full.command("A", "tribe_kick", {"target": "B"}, 1000) and full.state() == before, "Capacity refusal of expulsion is atomic")
	check(not full.can_damage("leaver-0", "companion-0", 1001), "Capacity handling never evicts a live protection")
	check(Store.valid(world_state(full)), "Capacity refusal cannot invalidate the world schema")

	var duplicate = paired_tribe()
	fill_capacity(duplicate, 5000)
	var id: String = duplicate.tribe_of("A")
	# This is the legacy v3 representation, including the departing player.
	duplicate.protections[0] = {"person": "A", "tribe": id, "members": ["B", "A"], "until": 1300.0}
	check(duplicate.command("A", "tribe_leave", {}, 1005), "Equivalent legacy protection can be renewed at full capacity")
	check(duplicate.protections.size() == Tribes.MAX_PROTECTIONS and duplicate.protections[0]["until"] == 1305, "Equivalent protection is updated instead of duplicated")
	check(not duplicate.can_damage("A", "B", 1304.999) and duplicate.can_damage("A", "B", 1305), "Renewal grants exactly the new 300-second interval")
	check(Tribes.valid_state(duplicate.state()), "Deduplicated legacy state remains valid v3")

	var expired = paired_tribe()
	fill_capacity(expired, 1000)
	check(expired.command("A", "tribe_leave", {}, 1000), "Expired records are pruned before testing capacity")
	check(expired.protections.size() == 1 and not expired.can_damage("A", "B", 1001), "Pruning retains the newly required protection")
	print("TRIBES CHECKS=%d FAILED=%d" % [checks, failed])
	quit(0 if failed == 0 else 1)
