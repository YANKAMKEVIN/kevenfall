extends Exploration
## Acte III, chapitre 11 : le Rêve Commun. Le donjon final, où les rêves des trois
## titans se mêlent. Le Gamin s'efface. Écouter les trois titans, vaincre le
## Cauchemar Commun, puis le dernier choix, avec l'Oiseau. Et la fin.

const ECHOES := {"echo_oiseau": 1000.0, "echo_tortue": 2250.0, "echo_serpent": 3450.0}
var heard := {}
var met := false
var ilo: Actor
var ending_reached := ""   # fin jouée (Story.ENDING_*), lue par le robot de parcours

func _config() -> Dictionary:
	return {
		"chapter": ["ACTE III  ·  CHAPITRE 11", "Le Rêve Commun"],
		"level_w": 4600.0,
		"segments": [[-200.0, 1500.0], [1760.0, 2900.0], [3160.0, 4800.0]],
		"platforms": [Rect2(1540, 460, 90, 22), Rect2(1660, 400, 80, 22), Rect2(2940, 460, 90, 22), Rect2(3060, 410, 80, 22),
			Rect2(2400, 380, 120, 22)],
		"far": "fond_reve_commun", "far_y": -20.0, "far_h": 780.0,
		"tile": "tuile_reve", "tile_h": 170.0,
		"start_x": 260.0, "rain": 0.0, "flash_every": 1.5, "flash_power": 0.35,
		"tint": Color(0.9, 0.9, 1.05), "fog": 0.35, "fog_col": Color(0.7, 0.6, 1.0),
		"follower": {"tex": "sprite_soldate", "h": 168.0, "native": 1},
		"npcs": [{"id": "ilo", "tex": "sprite_ilo", "h": 175.0, "x": 560.0, "face": -1, "native": -1}],
		"objects": [
			{"id": "echo_oiseau", "x": 1000.0, "label": "Écouter l'Oiseau", "h": 220.0},
			{"id": "echo_tortue", "x": 2250.0, "label": "Écouter la Tortue", "h": 220.0},
			{"id": "echo_serpent", "x": 3450.0, "label": "Écouter le Serpent", "h": 220.0},
		],
		"props": [["reve_arbre", 1900.0, 260.0, 0], ["reve_arche", 4300.0, 330.0, 0], ["reve_rochers", 700.0, 90.0, 1]],
		"music": "music_explore",
		"revelins": 14,
		"hint": "← →  marcher     Espace  sauter     E  écouter / parler     Échap  pause",
		"shards": [
			{"id": "c1", "pos": Vector2(1700, 300), "text": "Nous étions trois à rêver le même monde. Puis les petits ont appris à nous prendre nos rêves, et nous avons fait des cauchemars."},
			{"id": "c2", "pos": Vector2(2460, 280), "text": "Un rêve qui marche, qui rit, qui se met en colère. L'Oiseau en est si fier. Il ne veut pas se réveiller, pour ne pas le perdre."},
		],
	}

func _setup() -> void:
	can_zap = true
	Game.flags["foudre2"] = true
	Game.flags["niv3"] = true
	for k in ["communion1", "communion2"]:
		if not Game.flags.has(k): Game.flags[k] = "bercer"
	ilo = npcs["ilo"]
	if args.get("after_battle", false):
		cfg["start_x"] = 4000.0
		ilo.position.x = 4120.0
		for k in ECHOES:
			if Game.flags.get("heard_" + k, false): heard[k] = true

func _start() -> void:
	player.modulate = Color(1.15, 1.15, 1.3, 0.75)
	if args.get("after_battle", false):
		await _titans()
		return
	await title_cards(["Ilo chante. Le Gamin brille de plus en plus faiblement.\nQuand la brume se lève, le monde n'a plus de sol, plus de ciel :\nseulement les rêves des trois titans, mêlés."])
	await say([
		["gamin", "C'est beau... Il y a des plumes, de la carapace, de la brume... tout à la fois."],
		["soldate", "Comment tu te sens ?"],
		["gamin", "Léger. Trop léger."],
		["ilo", "Ici, vos Kevrês sont au plus près de leur source. Ils atteignent leur troisième niveau. Et nos trois rêves peuvent frapper ensemble."],
		["ilo", "Un dernier conseil : les titans n'écoutent que ceux qui les ont écoutés. Prêtez l'oreille à chacun d'eux avant d'aller plus loin."],
	])
	toast("Niveau 3 : vos Kevrês sont plus puissants. Nouvelle attaque à trois : Rêve Commun.", Game.GOLD)
	await wait(0.4)
	toast("Écoute les trois titans (E) avant d'aller au bout du rêve.", Game.CYAN)

