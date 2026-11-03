extends RefCounted
const Balance = preload("res://Game/Balance.gd")
## Stable item identifiers shared by authority, UI and save migration.
const RESOURCES := ["medical_kit","herb", "petals", "clay", "sand", "soil", "plank", "cloth", "rope", "brick", "glass", "silver_ingot", "gold_ingot", "bandage", "herbal_tea", "wood", "stone", "fiber", "coal", "copper_ore", "tin_ore", "iron_ore", "silver_ore", "gold_ore", "sulfur", "rare_ore", "copper_ingot", "bronze_ingot", "iron_ingot", "steel_ingot", "raw_meat", "cooked_meat", "raw_fish", "cooked_fish", "berries", "water", "leather", "bone", "arrow"]
const WEAPONS := {"silver_sword":30,"shovel": 5,"axe": 10, "club": 10, "spear": 15, "stone_sword": 12, "copper_sword": 17, "bronze_sword": 22, "iron_sword": 28, "steel_sword": 35, "bow": 16, "pickaxe": 5, "iron_pickaxe": 8}
const ARMOR := {"gold_armor":0.42,"leather_armor": 0.12, "bone_armor": 0.18, "copper_armor": 0.25, "bronze_armor": 0.32, "iron_armor": 0.45, "steel_armor": 0.55}
const RECIPES := {"medical_kit":{"cost":{"cloth":2,"herb":2},"station":"workbench"},"silver_sword":{"cost":{"silver_ingot":3,"rare_ore":1,"wood":2},"station":"workbench"},"gold_armor":{"cost":{"gold_ingot":6,"leather":3},"station":"workbench"},
	"plank": {"cost": {"wood": 1}, "station": "workbench"},
	"cloth": {"cost": {"fiber": 3}, "station": "workbench"},
	"rope": {"cost": {"fiber": 2}, "station": "hand"},
	"brick": {"cost": {"clay": 2}, "station": "furnace"},
	"glass": {"cost": {"sand": 2, "coal": 1}, "station": "furnace"},
	"silver_ingot": {"cost": {"silver_ore": 2, "coal": 1}, "station": "furnace"},
	"gold_ingot": {"cost": {"gold_ore": 2, "coal": 1}, "station": "furnace"},
	"bandage": {"cost": {"fiber": 3, "herb": 1}, "station": "hand"},
	"herbal_tea": {"cost": {"petals": 1, "herb": 1, "water": 1}, "station": "campfire"},
	"shovel": {"cost": {"wood": 3, "stone": 3}, "station": "hand"},

	"axe": {"cost": {"wood": 2, "stone": 3}, "station": "hand"},
	"campfire": {"cost": {"wood": 8}, "station": "hand"}, "shelter": {"cost": {"wood": 12}, "station": "hand"},
	"pickaxe": {"cost": {"wood": 4, "stone": 4}, "station": "hand"}, "club": {"cost": {"wood": 3}, "station": "hand"},
	"spear": {"cost": {"wood": 5, "stone": 3}, "station": "hand"}, "stone_sword": {"cost": {"wood": 3, "stone": 6}, "station": "workbench"},
	"copper_ingot": {"cost": {"copper_ore": 2, "coal": 1}, "station": "furnace"}, "bronze_ingot": {"cost": {"copper_ingot": 2, "tin_ore": 1, "coal": 1}, "station": "furnace"},
	"iron_ingot": {"cost": {"iron_ore": 2, "coal": 1}, "station": "furnace"}, "steel_ingot": {"cost": {"iron_ingot": 2, "coal": 2}, "station": "furnace"},
	"copper_sword": {"cost": {"copper_ingot": 3, "wood": 2}, "station": "workbench"}, "bronze_sword": {"cost": {"bronze_ingot": 3, "wood": 2}, "station": "workbench"},
	"iron_sword": {"cost": {"iron_ingot": 3, "wood": 2}, "station": "workbench"}, "steel_sword": {"cost": {"steel_ingot": 3, "wood": 2}, "station": "workbench"},
	"bow": {"cost": {"wood": 6, "fiber": 4}, "station": "workbench"}, "arrow": {"cost": {"wood": 1, "stone": 1}, "station": "hand"},
	"shield": {"cost": {"wood": 6, "leather": 2}, "station": "workbench"}, "leather_armor": {"cost": {"leather": 6, "fiber": 2}, "station": "workbench"},
	"bone_armor": {"cost": {"bone": 6, "leather": 3}, "station": "workbench"}, "iron_armor": {"cost": {"iron_ingot": 6, "leather": 3}, "station": "workbench"},
	"iron_pickaxe": {"cost": {"iron_ingot": 3, "wood": 4}, "station": "workbench"},
	"copper_armor": {"cost": {"copper_ingot": 3, "leather": 3}, "station": "workbench"},
	"bronze_armor": {"cost": {"bronze_ingot": 3, "leather": 3}, "station": "workbench"},
	"steel_armor": {"cost": {"steel_ingot": 3, "leather": 3}, "station": "workbench"},
	"cooked_fish": {"cost": {"raw_fish": 1}, "station": "campfire"}, "cooked_meat": {"cost": {"raw_meat": 1}, "station": "campfire"}}
