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
var inventory_search: LineEdit
var category: OptionButton
var capacity: Label
var slot_grid: GridContainer
var drop_zone
var _refresh_left: float = 0.0
var material_rows: Dictionary = {}
var quickbar_slot: OptionButton
func label(pt: String,en: String) -> String: return game.hud.t(pt,en)
func configure(value, _language: int = 0) -> void:
	game=value
	var tabs:=TabContainer.new()
	tabs.custom_minimum_size=Vector2(0,380)
	add_child(tabs)
	var inventory:=VBoxContainer.new();inventory.name=label("Mochila","Backpack");tabs.add_child(inventory)
	var toolbar := HBoxContainer.new(); inventory.add_child(toolbar)
	inventory_search = LineEdit.new(); inventory_search.placeholder_text = label("Buscar na mochila…", "Search backpack…")
	inventory_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_search.text_changed.connect(func(_text): _refresh(true)); toolbar.add_child(inventory_search)
	category = OptionButton.new()
	for title in [label("Todos", "All"), label("Equipamento", "Equipment"), label("Materiais", "Materials"), label("Alimentos", "Food")]: category.add_item(title)
	category.item_selected.connect(func(_index): _refresh(true)); toolbar.add_child(category)
	capacity = Label.new(); inventory.add_child(capacity)
	var help := Label.new(); help.text = label("Shift + arrastar: metade • Arraste para fora para deixar no chão", "Shift + drag: half stack • Drag outside to drop")
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; help.add_theme_font_size_override("font_size", 12); inventory.add_child(help)
	var grid:=GridContainer.new();grid.columns=6;inventory.add_child(grid);slot_grid=grid
	resized.connect(_fit_grid)
	drop_zone = preload("res://UI/InventoryDropZone.gd").new(); drop_zone.game = game
	drop_zone.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.hud.shade.add_child(drop_zone)
	tree_exiting.connect(func(): if is_instance_valid(drop_zone): drop_zone.queue_free())
	for i in range(36):
		var b:=preload("res://UI/InventorySlot.gd").new()
		b.game=game;b.index=i;b.custom_minimum_size=Vector2(102,70)
		b.expand_icon=true;b.add_theme_constant_override("icon_max_width",24);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;b.add_theme_font_size_override("font_size",12)
		b.pressed.connect(func(): selected=i;_refresh(true))
		grid.add_child(b);buttons.append(b)
	detail=Label.new();detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;inventory.add_child(detail)
	var actions:=GridContainer.new();actions.columns=3;inventory.add_child(actions)
	for action in ["Equip","Unequip","Eat","Drop","Repair","Split","Sort"]:
		var b:=Button.new();b.text=label({"Equip":"Equipar","Unequip":"Desequipar","Eat":"Consumir","Drop":"Descartar","Repair":"Reparar","Split":"Dividir pilha","Sort":"Organizar"}.get(action,action),action);b.pressed.connect(func():_action(action));actions.add_child(b)
	var quick := HBoxContainer.new();inventory.add_child(quick)
	quickbar_slot=OptionButton.new()
	for i in range(9):quickbar_slot.add_item(label("Atalho ","Shortcut ")+str(i+1))
	quick.add_child(quickbar_slot)
	var assign:=Button.new();assign.text=label("Vincular item selecionado","Assign selected item")
	assign.pressed.connect(func():
		var state:Dictionary=game.inventory.serialize()["slots"][selected]
		if not state.is_empty():game.settings_manager.write_sections({"quickbar":{"slot%d"%(quickbar_slot.selected+1):state["id"]}}))
	quick.add_child(assign)
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
		var materials := RichTextLabel.new(); materials.bbcode_enabled = true; materials.fit_content = true
		materials.mouse_filter = Control.MOUSE_FILTER_IGNORE; materials.add_theme_font_size_override("normal_font_size", 13)
		list.add_child(materials); material_rows[id] = materials
	var building:=VBoxContainer.new();building.name=label("Construir","Build");tabs.add_child(building)
	for entry in [["campfire",2],["shelter",3]]:
		var kind:String=entry[0];var tool:int=entry[1]
		var b:=Button.new();b.text=label("Posicionar ","Place ")+item_name(kind)
		b.pressed.connect(func():game.tool=tool;game.build_piece="";game.hud.show_panel(""));building.add_child(b)
	var scroll_build:=ScrollContainer.new();scroll_build.custom_minimum_size.y=340;building.add_child(scroll_build)
	var list_build:=VBoxContainer.new();list_build.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll_build.add_child(list_build)
	for kind in Balance.section("building")["costs"]:
		var b:=Button.new();b.text=tr("Build")+": "+item_name(kind)+" · "+cost_text(Balance.section("building")["costs"][kind])
		b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;b.add_theme_font_size_override("font_size",14)
		b.pressed.connect(func():game.select_building(kind));list_build.add_child(b)
	_refresh(true)
func item_name(id: String) -> String: return Catalog.display_name(id)
func cost_text(cost: Dictionary) -> String:
	var parts:=PackedStringArray()
	for item in cost: parts.append("%s %d/%d"%[item_name(item),game.inventory.count(item),cost[item]])
	return " · ".join(parts)
func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left > 0: return
	_refresh_left = 0.15
	_refresh()
	_refresh_recipes()

func _fit_grid() -> void:
	if slot_grid != null: slot_grid.columns = clampi(int(size.x / 82), 3, 6)

