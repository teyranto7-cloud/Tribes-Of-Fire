extends RefCounted
## Permanent IDs and all content definitions live in Data/Items.json.
static var _data: Dictionary = {}
static var WEAPONS: Dictionary = _statistics("damage")
static var ARMOR: Dictionary = _statistics("armor")
static var RECIPES: Dictionary = database().get("recipes", {}).duplicate(true)
static var RESOURCES: Array = database().get("items", {}).keys()
static func database() -> Dictionary:
	if _data.is_empty():
		var value: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://Data/Items.json"))
		if value is Dictionary: _data=value
	return _data
static func _statistics(key: String) -> Dictionary:
	var result:Dictionary={}
	for id in database().get("items",{}):
		var stats:Dictionary=database()["items"][id].get("statistics",{})
		if stats.has(key):result[id]=stats[key]
	return result
static func ids() -> Array:return database().get("items",{}).keys()
static func known(id: String) -> bool:return database().get("items",{}).has(id)
static func get_item(id: String) -> Dictionary:return database().get("items",{}).get(id,{}).duplicate(true)
static func damage(id: String) -> int:return int(get_item(id).get("statistics",{}).get("damage",0))
static func armor(id: String) -> float:return float(get_item(id).get("statistics",{}).get("armor",0))
static func recipe(id: String) -> Dictionary:
	var value:Dictionary=RECIPES.get(id,{}).duplicate(true)
	if value.is_empty():return {}
	value["cost"]=value.get("inputs",value.get("cost",{})).duplicate(true)
	for field in ["cost","outputs"]:
		for item in value.get(field,{}):value[field][item]=int(value[field][item])
	value["inputs"]=value["cost"].duplicate()
	return value
static func station(id: String) -> Dictionary:return database().get("stations",{}).get(id,{}).duplicate(true)
static func station_ids() -> Array:return database().get("stations",{}).keys()
static func localized(value: Dictionary) -> String:
	var locale:=TranslationServer.get_locale()
	if value.has(locale):return value[locale]
	if locale.begins_with("pt") and value.has("pt_BR"):return value["pt_BR"]
	return TranslationServer.translate(str(value.get("en","")))
static func display_name(id: String) -> String:
	if known(id):return localized(get_item(id).get("name",{}))
	if RECIPES.has(id):
		var outputs:Dictionary=recipe(id).get("outputs",{})
		if not outputs.is_empty():return display_name(outputs.keys()[0])
	return TranslationServer.translate(id.replace("_"," ").capitalize()) if not id.is_empty() else "—"
static func source_hint(id: String) -> String:
	var source:String=get_item(id).get("source","craft")
	var messages:Dictionary={"gather":"Collect in the world with E","mine":"Equip a pickaxe and mine a deposit","hunt":"Hunt animals and collect their remains","craft":"Crafting"}
	return TranslationServer.translate(messages.get(source,"Crafting"))
static func tool(id: String) -> String:return get_item(id).get("statistics",{}).get("tool","")
static func harvest_power(id: String) -> int:return int(get_item(id).get("statistics",{}).get("harvest_power",0))
static func gathering(id: String) -> Dictionary:return database().get("gathering",{}).get(id,{}).duplicate(true)
