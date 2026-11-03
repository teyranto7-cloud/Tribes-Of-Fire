extends Control
## Receives drags only outside the menu. The server owns removal and pickup creation.
var game
var confirmation: ConfirmationDialog
var pending: Dictionary = {}

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind") == "inventory_slot" and data.has("snapshot")

func _drop_data(_at: Vector2, data: Variant) -> void:
	request_drop(data)

func request_drop(data: Dictionary) -> void:
	if not _can_drop_data(Vector2.ZERO, data): return
	pending = data.duplicate(true)
	var item: String = data["snapshot"].get("id", "")
	var catalog = preload("res://Items/Catalog.gd")
	var valuable: bool = catalog.WEAPONS.has(item) or catalog.ARMOR.has(item) or item in ["shield", "rare_ore", "medical_kit", "gold_ingot", "silver_ingot"]
	if valuable:
		if confirmation == null:
			confirmation = ConfirmationDialog.new()
			add_child(confirmation)
			confirmation.confirmed.connect(_commit_drop)
			confirmation.canceled.connect(func(): pending.clear())
		confirmation.title = game.hud.t("Deixar item valioso no chão?", "Drop valuable item?")
		confirmation.dialog_text = "%s ×%d" % [catalog.display_name(item), int(data["amount"])]
		confirmation.popup_centered()
	else:
		_commit_drop()

func _commit_drop() -> void:
	if pending.is_empty(): return
	var slots: Array = game.inventory.serialize()["slots"]
	var index: int = pending["from"]
	# A confirmation may remain open while a network snapshot changes the slot.
	if index >= 0 and index < slots.size() and slots[index] == pending["snapshot"]:
		game.request_command("inventory_drop", {"slot": index, "amount": pending["amount"], "expected": pending["snapshot"]})
	pending.clear()
