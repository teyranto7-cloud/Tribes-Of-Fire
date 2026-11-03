extends RefCounted
## Authoritative machine inventory. Time advances even when its owner disconnects.
const Catalog=preload("res://Items/Catalog.gd")
const RECIPES={"sawmill":{"input":{"wood":1},"output":{"plank":2},"seconds":6.0},"loom":{"input":{"fiber":3},"output":{"cloth":1},"seconds":7.0},"crusher":{"input":{"stone":1},"output":{"sand":2},"seconds":5.0}}
static func empty() -> Dictionary:return {"input":{},"output":{},"progress":0.0}
static func advance(state: Dictionary,kind: String,delta: float) -> void:
	if not RECIPES.has(kind) or delta<=0:return
	var recipe:Dictionary=RECIPES[kind]
	for item in recipe["input"]:
		if int(state["input"].get(item,0))<recipe["input"][item]:return
	for item in recipe["output"]:
		if int(state["output"].get(item,0))+int(recipe["output"][item])>9999:return
	state["progress"]=float(state["progress"])+minf(delta,60)
	var cycles:=mini(10,floori(float(state["progress"])/float(recipe["seconds"])))
	for item in recipe["input"]:cycles=mini(cycles,int(state["input"].get(item,0))/int(recipe["input"][item]))
	for item in recipe["output"]:cycles=mini(cycles,(9999-int(state["output"].get(item,0)))/int(recipe["output"][item]))
	if cycles<=0:return
	for item in recipe["input"]:state["input"][item]=int(state["input"].get(item,0))-int(recipe["input"][item])*cycles
	for item in recipe["output"]:state["output"][item]=int(state["output"].get(item,0))+int(recipe["output"][item])*cycles
	state["progress"]-=cycles*float(recipe["seconds"])
static func valid(state: Variant) -> bool:
	if not state is Dictionary or state.size()!=3:return false
	for field in ["input","output"]:
		if not state.get(field) is Dictionary or state[field].size()>8:return false
		for item in state[field]:
			var n:Variant=state[field][item]
			if not item is String or not Catalog.known(item) or not (n is int or n is float) or not is_finite(float(n)) or n!=floorf(n) or n<0 or n>9999:return false
	var p:Variant=state.get("progress")
	return (p is int or p is float) and is_finite(float(p)) and p>=0 and p<=120
