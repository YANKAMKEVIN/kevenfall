extends Exploration
## Acte III, chapitre 10 : l'assaut sur la flotte d'Orsane, accrochée au Serpent.
## On joue la Soldate. Les canons tirent : une lueur rouge annonce les impacts.
## Au bout du vaisseau amiral, Orsane et ses trois Kevrês volés.

const CHECKPOINTS := [260.0, 1700.0, 3000.0]
var shots: Array = []
var next_shot := 2.0
var reached := false

func _config() -> Dictionary:
	return {
		"chapter": ["ACTE III  ·  CHAPITRE 10", "La flotte d'Orsane"],
		"level_w": 4500.0,
		"segments": [[-200.0, 1450.0], [1680.0, 2850.0], [3100.0, 4700.0]],
		"platforms": [Rect2(1490, 450, 150, 22), Rect2(2890, 450, 170, 22), Rect2(2200, 410, 130, 22)],
		"far": "fond_flotte", "far_y": -20.0, "far_h": 780.0,
		"tile": "tuile_navire", "tile_h": 300.0,
		"start_x": 260.0, "rain": 0.35, "flash_every": 0.6, "flash_power": 0.7,
		"tint": Color(0.8, 0.78, 0.95), "fog": 0.3, "fog_col": Color(0.6, 0.45, 0.8),
		"player_tex": "sprite_soldate", "player_h": 172.0, "player_native": 1, "speed_mul": 1.0,
		"follower": {"tex": "sprite_gamin", "h": 135.0, "native": 1},
		"props": [["centre_caisses", 650.0, 110.0], ["chaines", 1200.0, 160.0], ["centre_caisses", 2450.0, 120.0], ["chaines", 3500.0, 160.0]],
		"music": "music_battle",
		"hint": "← →  courir     Espace  sauter     Attention aux tirs de canon !     Échap  pause",
	}

func _setup() -> void:
	if not Game.flags.has("communion1"): Game.flags["communion1"] = "bercer"
	if not Game.flags.has("communion2"): Game.flags["communion2"] = "bercer"
	Game.flags["foudre2"] = true
	if args.get("after_battle", false):
		cfg["start_x"] = 3900.0

func _start() -> void:
	if args.get("after_battle", false):
		await _after()
		return
	await say([
		["soldate", "Le vaisseau amiral est au bout de cette ligne de navires. Orsane y est forcément."],
		["gamin", "Et Ilo ?"],
		["soldate", "Il retient les Spectres avec ses chants, derrière nous. Il nous rejoindra. Reste derrière moi et cours quand je cours."],
		["annonce", "Alerte ! Intrus sur la ligne d'amarrage ! Canons, feu à volonté !"],
	])
	toast("Fonce vers le vaisseau amiral. Une lueur rouge annonce les tirs de canon.", Color("ff9a8a"))

func _tick(delta: float) -> void:
	next_shot -= delta
	if next_shot <= 0.0 and player.position.x < 3950.0:
		next_shot = randf_range(0.9, 1.5)
		shots.append({"x": player.position.x + randf_range(-40.0, 380.0) * (1 if player.facing >= 0 else -1), "t": 1.0, "done": false})
	for s in shots.duplicate():
		s.t -= delta
		if s.t <= 0.0 and not s.done:
			s.done = true
			Game.sfx("stone", -2.0, 1.3); Game.sfx("hit", -4.0, 0.6); shake = maxf(shake, 10.0)
			fx.sparks(Vector2(s.x, GROUND_Y - 20), Color(1.0, 0.7, 0.3), 22)
			fx.ring(Vector2(s.x, GROUND_Y - 20), Color(1.0, 0.5, 0.3), 90.0, 0.4)
			if absf(player.position.x - s.x) < 55.0 and player.position.y > GROUND_Y - 120.0:
				_hit_shot()
		if s.t < -0.4: shots.erase(s)
	if not reached and player.position.x > 3950.0 and on_ground:
		reached = true
		_orsane()

func _hit_shot() -> void:
	busy = true
	main.flash(Color(1, 0.3, 0.2, 0.5), 0.4)
	toast("Touchée par un tir ! Retour au dernier abri.", Color("ff9a8a"))
	var cp: float = CHECKPOINTS[0]
	for c in CHECKPOINTS:
		if player.position.x > c + 100.0: cp = c
	await wait(0.4)
	player.position = Vector2(cp, GROUND_Y); vel = Vector2.ZERO
	if follower: follower.position.x = cp - 90.0
	cam.reset_smoothing(); shots.clear(); next_shot = 1.5
	busy = false

