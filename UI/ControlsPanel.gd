extends VBoxContainer
const ACTIONS := ["forward", "back", "left", "right", "sprint", "jump", "crouch", "dodge", "block", "heavy", "interact", "inventory", "push_to_talk", "chat", "world_map", "rotate_build", "view", "axe", "build", "shelter", "menu", "save", "load"]
var waiting: String = ""
var game
var buttons: Dictionary = {}
var config_path: String = "user://settings.cfg"
func configure(value, _language: int = 0) -> void:
	game = value
	var label := Label.new()
	label.text = tr("Sensitivity")
	add_child(label)
	var sensitivity := HSlider.new()
	sensitivity.min_value = 0.0005
	sensitivity.max_value = 0.01
	sensitivity.step = 0.0001
	sensitivity.value = game.sensitivity
	sensitivity.value_changed.connect(game.set_sensitivity)
	add_child(sensitivity)
	var smooth := CheckBox.new()
	smooth.text = tr("Camera smoothing")
	smooth.button_pressed = game.camera_smoothing
	smooth.toggled.connect(func(v):
		game.camera_smoothing = v
		if game.player != null: game.player.camera_smoothing = v
		game.save_settings())
	add_child(smooth)
	for action in ACTIONS:
		var button := Button.new()
		buttons[action] = button
		button.pressed.connect(func(): waiting = action; button.text = action_name(action) + ": …")
		add_child(button)
	var fov_label:=Label.new();fov_label.text=tr("Field of view");add_child(fov_label)
	var fov:=HSlider.new();fov.min_value=45;fov.max_value=110;fov.step=1
	fov.value=game._config_number(game.settings_manager.read("input","fov",70),70,45,110);add_child(fov)
	fov.value_changed.connect(func(v):
		game.settings_manager.write_sections({"input":{"fov":v}})
		if game.player!=null: game.player.camera.fov=v)
	var invert:=CheckBox.new();invert.text=tr("Invert vertical camera")
	invert.button_pressed=game.settings_manager.read("input","invert_y",false)==true;add_child(invert)
	invert.toggled.connect(func(v):
		game.settings_manager.write_sections({"input":{"invert_y":v}})
		if game.player!=null: game.player.invert_y=v)
	refresh()
func refresh() -> void:
	for action in buttons:
		var events := InputMap.action_get_events(action)
		buttons[action].text = action_name(action) + " : " + (events[0].as_text() if not events.is_empty() else "—")
func action_name(action: String) -> String:
	var text := action.replace("_", " ")
	return tr(text.left(1).to_upper() + text.substr(1))
func _input(event: InputEvent) -> void:
	if waiting == "" or not event.is_pressed() or not (event is InputEventKey or event is InputEventMouseButton):
		return
	if event is InputEventKey and event.echo:
		return
	for action in ACTIONS:
		if action==waiting: continue
		for existing in InputMap.action_get_events(action):
			if event.is_match(existing,true):
				buttons[waiting].text=tr("Key already assigned")+": "+action_name(action)
				get_viewport().set_input_as_handled()
				return
	InputMap.action_erase_events(waiting)
	InputMap.action_add_event(waiting, event)
	var config := ConfigFile.new()
	config.load(config_path)
	config.set_value("bindings", waiting, event)
	preload("res://Settings/ConfigStore.gd").write_sections({"bindings":{waiting:event}},config_path)
	waiting = ""
	get_viewport().set_input_as_handled()
	refresh()
static func load_bindings(path: String = "user://settings.cfg") -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	for action in ACTIONS:
		if not config.has_section_key("bindings", action): continue
		var event: Variant = config.get_value("bindings", action)
		if event is InputEventKey or event is InputEventMouseButton:
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, event)
