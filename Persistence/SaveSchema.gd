extends RefCounted
const Catalog = preload("res://Items/Catalog.gd")
const Journal = preload("res://Game/Journal.gd")
const Profile = preload("res://Progression/Profile.gd")
const Activities = preload("res://Crafting/Activities.gd")
const KINDS := ["lantern","torch","raft","foundation","floor","wall","window","door","roof","stairs","fence","bed","chest","garden","totem"]
static func number(value: Variant, low: float, high: float, whole: bool = false) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= low and value <= high and (not whole or float(value) == floorf(float(value)))
static func position(value: Variant, extent: float) -> bool:
	return value is Array and value.size() == 3 and number(value[0],-extent,extent) and number(value[1],-30,120) and number(value[2],-extent,extent)
static func descriptor(data: Dictionary) -> bool:
	var world: Variant = data.get("world")
	if not world is Dictionary or world.size() != 3: return false
	if not number(world.get("seed"),0,2147483647,true) or not number(world.get("generator"),0,3,true): return false
	return world.get("seed") == data.get("seed") and ((world["generator"] == 0 and world.get("size") == 128 and world["seed"] == 1337) or (world["generator"] == 1 and world.get("size") == 320) or (int(world["generator"]) in [2,3] and world.get("size") == 1536))
static func extra(data: Dictionary, extent: float) -> bool:
	var edits:Variant=data.get("terrain_changes",{})
	if not edits is Dictionary or edits.size()>1024:return false
	for cell in edits:
		if not cell is String:return false
		var parts:PackedStringArray=cell.split(",")
		if parts.size()!=2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():return false
		if absf(float(parts[0]))>extent/4+1 or absf(float(parts[1]))>extent/4+1 or not number(edits[cell],0,4):return false
	var rules: Variant = data.get("rules",{})
	if not rules is Dictionary or rules.size()>6: return false
	for key in rules:
		if key=="pvp":
			if rules[key] not in ["on","off","war"]: return false
		elif key=="difficulty":
			if rules[key] not in ["peaceful","normal","hard"]: return false
		elif key=="death_loss":
			if not number(rules[key],0,1): return false
		elif key in ["day_minutes","night_minutes"]:
			if not number(rules[key],1,180): return false
		elif key=="resource_rate":
			if not number(rules[key],0.25,4): return false
		else: return false
	var pieces: Variant = data.get("structures",[])
	if not pieces is Array or pieces.size() > 512: return false
	var ids := {}
	for piece in pieces:
		if not piece is Dictionary or not number(piece.get("id"),1,1000000,true) or ids.has(int(piece["id"])) or piece.get("kind") not in KINDS: return false
		ids[int(piece["id"])]=true
		if not position(piece.get("position"),extent) or not number(piece.get("rotation"),0,3,true) or not number(piece.get("hp"),0,100,true) or not piece.get("open") is bool: return false
		if not piece.get("owner") is String or piece["owner"].length()>128: return false
		if piece.has("bound_to") and (piece["kind"] != "bed" or not piece["bound_to"] is String or piece["bound_to"].length()>128): return false
		if piece.has("storage"):
			if piece["kind"] != "chest" or not piece["storage"] is Dictionary or piece["storage"].size()>24: return false
			for item in piece["storage"]:
				if not item is String or not Catalog.known(item) or not number(piece["storage"][item],0,9999,true): return false
		if piece.has("storage_wear"):
			if piece["kind"] != "chest" or not piece["storage_wear"] is Dictionary or piece["storage_wear"].size()>24: return false
			for item in piece["storage_wear"]:
				if not piece.get("storage",{}).has(item) or not number(piece["storage_wear"][item],0,100,true):return false
	var fishes: Variant = data.get("fishing",[])
	if not fishes is Array or fishes.size()>12: return false
	var fish_ids: Dictionary = {}
	for fish in fishes:
		if not fish is Dictionary or not number(fish.get("id"),0,11,true) or fish_ids.has(int(fish["id"])) or not number(fish.get("stock"),0,8,true) or not number(fish.get("restock_at"),0,4102444800): return false
		fish_ids[int(fish["id"])]=true
	var timers: Variant = data.get("resource_timers",{})
	if not timers is Dictionary or timers.size()>16384: return false
	for key in timers:
		if not key is String or not key.is_valid_int() or not number(int(key),0,65535,true) or not number(timers[key],0,4102444800): return false
	var fires: Variant = data.get("fire_states",[])
	if not fires is Array or fires.size()>32: return false
	for fire in fires:
		if not fire is Dictionary or not position(fire.get("position"),extent) or not number(fire.get("fuel"),0,3600) or not fire.get("lit") is bool: return false
	var farming: Variant = data.get("farming",{})
	if not farming is Dictionary or farming.size()>512: return false
	for id in farming:
		var row: Variant = farming[id]
		if not id is String or not id.is_valid_int() or not row is Dictionary or row.get("crop") not in ["berries"]: return false
		for field in ["growth","water"]:
			if not number(row.get(field),0,1): return false
		if not number(row.get("planted_at"),0,4102444800): return false
	var research: Variant = data.get("tribe_research",{})
	if not research is Dictionary or research.size()>256: return false
	for id in research:
		if not id is String or id.length()>128 or not research[id] is Array or research[id].size()>4: return false
		var seen := {}
		for tech in research[id]:
			if not tech is String or not Profile.technologies().has(tech) or seen.has(tech): return false
			seen[tech]=true
	var regrowth: Variant = data.get("resource_regrowth",[])
	if not regrowth is Array or (not regrowth.is_empty() and (regrowth.size()<22 or regrowth.size()>256)): return false
	for deadline in regrowth:
		if not number(deadline,0,4102444800): return false
	for player in data.get("players",{}).values():
		if player.has("death_handled") and not player["death_handled"] is bool: return false
		if player.has("journal") and not Journal.valid(player["journal"]): return false
		if player.has("progression") and (not player["progression"] is Dictionary or not Profile.valid(player["progression"])): return false
		if player.has("craft_queue") and (not player["craft_queue"] is Array or not Activities.valid_queue(player["craft_queue"])): return false
	return true
