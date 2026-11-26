extends Exploration
## Acte III, chapitre 8 : la mer de brume. Le vieux bateau du culte s'échoue
## sur les îles-écailles du Serpent. Il faut avancer d'écaille en écaille en
## dissipant les Spectres à la Foudre, avant l'attaque d'un Spectre ancien.

var wisps: Array = []
var boat: Sprite2D
var reached := false
const CHECKPOINTS := [300.0, 1750.0, 3000.0]
const WISP_X := [1100.0, 1500.0, 2200.0, 2600.0, 3300.0, 3700.0]

func _config() -> Dictionary:
	return {
		"chapter": ["ACTE III  ·  CHAPITRE 8", "La mer de brume"],
		"level_w": 4500.0,
		"segments": [[-200.0, 1300.0], [1620.0, 2450.0], [2800.0, 4700.0]],
		"platforms": [Rect2(1350, 470, 110, 22), Rect2(1500, 430, 100, 22), Rect2(2500, 470, 110, 22), Rect2(2660, 430, 110, 22)],
		"far": "fond_brume", "far_y": -20.0, "far_h": 780.0,
		"tile": "tuile_ecaille", "tile_h": 300.0, "tile_top": 0.04,
		"start_x": 330.0, "rain": 0.0, "flash_every": 2.5, "flash_power": 0.3,
		"tint": Color(0.75, 0.75, 0.95), "fog": 0.55, "fog_col": Color(0.6, 0.5, 0.9),
		"follower": {"tex": "sprite_soldate", "h": 168.0, "native": 1},
		"npcs": [{"id": "ilo", "tex": "sprite_ilo", "h": 175.0, "x": 560.0, "face": -1, "native": -1}],
		"music": "music_explore",
		"revelins": 6,
		"hint": "← →  marcher     Espace  sauter     X  Foudre (dissipe les Spectres)     E  parler",
		"shards": [
			{"id": "s1", "pos": Vector2(1550, 330), "text": "Je rêve que je nage entre les étoiles. Quand je me retourne, la brume me suit comme une traîne. Les petits humains l'appellent la mer."},
			{"id": "s2", "pos": Vector2(2715, 330), "text": "Les chanteurs du temple venaient chaque soir. Ils ne chantaient pas pour m'endormir. Ils chantaient pour que je n'entende pas qu'ils savaient."},
		],
	}

func _setup() -> void:
	can_zap = true
	Game.flags["foudre2"] = true
	if not Game.flags.has("communion1"): Game.flags["communion1"] = "bercer"
	boat = _prop("bateau", 200.0, 230.0, 0, 40.0)
	for x in WISP_X:
		var w := Actor.new().setup("sprite_spectre", 120, -1)
		w.position = Vector2(x, GROUND_Y - 90); w.modulate = Color(0.8, 0.8, 1.2, 0.75); w.z_index = 4
		add_child(w)
		wisps.append({"a": w, "home": Vector2(x, GROUND_Y - 90), "alive": true})
	if args.get("after_battle", false):
		cfg["start_x"] = 4000.0
		for w in wisps: w.a.visible = false; w.alive = false
		npcs["ilo"].position.x = 4120.0

func _start() -> void:
	if args.get("after_battle", false):
		await _outro()
		return
	await title_cards([
		"ACTE III  ·  LE SERPENT DES MARÉES",
		"Le Serpent dort sous une mer de brume, entouré d'îles-écailles\net des temples du culte d'Ilo, presque tous abandonnés.",
		"Depuis que la Tortue s'est levée, ses cauchemars sont partout.",
	])
	await say([
		["ilo", "Fin du voyage en bateau. La brume est trop épaisse : il va falloir marcher d'écaille en écaille."],
		["soldate", "Marcher... sur le Serpent ?"],
		["ilo", "Il dort profondément. Ce sont ses cauchemars qui ne dorment pas. Les Spectres."],
		["gamin", "Ceux du pont ? Ma Foudre leur fait peur."],
		["ilo", "Alors éclaire notre route, petit éclair. Et ne te laisse pas toucher : leur froid te ramènerait en arrière."],
	])
	toast("X : Foudre. Dissipe les Spectres avant qu'ils ne te touchent.", Game.GOLD)

