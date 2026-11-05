extends Node
## ENet transports intentions to the authority; clients never provide gameplay results.
## All peers must mount this node at /root/TribesOfFire/Session.

signal peer_joined(id: int)
signal peer_left(id: int)
signal state_received(state: Dictionary)
signal intent_received(id: int, intent: Dictionary)
signal action_received(id: int, action: String)
signal connection_ready()
signal failed(message: String)
signal command_received(id: int, command: String, data: Dictionary)
signal event_received(kind: String, data: Dictionary)
signal voice_requested(id: int, sequence: int, packet: PackedByteArray, channel: String, target: String)
signal voice_received(id: int, sequence: int, packet: PackedByteArray, channel: String)
signal admin_requested(id: int, action: String, data: Dictionary)
const ServerConfig = preload("res://Networking/ServerConfig.gd")
const SnapshotCodec = preload("res://Networking/SnapshotCodec.gd")
const PROTOCOL_VERSION := 6
const COMMANDS := ["factory_route","factory_unroute","energy_connect","energy_disconnect","energy_toggle","energy_install","team_ping","trade_offer","trade_accept","trade_cancel","station_select","station_load","station_refund","tribe_war","tribe_alliance","tribe_accept_alliance","tribe_break_alliance","tribe_peace","tribe_accept_peace","factory_load","factory_take","dig","appearance", "eat", "drink", "cook", "respawn", "inventory_sort", "inventory_move", "inventory_drop", "equip", "unequip", "craft", "interact", "combat", "mine", "build", "tribe_create", "tribe_invite", "tribe_accept", "tribe_leave", "tribe_kick", "tribe_leader", "chat", "group_create", "group_invite", "group_accept", "group_leave", "group_kick", "call_invite", "call_accept", "call_leave", "block", "chest_transfer", "refuel", "research", "craft_cancel", "repair", "plant", "harvest_crop", "fish", "tame", "map_mark", "map_remove"]

const DEFAULT_PORT := 24567
const MAX_PLAYERS := 100
const INPUTS_PER_SECOND := 90
const ACTIONS_PER_SECOND := 12
const GAME_ACTIONS := ["attack", "craft_fire", "craft_shelter", "place_fire", "place_shelter"]
const ADMIN_ACTIONS := ["save", "weather_clear", "weather_light_rain", "weather_heavy_rain", "weather_storm", "weather_fog"]

var role: String = "offline"
var local_id: int = 1
var maximum_players: int = 16
var accepted_peers: Dictionary = {}
var rejected_commands: int = 0
var _rate: Dictionary = {}
var _pending: Dictionary = {}
var _keys: Dictionary = {}
var _identity: String = ""
var local_admin: bool = false
var _leaving: bool = false
var _world_owner: String = ""
var server_options: Dictionary = ServerConfig.defaults()
var _password: String = ""
var _challenges: Dictionary = {}
var _snapshot_out: Dictionary = {}
var _snapshot_in: Dictionary = {}
var _snapshot_sequence: int = 0
var _moderation_path: String = ""
var _banned: Dictionary = {}
var _muted_until: Dictionary = {}
var snapshot_bytes_sent: int = 0
var snapshot_uncompressed_bytes: int = 0
var snapshot_packets: int = 0
var voice_rate_drops: int = 0
var audit_counts: Dictionary = {}
var _audit_file: FileAccess
var _last_audit_usec: int = 0

func _ready() -> void:
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_server_disconnected)

func _process(_delta: float) -> void:
	if role not in ["host", "dedicated"]:
		return
	for id in _pending.keys():
		if Time.get_ticks_msec() - int(_pending[id]) > 10000:
			_pending.erase(id)
			_challenges.erase(id)
			multiplayer.multiplayer_peer.disconnect_peer(id)
	if Time.get_ticks_usec() - _last_audit_usec > 10000000 and not audit_counts.is_empty():
		flush_audit()

func player_key(id: int) -> String:
	return "1" if id == 1 else str(_keys.get(id, ""))

func local_identity_hash() -> String:
	if _identity.is_empty() and not _load_identity():
		return ""
	return _identity.sha256_text()

func set_world_owner(identity_hash: String) -> void:
	_world_owner = identity_hash if _valid_identity(identity_hash) else ""

func set_local_profile_key(key: String) -> void:
	if role == "client" and local_id > 1 and (key == "1" or _valid_identity(key)):
		_keys[local_id] = key

func profile_key_for_identity(identity_hash: String) -> String:
	var key := "1" if not _world_owner.is_empty() and identity_hash == _world_owner else identity_hash
	if key in _keys.values() or (role == "host" and key == "1"):
		return ""
	return key

