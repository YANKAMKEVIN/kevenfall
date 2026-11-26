extends Exploration
## Acte II, chapitre 6 : le rêve de la Tortue. Première communion.
## Le Gamin rallume les lanternes du rêve pour faire apparaître les passages,
## affronte le Gardien, puis la Tortue leur demande : Bercer ou Éveiller ?
## Dans le rêve, le Gamin découvre qu'il est lui-même un rêve de l'Oiseau.

const LANTERNS := [1180.0, 2400.0, 3650.0]
const BRIDGES := [
	[Rect2(1350, 470, 110, 22), Rect2(1520, 430, 110, 22)],
	[Rect2(2570, 470, 110, 22), Rect2(2720, 420, 110, 22), Rect2(2860, 470, 100, 22)],
	[],
]
var lantern_nodes: Array = []
var lit := [false, false, false]
var bridge_t := [0.0, 0.0, 0.0]
var gardien: Actor
var met_gardien := false
var ilo: Actor

func _config() -> Dictionary:
	return {
		"chapter": ["ACTE II  ·  CHAPITRE 6", "Le rêve de la Tortue"],
		"level_w": 4500.0,
		"segments": [[-200.0, 1300.0], [1690.0, 2500.0], [2960.0, 4700.0]],
		"platforms": [],
		"far": "fond_reve", "far_y": -20.0, "far_h": 780.0,
		"tile": "tuile_reve", "tile_h": 170.0,
		"start_x": 260.0, "rain": 0.0, "flash_every": 99.0, "flash_power": 0.0,
		"tint": Color(0.82, 0.9, 1.0), "fog": 0.4, "fog_col": Color(0.4, 0.85, 0.9),
		"follower": {"tex": "sprite_soldate", "h": 168.0, "native": 1},
		"npcs": [{"id": "ilo", "tex": "sprite_ilo", "h": 175.0, "x": 560.0, "face": -1, "native": -1}],
		"props": [["reve_arbre", 120.0, 260.0, 0], ["reve_rochers", 760.0, 90.0, 1], ["reve_arbre", 2050.0, 280.0, 0],
			["reve_rochers", 3200.0, 90.0, 1], ["reve_arbre", 3400.0, 250.0, 0], ["reve_arche", 4200.0, 330.0, 0]],
		"music": "music_explore",
		"revelins": 10,
		"hint": "← →  marcher     Espace  sauter     X  Foudre (rallume les lanternes)     E  parler",
		"shards": [
			{"id": "t1", "pos": Vector2(1575, 330), "text": "Avant la ville, il y avait une forêt sur mon dos. Les arbres chantaient quand je nageais. Je ne nage plus depuis si longtemps."},
			{"id": "t2", "pos": Vector2(3900, 420), "text": "Les petits humains creusent. Chaque coup est une piqûre. Je ne leur en veux pas. Je voudrais seulement qu'ils m'entendent."},
		],
	}

func _setup() -> void:
	can_zap = true
	Game.flags["foudre2"] = true
	for x in LANTERNS:
		var l := _prop("reve_lanterne", x, 150.0, 1)
		if l: l.modulate = Color(0.45, 0.5, 0.65)
		lantern_nodes.append(l)
	ilo = npcs["ilo"]
	gardien = Actor.new().setup("sprite_gardien", 300, -1)
	gardien.position = Vector2(4250, GROUND_Y); gardien.facing = -1; gardien.z_index = 2
	gardien.modulate = Color(0.6, 0.9, 1.0, 0.0)
	add_child(gardien)
	if args.get("after_battle", false):
		cfg["start_x"] = 3950.0
		for i in 3: lit[i] = true; bridge_t[i] = 1.0
		ilo.position.x = 4060.0
		gardien.modulate.a = 0.0