func _talk_to(k: String) -> void:
	match k:
		"ilo":
			await say([["ilo", "Les titans n'écoutent que ceux qui les ont écoutés. Tous les trois. Et, je crois, ceux qui n'ont pas toujours choisi la même chose."]])
		"echo_oiseau":
			heard[k] = true; Game.flags["heard_" + k] = true
			Game.sfx("thunder", -6.0, 1.2)
			await say([
				["oiseau", "Petit rêve. Tu es venu jusqu'ici. Je t'ai senti grandir, dans chaque orage."],
				["oiseau", "Je ne veux pas me réveiller. Si j'ouvre les yeux, tu t'en vas. Mais ils me piquent, ils me tirent... Je ne pourrai plus dormir longtemps."],
				["gamin", "Je sais. Ce n'est pas ta faute."],
			])
		"echo_tortue":
			heard[k] = true; Game.flags["heard_" + k] = true
			Game.sfx("stone", -4.0, 0.5)
			await say([
				["tortue", "Encore toi, enfant de l'orage. Je suis debout, maintenant. Debout et fatiguée."],
				["tortue", "Je ne veux pas écraser les petits. Je voudrais seulement poser mon fardeau. Doucement. Quelque part."],
			])
		"echo_serpent":
			heard[k] = true; Game.flags["heard_" + k] = true
			Game.sfx("heal", -4.0, 0.4)
			await say([
				["serpent", "Le chanteur a enfin dit la vérité. Alors je vais dire la mienne."],
				["serpent", "Nous ne haïssons pas les petits. Nous voulons qu'on nous parle, au lieu de nous prendre. Un lien, pas une chaîne."],
			])
	if heard.size() == 3 and k.begins_with("echo"):
		toast("Tu as écouté les trois titans.", Game.GOLD)

func _extra_glows(g: GlowLayer, tt: float) -> void:
	Game.draw_glow(g, player.position + Vector2(0, -70), 200 + 30 * sin(tt * 4.0), Color(1.0, 0.85, 0.45, 0.2 + 0.08 * sin(tt * 9.0)))
	var cols := {"echo_oiseau": Color(1.0, 0.85, 0.35), "echo_tortue": Color(0.45, 1.0, 0.8), "echo_serpent": Color(0.7, 0.55, 1.0)}
	for k in ECHOES:
		var c: Color = cols[k]
		var a := 0.45 if not heard.has(k) else 0.18
		Game.draw_glow(g, Vector2(ECHOES[k], GROUND_Y - 120), 120 + 18 * sin(tt * 2.0 + ECHOES[k]), Color(c.r, c.g, c.b, a))
		Game.draw_glow(g, Vector2(ECHOES[k], GROUND_Y - 120), 40, Color(1, 1, 1, a))
	if ilo.visible:
		Game.draw_glow(g, ilo.position + Vector2(-50, -150), 120, Color(0.6, 0.45, 1.0, 0.3))

func _blocked_x() -> float:
	return INF

func _tick(_d: float) -> void:
	player.modulate.a = 0.65 + 0.15 * sin(t * 2.0) - (0.25 if fmod(t, 7.0) < 0.12 else 0.0)
	if not met and player.position.x > 4000.0 and on_ground:
		met = true
		_cauchemar()

func _cauchemar() -> void:
	busy = true; vel = Vector2.ZERO; player.walking = false; player.facing = 1
	Game.music("")
	Game.sfx("thunder", 2.0, 0.4); Game.sfx("stone", 2.0, 0.4); shake = 24.0
	base_tint = Color(0.8, 0.6, 0.8)
	main.flash(Color(1, 0.2, 0.4, 0.6), 0.6)
	await say([
		["ilo", "Là ! Entre nous et les titans... Ce n'est pas un rêve. C'est un cauchemar."],
		["soldate", "Fait de quoi ?"],
		["ilo", "De tout ce qu'on leur a arraché. Chaque extraction, chaque foreuse, chaque Kevrê volé. Le Cauchemar Commun."],
		["gamin", "Alors c'est le dernier. Ensemble ?"],
		["soldate", "Ensemble."],
	])
	busy = true
	await wait(0.3)
	main.goto("battle", {"encounter": "cauchemar"})

func _titans() -> void:
	busy = true
	player.facing = 1
	base_tint = Color(1.0, 0.97, 0.9)
	Game.sfx("heal", 0.0, 0.3)
	main.flash(Color(1, 1, 1, 0.8), 1.0)
	await say([
		["", "Le Cauchemar se dissout. Pour la première fois depuis des siècles, les trois titans rêvent au même endroit, et regardent les trois humains."],
		["oiseau", "Petit rêve."],
		["tortue", "Enfant de l'orage."],
		["serpent", "Petit chanteur. Capitaine sans armée."],
		["oiseau", "Vous avez traversé nos trois rêves. Dites-nous, maintenant. Que doit devenir le monde ?"],
	])
	busy = true
	var listened := heard.size() == 3
	var opts := [
		{"title": "Bercer", "col": Color("7fe8c8"), "text": "Endormir les trois titans pour des siècles. Les Kevrês s'éteindront.\n\nLe Gamin survivra... mais il deviendra un enfant ordinaire."},
		{"title": "Éveiller", "col": Color("ff9a6a"), "text": "Laisser les titans se lever. Le monde changera de forme.\n\nLe Gamin retournera à l'Oiseau et deviendra sa voix."},
	]
	var accord_ok := Story.accord_available(Game.flags, heard.size())
	if accord_ok:
		opts.append({"title": "L'Accord", "col": Game.GOLD, "text": "Demander aux titans de se réveiller lentement et de poser le monde au sol.\n\nPossible seulement parce que vous les avez tous écoutés, et que vous n'avez pas toujours choisi pareil."})
	elif listened:
		await say([["ilo", "Ils nous écoutent... mais nos choix ont toujours penché du même côté. Ils ne croiront pas à un équilibre."]])
	else:
		await say([["ilo", "Nous n'avons pas écouté chacun d'eux. Ils ne nous laisseront choisir qu'entre les deux vieilles voies."]])
	busy = true
	var c := await choose("Que répond le Gamin aux trois titans ?", opts)
	busy = true
	if c != Story.FINAL_ACCORD:
		Game.flags["communion3"] = Story.final_communion(c)
	var ending := Story.ending_for(Game.flags, c)
	await _ending(ending)

