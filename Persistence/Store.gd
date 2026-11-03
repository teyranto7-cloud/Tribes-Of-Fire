extends RefCounted

const WeatherModel = preload("res://Weather/Weather.gd")
const ExposureModel = preload("res://Weather/Exposure.gd")
const InventoryModel = preload("res://Core/Inventory.gd")
const Catalog = preload("res://Items/Catalog.gd")
const Appearance = preload("res://Character/Appearance.gd")
const Survival = preload("res://Survival/Survival.gd")
const Tribes = preload("res://Tribes/System.gd")
const Wildlife = preload("res://Animals/Director.gd")
const Channels = preload("res://Communication/Channels.gd")
const SaveSchema = preload("res://Persistence/SaveSchema.gd")
const MAX_BYTES := 16777216
const MAX_PLAYERS := 1024
static var owned_locks: Dictionary = {}

static func number(value: Variant, low: float, high: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and float(value) >= low and float(value) <= high

static func integer(value: Variant, low: int, high: int) -> bool:
	return number(value, low, high) and float(value) == floorf(float(value))

static func position_valid(value: Variant, extent: float = 61.0) -> bool:
	if not value is Array or value.size() != 3:
		return false
	return number(value[0], -extent, extent) and number(value[1], -30 if extent > 61 else -15, 120 if extent > 61 else 40) \
		and number(value[2], -extent, extent)

static func inventory_valid(value: Variant, legacy: bool = false) -> bool:
	if not value is Dictionary or value.size() > Catalog.ids().size() or (legacy and value.size() != 3):
		return false
	for key in ["wood", "campfire", "axe"]:
		if not integer(value.get(key), 0, 9999):
			return false
	for key in value:
		if not key is String or not Catalog.known(key) or not integer(value[key], 0, 9999):
			return false
	return (not legacy or value["axe"] == 1) and (legacy or integer(value.get("shelter"), 0, 9999))

static func positions_valid(value: Variant, limit: int, extent: float = 61.0) -> bool:
	if not value is Array or value.size() > limit:
		return false
	for p in value:
		if not position_valid(p, extent):
			return false
	return true

static func valid(data: Variant) -> bool:
	if not data is Dictionary or not integer(data.get("version"), 1, 4):
		return false
	if data.has("host_identity"):
		if not data["host_identity"] is String or data["host_identity"].length() != 64:
			return false
		for character in data["host_identity"]:
			if character not in "0123456789abcdef":
				return false
	var modern: bool = int(data["version"]) == 4
	if modern and not SaveSchema.descriptor(data): return false
	var extent := float(data["world"]["size"])*0.5+1.0 if modern and int(data["world"]["generator"]) > 0 else 61.0
	if not integer(data.get("seed"), 0 if modern else 1337, 2147483647 if modern else 1337) or not number(data.get("phase"), 0, 21600 if modern else 2700):
		return false
	var cut: Variant = data.get("cut")
	if not cut is Array or cut.size() > (16384 if modern else 160):
		return false
	var seen: Dictionary = {}
	for id in cut:
		if not integer(id, 0, 65535 if modern else 159) or seen.has(int(id)):
			return false
		seen[int(id)] = true
	if not positions_valid(data.get("fires"), 32, extent):
		return false
	if int(data["version"]) == 1:
		return position_valid(data.get("position")) and inventory_valid(data.get("inventory"), true) \
			and integer(data.get("hp"), 0, 100)
	if not positions_valid(data.get("shelters"), 32, extent) or not data.get("players") is Dictionary:
		return false
	var players: Dictionary = data["players"]
	if players.size() > MAX_PLAYERS:
		return false
	for id in players:
		if not id is String or id.is_empty() or id.length() > 128:
			return false
		var player: Variant = players[id]
		if not player is Dictionary or not position_valid(player.get("position"), extent) \
				or not inventory_valid(player.get("inventory")) or not integer(player.get("hp"), 0, 100):
			return false
		if player.has("quiet_seconds") and not number(player["quiet_seconds"], 0, 3):
			return false
		if player.has("exposure") and (not player["exposure"] is Dictionary or not ExposureModel.valid(player["exposure"])):
			return false
		if player.has("regen_block_left") and not number(player["regen_block_left"], 0, 60):
			return false
		if player.has("survival") and (not player["survival"] is Dictionary or not Survival.valid(player["survival"])):
			return false
		if player.has("appearance") and (not player["appearance"] is Dictionary or not Appearance.valid(player["appearance"])):
			return false
		if player.has("inventory_state"):
			if not player["inventory_state"] is Dictionary or not InventoryModel.valid_state(player["inventory_state"]):
				return false
			var inv := InventoryModel.new()
			inv.restore(player["inventory_state"])
			for key in Catalog.ids():
				if inv.count(key) != int(player["inventory"].get(key, 0)):
					return false
	if data.has("tribes") and (not data["tribes"] is Dictionary or not Tribes.valid_state(data["tribes"])):
		return false
	if data.has("communication") and (not data["communication"] is Dictionary or not Channels.valid_state(data["communication"])):
		return false
	if data.has("animals") and (not data["animals"] is Array or not Wildlife.valid_state(data["animals"])):
		return false
	if data.has("mining"):
		if not data["mining"] is Array or (data["mining"].size() < 22 or data["mining"].size() > 256):
			return false
		for value in data["mining"]:
			if not integer(value, 0, 8):
				return false
	for field in ["workshops", "drops"]:
		if not data.has(field):
			continue
		if not data[field] is Array or data[field].size() > (32 if field == "workshops" else 128):
			return false
		for record in data[field]:
			if not record is Dictionary or not position_valid(record.get("position"), extent):
				return false
			if field == "workshops" and (not Catalog.station_ids().has(record.get("kind")) or not record.get("owner") is String or record["owner"].length() > 128):
				return false
			if field=="workshops" and record.has("machine") and not preload("res://Building/Factory.gd").valid(record["machine"],record["kind"]): return false
			if field == "drops" and (not record.get("id") is String or not Catalog.known(record["id"]) or not integer(record.get("count"), 1, 9999)):
				return false
			if field == "drops" and record.has("durability") and not integer(record["durability"], 0, 100):
				return false
	return data.get("weather") is Dictionary and WeatherModel.valid(data["weather"]) and (not modern or SaveSchema.extra(data, extent))

static func migrate(data: Dictionary) -> Dictionary:
	var output := data.duplicate(true)
	if int(data.get("version",1))<4:
		for field in ["world","rules","structures","fire_states","resource_timers","resource_regrowth","tribe_research","farming","fishing"]: output.erase(field)
		for player in output.get("players",{}).values():
			for field in ["journal","progression","craft_queue"]: player.erase(field)
	if int(output.get("version", 0)) == 1:
		var items: Dictionary = output["inventory"].duplicate()
		items["shelter"] = 0
		output = {"version": 2, "seed": output["seed"],
			"players": {"1": {"position": output["position"], "hp": output["hp"], "inventory": items}},
			"cut": output["cut"], "fires": output["fires"], "shelters": [],
			"phase": output["phase"], "weather": WeatherModel.new().serialize()}
	for i in range(output["cut"].size()):
		output["cut"][i] = int(output["cut"][i])
	for id in output["players"]:
		var player: Dictionary = output["players"][id]
		player["hp"] = int(player["hp"])
		for key in player["inventory"]:
			player["inventory"][key] = int(player["inventory"][key])
	if not output.has("world"):
		output["world"] = {"seed": 1337, "generator": 0, "size": 128}
	output["version"] = 4
	return output

static func read_slot(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	if file.get_length() > MAX_BYTES:
		file.close()
		return {}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not parser.data is Dictionary:
		return {}
	var envelope: Dictionary = parser.data
	var seq: Variant = envelope.get("sequence")
	var payload: Variant = envelope.get("payload")
	var digest: Variant = envelope.get("digest")
	if not integer(seq, 1, 1000000000) or not payload is String or not digest is String:
		return {}
	if ("%d:%s" % [int(seq), payload]).sha256_text() != digest:
		return {}
	if parser.parse(payload) != OK or not valid(parser.data):
		return {}
	return {"sequence": int(seq), "data": migrate(parser.data)}

static func newest(folder: String) -> Dictionary:
	var a := read_slot(folder.path_join("world.a.json"))
	var b := read_slot(folder.path_join("world.b.json"))
	if a.is_empty():
		return b
	if b.is_empty():
		return a
	return a if a["sequence"] >= b["sequence"] else b

static func load_world(folder: String = "user://world") -> Dictionary:
	return newest(folder).get("data", {}).duplicate(true)

static func open_world(folder: String, allow_new: bool = false) -> Dictionary:
	# Acquire before reading: another writer must not replace the snapshot we select.
	var already_owned := owned_locks.has(lock_key(folder))
	var error := acquire_lock(folder)
	if not error.is_empty():
		return {"data": {}, "error": error}
	var data := load_world(folder)
	if data.is_empty():
		var has_slots := FileAccess.file_exists(folder.path_join("world.a.json")) or FileAccess.file_exists(folder.path_join("world.b.json"))
		if has_slots or not allow_new:
			if not already_owned:
				release_lock(folder)
			return {"data": {}, "error": "Nenhum snapshot válido; arquivos existentes foram preservados / No valid snapshot; existing files were preserved."}
	return {"data": data, "error": ""}

static func payload_fits(data: Dictionary) -> bool:
	return JSON.stringify(data).to_utf8_buffer().size() <= MAX_BYTES / 2

static func profile_room(data: Dictionary) -> bool:
	# Reserve space for a new fully equipped player instead of admitting an unsavable profile.
	return JSON.stringify(data).to_utf8_buffer().size() + 4096 <= MAX_BYTES / 2

static func lock_key(folder: String) -> String:
	return ProjectSettings.globalize_path(folder).simplify_path().trim_suffix("/")

static func acquire_lock(folder: String = "user://world") -> String:
	var absolute := lock_key(folder)
	if owned_locks.has(absolute):
		return ""
	var error := DirAccess.make_dir_recursive_absolute(absolute)
	if error != OK:
		return "Não foi possível criar a pasta de salvamento: %s" % error_string(error)
	var lock_path := absolute.path_join(".writer-lock")
	error = DirAccess.make_dir_absolute(lock_path)
	if error != OK:
		return "Salvamento bloqueado por .writer-lock. Pare outros servidores; após uma queda, remova o lock somente com todos os escritores parados."
	var owner := FileAccess.open(lock_path.path_join("owner.txt"), FileAccess.WRITE)
	if owner == null:
		DirAccess.remove_absolute(lock_path)
		return "Não foi possível registrar o proprietário do lock."
	owner.store_string("pid=%d\n" % OS.get_process_id())
	owner.close()
	owned_locks[absolute] = true
	return ""

static func release_lock(folder: String = "user://world") -> void:
	var absolute := lock_key(folder)
	if not owned_locks.has(absolute):
		return
	var lock_path := absolute.path_join(".writer-lock")
	DirAccess.remove_absolute(lock_path.path_join("owner.txt"))
	DirAccess.remove_absolute(lock_path)
	owned_locks.erase(absolute)

static func save_world(data: Dictionary, folder: String = "user://world") -> String:
	if not valid(data):
		return "Estado inválido; nenhum snapshot foi substituído."
	var lock_error := acquire_lock(folder)
	if not lock_error.is_empty():
		return lock_error
	var latest := newest(folder)
	var seq: int = int(latest.get("sequence", 0)) + 1
	if seq > 1000000000:
		return "Limite de sequência atingido."
	var suffix := "a" if seq % 2 == 1 else "b"
	var target := folder.path_join("world.%s.json" % suffix)
	var temporary := target + ".tmp"
	var payload := JSON.stringify(migrate(data))
	if payload.to_utf8_buffer().size() > MAX_BYTES / 2:
		return "Snapshot excede o limite de tamanho."
	var envelope := {"sequence": seq, "payload": payload,
		"digest": ("%d:%s" % [seq, payload]).sha256_text()}
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return "Falha ao abrir snapshot temporário: %s" % error_string(FileAccess.get_open_error())
	file.store_string(JSON.stringify(envelope))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return "Falha de escrita: %s" % error_string(error)
	if read_slot(temporary).is_empty():
		return "A verificação do snapshot temporário falhou."
	var absolute_target := ProjectSettings.globalize_path(target)
	if FileAccess.file_exists(target):
		error = DirAccess.remove_absolute(absolute_target)
		if error != OK:
			return "Falha ao substituir snapshot inativo: %s" % error_string(error)
	error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), absolute_target)
	if error != OK:
		return "Falha ao promover snapshot: %s" % error_string(error)
	return ""
