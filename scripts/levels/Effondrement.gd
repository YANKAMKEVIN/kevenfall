extends Exploration
## Acte II, chapitre 7 : la Grande Foreuse. La capitale s'effondre.
## Fuite sous une pluie de débris jusqu'au Noyau de la Foreuse, puis la Tortue se lève
## et Orsane part avec la flotte vers le Serpent. Fin de l'acte II.

const CHECKPOINTS := [260.0, 1800.0, 3250.0]
var debris: Array = []
var next_debris := 2.0
var tess_done := false
var reached := false
var noyau: Sprite2D
var hits := 0

func _config() -> Dictionary:
	return {
		"chapter": ["ACTE II  ·  CHAPITRE 7", "La Grande Foreuse"],
		"level_w": 4600.0,
		"segments": [[-200.0, 1500.0], [1720.0, 2950.0], [3180.0, 4800.0]],
		"platforms": [Rect2(1540, 470, 130, 22), Rect2(2990, 460, 140, 22), Rect2(2300, 420, 120, 22)],
		"far": "fond_effondrement", "far_y": -20.0, "far_h": 780.0,
		"tile": "tuile_metal", "tile_h": 330.0,
		"start_x": 260.0, "rain": 0.12, "flash_every": 0.5, "flash_power": 0.5,
		"tint": Color(1.0, 0.78, 0.78), "fog": 0.45, "fog_col": Color(0.9, 0.35, 0.3),
		"follower": {"tex": "sprite_soldate", "h": 168.0, "native": 1},
		"npcs": [{"id": "tess", "tex": "sprite_tess", "h": 150.0, "x": 2150.0, "face": -1}],
		"props": [["centre_caisses", 700.0, 110.0], ["centre_cuve", 1150.0, 220.0], ["centre_caisses", 2600.0, 120.0],
			["centre_cuve", 3600.0, 220.0], ["centre_caisses", 3900.0, 110.0]],
		"music": "music_battle",
		"hint": "← →  courir     Espace  sauter     Attention aux débris qui tombent !     Échap  pause",
	}

func _setup() -> void:
	can_zap = true
	if not Game.flags.has("communion1"): Game.flags["communion1"] = "bercer"
	Game.flags["foudre2"] = true
	noyau = _prop("sprite_noyau", 4380.0, 380.0, 0, 10.0)
	if noyau: noyau.modulate = Color(1.0, 0.75, 0.75)
	if args.get("after_battle", false):
		cfg["start_x"] = 4000.0
		if noyau: noyau.modulate = Color(0.3, 0.25, 0.3, 0.7)
		npcs["tess"].visible = false

func _start() -> void:
	if args.get("after_battle", false):
		await _finale()
		return
	shake = 14.0
	Game.sfx("stone", 4.0, 0.5)
	await say([
		["annonce", "Citoyens. Par ordre de la Chancelière, la Grande Foreuse est activée. Évacuez les quartiers bas. Gloire à la flotte."],
		["soldate", "Elle fore jusqu'au cœur de la Tortue. Elle va la tuer... ou la réveiller."],
		["ilo", "Les deux, Capitaine. Et la ville est sur son dos."],
		["gamin", "Alors on court. Jusqu'à la Foreuse !"],
	])
	toast("Fuis vers la Foreuse. Les débris qui tombent sont signalés par une lueur rouge.", Color("ff9a8a"))

func _talk_to(k: String) -> void:
	if k == "tess":
		await _tess()

func _tess() -> void:
	tess_done = true
	busy = true; vel = Vector2.ZERO; player.walking = false
	player.facing = 1
	await say([
		["tess", "Vous ?! Le gamin du pont... et la Capitaine. Les avis de recherche disaient que vous étiez morts."],
		["soldate", "Pas encore. Tess, la Foreuse : comment on l'arrête ?"],
		["tess", "Son Noyau. Tout au bout de la passerelle. Si vous le détruisez, le forage s'arrête. Mais il est blindé, et ses deux forets le protègent."],
		["tess", "Moi, j'emmène les gens des quartiers bas vers les ascenseurs. Quelqu'un doit le faire."],
		["gamin", "Merci, Tess. Fais attention à toi."],
		["tess", "C'est vous qui allez vers la grosse machine. Faites attention à vous."],
	])
	busy = true
	await walk_to(npcs["tess"], npcs["tess"].position.x - 600.0, 260.0)
	npcs["tess"].visible = false
	busy = false

func _tick(delta: float) -> void:
	if not tess_done and player.position.x > npcs["tess"].position.x - 160.0 and on_ground:
		_tess()
		return
	# pluie de débris
	next_debris -= delta
	if next_debris <= 0.0 and player.position.x < 4050.0:
		next_debris = randf_range(0.9, 1.6)
		var x := player.position.x + randf_range(-60.0, 420.0) * (1 if player.facing >= 0 else -1)
		_spawn_debris(x)
	for d in debris.duplicate():
		d.t -= delta
		if d.t <= 0.0 and not d.fallen:
			d.fallen = true
			Game.sfx("stone", -4.0, randf_range(0.8, 1.2)); shake = maxf(shake, 9.0)
			fx.rocks(Vector2(d.x, GROUND_Y))
			fx.sparks(Vector2(d.x, GROUND_Y - 20), Color(1.0, 0.6, 0.3), 14)
			if absf(player.position.x - d.x) < 55.0 and player.position.y > GROUND_Y - 120.0:
				_hit_by_debris()
		if d.t < -0.4:
			debris.erase(d)
	if not reached and player.position.x > 4060.0 and on_ground:
		reached = true
		_core()

