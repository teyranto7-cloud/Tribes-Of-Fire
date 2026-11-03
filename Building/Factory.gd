extends RefCounted
## The server updates input/output together. Old automatic machines keep their recipe.
const Catalog=preload("res://Items/Catalog.gd")
static var RECIPES:Dictionary=Catalog.database().get("legacy_machines",{}).duplicate(true)
static func empty() -> Dictionary:return {"input":{},"output":{},"progress":0.0}
static func definition(kind: String,state: Dictionary) -> Dictionary:
	var id:String=state.get("recipe","")
	if id.is_empty() and RECIPES.has(kind):return RECIPES[kind].duplicate(true)
	if id.is_empty():id=str(Catalog.station(kind).get("default_recipe",""))
	var recipe:=Catalog.recipe(id)
	if recipe.is_empty() or recipe["station"]!=kind:return {}
	return {"input":recipe["cost"],"output":recipe["outputs"],"seconds":recipe["time"]}
static func advance(state: Dictionary,kind: String,delta: float) -> void:
	var recipe:=definition(kind,state)
	if recipe.is_empty() or not is_finite(delta) or delta<=0:return
	for item in recipe["input"]:
		if int(state["input"].get(item,0))<recipe["input"][item]:return
	var output_keys:Dictionary=state["output"].duplicate()
	for item in recipe["output"]:
		output_keys[item]=true
		if int(state["output"].get(item,0))+int(recipe["output"][item])>9999:return
	if output_keys.size()>8:return
	state["progress"]=minf(120,float(state["progress"])+minf(delta,60))
	var cycles:=mini(10,floori(float(state["progress"])/float(recipe["seconds"])))
	for item in recipe["input"]:cycles=mini(cycles,int(state["input"].get(item,0))/int(recipe["input"][item]))
	for item in recipe["output"]:cycles=mini(cycles,(9999-int(state["output"].get(item,0)))/int(recipe["output"][item]))
	if cycles<=0:return
	for item in recipe["input"]:state["input"][item]=int(state["input"].get(item,0))-int(recipe["input"][item])*cycles
	for item in recipe["output"]:state["output"][item]=int(state["output"].get(item,0))+int(recipe["output"][item])*cycles
	state["progress"]-=cycles*float(recipe["seconds"])
	if recipe["input"].keys().any(func(item):return int(state["input"].get(item,0))<int(recipe["input"][item])):state["progress"]=0.0
static func valid(state: Variant,kind: String="") -> bool:
	if not state is Dictionary or state.size() not in [3,4]:return false
	if state.has("recipe") and (not state["recipe"] is String or not Catalog.RECIPES.has(state["recipe"]) or (not kind.is_empty() and Catalog.recipe(state["recipe"])["station"]!=kind)):return false
	for field in ["input","output"]:
		if not state.get(field) is Dictionary or state[field].size()>8:return false
		for item in state[field]:
			var n:Variant=state[field][item]
			if not item is String or not Catalog.known(item) or not (n is int or n is float) or not is_finite(float(n)) or n!=floorf(n) or n<0 or n>9999:return false
	var p:Variant=state.get("progress")
	return (p is int or p is float) and is_finite(float(p)) and p>=0 and p<=120
