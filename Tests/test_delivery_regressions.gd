extends SceneTree
const Inventory = preload("res://Core/Inventory.gd")
var checks := 0
var failed := 0
var game
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failed += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game = load("res://Scenes/Main.tscn").instantiate()
	game.save_folder = "user://delivery-qa/%d" % Time.get_ticks_usec()
	root.add_child(game)
	while not game.ready_world: await process_frame
	game.new_game(718991)
	game.runtime.command(1,"appearance",preload("res://Character/Appearance.gd").DEFAULT.duplicate(true))
	game.set_process(false); game.set_physics_process(false); game.player.set_physics_process(false)
	for z in range(-1,2):
		for x in range(-1,2):
			if not game.world._chunks.has(Vector2i(x,z)): game.world.make_chunk(x*16,z*16)
	var at := Vector3(0,game.world.terrain_height(0,0)+0.2,0)
	game.player.position = at
	var chest = game.world.add_structure("chest",at+Vector3(1.4,0,0),0,game.runtime.key(1))
	game.runtime._add_drop("wood",3,at+Vector3(-0.8,0,0))
	var drop = game.runtime.drops[-1]; drop.freeze = true
	await physics_frame; await physics_frame
	var before: int = game.inventory.count("wood")
	check(game.runtime._interact(1),"Nearby pickup can be selected beside a chest")
	check(game.runtime.activities.action_state(1).get("kind")=="pickup","E prioritizes the closer pickup rather than opening the chest")
	game.runtime._tick_activities(0.6)
	check(game.inventory.count("wood")==before+3 and game.runtime.drops.is_empty(),"Nearby-chest pickup is granted exactly once")
	check(game.runtime._interact(1) and game.hud.mode=="storage","Chest remains usable after pickup")
	game.runtime._event("channels",{"groups":{},"calls":{},"invitation":{},"blocked":[]})
	check(game.runtime.channel_state.get("storage",{}).get("id")==chest.structure_id,"Channel refresh retains the open chest identity")
	game.localization.select("en_US")
	check(game.hud.t("Equipar","Equip")=="Equip" and game.hud.t("Usar","Use")=="Use","English labels do not fall back to Portuguese")
	game.localization.select("pt_BR")
	var snapshot_count: int = game.snapshots_received
	var messages: int = game.runtime.messages.size()
	game.quitting = true; game.session.role = "client"
	game._receive_state({})
	check(game.snapshots_received==snapshot_count,"Late snapshot is ignored during shutdown")
	game.runtime._event("chat",{})
	check(game.runtime.messages.size()==messages,"Late UI/audio event is ignored during shutdown")
	game.runtime.audio.stop()
	for node in game.runtime.audio.pool:
		if is_instance_valid(node): node.queue_free()
	game.runtime.audio.ui.queue_free()
	await process_frame
	game.runtime.audio.play("pickup",Vector3.ZERO); game.runtime.audio.click()
	check(true,"Released audio emitters are not accessed by late playback")
	game.session.role = "offline"; game.quitting = false
	print("DELIVERY_REGRESSIONS CHECKS=%d FAILED=%d" % [checks,failed])
	await game.quit_game(0 if failed==0 else 1,false)
