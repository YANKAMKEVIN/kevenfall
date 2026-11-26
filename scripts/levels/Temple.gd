extends Exploration
## Acte III, chapitre 9 : le dernier temple des Marées. On joue Ilo.
## Il lit les fresques de son culte, avoue ce que le culte a caché,
## puis vient la deuxième communion, avec le Serpent. La nuit, le Gamin
## avoue son secret à la Soldate.

var read := {}
var revealed := false

func _config() -> Dictionary:
	return {
		"chapter": ["ACTE III  ·  CHAPITRE 9", "Le dernier temple"],
		"level_w": 3900.0,
		"segments": [[-200.0, 4100.0]],
		"platforms": [],
		"far": "fond_temple", "far_y": -20.0, "far_h": 780.0,
		"tile": "tuile_temple", "tile_h": 300.0,
		"start_x": 260.0, "rain": 0.0, "flash_every": 99.0, "flash_power": 0.0,
		"tint": Color(0.78, 0.82, 1.0), "fog": 0.3, "fog_col": Color(0.5, 0.6, 0.95),
		"player_tex": "sprite_ilo", "player_h": 178.0, "player_native": -1, "speed_mul": 0.9,
		"follower": {"tex": "sprite_gamin", "h": 135.0, "native": 1},
		"npcs": [{"id": "soldate", "tex": "sprite_soldate", "h": 168.0, "x": 3300.0, "face": -1, "native": 1}],
		"props": [["temple_statue", 520.0, 260.0, 0], ["temple_brasero", 1500.0, 150.0, 1], ["temple_statue", 2300.0, 260.0, 0],
			["temple_brasero", 2900.0, 150.0, 1]],
		"objects": [
			{"id": "f1", "x": 900.0, "label": "Lire la fresque", "h": 230.0},
			{"id": "f2", "x": 1900.0, "label": "Lire la fresque", "h": 230.0},
			{"id": "f3", "x": 2600.0, "label": "Lire la fresque", "h": 230.0},
			{"id": "cloche", "x": 3600.0, "label": "Sonner la cloche", "h": 230.0},
		],
		"music": "music_explore",
		"hint": "← →  marcher     Espace  sauter     E  lire / parler     Échap  pause",
	}

func _setup() -> void:
	if not Game.flags.has("communion1"): Game.flags["communion1"] = "bercer"
	for x in [900.0, 1900.0, 2600.0]:
		_prop("temple_stele", x, 220.0, 1)
	_prop("temple_autel", 3600.0, 200.0, 1)

func _start() -> void:
	await say([
		["gamin", "Waouh... C'est immense. Et tout est mouillé."],
		["ilo", "Le dernier temple des Marées. J'y ai appris à chanter. J'y ai aussi appris à me taire."],
		["soldate", "Je monte la garde à l'autel. Faites vite, la flotte d'Orsane ne doit plus être loin."],
		["ilo", "Les fresques racontent l'histoire de mon culte. Viens, petit éclair. Il est temps que quelqu'un la lise en entier."],
	])

func _extra_glows(g: GlowLayer, tt: float) -> void:
	for o in cfg.objects:
		var on := not read.has(o.id)
		Game.draw_glow(g, Vector2(o.x, GROUND_Y - 130), 70 + 10 * sin(tt * 2.5), Color(0.6, 0.55, 1.0, 0.4 if on else 0.12))
	for x in [1500.0, 2900.0]:
		Game.draw_glow(g, Vector2(x, GROUND_Y - 150), 150 + 15 * sin(tt * 6.0 + x), Color(0.7, 0.45, 1.0, 0.4))
	for x in [400.0, 1300.0, 2200.0, 3100.0]:
		Game.draw_glow(g, Vector2(x, 60), 260, Color(0.5, 0.7, 1.0, 0.12))

func _talk_to(k: String) -> void:
	match k:
		"f1":
			read["f1"] = true
			await say([
				["", "La fresque montre trois titans endormis, l'Oiseau, la Tortue et le Serpent, et entre eux, de minuscules humains qui chantent."],
				["ilo", "« Les Rêveurs-Monde portent les vivants. Chantez, et ils dormiront. » C'est la première chose qu'on nous apprend."],
				["gamin", "Ça a l'air plutôt gentil."],
			])
		"f2":
			read["f2"] = true
			await say([
				["", "La deuxième fresque montre le Serpent qui ouvre la gueule. Des lignes de lumière sortent de sa bouche et vont vers les prêtres."],
				["gamin", "Il... il leur parle ?"],
				["ilo", "Oui. Cette fresque-là, on nous interdisait de la regarder."],
			])
		"f3":
			read["f3"] = true
			await say([
				["", "La dernière fresque est grattée, presque effacée. On devine des prêtres qui se bouchent les oreilles, et chantent plus fort."],
				["ilo", "Voilà la vérité de mon culte."],
			])
		"soldate":
			if read.size() < 3:
				await say([["soldate", "Rien en vue pour l'instant. Lis tes fresques, Ilo. Je veille."]])
			else:
				await say([["soldate", "La cloche est derrière moi. Si c'est pour réveiller un serpent géant... prévenez-moi avant."]])
		"cloche":
			if read.size() < 3:
				await say([["ilo", "Pas encore. Il faut d'abord que le petit éclair connaisse toute l'histoire."]])
			else:
				read["cloche"] = true
				await _revelation()

