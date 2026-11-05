extends RefCounted
const Catalog = preload("res://Building/Catalog.gd")
const Geometry = preload("res://Building/Geometry.gd")
const Registry = preload("res://Building/Registry.gd")
static func anchor_points(row: Dictionary, kind: String) -> Array:
	var result: Array=[]; var own:=Catalog.piece(str(row["kind"])); var next:=Catalog.piece(kind)
	var family: String=own.get("snap_family","free"); var wanted: String=next.get("snap_family","free")
	var origin:=Vector3(row["position"][0],row["position"][1],row["position"][2]); var basis:=Basis(Vector3.UP,int(row["rotation"])*PI*.5)
	var points: Array=[]
	if kind=="door_leaf" and row["kind"]=="door_frame": points=[[Vector3.ZERO,0]]
	elif family=="deck":
		if wanted=="wall": points=[[Vector3(0,0,-2),0],[Vector3(0,0,2),0],[Vector3(-2,0,0),1],[Vector3(2,0,0),1]]
		elif wanted=="deck":
			var span:float=4 if kind!="bridge" else 6
			points=[[Vector3(span,0,0),0],[Vector3(-span,0,0),0],[Vector3(0,0,span),0],[Vector3(0,0,-span),0]]
		elif wanted=="pillar": points=[[Vector3(-1.8,.25,-1.8),0],[Vector3(1.8,.25,1.8),0],[Vector3.ZERO,0]]
	elif family=="wall":
		if wanted=="wall": points=[[Vector3(4,0,0),0],[Vector3(-4,0,0),0],[Vector3(0,3.2,0),0]]
		elif wanted=="roof": points=[[Vector3(0,0,-2),0],[Vector3(0,0,2),0]]
		elif wanted=="deck": points=[[Vector3(0,3.2,-2),0],[Vector3(0,3.2,2),0]]
	elif family=="pillar":
		if wanted=="deck": points=[[Vector3(0,3.2,0),0]]
		elif wanted=="roof": points=[[Vector3.ZERO,0]]
		elif wanted=="pillar": points=[[Vector3(0,3.2,0),0],[Vector3(4,0,0),0],[Vector3(-4,0,0),0]]
	elif family=="roof" and wanted=="roof": points=[[Vector3(4,0,0),0],[Vector3(-4,0,0),0],[Vector3(0,0,4),0],[Vector3(0,0,-4),0]]
	for entry in points: result.append({"position":origin+basis*entry[0],"rotation":posmod(int(row["rotation"])+int(entry[1]),4),"support":int(row["id"])})
	return result
