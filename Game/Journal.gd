extends RefCounted
## Per-world, server-owned exploration. Shared markers reveal no unexplored terrain.
const CELL_SIZE := 20.0
const MAX_MARKERS := 32
var records: Dictionary = {}
var shared_cache: Dictionary = {}

static func empty_record() -> Dictionary:
	return {"cells": {}, "markers": [], "achievements": {}, "stats": {}, "next_marker": 1}

func restore(identity: String, data: Dictionary) -> void:
	records[identity] = data.duplicate(true) if valid(data) else empty_record()

func serialize(identity: String) -> Dictionary:
	return records.get(identity, empty_record()).duplicate(true)

func explore(identity: String, at: Vector3, descriptor: Dictionary, delta: float) -> void:
	if not records.has(identity): records[identity] = empty_record()
	var record: Dictionary = records[identity]
	var extent := float(descriptor.get("size", 128)) * 0.5
	if absf(at.x) > extent or absf(at.z) > extent: return
	var cell := Vector2i(floori(at.x / CELL_SIZE), floori(at.z / CELL_SIZE))
	for z in range(-1, 2):
		for x in range(-1, 2):
			record["cells"]["%d,%d" % [cell.x + x, cell.y + z]] = true
	record["stats"]["time"] = float(record["stats"].get("time", 0)) + maxf(0, delta)

func record_event(identity: String, event: String, amount: float = 1.0) -> void:
	if event not in ["gather", "craft", "build", "hunt", "fish", "plant", "tame", "storm", "cave", "tribe"] or not is_finite(amount) or amount <= 0: return
	if not records.has(identity): records[identity] = empty_record()
	var record: Dictionary = records[identity]
	record["stats"][event] = minf(1000000000, float(record["stats"].get(event, 0)) + amount)
	record["achievements"][event] = true

func command(identity: String, action: String, data: Dictionary, tribes) -> bool:
	if not records.has(identity): return false
	var record: Dictionary = records[identity]
	if action == "map_remove":
		for marker in record["markers"]:
			if marker["id"] == data.get("id"):
				record["markers"].erase(marker)
				return true
		return false
	if action != "map_mark" or record["markers"].size() >= MAX_MARKERS or record["next_marker"] > 1000000: return false
	var p: Variant = data.get("position")
	if not p is Array or p.size() != 2: return false
	for value in p:
		if not (value is int or value is float) or not is_finite(float(value)) or absf(float(value)) > 10000: return false
	var cell := "%d,%d" % [floori(float(p[0]) / CELL_SIZE), floori(float(p[1]) / CELL_SIZE)]
	if not record["cells"].has(cell): return false
	var label: Variant = data.get("name")
	var color: Variant = data.get("color")
	if not label is String or label.strip_edges().is_empty() or label.length() > 40 or label.to_utf8_buffer().has(0): return false
	if not (color is int or color is float) or float(color) != floorf(float(color)) or color < 0 or color > 5 or not data.get("shared") is bool: return false
	if data["shared"] and tribes.tribe_of(identity).is_empty(): return false
	record["markers"].append({"id": int(record["next_marker"]), "position": p.duplicate(), "name": label.strip_edges(), "color": int(color), "shared": data["shared"]})
	record["next_marker"] = int(record["next_marker"]) + 1
	return true

func visible_markers(identity: String, tribes) -> Array:
	var result: Array = serialize(identity)["markers"]
	result.append_array(shared_cache.get(identity, []))
	var tribe: String = tribes.tribe_of(identity)
	if tribe.is_empty(): return result
	for owner in records:
		if owner == identity or tribes.tribe_of(owner) != tribe: continue
		for marker in records[owner]["markers"]:
			if marker["shared"]:
				var copy: Dictionary = marker.duplicate(true)
				copy["foreign"] = true
				result.append(copy)
	return result

static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 5: return false
	for field in ["cells", "achievements", "stats"]:
		if not data.get(field) is Dictionary: return false
	if data["cells"].size() > 8192 or data["achievements"].size() > 32 or data["stats"].size() > 32: return false
	for field in ["cells", "achievements"]:
		for key in data[field]:
			if not key is String or key.length() > 64 or not data[field][key] is bool: return false
	for key in data["stats"]:
		var value: Variant = data["stats"][key]
		if not key is String or key.length() > 32 or not (value is int or value is float) or not is_finite(float(value)) or value < 0 or value > 1000000000: return false
	if not data.get("markers") is Array or data["markers"].size() > MAX_MARKERS: return false
	var next: Variant = data.get("next_marker")
	if not (next is int or next is float) or float(next) != floorf(float(next)) or next < 1 or next > 1000001: return false
	var seen := {}
	for marker in data["markers"]:
		if not marker is Dictionary or marker.size() != 5: return false
		var id: Variant = marker.get("id")
		if not (id is int or id is float) or float(id) != floorf(float(id)) or id < 1 or id >= next or seen.has(int(id)): return false
		seen[int(id)] = true
		if not marker.get("name") is String or marker["name"].length() > 40 or marker["name"].is_empty(): return false
		var color: Variant = marker.get("color")
		if not (color is int or color is float) or float(color) != floorf(float(color)) or color < 0 or color > 5 or not marker.get("shared") is bool: return false
		var p: Variant = marker.get("position")
		if not p is Array or p.size() != 2: return false
		for value in p:
			if not (value is int or value is float) or not is_finite(float(value)) or absf(float(value)) > 10000: return false
	return true