func _matches(item: String) -> bool:
	var equipment: bool = Catalog.WEAPONS.has(item) or Catalog.ARMOR.has(item) or item == "shield"
	var food: bool = item in ["berries", "raw_meat", "cooked_meat", "raw_fish", "cooked_fish", "water"]
	if category.selected == 1 and not equipment: return false
	if category.selected == 2 and (equipment or food): return false
	if category.selected == 3 and not food: return false
	return inventory_search.text.strip_edges().is_empty() or inventory_search.text.to_lower() in item_name(item).to_lower()

func split_selected() -> void:
	var slots: Array = game.inventory.serialize()["slots"]
	if slots[selected].is_empty() or int(slots[selected]["count"]) < 2: return
	for i in range(slots.size()):
		if slots[i].is_empty():
			game.request_command("inventory_move", {"from": selected, "to": i, "amount": floori(float(slots[selected]["count"]) / 2), "expected": slots[selected].duplicate(true)})
			return
func _action(action: String) -> void:
	var slot:Dictionary=game.inventory.serialize()["slots"][selected]
	match action:
		"Repair": game.request_command("repair",{"slot":selected})
		"Equip": game.request_command("equip",{"slot":selected});game.tool=1;game.build_piece=""
		"Unequip": game.request_command("unequip",{"equipment":"hand"})
		"Eat": game.request_command("eat",{"item":slot.get("id","")})
		"Drop":
			var payload: Dictionary = buttons[selected].drag_payload()
			if not payload.is_empty(): payload["amount"] = 1; drop_zone.request_drop(payload)
		"Split": split_selected()
		"Sort": game.request_command("inventory_sort", {})
func _refresh(force: bool=false) -> void:
	if game==null or game.inventory==null:return
	var state:Dictionary=game.inventory.serialize()
	if not force and hash(state)==_signature:return
	_signature=hash(state)
	for i in range(buttons.size()):
		var slot:Dictionary=state["slots"][i]
		buttons[i].visible = inventory_search.text.is_empty() and category.selected == 0 if slot.is_empty() else _matches(slot["id"])
		buttons[i].text="·" if slot.is_empty() else item_name(slot["id"])+"\n×%d"%slot["count"]
		buttons[i].icon = null if slot.is_empty() else preload("res://UI/ItemIcons.gd").icon(slot["id"])
		buttons[i].tooltip_text="" if slot.is_empty() else item_name(slot["id"])+"\n"+Catalog.source_hint(slot["id"])
		buttons[i].modulate=Color("#ffe3a2") if i==selected else Color.WHITE
	capacity.text = label("Espaços ocupados: %d / 36", "Slots used: %d / 36") % state["slots"].filter(func(slot): return not slot.is_empty()).size()
	var current:Dictionary=state["slots"][selected]
	detail.text=label("Selecione um item.","Select an item.") if current.is_empty() else item_name(current["id"])+" — "+Catalog.source_hint(current["id"])
	if not current.is_empty():
		var item: String=current["id"]
		if Catalog.WEAPONS.has(item): detail.text += "\n"+label("Ataque %d (equipado: %d)","Damage %d (equipped: %d)") % [Catalog.damage(item),Catalog.damage(game.inventory.equipped_item())]
		if Catalog.ARMOR.has(item): detail.text += "\n"+label("Proteção %.0f%% (equipada: %.0f%%)","Protection %.0f%% (equipped: %.0f%%)") % [Catalog.armor(item)*100,Catalog.armor(game.inventory.equipped_item("armor"))*100]
		if state["durability"].has(item): detail.text += " · "+label("Durabilidade %d%%","Durability %d%%") % int(state["durability"][item])
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
		var materials: RichTextLabel = material_rows[recipe]
		materials.visible = b.visible
		var lines := PackedStringArray()
		for material in data["cost"]:
			var owned: int = game.inventory.count(material)
			var required: int = data["cost"][material]
			var enough := owned >= required
			lines.append("[color=%s]%s %s %d/%d[/color]" % ["#98df9c" if enough else "#ffaaaa", "+" if enough else "!", item_name(material), owned, required])
		materials.text = "  ·  ".join(lines)
		var reason:String=game.runtime.craft_reason(id,recipe)
		b.disabled=not reason.is_empty()
		b.text=item_name(recipe)+" ×%d · %.1fs"%[int(data.get("yield",1)),float(data.get("time",2.5))]+"\n"+tr(str(data["station"]).capitalize())+(" · "+reason_text(reason) if not reason.is_empty() else " · "+label("Pronto para fabricar","Ready to craft"))
		var hints:=PackedStringArray()
		for material in data["cost"]:hints.append(item_name(material)+": "+Catalog.source_hint(material))
		b.tooltip_text="\n".join(hints)

func reason_text(reason: String) -> String:
	if reason=="Crafting queue is full":return label("Fila cheia","Crafting queue is full")
	if reason=="Research required in Technology":return label("Pesquise em Tecnologias","Research required in Technology")
	if reason.begins_with("Missing materials: "):return label("Falta material: ","Missing materials: ")+reason.trim_prefix("Missing materials: ")
	if reason.begins_with("Stay near the required station: "):return label("Aproxime-se da estação: ","Stay near the required station: ")+item_name(reason.trim_prefix("Stay near the required station: "))
	return tr(reason)