static func _valid_identity(value: String) -> bool:
	if value.length() != 64:
		return false
	for character in value:
		if character not in "0123456789abcdef":
			return false
	return true

func _load_identity() -> bool:
	var config := ConfigFile.new()
	var error: Error = config.load("user://identity.cfg")
	if error == OK:
		var stored: Variant = config.get_value("identity", "token", "")
		if stored is String and _valid_identity(stored):
			_identity = stored
			return true
	var random := Crypto.new().generate_random_bytes(32)
	if random.size() != 32:
		return false
	_identity = random.hex_encode()
	config = ConfigFile.new()
	config.set_value("identity", "token", _identity)
	return config.save("user://identity.cfg") == OK

func is_authority() -> bool:
	return role in ["offline", "host", "dedicated"]

func offline() -> void:
	close()
	role = "offline"
	local_id = 1
	_leaving = false
	connection_ready.emit.call_deferred()

func host_game(port: int = DEFAULT_PORT, max_players: int = 16, dedicated: bool = false) -> Error:
	if port < 1 or port > 65535 or max_players < 1 or max_players > MAX_PLAYERS:
		return ERR_INVALID_PARAMETER
	close()
	var peer := ENetMultiplayerPeer.new()
	var remote_capacity: int = max_players if dedicated else maxi(1, max_players - 1)
	var error: Error = peer.create_server(port, remote_capacity, 4)
	if error != OK:
		return error
	maximum_players = max_players
	role = "dedicated" if dedicated else "host"
	local_id = 1
	# Gameplay is server-only: clients do not need peer-to-peer relay or peer announcements.
	# This also avoids racing relay notifications when several clients leave together.
	if multiplayer is SceneMultiplayer:
		multiplayer.server_relay = false
	multiplayer.multiplayer_peer = peer
	connection_ready.emit.call_deferred()
	return OK

func join_game(address: String, port: int = DEFAULT_PORT, password: String = "") -> Error:
	if address.strip_edges().is_empty() or address.length() > 253 or port < 1 or port > 65535:
		return ERR_INVALID_PARAMETER
	if password.length() > 128 or password.to_utf8_buffer().has(0):
		return ERR_INVALID_PARAMETER
	close()
	_password = password
	role = "client"
	local_id = 0
	if not _load_identity():
		failed.emit("Não foi possível salvar a identidade local / Could not save the local identity.")
		return ERR_FILE_CANT_WRITE
	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address.strip_edges(), port, 4)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	return OK

func close() -> void:
	flush_audit()
	var transport: MultiplayerPeer = multiplayer.multiplayer_peer
	# Detach SceneMultiplayer before destroying ENet channels; its teardown can send packets.
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	if transport != null:
		transport.close()
	accepted_peers.clear()
	_pending.clear()
	_challenges.clear()
	_keys.clear()
	_rate.clear()
	_snapshot_out.clear()
	_snapshot_in.clear()
	_snapshot_sequence = 0
	local_admin = false
	_password = ""
	_world_owner = ""
	_leaving = false
	role = "offline"
	local_id = 1

func graceful_leave() -> void:
	if _client_connected():
		_leaving = true
		_leave.rpc_id(1)
		# Allow the server to stop streaming before the underlying ENet channels disappear.
		await get_tree().create_timer(0.5).timeout
	close()

func send_intent(data: Dictionary) -> void:
	var clean := sanitize_intent(data)
	if clean.is_empty():
		rejected_commands += 1
		return
	if is_authority():
		if role != "dedicated":
			intent_received.emit(1, clean)
	elif _client_connected():
		_submit_intent.rpc_id(1, clean)

func send_action(action: String) -> void:
	if action not in GAME_ACTIONS and action not in ADMIN_ACTIONS:
		rejected_commands += 1
		return
	if is_authority():
		if role != "dedicated" or action in ADMIN_ACTIONS:
			action_received.emit(1, action)
	elif action in GAME_ACTIONS and _client_connected():
		_submit_action.rpc_id(1, action)
	else:
		rejected_commands += 1

func broadcast(state: Dictionary) -> void:
	if role not in ["host", "dedicated"]:
		return
	var transport: ENetMultiplayerPeer = multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if transport == null:
		return
	# A full world snapshot may exceed the MTU, so use ENet's reliable fragmentation.
	# Check each transport too: disconnect callbacks can arrive after a physics frame.
	for id in accepted_peers:
		var peer: ENetPacketPeer = transport.get_peer(id)
		if peer != null and peer.get_state() == ENetPacketPeer.STATE_CONNECTED and peer.get_channels() > 0:
			_receive_state.rpc_id(id, state)

