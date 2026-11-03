extends SceneTree
const Inventory = preload("res://Core/Inventory.gd")
const Catalog = preload("res://Items/Catalog.gd")
const Tribes = preload("res://Tribes/System.gd")
const Channels = preload("res://Communication/Channels.gd")
const Codec = preload("res://Communication/ADPCM.gd")
const Voice = preload("res://Communication/Voice.gd")
const Appearance = preload("res://Character/Appearance.gd")
const Graphics = preload("res://Graphics/Settings.gd")
const Localization = preload("res://Localization/Manager.gd")
const Needs = preload("res://Survival/Survival.gd")
const Vitals = preload("res://Core/Vitals.gd")
const Store = preload("res://Persistence/Store.gd")
const Session = preload("res://Networking/Session.gd")
var checks: int = 0
var failed: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failed += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var inv := Inventory.new()
	inv.add("wood", 20)
	var slot: int = inv.serialize()["slots"].find({"id": "wood", "count": 20})
	check(inv.move_slot(slot, 10, 7), "Split seven wood into a free slot")
	check(inv.count("wood") == 20 and inv.serialize()["slots"][10]["count"] == 7, "Split conserves total and layout")
	inv.add("stone", 4)
	check(inv.serialize()["slots"][10]["count"] == 7, "Collecting another item preserves split layout")
	check(not inv.move_slot(-1, 10, 1) and not inv.move_slot(10, 11, -1), "Invalid move rejected")
	check(not Session.valid_command("combat", {"kind": "light", "damage": 9999}), "Client cannot supply a damage result")
	check(not Session.valid_command("inventory_move", {"from": -1, "to": 10, "amount": 1}) and not Session.valid_command("equip", {"slot": 999}), "Malformed slot commands rejected before simulation")
	var prior := inv.serialize()
	check(not inv.transact({"iron_ingot": 10}, {"steel_sword": 1}) and inv.serialize() == prior, "Failed transaction preserves slots and equipment")
	check(not inv.craft_recipe("iron_ingot", []), "Furnace recipe requires station")
	check(inv.craft_recipe("pickaxe"), "Hand crafting consumes wood and stone")
	var pick := -1
	for i in range(36):
		if inv.slots[i].get("id", "") == "pickaxe": pick = i
	check(pick >= 0 and inv.equip(pick) and inv.equipped_item() == "pickaxe", "Equip actual crafted tool")
	inv.wear_equipment("hand", 100)
	check(inv.count("pickaxe") == 0 and inv.add("pickaxe", 1) and inv.durability["pickaxe"] == 100, "A replacement tool starts with full durability after the previous one breaks")
	check(inv.take_slot(10, 1).get("count", 0) == 1 and inv.count("wood") == 15, "Drop uses selected stack without duplicating")
	var broken := inv.serialize()
	broken["slots"][1] = {"id": "unknown", "count": 2}
	check(not Inventory.valid_state(broken), "Reject unknown serialized item")
	var tribes := Tribes.new()
	check(tribes.command("A", "tribe_create", {"name": "Alpha"}, 1000), "Create tribe")
	check(tribes.command("A", "tribe_invite", {"target": "B"}, 1000) and tribes.command("B", "tribe_accept", {}, 1000), "Invite and accept")
	check(not tribes.can_damage("A", "B", 1000) and not tribes.can_damage("B", "A", 1000), "Friendly fire blocked both ways")
	check(not tribes.command("B", "tribe_kick", {"target": "A"}, 1000), "Only leader can expel")
	check(tribes.command("B", "tribe_leave", {}, 1000), "Leave tribe")
	check(not tribes.can_damage("A", "B", 1299.99) and not tribes.can_damage("B", "A", 1299.99), "Protection bilateral up to five minutes")
	check(tribes.can_damage("A", "B", 1300), "Protection expires exactly at five minutes")
	check(tribes.can_damage("B", "C", 1001), "Third parties unaffected")
	check(tribes.command("B", "tribe_create", {"name": "Beta"}, 1001) and not tribes.can_damage("B", "A", 1002), "Changing tribe cannot bypass protection")
	var restored := Tribes.new()
	restored.restore(tribes.state())
	check(not restored.can_damage("B", "A", 1002), "Protection survives save and reconnect")
	check(Tribes.valid_state(restored.state()), "Tribe schema validates")
	var positions := {"A": Vector3.ZERO, "B": Vector3(8, 0, 0), "C": Vector3(45, 0, 0)}
	var channels := Channels.new()
	check(channels.recipients("A", "global", "", positions, tribes).size() == 3, "Global text reaches all online users")
	check(channels.recipients("A", "local", "", positions, tribes).size() == 2, "Local text follows server distance")
	check(channels.recipients("A", "proximity", "", positions, tribes, true).size() == 2, "Voice exceeds no proximity limit")
	check(channels.recipients("A", "private", "B", positions, tribes).size() == 2, "Private text excludes third user")
	check(channels.recipients("A", "private", "missing", positions, tribes).is_empty(), "Unknown private recipient rejected")
	check(channels.command("A", "call_invite", {"target": "B"}, positions.keys(), tribes), "Private call invite")
	var call: String = channels.calls.keys()[0]
	check(channels.recipients("A", "private", call, positions, tribes, true).is_empty(), "Private voice requires acceptance")
	check(not channels.command("C", "call_accept", {"id": call}, positions.keys(), tribes), "Third party cannot accept call")
	check(channels.command("B", "call_accept", {"id": call}, positions.keys(), tribes), "Recipient accepts private call")
	check(channels.recipients("A", "private", call, positions, tribes, true).size() == 2, "Accepted call has only authorized endpoints")
	check(channels.command("B", "block", {"target": "A", "enabled": true}, positions.keys(), tribes), "Block user")
	check(not "B" in channels.recipients("A", "private", call, positions, tribes, true), "Blocked voice not routed")
	check(not "B" in channels.recipients("A", "global", "", positions, tribes), "Blocked text not routed")
	channels.disconnected("B")
	check(channels.calls.is_empty(), "Disconnected calls require new acceptance")
	check(channels.command("A", "group_create", {"name": "Travel", "kind": "group"}, positions.keys(), tribes), "Persistent group creation")
	var channel_snapshot := channels.state()
	var channels_restored := Channels.new()
	channels_restored.restore(channel_snapshot)
	check(channels_restored.state() == channel_snapshot and channels_restored.calls.is_empty(), "Group and block preferences survive restart without restoring calls")
	var invalid_channels := channel_snapshot.duplicate(true)
	invalid_channels["groups"][invalid_channels["groups"].keys()[0]]["members"].append("A")
	check(not Channels.valid_state(invalid_channels), "Reject duplicate saved group membership")
	for i in range(5): check(channels.allow_text("spam", "hello", 1000), "Bounded text allowed")
	check(not channels.allow_text("spam", "too fast", 1001) and channels.allow_text("spam", "later", 1011), "Text flood limit and recovery")
	check(not channels.allow_text("A", "x".repeat(241)), "Oversize message rejected")
	var samples := PackedFloat32Array()
	for i in range(640): samples.append(sin(TAU * 330 * i / 16000.0) * 0.4)
	var encoded := Codec.encode(samples)
	var decoded := Codec.decode(encoded)
	check(encoded.size() == 325 and decoded.size() == 640, "Real ADPCM packet round trip")
	var error := 0.0
	for i in range(80, 640): error += pow(samples[i] - decoded[i].x, 2)
	check(error / 560 < 0.02, "Decoded signal remains close to original")
	var invalid := encoded.duplicate()
	invalid.encode_u16(0, 65535)
	check(Codec.decode(invalid).is_empty(), "Malformed audio count rejected before allocation")
	check(Codec.decode(encoded.slice(0, 10)).is_empty(), "Truncated packet rejected")
	check(Voice.proximity_gain(5) == 1 and Voice.proximity_gain(30) == 0 and Voice.proximity_gain(31) == 0, "Voice gain follows boundaries")
	check(Voice.proximity_gain(10) > Voice.proximity_gain(20), "Voice attenuation is continuous")
	var gfx := Graphics.new()
	check(gfx.applied["preset"] == 2, "Medium is default presentation")
	gfx.choose_preset(0)
	check(gfx.pending["vegetation"] < gfx.applied["vegetation"], "Very Low changes vegetation")
	gfx.cancel()
	check(gfx.pending == gfx.applied, "Cancel preserves applied graphics")
	gfx.set_pending("render_scale", 0.5)
	check(gfx.pending["render_scale"] == 0.5 and gfx.applied["render_scale"] == 1.0, "Render scale is staged until apply")
	gfx.set_pending("render_scale", 0.1)
	check(gfx.pending["render_scale"] == 0.5, "Reject unsupported render scale")
	var locale_path := "/tmp/tribes-locale-%d.cfg" % OS.get_process_id()
	var localization := Localization.new(locale_path)
	check(not localization.chosen, "First run has no language preference")
	for code in Localization.CODES:
		check(localization.select(code), "Locale selection saves: " + code)
		check(not localization.text("Settings").is_empty(), "Translated settings available: " + code)
	check(localization.select("ja") and localization.text("Name") == "名前" and Catalog.display_name("copper_ore") == "銅鉱石", "Japanese UI and compound item translations are real")
	check(Localization.new(locale_path).locale == "ja", "Language persists across restart")
	DirAccess.remove_absolute(locale_path)
	TranslationServer.set_locale("en_US")
	var font = preload("res://Assets/Fonts/NotoSansCJK-Regular.ttc")
	check(font.has_char(0x65e5), "Packaged font supports Japanese")
	var data := Appearance.DEFAULT.duplicate(true)
	check(Appearance.valid(data), "Default appearance valid")
	data["height"] = 10.0
	check(not Appearance.valid(data), "Giant cosmetic profile rejected")
	data = Appearance.DEFAULT.duplicate(true)
	data["name"] = "<fake>"
	check(not Appearance.valid(data), "Control/markup name rejected")
	var need := Needs.new()
	var life := Vitals.new()
	need.advance(60, life)
	check(need.hunger < 100 and need.thirst < 100 and life.hp == 100, "Needs decline without instant starvation damage")
	inv.add("berries", 1)
	check(need.eat(inv) and inv.count("berries") == 0, "Eating consumes an actual item")
	check(need.drink() and need.thirst == 100, "Validated drinking restores thirst")
	inv.add("raw_meat", 1)
	check(not need.cook(inv, false) and need.cook(inv, true), "Cooking requires real nearby fire")
	check(inv.count("raw_meat") == 0 and inv.count("cooked_meat") == 1, "Cooking conserves item transaction")
	await integration()
	print("V3 CHECKS=%d FAILED=%d" % [checks, failed])
	quit(0 if failed == 0 else 1)
