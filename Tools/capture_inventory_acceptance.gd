extends "res://Tools/capture_audit.gd"
## End-to-end native Godot drag/drop and dialog input, without invoking UI callbacks.
var bag
func click(button: Control) -> void:
	await frames(8); await super.click(button)
func motion(at: Vector2, previous: Vector2) -> void:
	var event := InputEventMouseMotion.new(); event.position = at; event.global_position = at
	event.relative = at - previous; event.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(event); await frames(2)
func drag(source: Control, to: Vector2) -> void:
	await frames(8)
	var start := source.get_global_rect().get_center(); Input.warp_mouse(start); await frames(3)
	var press := InputEventMouseButton.new(); press.button_index = MOUSE_BUTTON_LEFT; press.position = start; press.global_position = start; press.pressed = true
	Input.parse_input_event(press); await frames(2)
	var previous := start
	for i in range(1, 9):
		var at := start.lerp(to, i / 8.0); await motion(at, previous); previous = at
	check(root.gui_is_dragging(), "Native viewport starts an inventory drag")
	var release: InputEventMouseButton = press.duplicate(); release.position = to; release.global_position = to; release.pressed = false
	Input.parse_input_event(release); await frames(8)
func find_bag() -> void:
	await frames(8)
	for child in game.hud.column.get_children():
		if child.get_script() == preload("res://UI/InventoryPanel.gd"): bag = child
func run() -> void:
	if DisplayServer.get_name() == "headless": quit(1); return
	game = load("res://Scenes/Main.tscn").instantiate(); game.save_folder = "user://inventory-acceptance"; root.add_child(game)
	while not game.ready_world: await process_frame
	game.localization.select("pt_BR"); game.new_game(718991)
	game.runtime.command(1, "appearance", preload("res://Character/Appearance.gd").DEFAULT.duplicate(true))
	game.player.set_physics_process(false); root.disable_3d = true
	game.inventory.add("wood", 12); game.inventory.add("stone", 6); game.inventory.add("berries", 4)
	await key(KEY_I); await find_bag()
	check(game.hud.mode == "inventory", "I opens the actual backpack")
	var slots: Array = game.inventory.serialize()["slots"]
	for item in ["wood", "stone", "berries"]:
		var from := -1
		for i in range(slots.size()):
			if slots[i].get("id") == item: from = i; break
		var destination: int = {"wood": 8, "stone": 9, "berries": 10}[item]
		await frames(8); await drag(bag.buttons[from], bag.buttons[destination].get_global_rect().get_center())
		slots = game.inventory.serialize()["slots"]
		check(slots[from].is_empty() and slots[destination].get("id") == item, "Mouse moves stack: " + item)
	# Native Shift+drag splits twelve into six+six without changing total.
	var shift := InputEventKey.new(); shift.keycode = KEY_SHIFT; shift.physical_keycode = KEY_SHIFT; shift.pressed = true; Input.parse_input_event(shift)
	await drag(bag.buttons[8], bag.buttons[1].get_global_rect().get_center())
	shift = shift.duplicate(); shift.pressed = false; Input.parse_input_event(shift); await frames()
	slots = game.inventory.serialize()["slots"]
	check(slots[8].get("count") == 6 and slots[1].get("count") == 6 and game.inventory.count("wood") == 12, "Shift drag splits stack with exact conservation")
	await drag(bag.buttons[8], Vector2(1220, 340))
	check(game.inventory.count("wood") == 6 and game.runtime.drops.size() == 1, "Dragging outside creates one physical pickup and removes six items")
	await key(KEY_I); await key(KEY_E); await create_timer(0.8).timeout
	check(game.inventory.count("wood") == 12 and game.runtime.drops.is_empty(), "E collects the dropped stack exactly once")
	await key(KEY_I); await find_bag()
	var axe_slot := -1
	slots = game.inventory.serialize()["slots"]
	for i in range(slots.size()):
		if slots[i].get("id") == "axe": axe_slot = i; break
	await drag(bag.buttons[axe_slot], Vector2(1220, 340))
	check(bag.drop_zone.confirmation != null and bag.drop_zone.confirmation.visible and game.inventory.count("axe") == 1, "Valuable gear awaits confirmation without deleting it")
	await key(KEY_ESCAPE)
	check(not bag.drop_zone.confirmation.visible and game.inventory.count("axe") == 1 and game.runtime.drops.is_empty(), "Escape cancels valuable drop without loss")
	var wood_before: int = game.inventory.count("wood")
	check(game.save_game(), "Save after real drag, split, drop and pickup")
	game.load_game(); await frames(10)
	check(game.inventory.count("wood") == wood_before and game.inventory.count("axe") == 1 and game.runtime.drops.is_empty(), "Reload preserves items without duplicate pickups")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/settlement/inventory-input"))
	var file := FileAccess.open("res://builds/settlement/inventory-input/report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failed": failed, "method": "Input.parse_input_event mouse down/motion/up, native viewport drag detection, Shift split, outside-panel drop, E pickup, Escape confirmation cancellation, disk reload. Fixture inventory; no direct UI drag/drop callbacks."}, "  ")); file.close()
	print("INVENTORY_INPUT CHECKS=%d FAILED=%d" % [checks, failed])
	await game.quit_game(0 if failed == 0 else 1, false)
