extends RefCounted
const Catalog = preload("res://Building/Catalog.gd")
const Shapes = preload("res://World/Shapes.gd")
static var _ghosts: Dictionary = {}
static var _materials: Dictionary = {}
static func vertices(kind: String, mirrored: bool) -> PackedVector3Array:
	var shape: String = Catalog.piece(kind).get("shape","")
	var points := PackedVector3Array()
	if shape=="triangle":
		for y in [0.0,0.25]:
			for p in [Vector2(-2,-2),Vector2(2,-2),Vector2(-2,2)]: points.append(Vector3(p.x,y,p.y))
	elif shape=="stairs":
		points=PackedVector3Array([Vector3(-1,0,2),Vector3(1,0,2),Vector3(-1,0,-2),Vector3(-1,3.2,-2),Vector3(1,3.2,-2),Vector3(1,0,-2)])
	elif shape in ["ramp","roof_slope"]:
		for top in [false,true]:
			for p in [Vector2(-2,-2),Vector2(2,-2),Vector2(2,2),Vector2(-2,2)]:
				var y: float = (3.2 if p.y<0 else 0.0) if shape=="ramp" else (5.0 if p.y<0 else 3.2)
				points.append(Vector3(p.x,y+((0.0 if top else -0.2) if shape=="ramp" else (0.2 if top else 0.0)),p.y))
	if mirrored:
		for i in points.size(): points[i].x=-points[i].x
	return points
static func prism_mesh(kind: String, mirrored: bool) -> ArrayMesh:
	var p := vertices(kind,mirrored); var faces: Array
	if p.size()==6: faces=[[0,1,2],[3,4,5],[0,1,4],[0,4,3],[1,2,5],[1,5,4],[2,0,3],[2,3,5]]
	else: faces=[[0,1,2],[0,2,3],[4,5,6],[4,6,7],[0,1,5],[0,5,4],[1,2,6],[1,6,5],[2,3,7],[2,7,6],[3,0,4],[3,4,7]]
	var center := Vector3.ZERO
	for v in p: center+=v
	center/=p.size()
	var surface := SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in faces:
		var a: Vector3=p[face[0]]; var b: Vector3=p[face[1]]; var c: Vector3=p[face[2]]
		var normal := (b-a).cross(c-a).normalized(); var middle := (a+b+c)/3
		if normal.dot(middle-center)<0: normal=-normal
		# Godot front faces use clockwise winding; normals point outwards.
		var order: Array = [a,c,b] if (b-a).cross(c-a).dot(normal)>0 else [a,b,c]
		for v in order: surface.set_normal(normal); surface.set_uv(Vector2(v.x,v.z)); surface.add_vertex(v)
	return surface.commit()
static func add_box(parent: Node3D, box: Array, color: Color, solid: bool=true) -> void:
	var size := Vector3(box[0],box[1],box[2]); var at := Vector3(box[3],box[4],box[5])
	Shapes.box(parent,size,at,color)
	if solid:
		var shape := BoxShape3D.new(); shape.size=size; Shapes.collider(parent,shape,at)
static func build(body, row: Dictionary) -> void:
	var kind: String=body.kind; var wood := Color("#855d3b")
	for box in Catalog.boxes(kind,bool(row.get("mirror",false))): add_box(body,box,wood)
	var shape: String=Catalog.piece(kind).get("shape","")
	if shape in ["triangle","ramp","roof_slope"]:
		Shapes.mesh(body,prism_mesh(kind,bool(row.get("mirror",false))),Vector3.ZERO,wood)
		var solid := ConvexPolygonShape3D.new(); solid.points=vertices(kind,bool(row.get("mirror",false))); Shapes.collider(body,solid,Vector3.ZERO)
	if shape in ["gate","door_leaf"] or kind=="hatch":
		var size: Array=Catalog.piece(kind)["door"]; var w:=float(size[0]); var h:=float(size[1])
		body.hinge=Node3D.new(); body.hinge.position=Vector3(-w/2,0.25,0) if kind!="hatch" else Vector3(-w/2,0.25,0); body.add_child(body.hinge)
		var panel:=StaticBody3D.new(); body.hinge.add_child(panel); panel.add_to_group("building_door_leaf")
		if kind=="hatch": add_box(panel,[w,0.16,h,w/2,0,0],wood)
		else:
			add_box(panel,[w,h,0.18,w/2,h/2,0],wood)
			for y in [h*.2,h*.8]: add_box(panel,[w,0.12,0.24,w/2,y,0],wood.darkened(.25),false)
	if shape=="vase":
		Shapes.sculpted(body,Vector3(0,.28,0),Vector3(.5,.55,.5),Color("#b87950"),"stone")
		for i in range(5):
			var at:=Vector3(sin(i*2.4)*.15,.7+float(i%2)*.12,cos(i*2.4)*.15)
			Shapes.beam(body,Vector3(0,.4,0),at,.015,Color("#67854c")); Shapes.sphere(body,.07,at,Color("#e5af66") if i%2==0 else Color("#d5849c"))
	if shape=="banner": Shapes.box(body,Vector3(1.2,1.4,.04),Vector3(.55,1.75,0),Color("#af5947"))
	if kind in ["floor","ceiling","roof","roof_slope","foundation_triangle","bridge","platform","balcony","hatch"]: body.add_to_group("rain_roof")
