extends CanvasLayer
var game
var label: Label
var samples: Array[float] = []
var elapsed: float = 0.0
func configure(value) -> void:
	game = value
	label = Label.new()
	label.position = Vector2(10, 190)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)
func _process(delta: float) -> void:
	if game == null:
		return
	visible = bool(game.graphics.applied["performance"]) and game.session.is_admin(game.session.local_id)
	if not visible or delta <= 0:
		return
	samples.append(delta)
	if samples.size() > 600:
		samples.pop_front()
	elapsed += delta
	if elapsed < 0.5:
		return
	elapsed = 0
	var average := 0.0
	for sample in samples:
		average += sample
	average /= samples.size()
	var sorted := samples.duplicate()
	sorted.sort()
	var slow: float = sorted[mini(sorted.size() - 1, int(sorted.size() * 0.99))]
	label.text = "FPS %d | AVG %.1f | 1%% %.1f | %.2f ms\nRAM %.1f MiB | %s" % [Engine.get_frames_per_second(), 1.0 / average, 1.0 / slow, average * 1000, OS.get_static_memory_usage() / 1048576.0, game.graphics.hardware()["gpu"]]
