extends RefCounted
## Stable piece/material IDs. Legacy IDs and their wood costs remain unchanged.
const ItemCatalog = preload("res://Items/Catalog.gd")
const Balance = preload("res://Game/Balance.gd")
static var _data: Dictionary = {}
static func database() -> Dictionary:
	if _data.is_empty(): _data = JSON.parse_string(FileAccess.get_file_as_string("res://Data/Building.json"))
	return _data
static func ids() -> Array: return database()["pieces"].keys()
static func known(kind: String) -> bool: return database()["pieces"].has(kind)
static func piece(kind: String) -> Dictionary: return database()["pieces"].get(kind,{}).duplicate(true)
static func tiers() -> Array: return database()["materials"].keys()
static func material(tier: String) -> Dictionary: return database()["materials"].get(tier,{}).duplicate(true)
static func title(kind: String) -> String: return ItemCatalog.localized(piece(kind).get("name",{"en":kind}))
static func tier_title(tier: String) -> String: return ItemCatalog.localized(material(tier).get("name",{"en":tier}))
static func maximum_hp(tier: String) -> int: return int(material(tier).get("hp",100))
static func salvage_basis(kind: String, cost: Dictionary) -> Dictionary:
	var result:Dictionary={}
	for item in cost:
		var recipe:Dictionary=ItemCatalog.recipe(item)
		if ItemCatalog.get_item(item).get("place","")==kind and int(recipe.get("outputs",{}).get(item,0))>0:
			for input in recipe["cost"]:
				var amount:=floori(float(recipe["cost"][input])*float(cost[item])/float(recipe["outputs"][item]))
				if amount>0: result[input]=int(result.get(input,0))+amount
		else: result[item]=int(result.get(item,0))+int(cost[item])
	return result
static func cost(kind: String, tier: String = "wood") -> Dictionary:
	var row := piece(kind)
	if row.is_empty() or not tier in row.get("tiers",tiers()): return {}
	if tier == "wood" and Balance.section("building")["costs"].has(kind): return Balance.section("building")["costs"][kind].duplicate(true)
	var result := {}; var units := float(row.get("units",1))
	for item in material(tier).get("cost",{}): result[item] = maxi(1,ceili(units * float(material(tier)["cost"][item])))
	return result
static func boxes(kind: String, mirrored: bool = false) -> Array:
	var result: Array = piece(kind).get("boxes",[]).duplicate(true)
	if piece(kind).get("shape","")=="gate":
		var opening: Array = piece(kind)["door"]; var w := float(opening[0]); var h := float(opening[1])
		result = [[0.4,h+0.4,0.4,-w/2-0.2,h/2+0.25,0],[0.4,h+0.4,0.4,w/2+0.2,h/2+0.25,0],[w+0.8,0.4,0.4,0,h+0.45,0]]
	if mirrored:
		for box in result: box[3] = -float(box[3])
	return result
static func valid_options(options: Dictionary) -> bool:
	for key in options:
		match key:
			"tier":
				if not options[key] is String or not options[key] in tiers(): return false
			"height":
				if not numeric(options[key],-1,12) or not is_equal_approx(float(options[key])*4,roundf(float(options[key])*4)): return false
			"grid","snap","mirror":
				if not options[key] is bool: return false
			"position":
				if not options[key] is Array or options[key].size()!=3: return false
				for n in options[key]:
					if not numeric(n,-1000,1000): return false
			_: return false
	return true
static func numeric(n: Variant, low: float, high: float) -> bool:
	return (n is int or n is float) and is_finite(float(n)) and n>=low and n<=high