func _client_connected() -> bool:
	return role == "client" and local_id > 1 and multiplayer.multiplayer_peer is ENetMultiplayerPeer \
		and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func sanitize_intent(data: Dictionary) -> Dictionary:
	# Bound every accepted component before constructing vectors or touching physics.
	if data.size() > 7:
		return {}
	for key in data:
		if key not in ["move", "yaw", "jump", "sprint", "crouch", "block", "dodge"]:
			return {}
	var movement: Variant = data.get("move", [0.0, 0.0])
	var vector := Vector2.ZERO
	if movement is Vector2:
		vector = movement
	elif movement is Array and movement.size() == 2 \
			and _number(movement[0]) and _number(movement[1]):
		vector = Vector2(float(movement[0]), float(movement[1]))
	else:
		return {}
	if not vector.is_finite() or absf(vector.x) > 1.0 or absf(vector.y) > 1.0:
		return {}
	var angle: Variant = data.get("yaw", 0.0)
	var jumping: Variant = data.get("jump", false)
	var sprinting: Variant = data.get("sprint", false)
	if not _number(angle) or absf(float(angle)) > 100000.0 \
			or not jumping is bool or not sprinting is bool:
		return {}
	vector = vector.limit_length(1.0)
	var result := {"move": [vector.x, vector.y], "yaw": wrapf(float(angle), -PI, PI), "jump": jumping, "sprint": sprinting}
	for key in ["crouch", "block", "dodge"]:
		if data.has(key):
			if not data[key] is bool:
				return {}
			result[key] = data[key]
	return result

func _allowed(sender: int, kind: String, limit: int) -> bool:
	if role not in ["host", "dedicated"] or not accepted_peers.has(sender):
		rejected_commands += 1
		_audit("unaccepted_" + kind)
		return false
	var key := "%d:%s" % [sender, kind]
	var now := Time.get_ticks_msec()
	var bucket: Dictionary = _rate.get(key, {"start": now, "count": 0})
	if now - int(bucket["start"]) >= 1000:
		bucket = {"start": now, "count": 0}
	bucket["count"] = int(bucket["count"]) + 1
	_rate[key] = bucket
	if int(bucket["count"]) > limit:
		rejected_commands += 1
		_audit("rate_" + kind)
		return false
	return true

@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func _submit_intent(data: Dictionary) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if not _allowed(sender, "input", INPUTS_PER_SECOND):
		return
	var clean := sanitize_intent(data)
	if clean.is_empty():
		rejected_commands += 1
		return
	intent_received.emit(sender, clean)

@rpc("any_peer", "call_remote", "reliable", 2)
func _submit_action(action: String) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if not _allowed(sender, "action", ACTIONS_PER_SECOND):
		return
	if action not in GAME_ACTIONS:
		rejected_commands += 1
		return
	action_received.emit(sender, action)

@rpc("authority", "call_remote", "reliable", 0)
func _receive_state(state: Dictionary) -> void:
	if role == "client":
		state_received.emit(state)

static func password_proof(password: String, nonce: String, token: String, version: String, protocol: int = PROTOCOL_VERSION) -> String:
	var crypto := Crypto.new()
	var message := "%s:%s:%s:%d" % [nonce, token.sha256_text(), version, protocol]
	return crypto.hmac_digest(HashingContext.HASH_SHA256, password.to_utf8_buffer(), message.to_utf8_buffer()).hex_encode()

@rpc("authority", "call_remote", "reliable", 2)
func _challenge(nonce: String, protocol: int, version: String, required: bool, server_name: String) -> void:
	if role != "client" or nonce.length() != 64:
		return
	var local_version := str(ProjectSettings.get_setting("application/config/version", ""))
	if protocol != PROTOCOL_VERSION or version != local_version:
		close()
		failed.emit("Incompatible game version / Versão do jogo incompatível.")
		return
	if server_name.length() > 64:
		return
	var proof := password_proof(_password, nonce, _identity, local_version) if required else ""
	_authenticate.rpc_id(1, _identity, proof, PROTOCOL_VERSION, local_version)

