extends RefCounted
## Canonical records survive unloading. Physics/meshes are a bounded nearby cache.
const MAXIMUM := 8192
const CHUNK := 32.0
var records: Dictionary = {}
var chunks: Dictionary = {}
var next_id: int = 1
func cell(at: Vector3) -> Vector2i: return Vector2i(floori(at.x/CHUNK),floori(at.z/CHUNK))
func point(row: Dictionary) -> Vector3: return Vector3(row["position"][0],row["position"][1],row["position"][2])
func put(row: Dictionary) -> void:
	row=row.duplicate(true)
	for field in ["id","rotation","hp","revision","paint"]:
		if row.has(field): row[field]=int(row[field])
	if row.has("supports"): row["supports"]=row["supports"].map(func(id):return int(id))
	var at:=point(row); row["position"]=[at.x,at.y,at.z]
	for field in ["paid_cost","storage","storage_wear"]:
		for item in row.get(field,{}): row[field][item]=int(row[field][item])
	var id := int(row["id"])
	if records.get(id,{})==row: return
	if records.has(id):
		var old := cell(point(records[id])); chunks[old].erase(id)
		if chunks[old].is_empty(): chunks.erase(old)
	records[id] = row.duplicate(true)
	var key := cell(point(row))
	if not chunks.has(key): chunks[key] = []
	chunks[key].append(id); next_id = maxi(next_id,id+1)
func erase(id: int) -> void:
	if not records.has(id): return
	var key := cell(point(records[id])); chunks[key].erase(id)
	if chunks[key].is_empty(): chunks.erase(key)
	records.erase(id)
func clear() -> void: records.clear(); chunks.clear(); next_id=1
func load_records(rows: Array, sequence: int = 1) -> void:
	clear()
	for row in rows: put(row)
	next_id = maxi(next_id,sequence)
func nearby(at: Vector3, radius: float) -> Array:
	var result: Array = []; var center := cell(at); var reach := ceili(radius/CHUNK)
	for z in range(-reach,reach+1):
		for x in range(-reach,reach+1):
			for id in chunks.get(center+Vector2i(x,z),[]):
				if Vector2(point(records[id]).x-at.x,point(records[id]).z-at.z).length()<=radius: result.append(id)
	result.sort(); return result
func all_records() -> Array:
	var ids := records.keys(); ids.sort(); var result: Array = []
	for id in ids: result.append(records[id].duplicate(true))
	return result
func dependants(id: int) -> Array:
	var children:Dictionary={}
	for candidate in records:
		for parent in records[candidate].get("supports",[]):
			if not children.has(int(parent)): children[int(parent)]=[]
			children[int(parent)].append(int(candidate))
	var result: Array = []; var pending: Array = [id]; var visited:Dictionary={id:true}
	while not pending.is_empty():
		var parent: int = pending.pop_front()
		for candidate in children.get(parent,[]):
			if not visited.has(candidate): visited[candidate]=true; result.append(candidate); pending.append(candidate)
	return result
