extends RefCounted
const Catalog = preload("res://Items/Catalog.gd")
const Balance = preload("res://Game/Balance.gd")

const COST := 8
const SHELTER_COST := 12
const MAX_STACK := 9999
var items: Dictionary = {"axe": 1, "wood": 0, "campfire": 0, "shelter": 0}
var slots: Array = []
var equipment: Dictionary = {"hand": "axe", "offhand": "", "armor": ""}
var durability: Dictionary = {}
var _signature: int = 0
const SLOT_COUNT := 36

func count(item: String) -> int:
	return int(items.get(item, 0))

func can_add(item: String, amount: int) -> bool:
	_ensure_slots()
	if not Catalog.known(item) or amount <= 0 or count(item) > MAX_STACK - amount:
		return false
	return item in slots.map(func(s): return s.get("id", "")) or slots.any(func(s): return s.is_empty())

func add(item: String, amount: int, wear: int = -1) -> bool:
	if wear < -1 or wear > 100:
		return false
	if not can_add(item, amount):
		return false
	if Catalog.WEAPONS.has(item) or Catalog.ARMOR.has(item) or item == "shield":
		var received_wear := 100 if wear < 0 else wear
		# Durability is currently shared per item type. Receiving another copy must
		# never repair a worn copy already carried or equipped.
		durability[item] = received_wear if count(item) == 0 else mini(int(durability.get(item, 100)), received_wear)
	items[item] = count(item) + amount
	_signature = 0
	_ensure_slots()
	return true

func consume(item: String, amount: int) -> bool:
	if not items.has(item) or amount <= 0 or count(item) < amount:
		return false
	items[item] = count(item) - amount
	_signature = 0
	_ensure_slots()
	return true

func craft(item: String, cost: int) -> bool:
	return cost > 0 and transact({"wood": cost}, {item: 1})

func craft_fire() -> bool:
	return transact(Catalog.recipe("campfire")["cost"], {"campfire": 1})

func craft_shelter() -> bool:
	return transact(Catalog.recipe("shelter")["cost"], {"shelter": 1})

func restore(data: Dictionary) -> void:
	if data.has("slots") and valid_state(data):
		slots = data["slots"].duplicate(true)
		equipment = data["equipment"].duplicate()
		durability = data.get("durability", {}).duplicate()
		_sync_counts()
		return
	items = {"axe": 1, "wood": 0, "campfire": 0, "shelter": 0}
	for key in data:
		if Catalog.known(str(key)):
			items[key] = clampi(int(data[key]), 0, MAX_STACK)
	items["axe"] = 1
	_signature = 0
	_ensure_slots()

func _ensure_slots() -> void:
	if slots.size() == SLOT_COUNT and _signature == hash(items):
		return
	var remaining := items.duplicate()
	for i in range(slots.size()):
		if slots[i].is_empty():
			continue
		var id: String = slots[i]["id"]
		var quantity := mini(int(remaining.get(id, 0)), int(slots[i]["count"]))
		slots[i] = {"id": id, "count": quantity} if quantity > 0 else {}
		remaining[id] = int(remaining.get(id, 0)) - quantity
	while slots.size() < SLOT_COUNT:
		slots.append({})
	for id in remaining:
		if int(remaining[id]) <= 0:
			continue
		var destination := -1
		for i in range(slots.size()):
			if not slots[i].is_empty() and slots[i]["id"] == id:
				destination = i
				break
		if destination < 0:
			destination = slots.find({})
		if destination >= 0:
			slots[destination] = {"id": str(id), "count": int(slots[destination].get("count", 0)) + int(remaining[id])}
	for key in equipment:
		if int(items.get(equipment[key], 0)) <= 0:
			equipment[key] = ""
	_signature = hash(items)

func _sync_counts() -> void:
	items = {"axe": 0, "wood": 0, "campfire": 0, "shelter": 0}
	for slot in slots:
		if not slot.is_empty():
			items[slot["id"]] = int(items.get(slot["id"], 0)) + int(slot["count"])
	for key in equipment:
		if int(items.get(equipment[key], 0)) == 0:
			equipment[key] = ""
	_signature = hash(items)

func serialize() -> Dictionary:
	_ensure_slots()
	return {"slots": slots.duplicate(true), "equipment": equipment.duplicate(), "durability": durability.duplicate()}

