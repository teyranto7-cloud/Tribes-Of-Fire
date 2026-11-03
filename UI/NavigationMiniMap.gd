extends Control
## Optional local map; undiscovered cells stay hidden and secret POIs are never drawn.
var game
var texture: ImageTexture
var elapsed: float = 0.0
const Journal = preload("res://Game/Journal.gd")
func _process(delta: float) -> void:
	visible = game.running and game.player != null and game.hud.mode == "" and game.settings_manager.read("accessibility","minimap",false) == true
	if not visible: return
	elapsed -= delta
	if elapsed > 0: return
	elapsed = 0.7
	var cells: Dictionary = game.journal.serialize(game.session.player_key(game.session.local_id))["cells"]
	var image := Image.create(48,48,false,Image.FORMAT_RGB8)
	var at: Vector3 = game.player.position
	for y in range(48):
		for x in range(48):
			var p := Vector2(at.x,at.z) + (Vector2(x,y)-Vector2(24,24))*3
			var explored := cells.has("%d,%d" % [floori(p.x/Journal.CELL_SIZE),floori(p.y/Journal.CELL_SIZE)])
			var tint := Color("#142923")
			if explored: tint = Color("#528e9b") if game.world.terrain_height(p.x,p.y)<game.world.water_level else Color("#6e9256")
			image.set_pixel(x,y,tint)
	texture = ImageTexture.create_from_image(image); queue_redraw()
func _draw() -> void:
	if texture == null: return
	draw_texture_rect(texture,Rect2(Vector2.ZERO,size),false)
	draw_rect(Rect2(Vector2.ZERO,size),Color("#e2bc75"),false,2)
	var center := size*0.5
	draw_circle(center,4,Color("#fff0b0"))
	var direction := Vector2(-sin(game.player.yaw),-cos(game.player.yaw))
	draw_line(center,center+direction*12,Color("#fff0b0"),2)
	draw_string(get_theme_default_font(),Vector2(5,17),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,14)