@rpc("any_peer", "call_remote", "reliable", 2)
func _authenticate(token: String, proof: String = "", protocol: int = -1, version: String = "") -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if role not in ["host", "dedicated"] or not _pending.has(sender):
		return
	if not _valid_identity(token) or protocol != PROTOCOL_VERSION or version != str(ProjectSettings.get_setting("application/config/version", "")):
		_reject_handshake(sender, "Incompatible game version / Versão do jogo incompatível.")
		return
	var identity := token.sha256_text()
	if _banned.has(identity):
		_reject_handshake(sender, "Access denied / Acesso recusado.")
		return
	var password := str(server_options.get("password", ""))
	if not password.is_empty():
		var expected := password_proof(password, str(_challenges.get(sender, "")), token, version)
		if proof.length() != 64 or not Crypto.new().constant_time_compare(expected.to_utf8_buffer(), proof.to_utf8_buffer()):
			_reject_handshake(sender, "Incorrect server password / Senha do servidor incorreta.")
			return
	var key := profile_key_for_identity(token.sha256_text())
	# A reconnect can reclaim an offline record, never another currently active peer.
	if key.is_empty():
		_reject_handshake(sender, "Identity already connected / Identidade já conectada.")
		return
	_pending.erase(sender)
	_challenges.erase(sender)
	_keys[sender] = key
	accepted_peers[sender] = true
	peer_joined.emit(sender)
	_audit("authenticated")

func _reject_handshake(id: int, reason: String) -> void:
	_pending.erase(id)
	_challenges.erase(id)
	_audit("authentication_rejected")
	_rejected.rpc_id(id, reason)
	var transport := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if transport != null:
		var peer := transport.get_peer(id)
		if peer != null: peer.peer_disconnect_later()

@rpc("any_peer", "call_remote", "reliable", 2)
func _leave() -> void:
	if role not in ["host", "dedicated"]:
		return
	var sender: int = multiplayer.get_remote_sender_id()
	_peer_disconnected(sender)
	var transport: ENetMultiplayerPeer = multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if transport != null:
		var peer: ENetPacketPeer = transport.get_peer(sender)
		if peer != null and peer.get_state() == ENetPacketPeer.STATE_CONNECTED:
			peer.peer_disconnect_later()

func _peer_connected(id: int) -> void:
	if role not in ["host", "dedicated"]:
		return
	var local_count := 1 if role == "host" else 0
	if accepted_peers.size() + _pending.size() + local_count >= maximum_players:
		multiplayer.multiplayer_peer.disconnect_peer(id)
		return
	_pending[id] = Time.get_ticks_msec()
	var nonce := Crypto.new().generate_random_bytes(32).hex_encode()
	_challenges[id] = nonce
	_challenge.rpc_id(id, nonce, PROTOCOL_VERSION, str(ProjectSettings.get_setting("application/config/version", "")), not str(server_options.get("password", "")).is_empty(), str(server_options.get("name", "Tribes of Fire")))

func _peer_disconnected(id: int) -> void:
	_pending.erase(id)
	_challenges.erase(id)
	_snapshot_out.erase(id)
	if accepted_peers.erase(id):
		for bucket in _rate.keys():
			if str(bucket).begins_with("%d:" % id):
				_rate.erase(bucket)
		peer_left.emit(id)
		# peer_left handlers can still resolve the stable player key while persisting.
		_keys.erase(id)

func reject_peer(id: int, reason: String) -> void:
	if role not in ["host", "dedicated"] or not accepted_peers.has(id):
		return
	_rejected.rpc_id(id, reason.left(240))
	_peer_disconnected(id)
	var transport := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if transport != null:
		var peer := transport.get_peer(id)
		if peer != null:
			peer.peer_disconnect_later()

@rpc("authority", "call_remote", "reliable")
func _rejected(reason: String) -> void:
	if role == "client":
		failed.emit(reason)

func _connected() -> void:
	if role == "client":
		local_id = multiplayer.get_unique_id()
		_keys[local_id] = _identity.sha256_text()
		_leaving = false
		connection_ready.emit()

func _connection_failed() -> void:
	if role != "client":
		return
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	local_id = 0
	failed.emit("Não foi possível conectar ao servidor / Could not connect to server.")