func _ending(ending: String) -> void:
	busy = true
	ending_reached = ending
	Game.music("")
	match ending:
		"sommeil":
			await say([
				["gamin", "Dormez. Tous les trois. Et faites de beaux rêves, cette fois."],
				["oiseau", "Alors je te laisse partir, petit rêve. Vis. Vis à ma place."],
			])
			busy = true
			main.flash(Color(0.6, 1.0, 0.9, 0.7), 1.2)
			await show_art("fin_sommeil", [
				["", "Les titans se rendorment pour des siècles. Une à une, les lueurs de rêve s'éteignent dans l'air, et les Kevrês avec elles."],
				["gamin", "C'est bizarre. Je ne sens plus l'orage. Juste... le vent."],
				["soldate", "Le vent, c'est bien aussi. Ça ne te fait pas disparaître."],
				["ilo", "Pour la première fois de ma vie, personne n'a besoin que je chante. Je crois que je vais apprendre à pêcher."],
			], true)
			await _credits("Le Long Sommeil", "Le monde dort encore, pour longtemps. Le Gamin est un enfant comme les autres.")
		"reveil":
			await say([
				["gamin", "Réveillez-vous. Le monde est à vous aussi. Je... je n'ai pas peur."],
				["soldate", "Gamin, non...!"],
				["oiseau", "Reviens, petit rêve. Tu ne disparais pas. Tu deviens ma voix."],
			])
			busy = true
			main.flash(Color(1, 0.9, 0.6, 0.9), 1.2)
			Game.sfx("thunder", 4.0, 0.5)
			await show_art("fin_reveil", [
				["", "Les titans se lèvent, et le monde change de forme. Des continents montent vers le ciel, des cascades remontent les falaises."],
				["oiseau", "Capitaine. C'est moi. Je suis là, dans chaque orage. Protège-les pour moi."],
				["soldate", "... Toujours. Je te le promets."],
				["ilo", "Un monde nouveau. Il va falloir apprendre de nouvelles chansons."],
			], true)
			await _credits("Le Réveil", "Les titans marchent. Le Gamin est devenu la voix de l'Oiseau. La Soldate protège les survivants.")
		"accord":
			await say([
				["gamin", "Ne dormez pas pour toujours. Ne vous levez pas d'un coup. Réveillez-vous lentement... et posez le monde au sol. Doucement."],
				["tortue", "Poser mon fardeau... doucement. Oui."],
				["serpent", "Un lien, pas une chaîne. Les petits nous parleront ?"],
				["ilo", "Chaque jour. Je vous le jure. Plus de silence."],
				["oiseau", "Et toi, petit rêve ?"],
				["gamin", "Moi, je reste. À moitié rêve, à moitié humain. Comme un pont entre vous et nous."],
			])
			busy = true
			main.flash(Color(1, 0.95, 0.7, 0.9), 1.2)
			await show_art("fin_accord", [
				["", "Au lever du soleil, les trois titans descendent lentement et posent le monde au sol, sans briser une seule maison."],
				["", "Les Kevrês ne sont plus une ressource. Ils deviennent un lien, une conversation entre les titans et les humains."],
				["soldate", "Tu vois. Une troisième voie. Je t'avais dit qu'on l'inventerait."],
				["gamin", "Tu es vraiment têtue."],
				["soldate", "C'est la Pierre."],
			], true)
			await _credits("L'Accord", "La vraie fin. Les titans et les humains se parlent enfin. Le Gamin est resté.")

func _credits(name: String, line: String) -> void:
	await hide_art()
	var c := []
	for k in ["communion1", "communion2", "communion3"]:
		if Game.flags.has(k): c.append("Bercer" if Game.flags[k] == "bercer" else "Éveiller")
	if not Game.flags.has("communion3"): c.append("Accord")
	await end_card("KEVENFALL", "Fin  ·  " + name, [
		line,
		"Tes choix : Tortue %s  ·  Serpent %s  ·  Oiseau %s" % c,
		"Éclats de rêve trouvés : %d / %d" % [Game.shards, Game.SHARDS_TOTAL],
		"Un jeu original créé pour Kevin  ·  Merci d'avoir joué !",
	])
