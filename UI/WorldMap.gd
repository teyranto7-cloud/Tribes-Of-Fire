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
var coordinates: CheckBox
var selection_label: Label
var _elapsed: float = 0.0

func configure(value, _language: int = 0) -> void:
	game = value
	_build()

func label(pt: String, en: String) -> String:
	return game.hud.t(pt, en)

func _build() -> void:
	profile = game.journal.serialize(game.session.player_key(game.session.local_id))
	var image := Image.create(192, 192, false, Image.FORMAT_RGB8)
	var extent: float = game.world.half_extent()
	for y in range(192):
		for x in range(192):
			var p := Vector2(lerpf(-extent, extent, x / 191.0), lerpf(-extent, extent, y / 191.0))
			var cell := "%d,%d" % [floori(p.x / Journal.CELL_SIZE), floori(p.y / Journal.CELL_SIZE)]
			var color := Color("#1b2928")
			if profile["cells"].has(cell):
				var elevation: float = game.world.terrain_height(p.x, p.y)
				color = Color("#4a8390") if elevation < game.world.water_level else map_colors.get(game.world.biome_at(p.x, p.y), Color("#78935d"))
				if elevation >= game.world.water_level:
					color = color.lightened(clampf(elevation / 130.0, 0, 0.3))
					if fposmod(elevation, 8.0) < 0.7: color = color.darkened(0.18)
					if game.world.sampler.watershed != null and game.world.sampler.path_distance(p.x,p.y)<2.2:color=Color("#bda77a")
			image.set_pixel(x, y, color)
	texture = ImageTexture.create_from_image(image)
	var layout:=HBoxContainer.new();layout.add_theme_constant_override("separation",16);add_child(layout)
	var left:=VBoxContainer.new();left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;layout.add_child(left)
	var aspect:=AspectRatioContainer.new();aspect.ratio=1;aspect.size_flags_horizontal=Control.SIZE_EXPAND_FILL;aspect.size_flags_vertical=Control.SIZE_EXPAND_FILL;left.add_child(aspect)
	var side:=VBoxContainer.new();side.custom_minimum_size.x=240;side.size_flags_horizontal=Control.SIZE_EXPAND_FILL;layout.add_child(side)
	canvas = MapCanvas.new()
	canvas.owner_panel = self
	canvas.custom_minimum_size = Vector2(280, 280)
	canvas.clip_contents = true
	aspect.add_child(canvas)
	var navigation := HBoxContainer.new(); left.add_child(navigation)
	var center := Button.new(); center.text = label("Centrar no jogador", "Center on player")
	center.pressed.connect(func(): canvas.center_player()); navigation.add_child(center)
	var reset := Button.new(); reset.text = label("Mapa inteiro", "Whole map")
	reset.pressed.connect(func(): canvas.zoom = 1.0; canvas.pan = Vector2.ZERO; canvas.queue_redraw()); navigation.add_child(reset)
	coordinates = CheckBox.new(); coordinates.text = label("Coordenadas", "Coordinates")
	coordinates.button_pressed = game.settings_manager.read("accessibility", "map_coordinates", false) == true
	coordinates.toggled.connect(func(value): game.settings_manager.write_sections({"accessibility": {"map_coordinates": value}}); canvas.queue_redraw())
	side.add_child(coordinates)
	selection_label = Label.new(); selection_label.text = label("Roda: zoom • Arraste com botão direito • Clique para marcar", "Wheel: zoom • Right drag: pan • Click to mark")
	selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; add_child(selection_label)
	marker_name = LineEdit.new()
	marker_name.max_length = 40
	marker_name.placeholder_text = label("Nome do marcador", "Marker name")
	side.add_child(marker_name)
	share = CheckBox.new()
	share.text = label("Compartilhar com a tribo", "Share with tribe")
	share.disabled = game.runtime.tribes.tribe_of(game.session.player_key(game.session.local_id)).is_empty()
	side.add_child(share)
	var add := Button.new()
	add.text = label("Adicionar marcador", "Add marker")
	add.pressed.connect(func():
		game.request_command("map_mark", {"position": [selected.x, selected.y], "name": marker_name.text, "color": 0, "shared": share.button_pressed})
		game.hud.show_panel("map"))
	side.add_child(add)
	var ping := Button.new()
	ping.text = label("Enviar ping à tribo e aliados · 20 s", "Ping tribe and allies · 20 s")
	ping.disabled = share.disabled
	ping.tooltip_text = label("Escolha um local descoberto a até 250 m. O ping não revela terreno ou recursos.", "Choose a discovered location within 250 m. Pings reveal no terrain or resources.")
	ping.pressed.connect(func(): game.request_command("team_ping", {"position": [selected.x, selected.y]}))
	side.add_child(ping)
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

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 0.2 and canvas != null:
		_elapsed = 0.0
		canvas.queue_redraw()