func _start() -> void:
	if args.get("after_battle", false):
		await _communion()
		return
	await title_cards(["Ilo chante à voix basse. La brume monte, épaisse et tiède.\nQuand elle se dissipe, la mine a disparu."])
	await say([
		["gamin", "Où... on est où ?"],
		["ilo", "Dans le rêve de la Tortue. Ne t'éloigne pas trop : ici, ce qui est oublié n'existe plus."],
		["soldate", "Il n'y a pas de chemin. Juste de la brume."],
		["ilo", "Le chemin s'est éteint. Les lanternes du rêve attendent une étincelle. Petit éclair ?"],
	])
	toast("X : Foudre. Rallume les lanternes pour faire apparaître le chemin.", Game.GOLD)

func _talk_to(k: String) -> void:
	if k == "ilo":
		var n := lit.count(true)
		var lines := [
			["ilo", "Rallume la lanterne, et le rêve se souviendra du chemin."],
			["ilo", "Tu sens ? La Tortue respire plus doucement quand la lumière revient."],
			["ilo", "Encore une. Derrière l'arche, quelqu'un nous attend."],
			["ilo", "Le Gardien du rêve. Il ne laisse passer que ceux qui méritent d'être écoutés."],
		]
		await say([lines[mini(n, 3)]])

func _on_zap(from: Vector2, to: Vector2) -> void:
	var x0 := minf(from.x, to.x) - 50.0
	var x1 := maxf(from.x, to.x) + 50.0
	for i in LANTERNS.size():
		if lit[i]: continue
		if LANTERNS[i] > x0 and LANTERNS[i] < x1:
			lit[i] = true
			if lantern_nodes[i]: lantern_nodes[i].modulate = Color(1.3, 1.6, 1.8)
			fx.sparks(Vector2(LANTERNS[i], GROUND_Y - 110), Game.CYAN, 34)
			Game.sfx("pickup", -4.0, 0.7); Game.sfx("heal", -6.0, 0.8)
			for r in BRIDGES[i]:
				platforms.append(r)
				fx.ring(r.get_center(), Color(0.5, 1.0, 1.0), 90.0, 0.8)
			if deck_node: deck_node.queue_redraw()
			toast(["Le chemin du rêve réapparaît.", "Un deuxième passage se souvient de lui-même.", "L'arche du Gardien s'illumine."][i], Game.CYAN)
			_move_ilo(i)
			return

func _move_ilo(i: int) -> void:
	var dest: float = [2150.0, 3300.0, 4000.0][i]
	var tw := create_tween(); tw.tween_property(ilo, "modulate:a", 0.0, 0.6)
	await tw.finished
	ilo.position.x = dest
	create_tween().tween_property(ilo, "modulate:a", 1.0, 0.8)

func _blocked_x() -> float:
	return INF if lit[2] else 3700.0

func _tick(_d: float) -> void:
	if not lit[2] and player.position.x > 3690.0 and not busy and on_ground:
		toast("La lanterne de l'arche est éteinte. Utilise la Foudre (X).", Game.GOLD)
		player.position.x = 3600.0
	if lit[2] and not met_gardien and player.position.x > 3980.0 and on_ground:
		met_gardien = true
		_meet_gardien()

func _extra_glows(g: GlowLayer, tt: float) -> void:
	Game.draw_glow(g, player.position + Vector2(0, -70), 180 + 12 * sin(tt * 6.0), Color(1.0, 0.85, 0.45, 0.16))
	for i in LANTERNS.size():
		var p := Vector2(LANTERNS[i], GROUND_Y - 120)
		if lit[i]:
			Game.draw_glow(g, p, 260 + 20 * sin(tt * 2.0 + i), Color(0.35, 0.95, 1.0, 0.4))
			Game.draw_glow(g, p, 90, Color(0.8, 1.0, 1.0, 0.6))
		else:
			Game.draw_glow(g, p, 50 + 10 * sin(tt * 3.0 + i), Color(0.4, 0.7, 1.0, 0.3))
		for r in BRIDGES[i]:
			if lit[i]:
				Game.draw_glow(g, r.get_center() + Vector2(0, 10), 120, Color(0.4, 1.0, 1.0, 0.25 + 0.08 * sin(tt * 3.0)))
	if gardien.modulate.a > 0.05:
		Game.draw_glow(g, gardien.position + Vector2(0, -160), 300 + 20 * sin(tt * 1.5), Color(0.3, 0.9, 1.0, 0.35 * gardien.modulate.a))
	if ilo.visible:
		Game.draw_glow(g, ilo.position + Vector2(-50, -150), 120 + 10 * sin(tt * 3.0), Color(0.6, 0.45, 1.0, 0.35))

