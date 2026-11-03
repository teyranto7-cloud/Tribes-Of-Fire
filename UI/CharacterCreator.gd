extends VBoxContainer
const Appearance = preload("res://Character/Appearance.gd")
var game
var data: Dictionary = Appearance.DEFAULT.duplicate(true)
var model
var camera: Camera3D
var stage: Node3D
var yaw: float = 0.0
var distance: float = 3.4
var name_input: LineEdit
var error: Label
func configure(value, _language: int = 0) -> void:
	game = value
	if game.player != null:
		data = game.player.appearance.duplicate(true)
	build()
func label_text(text: String) -> Label:
	var label := Label.new()
	label.text = tr(text)
	add_child(label)
	return label
func slider(key: String, label: String, low: float, high: float) -> void:
	label_text(label)
	var control := HSlider.new()
	control.min_value = low
	control.max_value = high
	control.step = 0.01
	control.value = data[key]
	control.value_changed.connect(func(v): data[key] = v; refresh())
	add_child(control)
func option(key: String, title: String, options: Array) -> void:
	label_text(title)
	var control := OptionButton.new()
	for value in options:
		control.add_item(tr(str(value)))
	control.select(int(data[key]))
	control.item_selected.connect(func(i): data[key] = i; refresh())
	add_child(control)
func button(text: String, callback: Callable) -> void:
	var b := Button.new()
	b.text = tr(text)
	b.pressed.connect(callback)
	add_child(b)
func build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var container := SubViewportContainer.new()
	container.custom_minimum_size = Vector2(350, 300)
	container.stretch = true
	add_child(container)
	var view := SubViewport.new()
	view.size = Vector2i(480, 360)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(view)
	stage = Node3D.new()
	view.add_child(stage)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("#213e3b")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("#c3cdb5")
	settings.ambient_light_energy = 0.55
	environment.environment = settings
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -30, 0)
	light.light_color = Color("#ffe5bf")
	stage.add_child(light)
	var Shapes = preload("res://World/Shapes.gd")
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 1.6
	floor_mesh.bottom_radius = 1.7
	floor_mesh.height = 0.12
	Shapes.mesh(stage, floor_mesh, Vector3(0, -0.06, 0), Color("#536447"))
	for i in range(5):
		Shapes.cylinder(stage, 0.16, 3.5, Vector3(-2 + i, 1.3, 2.5), Color("#4c4d34"))
		Shapes.sphere(stage, 1.0, Vector3(-2 + i, 3.1, 2.5), Color("#355742"))
	model = preload("res://Player/Player.gd").new()
	model.authoritative = false
	model.local_control = false
	stage.add_child(model)
	model.collision_layer = 0
	model.collision_mask = 0
	model.label.hide()
	model.set_appearance(data, true)
	camera = Camera3D.new()
	camera.fov = 35
	stage.add_child(camera)
	camera.current = true
	slider("height", "Height", 1.35, 1.65)
	option("body", "Body", ["A", "B"])
	slider("volume", "Body volume", 0.85, 1.15)
	slider("shoulders", "Shoulders", 0.9, 1.15)
	option("skin", "Skin", ["1", "2", "3", "4", "5", "6"])
	option("eyes", "Eyes", ["1", "2", "3"])
	slider("eye_size", "Eye size", 0.8, 1.2)
	slider("eye_spacing", "Eye spacing", 0.85, 1.15)
	option("eye_color", "Eye color", ["1", "2", "3", "4", "5", "6", "7"])
	option("hair", "Hair", ["1", "2", "3", "4", "5", "6", "7", "8", "9"])
	option("hair_color", "Hair color", ["1", "2", "3", "4", "5", "6", "7"])
	option("beard", "Beard", ["0", "1", "2", "3", "4", "5"])
	for key in ["face", "nose", "mouth", "ears"]:
		slider(key, key.capitalize(), 0.85, 1.15)
	option("clothing", "Clothing", ["1", "2", "3", "4", "5", "6"])
	var rotate := HSlider.new()
	rotate.min_value = -PI
	rotate.max_value = PI
	rotate.value_changed.connect(func(v): yaw = v)
	label_text("Rotate")
	add_child(rotate)
	var zoom := HSlider.new()
	zoom.min_value = 2.1
	zoom.max_value = 5
	zoom.value = distance
	zoom.value_changed.connect(func(v): distance = v)
	label_text("Zoom")
	add_child(zoom)
	label_text("Name")
	name_input = LineEdit.new()
	name_input.text = data["name"]
	name_input.max_length = 24
	name_input.text_changed.connect(func(v): data["name"] = v)
	add_child(name_input)
	error = label_text("")
	button("Randomize", func():
		for key in ["skin", "eye_color", "hair_color"]:
			data[key] = randi_range(0, 5)
		data["hair"] = randi_range(0, 8)
		data["height"] = randf_range(1.35, 1.65)
		build())
	button("Reset defaults", func(): data = Appearance.DEFAULT.duplicate(true); build())
	button("Confirm", func():
		if Appearance.valid(data):
			game.request_command("appearance", data)
		else:
			error.text = tr("Action unavailable"))
	# Keep the live model on screen while the user scrolls customization controls.
	var fields := get_children().filter(func(child): return child != container)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 190
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(form)
	for field in fields:
		field.reparent(form, false)
func refresh() -> void:
	if is_instance_valid(model):
		model.set_appearance(data, true)
func _process(_delta: float) -> void:
	if camera != null and is_instance_valid(camera):
		camera.position = Vector3(sin(yaw) * distance, 1.2, -cos(yaw) * distance)
		camera.look_at(Vector3(0, 0.8, 0))