static func evaluate(world, player, kind: String, turn: int, options: Dictionary={}, ignore_id: int=0) -> Dictionary:
	var target: Vector3=player.position-player.global_basis.z*4
	if options.has("position"): target=Vector3(options["position"][0],options["position"][1],options["position"][2])
	else: target.y=world.terrain_height(target.x,target.z)+float(options.get("height",0))
	if options.get("grid",true): target.x=snappedf(target.x,2); target.z=snappedf(target.z,2)
	var result: Dictionary={"valid":false,"position":target,"rotation":posmod(turn,4),"supports":[],"reason":"invalid"}
	if not Catalog.known(kind) or not Catalog.valid_options(options): return result
	var definition:=Catalog.piece(kind)
	if options.get("mirror",false) and not definition.get("mirror",false): result["reason"]="mirror"; return result
	if not str(options.get("tier","wood")) in definition.get("tiers",Catalog.tiers()): result["reason"]="material"; return result
	if world.structure_registry.records.size()>=Registry.MAXIMUM and ignore_id==0: result["reason"]="limit"; return result
	var best:=2.35; var selected: Dictionary={}
	if options.get("snap",true):
		for id in world.structure_registry.nearby(target,12):
			if id==ignore_id: continue
			for anchor in anchor_points(world.structure_registry.records[id],kind):
				var distance:float=anchor["position"].distance_to(target)
				if distance<best: best=distance; selected=anchor
	if not selected.is_empty():
		target=selected["position"]; result["rotation"]=int(selected["rotation"]) if kind=="door_leaf" else posmod(int(selected["rotation"])+turn,4); result["supports"]=[selected["support"]]
	result["position"]=target
	if not world.contains_position(target) or not Catalog.numeric(target.y,-30,120) or target.distance_to(player.position)>9: result["reason"]="reach"; return result
	world.ensure_structures(target)
	for id in world.structure_registry.nearby(target,12):
		if id==ignore_id or id in result["supports"]: continue
		var node=world.get_structure(id)
		if node==null or int(node.get_meta("collision_frame",-100))>=Engine.get_physics_frames()-1:
			var planned:Dictionary={"kind":kind,"position":[target.x,target.y,target.z],"rotation":result["rotation"],"mirror":options.get("mirror",false)}
			if records_overlap(planned,world.structure_registry.records[id]): result["reason"]="collision"; return result
	if target.y<=world.water_level+.05 and kind!="bridge": result["reason"]="water"; return result
	var basis:=Basis(Vector3.UP,int(result["rotation"])*PI*.5)
	var exclusions: Array[RID]=[]
	for ground in world.get_tree().get_nodes_in_group("terrain"):
		if ground is CollisionObject3D: exclusions.append(ground.get_rid())
	for id in result["supports"]+[ignore_id]:
		var existing=world.get_structure(int(id))
		if existing!=null:
			exclusions.append(existing.get_rid())
			for child in existing.find_children("*","CollisionObject3D"): exclusions.append(child.get_rid())
	var parts: Array=Catalog.boxes(kind,bool(options.get("mirror",false)))
	if definition.has("door"):
		var opening:Array=definition["door"]
		parts.append([opening[0],0.16,opening[1],0,0.25,0] if kind=="hatch" else [opening[0],opening[1],0.18,0,0.25+float(opening[1])/2,0])
	for box in parts:
		var at:Vector3=target+basis*Vector3(box[3],box[4],box[5]); var size:=Vector3(box[0],box[1],box[2])
		var shape:=BoxShape3D.new(); shape.size=Vector3(maxf(.02,size.x-.26),maxf(.02,size.y-.04),maxf(.02,size.z-.06))
		var full_shape:=BoxShape3D.new(); full_shape.size=size+Vector3.ONE*.02
		var error:=volume_error(world,shape,Transform3D(basis,at),exclusions,full_shape)
		if not error.is_empty(): result["reason"]=error; return result
		if not definition.get("grounded",false):
			for x in [-.4,.4]:
				for z in [-.4,.4]:
					var sample:Vector3=at+basis*Vector3(size.x*x,0,size.z*z)
					if not world.contains_position(sample): result["reason"]="reach"; return result
					if at.y-size.y/2<world.terrain_height(sample.x,sample.z)-.45: result["reason"]="terrain"; return result
	if definition.get("shape","") in ["triangle","ramp","roof_slope","stairs"]:
		var points:=Geometry.vertices(kind,bool(options.get("mirror",false))); var center:=Vector3.ZERO
		for p in points: center+=p
		center/=points.size()
		var inset:=PackedVector3Array()
		for p in points: inset.append(center+(p-center)*.99)
		var shape:=ConvexPolygonShape3D.new(); shape.points=inset
		var full_shape:=ConvexPolygonShape3D.new(); full_shape.points=points
		var error:=volume_error(world,shape,Transform3D(basis,target),exclusions,full_shape)
		if not error.is_empty(): result["reason"]=error; return result
	if definition.get("grounded",false) and result["supports"].is_empty():
		for offset in [Vector3(-1.5,0,-1.5),Vector3(1.5,0,1.5)]:
			var p:Vector3=target+basis*offset
			if absf(target.y-world.terrain_height(p.x,p.z))>1.2: result["reason"]="terrain"; return result
	var ray:=PhysicsRayQueryParameters3D.create(player.position+Vector3.UP*1.4,target+Vector3.UP*.6,1,[player.get_rid()])
	if ignore_id>0 and world.get_structure(ignore_id)!=null: ray.exclude.append(world.get_structure(ignore_id).get_rid())
	var hit:Dictionary=world.get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty() and not hit["collider"].is_in_group("terrain") and hit["position"].distance_to(target+Vector3.UP*.6)>.8:
		if not (hit["collider"].is_in_group("building_piece") and hit["collider"].structure_id in result["supports"]): result["reason"]="visibility"; return result
	result["valid"]=true; result["reason"]="ok"; return result
static func volume_error(world, shape: Shape3D, transform: Transform3D, exclude: Array[RID], character_shape: Shape3D=null) -> String:
	var query:=PhysicsShapeQueryParameters3D.new(); query.shape=shape; query.transform=transform; query.exclude=exclude; query.collision_mask=1
	if not world.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(): return "collision"
	query.exclude=[]; query.collision_mask=2
	if character_shape!=null: query.shape=character_shape
	if not world.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(): return "player"
	return ""