func _extra_glows(g: GlowLayer, tt: float) -> void:
	for s in shots:
		if s.done: continue
		var k: float = 1.0 - clampf(s.t, 0.0, 1.0)
		Game.draw_glow(g, Vector2(s.x, GROUND_Y - 10), 50 + 50 * k, Color(1.0, 0.25, 0.15, 0.25 + 0.45 * k))
		var y := lerpf(-60.0, GROUND_Y - 30.0, k * k)
		Game.draw_glow(g, Vector2(s.x - 200.0 * (1.0 - k), y), 35, Color(1.0, 0.7, 0.35, 0.9))
	for x in [800.0, 2300.0, 3700.0]:
		Game.draw_glow(g, Vector2(x + 200 * sin(tt * 0.7 + x), 140), 260, Color(1.0, 0.95, 0.75, 0.1))

func _orsane() -> void:
	busy = true; vel = Vector2.ZERO; player.walking = false; player.facing = 1
	shots.clear()
	Game.music("")
	var o := Actor.new().setup("sprite_orsane_boss", 200, -1)
	o.position = Vector2(player.position.x + 700, GROUND_Y); o.facing = -1; o.z_index = 2
	add_child(o)
	await walk_to(o, player.position.x + 260, 120.0)
	o.facing = -1
	await say([
		["orsane", "Capitaine. Vous êtes tenace. C'est pour cela que je vous avais choisie."],
		["soldate", "Arrêtez l'extraction, Orsane. Le Serpent peut parler. Les titans peuvent nous écouter !"],
		["orsane", "Des contes de prêtres. Moi, j'ai des chiffres. Dans quarante ans, le monde tombe. Ma flotte, elle, volera."],
		["orsane", "Et grâce à ces trois Kevrês, la Foudre, la Pierre et la Brume, plus personne ne pourra m'en empêcher."],
		["gamin", "Ce sont des rêves volés ! Rendez-les !"],
		["orsane", "Viens donc les reprendre, petit rêve."],
	])
	busy = true
	o.queue_free()
	await wait(0.2)
	main.flash(Color(0.85, 0.6, 1.0, 0.6), 0.5)
	main.goto("battle", {"encounter": "orsane"})

func _after() -> void:
	busy = true
	player.facing = 1
	var o := Actor.new().setup("sprite_orsane", 178, -1)
	o.position = Vector2(player.position.x + 240, GROUND_Y); o.facing = -1; o.z_index = 2
	o.rotation = 0.15; o.modulate = Color(0.85, 0.85, 0.9)
	add_child(o)
	var ilo := Actor.new().setup("sprite_ilo", 175, -1)
	ilo.position = Vector2(player.position.x - 260, GROUND_Y); ilo.facing = 1; ilo.z_index = 2
	add_child(ilo)
	await say([
		["orsane", "Vous croyez avoir gagné... Mais l'extraction est lancée. Même sans moi, les foreuses aspirent le Serpent."],
		["ilo", "Je suis là. J'ai entendu. Les chants ne retiennent plus rien : le Serpent se vide."],
	])
	busy = true
	# l'Oiseau se réveille
	Game.sfx("thunder", 4.0, 0.5); shake = 30.0
	main.flash(Color(1, 0.95, 0.6, 0.9), 1.0)
	base_tint = Color(1.0, 0.9, 0.7)
	await wait(0.8)
	await say([
		["oiseau", "......  QUI ......  M'APPELLE ......"],
		["ilo", "L'Oiseau d'Orage. L'extraction l'a réveillé. Tout au nord, le ciel se déchire."],
	])
	busy = true
	follower.modulate = Color(1.2, 1.2, 1.4, 0.55)
	var tw := create_tween().set_loops(3)
	tw.tween_property(follower, "modulate:a", 0.25, 0.25); tw.tween_property(follower, "modulate:a", 0.6, 0.25)
	await wait(1.6)
	await say([
		["gamin", "Capitaine... mes mains. Je vois à travers mes mains."],
		["soldate", "Non. Non, non, non. Reste avec moi, gamin. Ilo !"],
		["ilo", "Il s'efface. Il n'y a qu'un endroit où l'on peut encore tout arrêter : le Rêve Commun, là où les rêves des trois titans se mêlent."],
		["ilo", "Là-bas, ils nous entendront tous les trois en même temps. Si nous les avons écoutés, eux aussi."],
		["orsane", "... Si vous pouvez vraiment leur parler... alors parlez-leur."],
		["orsane", "J'avais raison sur le danger, Capitaine. Je crois... que j'avais tort sur la solution."],
		["soldate", "Gardez vos regrets pour plus tard, Chancelière. Ilo, emmène-nous."],
	])
	busy = true
	Game.sfx("heal", 0.0, 0.3)
	main.flash(Color(1, 1, 1, 1), 1.0)
	await wait(0.6)
	main.goto("explore", {"level": "ReveCommun"})