static func valid_command(command: String, data: Dictionary) -> bool:
	if command not in COMMANDS or not _bounded(data, 0) or JSON.stringify(data).length() > 4096:
		return false
	if command == "chest_transfer" and data.has("expected_item"):
		if not data["expected_item"] is String or not preload("res://Items/Catalog.gd").known(data["expected_item"]):return false
		var base:=data.duplicate();base.erase("expected_item")
		return valid_command(command,base)
	if command in ["inventory_move", "inventory_drop"] and data.has("expected"):
		var expected: Variant = data["expected"]
		if not expected is Dictionary or expected.size() != 2 or not expected.get("id") is String or not preload("res://Items/Catalog.gd").known(expected["id"]): return false
		if not _number(expected.get("count")) or expected["count"] < 1 or expected["count"] > 9999 or expected["count"] != floorf(expected["count"]): return false
		var base := data.duplicate(true); base.erase("expected")
		return valid_command(command, base)
	if command in ["craft","craft_cancel","station_select","station_load","station_refund","factory_load","factory_take","trade_offer","trade_accept","trade_cancel","energy_connect","energy_disconnect","energy_toggle","energy_install","factory_route","factory_unroute"] and data.has("request_id"):
		if not data["request_id"] is String or data["request_id"].is_empty() or data["request_id"].length()>64:return false
		var base:=data.duplicate();base.erase("request_id")
		return valid_command(command,base)
	if command=="craft_cancel" and data.has("job_uid"):
		var uid: Variant = data["job_uid"]
		if not uid is String or uid.length()!=32 or not uid.is_valid_hex_number(false): return false
		var base:=data.duplicate();base.erase("job_uid")
		return valid_command(command,base)
	if command in ["energy_connect","energy_disconnect"]:
		return data.size()==2 and _power_port(data.get("a")) and _power_port(data.get("b")) and data["a"]!=data["b"]
	if command=="energy_toggle": return data.size()==1 and _power_port(data.get("id")) and data["id"].begins_with("n")
	if command == "appearance":
		return preload("res://Character/Appearance.gd").valid(data)
	var fields: Dictionary = {"factory_route":["from","to","item"],"factory_unroute":["from","to","item"],"energy_install":["station"],"team_ping":["position"],"trade_offer":["target","give","amount","want","quantity"],"trade_accept":["id"],"trade_cancel":["id"],"station_select":["station","recipe"],"station_load":["station","amount"],"station_refund":["station"],"tribe_war":["target"],"tribe_alliance":["target"],"tribe_accept_alliance":["target"],"tribe_break_alliance":["target"],"tribe_peace":["target"],"tribe_accept_peace":["target"],"factory_load":["station"],"factory_take":["station"],"dig":[],
		"eat": ["item"], "drink": [], "cook": [], "respawn": [], "inventory_sort": [], "inventory_move": ["from", "to", "amount"], "inventory_drop": ["slot", "amount"], "equip": ["slot"], "unequip": ["equipment"], "craft": ["recipe"], "interact": [], "mine": [], "combat": ["kind"],
		"tribe_create": ["name"], "tribe_invite": ["target"], "tribe_accept": [], "tribe_leave": [], "tribe_kick": ["target"], "tribe_leader": ["target"],
		"chat": ["channel","target","text"], "group_create": ["name","kind"], "group_invite": ["id","target"], "group_accept": [], "group_leave": ["id"], "group_kick": ["id","target"], "call_invite": ["target"], "call_accept": ["id"], "call_leave": ["id"], "block": ["target","enabled"],
		"chest_transfer": ["structure","slot","amount","to_chest"], "refuel": [], "research": ["technology"], "craft_cancel": ["index"], "repair": ["slot"], "plant": ["structure","crop"], "harvest_crop": ["structure"], "fish": [], "tame": ["animal"], "map_mark": ["position","name","color","shared"], "map_remove": ["id"]}
	if command == "build":
		if data.get("piece") in preload("res://Energy/Grid.gd").KINDS: return data.size()==2 and _number(data.get("rotation")) and data["rotation"]==floorf(data["rotation"]) and data["rotation"]>=0 and data["rotation"]<=3
		if not data.get("piece") is String or (not data["piece"] in ["foundation","floor","wall","window","door","roof","stairs","fence","bed","chest","garden","lantern","torch","raft","totem"] and not preload("res://Items/Catalog.gd").station_ids().has(data["piece"])): return false
		if data.size() != (2 if data.has("rotation") else 1): return false
		return not data.has("rotation") or (_number(data["rotation"]) and data["rotation"] == floorf(float(data["rotation"])) and data["rotation"] >= 0 and data["rotation"] <= 3)
	if not fields.has(command) or data.size() != fields[command].size(): return false
	for key in fields[command]:
		if not data.has(key): return false
		if key in ["enabled","shared","to_chest"]:
			if not data[key] is bool: return false
		elif key == "position":
			if not data[key] is Array or data[key].size()!=2: return false
			for value in data[key]:
				if not _number(value) or absf(float(value))>768: return false
		elif key in ["slot","from","to","amount","index","animal","structure","color","station","quantity"] or (key=="id" and command=="map_remove"):
			if not _number(data[key]) or float(data[key]) != floorf(float(data[key])): return false
			var limits: Dictionary = {"station":[0,31],"slot":[0,35],"from":[0,35],"to":[0,35],"amount":[1,9999],"quantity":[1,9999],"index":[0,4],"animal":[0,95],"structure":[1,1000000],"color":[0,5],"id":[1,1000000]}
			if data[key]<limits[key][0] or data[key]>limits[key][1]: return false
		elif not data[key] is String: return false
	if command in ["factory_route","factory_unroute"] and not preload("res://Items/Catalog.gd").known(data["item"]): return false
	if command=="trade_offer" and (not preload("res://Items/Catalog.gd").known(data["give"]) or not preload("res://Items/Catalog.gd").known(data["want"])): return false
	if command in ["trade_accept","trade_cancel"] and (data["id"].length()!=32 or not data["id"].is_valid_hex_number(false)): return false
	if command=="map_mark" and (data["name"].strip_edges().is_empty() or data["name"].length()>40): return false
	if command=="research" and data["technology"] not in ["knapping","firecraft","leatherwork","metalwork"]: return false
	if command=="plant" and data["crop"]!="berries": return false
	if command == "combat" and data["kind"] not in ["light", "heavy", "ranged"]: return false
	if command == "unequip" and data["equipment"] not in ["hand", "offhand", "armor"]: return false
	if command == "chat" and (data["channel"] not in ["global", "local", "private", "group", "tribe", "diplomacy", "allies"] or data["text"].length() > 240): return false
	if command == "group_create" and data["kind"] not in ["group", "diplomacy"]: return false
	return true

