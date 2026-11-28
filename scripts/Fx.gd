class_name Fx
extends Node2D
## Effets dessinés : éclairs, étincelles, onde de choc, rochers, halos.
var items: Array = []
var _was_empty := true
func _process(d: float) -> void:
	if items.is_empty():
		if not _was_empty:  # un dernier redessin pour effacer les effets finis
			_was_empty = true; queue_redraw()
		return
	_was_empty = false
	for i in range(items.size() - 1, -1, -1):  # retrait sur place : pas de nouveau tableau par image
		var it: Dictionary = items[i]
		it.t += d
		if it.t >= it.life:
			items.remove_at(i); continue
		if it.has("parts"):
			for p in it.parts:
				p.v.y += p.get("g", 600.0) * d
				p.p += p.v * d
	queue_redraw()
func bolt(a: Vector2, b: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	var n := 12
	for i in n + 1:
		var k := float(i) / n
		var p := a.lerp(b, k)
		if i > 0 and i < n: p += Vector2(randf_range(-28, 28), randf_range(-8, 8))
		pts.append(p)
	items.append({"kind": "bolt", "pts": pts, "col": col, "t": 0.0, "life": 0.35})
func sparks(p: Vector2, col: Color, n: int) -> void:
	var parts := []
	for i in n:
		var a := randf() * TAU
		parts.append({"p": p, "v": Vector2(cos(a), sin(a)) * randf_range(150, 520), "g": 500.0})
	items.append({"kind": "sparks", "parts": parts, "col": col, "t": 0.0, "life": 0.7})
func ring(p: Vector2, col: Color, r: float, life: float) -> void:
	items.append({"kind": "ring", "p": p, "col": col, "r": r, "t": 0.0, "life": life})
func burst(p: Vector2, col: Color, r: float) -> void:
	items.append({"kind": "glow", "p": p, "col": col, "r": r, "t": 0.0, "life": 0.6})
func slash(p: Vector2, right: bool) -> void:
	items.append({"kind": "slash", "p": p, "dir": 1.0 if right else -1.0, "t": 0.0, "life": 0.25})
func shockwave(p: Vector2) -> void:
	items.append({"kind": "shock", "p": p, "t": 0.0, "life": 0.8})
func wave(a: Vector2, b: Vector2) -> void:
	items.append({"kind": "wave", "a": a, "b": b, "t": 0.0, "life": 0.6})
func rocks(p: Vector2) -> void:
	var parts := []
	for i in 7:
		parts.append({"p": p + Vector2(randf_range(-70, 70), -randf_range(420, 620)), "v": Vector2(0, randf_range(300, 500)), "g": 1800.0, "r": randf_range(10, 22)})
	items.append({"kind": "rocks", "parts": parts, "t": 0.0, "life": 0.75})
func _draw() -> void:
	for it in items:
		var k: float = it.t / it.life
		match it.kind:
			"bolt":
				var a := 1.0 - k
				draw_polyline(it.pts, Color(it.col, a * 0.5), 14.0)
				draw_polyline(it.pts, Color(it.col, a), 5.0)
				draw_polyline(it.pts, Color(1, 1, 1, a), 2.0)
			"sparks":
				for p in it.parts:
					draw_line(p.p, p.p - p.v * 0.03, Color(it.col, 1.0 - k), 3.0)
			"ring":
				draw_arc(it.p, it.r * (0.3 + k), 0, TAU, 48, Color(it.col, 1.0 - k), 6.0 * (1.0 - k) + 1.0)
			"glow":
				Game.draw_glow(self, it.p, it.r * (0.6 + 0.6 * k), Color(it.col, it.col.a * (1.0 - k)))
			"slash":
				var d: float = it.dir
				draw_arc(it.p, 80.0, -1.2 * d + PI * (0.0 if d > 0 else 1.0), 1.2 * d + PI * (0.0 if d > 0 else 1.0), 24, Color(1, 1, 1, 1.0 - k), 8.0 * (1.0 - k) + 1.0)
			"shock":
				var w := k * 1100.0
				for s in [1.0]:
					draw_arc(it.p, w, -PI, 0, 64, Color(1.0, 0.8, 0.4, (1.0 - k) * 0.9), 14.0)
					draw_arc(it.p, w * 0.9, -PI, 0, 64, Color(0.4, 0.9, 1.0, (1.0 - k) * 0.6), 6.0)
				draw_rect(Rect2(it.p.x, it.p.y - 6, w, 12), Color(1.0, 0.85, 0.5, (1.0 - k) * 0.6))
			"wave":
				var pts := PackedVector2Array()
				for i in 20:
					var q := float(i) / 19.0
					if q > k * 1.4: break
					pts.append(it.a.lerp(it.b, q) + Vector2(0, sin(q * 12.0 + it.t * 20.0) * 18.0))
				if pts.size() > 1:
					draw_polyline(pts, Color(0.7, 0.55, 1.0, 1.0 - k), 10.0)
					draw_polyline(pts, Color(0.5, 0.95, 1.0, 1.0 - k), 3.0)
			"rocks":
				for p in it.parts:
					var r: float = p.r
					var poly := PackedVector2Array([p.p + Vector2(-r, 0), p.p + Vector2(-r * 0.4, -r), p.p + Vector2(r * 0.7, -r * 0.7), p.p + Vector2(r, r * 0.3), p.p + Vector2(0, r)])
					draw_colored_polygon(poly, Color(0.45, 0.42, 0.38, 1.0 - k * 0.5))
