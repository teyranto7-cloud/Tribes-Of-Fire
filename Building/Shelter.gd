extends Node3D

const Shapes = preload("res://World/Shapes.gd")

func _ready() -> void:
	var wood := Color("#825937")
	var roof_color := Color("#614639")
	var walls := StaticBody3D.new()
	add_child(walls)
	for x in [-1.9, 1.9]:
		for z in [-1.9, 1.9]:
			Shapes.cylinder(self, 0.13, 2.9, Vector3(x, 1.45, z), wood)
			var post_shape := BoxShape3D.new()
			post_shape.size = Vector3(0.3, 2.9, 0.3)
			Shapes.collider(walls, post_shape, Vector3(x, 1.45, z))
	for side in [-1.0, 1.0]:
		var panel := Shapes.box(self, Vector3(2.55, 0.16, 4.7), Vector3(side * 1.13, 3.17, 0), roof_color)
		panel.rotation.z = -side * 0.32
		Shapes.beam(self, Vector3(side * 2.4, 2.8, -2.3), Vector3(0, 3.57, -2.3), 0.09, wood)
		Shapes.beam(self, Vector3(side * 2.4, 2.8, 2.3), Vector3(0, 3.57, 2.3), 0.09, wood)
	for i in range(7):
		var z := -2.1 + i * 0.7
		for side in [-1.0, 1.0]:
			Shapes.beam(self, Vector3(side * 2.3, 2.86, z), Vector3(0, 3.6, z), 0.035, roof_color.lightened(0.12))
	# The solid roof collision is also the authoritative rain occluder.
	var roof := StaticBody3D.new()
	roof.name = "RainRoof"
	roof.add_to_group("rain_roof")
	add_child(roof)
	for side in [-1.0, 1.0]:
		var roof_shape := BoxShape3D.new()
		roof_shape.size = Vector3(2.55, 0.16, 4.7)
		var panel_collision := Shapes.collider(roof, roof_shape, Vector3(side * 1.13, 3.17, 0))
		panel_collision.rotation.z = -side * 0.32
	for i in range(5):
		var y := 0.25 + i * 0.31
		Shapes.box(self, Vector3(3.7, 0.27, 0.13), Vector3(0, y, 1.95), wood.lightened(i * 0.012))
	var back_shape := BoxShape3D.new()
	back_shape.size = Vector3(3.7, 1.7, 0.18)
	Shapes.collider(walls, back_shape, Vector3(0, 0.85, 1.95))
