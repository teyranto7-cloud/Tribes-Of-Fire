extends Button
var game
var index: int

func drag_payload(half: bool = false) -> Dictionary:
	var slots: Array = game.inventory.serialize()["slots"]
	if slots[index].is_empty(): return {}
	return {"kind": "inventory_slot", "from": index,
		"amount": maxi(1, ceili(float(slots[index]["count"]) / 2)) if half else int(slots[index]["count"]),
		"snapshot": slots[index].duplicate(true)}

func _get_drag_data(_position: Vector2) -> Variant:
	var data := drag_payload(Input.is_key_pressed(KEY_SHIFT))
	if data.is_empty(): return null
	var preview := Label.new()
	preview.text = text + " ×%d" % data["amount"]
	set_drag_preview(preview)
	return data

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind") == "inventory_slot" and data.has("snapshot") and data.get("from", -1) != index

func _drop_data(_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_position, data): return
	var slots: Array = game.inventory.serialize()["slots"]
	if slots[data["from"]] != data["snapshot"]: return
	game.request_command("inventory_move", {"from": data["from"], "to": index, "amount": data["amount"], "expected": data["snapshot"]})
