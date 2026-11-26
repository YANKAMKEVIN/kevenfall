extends Exploration
## Acte II, chapitre 4 : le centre d'extraction. On joue la Soldate.
## Elle lit les rapports, croise la Chancelière Orsane, puis libère le Gamin.

var read := {}
var orsane_done := false
var freed := false
var cell: Sprite2D
var gamin: Actor
var alarm := 0.0

func _config() -> Dictionary:
	return {
		"chapter": ["ACTE II  ·  CHAPITRE 4", "Le centre d'extraction"],
		"level_w": 4300.0,
		"segments": [[-200.0, 1720.0], [1880.0, 4500.0]],
		"platforms": [Rect2(1740, 470, 120, 22)],
		"far": "fond_capitale", "far_y": -30.0, "far_h": 760.0,
		"tile": "tuile_metal", "tile_h": 330.0,
		"start_x": 240.0, "rain": 0.0, "flash_every": 3.0, "flash_power": 0.25,
		"tint": Color(0.82, 0.8, 0.95), "fog": 0.3, "fog_col": Color(0.4, 0.5, 0.7),
		"player_tex": "sprite_soldate", "player_h": 172.0, "player_native": 1, "speed_mul": 0.95,
		"music": "music_explore",
		"hint": "← →  marcher     Espace  sauter     E  lire / parler     Échap  pause",
		"props": [["centre_caisses", 120.0, 120.0], ["centre_cuve", 600.0, 230.0], ["centre_cuve", 1450.0, 230.0],
			["centre_caisses", 2300.0, 110.0], ["centre_cuve", 2600.0, 230.0], ["centre_cuve", 3500.0, 230.0]],
		"objects": [
			{"id": "r1", "x": 980.0, "label": "Lire le rapport", "h": 200.0},
			{"id": "r2", "x": 2050.0, "label": "Lire le rapport", "h": 200.0},
			{"id": "r3", "x": 3000.0, "label": "Lire le rapport", "h": 200.0},
		],
		"npcs": [
			{"id": "tess", "tex": "sprite_tess", "h": 150.0, "x": 1250.0, "face": -1},
			{"id": "garde", "tex": "sprite_garde", "h": 168.0, "x": 3350.0, "face": -1},
		],
		"glows": [
			[Vector2(600, GROUND_Y - 120), 150.0, Color(0.3, 0.9, 1.0, 0.35)],
			[Vector2(1450, GROUND_Y - 120), 150.0, Color(0.3, 0.9, 1.0, 0.35)],
			[Vector2(2600, GROUND_Y - 120), 150.0, Color(0.3, 0.9, 1.0, 0.35)],
			[Vector2(3500, GROUND_Y - 120), 150.0, Color(0.3, 0.9, 1.0, 0.35)],
			[Vector2(3950, GROUND_Y - 150), 170.0, Color(0.3, 0.9, 1.0, 0.45)],
		],
	}

func _setup() -> void:
	Game.flags["foudre2"] = true
	for x in [980.0, 2050.0, 3000.0]:
		_prop("centre_console", x, 150.0, 1)
	cell = _prop("centre_cellule", 3950.0, 250.0, 1)
	gamin = Actor.new().setup("sprite_gamin", 125, 1)
	gamin.position = Vector2(3950, GROUND_Y - 14); gamin.facing = -1; gamin.z_index = 0
	gamin.modulate = Color(0.7, 0.9, 1.1)
	add_child(gamin)
	cell.z_index = 2

func _start() -> void:
	await title_cards([
		"ACTE II  ·  LA TORTUE-MONTAGNE",
		"La capitale de l'Empire est creusée dans la carapace de la Tortue.\nMines, usines, quartiers suspendus.",
		"Le Gamin a été conduit au centre d'extraction numéro sept.\nLa Soldate, elle, doit y remettre son rapport de capture.",
	])
	await say([["soldate", "Un rapport de capture, et ensuite une nouvelle mission. Comme d'habitude."],
		["soldate", "... Alors pourquoi je n'arrive pas à oublier ce gamin ?"]])

func _extra_glows(g: GlowLayer, tt: float) -> void:
	for o in cfg.objects:
		var on := not read.has(o.id)
		Game.draw_glow(g, Vector2(o.x, GROUND_Y - 120), 60 + 10 * sin(tt * 3.0), Color(0.4, 0.9, 1.0, 0.45 if on else 0.15))
	if alarm > 0.0:
		var a := 0.25 + 0.25 * sin(tt * 8.0)
		for x in [500.0, 1500.0, 2500.0, 3500.0, 4100.0]:
			Game.draw_glow(g, Vector2(x, 200), 400, Color(1.0, 0.15, 0.1, a))

