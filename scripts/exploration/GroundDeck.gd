class_name GroundDeck
extends Node2D
## Sol d'un niveau d'exploration (tuile peinte répétée) et plateformes flottantes.
var ex: Exploration
func _draw() -> void:
	var tile: Texture2D = Game.tex(ex.cfg.get("tile", "tuile_pont"))
	var h: float = ex.cfg.get("tile_h", 300.0)
	var top: float = ex.cfg.get("tile_top", 0.0)
	for s in ex.segments:
		var x0: float = s[0]; var x1: float = s[1]
		if tile:
			var sc := h / tile.get_height()
			var w := tile.get_width() * sc
			var y := ex.GROUND_Y - h * top
			var x := x0
			while x < x1:
				var seg_w := minf(w, x1 - x)
				draw_texture_rect_region(tile, Rect2(x, y, seg_w, h), Rect2(0, 0, seg_w / sc, tile.get_height()))
				x += w
		else:
			draw_rect(Rect2(x0, ex.GROUND_Y, x1 - x0, 46), Color(0.55, 0.52, 0.62))
	for p in ex.platforms:
		_platform(p)

func _platform(p: Rect2) -> void:
	var c := Color(0.62, 0.58, 0.7)
	var pts := PackedVector2Array([p.position + Vector2(-6, 0), Vector2(p.end.x + 6, p.position.y),
		Vector2(p.end.x - 6, p.position.y + 20), Vector2(p.position.x + p.size.x * 0.6, p.position.y + 44),
		Vector2(p.position.x + 10, p.position.y + 22)])
	draw_colored_polygon(pts, Color(0.32, 0.28, 0.42))
	draw_rect(Rect2(p.position + Vector2(-6, 0), Vector2(p.size.x + 12, 7)), c)
	draw_line(p.position + Vector2(8, 3), Vector2(p.end.x - 8, p.position.y + 3), Color(1, 0.83, 0.35, 0.7), 2.0)
