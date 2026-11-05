extends VBoxContainer
const Catalog = preload("res://Items/Catalog.gd")
var game
var target: OptionButton
var give: OptionButton
var want: OptionButton
var amount: SpinBox
var quantity: SpinBox
var send: Button
var offers: VBoxContainer
var identities: Array = []
var item_ids: Array = []
var _signature: int = 0
var _left: float = 0

func configure(value, _language: int = 0) -> void:
	game = value
	var help := Label.new()
	help.text = game.hud.t("Troque a até 6 m. Confira as quantidades: a troca só ocorre inteira após o destinatário aceitar. Ofertas expiram em 90 s.", "Trade within 6 m. Check quantities: both backpacks change together only after the recipient accepts. Offers expire in 90 s.")
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; add_child(help)
	target = OptionButton.new(); add_child(target)
	var me: String = game.runtime.key(game.session.local_id)
	for id in game.players:
		if id != game.session.local_id and game.player.position.distance_to(game.players[id].position) <= 6:
			identities.append(game.runtime.key(id)); target.add_item(game.players[id].appearance["name"])
	item_ids = Catalog.ids()
	for entry in [["Oferecer", "Offer"], ["Receber", "Receive"]]:
		var title := Label.new(); title.text = game.hud.t(entry[0], entry[1]); add_child(title)
		var row := HBoxContainer.new(); add_child(row)
		var picker := OptionButton.new(); picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(picker)
		for item in item_ids: picker.add_item(Catalog.display_name(item))
		var count := SpinBox.new(); count.min_value = 1; count.max_value = 9999; count.value = 1; row.add_child(count)
		if give == null: give = picker; amount = count
		else: want = picker; quantity = count
	send = Button.new(); send.text = game.hud.t("Enviar oferta", "Send offer"); add_child(send)
	send.pressed.connect(func():
		if target.selected >= 0: game.request_crafting_command("trade_offer", {"target": identities[target.selected], "give": item_ids[give.selected], "amount": int(amount.value), "want": item_ids[want.selected], "quantity": int(quantity.value)}))
	offers = VBoxContainer.new(); add_child(offers)
	_signature = -1
	_refresh()

func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0: _left = 0.25; _refresh()

func _refresh() -> void:
	if game == null or send == null: return
	var me: String = game.runtime.key(game.session.local_id)
	var rows: Array = game.runtime.exchange.visible(me) if game.session.is_authority() else game.runtime.trade_view
	send.disabled = identities.is_empty() or game.inventory.count(item_ids[give.selected]) < int(amount.value) or rows.any(func(row): return row["from"] == me)
	send.tooltip_text = game.hud.t("É preciso um jogador próximo, materiais e nenhuma oferta pendente.", "Requires a nearby player, materials and no pending outgoing offer.") if send.disabled else send.text
	if hash(rows) == _signature: return
	_signature = hash(rows)
	for child in offers.get_children(): offers.remove_child(child); child.queue_free()
	for offer in rows:
		var description := Label.new()
		description.text = "%s ×%d  ⇄  %s ×%d" % [Catalog.display_name(offer["give"]), offer["amount"], Catalog.display_name(offer["want"]), offer["quantity"]]
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; offers.add_child(description)
		var owner_id: int = game.runtime.peer(offer["from"])
		var owner := Label.new(); owner.text = game.players[owner_id].appearance["name"] if owner_id != 0 else game.hud.t("Jogador desconectado", "Disconnected player"); offers.add_child(owner)
		var uid: String = offer["id"]
		if offer["to"] == me:
			var accept := Button.new(); accept.text = game.hud.t("Aceitar esta troca", "Accept this trade"); offers.add_child(accept)
			accept.pressed.connect(func(): game.request_crafting_command("trade_accept", {"id": uid}))
		var cancel := Button.new(); cancel.text = game.hud.t("Recusar / cancelar", "Decline / cancel"); offers.add_child(cancel)
		cancel.pressed.connect(func(): game.request_crafting_command("trade_cancel", {"id": uid}))
