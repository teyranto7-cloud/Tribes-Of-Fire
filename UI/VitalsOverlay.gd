extends Control
## Lightweight vector HUD: no extra 3D nodes, textures or per-frame allocations.
var game
var _left: float = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	visible = game != null and game.player != null and game.hud.mode == ""
	_left -= delta
	if visible and _left <= 0: _left = 0.1; queue_redraw()

func _draw() -> void:
	if not visible or game == null or game.player == null: return
	var font := get_theme_default_font()
	var ink := Color("#eee9dc")
	draw_style_box(_panel(), Rect2(0, 0, 280, 134))
	draw_string(font, Vector2(16, 24), game.hud.t("VITALIDADE", "VITALITY"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#b5b9a9"))
	draw_string(font, Vector2(207, 24), game.clock.label(), HORIZONTAL_ALIGNMENT_RIGHT, 56, 13, ink)
	_bar(Vector2(16, 37), game.player.vitals.hp / 100.0, Color("#ce8065"), game.hud.t("Vida", "Health"), game.player.vitals.hp)
	_bar(Vector2(16, 69), game.player.stamina / 100.0, Color("#c7b57a"), game.hud.t("Energia", "Stamina"), int(game.player.stamina))
	if game.survival != null:
		draw_string(font, Vector2(16, 120), "%s %.0f" % [game.hud.t("Fome", "Food"), game.survival.hunger], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#c8b786"))
		draw_string(font, Vector2(113, 120), "%s %.0f" % [game.hud.t("Sede", "Water"), game.survival.thirst], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#9abcc0"))
		if game.exposure != null: draw_string(font, Vector2(218, 120), "%.0f°C" % game.exposure.temperature, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ink)

func _panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color(0.045, 0.07, 0.065, 0.9)
	style.set_corner_radius_all(9); style.border_color = Color("#526154"); style.border_width_left = 2
	return style

func _bar(at: Vector2, ratio: float, tint: Color, title: String, value: int) -> void:
	draw_string(get_theme_default_font(), at + Vector2(0, 10), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8e3d6"))
	draw_string(get_theme_default_font(), at + Vector2(218, 10), str(value), HORIZONTAL_ALIGNMENT_RIGHT, 30, 12, tint)
	draw_rect(Rect2(at + Vector2(0, 16), Vector2(248, 4)), Color("#293b34"))
	draw_rect(Rect2(at + Vector2(0, 16), Vector2(248 * clampf(ratio, 0, 1), 4)), tint)
