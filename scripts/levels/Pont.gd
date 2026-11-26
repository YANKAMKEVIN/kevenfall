extends Exploration
## Chapitre 3 : le Pont de l'Oiseau. Le convoi fait halte avant de passer sur la Tortue.

var golem_static: Sprite2D
var cutscene_done := false

func _config() -> Dictionary:
	return {
		"chapter": ["ACTE I  ·  CHAPITRE 3", "Le Pont de l'Oiseau"],
		"level_w": 4300.0,
		"segments": [[-200.0, 1480.0], [1640.0, 2560.0], [2720.0, 4500.0]],
		"platforms": [Rect2(1760, 455, 130, 22), Rect2(1905, 375, 130, 22), Rect2(2880, 450, 120, 22), Rect2(3010, 365, 120, 22)],
		"far": "fond_lointain", "tile": "tuile_pont",
		"start_x": 260.0, "revelins": 9,
		"props": [["camp_chariot", 330.0, 250.0], ["camp_feu", 720.0, 92.0], ["camp_lanterne", 1330.0, 200.0]],
		"npcs": [
			{"id": "soldate", "tex": "sprite_soldate", "h": 175.0, "x": 800.0, "face": -1, "native": 1},
			{"id": "brann", "tex": "sprite_brann", "h": 165.0, "x": 1220.0, "face": -1},
			{"id": "tess", "tex": "sprite_tess", "h": 150.0, "x": 3600.0, "face": -1},
		],
		"shards": [
			{"id": "p1", "pos": Vector2(1970, 320), "text": "Je vole depuis si longtemps que j'ai oublié le sol. Sur mes ailes, de petites lumières se sont allumées. Des maisons. Des voix."},
			{"id": "p2", "pos": Vector2(2640, 410), "text": "Un rêve s'est détaché de moi cette nuit. Il avait des cheveux blancs, et il riait comme le tonnerre."},
			{"id": "p3", "pos": Vector2(3070, 310), "text": "Ils creusent la Tortue. Je sens sa douleur à travers les nuages. Si elle s'éveille... je m'éveillerai aussi."},
		],
		"glows": [
			[Vector2(720, GROUND_Y - 25), 160.0, Color(1.0, 0.55, 0.2, 0.55)],
			[Vector2(1365, GROUND_Y - 165), 90.0, Color(1.0, 0.8, 0.35, 0.5)],
			[Vector2(3850, GROUND_Y - 130), 160.0, Color(0.3, 0.9, 1.0, 0.18)],
		],
	}

func _setup() -> void:
	npcs["tess"].set_meta("mute", true)
	golem_static = _prop("chaines", 3850.0, 300.0, 1, 30.0)

func _start() -> void:
	await say([
		["gamin", "Ces entraves me grattent les poignets... Et la Capitaine ne m'a pas quitté des yeux depuis le village."],
		["gamin", "Bon. Si je ne peux pas m'enfuir, au moins je peux me dégourdir les jambes."],
	])

func _extra_glows(g: GlowLayer, tt: float) -> void:
	var fl := 0.85 + 0.15 * sin(tt * 13.0)
	Game.draw_glow(g, npcs["brann"].position + Vector2(-45, -60), 70 * fl, Color(1.0, 0.75, 0.3, 0.5))

func _talk_to(k: String) -> void:
	match k:
		"soldate":
			if not Game.talked_soldate:
				await say([
					["soldate", "Tu as fini de tourner en rond ? On repart à l'aube."],
					["gamin", "Je tourne pas en rond. Je compte les étoiles. Il y en a moins qu'au village."],
					["soldate", "C'est l'orage. Ici, entre l'Oiseau et la Tortue, il ne s'arrête jamais."],
					["gamin", "Pourquoi l'Empire veut mes éclairs ? Ils font même pas mal. Enfin... pas beaucoup."],
					["soldate", "Ce qu'il y a en toi peut faire voler une flotte entière. De quoi mettre des milliers de gens à l'abri."],
					["gamin", "Et moi, on me met à l'abri où ?"],
					["soldate", "..."],
					["soldate", "Va te dégourdir les jambes. Pas plus loin que le Golem de Tess. Brann te laissera passer."],
				])
				Game.talked_soldate = true
			else:
				await say([["soldate", "Le pont craque depuis tout à l'heure. Reste là où je peux te voir."]])
		"brann":
			if not Game.talked_soldate:
				await say([["brann", "Halte, petit. La Capitaine veut te parler avant que tu ailles traîner où que ce soit."]])
			else:
				await say([
					["brann", "La Capitaine est d'accord ? Alors file. Mais ne t'approche pas trop du bord."],
					["brann", "Ma femme dit que les orages, c'est les titans qui ronflent. Moi, je crois qu'ils font des cauchemars."],
				])
				if npcs["brann"].position.x > 1100:
					await walk_to(npcs["brann"], 1060.0)
					npcs["brann"].facing = 1

func _blocked_x() -> float:
	return INF if Game.talked_soldate else npcs["brann"].position.x - 60.0

func _tick(_d: float) -> void:
	if not Game.talked_soldate and player.position.x >= npcs["brann"].position.x - 62.0:
		player.position.x = npcs["brann"].position.x - 70.0
		vel.x = 0
		talk("brann")
		return
	if not cutscene_done and player.position.x > 3380.0 and on_ground:
		cutscene_done = true
		_attack_cutscene()

func _attack_cutscene() -> void:
	busy = true; vel = Vector2.ZERO; player.walking = false
	player.facing = 1
	await say([
		["tess", "Hé ! Toi, le porteur ! Ne t'approche pas, il est nerveux ce soir."],
		["gamin", "C'est un Golem ? On dirait qu'il respire..."],
		["tess", "Un fragment de la Tortue, taillé et enchaîné. Il n'est pas censé respirer. Ni rêver."],
	])
	busy = true
	Game.sfx("stone", 0.0, 0.6); Game.sfx("thunder", -2.0, 0.7)
	shake = 18.0; flash_v = 1.0
	await wait(0.8)
	await say([["tess", "Qu'est-ce que... Les runes s'emballent ! Il se réveille !"]])
	busy = true
	Game.music("")
	if golem_static:
		var tw := create_tween()
		for i in 6:
			tw.tween_property(golem_static, "position:x", 3850.0 + (8 if i % 2 == 0 else -8), 0.06)
		tw.tween_property(golem_static, "modulate", Color(1.6, 0.6, 0.6), 0.3)
		await tw.finished
	Game.sfx("stone", 2.0, 0.5); shake = 26.0
	main.flash(Color(1, 0.3, 0.3, 0.5), 0.5)
	var tw2 := create_tween()
	tw2.tween_method(func(v): fog_mat.set_shader_parameter("density", v), 0.35, 1.0, 2.0)
	await walk_to(npcs["tess"], 3300.0, 300.0)
	await say([["gamin", "Il y a quelque chose dans la brume... !"]])
	busy = true
	var s: Actor = npcs["soldate"]
	s.position.x = player.position.x - 700.0
	await walk_to(s, player.position.x - 110.0, 700.0)
	player.facing = -1
	await say([
		["soldate", "Recule, gamin ! Tess, évacue l'escouade !"],
		["soldate", "Tends tes poignets. Je t'enlève une entrave. Une seule. Ne me fais pas regretter."],
		["gamin", "Enfin ! Je vais te montrer ce que fait un vrai orage."],
	])
	busy = true
	Game.sfx("zap", -2.0)
	main.flash(Color(1.0, 0.85, 0.35, 0.8), 0.6)
	await wait(0.5)
	main.goto("battle", {"encounter": "pont"})
