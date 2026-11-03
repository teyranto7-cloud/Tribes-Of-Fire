extends RefCounted
## Persisted escrow prevents crafting duplication across cancellation/reconnect.
const Catalog = preload("res://Items/Catalog.gd")
const Balance = preload("res://Game/Balance.gd")
var queues: Dictionary = {}
var actions: Dictionary = {}
var requests: Dictionary = {}
func queue(id: int) -> Array:
	return queues.get(id, [])
func restore(id: int, records: Array) -> void:
	queues[id] = records.duplicate(true) if valid_queue(records) else []
func enqueue(id: int, recipe: String, inventory, request_id: String = "") -> bool:
	if not request_id.is_empty() and request_id in requests.get(id,[]):return false
	if not Catalog.RECIPES.has(recipe) or queue(id).size() >= Balance.integer("crafting", "queue_limit", 5): return false
	var definition: Dictionary = Catalog.recipe(recipe)
	if not inventory.transact(definition["cost"], {}): return false
	var duration := maxf(0.1, float(definition.get("time", 2.5)))
	if not queues.has(id): queues[id] = []
	queues[id].append({"recipe": recipe, "remaining": duration, "total": duration, "escrow": definition["cost"].duplicate()})
	if not request_id.is_empty():
		if not requests.has(id):requests[id]=[]
		requests[id].append(request_id)
		if requests[id].size()>128:requests[id].pop_front()
	return true
func cancel(id: int, index: int, inventory) -> bool:
	var entries := queue(id)
	if index < 0 or index >= entries.size() or not inventory.add_many(entries[index]["escrow"]): return false
	entries.remove_at(index)
	return true
func start_action(id: int, kind: String, duration: float, metadata: Dictionary = {}) -> bool:
	if actions.has(id): return false
	actions[id] = {"kind": kind, "remaining": duration, "total": duration, "metadata": metadata.duplicate(true)}
	return true
func action_state(id: int) -> Dictionary:
	var record: Dictionary = actions.get(id, {})
	return {"kind": record.get("kind", ""), "remaining": record.get("remaining", 0), "total": record.get("total", 0)}
func remove_player(id: int) -> void:
	actions.erase(id)
	queues.erase(id)
	requests.erase(id)
static func valid_queue(records: Array) -> bool:
	if records.size() > Balance.integer("crafting", "queue_limit", 5): return false
	for record in records:
		if not record is Dictionary or not record.get("recipe") is String or not Catalog.RECIPES.has(record["recipe"]): return false
		for field in ["remaining", "total"]:
			var value: Variant = record.get(field)
			if not (value is int or value is float) or not is_finite(float(value)) or value < 0 or value > 3600: return false
		if record["remaining"] > record["total"] or not record.get("escrow") is Dictionary or not same_cost(record["escrow"],Catalog.recipe(record["recipe"])["cost"]): return false
	return true

static func same_cost(a:Dictionary,b:Dictionary)->bool:
	if a.size()!=b.size():return false
	for id in b:
		if not a.has(id) or not (a[id] is int or a[id] is float) or not is_finite(float(a[id])) or a[id]!=b[id]:return false
	return true
