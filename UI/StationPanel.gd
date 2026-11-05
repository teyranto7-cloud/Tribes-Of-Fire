extends VBoxContainer
const Catalog=preload("res://Items/Catalog.gd")
var game
var info:Dictionary
var picker:OptionButton
var detail:RichTextLabel
var progress:ProgressBar
var motor_button:Button
var wiring_button:Button
var route_item:OptionButton
var route_target:OptionButton
var route_button:Button
var route_destinations:Array=[]
var route_items:Array=[]
var route_rows:VBoxContainer
var _route_signature:int=-1
var recipes:Array=[]
var _clock:float=0
var action_buttons:Dictionary={}
func configure(value,_language:int=0)->void:
	game=value;info=game.runtime.factory_view
	var title:=Label.new();title.text=Catalog.display_name(info["kind"]);title.add_theme_font_size_override("font_size",24);add_child(title)
	picker=OptionButton.new();add_child(picker)
	for id in Catalog.RECIPES:
		if Catalog.recipe(id)["station"]==info["kind"]:recipes.append(id);picker.add_item(Catalog.display_name(id))
	var selected:String=info["state"].get("recipe",str(Catalog.station(info["kind"]).get("default_recipe","")))
	if selected in recipes:picker.select(recipes.find(selected))
	if not info["state"].has("recipe") and preload("res://Building/Factory.gd").RECIPES.has(info["kind"]):
		picker.select(-1);picker.text=game.hud.t("Receita legada preservada","Preserved legacy recipe")
	picker.item_selected.connect(func(index):game.request_crafting_command("station_select",{"station":int(info["station"]),"recipe":recipes[index]}))
	detail=RichTextLabel.new();detail.bbcode_enabled=true;detail.fit_content=true;detail.mouse_filter=Control.MOUSE_FILTER_IGNORE;detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(detail)
	progress=ProgressBar.new();progress.custom_minimum_size.y=8;progress.show_percentage=false;add_child(progress)
	for entry in [["station_load",game.hud.t("Abastecer 1 ciclo","Supply 1 cycle")],["factory_load",game.hud.t("Abastecer 5 ciclos","Supply 5 cycles")],["factory_take",game.hud.t("Retirar produção","Collect output")],["station_refund",game.hud.t("Cancelar e devolver entradas","Cancel and refund inputs")]]:
		var action:String=entry[0];var button:=Button.new();button.text=entry[1];add_child(button);action_buttons[action]=button
		button.pressed.connect(func():
			var data:={"station":int(info["station"])}
			if action=="station_load":data["amount"]=1
			game.request_crafting_command(action,data))
	if info["kind"] in preload("res://Energy/Grid.gd").MOTOR_KINDS:
		var motor:=Button.new();motor_button=motor;motor.text=game.hud.t("Instalar motor elétrico · 1 motor · 40 W", "Install electric motor · 1 motor · 40 W");add_child(motor)
		motor.disabled=int(info["station"]) in game.runtime.grid.motors or game.inventory.count("motor")==0
		motor.pressed.connect(func():game.request_crafting_command("energy_install",{"station":int(info["station"])}))
		var wiring:=Button.new();wiring_button=wiring;wiring.text=game.hud.t("Conexão elétrica desta máquina", "Electrical connection for this machine");add_child(wiring)
		wiring.pressed.connect(func():game.runtime.energy_view="w%d"%int(info["station"]);game.hud.show_panel("energy"))
		_build_automation()
	_refresh()
func _process(delta:float)->void:
	_clock-=delta
	if _clock<=0:_clock=0.25;_refresh()
