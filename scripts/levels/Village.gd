extends Exploration
## Chapitre 1 : le village des Plumes, sur l'aile de l'Oiseau d'Orage.
## Le Gamin allume les paratonnerres pour la fête de l'Orage... et la foreuse arrive.

const RODS := [1500.0, 2760.0, 4180.0]
var rod_nodes: Array = []
var swarm: Array = []
var swarm_x := 3420.0
var foreuse: Sprite2D
var finale := false

func _config() -> Dictionary:
	return {
		"chapter": ["ACTE I  ·  CHAPITRE 1", "Le village des Plumes"],
		"level_w": 4600.0,
		"segments": [[-200.0, 1900.0], [2070.0, 3020.0], [3170.0, 4800.0]],
		"platforms": [Rect2(2250, 450, 120, 22), Rect2(2400, 365, 120, 22), Rect2(3560, 450, 120, 22), Rect2(3700, 370, 120, 22)],
		"far": "fond_village", "far_y": -60.0, "tile": "tuile_plume", "tile_h": 260.0,
		"start_x": 330.0, "revelins": 12, "rain": 0.12, "flash_every": 1.6, "flash_power": 0.6,
		"tint": Color(0.9, 0.86, 1.0), "fog": 0.25, "fog_col": Color(0.6, 0.45, 0.8),
		"hint": "← →  marcher     Espace  sauter     E  parler     Échap  pause",
		"props": [["village_maison", 180.0, 260.0], ["village_poteau", 520.0, 240.0], ["village_etendoir", 980.0, 130.0],
			["village_maison", 1180.0, 230.0], ["village_poteau", 1760.0, 240.0], ["village_maison", 2620.0, 240.0],
			["village_etendoir", 3300.0, 130.0], ["village_poteau", 3960.0, 240.0], ["village_maison", 4420.0, 250.0]],
		"npcs": [
			{"id": "sauge", "tex": "sprite_ancienne", "h": 150.0, "x": 700.0, "face": -1},
		],
		"shards": [
			{"id": "v1", "pos": Vector2(2460, 310), "text": "Il y a longtemps, je me suis endormi en plein vol. Je rêve depuis. Et dans mon rêve, de petits êtres ont bâti leurs nids sur mes plumes."},
			{"id": "v2", "pos": Vector2(3760, 315), "text": "Quand je rêve de colère, naissent les Cauchemerles. Quand je rêve de joie... naît la Foudre."},
		],
	}

func _setup() -> void:
	for x in RODS:
		var r := _prop("village_puits", x, 200.0, 1)
		rod_nodes.append(r)
	if not Game.flags.get("swarm_done", false):
		for i in 3:
			var c := _prop("sprite_cauchemerle", swarm_x + i * 70.0, 70.0 + i * 8.0, 3)
			c.flip_h = false
			swarm.append(c)
	if args.get("after_battle", false):
		cfg["start_x"] = swarm_x - 60.0
	foreuse = _prop("foreuse", 4300.0, 420.0, 0)
	foreuse.position.y = -500
	can_zap = Game.flags.get("sauge_talk", false)
	_update_hint()

func _update_hint() -> void:
	var h := "← →  marcher     Espace  sauter     E  parler"
	if can_zap: h += "     X  Foudre"
	h += "     Échap  pause"
	if hint_lbl: hint_lbl.text = h
	cfg["hint"] = h

func _start() -> void:
	if args.get("after_battle", false):
		await say([["gamin", "Ouf... Les Cauchemerles sont reparties dans les rêves de l'Oiseau. Plus qu'un paratonnerre !"]])
		return
	await title_cards([
		"Le monde repose sur le dos de trois titans endormis.",
		"Leurs rêves débordent dans certains humains.\nOn appelle ces pouvoirs les Kevrês.",
		"Sur l'aile de l'Oiseau d'Orage, un village fête ce soir\nla plus belle tempête de l'année.",
	])
	await say([
		["gamin", "Ce soir, c'est la fête de l'Orage ! Il faut que je trouve Mamé Sauge."],
	])

func _rods_lit() -> int:
	var n := 0
	for i in RODS.size():
		if Game.flags.get("rod%d" % i, false): n += 1
	return n