static func _bounded(value: Variant, depth: int) -> bool:
	if depth > 3:
		return false
	if value is String:
		return value.length() <= 256 and not value.to_utf8_buffer().has(0)
	if value is bool or value == null:
		return true
	if value is int or value is float:
		return is_finite(float(value)) and absf(float(value)) <= 1000000000
	if value is Dictionary:
		if value.size() > 32:
			return false
		for key in value:
			if not key is String or not _bounded(key, depth + 1) or not _bounded(value[key], depth + 1):
				return false
		return true
	if value is Array:
		if value.size() > 24:
			return false
		for entry in value:
			if not _bounded(entry, depth + 1):
				return false
		return true
	return false

func send_command(command: String, data: Dictionary = {}) -> void:
	if not valid_command(command, data):
		rejected_commands += 1
		return
	if is_authority():
		command_received.emit(1, command, data.duplicate(true))
	elif _client_connected():
		_submit_command.rpc_id(1, command, data)

@rpc("any_peer", "call_remote", "reliable", 2)
func _submit_command(command: String, data: Dictionary) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if not _allowed(sender, "command", 16) or not valid_command(command, data):
		rejected_commands += 1
		return
	command_received.emit(sender, command, data)

func notify(id: int, kind: String, data: Dictionary) -> void:
	if not is_authority():
		return
	if id == 1 and role != "dedicated":
		event_received.emit(kind, data)
	elif accepted_peers.has(id):
		_deliver_event.rpc_id(id, kind, data)

@rpc("authority", "call_remote", "reliable", 2)
func _deliver_event(kind: String, data: Dictionary) -> void:
	if role == "client":
		event_received.emit(kind, data)

func send_voice(sequence: int, packet: PackedByteArray, channel: String, target: String) -> void:
	if packet.size() < 5 or packet.size() > 512 or sequence < 0 or channel.length() > 24 or target.length() > 128:
		return
	if is_authority() and role != "dedicated":
		voice_requested.emit(1, sequence, packet, channel, target)
	elif _client_connected():
		_submit_voice.rpc_id(1, sequence, packet, channel, target)

@rpc("any_peer", "call_remote", "unreliable_ordered", 3)
func _submit_voice(sequence: int, packet: PackedByteArray, channel: String, target: String) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if not _allowed(sender, "voice", 30) or sequence < 0 or packet.size() < 5 or packet.size() > 512 or channel.length() > 24 or target.length() > 128:
		return
	voice_requested.emit(sender, sequence, packet, channel, target)

func relay_voice(recipient: int, sender: int, sequence: int, packet: PackedByteArray, channel: String) -> void:
	if not is_authority():
		return
	if recipient == 1 and role != "dedicated":
		voice_received.emit(sender, sequence, packet, channel)
	elif accepted_peers.has(recipient):
		_deliver_voice.rpc_id(recipient, sender, sequence, packet, channel)

@rpc("authority", "call_remote", "unreliable_ordered", 3)
func _deliver_voice(sender: int, sequence: int, packet: PackedByteArray, channel: String) -> void:
	if role == "client" and packet.size() >= 5 and packet.size() <= 512:
		voice_received.emit(sender, sequence, packet, channel)

func _server_disconnected() -> void:
	if role != "client":
		return
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	local_id = 0
	if not _leaving:
		failed.emit("Servidor desconectado / Server disconnected.")

