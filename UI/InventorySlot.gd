extends Button
var game
var index: int
func _get_drag_data(_position: Vector2) -> Variant:
	var slots: Array = game.inventory.serialize()["slots"]
	if slots[index].is_empty():
		return null
	var label := Label.new()
	label.text = text
	set_drag_preview(label)
	return {"from": index, "amount": maxi(1, ceili(float(slots[index]["count"]) / 2)) if Input.is_key_pressed(KEY_SHIFT) else int(slots[index]["count"])}
func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("from") and data.has("amount")
func _drop_data(_position: Vector2, data: Variant) -> void:
	game.request_command("inventory_move", {"from": data["from"], "to": index, "amount": data["amount"]})
