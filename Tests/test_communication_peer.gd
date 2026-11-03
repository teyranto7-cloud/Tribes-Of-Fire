extends SceneTree
## Synthetic audio only. Exercises the real Main/Runtime/Session, never a microphone.
const Codec = preload("res://Communication/ADPCM.gd")
const Appearance = preload("res://Character/Appearance.gd")
var game
var role: String = "server"
var age: float = 0.0
var ready_age: float = -1.0
var profile_sent: bool = false
var phases: Dictionary = {}
var audio_received: Dictionary = {}
var packets: Array = []
var send_left: float = 0.0
var seq: int = 0
var finish: bool = false
var blocked_seen_at: float = -1.0
var server_finishing: bool = false
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--qa-role="): role = arg.trim_prefix("--qa-role=")
	call_deferred("start")
func start() -> void:
	game = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(game)
	while not game.ready_world: await process_frame
	game.session.event_received.connect(event)
	game.session.voice_received.connect(func(_id, _seq, _packet, channel): audio_received[channel] = int(audio_received.get(channel, 0)) + 1)
	game.session.command_received.connect(observe_command)
	if role != "server":
		# Receive-only opt-in; do not call set_enabled(), so no capture device starts.
		game.runtime.voice.enabled = true
func named(label: String) -> int:
	for id in game.players:
		if game.players[id].appearance["name"] == "Client " + label: return id
	return 0
func identity(label: String) -> String:
	var id := named(label)
	return game.runtime.key(id) if id != 0 else ""
func command(kind: String, data: Dictionary = {}) -> void:
	game.request_command(kind, data)
func message(channel: String, text: String, target: String = "") -> void:
	command("chat", {"channel": channel, "text": text, "target": target})
func group_id(name: String) -> String:
	for id in game.runtime.channel_state.get("groups", {}):
		if game.runtime.channel_state["groups"][id]["name"] == name: return id
	return ""
func _process(delta: float) -> bool:
	age += delta
	if age > 42 and not finish:
		printerr("COMMUNICATION_FAIL timeout role=", role, " phases=", phases.keys(), " audio=", audio_received)
		finish = true
		game.quit_game(1, false)
	if game == null or not game.ready_world or not game.running: return false
	if role == "server":
		for label in ["A", "B", "C"]:
			var id := named(label)
			if id != 0:
				var x := {"A": 0.0, "B": 8.0, "C": 45.0}[label] as float
				game.players[id].position = Vector3(x, game.world.terrain_height(x, 0) + 0.1, 0)
				if label == "B" and ready_age > 0 and age - ready_age > 13:
					game.players[id].position = Vector3(0, game.world.terrain_height(0, -1.8) + 0.1, -1.8)
		if ready_age < 0 and named("A") != 0 and named("B") != 0 and named("C") != 0:
			ready_age = age
		if blocked_seen_at > 0 and age - blocked_seen_at > 1.3 and not server_finishing:
			server_finishing = true
			for id in game.players: game.session.notify(id, "qa_finish", {})
			end_server()
		return false
	if game.player == null: return false
	# Main first completes the automatic headless creation handshake. Sending
	# our custom profile before that acknowledgement races its default profile.
	if not profile_sent and not game.player.creation_pending:
		profile_sent = true
		var profile := Appearance.DEFAULT.duplicate(true)
		profile["name"] = "Client " + role
		profile["eye_color"] = {"A": 4, "B": 3, "C": 2}[role]
		command("appearance", profile)
	if named("A") == 0 or named("B") == 0 or named("C") == 0: return false
	if ready_age < 0: ready_age = age
	var t := age - ready_age
	var me := identity(role)
	if role == "C" and not phases.has("tribe"):
		phases["tribe"] = true
		command("tribe_create", {"name": "Gamma"})
	if role == "B":
		if game.runtime.tribes.invitations.has(me) and not phases.has("tribe_accept"):
			phases["tribe_accept"] = true
			command("tribe_accept")
		for id in game.runtime.channel_state.get("calls", {}):
			if not game.runtime.channel_state["calls"][id]["accepted"] and not phases.has("call"):
				phases["call"] = true
				command("call_accept", {"id": id})
		if t > 16 and not phases.has("block"):
			phases["block"] = true
			command("block", {"target": identity("A"), "enabled": true})
		if t > 15 and not phases.has("tribe_leave"):
			phases["tribe_leave"] = true
			command("tribe_leave")
	if role in ["B", "C"]:
		var invite: Dictionary = game.runtime.channel_state.get("invitation", {})
		if not invite.is_empty() and not phases.has(str(invite["id"])):
			phases[invite["id"]] = true
			command("group_accept")
	if role == "A":
		if t > 0.2 and not phases.has("global"):
			phases["global"] = true
			message("global", "global-proof")
		if t > 0.8 and not phases.has("local"):
			phases["local"] = true
			message("local", "local-proof")
		if t > 1.4 and not phases.has("private"):
			phases["private"] = true
			message("private", "private-proof", identity("B"))
			command("tribe_create", {"name": "Alpha"})
			command("group_create", {"name": "Party", "kind": "group"})
			command("call_invite", {"target": identity("B")})
		if t > 2.5 and group_id("Party") != "" and not phases.has("invite"):
			phases["invite"] = true
			command("group_invite", {"id": group_id("Party"), "target": identity("B")})
			command("tribe_invite", {"target": identity("B")})
		if t > 4.5 and not phases.has("group"):
			phases["group"] = true
			message("group", "group-proof", group_id("Party"))
			queue_audio("proximity", "", 6)
		if t > 6.5 and not phases.has("tribe"):
			phases["tribe"] = true
			message("tribe", "tribe-proof")
			command("group_create", {"name": "Council", "kind": "diplomacy"})
		if t > 8 and group_id("Council") != "" and not phases.has("diplomatic_invite"):
			phases["diplomatic_invite"] = true
			command("group_invite", {"id": group_id("Council"), "target": identity("C")})
		if t > 12.2 and not phases.has("diplomacy"):
			phases["diplomacy"] = true
			message("diplomacy", "diplomacy-proof", group_id("Council"))
			for id in game.runtime.channel_state["calls"]:
				if game.runtime.channel_state["calls"][id]["accepted"]: queue_audio("private", id, 4)
			queue_audio("tribe", "", 4)
			queue_audio("group", group_id("Party"), 4)
			queue_audio("diplomacy", group_id("Council"), 4)
		if t > 14 and not phases.has("friendly_attack"):
			phases["friendly_attack"] = true
			command("combat", {"kind": "light"})
		if t > 15.8 and not phases.has("protected_attack"):
			phases["protected_attack"] = true
			command("combat", {"kind": "light"})
		if not packets.is_empty():
			send_left -= delta
			if send_left <= 0:
				send_left = 0.05
				var next: Array = packets.pop_front()
				seq += 1
				game.session.send_voice(seq, next[2], next[0], next[1])
	return false