class MapCanvas extends Control:
	var owner_panel
	var zoom: float = 1.0
	var pan := Vector2.ZERO
	var selected_set: bool = false

	func world_to_screen(at: Vector2) -> Vector2:
		return (at / (owner_panel.game.world.half_extent() * 2) * zoom + Vector2.ONE * 0.5) * size + pan

	func screen_to_world(at: Vector2) -> Vector2:
		return ((at - pan) / size - Vector2.ONE * 0.5) / zoom * owner_panel.game.world.half_extent() * 2

	func center_player() -> void:
		if owner_panel.game.player == null: return
		var at: Vector3 = owner_panel.game.player.position
		pan = -Vector2(at.x, at.z) / (owner_panel.game.world.half_extent() * 2) * zoom * size
		_limit_pan()
		queue_redraw()

	func _limit_pan() -> void:
		var limit := size * (zoom - 1.0) * 0.5
		pan = pan.clamp(-limit, limit)

	func zoom_at(at: Vector2, factor: float) -> void:
		var before := screen_to_world(at)
		zoom = clampf(zoom * factor, 1.0, 8.0)
		pan += at - world_to_screen(before)
		_limit_pan()
		queue_redraw()

	func _draw() -> void:
		if owner_panel.texture == null: return
		_limit_pan()
		var extent: float = owner_panel.game.world.half_extent()
		draw_texture_rect(owner_panel.texture, Rect2(world_to_screen(Vector2.ONE * -extent), size * zoom), false)
		var body = owner_panel.game.player
		if body != null:
			var center := world_to_screen(Vector2(body.position.x, body.position.z))
			var direction := Vector2(-sin(body.yaw), -cos(body.yaw))
			draw_circle(center, 5, Color("#fff1b7"))
			draw_line(center, center + direction * 15, Color("#fff1b7"), 3, true)
			var spawn := world_to_screen(Vector2(body.respawn_position.x, body.respawn_position.z))
			draw_rect(Rect2(spawn - Vector2(4, 4), Vector2(8, 8)), Color("#b4dca8"), false, 2)
			if owner_panel.coordinates != null and owner_panel.coordinates.button_pressed:
				draw_string(get_theme_default_font(), Vector2(8, 20), "X %.0f  Z %.0f" % [body.position.x, body.position.z], HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
		var identity: String = owner_panel.game.session.player_key(owner_panel.game.session.local_id)
		var pings: Array = owner_panel.game.runtime.team_pings.visible(identity, owner_panel.game.runtime.tribes, owner_panel.game.runtime.channels.blocked) if owner_panel.game.session.is_authority() else owner_panel.game.runtime.ping_view
		for ping in pings:
			var point := world_to_screen(Vector2(ping["position"][0], ping["position"][1]))
			draw_arc(point, 10, 0, TAU, 24, Color("#e9b675"), 2, true)
			draw_line(point - Vector2(0, 15), point + Vector2(0, 15), Color("#e9b675"), 1, true)
		for marker in owner_panel.game.journal.visible_markers(identity, owner_panel.game.runtime.tribes):
			var center := world_to_screen(Vector2(marker["position"][0], marker["position"][1]))
			draw_circle(center, 4, Color("#edb36a"))
			draw_string(get_theme_default_font(), center + Vector2(7, -5), marker["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#fff1b7"))
		var cells:Dictionary=owner_panel.profile["cells"]
		for structure in owner_panel.game.world.structures:
			if structure.kind not in ["bed","chest","totem","raft"]:continue
			var cell:="%d,%d"%[floori(structure.position.x/Journal.CELL_SIZE),floori(structure.position.z/Journal.CELL_SIZE)]
			if not cells.has(cell):continue
			var center:=world_to_screen(Vector2(structure.position.x,structure.position.z))
			draw_rect(Rect2(center-Vector2(3,3),Vector2(6,6)),Color("#d9cc9e"))
		if owner_panel.game.world.sampler.watershed != null:
			for z in owner_panel.game.world.sampler.watershed.crossings:
				var x:float=owner_panel.game.world.sampler.river_x(z)
				if cells.has("%d,%d"%[floori(x/Journal.CELL_SIZE),floori(z/Journal.CELL_SIZE)]):
					var center:=world_to_screen(Vector2(x,z));draw_line(center-Vector2(6,0),center+Vector2(6,0),Color("#eac28b"),3)
		if selected_set:
			var at := world_to_screen(owner_panel.selected)
			draw_arc(at, 8, 0, TAU, 24, Color.WHITE, 2, true)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			pan += event.relative; _limit_pan(); queue_redraw(); accept_event()
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP: zoom_at(event.position, 1.25); accept_event()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom_at(event.position, 0.8); accept_event()
			elif event.button_index == MOUSE_BUTTON_LEFT:
				var extent: float = owner_panel.game.world.half_extent()
				owner_panel.selected = screen_to_world(event.position).clamp(Vector2.ONE * -extent, Vector2.ONE * extent)
				selected_set = true
				owner_panel.selection_label.text = owner_panel.label("Marcador: X %.0f, Z %.0f", "Marker: X %.0f, Z %.0f") % [owner_panel.selected.x, owner_panel.selected.y]
				queue_redraw(); accept_event()