func _revelation() -> void:
	busy = true
	revealed = true
	player.facing = -1
	await say([
		["ilo", "Avant de sonner, je vous dois la vérité. À tous les deux."],
		["ilo", "Mon culte n'a jamais seulement bercé le Serpent. Nous savions que les titans peuvent parler. Qu'on peut leur répondre."],
		["ilo", "Et nous l'avons caché. Pendant des siècles. Parce qu'un titan qui dort, on le contrôle. Un titan qui parle, on doit l'écouter."],
		["soldate", "Vous saviez. Depuis le début. Et tu nous as laissés croire qu'il n'y avait que deux choix : les endormir ou les laisser tout détruire."],
		["ilo", "Oui. Je suis désolé, Capitaine. C'est pour ça que je suis le dernier. Les autres ont préféré oublier."],
		["gamin", "Mais alors... si les titans parlent, on peut leur demander ce qu'ils veulent, eux ?"],
		["ilo", "Si tous les trois nous écoutent en même temps, oui. Peut-être. Commençons par le Serpent."],
	])
	busy = true
	Game.sfx("pickup", 0.0, 0.4); Game.sfx("heal", 0.0, 0.3)
	shake = 10.0
	main.flash(Color(0.6, 0.5, 1.0, 0.6), 1.0)
	await wait(0.6)
	await show_art("serpent_communion", [
		["serpent", "... Tu es revenu, petit chanteur. Après tout ce temps à me boucher les oreilles."],
		["ilo", "Je suis revenu pour écouter, cette fois. Et pour te demander pardon."],
		["serpent", "La Tortue s'est levée. Je l'ai sentie. Et maintenant les vaisseaux de métal plantent leurs griffes dans mes écailles."],
		["serpent", "Dois-je replonger dans mon rêve le plus profond... ou ouvrir les yeux, et chasser ceux qui me blessent ?"],
	], true)
	var c := await choose("Que répond Ilo au Serpent ?", [
		{"title": "Bercer", "col": Color("7fe8c8"), "text": "Chanter une dernière fois la vieille berceuse, mais sans mentir. Le Serpent replonge dans son rêve.\n\nNouveau Kevrê d'Ilo :\nBerceuse (soin de l'équipe, endort les jauges ennemies)."},
		{"title": "Éveiller", "col": Color("ff9a6a"), "text": "Laisser le Serpent ouvrir les yeux et sentir sa colère contre la flotte.\n\nNouveau Kevrê d'Ilo :\nMarée noire (vole la jauge des ennemis pour l'équipe)."},
	])
	busy = true
	if c == 0:
		Game.flags["communion2"] = "bercer"
		await say([
			["ilo", "Dors, vieux Serpent. Mais cette fois, je resterai éveillé pour toi."],
			["serpent", "Une berceuse sans mensonge... Elle est plus douce que les autres."],
		])
		toast("Communion : Bercer  ·  Brume niveau 2 : Berceuse", Color("7fe8c8"))
	else:
		Game.flags["communion2"] = "eveiller"
		shake = 16.0; Game.sfx("thunder", -2.0, 0.6)
		await say([
			["ilo", "Ouvre les yeux, vieux Serpent. Regarde ce qu'ils te font. Je ne te ferai plus taire."],
			["serpent", "Enfin... Enfin quelqu'un me laisse voir. Prends ma marée, chanteur. Rends-leur ce qu'ils m'ont pris."],
		])
		toast("Communion : Éveiller  ·  Brume niveau 2 : Marée noire", Color("ff9a6a"))
	await hide_art()
	await wait(1.0)
	await _confession()

func _confession() -> void:
	busy = true
	await title_cards(["La nuit tombe sur le temple. Ilo chante doucement près de l'autel.\nSur les marches, le Gamin rejoint la Soldate."])
	base_tint = Color(0.5, 0.55, 0.85)
	var s: Actor = npcs["soldate"]
	player.visible = false
	player.position.x = s.position.x - 100.0; player.facing = 1
	follower.position = Vector2(s.position.x - 110.0, GROUND_Y); follower.facing = 1; s.facing = -1
	cam.reset_smoothing()
	await wait(0.6)
	await say([
		["gamin", "Capitaine... Je peux te dire un truc ? Un vrai truc."],
		["soldate", "Je ne suis plus capitaine. Vas-y."],
		["gamin", "Dans le rêve de la Tortue, j'ai vu l'Oiseau. Il m'a fabriqué. Je ne suis pas un porteur de Kevrê. Je suis un rêve de l'Oiseau."],
		["gamin", "Et si l'Oiseau se réveille... je disparais. Comme un rêve quand on se lève."],
		["soldate", "..."],
		["gamin", "Alors si on réveille les titans pour sauver le monde, moi je m'efface. Et si on les endort, tout recommencera un jour. Il faut choisir."],
		["soldate", "Non."],
		["gamin", "Quoi, non ?"],
		["soldate", "Non, je ne choisis pas. Ni le monde contre toi, ni toi contre le monde. On m'a appris toute ma vie qu'il fallait sacrifier quelqu'un. J'en ai assez."],
		["soldate", "On trouvera une troisième voie. Et si elle n'existe pas, on l'inventera."],
		["gamin", "... Tu es vraiment têtue."],
		["soldate", "C'est la Pierre. Dors, maintenant. Demain, on monte à l'assaut de la flotte."],
	])
	busy = true
	await wait(0.5)
	main.goto("explore", {"level": "Flotte"})
