class_name Revelin
extends Node2D
## Révelin : petite créature de rêve qui flotte et fuit le joueur.
var home := Vector2.ZERO
var t := randf() * 10.0
var spr: Sprite2D
var flee := Vector2.ZERO
func _ready() -> void:
	var tx: Texture2D = Game.tex("revelin")
	if tx:
		spr = Sprite2D.new(); spr.texture = tx; spr.scale = Vector2(0.32, 0.32); add_child(spr)
func _process(d: float) -> void:
	t += d
	var ex := get_parent() as Exploration
	if ex.player and ex.player.position.distance_to(position + Vector2(0, 60)) < 90.0:
		flee = (position - ex.player.position + Vector2(0, -60)).normalized() * 260.0
	flee = flee.move_toward(Vector2.ZERO, d * 200.0)
	home += flee * d
	var target := home + Vector2(sin(t * 0.7) * 60.0, sin(t * 1.9) * 18.0)
	var dx := target.x - position.x
	position = position.lerp(target, clampf(d * 2.0, 0, 1))
	if spr:
		spr.flip_h = dx < 0
		spr.scale.y = 0.32 * (0.85 + 0.15 * absf(sin(t * 9.0)))