func _talk_to(k: String) -> void:
	match k:
		"r1":
			read["r1"] = true
			await say([["rapport", "Rapport d'extraction n° 212. Porteuse : une fileuse de trente-quatre ans, Kevrê du Vent. Extraction réussie."],
				["rapport", "Secousse mesurée dans la carapace pendant l'opération : force 2. Note de l'opérateur : la porteuse ne parle plus depuis."],
				["soldate", "« Ne parle plus »... Elle était vivante quand je l'ai amenée ici."]])
		"r2":
			read["r2"] = true
			await say([["rapport", "Relevés sismiques du trimestre. Les secousses augmentent après chaque extraction."],
				["rapport", "Premier mois : 14 secousses. Deuxième mois : 31. Troisième mois : 58. Recommandation : ne pas transmettre aux équipes de capture."],
				["soldate", "Chaque porteur qu'on ramène... fait trembler la Tortue un peu plus. Et on nous le cache."]])
		"r3":
			read["r3"] = true
			await say([["rapport", "Ordre de la Chancellerie. Porteur prioritaire : un enfant, Kevrê de la Foudre, origine Oiseau d'Orage."],
				["rapport", "Extraction totale autorisée. Survie du porteur : non requise."],
				["soldate", "..."],
				["soldate", "Non requise."]])
		"tess":
			await say([["tess", "Capitaine ! Vous êtes vivante ! Après ce qui s'est passé sur le pont, j'ai cru..."],
				["tess", "Le Golem rêvait de la Tortue, j'en suis sûre. Quand il est devenu fou, il... il avait mal."],
				["tess", "Je crois que c'est elle qui a mal, Capitaine. Chaque fois qu'on allume les cuves."]])
		"garde":
			if read.size() < 3:
				await say([["garde", "Capitaine. Le bloc des cellules est fermé : la Chancelière est en inspection."],
					["soldate", "Je dois d'abord remettre mon rapport. Les consoles sont sur le chemin."]])
			else:
				await say([["garde", "Capitaine. Personne n'entre dans le bloc des cellules."]])
		_:
			pass
	if read.size() == 3 and not orsane_done:
		await _orsane()

func _blocked_x() -> float:
	return INF if orsane_done else npcs["garde"].position.x - 60.0

func _tick(delta: float) -> void:
	alarm = maxf(0.0, alarm - delta * 0.0)
	if not orsane_done and player.position.x >= npcs["garde"].position.x - 62.0 and not busy:
		player.position.x = npcs["garde"].position.x - 70.0
		talk("garde")
	if orsane_done and not freed and player.position.x > 3780.0:
		freed = true
		_free_gamin()

func _orsane() -> void:
	busy = true
	await wait(0.5)
	var o := Actor.new().setup("sprite_orsane", 178, -1)
	o.position = Vector2(player.position.x + 650, GROUND_Y); o.facing = -1; o.z_index = 2
	add_child(o)
	Game.music("")
	await walk_to(o, player.position.x + 190, 110.0)
	o.facing = -1; player.facing = 1
	await say([
		["orsane", "Capitaine. On me dit que votre capture sur l'Oiseau est remarquable. Le porteur de Foudre alimentera trois navires à lui seul."],
		["soldate", "Chancelière. Les rapports... Chaque extraction fait trembler la Tortue. Les secousses doublent chaque mois."],
		["orsane", "Je sais lire, Capitaine. Les titans se réveilleront dans quarante ans, que nous creusions ou non."],
		["orsane", "Je ne choisis pas si le monde tombe. Je choisis seulement qui sera à bord de la flotte quand il tombera."],
		["soldate", "Et l'enfant ?"],
		["orsane", "L'enfant est une ressource. Comme vous. Comme moi. Reposez-vous, Capitaine. Demain, vous repartez en chasse."],
	])
	busy = true
	await walk_to(o, player.position.x + 800, 140.0)
	o.queue_free()
	await say([["soldate", "Une ressource..."], ["soldate", "Non."]])
	busy = true
	# la Soldate écarte le garde d'un coup de gantelet
	var g: Actor = npcs["garde"]
	await walk_to(player, g.position.x - 90.0, 200.0)
	player.facing = 1
	Game.sfx("stone", 2.0, 1.1); shake = 14.0
	fx.ring(g.position + Vector2(0, -90), Color(1.0, 0.75, 0.35), 130.0, 0.6)
	main.flash(Color(1.0, 0.85, 0.5, 0.4), 0.3)
	var tw := create_tween().set_parallel()
	tw.tween_property(g, "position:x", g.position.x + 120, 0.25)
	tw.tween_property(g, "rotation", 1.4, 0.3)
	tw.tween_property(g, "modulate:a", 0.6, 0.3)
	g.set_meta("mute", true)
	await wait(0.6)
	orsane_done = true
	await say([["soldate", "Désolée, soldat. Le gamin ne restera pas une nuit de plus dans cette cage."]])
	busy = false

func _free_gamin() -> void:
	busy = true; vel = Vector2.ZERO
	await walk_to(player, 3800.0, 200.0)
	player.facing = 1
	await say([
		["gamin", "Toi ?! Tu viens m'emmener à la machine ?"],
		["soldate", "Je viens te sortir d'ici. Ne pose pas de questions."],
		["gamin", "Tu vas avoir de gros ennuis."],
		["soldate", "J'en ai déjà. Recule."],
	])
	busy = true
	Game.sfx("stone", 4.0, 0.9); Game.sfx("hit", 0.0, 0.6); shake = 20.0
	main.flash(Color(0.6, 0.95, 1.0, 0.6), 0.4)
	fx.sparks(cell.position + Vector2(0, -120), Game.CYAN, 50)
	cell.modulate = Color(1, 1, 1, 0.25)
	gamin.modulate = Color.WHITE; gamin.z_index = 3
	await walk_to(gamin, 3880.0, 200.0)
	# alarme
	alarm = 1.0
	base_tint = Color(1.0, 0.7, 0.75)
	Game.sfx("thunder", 0.0, 1.6)
	await say([
		["gamin", "C'est quoi ce bruit ?!"],
		["soldate", "L'alarme. Et ça, c'est l'Extracteur. Tu sais encore te servir de ta Foudre ?"],
		["gamin", "Mieux qu'avant. Regarde bien."],
	])
	busy = true
	main.flash(Color(1, 0.3, 0.3, 0.6), 0.5)
	await wait(0.4)
	main.goto("battle", {"encounter": "centre"})