func _talk_to(k: String) -> void:
	if k == "ilo":
		await say([["ilo", "Mon temple est tout au bout. Le dernier. Je n'y suis pas retourné depuis... longtemps."]])

func _on_zap(from: Vector2, to: Vector2) -> void:
	for w in wisps:
		if not w.alive: continue
		var p: Vector2 = w.a.position
		var x0 := minf(from.x, to.x) - 40.0
		var x1 := maxf(from.x, to.x) + 40.0
		if p.x > x0 and p.x < x1 and absf(p.y - (from.y + 40)) < 160.0:
			w.alive = false
			fx.sparks(p, Color("b9a6ff"), 30)
			Game.sfx("heal", -4.0, 1.4)
			var tw := create_tween().set_parallel()
			tw.tween_property(w.a, "modulate", Color(3, 3, 3, 0), 0.6)
			tw.tween_property(w.a, "scale", Vector2(1.3, 0.7), 0.6)

func _tick(delta: float) -> void:
	for w in wisps:
		if not w.alive: continue
		var a: Actor = w.a
		var d: float = player.position.x - a.position.x
		if absf(d) < 520.0:
			a.position.x += signf(d) * 70.0 * delta
			a.position.y = lerpf(a.position.y, player.position.y - 80.0 + sin(t * 3.0 + w.home.x) * 20.0, delta * 1.5)
			a.facing = 1 if d > 0 else -1
		else:
			a.position.y = w.home.y + sin(t * 2.0 + w.home.x) * 18.0
		if a.position.distance_to(player.position + Vector2(0, -70)) < 60.0:
			_touched()
			return
	if not reached and player.position.x > 4000.0 and on_ground:
		reached = true
		_ambush()

func _touched() -> void:
	busy = true
	main.flash(Color(0.6, 0.5, 1.0, 0.5), 0.4)
	Game.sfx("heal", -2.0, 0.5)
	toast("Le froid du Spectre te repousse !", Color("b9a6ff"))
	var cp: float = CHECKPOINTS[0]
	for c in CHECKPOINTS:
		if player.position.x > c + 100.0: cp = c
	await wait(0.4)
	player.position = Vector2(cp, GROUND_Y); vel = Vector2.ZERO
	if follower: follower.position.x = cp - 90.0
	for w in wisps:
		if w.alive: w.a.position = w.home
	cam.reset_smoothing()
	busy = false

func _extra_glows(g: GlowLayer, tt: float) -> void:
	Game.draw_glow(g, player.position + Vector2(0, -70), 170 + 12 * sin(tt * 6.0), Color(1.0, 0.85, 0.45, 0.16))
	for w in wisps:
		if w.alive:
			Game.draw_glow(g, w.a.position + Vector2(0, -50), 110 + 10 * sin(tt * 4.0), Color(0.6, 0.45, 1.0, 0.35))

func _ambush() -> void:
	busy = true; vel = Vector2.ZERO; player.walking = false; player.facing = 1
	Game.music("")
	Game.sfx("heal", 0.0, 0.3)
	main.flash(Color(0.6, 0.5, 1.0, 0.5), 0.6)
	await say([
		["soldate", "La brume se referme derrière nous..."],
		["ilo", "Un Spectre ancien. Un très vieux cauchemar du Serpent. Il ne nous laissera pas passer."],
		["gamin", "Alors on passe quand même !"],
	])
	busy = true
	await wait(0.3)
	main.goto("battle", {"encounter": "brume"})

func _outro() -> void:
	busy = true
	await say([
		["ilo", "Regardez. Là-bas, au bout de la dernière écaille."],
		["gamin", "Des lumières... C'est ton temple ?"],
		["ilo", "Le dernier temple des Marées. Quelqu'un a rallumé les lanternes... ou alors c'est le Serpent qui nous attend."],
	])
	busy = true
	main.goto("explore", {"level": "Temple"})
