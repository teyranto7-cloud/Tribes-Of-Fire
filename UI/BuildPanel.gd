extends VBoxContainer
const Catalog = preload("res://Building/Catalog.gd")
const Items = preload("res://Items/Catalog.gd")
const Config = preload("res://Settings/ConfigStore.gd")
var game
var search: LineEdit
var category: OptionButton
var tier_picker: OptionButton
var listing: VBoxContainer
var favourites: Array=[]
var categories: Array=["","favourites","structure","walls","doors","roofs","access","defense","furniture","decoration","stations","boats"]
var nearby: OptionButton
var selected_row: Dictionary={}
var details: VBoxContainer
var materials: Array=[]
var _refresh_left:=0.0
var _industry_signature:=0
func _process(delta:float) -> void:
	_refresh_left-=delta
	if _refresh_left>0 or nearby==null or nearby.item_count==0:return
	_refresh_left=.25
	var selection:Variant=nearby.get_item_metadata(nearby.selected)
	if not selection is String:return
	# Industrial controls contain no editable text; refresh after replicated edits.
	if find_children("*","ConfirmationDialog",true,false).any(func(d):return d.visible):return
	var index:=int(selection.trim_prefix("w"))
	if index>=game.runtime.workshops.size() or game.runtime.workshops[index].retired():refresh_nearby();return
	var station=game.runtime.workshops[index]
	var signature:int=hash([station.building,station.machine,game.runtime.grid.state(),game.runtime.automation.routes,game.inventory.items])
	if signature!=_industry_signature:_industry_signature=signature;show_selected()
func t(pt: String,en: String) -> String: return game.hud.t(pt,en)
func configure(value, _language: int=0) -> void:
	game=value
	var saved:Variant=Config.read("building","favourites",[])
	if saved is Array:
		for key in saved:
			if key is String and (Catalog.known(key) or Items.station_ids().has(key)) and key not in favourites: favourites.append(key)
	var tabs:=TabContainer.new(); tabs.custom_minimum_size.y=365; add_child(tabs)
	var place:=VBoxContainer.new(); place.name=t("Catálogo","Catalogue"); tabs.add_child(place)
	search=LineEdit.new(); search.placeholder_text=t("Buscar peça ou bancada…","Search pieces or stations…"); place.add_child(search); search.text_changed.connect(func(_s):refresh())
	var toolbar:=HBoxContainer.new(); place.add_child(toolbar)
	category=OptionButton.new(); category.size_flags_horizontal=Control.SIZE_EXPAND_FILL; toolbar.add_child(category)
	for title in [t("Todas","All"),t("Favoritos","Favourites"),t("Estrutura","Structure"),t("Paredes","Walls"),t("Portas","Doors"),t("Telhados","Roofs"),t("Acesso","Access"),t("Defesa","Defense"),t("Móveis","Furniture"),t("Decoração","Decoration"),t("Bancadas","Stations"),t("Barcos","Boats")]: category.add_item(title)
	category.item_selected.connect(func(_i):refresh())
	tier_picker=OptionButton.new(); toolbar.add_child(tier_picker)
	for tier in Catalog.tiers(): tier_picker.add_item(Catalog.tier_title(tier))
	tier_picker.select(1); tier_picker.item_selected.connect(func(_i):refresh())
	var options:=HBoxContainer.new(); place.add_child(options)
	for field in ["grid","snap"]:
		var check:=CheckBox.new(); check.text=t("Grade","Grid") if field=="grid" else t("Encaixe","Snap"); check.button_pressed=game.build_options[field]; options.add_child(check)
		check.toggled.connect(func(on): game.build_options[field]=on)
	var strict:=CheckBox.new(); strict.text=t("Suporte estrutural","Structural support"); strict.button_pressed=game.server_rules.get("structural_support",false); strict.disabled=not game.session.is_authority(); options.add_child(strict)
	strict.toggled.connect(func(on):
		if game.session.is_authority(): game.server_rules["structural_support"]=on)
	var help:=Label.new(); help.text=t("R gira · PgUp/PgDn altura · G grade · T encaixe · H espelha · Esc cancela","R rotates · PgUp/PgDn height · G grid · T snap · H mirror · Esc cancels"); help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; help.add_theme_font_size_override("font_size",12); place.add_child(help)
	var scroll:=ScrollContainer.new(); scroll.follow_focus=true; scroll.custom_minimum_size.y=220; scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; place.add_child(scroll)
	listing=VBoxContainer.new(); listing.size_flags_horizontal=Control.SIZE_EXPAND_FILL; scroll.add_child(listing)
	var manage:=VBoxContainer.new(); manage.name=t("Gerenciar base","Manage base"); tabs.add_child(manage)
	var top:=HBoxContainer.new(); manage.add_child(top)
	nearby=OptionButton.new(); nearby.size_flags_horizontal=Control.SIZE_EXPAND_FILL; top.add_child(nearby); nearby.item_selected.connect(func(_i):show_selected())
	var update:=Button.new(); update.text=t("Atualizar","Refresh"); top.add_child(update); update.pressed.connect(refresh_nearby)
	var manager_scroll:=ScrollContainer.new(); manager_scroll.follow_focus=true; manager_scroll.custom_minimum_size.y=290; manage.add_child(manager_scroll)
	details=VBoxContainer.new(); details.size_flags_horizontal=Control.SIZE_EXPAND_FILL; manager_scroll.add_child(details)
	refresh(); refresh_nearby()
