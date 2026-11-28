class_name Rain
extends Node2D
## Pluie oblique dessinée en lignes (premier plan).

var drops: Array = []
var size := Vector2(1280, 720)
var count := 220
var alpha := 0.35

func _ready() -> void:
	for i in count:
		drops.append(_new_drop(true))

func _new_drop(anywhere: bool) -> Dictionary:
	var z := randf_range(0.4, 1.0)
	return {"p": Vector2(randf_range(-100, size.x + 200), randf_range(-50, size.y) if anywhere else randf_range(-80, -10)),
		"z": z, "v": lerpf(700.0, 1400.0, z)}

func _process(delta: float) -> void:
	for d in drops:
		d.p += Vector2(-0.28, 1.0) * d.v * delta
		if d.p.y > size.y + 20 or d.p.x < -150:  # la goutte repart d'en haut (sans allouer)
			d.z = randf_range(0.4, 1.0); d.v = lerpf(700.0, 1400.0, d.z)
			d.p = Vector2(randf_range(-100, size.x + 200), randf_range(-80, -10))
	queue_redraw()

func _draw() -> void:
	for d in drops:
		var l: float = 10.0 + 18.0 * d.z
		draw_line(d.p, d.p + Vector2(-0.28, 1.0) * l, Color(0.7, 0.8, 1.0, alpha * d.z), 1.0 + d.z)