func queue_audio(channel: String, target: String, count: int) -> void:
	var samples := PackedFloat32Array()
	for i in range(640): samples.append(sin(TAU * 330 * i / 16000.0) * 0.3)
	var packet := Codec.encode(samples)
	for i in range(count): packets.append([channel, target, packet])
func observe_command(id: int, kind: String, data: Dictionary) -> void:
	if role == "server" and kind == "block" and id == named("B"):
		await create_timer(0.2).timeout
		game.session.notify(named("A"), "qa_blocked", {})
	if role == "server" and kind == "chat" and data.get("text") == "blocked-proof" and id == named("A"):
		blocked_seen_at = age
func event(kind: String, _data: Dictionary) -> void:
	if kind == "qa_blocked" and role == "A":
		message("private", "blocked-proof", identity("B"))
	if kind == "qa_finish" and not finish:
		finish = true
		verify()
func verify() -> void:
	var texts: Array = game.runtime.messages.map(func(m): return m["text"])
	var ok: bool = "global-proof" in texts
	if role == "B":
		ok = ok and ["local-proof", "private-proof", "group-proof", "tribe-proof"].all(func(text): return text in texts)
		ok = ok and not "diplomacy-proof" in texts and not "blocked-proof" in texts
		ok = ok and ["proximity", "private", "group", "tribe"].all(func(c): return int(audio_received.get(c, 0)) >= 2)
		ok = ok and not audio_received.has("diplomacy") and game.runtime.voice.played_samples > 0
	elif role == "C":
		ok = ok and "diplomacy-proof" in texts
		ok = ok and ["local-proof", "private-proof", "group-proof", "tribe-proof", "blocked-proof"].all(func(text): return not text in texts)
		ok = ok and not audio_received.has("proximity") and not audio_received.has("private") and not audio_received.has("tribe") and not audio_received.has("group")
		ok = ok and int(audio_received.get("diplomacy", 0)) >= 2 and game.runtime.voice.played_samples > 0
	if not ok:
		printerr("COMMUNICATION_FAIL role=", role, " messages=", texts, " audio=", audio_received, " played=", game.runtime.voice.played_samples)
		game.quit_game(1, false)
		return
	print("COMMUNICATION_CLIENT_PASS role=%s messages=%d audio_packets=%s played_samples=%d microphone_started=%s" % [role, texts.size(), audio_received, game.runtime.voice.played_samples, game.runtime.voice.microphone.playing])
	game.quit_game()
func end_server() -> void:
	await create_timer(2).timeout
	if game.runtime.pvp_blocked < 2 or game.runtime.pvp_damage != 0:
		printerr("COMMUNICATION_FAIL PvP protections not exercised: ", game.runtime.pvp_blocked)
		game.quit_game(1, false)
		return
	print("COMMUNICATION_SERVER_PASS clients=3 routing=authority blocks=validated")
	finish = true
	game.quit_game()
