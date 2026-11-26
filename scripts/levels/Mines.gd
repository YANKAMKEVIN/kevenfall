extends Exploration
## Acte II, chapitre 5 : les mines profondes. Le Gamin éclaire l'obscurité avec la Foudre,
## la Soldate le suit. Au bord du lac de brume, ils rencontrent Ilo.

const CRYSTALS := [700.0, 1500.0, 2250.0, 3000.0, 3650.0]
var crystal_nodes: Array = []
var met_ilo := false
var ilo: Actor

func _config() -> Dictionary:
	return {
		"chapter": ["ACTE II  ·  CHAPITRE 5", "Les mines profondes"],
		"level_w": 4400.0,
		"segments": [[-200.0, 1850.0], [2010.0, 2700.0], [2860.0, 4600.0]],
		"platforms": [Rect2(1890, 470, 90, 22), Rect2(2420, 440, 120, 22), Rect2(2560, 360, 120, 22), Rect2(2720, 470, 110, 22)],
		"far": "fond_mines", "far_y": -10.0, "far_h": 760.0, "far_mod": Color(0.75, 0.75, 0.9),
		"tile": "tuile_roche", "tile_h": 330.0,
		"start_x": 260.0, "rain": 0.0, "flash_every": 99.0, "flash_power": 0.0,
		"tint": Color(0.32, 0.32, 0.5), "fog": 0.45, "fog_col": Color(0.45, 0.3, 0.8),
		"follower": {"tex": "sprite_soldate", "h": 168.0, "native": 1},
		"hint": "← →  marcher     Espace  sauter     X  Foudre (éclaire les cristaux)     Échap  pause",
		"shards": [
			{"id": "m1", "pos": Vector2(2620, 305), "text": "La Tortue rêve qu'elle nage. Elle a oublié qu'elle porte une ville. Chaque coup de pioche est une piqûre dans son sommeil."},
			{"id": "m2", "pos": Vector2(4050, 420), "text": "L'Oiseau, la Tortue, le Serpent. Trois dormeurs, un seul rêve. Celui qui écoute les trois entendra la vraie voix du monde."},
		],
	}

func _setup() -> void:
	can_zap = true
	for x in CRYSTALS:
		var c := _prop("cristal", x, 170.0, 1, 8.0)
		c.modulate = Color(0.55, 0.6, 0.8)
		crystal_nodes.append(c)
	ilo = Actor.new().setup("sprite_ilo", 180, -1)
	ilo.position = Vector2(4150, GROUND_Y); ilo.facing = -1; ilo.z_index = 2
	ilo.visible = false
	add_child(ilo)
	if args.get("after_battle", false):
		cfg["start_x"] = 3900.0
		ilo.visible = true; ilo.position.x = 4060.0

func _start() -> void:
	if args.get("after_battle", false):
		met_ilo = true
		await _outro()
		return
	await title_cards(["Traqués par l'Empire, le Gamin et la Soldate s'enfoncent\ndans les mines abandonnées, sous la capitale."])
	await say([
		["gamin", "On n'y voit rien du tout..."],
		["soldate", "Alors fais de la lumière, petit orage. Les vieux cristaux de mine réagissent à la Foudre."],
	])
	toast("X : Foudre. Allume les cristaux pour éclairer la mine.", Game.GOLD)

func _lit(i: int) -> bool:
	return Game.flags.get("crystal%d" % i, false)

func _extra_glows(g: GlowLayer, tt: float) -> void:
	# le Gamin éclaire autour de lui
	Game.draw_glow(g, player.position + Vector2(0, -70), 230 + 15 * sin(tt * 7.0), Color(1.0, 0.85, 0.45, 0.22))
	for i in CRYSTALS.size():
		var p := Vector2(CRYSTALS[i], GROUND_Y - 80)
		if _lit(i):
			Game.draw_glow(g, p, 330 + 20 * sin(tt * 2.0 + i), Color(0.3, 0.85, 1.0, 0.4))
			Game.draw_glow(g, p, 120, Color(0.6, 1.0, 1.0, 0.5))
		else:
			Game.draw_glow(g, p, 50 + 8 * sin(tt * 3.0 + i), Color(0.3, 0.6, 1.0, 0.25))
	if ilo.visible:
		Game.draw_glow(g, ilo.position + Vector2(-50, -150), 140 + 10 * sin(tt * 3.0), Color(0.6, 0.45, 1.0, 0.45))

func _on_zap(from: Vector2, to: Vector2) -> void:
	var x0 := minf(from.x, to.x) - 40.0
	var x1 := maxf(from.x, to.x) + 40.0
	for i in CRYSTALS.size():
		if _lit(i): continue
		if CRYSTALS[i] > x0 and CRYSTALS[i] < x1:
			Game.flags["crystal%d" % i] = true
			crystal_nodes[i].modulate = Color(1.3, 1.6, 1.9)
			fx.sparks(Vector2(CRYSTALS[i], GROUND_Y - 90), Game.CYAN, 30)
			Game.sfx("pickup", -6.0, 0.8)
			var n := 0
			for k in CRYSTALS.size():
				if _lit(k): n += 1
			base_tint = Color(0.32, 0.32, 0.5).lerp(Color(0.62, 0.64, 0.85), n / 5.0)
			toast("Cristal allumé  %d / 5" % n, Game.CYAN)
			return

func _tick(_d: float) -> void:
	if not met_ilo and player.position.x > 3800.0 and on_ground:
		met_ilo = true
		_meet_ilo()

func _meet_ilo() -> void:
	busy = true; vel = Vector2.ZERO; player.walking = false
	player.facing = 1
	ilo.visible = true; ilo.modulate.a = 0.0
	ilo.position.x = 4060.0
	Game.sfx("heal", -4.0, 0.5)
	create_tween().tween_property(ilo, "modulate:a", 1.0, 1.2)
	await wait(1.2)
	await say([
		["ilo", "Doucement, petit éclair. Tu vas effrayer les rêves de la Tortue. Ils sont déjà assez nerveux."],
		["gamin", "Qui êtes-vous ? Et comment vous savez comment Mamé m'appelle ?"],
		["ilo", "Ilo. Prêtre des Marées, dernier de mon culte. Je sais beaucoup de choses. C'est mon métier, et ma malédiction."],
		["soldate", "Un espion du Serpent, dans les mines de l'Empire."],
		["ilo", "Un curieux, Capitaine. Pardon : ex-Capitaine. Les nouvelles vont vite, sous la carapace."],
		["ilo", "Vous voulez comprendre pourquoi la Tortue tremble ? Alors suivez-moi. Je connais un chemin jusqu'à son cœur."],
		["gamin", "Son cœur ?"],
		["ilo", "Là où elle rêve. Mais d'abord... nous avons de la compagnie."],
	])
	busy = true
	Game.sfx("stone", 2.0, 0.6); shake = 16.0
	main.flash(Color(0.8, 0.6, 0.3, 0.4), 0.4)
	await wait(0.6)
	main.goto("battle", {"encounter": "mines"})

func _outro() -> void:
	busy = true
	player.facing = 1
	await say([
		["ilo", "Pas mal, pour une déserteuse et un orage de poche."],
		["soldate", "Et vous, vous vous battez avec du brouillard."],
		["ilo", "Le brouillard ne rate jamais sa cible, Capitaine. Il l'entoure."],
		["gamin", "On va vraiment voir le cœur de la Tortue ?"],
		["ilo", "Nous allons faire mieux que le voir, petit éclair. Nous allons entrer dans son rêve."],
	])
	busy = true
	main.goto("explore", {"level": "Reve"})