static func finish(body, tier: String, paint: int) -> void:
	var tint:=Color(Catalog.material(tier).get("color","#855d3b"))
	if paint>0: tint=tint.lerp([Color.WHITE,Color("#a54e3f"),Color("#557b66"),Color("#52758e"),Color("#b89546"),Color("#ddd0aa")][paint],.4)
	var base:=Shapes.material(tint); var trim:=Shapes.material(tint.darkened(.22)); var i:=0
	for child in body.find_children("*","MeshInstance3D",true,false):
		if child is MeshInstance3D:
			var original:Material=child.material_override
			if original is StandardMaterial3D and original.emission_enabled: continue
			if tier!="wood" or paint>0: child.material_override=base if i%4 else trim
			elif original is StandardMaterial3D:
				var key:String=original.albedo_color.to_html()
				if not _materials.has(key): _materials[key]=original
				child.material_override=_materials[key]
			i+=1
	# Distinct masonry courses, reinforced timber straps and metal rivets.
	var kind: String=body.kind
	if kind in ["wall","half_wall"]:
		var height: float=1.5 if kind=="half_wall" else 3.0
		if tier=="wood":
			for x in range(9): Shapes.box(body,Vector3(.025,height,.205),Vector3(-1.6+x*.4,.25+height/2,0),tint.darkened(.22))
		if tier in ["stone","concrete","metal","reinforced_wood","thatch"]:
			var step: float=.5 if tier=="stone" else 1.0
			for j in range(1,ceili(height/step)):
				Shapes.box(body,Vector3(4,.035,.205),Vector3(0,.25+j*step,0),tint.darkened(.2))
			if tier=="stone":
				for y in range(6):
					for x in range(4): Shapes.box(body,Vector3(.025,.47,.21),Vector3(-1.5+x+float(y%2)*.25,.5+y*.5,0),tint.darkened(.15))
			elif tier in ["metal","reinforced_wood"]:
				for x in [-1.7,1.7]: Shapes.box(body,Vector3(.12,height,.23),Vector3(x,.25+height/2,0),Color("#465760"))
	Shapes.consolidate(body)
static func preview_mesh(kind: String, mirrored: bool=false) -> Mesh:
	var key:=kind+str(mirrored)
	if _ghosts.has(key): return _ghosts[key]
	var surface:=SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for box in Catalog.boxes(kind,mirrored):
		var cube:=BoxMesh.new(); cube.size=Vector3(box[0],box[1],box[2])
		var input:=SurfaceTool.new(); input.create_from(cube,0); input.deindex()
		surface.append_from(input.commit(),0,Transform3D(Basis.IDENTITY,Vector3(box[3],box[4],box[5])))
	if Catalog.piece(kind).has("door"):
		var opening:Array=Catalog.piece(kind)["door"]; var cube:=BoxMesh.new()
		cube.size=Vector3(opening[0],.16,opening[1]) if kind=="hatch" else Vector3(opening[0],opening[1],.18)
		var input:=SurfaceTool.new(); input.create_from(cube,0); input.deindex()
		surface.append_from(input.commit(),0,Transform3D(Basis.IDENTITY,Vector3(0,.25 if kind=="hatch" else .25+float(opening[1])/2,0)))
	if Catalog.piece(kind).get("shape","") in ["triangle","ramp","roof_slope"]: surface.append_from(prism_mesh(kind,mirrored),0,Transform3D.IDENTITY)
	_ghosts[key]=surface.commit(); return _ghosts[key]