func _spawn_debris(x: float) -> void:
	debris.append({"x": x, "t": 1.0, "fallen": false})

func _hit_by_debris() -> void:
	hits += 1
	main.flash(Color(1, 0.2, 0.15, 0.5), 0.4)
	var cp: float = CHECKPOINTS[0]
	for c in CHECKPOINTS:
		if player.position.x > c + 100.0: cp = c
	busy = true
	toast("Touché par un débris ! Retour au dernier passage sûr.", Color("ff9a8a"))
	await wait(0.4)
	player.position = Vector2(cp, GROUND_Y); vel = Vector2.ZERO
	if follower: follower.position.x = cp - 90.0
	cam.reset_smoothing()
	debris.clear()
	next_debris = 1.5
	busy = false

func _extra_glows(g: GlowLayer, tt: float) -> void:
	for d in debris:
		if d.fallen: continue
		var k: float = 1.0 - clampf(d.t, 0.0, 1.0)
		Game.draw_glow(g, Vector2(d.x, GROUND_Y - 10), 50 + 50 * k, Color(1.0, 0.25, 0.15, 0.25 + 0.4 * k))
		# le débris lui-même, qui tombe
		var y := lerpf(-60.0, GROUND_Y - 30.0, k * k)
		Game.draw_glow(g, Vector2(d.x, y), 40, Color(1.0, 0.55, 0.3, 0.8))
	if noyau:
		Game.draw_glow(g, Vector2(4380, GROUND_Y - 190), 320 + 30 * sin(tt * 5.0), Color(1.0, 0.3, 0.25, 0.3 if not args.get("after_battle", false) else 0.05))
	for x in [600.0, 1900.0, 3300.0]:
		Game.draw_glow(g, Vector2(x, 120), 420, Color(1.0, 0.25, 0.1, 0.12 + 0.06 * sin(tt * 4.0 + x)))

func _core() -> void:
	busy = true; vel = Vector2.ZERO; player.walking = false; player.facing = 1
	debris.clear()
	Game.music("")
	await say([
		["gamin", "Le voilà. Le Noyau de la Foreuse."],
		["orsane", "Capitaine. Vous arrivez trop tard. Comme toujours, vous arrivez trop tard."],
		["soldate", "Orsane ! Où êtes-vous ?!"],
		["orsane", "À bord de mon vaisseau amiral. La Tortue est perdue, de toute façon. J'emporte ce qu'elle avait de précieux : ses Kevrês."],
		["orsane", "Le Noyau vous dira adieu de ma part."],
		["ilo", "Il se réveille. Préparez-vous !"],
	])
	busy = true
	Game.sfx("zap", 0.0, 0.5); shake = 18.0
	main.flash(Color(1, 0.3, 0.2, 0.6), 0.5)
	await wait(0.4)
	main.goto("battle", {"encounter": "noyau"})

func _finale() -> void:
	busy = true
	player.facing = 1
	Game.music("")
	shake = 30.0
	Game.sfx("stone", 6.0, 0.35); Game.sfx("thunder", 0.0, 0.5)
	await say([
		["soldate", "Le forage s'est arrêté..."],
		["ilo", "Trop tard. Écoutez."],
		["tortue", "... JE ... ME ... LÈVE ..."],
	])
	busy = true
	main.flash(Color(1, 1, 1, 0.8), 0.8)
	Game.sfx("thunder", 2.0, 0.4)
	await show_art("tortue_leve", [
		["", "La Tortue-Montagne se soulève à moitié de la mer de nuages. Des quartiers entiers de la capitale glissent de sa carapace."],
		["orsane", "Regardez bien, Capitaine. Voilà ce qui arrive au monde quand les titans s'éveillent."],
		["orsane", "Le Serpent des Marées porte la plus grande réserve de Kevrês du monde. La flotte y sera avant vous."],
		["soldate", "Vous abandonnez votre propre capitale !"],
		["orsane", "Je sauve ceux qui peuvent l'être. Adieu, Capitaine."],
	], true)
	busy = true
	await say([
		["ilo", "Elle part vers le Serpent. Vers les temples de mon culte."],
		["gamin", "Si la Tortue s'est levée... est-ce que l'Oiseau va se réveiller, lui aussi ?"],
		["ilo", "Pas encore, petit éclair. Pas encore."],
		["soldate", "Alors on la suit. Il nous faut un bateau."],
		["ilo", "J'en connais un. Vieux, lent, et il fuit un peu. Il sera parfait."],
	])
	busy = true
	await hide_art()
	var choice: String = "Bercer" if Game.flags.get("communion1", "bercer") == "bercer" else "Éveiller"
	await end_card("KEVENFALL", "Fin de l'acte II  ·  La Tortue-Montagne", [
		"Prochain acte : le Serpent des Marées.",
		"Ton choix dans le rêve de la Tortue : %s" % choice,
		"Éclats de rêve trouvés : %d / %d" % [Game.shards, Game.SHARDS_TOTAL],
	], false)
	main.goto("explore", {"level": "Brume"})
