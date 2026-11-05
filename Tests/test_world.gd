extends SceneTree

const WorldScript = preload("res://World/World.gd")
var failed: int = 0
var checks: int = 0
var world

class TestClock:
	extends RefCounted
	var value: float = 12.0
	func hour() -> float:
		return value
	func daylight() -> float:
		return clampf(sin((value - 6.0) / 24.0 * TAU), 0, 1)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	world = WorldScript.new()
	root.add_child(world)
	await world.generate(func(_progress): pass)
	await physics_frame
	await physics_frame
	check(world.trees.size() == 160, "Generated forest contains all harvestable resources")
	var ground_query := PhysicsRayQueryParameters3D.create(Vector3(0, 10, 0), Vector3(0, -10, 0), 1)
	var ground_hit: Dictionary = world.get_world_3d().direct_space_state.intersect_ray(ground_query)
	check(not ground_hit.is_empty() and ground_hit["collider"].is_in_group("terrain"), "Terrain provides upward collision")
	if not ground_hit.is_empty():
		check(absf(ground_hit["position"].y - WorldScript.height_at(0, 0)) < 0.02, "Ground collision matches rendered height at grid vertex")
	var player := CharacterBody3D.new()
	root.add_child(player)
	player.position = Vector3(0, WorldScript.height_at(0, 3) + 0.1, 3)
	await physics_frame
	check(bool(world.placement(player)["valid"]), "An unobstructed campfire site is accepted")
	world.add_fire(Vector3(0, WorldScript.height_at(0, 0) + 0.03, 0))
	await physics_frame
	check(not bool(world.placement(player)["valid"]), "Placing another campfire over existing collision is rejected")
	check(world.warmth_at(Vector3(1, WorldScript.height_at(0, 0), 0)), "Campfire supplies nearby heat")
	check(not world.warmth_at(Vector3(20, 3, 0)), "Heat has bounded reach")
	var shelter_at := Vector3(10, WorldScript.height_at(10, 0), 0)
	world.add_shelter(shelter_at)
	await physics_frame
	await physics_frame
	player.position = shelter_at + Vector3.UP * 0.05
	check(world.is_sheltered(player), "Solid roof protects a standing character below it")
	player.position = shelter_at + Vector3(3.5, 0.05, 0)
	check(not world.is_sheltered(player), "Leaving physical roof removes shelter")
	var roof_hit: Dictionary = world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(shelter_at + Vector3.UP * 12, shelter_at, 1))
	check(not roof_hit.is_empty() and roof_hit["collider"].is_in_group("rain_roof"), "Rain column hits roof before terrain")
	var tree = world.trees[0]
	check(tree.detail_meshes.size() <= 3, "Static tree geometry consolidated by material without changing collisions")
	check(not tree.hit() and not tree.hit() and tree.hit(), "Exactly three axe hits fell a tree")
	check(not tree.hit() and tree.collision_layer == 0, "Felled trees cannot be harvested twice and stop blocking")
	check(world.cut_ids().has(0), "Felled resource appears in persistent state")
	tree.restore_cut(false)
	check(not tree.felled and tree.hits == 0 and tree.collision_layer == 1, "Restoring an uncut tree restores collision and hit count")
	var day := TestClock.new()
	world.illuminate(day)
	var day_energy: float = world.sun.light_energy
	day.value = 0
	world.illuminate(day)
	check(world.sun.light_energy < day_energy and world.moon.light_energy > 0, "Day-night lighting changes solar and lunar energy")
	world.set_quality(0)
	var low_count: int = world.grass.multimesh.visible_instance_count
	var low_detail_distance: float = world.trees[0].detail_meshes[0].visibility_range_end
	check(not world.reflection_probe.visible, "Low quality disables the environment reflection capture")
	world.set_quality(3)
	check(world.grass.multimesh.visible_instance_count > low_count and world.sun.shadow_enabled, "Quality changes actual vegetation density and shadows")
	check(world.trees[0].detail_meshes[0].visibility_range_end > low_detail_distance and world.trees[0].distant_meshes.size() == 2, "Quality changes actual tree LOD ranges")
	check(world.reflection_probe.visible, "High quality enables captured environment reflections")
	world.apply_weather({"rain": 1.0, "cloud": 1.0, "wind": 0.8, "fog": 0.7, "lightning": 0.0})
	world.illuminate(day)
	check(world.environment.fog_density > 0.02, "Storm weather changes atmospheric visibility")
	world.rain_focus = shelter_at + Vector3.UP
	var rain_stop: float = world.rain_stop_at(shelter_at.x, shelter_at.z, shelter_at.y + 15)
	check(rain_stop >= shelter_at.y + 2.9, "Rendered rain column stops above solid roof")
	world.rain_drops[0] = {"p": shelter_at + Vector3.UP * 4, "bottom": rain_stop, "active": true}
	await physics_frame
	check(world.rain_drops[0]["p"].y > rain_stop, "Drop remains above the collision roof")
	world.add_shelter(Vector3(-10, WorldScript.height_at(-10, 0), 0))
	check(not world.rain_drops[0]["active"], "New roofs invalidate already falling columns")
	world.shelters[-1].queue_free()
	world.shelters.pop_back()
	var saved: Dictionary = {"cut": [1, 4], "fires": world.fire_positions(), "shelters": world.shelter_positions()}
	world.restore(saved)
	await physics_frame
	check(world.cut_ids() == [1, 4] and world.fires.size() == 1 and world.shelters.size() == 1, "World edits restore across tree and building state")
	player.queue_free()
	var playbacks: Array[WeakRef] = []
	_collect_playbacks(world,playbacks)
	# Use the world's real emitter cleanup and verify mixer release. A fixed
	# delay could race the audio thread when other processes are using the CPU.
	world._stop_world_audio(world)
	world.queue_free()
	await process_frame
	var deadline := Time.get_ticks_msec()+2000
	while playbacks.any(func(playback):return playback.get_ref()!=null) and Time.get_ticks_msec()<deadline:
		await create_timer(0.02).timeout
	check(not playbacks.any(func(playback):return playback.get_ref()!=null),"World teardown releases every captured mixer playback")
	print("WORLD CHECKS=%d FAILED=%d" % [checks, failed])
	quit(0 if failed == 0 else 1)

func _collect_playbacks(node:Node,refs:Array[WeakRef])->void:
	if (node is AudioStreamPlayer or node is AudioStreamPlayer3D) and node.has_stream_playback():refs.append(weakref(node.get_stream_playback()))
	for child in node.get_children():_collect_playbacks(child,refs)
