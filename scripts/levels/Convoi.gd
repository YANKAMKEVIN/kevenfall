extends Exploration
## Chapitre 2 : le convoi. De nuit, sur le dos de l'Oiseau, le Gamin tente de s'évader.
## Infiltration : éviter la lumière des lanternes des gardes, se cacher derrière les caisses (↓).

const HIDES := [700.0, 1130.0, 1560.0, 2330.0, 2780.0, 3260.0]
const CHECKPOINTS := [220.0, 1560.0, 2330.0]

var guards: Array = []
var caught := 0
var checkpoint := 220.0
var ending := false
var soldate: Actor

func _config() -> Dictionary:
	return {
		"chapter": ["ACTE I  ·  CHAPITRE 2", "Le convoi"],
		"level_w": 3900.0,
		"segments": [[-200.0, 4100.0]],
		"platforms": [Rect2(1760, 440, 120, 22), Rect2(1900, 360, 140, 22), Rect2(2060, 440, 120, 22)],
		"far": "fond_convoi", "far_y": -70.0, "tile": "tuile_plume", "tile_h": 260.0,
		"start_x": 220.0, "rain": 0.08, "flash_every": 2.5, "flash_power": 0.4,
		"tint": Color(0.55, 0.62, 0.9), "fog": 0.3, "fog_col": Color(0.3, 0.4, 0.8),
		"speed_mul": 0.85,
		"hint": "← →  marcher     Espace  sauter     ↓  se cacher derrière les caisses     Échap  pause",
		"props": [["camp_chariot", 120.0, 250.0], ["camp_feu", 3560.0, 92.0]],
		"glows": [[Vector2(3560, GROUND_Y - 25), 170.0, Color(1.0, 0.55, 0.2, 0.55)]],
	}

func _setup() -> void:
	for x in HIDES:
		_prop("caisses", x, 135.0, 4, 6.0)
	_add_guard(820.0, 1260.0, 75.0)
	_add_guard(1960.0, 1960.0, 0.0, 2.6)     # garde immobile qui se retourne
	_add_guard(2480.0, 3080.0, 95.0)
	_add_guard(3150.0, 3420.0, 120.0)
	soldate = Actor.new().setup("sprite_soldate", 175, 1)
	soldate.position = Vector2(3620, GROUND_Y); soldate.facing = -1; soldate.z_index = 2
	add_child(soldate)

func _add_guard(a: float, b: float, speed: float, turn_every := 0.0) -> void:
	var g := Actor.new().setup("sprite_garde", 165, -1)
	g.position = Vector2(a, GROUND_Y); g.facing = 1; g.z_index = 2
	add_child(g)
	guards.append({"actor": g, "a": a, "b": b, "speed": speed, "wait": 0.0, "dir": 1, "turn": turn_every, "turn_t": turn_every, "alert": 0.0, "mark": _mark()})

