extends "res://scripts/battle/BattleStage.gd"
## Combat, couche 3 : actions des héros (attaques, Foudre, attaques combinées) et dégâts infligés.

func _execute(cmd: String, target: Variant) -> void:
	state = "anim"; menu_panel.visible = false
	var h: Dictionary = cur
	ready_q.erase(h)
	h.defend = false
	for o in heroes:
		if o.guarded_by == h: o.guarded_by = null
	match cmd:
		"attack":
			await _show_banner(h.name + "  ·  Attaque", 0.0)
			await _melee(h, target)
			var r: Array = BattleRules.attack_range(h.id)
			var dmg: int = randi_range(r[0], r[1]) + h.get("atk_bonus", 0)
			await _hit(target, dmg, "phys")
		"eclair":
			h.pr -= 3
			await _show_banner("Le Gamin  ·  Kevrê de la Foudre : Éclair", 0.0)
			await _bolt(target)
			await _hit(target, randi_range(16, 20), "foudre")
		"chaine":
			h.pr -= 5
			await _show_banner("Le Gamin  ·  Foudre niveau 2 : Éclair chaîné", 0.0)
			var list := _alive(enemies)
			var prev: Vector2 = h.actor.position + Vector2(30, -100)
			Game.sfx("zap", 0.0, 0.9)
			for e in list:
				var p: Vector2 = e.actor.position + Vector2(0, -_height(e) * 0.5)
				fx.bolt(prev, p, Game.GOLD); fx.bolt(prev, p, Game.CYAN)
				fx.sparks(p, Game.GOLD, 16); glow.burst(p, Color(1, 0.85, 0.4, 0.8), 180.0)
				prev = p
				await get_tree().create_timer(0.12).timeout
			flash_v = 1.0; shake = 12.0
			main.flash(Color(1.0, 0.95, 0.7, 0.4), 0.3)
			for e in list:
				_hit(e, randi_range(11, 14), "foudre")
			await get_tree().create_timer(0.7).timeout
		"garde":
			h.pr -= 2
			await _show_banner("La Soldate  ·  Kevrê de la Pierre : Garde", 0.0)
			target.guarded_by = h
			Game.sfx("stone", -6.0, 1.3)
			fx.ring(target.actor.position + Vector2(0, -80), Color(1.0, 0.75, 0.35), 120.0, 0.6)
			_float_text(target.actor.position + Vector2(0, -_height(target) - 30), "Protégé", Game.STONE)
			await get_tree().create_timer(0.6).timeout
		"arc":
			h.pr -= 4
			await _show_banner("Le Gamin  ·  Bercer : Arc apaisant", 0.0)
			await _bolt(target)
			await _hit(target, int(randi_range(12, 14) * _m3()), "foudre")
			for e in _alive(enemies):
				e.slow = 10.0
				fx.ring(e.actor.position + Vector2(0, -_height(e) * 0.5), Color(0.6, 0.9, 1.0), 120.0, 0.9)
				_float_text(e.actor.position + Vector2(0, -_height(e) - 70), "Apaisé", Color("9fe3ff"), 22)
			await get_tree().create_timer(0.5).timeout
		"tempete":
			h.pr -= 5
			await _show_banner("Le Gamin  ·  Éveiller : Tempête", 0.0)
			world.modulate = Color(0.7, 0.7, 0.9)
			for k in 3:
				await _bolt(target)
			world.modulate = Color.WHITE
			await _hit(target, int(randi_range(30, 36) * _m3()), "foudre")
			if randf() < 0.35:
				h.overload = true
				_float_text(h.actor.position + Vector2(0, -_height(h) - 40), "Surcharge !", Color("ff8a6a"), 28)
				fx.sparks(h.actor.position + Vector2(0, -90), Game.GOLD, 30)
				await get_tree().create_timer(0.5).timeout
		"rempart":
			h.pr -= 4
			await _show_banner("La Soldate  ·  Bercer : Rempart", 0.0)
			Game.sfx("stone", 0.0, 0.8); shake = 10.0
			for o in _alive(heroes):
				o.rempart = 3 if Game.flags.get("niv3", false) else 2
				o.hp = mini(o.max_hp, o.hp + int(10 * _m3()))
				fx.ring(o.actor.position + Vector2(0, -90), Color(1.0, 0.8, 0.45), 130.0, 0.8)
				glow.burst(o.actor.position + Vector2(0, -90), Color(1.0, 0.75, 0.35, 0.6), 170.0)
				_float_text(o.actor.position + Vector2(0, -_height(o) - 30), "Rempart  +10", Game.STONE, 24)
			await get_tree().create_timer(0.8).timeout
		"seisme":
			h.pr -= 5
			await _show_banner("La Soldate  ·  Éveiller : Séisme", 0.0)
			var tw := create_tween(); tw.tween_property(h.actor, "position:y", h.home.y - 90, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(h.actor, "position:y", h.home.y, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			await tw.finished
			Game.sfx("stone", 6.0, 0.6); shake = 30.0
			main.flash(Color(1.0, 0.75, 0.4, 0.5), 0.4)
			fx.shockwave(Vector2(h.actor.position.x + 80, 555))
			for e in _alive(enemies):
				fx.rocks(e.actor.position)
			await get_tree().create_timer(0.4).timeout
			for e in _alive(enemies):
				_hit(e, int(randi_range(15, 18) * _m3()), "seisme")
				_break_armor(e)
			await get_tree().create_timer(0.8).timeout
		"berceuse":
			h.pr -= 4
			await _show_banner("Ilo  ·  Bercer : Berceuse", 0.0)
			Game.sfx("heal", 0.0, 0.6)
			for o in _alive(heroes):
				var hl := int(15 * _m3())
				o.hp = mini(o.max_hp, o.hp + hl)
				glow.burst(o.actor.position + Vector2(0, -90), Color(0.5, 0.95, 0.9, 0.6), 170.0)
				_float_text(o.actor.position + Vector2(0, -_height(o) - 30), "+%d" % hl, Color("6bea8c"), 30)
			for e in _alive(enemies):
				e.atb = maxf(0.0, e.atb - 35.0)
				fx.wave(h.actor.position + Vector2(20, -150), e.actor.position + Vector2(0, -_height(e) * 0.5))
				_float_text(e.actor.position + Vector2(0, -_height(e) - 70), "Endormi", Color("9fe3ff"), 22)
			await get_tree().create_timer(0.9).timeout
		"maree":
			h.pr -= 5
			await _show_banner("Ilo  ·  Éveiller : Marée noire", 0.0)
			Game.sfx("heal", -2.0, 0.3); shake = 12.0
			world.modulate = Color(0.55, 0.5, 0.75)
			var stolen := 0.0
			for e in _alive(enemies):
				stolen += minf(e.atb, 60.0)
				e.atb = maxf(0.0, e.atb - 60.0)
				fx.wave(e.actor.position + Vector2(0, -_height(e) * 0.5), h.actor.position + Vector2(0, -120))
				_hit(e, int(randi_range(8, 10) * _m3()), "combo")
			await get_tree().create_timer(0.5).timeout
			world.modulate = Color.WHITE
			for o in _alive(heroes):
				if o == h: continue
				o.atb = minf(100.0, o.atb + 25.0 + stolen * 0.2)
				if o.atb >= 100.0 and not ready_q.has(o): ready_q.append(o)
				_float_text(o.actor.position + Vector2(0, -_height(o) - 30), "Jauge +", Color("b9a6ff"), 24)
			await get_tree().create_timer(0.6).timeout
		"combo3":
			await _combo3()
		"voile":
			h.pr -= 3
			await _show_banner("Ilo  ·  Kevrê de la Brume : Voile", 0.0)
			Game.sfx("heal", -4.0, 0.7)
			for o in _alive(heroes):
				o.veil = 3
				glow.burst(o.actor.position + Vector2(0, -90), Color(0.6, 0.5, 1.0, 0.6), 160.0)
				fx.ring(o.actor.position + Vector2(0, -90), Color(0.7, 0.6, 1.0), 110.0, 0.8)
				_float_text(o.actor.position + Vector2(0, -_height(o) - 30), "Voile", Color("b9a6ff"), 24)
			await get_tree().create_timer(0.8).timeout
		"defend":
			h.defend = true
			h.pr = mini(h.max_pr, h.pr + 3)
			_float_text(h.actor.position + Vector2(0, -_height(h) - 30), "Défense  +3 Rêve", Game.CYAN)
			Game.sfx("heal", -10.0, 1.4)
			await get_tree().create_timer(0.6).timeout
		"combo":
			await _combo(pending.combo, h, pending.partner)
	if cmd != "combo3":
		h.atb = 0.0
		commun = minf(100.0, commun + 9.0)
	if h.get("overload", false):
		h.overload = false; h.atb = -70.0
	if cmd != "combo" and cmd != "combo3":
		h.pr = mini(h.max_pr, h.pr + 1)
	_hide_banner()
	await _check_end()
	if state != "end": state = "run"

func _melee(h: Dictionary, target: Dictionary) -> void:
	var a: Actor = h.actor
	var home: Vector2 = h.home
	var dest: Vector2 = target.actor.position + Vector2(-110 if h.hero else 110, 0)
	dest.y = home.y
	a.walking = true
	var tw := create_tween(); tw.tween_property(a, "position", dest, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished
	a.walking = false
	Game.sfx("slash", -2.0, randf_range(0.9, 1.1))
	fx.slash(target.actor.position + Vector2(0, -_height(target) * 0.55), h.hero)
	var tw2 := create_tween(); tw2.tween_interval(0.12)
	tw2.tween_property(a, "position", home, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(0.1).timeout

func _bolt(target: Dictionary) -> void:
	var g: Dictionary = _f("gamin")
	var tw := create_tween(); tw.tween_property(g.actor, "position:y", g.home.y - 30, 0.15)
	tw.tween_property(g.actor, "position:y", g.home.y, 0.2)
	await get_tree().create_timer(0.15).timeout
	Game.sfx("zap", 0.0)
	var p: Vector2 = target.actor.position + Vector2(0, -_height(target) * 0.5)
	fx.bolt(Vector2(p.x + randf_range(-60, 60), -40), p, Game.GOLD)
	fx.bolt(Vector2(p.x + randf_range(-60, 60), -40), p, Game.CYAN)
	fx.sparks(p, Game.GOLD, 26)
	glow.burst(p, Color(1.0, 0.85, 0.4, 0.9), 260.0)
	main.flash(Color(1.0, 0.95, 0.7, 0.45), 0.3)
	flash_v = 1.0; shake = 10.0
	await get_tree().create_timer(0.2).timeout

func _bolt_at(target: Dictionary) -> void:
	Game.sfx("zap", 0.0, 0.8)
	var p: Vector2 = target.actor.position + Vector2(0, -_height(target) * 0.5)
	fx.bolt(Vector2(p.x + randf_range(-60, 60), -40), p, Game.GOLD)
	fx.bolt(Vector2(p.x + randf_range(-60, 60), -40), p, Color("d9a6ff"))
	fx.sparks(p, Game.GOLD, 20)
	glow.burst(p, Color(1.0, 0.8, 0.4, 0.8), 200.0)
	main.flash(Color(1.0, 0.9, 0.7, 0.35), 0.3)
	flash_v = 1.0; shake = 10.0
	await get_tree().create_timer(0.25).timeout

func _combo(key: String, a: Dictionary, b: Dictionary) -> void:
	var c: Dictionary = COMBOS[key]
	ready_q.erase(a); ready_q.erase(b)
	for id in c.cost: _f(id).pr -= c.cost[id]
	await _show_banner("★  %s  ★   %s" % [c.name.to_upper(), c.pair], 0.0)
	main.flash(Color(1, 1, 1, 0.5), 0.4)
	match c.id:
		"onde": await _combo_onde()
		"sables": await _combo_sables()
		"orage": await _combo_orage()
	for e in _alive(enemies):
		if e.id in ["gardien", "orsane"]: _break_armor(e)
	a.atb = 0.0; b.atb = 0.0

func _combo3() -> void:
	var g: Dictionary = _f("gamin"); var s: Dictionary = _f("soldate"); var i: Dictionary = _f("ilo")
	commun = 0.0
	for h in heroes:
		ready_q.erase(h)
	await _show_banner("✦  RÊVE COMMUN  ✦   Foudre + Pierre + Brume", 0.0)
	main.flash(Color(1, 1, 1, 0.7), 0.6)
	Game.sfx("thunder", 2.0, 0.7)
	var tw := create_tween().set_parallel()
	for h in [g, s, i]:
		tw.tween_property(h.actor, "position:y", h.home.y - 120, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	for h in [g, s, i]:
		glow.burst(h.actor.position + Vector2(0, -100), h.col, 260.0)
		fx.ring(h.actor.position + Vector2(0, -100), h.col, 160.0, 1.0)
	await get_tree().create_timer(0.4).timeout
	world.modulate = Color(0.6, 0.6, 0.85)
	for k in 4:
		for e in _alive(enemies):
			var p: Vector2 = e.actor.position + Vector2(randf_range(-40, 40), -_height(e) * randf_range(0.3, 0.7))
			fx.bolt(Vector2(p.x + randf_range(-300, 300), -40), p, [Game.GOLD, Game.CYAN, Color("ffb3c8"), Color("b9a6ff")][k])
			fx.rocks(e.actor.position)
		Game.sfx("zap", 0.0, 0.7 + k * 0.1); Game.sfx("stone", 0.0, 0.6)
		shake = 24.0; flash_v = 1.0
		await get_tree().create_timer(0.18).timeout
	world.modulate = Color.WHITE
	main.flash(Color(1, 0.95, 0.8, 0.8), 0.6)
	fx.shockwave(Vector2(640, 555))
	glow.burst(Vector2(900, 400), Color(1, 0.9, 0.6, 0.8), 600.0)
	for e in _alive(enemies):
		_hit(e, randi_range(62, 72), "combo")
		_break_armor(e)
	var tw2 := create_tween().set_parallel()
	for h in [g, s, i]:
		tw2.tween_property(h.actor, "position:y", h.home.y, 0.4)
		h.atb = 0.0
	await get_tree().create_timer(1.0).timeout

func _break_armor(e: Dictionary) -> void:
	if not e.armor or not e.alive: return
	if e.id == "noyau" and (_f("foret0").alive or _f("foret1").alive):
		_float_text(e.actor.position + Vector2(0, -_height(e) - 70), "Blindage tenu par les forets", Color(0.8, 0.8, 0.85), 22)
		return
	e.armor = false; e.was_armored = true
	Game.sfx("stone", 0.0, 1.2)
	fx.sparks(e.actor.position + Vector2(0, -_height(e) * 0.5), Game.GOLD, 30)
	_float_text(e.actor.position + Vector2(0, -_height(e) - 70), "Armure brisée !", Game.GOLD, 30)

func _combo_onde() -> void:
	var g: Dictionary = _f("gamin"); var s: Dictionary = _f("soldate")
	var tw := create_tween().set_parallel()
	tw.tween_property(g.actor, "position:y", g.home.y - 150, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(s.actor, "position:x", s.home.x + 120, 0.25)
	await tw.finished
	Game.sfx("zap", 0.0, 0.8)
	glow.burst(g.actor.position + Vector2(0, -90), Color(1.0, 0.85, 0.35, 0.9), 200.0)
	fx.sparks(g.actor.position + Vector2(0, -90), Game.GOLD, 30)
	await get_tree().create_timer(0.25).timeout
	var tw2 := create_tween(); tw2.tween_property(g.actor, "position:y", g.home.y, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw2.finished
	Game.sfx("stone", 4.0, 0.8); Game.sfx("thunder", -2.0, 1.2)
	shake = 26.0; flash_v = 1.0
	main.flash(Color(1.0, 0.9, 0.6, 0.6), 0.5)
	fx.shockwave(Vector2(s.actor.position.x + 60, 555))
	glow.burst(Vector2(700, 520), Color(1.0, 0.7, 0.3, 0.7), 420.0)
	for e in _alive(enemies):
		fx.bolt(Vector2(e.actor.position.x, -40), e.actor.position + Vector2(0, -_height(e) * 0.5), Game.CYAN)
	await get_tree().create_timer(0.35).timeout
	for e in _alive(enemies):
		_hit(e, randi_range(24, 28), "combo")
		_break_armor(e)
		if e.id.begins_with("spectre"):
			e.atb = 0.0
			_float_text(e.actor.position + Vector2(0, -_height(e) - 70), "Jauge vidée", Game.CYAN, 22)
	var tw3 := create_tween(); tw3.tween_property(s.actor, "position:x", s.home.x, 0.4)
	await get_tree().create_timer(0.9).timeout

func _combo_sables() -> void:
	var s: Dictionary = _f("soldate"); var i: Dictionary = _f("ilo")
	var tw := create_tween().set_parallel()
	tw.tween_property(s.actor, "position:x", s.home.x + 100, 0.25)
	tw.tween_property(i.actor, "position:y", i.home.y - 40, 0.3)
	await tw.finished
	Game.sfx("stone", 2.0, 0.6); Game.sfx("heal", -2.0, 0.5)
	shake = 18.0
	for e in _alive(enemies):
		fx.ring(e.actor.position + Vector2(0, -10), Color(0.85, 0.7, 0.45), 140.0, 0.9)
		glow.burst(e.actor.position + Vector2(0, -20), Color(0.6, 0.45, 0.9, 0.7), 220.0)
		var sink := create_tween(); sink.tween_property(e.actor, "position:y", e.home.y + 25, 0.3)
		sink.tween_property(e.actor, "position:y", e.home.y, 0.6)
	await get_tree().create_timer(0.4).timeout
	for e in _alive(enemies):
		_hit(e, randi_range(15, 18), "combo")
		e.slow = 9.0
		_float_text(e.actor.position + Vector2(0, -_height(e) - 70), "Ralenti", Color("d9b98a"), 24)
	var tw2 := create_tween().set_parallel()
	tw2.tween_property(s.actor, "position:x", s.home.x, 0.4); tw2.tween_property(i.actor, "position:y", i.home.y, 0.4)
	await get_tree().create_timer(0.9).timeout

func _combo_orage() -> void:
	Game.sfx("heal", -2.0, 0.4)
	for k in 3:
		glow.burst(Vector2(randf_range(700, 1150), randf_range(300, 480)), Color(0.55, 0.45, 0.95, 0.6), 300.0)
	world.modulate = Color(0.6, 0.55, 0.85)
	await get_tree().create_timer(0.5).timeout
	for k in 3:
		for e in _alive(enemies):
			var p: Vector2 = e.actor.position + Vector2(randf_range(-30, 30), -_height(e) * randf_range(0.3, 0.7))
			fx.bolt(Vector2(p.x + randf_range(-200, 200), randf_range(250, 420)), p, Game.CYAN if k % 2 else Game.GOLD)
		Game.sfx("zap", -2.0, 0.8 + k * 0.15)
		flash_v = 1.0; shake = 14.0
		await get_tree().create_timer(0.15).timeout
	world.modulate = Color.WHITE
	main.flash(Color(0.8, 0.85, 1.0, 0.6), 0.4)
	for e in _alive(enemies):
		_hit(e, randi_range(20, 24), "orage")
		e.atb = 0.0
		_float_text(e.actor.position + Vector2(0, -_height(e) - 70), "Jauge vidée", Game.CYAN, 22)
	await get_tree().create_timer(0.9).timeout

## Applique des dégâts à un ennemi.
func _hit(e: Dictionary, base: int, kind: String) -> void:
	if not e.alive: return
	var dodge := BattleRules.dodge_chance(e, kind)
	if dodge > 0.0 and randf() < dodge:
		_float_text(e.actor.position + Vector2(0, -_height(e) * 0.6), "Esquive", Color(0.75, 0.75, 0.9), 30)
		Game.sfx("cancel", -10.0, 0.7)
		var tw := create_tween(); tw.tween_property(e.actor, "position:x", e.home.x + 50, 0.12)
		tw.tween_property(e.actor, "position:x", e.home.x, 0.25)
		await get_tree().create_timer(0.5).timeout
		return
	var res := BattleRules.damage_to_enemy(e, base, kind)
	var note: String = res.note
	var col := Color.WHITE
	if res.tone == "weak": col = Game.GOLD
	elif res.tone == "resist": col = Color(0.7, 0.7, 0.75)
	if res.armor_hint and not armor_hint_done:
		armor_hint_done = true
		_tip("Cette carapace encaisse les coups. Utilise les Kevrês ou une attaque combinée pour la briser !")
	var d: int = res.dmg
	e.hp = BattleRules.hp_after(e.hp, d)
	Game.sfx("hit", -2.0, randf_range(0.85, 1.15))
	_flash_actor(e.actor)
	var kb := create_tween(); kb.tween_property(e.actor, "position:x", e.home.x + 18, 0.06)
	kb.tween_property(e.actor, "position:x", e.home.x, 0.2)
	shake = maxf(shake, 6.0)
	_float_text(e.actor.position + Vector2(randf_range(-20, 20), -_height(e) * 0.6), str(d), col, 44)
	if note != "":
		_float_text(e.actor.position + Vector2(0, -_height(e) * 0.6 - 46), note, col, 22)
	if e.id == "orsane" and e.hp > 0:
		_orsane_phase(e)
	if e.hp <= 0:
		_kill(e)
	await get_tree().create_timer(0.55).timeout

func _orsane_phase(e: Dictionary) -> void:
	var want := BattleRules.orsane_phase(e.hp, e.max_hp)
	if want <= e.phase: return
	e.phase = want
	if want == 1:
		e.armor = true
		_float_text(e.actor.position + Vector2(0, -_height(e) - 90), "Pierre volée : armure !", Color("ffb3a0"), 30)
		Game.sfx("stone", 2.0, 0.7); shake = 16.0
		e.actor.modulate = Color(1.2, 0.95, 0.85)
		_tip("Orsane utilise la Pierre volée : son armure encaisse les coups. Séisme, Onde de choc ou une attaque combinée la brisent.")
	else:
		e.armor = false
		_float_text(e.actor.position + Vector2(0, -_height(e) - 90), "Brume volée : elle esquive !", Color("b9a6ff"), 30)
		Game.sfx("heal", 0.0, 0.4)
		e.actor.modulate = Color(0.85, 0.85, 1.2, 0.85)
		_tip("Orsane se cache dans la Brume volée : les attaques simples ratent souvent. Les Kevrês et les attaques combinées touchent toujours.")