func integration() -> void:
	var game = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.save_folder = "user://v3-tests/%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	while not game.ready_world: await process_frame
	game.new_game()
	game.player.set_physics_process(false)
	game.set_physics_process(false)
	game.set_process(false)
	check(game.runtime.needs.has(1), "Needs attached to real authoritative player")
	for mode in ["inventory", "graphics", "controls", "communication", "character", "language", "settings"]:
		game.hud.show_panel(mode)
		await process_frame
		check(game.hud.mode == mode, "Functional panel instantiates: " + mode)
	game.hud.show_panel("")
	var graphics_path := "user://preview-%d.cfg" % Time.get_ticks_usec()
	check(game.graphics.persist(graphics_path), "Graphics can save a confirmed configuration")
	var confirmed := FileAccess.get_file_as_bytes(graphics_path)
	var original: Dictionary = game.graphics.applied.duplicate(true)
	game.graphics.set_pending("resolution", Vector2i(1600, 900))
	check(game.graphics.preview(game.world, game.get_viewport(), game.player) and FileAccess.get_file_as_bytes(graphics_path) == confirmed, "Resolution preview leaves confirmed file untouched")
	game.graphics.applied = original
	game.graphics.begin_edit()
	game.graphics.apply_current(game.world, game.get_viewport(), game.player)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(graphics_path))
	check(not game.network_state().has("communication"), "Public snapshots omit private groups and block lists")
	# Feed a synthetic source through the actual mixer/capture/resampling pipeline.
	# The real AudioStreamMicrophone is deliberately never started in this test.
	var voice = game.runtime.voice
	voice.enabled = true
	voice.testing = true
	var source := AudioStreamPlayer.new()
	source.bus = "VoiceCapture"
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = AudioServer.get_mix_rate()
	generator.buffer_length = 0.12
	source.stream = generator
	game.add_child(source)
	source.play()
	var playback: AudioStreamGeneratorPlayback = source.get_stream_playback()
	var cursor := 0
	var peak := 0.0
	for step in range(12):
		var samples := PackedVector2Array()
		for i in range(playback.get_frames_available()):
			samples.append(Vector2.ONE * sin(TAU * 440 * cursor / AudioServer.get_mix_rate()) * 0.35)
			cursor += 1
		playback.push_buffer(samples)
		await create_timer(0.05).timeout
		peak = maxf(peak, voice.level)
	check(voice.captured_packets > 0 and peak > 0.2, "Synthetic mixer signal is really captured, resampled and encoded")
	check(voice.played_samples > 0 and not voice.microphone.playing, "Loopback decodes and feeds playback without starting a microphone")
	source.stop()
	source.queue_free()
	voice.stop()
	var profile := Appearance.DEFAULT.duplicate(true)
	profile["name"] = "Test Hero"
	profile["height"] = 1.35
	profile["eye_color"] = 4
	game.runtime.command(1, "appearance", profile)
	var short_height: float = game.player.avatar.scale.y
	profile["height"] = 1.65
	game.runtime.command(1, "appearance", profile)
	check(game.player.avatar.scale.y > short_height and is_equal_approx(game.player.body_shape.shape.height, 1.82), "Cosmetic height changes actual mesh without changing collision")
	check(game.player._materials["eye"].albedo_color == Appearance.EYES[4], "Eye color changes actual material")
	check(game.player.avatar.get_child(game.player.avatar.get_child_count() - 1).skeleton.get_bone_count() == 9, "Model uses live skeletal attachments")
	game.runtime.needs[1].hunger = 42
	var wildlife = game.runtime.wildlife
	check(wildlife.animals.size() == 96 and preload("res://Animals/Director.gd").valid_state(wildlife.capture()), "Six animal species are instantiated and serializable")
	var animal = wildlife.animals[0]
	game.player.position = animal.position + Vector3(0, 0, 1)
	check(wildlife.hit(animal, 35) and animal.hp == 0, "Authoritative hunting produces a corpse")
	var meat_before: int = game.inventory.count("raw_meat")
	check(wildlife.harvest(game.player, game.inventory) and game.inventory.count("raw_meat") > meat_before, "Corpse grants real food resources")
	check(not wildlife.harvest(game.player, game.inventory), "Corpse cannot grant loot twice")
	game.runtime._animal_damage(1, 999)
	check(game.player.vitals.hp == 80, "Animal attack route caps a hit at twenty HP")
	game.world.add_fire(game.player.position + Vector3(1, -0.1, 0))
	game.runtime.command(1, "cook", {})
	game.runtime._tick_activities(2)
	check(game.inventory.count("cooked_meat") > 0, "Hunted meat cooks at an actual nearby fire")
	game.player.position = Vector3(0, game.world.height_at(0, 0) + 0.1, 0)
	game.player.rotation.y = 0
	game.player.attack_time = 0
	game.player.stamina = 100
	game.inventory.add("bow", 1)
	game.inventory.add("arrow", 1)
	for index in range(36):
		if game.inventory.slots[index].get("id", "") == "bow":
			game.inventory.equip(index)
	var target = wildlife.animals[1]
	target.set_physics_process(false)
	target.position = game.player.position + Vector3(0, 0, -4)
	var old_hp: int = target.hp
	game.runtime.command(1, "combat", {"kind": "light"})
	check(game.inventory.count("arrow") == 0 and target.hp < old_hp, "Primary bow attack consumes ammunition and damages an actual target")
	game.inventories[1].add("berries", 4)
	check(game.save_game(), "New profile, inventory and needs save together")
	var saved: Dictionary = Store.load_world(game.save_folder)
	check(saved.get("version") == 4 and saved["players"]["1"]["appearance"]["name"] == "Test Hero", "Appearance persists through version-four migration")
	check(saved["players"]["1"]["survival"]["hunger"] == 42 and Inventory.valid_state(saved["players"]["1"]["inventory_state"]), "Needs and exact slots persisted")
	await game.quit_game(0 if failed == 0 else 1,false)
