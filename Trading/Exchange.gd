extends RefCounted
## Immutable offers: nothing leaves either backpack until both sides agree.
const Inventory = preload("res://Core/Inventory.gd")
var offers: Dictionary = {}

func expire(online: Array, now: float) -> void:
	for uid in offers.keys():
		var row: Dictionary = offers[uid]
		if row["expires"] <= now or row["from"] not in online or row["to"] not in online:
			offers.erase(uid)

func create(sender: String, recipient: String, give: String, amount: int, want: String, quantity: int, inventory, now: float) -> bool:
	if sender == recipient or amount < 1 or quantity < 1 or amount > 9999 or quantity > 9999:
		return false
	if not Inventory.Catalog.known(give) or not Inventory.Catalog.known(want) or inventory.count(give) < amount:
		return false
	if offers.size() >= 64 or offers.values().any(func(row): return row["from"] == sender):
		return false
	var uid := Crypto.new().generate_random_bytes(16).hex_encode()
	offers[uid] = {"id": uid, "from": sender, "to": recipient, "give": give, "amount": amount, "want": want, "quantity": quantity, "expires": now + 90.0}
	return true

func cancel(actor: String, uid: String) -> bool:
	if not offers.has(uid) or actor not in [offers[uid]["from"], offers[uid]["to"]]:
		return false
	offers.erase(uid)
	return true

func accept(actor: String, uid: String, sender_inventory, recipient_inventory, now: float) -> bool:
	if not offers.has(uid): return false
	var row: Dictionary = offers[uid]
	if row["to"] != actor or row["expires"] <= now: return false
	# Work on complete copies. Capacity is evaluated after removing the offered
	# items; wear is transferred conservatively, never repaired by a trade.
	var a := Inventory.new(); a.restore(sender_inventory.serialize())
	var b := Inventory.new(); b.restore(recipient_inventory.serialize())
	var wear_a: int = a.durability.get(row["give"], 100)
	var wear_b: int = b.durability.get(row["want"], 100)
	if not a.consume(row["give"], row["amount"]) or not b.consume(row["want"], row["quantity"]): return false
	if not a.add(row["want"], row["quantity"], wear_b) or not b.add(row["give"], row["amount"], wear_a): return false
	sender_inventory.restore(a.serialize())
	recipient_inventory.restore(b.serialize())
	offers.erase(uid)
	return true

func visible(actor: String) -> Array:
	return offers.values().filter(func(row): return actor in [row["from"], row["to"]]).duplicate(true)
