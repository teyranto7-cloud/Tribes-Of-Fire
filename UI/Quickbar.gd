extends HBoxContainer
const Catalog = preload("res://Items/Catalog.gd")
const DEFAULTS := ["axe","campfire","shelter","pickaxe","spear","berries","water","bandage","shovel"]
var game
var buttons: Array[Button] = []
static func item_for(game_value, index: int) -> String:
	var item: Variant = game_value.settings_manager.read("quickbar","slot%d" % (index+1),DEFAULTS[index])
	return item if item is String and Catalog.known(item) else DEFAULTS[index]
func _ready() -> void:
	for i in range(9):
		var button := Button.new(); button.expand_icon=true;button.add_theme_constant_override("icon_max_width",22)
		button.add_theme_font_size_override("font_size",12);button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.pressed.connect(func():game.use_quick_slot(i));add_child(button);buttons.append(button)
func _process(_delta: float) -> void:
	visible=game.running and game.player!=null and game.hud.mode==""
	if not visible:return
	for i in range(buttons.size()):
		var item:=item_for(game,i);var button:=buttons[i]
		button.text="%d · %s\n×%d" % [i+1,Catalog.display_name(item),game.inventory.count(item)]
		button.icon=preload("res://UI/ItemIcons.gd").icon(item)
		button.tooltip_text=Catalog.display_name(item)
		button.disabled=game.inventory.count(item)==0
