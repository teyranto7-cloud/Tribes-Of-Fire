extends SceneTree
const InventoryPanel = preload("res://UI/InventoryPanel.gd")
const WorldMap = preload("res://UI/WorldMap.gd")
const Session = preload("res://Networking/Session.gd")
var checks := 0
var failed := 0
var game
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failed += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func panel_with(script):
	for child in game.hud.column.get_children():
		if child.get_script() == script: return child
	return null
func flush() -> void:
	while not game.commands.is_empty():
		var entry: Dictionary = game.commands.pop_front()
		game.runtime.command(entry["id"], entry["command"], entry["data"])
func run() -> void:
	game = load("res://Scenes/Main.tscn").instantiate()
	game.save_folder = "user://phase2/%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	root.add_child(game)
	while not game.ready_world: await process_frame
	game.settings_manager.config_path = "user://phase2-settings-%d.cfg" % OS.get_process_id()
	game.new_game(718991)
	game.set_process(false); game.set_physics_process(false); game.player.set_physics_process(false)
	game.inventory.add("wood", 20); game.inventory.add("stone", 12); game.inventory.add("fiber", 8)
	game.hud.show_panel("inventory")
	await process_frame
	var panel = panel_with(InventoryPanel)
	check(panel != null and panel.buttons.size() == 36, "Real HUD contains 36-slot inventory")
	var inv = game.inventory
	for item in ["wood", "stone", "fiber"]:
		var slots: Array = inv.serialize()["slots"]
		var source := -1
		for i in range(36):
			if slots[i].get("id") == item: source = i; break
		var target := 30 + ["wood", "stone", "fiber"].find(item)
		var payload: Dictionary = panel.buttons[source].drag_payload()
		check(panel.buttons[target]._can_drop_data(Vector2.ZERO, payload), "Slot accepts item drag")
		panel.buttons[target]._drop_data(Vector2.ZERO, payload); flush()
		check(inv.serialize()["slots"][target].get("id") == item, "Dragged item moves through authority command")
	panel.selected = 30; panel.split_selected(); flush()
	check(inv.count("wood") == 20 and inv.serialize()["slots"][30]["count"] == 10, "Split preserves total and divides stack")
	panel.inventory_search.text = "zzzz-no-item"; panel._refresh(true)
	check(panel.buttons.all(func(b): return not b.visible), "Search filters without mutating slots")
	panel.inventory_search.text = ""; panel.category.selected = 1; panel._refresh(true)
	check(not panel.buttons[30].visible and inv.count("wood") == 20, "Equipment filter hides resource slots")
	panel.category.selected = 0
	var drag: Dictionary = panel.buttons[30].drag_payload(true)
	check(drag["amount"] == 5, "Shift drag takes half stack")
	panel.drop_zone.request_drop(drag); flush()
	check(inv.count("wood") == 15 and game.runtime.drops.size() == 1, "Outside drag creates exactly one physical pickup")
	var drop = game.runtime.drops[0]
	check(drop is RigidBody3D and drop.get_meta("count") == 5, "Dropped item has lightweight physics and correct quantity")
	# Replayed stale drag cannot consume a different current stack.
	panel.drop_zone.request_drop(drag); flush()
	check(inv.count("wood") == 15 and game.runtime.drops.size() == 1, "Stale drag cannot duplicate or remove more items")
	check(Session.valid_command("inventory_drop", {"slot":30, "amount":5, "expected":drag["snapshot"]}), "Protocol accepts guarded drop")
	check(not Session.valid_command("inventory_drop", {"slot":30,"amount":5,"expected":{"id":"wood","count":-1}}), "Protocol rejects invalid expected count")
	var axe_slot := -1
	for i in range(36):
		if inv.serialize()["slots"][i].get("id") == "axe": axe_slot = i; break
	panel.drop_zone.request_drop(panel.buttons[axe_slot].drag_payload())
	check(panel.drop_zone.confirmation.visible and inv.count("axe") == 1, "Valuable equipment requires confirmation")
	panel.drop_zone.confirmation.canceled.emit(); panel.drop_zone.confirmation.hide()
	panel._action("Sort"); flush()
	check(inv.count("wood") == 15 and inv.count("stone") == 12, "Server organization preserves all item totals")
	# Verify pickup using the actual delayed interaction machinery.
	game.player.position = drop.position + Vector3(0, 0.1, 1)
	await physics_frame; await physics_frame
	game.runtime.command(1, "interact", {}); game.runtime._tick_activities(0.7)
	check(inv.count("wood") == 20 and game.runtime.drops.is_empty(), "Physical drop can be collected once")
	var chest_at:Vector3=game.player.position+Vector3(0,0,3)
	chest_at.y=game.world.terrain_height(chest_at.x,chest_at.z)
	var chest=game.world.add_structure("chest",chest_at,0,game.session.player_key(1))
	inv.durability["axe"]=42
	for i in range(36):
		if inv.serialize()["slots"][i].get("id")=="axe":axe_slot=i;break
	game.runtime.channel_state["storage"]={"id":chest.structure_id,"storage":{}}
	game.hud.show_panel("storage");await process_frame
	var storage=panel_with(preload("res://UI/StoragePanel.gd"))
	check(storage!=null,"Storage grid opens in actual HUD")
	storage.transfer("axe",axe_slot,1,true);flush()
	check(inv.count("axe")==0 and chest.storage.get("axe")==1 and chest.storage_wear.get("axe")==42,"Equipment transfer preserves wear")
	storage=panel_with(preload("res://UI/StoragePanel.gd"))
	storage.transfer("axe",0,1,false);flush()
	check(inv.count("axe")==1 and inv.durability.get("axe")==42,"Equipment withdrawal cannot repair or duplicate")
	var position:Vector3=game.player.position
	game.player.position.x+=100
	check(not game.runtime._chest_transfer(1,{"structure":chest.structure_id,"slot":axe_slot,"amount":1,"to_chest":true}),"Remote chest transfer is rejected")
	game.player.position=position
	game.hud.show_panel("")
	game.settings_manager.write_sections({"quickbar":{"slot4":"axe"},"accessibility":{"minimap":true}})
	game.use_quick_slot(3);flush()
	check(inv.equipped_item()=="axe","Assigned 4 shortcut equips selected item")
	check(game.settings_manager.read("accessibility","minimap",false)==true,"Minimap preference persists")
	check(preload("res://UI/ItemIcons.gd").icon("axe")!=null,"Inventory icons load as real textures")
	game.journal.explore(game.session.player_key(1), game.player.position, game.world.descriptor(), 0.2)
	game.hud.show_panel("map"); await process_frame
	var map = panel_with(WorldMap)
	check(map != null and map.texture.get_width() == 192, "Navigation map samples actual world geometry")
	var canvas = map.canvas
	var sample := Vector2(10, 15)
	check(canvas.screen_to_world(canvas.world_to_screen(sample)).distance_to(sample) < 0.01, "Map coordinates round trip")
	canvas.zoom_at(canvas.size * 0.5, 2)
	check(canvas.zoom == 2 and canvas.screen_to_world(canvas.world_to_screen(sample)).distance_to(sample) < 0.01, "Zoom preserves coordinate mapping")
	canvas.center_player()
	check(canvas.world_to_screen(Vector2(game.player.position.x, game.player.position.z)).distance_to(canvas.size * 0.5) < 1, "Map centers on player")
	map.selected = Vector2(game.player.position.x, game.player.position.z)
	game.request_command("map_mark", {"position":[map.selected.x,map.selected.y],"name":"Base QA","color":0,"shared":false}); flush()
	check(game.journal.serialize(game.session.player_key(1))["markers"].size() == 1, "Explored waypoint created by authority")
	game.inventory.add("wood", 20)
	game.request_command("craft", {"recipe":"campfire"}); flush(); game.runtime._tick_activities(30.0)
	check(game.inventory.count("campfire") > 0, "Simple recipe crafted through actual queue")
	var expected: Dictionary = inv.serialize()
	check(game.save_game(), "Inventory and waypoint save successfully")
	game.inventory.consume("wood", 1)
	game.load_game()
	check(game.inventory.serialize() == expected, "Reload restores inventory without duplication")
	check(game.journal.serialize(game.session.player_key(1))["markers"].size() == 1, "Waypoint survives reload")
	check(InputMap.action_get_events("inventory").any(func(e): return e is InputEventKey and e.physical_keycode == KEY_I), "Backpack has I shortcut")
	print("PHASE2 CHECKS=%d FAILED=%d" % [checks, failed])
	game.quit_game(0 if failed == 0 else 1, false)