func _meet_gardien() -> void:
	busy = true; vel = Vector2.ZERO; player.walking = false; player.facing = 1
	Game.music("")
	Game.sfx("stone", 0.0, 0.4); shake = 12.0
	var tw := create_tween(); tw.tween_property(gardien, "modulate:a", 1.0, 2.0)
	await wait(2.0)
	await say([
		["tortue", "... Qui ... marche ... dans mon sommeil ..."],
		["ilo", "Le Gardien parle avec la voix de la Tortue. Restez calmes."],
		["gamin", "On veut seulement vous parler ! Les humains de la ville vous font du mal, on le sait !"],
		["tortue", "Tant de petits humains... sont venus... avec des pioches. Montrez-moi... que vous êtes différents."],
		["soldate", "Ça, c'est une invitation à se battre. Je connais."],
	])
	busy = true
	main.flash(Color(0.4, 0.95, 1.0, 0.6), 0.5)
	await wait(0.4)
	main.goto("battle", {"encounter": "gardien"})

func _communion() -> void:
	busy = true
	player.position.x = 3950.0; player.facing = 1
	gardien.modulate.a = 0.0
	Game.music("")
	base_tint = Color(0.9, 1.0, 1.05)
	await wait(0.6)
	Game.sfx("heal", 0.0, 0.3); shake = 6.0
	main.flash(Color(0.5, 1.0, 1.0, 0.6), 1.0)
	await say([
		["tortue", "Vous vous êtes battus... sans haine. Les autres avaient toujours de la haine."],
		["tortue", "J'ouvre l'œil, petits. Écoutez."],
		["tortue", "Je suis vieille. Je porte une ville sur mon dos depuis trois cents ans. Chaque Kevrê arraché me réveille un peu plus."],
		["tortue", "Bientôt, je ne pourrai plus dormir. Et quand je me lèverai, votre ville tombera."],
		["ilo", "Mon culte chantait pour garder les titans endormis. Bercer : apaiser son rêve, lui rendre le sommeil, un temps."],
		["ilo", "Mais on peut aussi... écouter sa colère. Éveiller : la laisser se réveiller un peu, à son rythme, et en recevoir la force."],
		["soldate", "Et c'est à nous de choisir ? Pour une montagne ?"],
		["tortue", "C'est à l'enfant de l'orage de me répondre."],
	])
	var c := await choose("Que demande le Gamin à la Tortue ?", [
		{"title": "Bercer", "col": Color("7fe8c8"), "text": "Chanter avec Ilo pour apaiser la Tortue. Elle se rendort plus profondément, pour un temps.\n\nVos Kevrês deviennent protecteurs :\nRempart (Pierre 2) et Arc apaisant (Foudre)."},
		{"title": "Éveiller", "col": Color("ff9a6a"), "text": "Écouter sa colère et la laisser monter. La Tortue s'éveille un peu, à son rythme.\n\nVos Kevrês deviennent offensifs :\nSéisme (Pierre 2) et Tempête (Foudre)."},
	])
	busy = true
	if c == 0:
		Game.flags["communion1"] = "bercer"
		Game.sfx("heal", -2.0, 0.6)
		await say([
			["gamin", "Dormez encore, s'il vous plaît. Le temps qu'on trouve une solution."],
			["ilo", "Alors chantons, petit éclair. Doucement."],
			["tortue", "Une berceuse... Personne ne m'avait chanté de berceuse depuis la forêt..."],
		])
		base_tint = Color(0.75, 0.95, 1.0)
		toast("Communion : Bercer", Color("7fe8c8"))
		await wait(0.4)
		toast("Pierre niveau 2 : Rempart  ·  Foudre : Arc apaisant", Game.GOLD)
	else:
		Game.flags["communion1"] = "eveiller"
		Game.sfx("thunder", -2.0, 0.7); shake = 18.0
		await say([
			["gamin", "Vous avez le droit d'être en colère. Réveillez-vous un peu. Qu'ils vous entendent enfin !"],
			["ilo", "... Audacieux. Tiens-toi bien, Capitaine."],
			["tortue", "Oui... Je me souviens de ma force. Prenez-en un peu, petits. Faites-leur entendre ma voix."],
		])
		base_tint = Color(1.0, 0.88, 0.8)
		toast("Communion : Éveiller", Color("ff9a6a"))
		await wait(0.4)
		toast("Pierre niveau 2 : Séisme  ·  Foudre : Tempête", Game.GOLD)
	main.flash(Color(1, 1, 1, 0.5), 0.6)
	await wait(2.6)
	# le retournement
	await say([
		["tortue", "Enfant de l'orage. Reste un instant. Toi seul."],
		["tortue", "Tu n'es pas un porteur, toi. Tu n'as pas d'éclat de rêve en toi. Regarde."],
	])
	busy = true
	Game.sfx("thunder", -4.0, 0.6)
	await show_art("vision_oiseau", [
		["reve", "Une nuit d'orage, il y a treize ans. Au-dessus du village des Plumes."],
		["oiseau", "Petit rêve... Va. Vis ce que je ne peux que rêver."],
		["gamin", "C'est... c'est moi ? Ce bébé, c'est moi ?"],
		["tortue", "Tu es un rêve de l'Oiseau, devenu enfant. Tu es né de son sommeil."],
		["tortue", "Quand l'Oiseau s'éveillera, ses rêves finiront. Tous ses rêves."],
		["gamin", "..."],
	])
	busy = true
	await say([
		["soldate", "Hé ! Gamin ! Tu es tout pâle. Qu'est-ce qu'elle t'a montré ?"],
		["gamin", "Rien... Juste des nuages. Des souvenirs de nuages."],
		["soldate", "Hm. Si tu le dis."],
	])
	busy = true
	await walk_to(ilo, player.position.x + 110.0, 120.0)
	ilo.facing = -1
	await say([
		["ilo", "Des nuages. Bien sûr."],
		["gamin", "Tu as compris, hein ?"],
		["ilo", "Je comprends beaucoup de choses. C'est mon métier, et ma malédiction."],
		["ilo", "Tu n'es pas obligé d'en parler. Mais tu n'es pas obligé de le porter seul non plus. Ton secret est en sécurité, petit éclair."],
	])
	busy = true
	# l'Empire creuse
	Game.sfx("stone", 6.0, 0.4); Game.sfx("thunder", 0.0, 0.5); shake = 26.0
	base_tint = Color(1.0, 0.55, 0.55)
	main.flash(Color(1, 0.2, 0.15, 0.6), 0.6)
	await say([
		["tortue", "AAAH... ! Une aiguille... jusqu'au cœur...!"],
		["soldate", "Qu'est-ce qui se passe ?!"],
		["ilo", "Ce n'est pas nous. C'est l'Empire. Quelqu'un fore très, très profond. Il faut se réveiller. Maintenant !"],
	])
	busy = true
	main.flash(Color(1, 1, 1, 1), 0.8)
	await wait(0.6)
	main.goto("explore", {"level": "Effondrement"})