func configure_server(options: Dictionary, moderation_path: String = "user://server-moderation.json") -> String:
	var validated := ServerConfig.normalize(options)
	if not validated["error"].is_empty(): return validated["error"]
	server_options = validated["data"]
	_moderation_path = moderation_path
	_banned.clear()
	_muted_until.clear()
	for identity in server_options["bans"]: _banned[identity] = true
	if FileAccess.file_exists(moderation_path):
		var file := FileAccess.open(moderation_path, FileAccess.READ)
		if file == null: return "Could not read server moderation state"
		if file.get_length() > 262144:
			file.close()
			return "Server moderation state exceeds its size limit"
		var parser := JSON.new()
		var error := parser.parse(file.get_as_text())
		file.close()
		if error != OK or not _valid_moderation(parser.data):
			return "Invalid server moderation state; existing file was preserved"
		for identity in parser.data["bans"]: _banned[identity] = true
		_muted_until = parser.data["mutes"].duplicate()
	return ""

static func _valid_moderation(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != 1 or not data.get("bans") is Array or not data.get("mutes") is Dictionary or data["bans"].size() > 1024 or data["mutes"].size() > 1024:
		return false
	for identity in data["bans"]:
		if not ServerConfig.identity_valid(identity): return false
	for identity in data["mutes"]:
		var until: Variant = data["mutes"][identity]
		if not ServerConfig.identity_valid(identity) or not (until is float or until is int) or not is_finite(float(until)) or until < 0 or until > 1000000000000:
			return false
	return true

func _persist_moderation() -> bool:
	if _moderation_path.is_empty(): return false
	var data := {"version": 1, "bans": _banned.keys(), "mutes": _muted_until}
	if not _valid_moderation(data): return false
	var absolute := ProjectSettings.globalize_path(_moderation_path)
	if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir()) != OK: return false
	var temporary := _moderation_path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK: return false
	# Preserve the prior policy if a replacement fails; never silently forget a ban.
	var backup := absolute + ".bak"
	if FileAccess.file_exists(_moderation_path):
		if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup) != OK: return false
		if DirAccess.rename_absolute(absolute, backup) != OK: return false
	error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), absolute)
	if error != OK and FileAccess.file_exists(backup): DirAccess.rename_absolute(backup, absolute)
	return error == OK

func _identity_for_peer(id: int) -> String:
	var identity := player_key(id)
	return _world_owner if identity == "1" else identity

func is_admin(id: int) -> bool:
	if not is_authority(): return id == local_id and local_admin
	if id == 1: return true # Local process owner; remote peers never get transport ID 1.
	return accepted_peers.has(id) and _identity_for_peer(id) in server_options.get("admins", [])

func is_muted(id: int) -> bool:
	return float(_muted_until.get(_identity_for_peer(id), 0)) > Time.get_unix_time_from_system()

func public_server_info() -> Dictionary:
	var result := ServerConfig.public_state(server_options)
	result["players"] = accepted_peers.size() + (1 if role == "host" else 0)
	result["version"] = str(ProjectSettings.get_setting("application/config/version", ""))
	result["protocol"] = PROTOCOL_VERSION
	return result

func send_admin_action(action: String, data: Dictionary = {}) -> void:
	if is_authority(): _handle_admin(1, action, data)
	elif _client_connected(): _submit_admin.rpc_id(1, action, data)

@rpc("any_peer", "call_remote", "reliable", 2)
func _submit_admin(action: String, data: Dictionary) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if not _allowed(sender, "admin", 4): return
	_handle_admin(sender, action, data)