static func valid_state(data: Dictionary) -> bool:
	if not data.get("slots") is Array or data["slots"].size() != SLOT_COUNT or not data.get("equipment") is Dictionary:
		return false
	var totals: Dictionary = {}
	for s in data["slots"]:
		if not s is Dictionary or s.size() > 2:
			return false
		if s.is_empty():
			continue
		var id: Variant = s.get("id")
		var amount: Variant = s.get("count")
		if not id is String or not Catalog.known(id) or not (amount is int or amount is float) or not is_finite(float(amount)) or amount != floorf(amount) or amount < 1:
			return false
		totals[id] = int(totals.get(id, 0)) + int(amount)
		if totals[id] > MAX_STACK:
			return false
	if data["equipment"].size() != 3:
		return false
	for key in ["hand", "offhand", "armor"]:
		var id: Variant = data["equipment"].get(key)
		if not id is String or (id != "" and (not totals.has(id) or (key == "hand" and not Catalog.WEAPONS.has(id)) or (key == "armor" and not Catalog.ARMOR.has(id)) or (key == "offhand" and id != "shield"))):
			return false
	var wear: Variant = data.get("durability", {})
	if not wear is Dictionary or wear.size() > Catalog.ids().size():
		return false
	for id in wear:
		if not Catalog.known(str(id)) or not (wear[id] is int or wear[id] is float) or not is_finite(float(wear[id])) or float(wear[id]) < 0 or float(wear[id]) > 100:
			return false
	return true

func move_slot(source: int, target: int, amount: int = 9999) -> bool:
	_ensure_slots()
	if source < 0 or source >= SLOT_COUNT or target < 0 or target >= SLOT_COUNT or source == target or slots[source].is_empty() or amount <= 0:
		return false
	var a: Dictionary = slots[source]
	var b: Dictionary = slots[target]
	if not b.is_empty() and b["id"] != a["id"]:
		if amount < int(a["count"]):
			return false
		slots[source] = b
		slots[target] = a
	else:
		var quantity := mini(amount, int(a["count"]))
		quantity = mini(quantity, MAX_STACK - int(b.get("count", 0)))
		if quantity <= 0:
			return false
		slots[target] = {"id": a["id"], "count": int(b.get("count", 0)) + quantity}
		a["count"] -= quantity
		if a["count"] == 0:
			slots[source] = {}
	_sync_counts()
	return true

func equip(index: int) -> bool:
	_ensure_slots()
	if index < 0 or index >= slots.size() or slots[index].is_empty():
		return false
	var id: String = slots[index]["id"]
	var key := "armor" if Catalog.ARMOR.has(id) else ("offhand" if id == "shield" else "hand")
	if key == "hand" and not Catalog.WEAPONS.has(id):
		return false
	equipment[key] = id
	return true

func take_slot(index: int, amount: int) -> Dictionary:
	_ensure_slots()
	if index < 0 or index >= SLOT_COUNT or slots[index].is_empty() or amount <= 0 or int(slots[index]["count"]) < amount:
		return {}
	var result := {"id": slots[index]["id"], "count": amount}
	var id: String = result["id"]
	if Catalog.WEAPONS.has(id) or Catalog.ARMOR.has(id) or id == "shield":
		result["durability"] = int(durability.get(id, 100))
	slots[index]["count"] -= amount
	if slots[index]["count"] == 0:
		slots[index] = {}
	_sync_counts()
	return result

func unequip(key: String) -> bool:
	if not equipment.has(key):
		return false
	equipment[key] = ""
	return true

func equipped_item(key: String = "hand") -> String:
	_ensure_slots()
	return str(equipment.get(key, ""))

func wear_equipment(key: String, amount: int) -> void:
	var id := equipped_item(key)
	if id == "" or amount <= 0:
		return
	durability[id] = maxi(0, int(durability.get(id, 100)) - amount)
	if durability[id] == 0:
		consume(id, 1)
		if count(id) > 0:
			# A spare copy is usable after the equipped one breaks.
			durability[id] = 100
		equipment[key] = ""

func transact(costs: Dictionary, rewards: Dictionary) -> bool:
	var before := serialize()
	for id in costs:
		if not consume(str(id), int(costs[id])):
			restore(before)
			return false
	for id in rewards:
		if not add(str(id), int(rewards[id])):
			restore(before)
			return false
	return true

func add_many(rewards: Dictionary) -> bool:
	return transact({}, rewards)

func craft_recipe(id: String, stations: Array = []) -> bool:
	if not Catalog.RECIPES.has(id):
		return false
	var recipe: Dictionary = Catalog.recipe(id)
	if recipe["station"] != "hand" and not recipe["station"] in stations:
		return false
	return transact(recipe["cost"], {id: 1})