func clear(container: Node) -> void:
	for child in container.get_children(): container.remove_child(child); child.queue_free()
func costs(cost: Dictionary) -> String:
	var parts:=PackedStringArray()
	for item in cost:
		var have:int=game.inventory.count(item); var need:int=cost[item]
		parts.append("[color=%s]%s %s %d/%d[/color]"%["#9dd69a" if have>=need else "#ff9b83","✓" if have>=need else "!",Items.display_name(item),have,need])
	return "  ·  ".join(parts)
func refresh() -> void:
	if listing==null: return
	clear(listing)
	var filter: String=categories[category.selected]; var tier: String=Catalog.tiers()[tier_picker.selected]
	var keys:=Catalog.ids()+Items.station_ids()+["waterwheel","power_pole","electric_lamp"]
	for kind in keys:
		var row:=Catalog.piece(kind); var name:=Catalog.title(kind) if Catalog.known(kind) else Items.display_name(kind)
		var group: String=row.get("category","stations")
		if filter=="favourites" and kind not in favourites: continue
		if filter not in ["","favourites",group]: continue
		if not search.text.strip_edges().is_empty() and not (name+" "+kind).to_lower().contains(search.text.strip_edges().to_lower()): continue
		if Catalog.known(kind) and tier not in row.get("tiers",Catalog.tiers()): continue
		if not Catalog.known(kind) and tier!="wood": continue
		var cost:Dictionary=Catalog.cost(kind,tier) if Catalog.known(kind) else preload("res://Game/Balance.gd").section("building")["costs"].get(kind,{})
		var line:=HBoxContainer.new(); listing.add_child(line)
		var star:=Button.new(); star.text="★" if kind in favourites else "☆"; star.tooltip_text=t("Favorito","Favourite"); line.add_child(star)
		star.pressed.connect(func():
			if kind in favourites: favourites.erase(kind)
			else: favourites.append(kind)
			if Config.write_sections({"building":{"favourites":favourites}})!=OK: game.hud.notify_message(t("Não foi possível salvar favoritos","Could not save favourites"))
			refresh())
		var select:=Button.new(); select.text=name+" · "+str(Catalog.maximum_hp(tier))+" HP" if Catalog.known(kind) else name; select.size_flags_horizontal=Control.SIZE_EXPAND_FILL; select.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; line.add_child(select)
		select.tooltip_text=t("Selecionar prévia. O servidor confere custo, terreno e permissões.","Select preview. Server checks cost, terrain and permissions.")
		select.pressed.connect(func():game.select_building(kind,tier))
		var label:=RichTextLabel.new(); label.bbcode_enabled=true; label.fit_content=true; label.mouse_filter=Control.MOUSE_FILTER_IGNORE; label.text=costs(cost); listing.add_child(label)
