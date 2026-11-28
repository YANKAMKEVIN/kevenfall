class_name DreamShard
extends Node2D
## Éclat de rêve flottant, à ramasser.
var t := randf() * 5.0
func _process(d: float) -> void:
	t += d; queue_redraw()
func collect() -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "scale", Vector2(2.5, 2.5), 0.5)
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
func _draw() -> void:
	var y := sin(t * 2.5) * 6.0
	var s := 1.0 + 0.08 * sin(t * 5.0)
	var pts := PackedVector2Array([Vector2(0, -22) * s, Vector2(12, 0) * s, Vector2(0, 22) * s, Vector2(-12, 0) * s])
	for i in pts.size(): pts[i] = pts[i].rotated(sin(t) * 0.2) + Vector2(0, y)
	draw_colored_polygon(pts, Color(0.55, 0.95, 1.0))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1, 1, 1, 0.9), 2.0)
	draw_line(Vector2(0, -22 + y), Vector2(0, 22 + y), Color(1, 1, 1, 0.6), 1.5)