static func station(world, player, turn: int, options: Dictionary={}, ignore: Variant=null) -> Dictionary:
	var at:Vector3=player.position-player.global_basis.z*4
	if options.has("position"): at=Vector3(options["position"][0],options["position"][1],options["position"][2])
	if options.get("grid",true): at.x=snappedf(at.x,2); at.z=snappedf(at.z,2)
	if not options.has("position"): at.y=world.terrain_height(at.x,at.z)+float(options.get("height",0))
	var result:Dictionary={"valid":false,"position":at,"rotation":posmod(turn,4),"reason":"invalid"}
	if not Catalog.valid_options(options) or options.get("tier","wood")!="wood" or options.get("mirror",false): return result
	if not world.contains_position(at) or not Catalog.numeric(at.y,-30,120) or at.distance_to(player.position)>9: result["reason"]="reach"; return result
	if at.y<=world.water_level+.1: result["reason"]="water"; return result
	world.ensure_structures(at)
	var excluded:Array[RID]=[]
	for ground in world.get_tree().get_nodes_in_group("terrain"):
		if ground is CollisionObject3D: excluded.append(ground.get_rid())
	if ignore!=null: excluded.append(ignore.get_rid())
	var shape:=BoxShape3D.new(); shape.size=Vector3(1.65,1.16,.95)
	var reason:=volume_error(world,shape,Transform3D(Basis(Vector3.UP,turn*PI*.5),at+Vector3.UP*.6),excluded)
	if not reason.is_empty(): result["reason"]=reason; return result
	if at.y-world.terrain_height(at.x,at.z)>.5:
		var support:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.08,at-Vector3.UP*.35,1)
		if ignore!=null: support.exclude=[ignore.get_rid()]
		if world.get_world_3d().direct_space_state.intersect_ray(support).is_empty(): result["reason"]="support"; return result
	for x in [-.7,.7]:
		for z in [-.4,.4]:
			if at.y<world.terrain_height(at.x+x,at.z+z)-.2: result["reason"]="terrain"; return result
	var ray:=PhysicsRayQueryParameters3D.create(player.position+Vector3.UP*1.4,at+Vector3.UP*.6,1,[player.get_rid()])
	if ignore!=null: ray.exclude.append(ignore.get_rid())
	var hit:Dictionary=world.get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty() and not hit["collider"].is_in_group("terrain"): result["reason"]="visibility"; return result
	result["valid"]=true; result["reason"]="ok"; return result
static func volumes(row: Dictionary) -> Array:
	var result:Array=[]; var kind:String=row["kind"]; var origin:=Vector3(row["position"][0],row["position"][1],row["position"][2]); var basis:=Basis(Vector3.UP,int(row["rotation"])*PI*.5)
	var boxes:Array=Catalog.boxes(kind,row.get("mirror",false))
	if Catalog.piece(kind).has("door"):
		var opening:Array=Catalog.piece(kind)["door"]
		boxes.append([opening[0],.16,opening[1],0,.25,0] if kind=="hatch" else [opening[0],opening[1],.18,0,.25+float(opening[1])/2,0])
	for box in boxes:
		var poly:Array=[]; var at:=Vector3(box[3],box[4],box[5])
		for p in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
			var v:Vector3=origin+basis*(at+Vector3(p.x*maxf(.01,float(box[0])/2-.13),0,p.y*maxf(.01,float(box[2])/2-.03)))
			poly.append(Vector2(v.x,v.z))
		result.append({"poly":poly,"low":origin.y+at.y-float(box[1])/2+.02,"high":origin.y+at.y+float(box[1])/2-.02})
	var vertices:=Geometry.vertices(kind,row.get("mirror",false))
	if not vertices.is_empty():
		var low:=INF; var high:=-INF; var poly:Array=[]; var count:int=vertices.size()/2
		for v in vertices: low=minf(low,v.y); high=maxf(high,v.y)
		var indices:Array=[0,1,5,2] if Catalog.piece(kind).get("shape","")=="stairs" else range(count)
		for i in indices:
			var v:Vector3=origin+basis*(vertices[i]*Vector3(.995,1,.995)); poly.append(Vector2(v.x,v.z))
		result.append({"poly":poly,"low":origin.y+low+.02,"high":origin.y+high-.02})
	return result
static func records_overlap(a:Dictionary,b:Dictionary) -> bool:
	for left in volumes(a):
		for right in volumes(b):
			if minf(left["high"],right["high"])<=maxf(left["low"],right["low"])+.005: continue
			var separated:=false
			for polygon in [left["poly"],right["poly"]]:
				for i in range(polygon.size()):
					var edge:Vector2=polygon[(i+1)%polygon.size()]-polygon[i]; var axis:=Vector2(-edge.y,edge.x).normalized()
					var min_a:=INF; var max_a:=-INF; var min_b:=INF; var max_b:=-INF
					for p in left["poly"]: min_a=minf(min_a,p.dot(axis)); max_a=maxf(max_a,p.dot(axis))
					for p in right["poly"]: min_b=minf(min_b,p.dot(axis)); max_b=maxf(max_b,p.dot(axis))
					if minf(max_a,max_b)<=maxf(min_a,min_b)+.005: separated=true; break
				if separated: break
			if not separated: return true
	return false
