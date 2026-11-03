extends VBoxContainer
## The map is sampled from the actual generated terrain and masked by exploration.
const Journal = preload("res://Game/Journal.gd")
var game
var canvas
var marker_name: LineEdit
var share: CheckBox
var selected := Vector2.ZERO
var map_colors := {"plains": Color("#78935d"), "forest": Color("#335e42"), "woodland": Color("#52774c"), "marsh": Color("#52796c"), "mountains": Color("#89837a"), "tundra": Color("#d3d9cf"), "beach": Color("#d0be87"), "desert": Color("#b99b66"), "volcanic": Color("#6b5551")}
var texture: ImageTexture
var profile: Dictionary = {}

func configure(value, _language: int = 0) -> void:
	game = value
	_build()

func label(pt: String, en: String) -> String:
	return game.hud.t(pt, en)

func _build() -> void:
	profile = game.journal.serialize(game.session.player_key(game.session.local_id))
	var image := Image.create(96, 96, false, Image.FORMAT_RGB8)
	var extent: float = game.world.half_extent()
	for y in range(96):
		for x in range(96):
			var p := Vector2(lerpf(-extent, extent, x / 95.0), lerpf(-extent, extent, y / 95.0))
			var cell := "%d,%d" % [floori(p.x / Journal.CELL_SIZE), floori(p.y / Journal.CELL_SIZE)]
			var color := Color("#1b2928")
			if profile["cells"].has(cell):
				color = Color("#4a8390") if game.world.terrain_height(p.x, p.y) < game.world.water_level else map_colors.get(game.world.biome_at(p.x, p.y), Color("#78935d"))
			image.set_pixel(x, y, color)
	texture = ImageTexture.create_from_image(image)
	canvas = MapCanvas.new()
	canvas.owner_panel = self
	canvas.custom_minimum_size = Vector2(280, 280)
	add_child(canvas)
	marker_name = LineEdit.new()
	marker_name.max_length = 40
	marker_name.placeholder_text = label("Nome do marcador", "Marker name")
	add_child(marker_name)
	share = CheckBox.new()
	share.text = label("Compartilhar com a tribo", "Share with tribe")
	share.disabled = game.runtime.tribes.tribe_of(game.session.player_key(game.session.local_id)).is_empty()
	add_child(share)
	var add := Button.new()
	add.text = label("Adicionar marcador", "Add marker")
	add.pressed.connect(func():
		game.request_command("map_mark", {"position": [selected.x, selected.y], "name": marker_name.text, "color": 0, "shared": share.button_pressed})
		game.hud.show_panel("map"))
	add_child(add)
	for marker in profile["markers"]:
		var remove := Button.new()
		remove.text = label("Remover: ", "Remove: ") + marker["name"]
		remove.pressed.connect(func():
			game.request_command("map_remove", {"id": marker["id"]})
			game.hud.show_panel("map"))
		add_child(remove)
	var progress := Label.new()
	progress.text = label("Descobertas: %d • Conquistas: %d", "Discovered: %d • Achievements: %d") % [profile["cells"].size(), profile["achievements"].size()]
	add_child(progress)

class MapCanvas extends Control:
	var owner_panel
	func _draw() -> void:
		if owner_panel.texture == null: return
		draw_texture_rect(owner_panel.texture, Rect2(Vector2.ZERO, size), false)
		var extent: float = owner_panel.game.world.half_extent()
		var body = owner_panel.game.player
		if body != null:
			var center := (Vector2(body.position.x, body.position.z) / (extent * 2) + Vector2.ONE * 0.5) * size
			draw_circle(center, 4, Color("#fff1b7"))
		var identity: String = owner_panel.game.session.player_key(owner_panel.game.session.local_id)
		for marker in owner_panel.game.journal.visible_markers(identity, owner_panel.game.runtime.tribes):
			var center := (Vector2(marker["position"][0], marker["position"][1]) / (extent * 2) + Vector2.ONE * 0.5) * size
			draw_circle(center, 3, Color("#edb36a"))
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			owner_panel.selected = (event.position / size - Vector2.ONE * 0.5) * owner_panel.game.world.half_extent() * 2
			accept_event()