func _extra_glows(g: GlowLayer, tt: float) -> void:
	var lit := _rods_lit()
	for i in RODS.size():
		var on: bool = Game.flags.get("rod%d" % i, false)
		var p := Vector2(RODS[i], GROUND_Y - 190)
		if on:
			Game.draw_glow(g, p, 110 + 15 * sin(tt * 8.0 + i), Color(1.0, 0.85, 0.35, 0.65))
		else:
			Game.draw_glow(g, p, 40 + 10 * sin(tt * 3.0 + i), Color(0.37, 0.9, 1.0, 0.35))
	# lanternes de fête : plus elles brillent, plus de paratonnerres sont allumés
	for x in [520.0, 1760.0, 3960.0]:
		Game.draw_glow(g, Vector2(x, GROUND_Y - 170), 60.0 + 30.0 * lit, Color(1.0, 0.75, 0.3, 0.25 + 0.12 * lit))
	for x in [180.0, 1180.0, 2620.0, 4420.0]:
		Game.draw_glow(g, Vector2(x + 20, GROUND_Y - 70), 70.0, Color(1.0, 0.7, 0.3, 0.35))
	for c in swarm:
		Game.draw_glow(g, c.position + Vector2(0, -40), 50, Color(0.6, 0.3, 1.0, 0.35))
	if finale and foreuse:
		Game.draw_glow(g, foreuse.position + Vector2(-60, -60), 260 + 30 * sin(tt * 4.0), Color(0.3, 0.9, 1.0, 0.35))

func _talk_to(k: String) -> void:
	match k:
		"sauge":
			if not Game.flags.get("sauge_talk", false):
				await say([
					["sauge", "Te voilà enfin, petit éclair ! Tu as encore dormi dans les plumes du Grand Duvet ?"],
					["gamin", "J'ai encore rêvé de l'Oiseau, Mamé. Il volait au-dessus d'un monde tout plat, sans nuages."],
					["sauge", "Les rêves de l'Oiseau sont les tiens depuis que tu es tout petit. C'est pour ça que la Foudre t'écoute."],
					["sauge", "Ce soir, c'est toi qui ouvres la fête. Il faut allumer les trois paratonnerres du village."],
					["sauge", "Tends la main et appelle la Foudre, comme je t'ai appris. [color=#ffd35a]Touche X[/color]. Vise le sommet des paratonnerres."],
					["gamin", "Facile ! Le premier est juste après la maison des tisserands."],
					["sauge", "Et fais attention aux Cauchemerles. Les mauvais rêves de l'Oiseau sont nerveux, les soirs d'orage."],
				])
				Game.flags["sauge_talk"] = true
				can_zap = true
				_update_hint()
				toast("Nouveau pouvoir : Foudre  (touche X)", Game.GOLD)
			else:
				var n := _rods_lit()
				await say([
					["sauge", "Encore %d paratonnerre%s, petit éclair. Le village t'attend !" % [3 - n, "s" if 3 - n > 1 else ""]],
					["sauge", "Les marchands ont vu un ballon gris de l'Empire tourner autour de l'aile, ce matin... Sois prudent."],
				])

func _on_zap(from: Vector2, to: Vector2) -> void:
	var x0 := minf(from.x, to.x) - 50.0
	var x1 := maxf(from.x, to.x) + 50.0
	for i in RODS.size():
		if Game.flags.get("rod%d" % i, false): continue
		if RODS[i] > x0 and RODS[i] < x1 and absf(player.position.y - GROUND_Y) < 200:
			Game.flags["rod%d" % i] = true
			fx.bolt(Vector2(RODS[i], -40), Vector2(RODS[i], GROUND_Y - 200), Game.GOLD)
			fx.sparks(Vector2(RODS[i], GROUND_Y - 200), Game.GOLD, 30)
			Game.sfx("thunder", -6.0, 1.3); Game.sfx("pickup", -6.0)
			flash_v = 1.0; shake = 6.0
			var n := _rods_lit()
			toast("Paratonnerre allumé  %d / 3" % n, Game.GOLD)
			if n == 3:
				_finale()
			return
	for c in swarm:
		if c.position.x > x0 and c.position.x < x1:
			_start_swarm_battle()
			return

