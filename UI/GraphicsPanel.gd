extends VBoxContainer
## Quality is saved immediately. Only display mode/resolution use a safety preview.
var game
var previous: Dictionary = {}
var confirm_left: float = 0.0
var confirm_deadline: int = 0
var confirm_label: Label
var preset_choice: OptionButton
var resolution_choices: Array[Vector2i] = []
func configure(value, _language: int = 0) -> void:
	game = value
	game.graphics.begin_edit()
	build()
func label_text(key: String) -> Label:
	var label := Label.new()
	label.text = tr(key)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	return label
func button(key: String, callback: Callable) -> Button:
	var control := Button.new()
	control.text = tr(key)
	control.pressed.connect(callback)
	add_child(control)
	return control
func option(key: String, choices: Array, selected: int, callback: Callable) -> OptionButton:
	label_text(key)
	var control := OptionButton.new()
	for choice in choices: control.add_item(tr(str(choice)))
	control.select(maxi(0, selected))
	control.item_selected.connect(callback)
	add_child(control)
	return control
func slider(key: String, minimum: float, maximum: float, step: float, current: float, callback: Callable) -> void:
	var label := label_text(key)
	label.text += "  %.2f" % current
	var control := HSlider.new()
	control.min_value = minimum
	control.max_value = maximum
	control.step = step
	control.value = current
	control.value_changed.connect(func(v): label.text = tr(key) + "  %.2f" % v; callback.call(v))
	add_child(control)
func _quality_changed(key: String, value: Variant) -> void:
	var chosen_display := {"resolution": game.graphics.pending["resolution"], "window_mode": game.graphics.pending["window_mode"]}
	if confirm_left > 0:
		_rollback()
		chosen_display = {"resolution": game.graphics.applied["resolution"], "window_mode": game.graphics.applied["window_mode"]}
	game.graphics.begin_edit()
	game.graphics.set_pending(key, value)
	if not game.graphics.apply_to(game.world, game.get_viewport(), game.player):
		game.hud.notify_message(tr("Could not save settings"))
	for field in chosen_display: game.graphics.pending[field] = chosen_display[field]
	if is_instance_valid(preset_choice): preset_choice.select(int(game.graphics.applied["preset"]))
func _preset_selected(index: int) -> void:
	_rollback()
	var chosen_display := {"resolution": game.graphics.pending["resolution"], "window_mode": game.graphics.pending["window_mode"]}
	game.graphics.begin_edit()
	game.graphics.choose_preset(index)
	if not game.graphics.apply_to(game.world, game.get_viewport(), game.player):
		game.hud.notify_message(tr("Could not save settings"))
	for field in chosen_display: game.graphics.pending[field] = chosen_display[field]
	build()
func build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var settings = game.graphics
	label_text("Quality changes are saved immediately.")
	preset_choice = option("Graphics", ["Very Low", "Low", "Medium", "High", "Ultra", "Custom"], int(settings.applied["preset"]), _preset_selected)
	resolution_choices = settings.available_resolutions()
	var names: Array = []
	for size in resolution_choices: names.append("%d × %d" % [size.x, size.y])
	option("Resolution", names, resolution_choices.find(settings.pending["resolution"]), func(i): settings.set_pending("resolution", resolution_choices[i]))
	option("Window mode", ["Windowed", "Fullscreen", "Borderless"], int(settings.pending["window_mode"]), func(i): settings.set_pending("window_mode", i))
	slider("Render scale", 0.5, 1.0, 0.05, float(settings.applied["render_scale"]), func(v): _quality_changed("render_scale", v))
	slider("Interface scale", 0.75, 2.0, 0.05, float(settings.applied["ui_scale"]), func(v): _quality_changed("ui_scale", v))
	for entry in [["Shadows", "shadows", 0, 3, 1], ["Vegetation", "vegetation", 0, 4200, 100], ["View distance", "view_distance", 30, 200, 5], ["Water", "water", 0, 2, 1], ["Particles", "particles", 0, 3, 1], ["Lighting", "lighting", 0, 2, 1], ["Antialiasing", "antialiasing", 0, 3, 1], ["FPS", "fps", 0, 240, 30]]:
		var key: String = entry[1]
		slider(entry[0], entry[2], entry[3], entry[4], float(settings.applied[key]), func(v): _quality_changed(key, v if key == "view_distance" else int(v)))
	for entry in [["VSync", "vsync"], ["Reflections", "reflections"], ["Clouds", "clouds"], ["Rain", "rain"], ["Postprocessing", "postprocess"], ["Show performance", "performance"], ["High contrast", "high_contrast"], ["Reduce flashes", "reduced_flash"], ["Sound captions", "captions"]]:
		var key: String = entry[1]
		var check := CheckBox.new()
		check.text = tr(entry[0])
		check.button_pressed = settings.applied[key]
		check.toggled.connect(func(v): _quality_changed(key, v))
		add_child(check)
	var support: Dictionary = settings.support()
	for entry in [["Ambient occlusion", "ao"], ["Volumetric fog", "volumetric"]]:
		if support[entry[1]]:
			var key: String = entry[1]
			var check := CheckBox.new()
			check.text = tr(entry[0])
			check.button_pressed = settings.applied[key]
			check.toggled.connect(func(v): _quality_changed(key, v))
			add_child(check)
		else: label_text(tr(entry[0]) + ": " + tr("Not available"))
	button("Apply display", _apply)
	button("Cancel display", func(): _rollback(); settings.begin_edit(); build())
	button("Reset defaults", func(): _rollback(); settings.reset_pending(); settings.apply_to(game.world, game.get_viewport(), game.player); build())
	button("Detect automatically", func(): _rollback(); settings.begin_edit(); settings.detect_automatically(); settings.apply_to(game.world, game.get_viewport(), game.player); build())
	confirm_label = label_text("")
	var keep := button("Confirm", _confirm)
	keep.name = "KeepSettings"
	keep.visible = confirm_left > 0
func _apply() -> void:
	if confirm_left > 0: _rollback(); return
	previous = game.graphics.applied.duplicate(true)
	var changed: bool = previous["resolution"] != game.graphics.pending["resolution"] or previous["window_mode"] != game.graphics.pending["window_mode"]
	if not changed: previous.clear(); return
	if not game.graphics.preview(game.world, game.get_viewport(), game.player):
		game.hud.notify_message(tr("Could not save settings"))
		return
	confirm_left = 15.0
	confirm_deadline = Time.get_ticks_msec() + 15000
	get_node("KeepSettings").show()
func _confirm() -> void:
	if confirm_left <= 0: return
	if not game.graphics.persist():
		game.hud.notify_message(tr("Could not save settings"))
		_rollback()
		return
	confirm_left = 0
	previous.clear()
	confirm_label.text = ""
	get_node("KeepSettings").hide()
func _rollback() -> void:
	if confirm_left > 0 and not previous.is_empty():
		for field in ["resolution", "window_mode"]:
			game.graphics.applied[field] = previous[field]
			game.graphics.pending[field] = previous[field]
		if is_instance_valid(game.world) and game.is_inside_tree(): game.graphics.apply_current(game.world, game.get_viewport(), game.player)
	confirm_left = 0
	previous.clear()
func _process(_delta: float) -> void:
	if confirm_left > 0:
		confirm_left = maxf(0.001, float(confirm_deadline - Time.get_ticks_msec()) / 1000.0)
		confirm_label.text = tr("Keep these settings?") + " %ds" % ceili(confirm_left)
		if Time.get_ticks_msec() >= confirm_deadline:
			_rollback()
			build()
func _exit_tree() -> void:
	_rollback()
