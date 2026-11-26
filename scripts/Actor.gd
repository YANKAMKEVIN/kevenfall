class_name Actor
extends Node2D
## Personnage peint (sprite Codex) animé par code : respiration, marche, saut.

var sprite: Sprite2D
var facing := 1          # 1 = droite, -1 = gauche
var native_facing := 1   # sens dans lequel le dessin regarde
var walking := false
var airborne := false
var crouch := false
var t := randf() * 10.0
var base_scale := 0.33
var bob := 0.0

func setup(tex_id: String, height_px: float, native_dir := 1) -> Actor:
	sprite = Sprite2D.new()
	sprite.texture = Game.tex(tex_id)
	native_facing = native_dir
	if sprite.texture:
		base_scale = height_px / sprite.texture.get_height()
		sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0)
	add_child(sprite)
	# ombre au sol
	var sh := Shadow.new(); sh.w = height_px * 0.32; add_child(sh); move_child(sh, 0)
	return self

func _process(delta: float) -> void:
	t += delta
	if not sprite: return
	var sx := base_scale * (1 if facing == native_facing else -1)
	var sy := base_scale
	var rot := 0.0
	var oy := 0.0
	if crouch:
		sy *= 0.78; sx *= 1.06
	elif airborne:
		sy *= 1.06; sx *= 0.95
	elif walking:
		var w := t * 11.0
		oy = -absf(sin(w)) * 7.0
		rot = sin(w) * 0.04
		sy *= 1.0 + absf(sin(w)) * 0.03
	else:
		sy *= 1.0 + sin(t * 2.2) * 0.012
		sx *= 1.0 - sin(t * 2.2) * 0.006
	sprite.scale = Vector2(sx, sy)
	sprite.position.y = oy + bob
	sprite.rotation = rot * facing

class Shadow extends Node2D:
	var w := 40.0
	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			pts.append(Vector2(cos(a) * w, sin(a) * w * 0.18))
		draw_colored_polygon(pts, Color(0, 0, 0.05, 0.45))
