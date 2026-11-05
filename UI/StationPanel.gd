extends VBoxContainer
const Catalog=preload("res://Items/Catalog.gd")
var game
var info:Dictionary
var picker:OptionButton
var detail:Label
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
	detail=Label.new();detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(detail)
	for entry in [["station_load",game.hud.t("Abastecer 1 ciclo","Supply 1 cycle")],["factory_load",game.hud.t("Abastecer 5 ciclos","Supply 5 cycles")],["factory_take",game.hud.t("Retirar produção","Collect output")],["station_refund",game.hud.t("Cancelar e devolver entradas","Cancel and refund inputs")]]:
		var action:String=entry[0];var button:=Button.new();button.text=entry[1];add_child(button);action_buttons[action]=button
		button.pressed.connect(func():
			var data:={"station":int(info["station"])}
			if action=="station_load":data["amount"]=1
			game.request_crafting_command(action,data))
	_refresh()
func _process(delta:float)->void:
	_clock-=delta
	if _clock<=0:_clock=0.25;_refresh()
func _refresh()->void:
	var index:int=info["station"]
	var state:Dictionary=info["state"]
	if index>=0 and index<game.runtime.workshops.size():state=game.runtime.workshops[index].machine
	var recipe:=preload("res://Building/Factory.gd").definition(info["kind"],state)
	var lines:=PackedStringArray()
	for item in recipe.get("input",{}):lines.append("%s: %d/%d (%s %d)"%[Catalog.display_name(item),game.inventory.count(item),recipe["input"][item],game.hud.t("na bancada","in station"),state["input"].get(item,0)])
	for item in recipe.get("output",{}):lines.append("→ %s ×%d"%[Catalog.display_name(item),recipe["output"][item]])
	var stored:=PackedStringArray()
	for item in state["output"]:
		if int(state["output"][item])>0:stored.append("%s ×%d"%[Catalog.display_name(item),state["output"][item]])
	lines.append(game.hud.t("Produção disponível: ","Output stored: ")+(" · ".join(stored) if not stored.is_empty() else "—"))
	lines.append("%.1f / %.1f s"%[state["progress"],recipe.get("seconds",0)])
	detail.text="\n".join(lines)

	for action in action_buttons:
		var operation:String="factory_load" if action=="station_load" else action
		var amount:int=1 if action=="station_load" else 5
		var reason:String=game.runtime.station_reason(game.session.local_id,index,operation,amount)
		action_buttons[action].disabled=not reason.is_empty()
		action_buttons[action].tooltip_text=game.localization.text(reason) if not reason.is_empty() else action_buttons[action].text
	for i in range(recipes.size()):
		var reason:String=game.runtime.station_reason(game.session.local_id,index,"station_select",1,recipes[i])
		picker.set_item_disabled(i,not reason.is_empty())