func _refresh()->void:
	var index:int=info["station"]
	var state:Dictionary=info["state"]
	if index>=0 and index<game.runtime.workshops.size():state=game.runtime.workshops[index].machine
	if index>=0 and index<game.runtime.workshops.size() and game.runtime.workshops[index].retired():
		detail.text=game.hud.t("Esta bancada foi removida. Feche esta janela.","This station was removed. Close this window.")
		picker.disabled=true
		for button in action_buttons.values(): button.disabled=true
		if motor_button!=null: motor_button.disabled=true;wiring_button.disabled=true;route_button.disabled=true
		return
	var recipe:=preload("res://Building/Factory.gd").definition(info["kind"],state)
	var lines:=PackedStringArray()
	for item in recipe.get("input",{}):
		var enough:bool=game.inventory.count(item)>=int(recipe["input"][item])
		lines.append("[color=%s]%s %s: %d/%d[/color]  ·  %s %d"%["#9bd8a4" if enough else "#eda18d","+" if enough else "!",Catalog.display_name(item),game.inventory.count(item),recipe["input"][item],game.hud.t("na bancada","in station"),state["input"].get(item,0)])
	for item in recipe.get("output",{}):lines.append("→ %s ×%d"%[Catalog.display_name(item),recipe["output"][item]])
	var stored:=PackedStringArray()
	for item in state["output"]:
		if int(state["output"][item])>0:stored.append("%s ×%d"%[Catalog.display_name(item),state["output"][item]])
	lines.append(game.hud.t("Produção disponível: ","Output stored: ")+(" · ".join(stored) if not stored.is_empty() else "—"))
	lines.append("%.1f / %.1f s"%[state["progress"],recipe.get("seconds",0)])
	if index in game.runtime.grid.motors: lines.append(game.hud.t("Motor ligado · 40 W", "Motor running · 40 W") if game.runtime.grid.powered.get("w%d"%index,false) else game.hud.t("Motor instalado · produção pausada sem energia", "Motor installed · production paused without power"))
	progress.max_value=maxf(0.1,float(recipe.get("seconds",1)));progress.value=float(state["progress"])
	if route_item!=null and route_items!=recipe.get("output",{}).keys():
		route_items=recipe.get("output",{}).keys();route_item.clear()
		for item in route_items:route_item.add_item(Catalog.display_name(item))
		_route_targets()
	if motor_button!=null:
		motor_button.disabled=index in game.runtime.grid.motors or game.inventory.count("motor")==0
		wiring_button.disabled=not index in game.runtime.grid.motors
		if route_button!=null: route_button.disabled=not index in game.runtime.grid.motors or game.inventory.count("conveyor")==0 or route_destinations.is_empty()
		motor_button.tooltip_text=game.hud.t("A instalação consome um motor; depois, conecte a uma roda-d’água por cabos.","Installation consumes one motor; then connect cables to a waterwheel.")
	detail.text="\n".join(lines)

	_refresh_routes()
	for action in action_buttons:
		var operation:String="factory_load" if action=="station_load" else action
		var amount:int=1 if action=="station_load" else 5
		var reason:String=game.runtime.station_reason(game.session.local_id,index,operation,amount)
		action_buttons[action].disabled=not reason.is_empty()
		action_buttons[action].tooltip_text=game.localization.text(reason) if not reason.is_empty() else action_buttons[action].text
	for i in range(recipes.size()):
		var reason:String=game.runtime.station_reason(game.session.local_id,index,"station_select",1,recipes[i])
		picker.set_item_disabled(i,not reason.is_empty())

func _build_automation()->void:
	var title:=Label.new();title.text=game.hud.t("Automatizar saída · 1 esteira · motor na origem","Automate output · 1 conveyor · source motor");title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(title)
	route_item=OptionButton.new();add_child(route_item)
	var definition:=preload("res://Building/Factory.gd").definition(info["kind"],info["state"])
	for item in definition.get("output",{}):route_items.append(item);route_item.add_item(Catalog.display_name(item))
	route_target=OptionButton.new();add_child(route_target)
	route_item.item_selected.connect(func(_index):_route_targets())
	route_button=Button.new();route_button.text=game.hud.t("Conectar esteira · alcance 8 m","Connect conveyor · 8 m reach");add_child(route_button)
	route_button.pressed.connect(func():
		if route_target.selected>=0 and route_item.selected>=0:game.request_crafting_command("factory_route",{"from":int(info["station"]),"to":route_destinations[route_target.selected],"item":route_items[route_item.selected]}))
	route_rows=VBoxContainer.new();add_child(route_rows)
	_route_targets()

func _route_targets()->void:
	route_target.clear();route_destinations.clear()
	if route_item.selected<0:return
	var index:int=info["station"]
	var item:String=route_items[route_item.selected]
	for other in range(game.runtime.workshops.size()):
		var station=game.runtime.workshops[other]
		if station.retired() or other==index or station.position.distance_to(game.runtime.workshops[index].position)>8 or not game.runtime.tribes.can_build(station.owner_key,game.runtime.key(game.session.local_id)):continue
		if not preload("res://Building/Factory.gd").definition(station.kind,station.machine).get("input",{}).has(item):continue
		route_destinations.append(other);route_target.add_item("%s #%d"%[Catalog.display_name(station.kind),other+1])
	if route_destinations.is_empty():route_target.add_item(game.hud.t("Nenhum destino compatível próximo","No compatible nearby destination"))
	route_target.disabled=route_destinations.is_empty()

func _refresh_routes()->void:
	if route_rows==null:return
	var rows:Array=game.runtime.automation.routes.filter(func(row):return int(row["from"])==int(info["station"]))
	var signature:int=hash(rows.map(func(row):return [row["from"],row["to"],row["item"]]))
	if signature==_route_signature:return
	_route_signature=signature
	for child in route_rows.get_children():route_rows.remove_child(child);child.queue_free()
	for row in rows:
		var remove:=Button.new();remove.text=game.hud.t("Remover esteira: ","Remove conveyor: ")+Catalog.display_name(row["item"])+" → #%d"%(int(row["to"])+1);route_rows.add_child(remove)
		var data:Dictionary={"from":int(row["from"]),"to":int(row["to"]),"item":row["item"]}
		remove.pressed.connect(func():game.request_crafting_command("factory_unroute",data))