func _mark() -> Label:
	var l := Game.label("", 40, Game.GOLD, Game.font_title, 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.size = Vector2(60, 50)
	l.z_index = 10; add_child(l)
	return l

func _start() -> void:
	await say([
		["gamin", "Ils m'ont mis dans une cage... Mais le loquet est rouillé. Si je pousse un peu..."],
		["gamin", "Voilà ! Il faut juste éviter la lumière des lanternes. Les caisses me cacheront si je m'accroupis."],
	])
	toast("Reste hors de la lumière des lanternes.  ↓ derrière une caisse pour te cacher.", Game.CYAN)

func _hidden() -> bool:
	if not crouching: return false
	for x in HIDES:
		if absf(player.position.x - x) < 55.0: return true
	return false

func _tick(delta: float) -> void:
	for cp in CHECKPOINTS:
		if player.position.x > cp + 20.0 and cp > checkpoint:
			checkpoint = cp
	for g in guards:
		var a: Actor = g.actor
		if g.speed > 0.0:
			if g.wait > 0.0:
				g.wait -= delta; a.walking = false
			else:
				a.walking = true
				a.position.x += g.dir * g.speed * delta
				if (g.dir > 0 and a.position.x >= g.b) or (g.dir < 0 and a.position.x <= g.a):
					a.position.x = clampf(a.position.x, g.a, g.b)
					g.dir = -g.dir; g.wait = 1.6
			a.facing = g.dir
		else:
			g.turn_t -= delta
			if g.turn_t <= 0.0:
				g.turn_t = g.turn; a.facing = -a.facing
		# détection
		var dx: float = (player.position.x - a.position.x) * a.facing
		var high := player.position.y < GROUND_Y - 130.0
		var seen := dx > -10.0 and dx < 300.0 and not high and not _hidden()
		g.alert = clampf(g.alert + (2.2 if seen else -1.5) * delta, 0.0, 1.0)
		var m: Label = g.mark
		m.position = a.position + Vector2(-30, -230)
		m.text = "!" if g.alert >= 1.0 else ("?" if g.alert > 0.05 else "")
		m.add_theme_color_override("font_color", Color("ff6b5e") if g.alert >= 1.0 else Game.GOLD)
		if g.alert >= 1.0:
			_caught(g)
			return
	if not ending and player.position.x > 3420.0:
		ending = true
		_end_scene()

func _extra_glows(gl: GlowLayer, tt: float) -> void:
	for g in guards:
		var a: Actor = g.actor
		var lamp: Vector2 = a.position + Vector2(a.facing * 55.0, -95.0)
		var k: float = 0.85 + 0.15 * sin(tt * 11.0 + a.position.x)
		Game.draw_glow(gl, lamp, 55.0 * k, Color(1.0, 0.8, 0.4, 0.7))
		var far_x: float = a.position.x + a.facing * 300.0
		var pts := PackedVector2Array([lamp, Vector2(far_x, GROUND_Y - 150.0), Vector2(far_x, GROUND_Y + 4.0), Vector2(a.position.x + a.facing * 30.0, GROUND_Y + 4.0)])
		var c := Color(1.0, 0.8, 0.35, 0.3 + 0.25 * g.alert)
		if g.alert > 0.05: c = c.lerp(Color(1.0, 0.35, 0.25, 0.5), g.alert)
		var c0 := Color(c, 0.0)
		gl.draw_polygon(pts, PackedColorArray([c, c0, c0, Color(c, c.a * 0.5)]))

func _caught(g: Dictionary) -> void:
	busy = true; vel = Vector2.ZERO; player.walking = false
	Game.sfx("cancel", 0.0, 0.6); Game.sfx("stone", -6.0, 1.5)
	main.flash(Color(1, 0.3, 0.2, 0.35), 0.4)
	await wait(0.6)
	var a: Actor = g.actor
	# la Soldate surgit derrière le Gamin
	var s := Actor.new().setup("sprite_soldate", 175, 1)
	s.position = player.position + Vector2(-player.facing * 110.0, 0); s.facing = player.facing; s.z_index = 2
	s.modulate.a = 0.0; add_child(s)
	create_tween().tween_property(s, "modulate:a", 1.0, 0.35)
	await wait(0.4)
	player.facing = -player.facing
	caught += 1
	var lines := []
	match caught:
		1: lines = [
			["garde", "Halte ! Le porteur s'échappe !"],
			["soldate", "Baisse ta lanterne, soldat. Je m'en occupe."],
			["gamin", "Tu m'as suivi depuis le début ?!"],
			["soldate", "Je suis toujours là où tu ne regardes pas. Première tentative... pas mauvaise."],
		]
		2: lines = [
			["soldate", "Encore toi."],
			["gamin", "Pourquoi tu ne m'enchaînes pas pour de bon ? Tu pourrais."],
			["soldate", "Je pourrais. Mais un porteur qui a peur, ça se brise. Et l'Empire a besoin de toi entier."],
			["gamin", "... C'est censé me rassurer ?"],
		]
		3: lines = [
			["soldate", "Tu es têtu."],
			["gamin", "Mamé dit que c'est ma meilleure qualité."],
			["soldate", "Ta Mamé a raison. C'est aussi ce qui finira par te faire tuer. Observe leurs rondes avant de bouger."],
		]
		_:
			lines = [[["soldate", "On recommence ? Les gardes tournent toujours dans le même sens. Regarde avant de courir."]],
				[["soldate", "Accroupis-toi derrière les caisses quand la lumière approche. ... Pourquoi je t'aide, moi ?"]],
				[["soldate", "Pas cette fois non plus, gamin."]]][caught % 3]
	await say(lines)
	busy = true
	main.flash(Color(0, 0, 0, 1), 0.8)
	await wait(0.2)
	s.queue_free()
	player.position = Vector2(checkpoint, GROUND_Y); vel = Vector2.ZERO; player.facing = 1
	for gg in guards:
		gg.alert = 0.0
		gg.actor.position.x = gg.a
		gg.dir = 1; gg.wait = 1.0
	cam.reset_smoothing()
	busy = false

func _end_scene() -> void:
	busy = true; vel = Vector2.ZERO; player.walking = false
	await walk_to(player, 3500.0, 160.0)
	player.facing = 1
	await say([
		["soldate", "Belle tentative. La meilleure, même."],
		["gamin", "Quoi ?! Comment tu savais que je passerais par là ?"],
		["soldate", "Parce que c'est par là que je serais passée. À ton âge."],
		["gamin", "Toi aussi, tu t'es enfuie de quelque part ?"],
		["soldate", "..."],
		["soldate", "Assieds-toi près du feu. Demain, on traverse le pont vers la Tortue."],
		["gamin", "Et si je refuse ?"],
		["soldate", "Alors tu auras froid. Le feu, lui, ne refuse personne."],
	])
	busy = true
	await title_cards(["Le lendemain soir, le convoi fit halte sur le Pont de l'Oiseau."])
	main.goto("explore", {"level": "Pont"})
