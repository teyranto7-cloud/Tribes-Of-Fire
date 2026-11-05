extends Control
## Original, resolution-independent valley illustration behind the main menu.
var _age: float = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var s := size
	for i in range(32):
		draw_rect(Rect2(0, s.y * i / 32, s.x, s.y / 32 + 1), Color("#152d36").lerp(Color("#a79269"), float(i) / 38))
	draw_circle(Vector2(s.x * 0.78, s.y * 0.3), s.y * 0.08, Color("#edce90"))
	for layer in range(4):
		var points := PackedVector2Array([Vector2(0, s.y)])
		for i in range(25):
			var x := float(i) / 24
			var y := 0.54 + layer * 0.1 + sin(x * 13 + layer * 1.8) * 0.065 + sin(x * 29 + layer) * 0.015
			points.append(Vector2(x * s.x, y * s.y))
		points.append(Vector2(s.x, s.y))
		draw_colored_polygon(points, [Color("#576b61"), Color("#3c574d"), Color("#28463d"), Color("#17362e")][layer])
	var river := PackedVector2Array()
	for i in range(18):
		var t := float(i) / 17
		river.append(Vector2(s.x * (0.76 + sin(t * 7.5) * t * 0.1), s.y * (0.65 + t * 0.35)))
	draw_polyline(river, Color("#739898"), maxf(3, s.x * 0.011), true)
	for i in range(18):
		var x := s.x * (0.50 + fposmod(i * 0.131, 0.49))
		var y := s.y * (0.71 + fposmod(i * 0.117, 0.28))
		var h := s.y * (0.04 + fposmod(i * 0.011, 0.07))
		draw_line(Vector2(x, y), Vector2(x, y - h * 0.8), Color("#142c28"), 3)
		for tier in range(3):
			var top := Vector2(x, y - h + tier * h * 0.25)
			draw_colored_polygon(PackedVector2Array([top, top + Vector2(-h * 0.24, h * 0.5), top + Vector2(h * 0.24, h * 0.5)]), Color("#203e31"))
	draw_rect(Rect2(0, 0, s.x * 0.46, s.y), Color(0.02, 0.04, 0.035, 0.6))