func _tick(_d: float) -> void:
	for i in swarm.size():
		var c: Sprite2D = swarm[i]
		c.position.y = GROUND_Y + 4 - absf(sin(t * 4.0 + i * 1.3)) * 18.0
		c.flip_h = player.position.x > c.position.x
	if not swarm.is_empty() and player.position.x > swarm_x - 140.0:
		_start_swarm_battle()

func _blocked_x() -> float:
	return INF

func _start_swarm_battle() -> void:
	if busy: return
	busy = true
	vel = Vector2.ZERO
	await say([["gamin", "Des Cauchemerles ! Elles bloquent le chemin du dernier paratonnerre..."]])
	busy = true
	Game.flags["swarm_done"] = true
	Game.sfx("zap", -2.0, 0.7)
	main.flash(Color(0.7, 0.4, 1.0, 0.7), 0.5)
	await wait(0.3)
	main.goto("battle", {"encounter": "village"})

func _finale() -> void:
	busy = true; vel = Vector2.ZERO; player.walking = false
	await wait(0.8)
	Game.music("")
	await say([
		["gamin", "Les trois paratonnerres brillent ! Mamé, tu vois ça ?"],
		["gamin", "... Pourquoi tout le monde s'est tu ?"],
	])
	busy = true
	finale = true
	# la foreuse descend des nuages
	Game.sfx("stone", 0.0, 0.4); Game.sfx("thunder", 0.0, 0.5)
	foreuse.position = Vector2(player.position.x + 520, -400)
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(foreuse, "position:y", GROUND_Y - 190.0, 3.0)
	while tw.is_running():
		shake = 8.0
		await wait(0.5)
	base_tint = Color(0.75, 0.85, 1.05)
	await say([["gamin", "La Foreuse de l'Empire..."]])
	busy = true
	# la Soldate et un garde descendent
	var s := Actor.new().setup("sprite_soldate", 175, 1)
	s.position = Vector2(player.position.x + 420, GROUND_Y); s.facing = -1; s.z_index = 2
	s.modulate.a = 0.0; add_child(s)
	var gd := Actor.new().setup("sprite_garde", 165, -1)
	gd.position = Vector2(player.position.x + 540, GROUND_Y); gd.facing = -1; gd.z_index = 2
	gd.modulate.a = 0.0; add_child(gd)
	var tw2 := create_tween().set_parallel()
	tw2.tween_property(s, "modulate:a", 1.0, 0.6); tw2.tween_property(gd, "modulate:a", 1.0, 0.6)
	await tw2.finished
	await walk_to(s, player.position.x + 200, 160.0)
	player.facing = 1
	await say([
		["soldate", "Porteur de Foudre. Au nom de l'Empire, tu viens avec nous."],
		["gamin", "Jamais !"],
	])
	busy = true
	# le Gamin tente un éclair, la Soldate le bloque avec son gantelet
	var from := player.position + Vector2(30, -80)
	fx.bolt(from, s.position + Vector2(-20, -100), Game.GOLD); fx.bolt(from, s.position + Vector2(-20, -100), Game.CYAN)
	Game.sfx("zap", 0.0)
	await wait(0.15)
	Game.sfx("stone", 2.0, 1.2); shake = 14.0
	fx.ring(s.position + Vector2(-20, -100), Color(1.0, 0.75, 0.35), 140.0, 0.6)
	main.flash(Color(1.0, 0.85, 0.5, 0.5), 0.3)
	await wait(0.6)
	await say([
		["soldate", "Pas mal. Mais la Pierre ne craint pas l'orage."],
	])
	busy = true
	var sg: Actor = npcs["sauge"]
	sg.position.x = player.position.x - 600
	await walk_to(sg, player.position.x - 120, 400.0)
	sg.facing = 1
	await say([
		["sauge", "Laissez-le ! Ce n'est qu'un enfant !"],
		["soldate", "C'est pour ça qu'il vivra, madame. Les autres porteurs n'ont pas eu cette chance."],
		["gamin", "Mamé... !"],
		["sauge", "Écoute les rêves de l'Oiseau, petit éclair. Où que tu ailles, ils te ramèneront ici."],
	])
	busy = true
	await title_cards(["Cette nuit-là, la Foreuse emporta le Gamin loin du village des Plumes."])
	main.goto("explore", {"level": "Convoi"})