func _handle_admin(sender: int, action: String, data: Dictionary) -> void:
	if not is_admin(sender) or action not in ["kick", "ban", "unban", "mute", "unmute", "players", "save", "shutdown", "set_rule"] or not _bounded(data, 0):
		rejected_commands += 1
		_audit("unauthorized_admin")
		return
	var identity := str(data.get("target", ""))
	var target := 0
	for id in accepted_peers:
		if _identity_for_peer(id) == identity: target = id
	if action in ["kick", "ban", "unban", "mute", "unmute"]:
		if data.size() != 1 or not ServerConfig.identity_valid(identity): return
		var before_bans := _banned.duplicate()
		var before_mutes := _muted_until.duplicate()
		if action == "ban": _banned[identity] = true
		elif action == "unban": _banned.erase(identity)
		elif action == "mute": _muted_until[identity] = Time.get_unix_time_from_system() + 300
		elif action == "unmute": _muted_until.erase(identity)
		if action != "kick" and not _persist_moderation():
			_banned = before_bans
			_muted_until = before_mutes
			notify(sender, "admin", {"ok": false, "action": action})
			_audit("moderation_write_failed")
			return
		if action in ["kick", "ban"] and target != 0: reject_peer(target, "Removed by the server administrator / Removido pelo administrador do servidor.")
	elif action == "set_rule":
		if data.size() != 2 or not data.get("rule") is String or not data.has("value"): return
		var rule: String = data["rule"]
		if rule not in ["pvp", "death_loss", "day_minutes", "night_minutes", "resource_rate", "difficulty"]: return
		var updated := server_options.duplicate(true)
		updated[rule] = data["value"]
		var checked := ServerConfig.normalize(updated)
		if not checked["error"].is_empty(): return
		server_options = checked["data"]
		admin_requested.emit(sender, action, data.duplicate(true))
	elif not data.is_empty():
		return
	elif action == "players":
		var online: Array = []
		for id in accepted_peers: online.append({"peer": id, "identity": _identity_for_peer(id)})
		notify(sender, "admin", {"ok": true, "action": action, "players": online, "server": public_server_info(), "metrics": metrics()})
	elif action == "save":
		action_received.emit(1, "save")
	else:
		admin_requested.emit(sender, action, {})
	_audit("admin_" + action)
	if action != "players": notify(sender, "admin", {"ok": true, "action": action})

func _audit(kind: String) -> void:
	audit_counts[kind] = int(audit_counts.get(kind, 0)) + 1

func flush_audit() -> void:
	_last_audit_usec = Time.get_ticks_usec()
	if audit_counts.is_empty(): return
	if _audit_file == null:
		var directory := ProjectSettings.globalize_path("user://logs")
		if DirAccess.make_dir_recursive_absolute(directory) != OK: return
		_audit_file = FileAccess.open(directory.path_join("network-%d.jsonl" % OS.get_process_id()), FileAccess.WRITE)
	if _audit_file != null:
		# Aggregate only categories. Tokens, passwords, payloads and chat never enter logs.
		_audit_file.store_line(JSON.stringify({"time_utc": Time.get_datetime_string_from_system(true), "system": "network", "level": "info", "counts": audit_counts}))
		_audit_file.flush()
		audit_counts.clear()

func metrics() -> Dictionary:
	return {"snapshot_bytes": snapshot_bytes_sent, "snapshot_full_bytes": snapshot_uncompressed_bytes, "snapshot_packets": snapshot_packets, "rejected_commands": rejected_commands, "voice_rate_drops": voice_rate_drops}

func send_snapshot(id: int, state: Dictionary) -> void:
	if role not in ["host", "dedicated"] or not accepted_peers.has(id): return
	var transport := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if transport == null: return
	var peer := transport.get_peer(id)
	if peer == null or peer.get_state() != ENetPacketPeer.STATE_CONNECTED or peer.get_channels() <= 0: return
	var previous: Dictionary = _snapshot_out.get(id, {})
	var sequence: int = int(previous.get("sequence", 0)) + 1
	var envelope: Dictionary
	if previous.is_empty() or sequence % 100 == 0:
		envelope = {"sequence": sequence, "base": 0, "full": state}
	else:
		envelope = {"sequence": sequence, "base": sequence - 1, "patch": SnapshotCodec.difference(previous["state"], state)}
	_snapshot_out[id] = {"sequence": sequence, "state": state.duplicate(true)}
	snapshot_bytes_sent += var_to_bytes(envelope).size()
	snapshot_uncompressed_bytes += var_to_bytes(state).size()
	snapshot_packets += 1
	_receive_snapshot.rpc_id(id, envelope)

@rpc("authority", "call_remote", "reliable", 0)
func _receive_snapshot(envelope: Dictionary) -> void:
	if role != "client": return
	var sequence := int(envelope.get("sequence", 0))
	if sequence <= _snapshot_sequence: return
	var state: Dictionary
	if envelope.get("full") is Dictionary:
		state = envelope["full"]
	elif int(envelope.get("base", 0)) == _snapshot_sequence and envelope.get("patch") is Dictionary:
		state = SnapshotCodec.apply(_snapshot_in, envelope["patch"])
	else:
		return # The next periodic complete state repairs a lost base after reconnect.
	_snapshot_in = state.duplicate(true)
	_snapshot_sequence = sequence
	state_received.emit(state)

func _exit_tree() -> void:
	flush_audit()
	if _audit_file != null:
		_audit_file.close()
		_audit_file = null

static func _power_port(value: Variant) -> bool:
	return value is String and value.length()>=2 and value.length()<=8 and value.substr(0,1) in ["n","w"] and value.substr(1).is_valid_int() and int(value.substr(1))>=0 and int(value.substr(1))<=1000000
