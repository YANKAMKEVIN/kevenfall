class_name GlowLayer
extends Node2D
## Halos additifs d'un niveau d'exploration (éclats, révelins, joueur, halos du chapitre).
const NONE: Array = []  # valeur par défaut partagée : pas de tableau neuf à chaque image
var ex: Exploration
func _process(_d: float) -> void: queue_redraw()
func _draw() -> void:
	var tt := Time.get_ticks_msec() / 1000.0
	var fl := 0.85 + 0.15 * sin(tt * 13.0) * sin(tt * 7.3)
	for g in ex.cfg.get("glows", NONE):
		Game.draw_glow(self, g[0], g[1] * fl, g[2])
	for sd in ex.cfg.get("shards", NONE):
		if not Game.shards_taken.has(sd.id):
			Game.draw_glow(self, sd.pos, 60 + 8 * sin(tt * 3.0), Color(0.37, 0.9, 1.0, 0.5))
	for r in ex.revelins:
		Game.draw_glow(self, r.position, 34, Color(0.5, 0.95, 1.0, 0.35))
	if ex.player:
		Game.draw_glow(self, ex.player.position + Vector2(18, -70), 40 + 10 * sin(tt * 9.0), Color(1.0, 0.85, 0.35, 0.25 if ex.can_zap else 0.12))
	ex._extra_glows(self, tt)