static func ids() -> Array:
	return ["axe", "wood", "campfire", "shelter"] + RESOURCES.filter(func(id): return id != "wood") + WEAPONS.keys().filter(func(id): return id != "axe") + ["shield"] + ARMOR.keys()
static func known(id: String) -> bool:
	return id in ["campfire", "shelter", "shield"] or id in RESOURCES or WEAPONS.has(id) or ARMOR.has(id)
static func get_item(id: String) -> Dictionary:
	return {"id": id, "stack": 1 if WEAPONS.has(id) or ARMOR.has(id) or id == "shield" else 99, "durability": 100} if known(id) else {}
static func damage(id: String) -> int:
	return int(Balance.section("weapons").get(id, WEAPONS.get(id, 0)))
static func armor(id: String) -> float:
	return float(Balance.section("armor").get(id, ARMOR.get(id, 0.0)))
static func recipe(id: String) -> Dictionary:
	return Balance.section("recipes").get(id, RECIPES.get(id, {})).duplicate(true)
static func display_name(id: String) -> String:
	if TranslationServer.get_locale().begins_with("pt"):
		var names:Dictionary={"medical_kit":"Kit medicinal","silver_sword":"Espada de prata","gold_armor":"Armadura de ouro","lantern":"Lamparina","torch":"Tocha","herb":"Erva medicinal","petals":"Flores","clay":"Argila","sand":"Areia","soil":"Terra","plank":"Tábuas","cloth":"Tecido","rope":"Corda","brick":"Tijolos","glass":"Vidro","bandage":"Curativo","herbal_tea":"Chá de ervas","shovel":"Pá","sawmill":"Serraria","loom":"Tear","crusher":"Britador","raft":"Jangada","totem":"Totem da tribo","silver_ingot":"Lingote de prata","gold_ingot":"Lingote de ouro"}
		if names.has(id):return names[id]
	var text := id.replace("_", " ").to_lower()
	if text.is_empty():
		return "—"
	# Catalog keys use sentence case; String.capitalize() title-cases every word.
	return TranslationServer.translate(text.left(1).to_upper() + text.substr(1))

static func source_hint(id: String) -> String:
	if id in ["raw_meat","leather","bone"]: return TranslationServer.translate("Hunt animals and collect their remains")
	if id=="raw_fish": return TranslationServer.translate("Fish with a spear near the lake")
	if id=="water": return TranslationServer.translate("Interact with the spring to drink or fill water")
	if id in ["herb","petals","berries","fiber","wood","stone","clay","sand","soil"]: return TranslationServer.translate("Collect in the world with E")
	if id.ends_with("_ore") or id in ["coal","sulfur"]: return TranslationServer.translate("Equip a pickaxe and mine a deposit")
	return TranslationServer.translate("Crafting")