func refresh_nearby() -> void:
	nearby.clear()
	if game.player!=null:
		for row in game.world.building_records():
			if game.world.structure_registry.point(row).distance_to(game.player.position)>9: continue
			nearby.add_item("#%d %s"%[row["id"],row.get("name","") if not str(row.get("name","")).is_empty() else Catalog.title(row["kind"])])
			nearby.set_item_metadata(nearby.item_count-1,int(row["id"]))
		for i in range(game.runtime.workshops.size()):
			var station=game.runtime.workshops[i]
			if station.retired(): continue
			if station.position.distance_to(game.player.position)>9: continue
			nearby.add_item("w%d %s"%[i,Items.display_name(station.kind)]); nearby.set_item_metadata(nearby.item_count-1,"w%d"%i)
	show_selected()
func send(op: String, fields: Dictionary={}) -> void:
	var payload:Dictionary={"id":int(selected_row["id"]),"revision":int(selected_row.get("revision",1)),"op":op}; payload.merge(fields)
	game.request_crafting_command("structure_edit",payload)
func show_selected() -> void:
	clear(details); selected_row={}
	if nearby.item_count==0:
		var empty:=Label.new(); empty.text=t("Aproxime-se de uma peça da sua base (até 9 m).","Approach a base piece (within 9 m)."); empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; details.add_child(empty); return
	var selection:Variant=nearby.get_item_metadata(nearby.selected)
	if selection is String:
		var index:=int(selection.trim_prefix("w")); var station=game.runtime.workshops[index]
		var info:=Label.new(); info.text=Items.display_name(station.kind)+" · r%d"%int(station.building.get("revision",1)); details.add_child(info)
		var help:=Label.new(); help.text=t("Esvazie entrada/saída e filas. Remova cabos, esteiras e motor antes de mover ou demolir. IDs de bancadas removidas não são reutilizados.","Empty input/output and crafting queues. Remove cables, belts and motor before moving or demolishing. Removed station IDs are never reused."); help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; details.add_child(help)
		var move:=Button.new(); move.text=t("Mover bancada vazia","Move empty station"); move.disabled=not game.runtime.building.station_move_reason(game.session.local_id,index).is_empty(); details.add_child(move)
		move.pressed.connect(func():game.relocate_station(index))
		for operation in ["remove_motor","demolish"]:
			var button:=Button.new();button.text=t("Retirar motor (devolve 1 motor)…","Remove motor (returns 1 motor)…") if operation=="remove_motor" else t("Demolir bancada (restitui 50%)…","Demolish station (refunds 50%)…")
			var reason:String=game.runtime.industry.reason(game.session.local_id,index,operation)
			button.disabled=not reason.is_empty();button.tooltip_text=Catalog.reason(reason) if not reason.is_empty() else button.text;details.add_child(button)
			var payload:Dictionary={"station":index,"revision":int(station.building.get("revision",1)),"op":operation,"confirm":true}
			button.pressed.connect(func():
				var dialog:=ConfirmationDialog.new();dialog.title=t("Confirmar alteração industrial","Confirm industrial change");dialog.dialog_text=button.text+"\n"+t("Conteúdo, conexões, alcance e versão são conferidos novamente pelo servidor.","The server rechecks contents, connections, reach and revision.")
				add_child(dialog);dialog.confirmed.connect(func():game.request_crafting_command("industry_edit",payload);dialog.queue_free());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered())
		return
	var id:int=selection
	selected_row=game.world.structure_registry.records.get(id,{}).duplicate(true)
	if selected_row.is_empty(): return
	var maximum:=Catalog.maximum_hp(selected_row.get("tier","wood"))
	var info:=Label.new(); info.text="%s · %s · %d/%d HP · r%d"%[Catalog.title(selected_row["kind"]),Catalog.tier_title(selected_row.get("tier","wood")),selected_row["hp"],maximum,selected_row.get("revision",1)]; info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; details.add_child(info)
	var editable:bool=game.runtime.tribes.can_build(selected_row["owner"],game.runtime.key(game.session.local_id))
	var manage:bool=game.runtime.building.can_manage(selected_row,game.runtime.key(game.session.local_id))
	var name:=LineEdit.new(); name.text=selected_row.get("name",""); name.placeholder_text=t("Nome do objeto","Object name"); name.max_length=40; name.editable=manage; details.add_child(name)
	var style:=OptionButton.new(); details.add_child(style)
	for title in [t("Natural","Natural"),t("Argila","Clay"),t("Musgo","Moss"),t("Azul","Blue"),t("Ocre","Ochre"),t("Marfim","Ivory")]: style.add_item(title)
	style.select(int(selected_row.get("paint",0))); style.disabled=not manage
	var locked:=CheckBox.new(); locked.text=t("Porta/baú trancado para estranhos","Lock door/chest to strangers"); locked.button_pressed=selected_row.get("locked",true); locked.disabled=not manage; details.add_child(locked)
	var allies:=CheckBox.new(); allies.text=t("Permitir interação de aliados","Allow allied interaction"); allies.button_pressed=selected_row.get("allow_allies",false); allies.disabled=not manage; details.add_child(allies)
	var save:=Button.new(); save.text=t("Salvar nome e aparência","Save name and appearance"); save.disabled=not manage; details.add_child(save)
	save.pressed.connect(func():send("configure",{"name":name.text,"paint":style.selected,"locked":locked.button_pressed,"allow_allies":allies.button_pressed}))
	var repair:=Button.new(); repair.text=t("Reparar 25% (consome materiais)","Repair 25% (costs materials)"); repair.disabled=not editable or int(selected_row["hp"])<=0 or int(selected_row["hp"])>=maximum; details.add_child(repair); repair.pressed.connect(func():send("repair"))
	var upgrades:=HBoxContainer.new(); details.add_child(upgrades); var tier:=OptionButton.new(); upgrades.add_child(tier)
	materials=[]
	for key in Catalog.piece(selected_row["kind"]).get("tiers",Catalog.tiers()):
		if Catalog.tiers().find(key)>Catalog.tiers().find(selected_row.get("tier","wood")): materials.append(key); tier.add_item(Catalog.tier_title(key))
	var upgrade:=Button.new(); upgrade.text=t("Aprimorar","Upgrade"); upgrade.disabled=not editable or int(selected_row["hp"])<=0 or materials.is_empty(); upgrades.add_child(upgrade)
	var upgrade_cost:=RichTextLabel.new(); upgrade_cost.bbcode_enabled=true; upgrade_cost.fit_content=true; details.add_child(upgrade_cost)
	var update_cost:=func():
		if not materials.is_empty(): upgrade_cost.text=costs(Catalog.cost(selected_row["kind"],materials[tier.selected]))
	tier.item_selected.connect(func(_i):update_cost.call()); update_cost.call()
	upgrade.pressed.connect(func():send("upgrade",{"tier":materials[tier.selected]}))
	var dependants:Array=game.world.structure_registry.dependants(id)
	var move:=Button.new(); move.text=t("Mover / recolocar (ID preservado)","Move / relocate (same ID)"); move.disabled=not manage or not dependants.is_empty() or selected_row["kind"]=="raft" or selected_row.get("storage",{}).values().any(func(n):return int(n)>0); details.add_child(move)
	move.tooltip_text=t("Esvazie o baú antes. Peças com dependentes não se movem.","Empty the chest first. Pieces with dependants cannot move.")
	move.pressed.connect(func():game.relocate_building(selected_row))
	var cascade:=CheckBox.new(); cascade.text=t("Incluir dependentes (%d)","Include dependants (%d)")%dependants.size(); details.add_child(cascade)
	var demolish:=Button.new(); demolish.text=t("Demolir…","Demolish…"); demolish.disabled=not manage; details.add_child(demolish)
	demolish.pressed.connect(func():
		var dialog:=ConfirmationDialog.new(); dialog.title=t("Confirmar demolição","Confirm demolition")
		var affected:Array=[id]+(dependants if cascade.button_pressed else [])
		if affected.size()>24:
			game.hud.notify_message(t("Demola por partes: no máximo 24 peças por confirmação.","Demolish in smaller groups: at most 24 pieces per confirmation.")); dialog.free(); return
		var expected:Array=[]
		for uid in affected: expected.append([uid,int(game.world.structure_registry.records[uid].get("revision",1))])
		dialog.dialog_text=t("Remover %d peça(s): %s\nRestituição: 50%% do custo registrado, arredondado para baixo.\nConteúdo e personagens devem sair primeiro.","Remove %d piece(s): %s\nRefund: 50%% of recorded cost, rounded down.\nEmpty contents and move characters away first.")%[affected.size(),str(affected)]
		add_child(dialog); dialog.confirmed.connect(func():send("demolish",{"confirm":true,"cascade":cascade.button_pressed,"expected":expected});dialog.queue_free()); dialog.canceled.connect(dialog.queue_free); dialog.popup_centered())