static func reason(code: String) -> String:
	var messages := {
		"ok":["Local válido","Valid location"],"invalid":["Pedido inválido","Invalid request"],
		"cost":["Faltam materiais","Missing materials"],"collision":["Colisão com estrutura ou recurso","Structure or resource collision"],
		"player":["Há um personagem no espaço da peça","A character occupies the piece volume"],"terrain":["Terreno obstruído ou muito inclinado","Terrain obstructed or too steep"],
		"ownership":["Sem permissão nesta propriedade","No permission on this property"],"reach":["Fora do alcance de 9 m","Outside 9 m reach"],
		"water":["Local submerso","Submerged location"],"frame":["A folha exige um marco de porta compatível","Door leaf requires a compatible door frame"],"support":["Falta suporte ou vão excedido","Missing support or excessive span"],
		"visibility":["Caminho de interação bloqueado","Interaction path blocked"],"limit":["Limite de estruturas ou IDs atingido","Structure or ID limit reached"],
		"mirror":["Esta peça não permite espelhamento","This piece cannot be mirrored"],"material":["Material incompatível ou melhoria inválida","Incompatible material or invalid upgrade"],
		"stale":["Peça alterada: atualize a seleção","Piece changed: refresh selection"],"intact":["Peça já está íntegra","Piece is already intact"],
		"dependants":["Há peças dependentes: remova-as ou confirme o conjunto","Dependent pieces: remove them or confirm the group"],
		"contents":["Esvazie o conteúdo primeiro; jangadas usam seu próprio sistema","Empty contents first; rafts use their own system"],
		"industrial_support":["Suporte industrial protegido: esvazie e recoloque os aparelhos antes","Industrial support protected: empty and relocate devices first"],
		"destroyed":["Estrutura destruída: recolha os destroços e reconstrua","Structure destroyed: collect wreckage and rebuild"],
		"connections":["Remova cabos e esteiras primeiro","Remove cables and conveyors first"],"motor":["Retire o motor primeiro","Remove the motor first"],
		"occupied":["Afaste os personagens da estrutura","Move characters away from the structure"],"capacity":["Mochila sem espaço para a restituição","Backpack cannot hold the refund"]}
	var pair: Array=messages.get(code,[code,code])
	return pair[0] if TranslationServer.get_locale().begins_with("pt") else pair[1]
static func valid_record(row: Dictionary, extent: float) -> bool:
	if not known(str(row.get("kind",""))) or not numeric(row.get("id"),1,1000000) or float(row["id"])!=floorf(float(row["id"])): return false
	var p: Variant = row.get("position")
	if not p is Array or p.size()!=3 or not numeric(p[0],-extent,extent) or not numeric(p[1],-30,120) or not numeric(p[2],-extent,extent): return false
	var tier: Variant = row.get("tier","wood")
	if not tier is String or not tier in piece(row["kind"]).get("tiers",tiers()): return false
	if not numeric(row.get("rotation"),0,3) or row["rotation"]!=floorf(row["rotation"]) or not numeric(row.get("hp"),0,maximum_hp(tier)) or row["hp"]!=floorf(row["hp"]): return false
	if not row.get("open") is bool or not row.get("owner") is String or row["owner"].length()>128: return false
	for flag in ["mirror","locked","allow_allies"]:
		if row.has(flag) and not row[flag] is bool: return false
	if row.get("mirror",false) and not piece(row["kind"]).get("mirror",false): return false
	if row.has("door_swing") and (not piece(row["kind"]).has("door") or not numeric(row["door_swing"],-1,1) or absf(float(row["door_swing"]))!=1): return false
	if not row.get("name","") is String or row.get("name","").length()>40 or str(row.get("name","")).contains("\n"): return false
	if not numeric(row.get("paint",0),0,5) or row.get("paint",0)!=floorf(row.get("paint",0)): return false
	if not numeric(row.get("revision",1),1,1000000000) or row.get("revision",1)!=floorf(row.get("revision",1)): return false
	var supports: Variant = row.get("supports",[])
	if not supports is Array or supports.size()>8: return false
	var seen := {}
	for id in supports:
		if not numeric(id,1,1000000) or id!=floorf(id) or int(id)==int(row["id"]) or seen.has(int(id)): return false
		seen[int(id)] = true
	var paid: Variant = row.get("paid_cost",{})
	if not paid is Dictionary or paid.size()>16: return false
	for item in paid:
		if not item is String or not ItemCatalog.known(item) or not numeric(paid[item],1,9999) or paid[item]!=floorf(paid[item]): return false
	return true
