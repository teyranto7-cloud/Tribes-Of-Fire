extends VBoxContainer
const Catalog = preload("res://Items/Catalog.gd")
var game
var chest_id: int = -1
var rows: HBoxContainer
var pack: GridContainer
var chest_grid: GridContainer
var all_items: CheckBox
var signature: int = 0
func configure(value, _language: int=0) -> void:
	game=value
	chest_id=int(game.runtime.channel_state.get("storage",{}).get("id",-1))
	var hint:=Label.new();hint.text=game.hud.t("Clique para transferir • Shift: pilha inteira • Arraste entre as grades","Click to transfer • Shift: full stack • Drag between grids")
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(hint)
	all_items=CheckBox.new();all_items.text=game.hud.t("Transferir pilha inteira","Transfer full stack");add_child(all_items)
	rows=HBoxContainer.new();add_child(rows)
	pack=GridContainer.new();pack.columns=3;pack.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_child(pack)
	chest_grid=GridContainer.new();chest_grid.columns=3;chest_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_child(chest_grid)
	_refresh()
func _process(_delta: float) -> void:
	if pack != null: pack.columns=2 if size.x<680 else 3;chest_grid.columns=pack.columns
	_refresh()
func transfer(item: String, index: int, count: int, to_chest: bool) -> void:
	game.request_command("chest_transfer",{"structure":chest_id,"slot":index,"amount":count,"to_chest":to_chest,"expected_item":item})
func _refresh() -> void:
	var chest=game.world.get_structure(chest_id)
	if chest==null:return
	var contents:Dictionary=game.runtime.channel_state.get("storage",{}).get("storage",chest.storage)
	var slots:Array=game.inventory.serialize()["slots"]
	var next:=hash([contents,slots])
	if signature==next:return
	signature=next
	for grid in [pack,chest_grid]:
		for child in grid.get_children():grid.remove_child(child);child.queue_free()
	for i in range(slots.size()):
		if not slots[i].is_empty():_add_slot(pack,slots[i]["id"],int(slots[i]["count"]),i,true)
	var keys:Array=contents.keys();keys.sort()
	for i in range(keys.size()):_add_slot(chest_grid,keys[i],int(contents[keys[i]]),i,false)
	# Empty destination accepts drags even when the chest or backpack is empty.
	_add_slot(pack,"",0,-1,true);_add_slot(chest_grid,"",0,-1,false)
func _add_slot(grid: GridContainer,item: String,count: int,index: int,to_chest: bool) -> void:
	var button:=StorageSlot.new();button.panel=self;button.item=item;button.count=count;button.index=index;button.to_chest=to_chest
	button.custom_minimum_size=Vector2(100,64);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.text=game.hud.t("Mochila","Backpack") if item.is_empty() and to_chest else (game.hud.t("Baú","Chest") if item.is_empty() else Catalog.display_name(item)+"\n×%d"%count)
	button.icon=preload("res://UI/ItemIcons.gd").icon(item) if not item.is_empty() else null
	button.expand_icon=true;button.add_theme_constant_override("icon_max_width",20);button.add_theme_font_size_override("font_size",12)
	button.pressed.connect(func():if not item.is_empty():transfer(item,index,count if all_items.button_pressed or Input.is_key_pressed(KEY_SHIFT) else 1,to_chest))
	grid.add_child(button)
class StorageSlot extends Button:
	var panel
	var item: String
	var count: int
	var index: int
	var to_chest: bool
	func _get_drag_data(_at: Vector2) -> Variant:
		if item.is_empty():return null
		var preview:=Label.new();preview.text=text;set_drag_preview(preview)
		return {"kind":"storage_transfer","item":item,"count":count,"index":index,"to_chest":to_chest,"chest":panel.chest_id}
	func _can_drop_data(_at: Vector2,data: Variant) -> bool:
		return data is Dictionary and data.get("kind")=="storage_transfer" and data.get("chest")==panel.chest_id and data.get("to_chest") == (not to_chest)
	func _drop_data(_at: Vector2,data: Variant) -> void:
		if _can_drop_data(_at,data):panel.transfer(data["item"],data["index"],data["count"],data["to_chest"])
