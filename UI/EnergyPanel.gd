extends VBoxContainer
var game
var source: String = ""
var targets: OptionButton
var keys: Array = []
var meter: Label
var _left: float = 0

func configure(value, _language: int = 0) -> void:
	game = value; source = game.runtime.energy_view
	meter = Label.new(); meter.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; add_child(meter)
	var help := Label.new(); help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.text = game.hud.t("Cabos alcançam 18 m e custam 1 fio a cada 6 m. Use postes para ampliar a rede. Instale um motor na bancada para ligá-la. Sobrecarga interrompe o circuito.", "Cables reach 18 m and cost 1 wire per 6 m. Extend the grid with poles. Install a motor at a workshop to connect it. Overload stops the circuit."); add_child(help)
	targets = OptionButton.new(); add_child(targets)
	var grid = game.runtime.grid
	var candidates: Array = grid.nodes.keys()
	for index in grid.motors: candidates.append("w%d" % int(index))
	var me: String = game.runtime.key(game.session.local_id)
	for uid in candidates:
		var row: Dictionary = grid.endpoint(uid, game.runtime.workshops)
		if row.is_empty():continue
		if uid == source or not game.runtime.tribes.can_build(row["owner"], me): continue
		var distance: float = grid.point(source, game.runtime.workshops).distance_to(grid.point(uid, game.runtime.workshops))
		if distance <= 18:
			keys.append(uid); targets.add_item("%s · %.0f m" % [preload("res://Items/Catalog.gd").display_name(row["kind"]), distance])
	var connect := Button.new(); connect.text = game.hud.t("Conectar com fio", "Connect with wire"); connect.disabled = keys.is_empty(); add_child(connect)
	connect.pressed.connect(func():
		if targets.selected >= 0: game.request_crafting_command("energy_connect", {"a": source, "b": keys[targets.selected]}))
	if source in grid.nodes:
		var toggle := Button.new(); toggle.text = game.hud.t("Ligar / desligar aparelho", "Toggle device"); add_child(toggle)
		toggle.pressed.connect(func(): game.request_crafting_command("energy_toggle", {"id": source}))
	for i in range(grid.links.size()):
		var row: Dictionary = grid.links[i]
		if source not in [row["a"], row["b"]]: continue
		var remove := Button.new(); remove.text = game.hud.t("Remover cabo e recuperar fios", "Remove cable and recover wire"); add_child(remove)
		var a: String = row["a"]; var b: String = row["b"]
		remove.pressed.connect(func(): game.request_crafting_command("energy_disconnect", {"a": a, "b": b}))
	if source in grid.nodes:
		var reason:String=game.runtime.industry.device_reason(game.session.local_id,source)
		var move:=Button.new();move.text=game.hud.t("Recolocar aparelho (prévia à frente)","Relocate device (preview ahead)");move.set_meta("manage_device",true);move.disabled=not reason.is_empty();move.tooltip_text=preload("res://Building/Catalog.gd").reason(reason);add_child(move);move.pressed.connect(func():game.relocate_device(source))
		var remove:=Button.new();remove.text=game.hud.t("Demolir aparelho (50% dos materiais)…","Demolish device (50% materials)…");remove.set_meta("manage_device",true);remove.disabled=not reason.is_empty();remove.tooltip_text=move.tooltip_text;add_child(remove)
		remove.pressed.connect(func():
			if not grid.nodes.has(source):return
			var payload:Dictionary={"id":source,"revision":int(grid.nodes[source].get("revision",1)),"op":"demolish","confirm":true}
			var dialog:=ConfirmationDialog.new();dialog.title=remove.text;dialog.dialog_text=game.hud.t("Remova os cabos primeiro. A restituição usa o custo registrado e exige espaço na mochila.","Remove cables first. Refund uses recorded cost and requires inventory space.");add_child(dialog)
			dialog.confirmed.connect(func():game.request_crafting_command("device_edit",payload);dialog.queue_free());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered())
	_refresh()

func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0: _left = 0.25; _refresh()

func _refresh() -> void:
	if game == null: return
	if game.runtime.grid.endpoint(source,game.runtime.workshops).is_empty():
		meter.text=game.hud.t("Aparelho removido. Feche esta janela.","Device removed. Close this window.")
		for child in get_children():
			if child is Button:child.disabled=true
		return
	if source in game.runtime.grid.nodes:
		var reason:String=game.runtime.industry.device_reason(game.session.local_id,source)
		for child in get_children():
			if child is Button and child.get_meta("manage_device",false):child.disabled=not reason.is_empty();child.tooltip_text=preload("res://Building/Catalog.gd").reason(reason)
	var values: Dictionary = game.runtime.grid.meters.get(source, {})
	meter.text = game.hud.t("Geração %.0f W · Consumo %.0f W\n%s", "Generation %.0f W · Demand %.0f W\n%s") % [values.get("generation", 0), values.get("demand", 0), game.hud.t("Energizado", "Powered") if game.runtime.grid.powered.get(source, false) else game.hud.t("Sem energia / desligado / sobrecarga", "No power / switched off / overloaded")]
