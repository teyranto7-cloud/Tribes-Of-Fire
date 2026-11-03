extends RefCounted
## Shared data-selected model builder, with stable style families rather than item branches.
static func build(parent: Node3D, item: Dictionary) -> void:
	var shapes=preload("res://World/Shapes.gd")
	var type:String=item.get("type","materials")
	var color:Color={"wood":Color("#936737"),"tools":Color("#a6b9bc"),"armor":Color("#a4a9ad"),"food":Color("#9baa55"),"electrical":Color("#c18c55"),"mechanical":Color("#969c99")}.get(type,Color("#b39761"))
	var mesh=shapes.sphere(parent,0.18,Vector3.UP*0.2,color);mesh.scale.y=1.1
