extends VBoxContainer
const Catalog = preload("res://Items/Catalog.gd")
const Balance = preload("res://Game/Balance.gd")
var game
var selected: int = 0
var buttons: Array[Button] = []
var detail: Label
var recipes: Dictionary = {}
var search: LineEdit
var queue_labels: Array[Button] = []
var _signature: int = 0
func label(pt: String,en: String) -> String: return game.hud.t(pt,en)
func configure(value, _language: int = 0) -> void:
	game=value
	var tabs:=TabContainer.new()
	tabs.custom_minimum_size=Vector2(0,450)
	add_child(tabs)
	var inventory:=VBoxContainer.new();inventory.name=label("Mochila","Backpack");tabs.add_child(inventory)
	var grid:=GridContainer.new();grid.columns=6;inventory.add_child(grid)
	for i in range(36):
		var b:=preload("res://UI/InventorySlot.gd").new()
		b.game=game;b.index=i;b.custom_minimum_size=Vector2(74,54)
		b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.add_theme_font_size_override("font_size",12)
		b.pressed.connect(func(): selected=i;_refresh(true))
		grid.add_child(b);buttons.append(b)
	detail=Label.new();detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;inventory.add_child(detail)
	var actions:=GridContainer.new();actions.columns=3;inventory.add_child(actions)
	for action in ["Equip","Unequip","Eat","Drop","Repair"]:
		var b:=Button.new();b.text=tr(action);b.pressed.connect(func():_action(action));actions.add_child(b)
	var craft:=VBoxContainer.new();craft.name=label("Fabricação","Crafting");tabs.add_child(craft)
	search=LineEdit.new();search.placeholder_text=label("Buscar item ou material…","Search item or material…")
	search.text_changed.connect(func(_text):_refresh_recipes());craft.add_child(search)
	var technology:=Button.new();technology.text=label("Pesquisa e tecnologias →","Research and technology →")
	technology.pressed.connect(func():game.hud.show_panel("technology"));craft.add_child(technology)
	for i in range(5):
		var b:=Button.new();b.pressed.connect(func():game.request_command("craft_cancel",{"index":i}));craft.add_child(b);queue_labels.append(b)
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size.y=300;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;craft.add_child(scroll)
	var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
	var recipe_ids:Array=Catalog.RECIPES.keys()
	recipe_ids.sort_custom(func(a,b):return int(Catalog.recipe(a).get("era",0))<int(Catalog.recipe(b).get("era",0)))
	for id in recipe_ids:
		var b:=Button.new();b.alignment=HORIZONTAL_ALIGNMENT_LEFT;b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size",14)
		b.pressed.connect(func():game.request_command("craft",{"recipe":id}));list.add_child(b);recipes[id]=b
	var building:=VBoxContainer.new();building.name=label("Construir","Build");tabs.add_child(building)
	for entry in [["campfire",2],["shelter",3]]:
		var kind:String=entry[0];var tool:int=entry[1]
		var b:=Button.new();b.text=label("Posicionar ","Place ")+item_name(kind)
		b.pressed.connect(func():game.tool=tool;game.build_piece="";game.hud.show_panel(""));building.add_child(b)
	var scroll_build:=ScrollContainer.new();scroll_build.custom_minimum_size.y=340;building.add_child(scroll_build)
	var list_build:=VBoxContainer.new();list_build.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll_build.add_child(list_build)
	for kind in Balance.section("building")["costs"]:
		var b:=Button.new();b.text=tr("Build")+": "+item_name(kind)+" · "+cost_text(Balance.section("building")["costs"][kind])
		b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.add_theme_font_size_override("font_size",14)
		b.pressed.connect(func():game.select_building(kind));list_build.add_child(b)
	_refresh(true)
func item_name(id: String) -> String: return Catalog.display_name(id)
func cost_text(cost: Dictionary) -> String:
	var parts:=PackedStringArray()
	for item in cost: parts.append("%s %d/%d"%[item_name(item),game.inventory.count(item),cost[item]])
	return " · ".join(parts)
func _process(_delta: float) -> void:
	_refresh()
	_refresh_recipes()
func _action(action: String) -> void:
	var slot:Dictionary=game.inventory.serialize()["slots"][selected]
	match action:
		"Repair": game.request_command("repair",{"slot":selected})
		"Equip": game.request_command("equip",{"slot":selected});game.tool=1;game.build_piece=""
		"Unequip": game.request_command("unequip",{"equipment":"hand"})
		"Eat": game.request_command("eat",{"item":slot.get("id","")})
		"Drop": game.request_command("inventory_drop",{"slot":selected,"amount":1})
func _refresh(force: bool=false) -> void:
	if game==null or game.inventory==null:return
	var state:Dictionary=game.inventory.serialize()
	if not force and hash(state)==_signature:return
	_signature=hash(state)
	for i in range(buttons.size()):
		var slot:Dictionary=state["slots"][i]
		buttons[i].text="·" if slot.is_empty() else item_name(slot["id"])+"\n×%d"%slot["count"]
		buttons[i].tooltip_text="" if slot.is_empty() else item_name(slot["id"])+"\n"+Catalog.source_hint(slot["id"])
		buttons[i].modulate=Color("#ffe3a2") if i==selected else Color.WHITE
	var current:Dictionary=state["slots"][selected]
	detail.text=label("Selecione um item.","Select an item.") if current.is_empty() else item_name(current["id"])+" — "+Catalog.source_hint(current["id"])
	for slot in state["equipment"]:
		if state["equipment"][slot]!="":detail.text+="\n"+tr(slot.capitalize())+": "+item_name(state["equipment"][slot])
func _refresh_recipes() -> void:
	if game==null or game.player==null or search==null:return
	var id:int=game.session.local_id
	var jobs:Array=game.runtime.activities.queue(id)
	for i in range(queue_labels.size()):
		var b:=queue_labels[i];b.visible=i<jobs.size()
		if b.visible:b.text=item_name(jobs[i]["recipe"])+" · %.1fs · "%jobs[i]["remaining"]+label("Cancelar e devolver materiais","Cancel and refund")
	for recipe in recipes:
		var b:Button=recipes[recipe];var data:Dictionary=Catalog.recipe(recipe)
		var needle:=search.text.strip_edges().to_lower()
		b.visible=needle.is_empty() or needle in item_name(recipe).to_lower() or needle in cost_text(data["cost"]).to_lower()
		var reason:String=game.runtime.craft_reason(id,recipe)
		b.disabled=not reason.is_empty()
		b.text=item_name(recipe)+" ×%d · %.1fs"%[int(data.get("yield",1)),float(data.get("time",2.5))]+"\n"+cost_text(data["cost"])+"\n"+tr(str(data["station"]).capitalize())+(" · "+reason_text(reason) if not reason.is_empty() else " · "+label("Pronto para fabricar","Ready to craft"))
		var hints:=PackedStringArray()
		for material in data["cost"]:hints.append(item_name(material)+": "+Catalog.source_hint(material))
		b.tooltip_text="\n".join(hints)

func reason_text(reason: String) -> String:
	if reason=="Crafting queue is full":return label("Fila cheia","Crafting queue is full")
	if reason=="Research required in Technology":return label("Pesquise em Tecnologias","Research required in Technology")
	if reason.begins_with("Missing materials: "):return label("Falta material: ","Missing materials: ")+reason.trim_prefix("Missing materials: ")
	if reason.begins_with("Stay near the required station: "):return label("Aproxime-se da estação: ","Stay near the required station: ")+item_name(reason.trim_prefix("Stay near the required station: "))
	return tr(reason)
