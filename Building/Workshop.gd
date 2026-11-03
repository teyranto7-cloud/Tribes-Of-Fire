extends StaticBody3D
const Shapes = preload("res://World/Shapes.gd")
var machine: Dictionary = preload("res://Building/Factory.gd").empty()
var _wheel: Node3D
var kind: String = "workbench"
var owner_key: String = ""
func setup(type: String, at: Vector3, key: String) -> void:
	kind = type
	owner_key = key
	position = at
	add_to_group(type)
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.7, 1.2, 1.0)
	Shapes.collider(self, shape, Vector3(0, 0.6, 0))
	if kind in ["workbench","sawmill","loom","crusher"]:
		Shapes.box(self, Vector3(1.7, 0.14, 1.0), Vector3(0, 1.1, 0), Color("#785336"))
		for x in [-0.65, 0.65]:
			for z in [-0.35, 0.35]:
				Shapes.cylinder(self, 0.09, 1.0, Vector3(x, 0.5, z), Color("#654b32"))
		Shapes.cylinder(self, 0.08, 0.5, Vector3(0.3, 1.25, 0), Color("#9e9c84"))
	else:
		for i in range(10):
			var angle := i / 10.0 * TAU
			var stone := Shapes.sphere(self, 0.27, Vector3(sin(angle) * 0.55, 0.32, cos(angle) * 0.45), Color("#70736a"))
			stone.scale.y = 1.8
		Shapes.sphere(self, 0.3, Vector3(0, 0.25, 0), Color("#e88132"), 1.5)
		var light := OmniLight3D.new()
		light.position.y = 0.6
		light.omni_range = 4
		light.light_color = Color("#ffc67b")
		add_child(light)

func _process(delta: float) -> void:
	if kind not in ["sawmill","loom","crusher"]:return
	if _wheel==null:
		_wheel=Node3D.new();_wheel.position=Vector3(-0.5,1.35,0);add_child(_wheel)
		var gear:=Shapes.cylinder(_wheel,0.32,0.10,Vector3.ZERO,Color("#b59b68"));gear.rotation.x=PI/2
		for i in range(8):
			var a:=float(i)*TAU/8
			Shapes.box(_wheel,Vector3(0.09,0.09,0.14),Vector3(cos(a)*0.32,sin(a)*0.32,0),Color("#71684f"))
		var title:=Label3D.new();title.text=preload("res://Items/Catalog.gd").display_name(kind);title.position.y=2.0
		title.billboard=BaseMaterial3D.BILLBOARD_ENABLED;title.font_size=26;title.pixel_size=0.007;title.visibility_range_end=15;add_child(title)
	if preload("res://Building/Factory.gd").RECIPES[kind]["input"].keys().all(func(item):return int(machine["input"].get(item,0))>=preload("res://Building/Factory.gd").RECIPES[kind]["input"][item]):_wheel.rotation.z+=delta*1.8
