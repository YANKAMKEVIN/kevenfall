extends "res://scripts/battle/BattleHeroes.gd"
## Combat, couche 4 : tour des ennemis, choix de la cible, dégâts reçus.

# ------------------------------------------------------------------ ennemis
func _enemy_turn(e: Dictionary) -> void:
	var prev := state
	state = "anim"
	menu_panel.visible = false
	await _enemy_act(e)
	e.atb = 0.0
	_hide_banner()
	await _check_end()
	if state == "end": return
	if prev == "menu" or prev == "target":
		if cur and cur.alive and cur.atb >= 100.0:
			_open_menu(cur)
		else:
			state = "run"
	else:
		state = "run"

func _enemy_act(e: Dictionary) -> void:
	var alive_h := _alive(heroes)
	if alive_h.is_empty(): return
	e.turns += 1
	if e.id == "golem":
		if e.charging:
			e.charging = false
			await _show_banner("Golem de l'Empire  ·  Éboulement !", 0.0)
			Game.sfx("stone", 4.0, 0.7); shake = 22.0
			for h in alive_h:
				fx.rocks(h.actor.position)
			await get_tree().create_timer(0.45).timeout
			for h in alive_h:
				_hurt(h, randi_range(13, 16))
			await get_tree().create_timer(0.7).timeout
		elif e.turns % 3 == 0:
			e.charging = true
			await _show_banner("Le Golem accumule une énergie instable...", 0.0)
			Game.sfx("stone", -6.0, 0.5)
			glow.burst(e.actor.position + Vector2(0, -150), Color(1.0, 0.3, 0.2, 0.8), 260.0)
			_float_text(e.actor.position + Vector2(0, -_height(e) - 40), "Défendez-vous !", Color("ff8a6a"), 24)
			await get_tree().create_timer(1.0).timeout
		else:
			var tg: Dictionary = _pick_target(alive_h)
			await _show_banner("Golem de l'Empire  ·  Coup de roc", 0.0)
			await _melee(e, _redirect(tg))
			Game.sfx("stone", 0.0, 1.1)
			_hurt(tg, randi_range(13, 16))
			await get_tree().create_timer(0.6).timeout
	elif e.id.begins_with("garde"):
		var tg: Dictionary = _pick_target(alive_h)
		if randf() < 0.25:
			await _show_banner("Garde impérial  ·  Lanterne aveuglante", 0.0)
			glow.burst(_redirect(tg).actor.position + Vector2(0, -100), Color(1.0, 0.85, 0.4, 0.9), 220.0)
			main.flash(Color(1, 0.9, 0.6, 0.35), 0.3)
			await get_tree().create_timer(0.3).timeout
			_hurt(tg, randi_range(4, 5))
			var real: Dictionary = _redirect(tg)
			if real.alive:
				real.atb = maxf(0.0, real.atb - 50.0); ready_q.erase(real)
				_float_text(real.actor.position + Vector2(0, -_height(real) - 70), "Ébloui", Game.GOLD, 22)
		else:
			await _show_banner("Garde impérial  ·  Coup de lance", 0.0)
			await _melee(e, _redirect(tg))
			_hurt(tg, randi_range(9, 12))
		await get_tree().create_timer(0.5).timeout
	elif e.id == "extracteur":
		if e.turns % 3 == 0:
			var tg: Dictionary = _f("gamin") if _f("gamin").alive else alive_h[0]
			await _show_banner("L'Extracteur  ·  Extraction !", 0.0)
			var real: Dictionary = _redirect(tg)
			fx.wave(e.actor.position + Vector2(-60, -150), real.actor.position + Vector2(0, -90))
			fx.wave(e.actor.position + Vector2(-60, -130), real.actor.position + Vector2(0, -70))
			Game.sfx("zap", -2.0, 0.5); Game.sfx("heal", -4.0, 0.4)
			await get_tree().create_timer(0.6).timeout
			_hurt(tg, randi_range(9, 11))
			if real.alive:
				var lost := mini(real.pr, 4)
				real.pr -= lost
				_float_text(real.actor.position + Vector2(0, -_height(real) - 70), "-%d Rêve" % lost, Game.CYAN, 24)
			e.hp = mini(e.max_hp, e.hp + 14)
			glow.burst(e.actor.position + Vector2(0, -140), Color(0.3, 0.9, 1.0, 0.8), 240.0)
			_float_text(e.actor.position + Vector2(0, -_height(e) - 40), "+14", Color("6bea8c"), 30)
			await get_tree().create_timer(0.7).timeout
		else:
			var tg: Dictionary = _pick_target(alive_h)
			await _show_banner("L'Extracteur  ·  Aiguilles", 0.0)
			await _melee(e, _redirect(tg))
			_hurt(tg, randi_range(11, 14))
			await get_tree().create_timer(0.5).timeout
	elif e.id == "orsane":
		var tg: Dictionary = _pick_target(alive_h)
		if e.phase == 0:
			if e.turns % 3 == 0:
				await _show_banner("Orsane  ·  Foudre volée : Tempête de l'Empire", 0.0)
				for h in alive_h:
					fx.bolt(Vector2(h.actor.position.x + randf_range(-80, 80), -40), h.actor.position + Vector2(0, -90), Game.GOLD)
				Game.sfx("zap", 2.0, 0.7); shake = 18.0; main.flash(Color(1, 0.9, 0.5, 0.4), 0.3)
				await get_tree().create_timer(0.3).timeout
				for h in alive_h: _hurt(h, randi_range(11, 14))
			else:
				await _show_banner("Orsane  ·  Foudre volée : Éclair", 0.0)
				await _bolt_at(_redirect(tg))
				_hurt(tg, randi_range(15, 18))
		elif e.phase == 1:
			if e.turns % 3 == 0:
				await _show_banner("Orsane  ·  Pierre volée : Écrasement", 0.0)
				Game.sfx("stone", 4.0, 0.6); shake = 24.0
				for h in alive_h: fx.rocks(h.actor.position)
				await get_tree().create_timer(0.45).timeout
				for h in alive_h: _hurt(h, randi_range(13, 16))
			else:
				await _show_banner("Orsane  ·  Gantelet de pierre", 0.0)
				await _melee(e, _redirect(tg))
				Game.sfx("stone", 0.0, 1.0)
				_hurt(tg, randi_range(16, 19))
		else:
			if e.turns % 2 == 0:
				await _show_banner("Orsane  ·  Brume volée : Extraction", 0.0)
				var real: Dictionary = _redirect(tg)
				fx.wave(e.actor.position + Vector2(-60, -150), real.actor.position + Vector2(0, -90))
				Game.sfx("heal", -2.0, 0.4)
				await get_tree().create_timer(0.5).timeout
				_hurt(tg, randi_range(12, 15))
				if real.alive:
					var lost := mini(real.pr, 4); real.pr -= lost
					_float_text(real.actor.position + Vector2(0, -_height(real) - 70), "-%d Rêve" % lost, Game.CYAN, 24)
				e.hp = mini(e.max_hp, e.hp + 12)
				_float_text(e.actor.position + Vector2(0, -_height(e) - 40), "+12", Color("6bea8c"), 28)
			else:
				await _show_banner("Orsane  ·  Lame de brume", 0.0)
				await _melee(e, _redirect(tg))
				_hurt(tg, randi_range(14, 17))
		await get_tree().create_timer(0.5).timeout
	elif e.id == "cauchemar":
		var ph: int = e.turns % 4
		if ph == 0:
			await _show_banner("Cauchemar Commun  ·  Cri des trois titans", 0.0)
			Game.sfx("thunder", 2.0, 0.5); Game.sfx("stone", 2.0, 0.5); shake = 26.0
			main.flash(Color(1, 0.2, 0.35, 0.5), 0.5)
			glow.burst(e.actor.position + Vector2(0, -200), Color(1.0, 0.25, 0.4, 0.9), 480.0)
			await get_tree().create_timer(0.4).timeout
			for h in alive_h: _hurt(h, randi_range(15, 18))
		elif ph == 2:
			await _show_banner("Cauchemar Commun  ·  Extraction", 0.0)
			for h in alive_h:
				fx.wave(e.actor.position + Vector2(-60, -200), h.actor.position + Vector2(0, -90))
			Game.sfx("heal", -2.0, 0.3)
			await get_tree().create_timer(0.5).timeout
			for h in alive_h:
				_hurt(h, randi_range(7, 9))
				var real: Dictionary = _redirect(h)
				if real.alive: real.pr = maxi(0, real.pr - 3)
			e.hp = mini(e.max_hp, e.hp + 20)
			_float_text(e.actor.position + Vector2(0, -_height(e) - 40), "+20", Color("6bea8c"), 30)
		else:
			var tg: Dictionary = _pick_target(alive_h)
			await _show_banner("Cauchemar Commun  ·  Griffe d'ombre", 0.0)
			await _melee(e, _redirect(tg))
			Game.sfx("slash", 0.0, 0.5)
			_hurt(tg, randi_range(17, 21))
		await get_tree().create_timer(0.5).timeout
	elif e.id == "gardien":
		var phase: int = e.turns % 4
		if phase == 1:
			await _show_banner("Gardien du Rêve  ·  Berceuse de pierre", 0.0)
			Game.sfx("heal", -2.0, 0.35)
			glow.burst(e.actor.position + Vector2(0, -180), Color(0.4, 0.9, 1.0, 0.8), 380.0)
			await get_tree().create_timer(0.5).timeout
			for h in alive_h:
				fx.wave(e.actor.position + Vector2(-60, -200), h.actor.position + Vector2(0, -90))
				_hurt(h, randi_range(4, 6))
				if h.alive and h.veil <= 0:
					h.atb = maxf(0.0, h.atb - 45.0); ready_q.erase(h)
					_float_text(h.actor.position + Vector2(0, -_height(h) - 70), "Somnolent", Color("9fe3ff"), 22)
			if not e.armor:
				e.armor = true
				_float_text(e.actor.position + Vector2(0, -_height(e) - 70), "La carapace se reforme", Game.CYAN, 24)
			await get_tree().create_timer(0.7).timeout
		elif phase == 0:
			await _show_banner("Gardien du Rêve  ·  Marée de rêve", 0.0)
			Game.sfx("stone", 2.0, 0.5); shake = 20.0
			main.flash(Color(0.4, 0.9, 1.0, 0.4), 0.4)
			for h in alive_h:
				fx.rocks(h.actor.position)
			await get_tree().create_timer(0.45).timeout
			for h in alive_h:
				_hurt(h, randi_range(10, 13))
			await get_tree().create_timer(0.7).timeout
		else:
			var tg: Dictionary = _pick_target(alive_h)
			await _show_banner("Gardien du Rêve  ·  Main de pierre", 0.0)
			await _melee(e, _redirect(tg))
			Game.sfx("stone", 0.0, 0.9)
			_hurt(tg, randi_range(14, 17))
			await get_tree().create_timer(0.5).timeout
	elif e.id == "noyau":
		var forets: int = _alive(enemies).filter(func(x): return x.id.begins_with("foret")).size()
		if e.turns % 3 == 0:
			await _show_banner("Noyau  ·  Surcharge de Kevrês !", 0.0)
			glow.burst(e.actor.position + Vector2(0, -160), Color(1.0, 0.3, 0.2, 0.9), 420.0)
			Game.sfx("zap", 2.0, 0.5); Game.sfx("thunder", -2.0, 0.8)
			await get_tree().create_timer(0.4).timeout
			for h in alive_h:
				fx.bolt(e.actor.position + Vector2(-40, -170), h.actor.position + Vector2(0, -90), Color("ff6b5e"))
			shake = 20.0; main.flash(Color(1, 0.3, 0.2, 0.4), 0.4)
			await get_tree().create_timer(0.2).timeout
			for h in alive_h:
				_hurt(h, randi_range(13, 16) if forets > 0 else randi_range(9, 11))
			await get_tree().create_timer(0.7).timeout
		else:
			var tg: Dictionary = _pick_target(alive_h)
			await _show_banner("Noyau  ·  Pointe de forage", 0.0)
			await _melee(e, _redirect(tg))
			Game.sfx("stone", 0.0, 1.3)
			_hurt(tg, randi_range(12, 15))
			await get_tree().create_timer(0.5).timeout
	elif e.id.begins_with("foret"):
		var tg: Dictionary = alive_h[randi() % alive_h.size()]
		await _show_banner("Foret  ·  Vrille", 0.0)
		await _melee(e, _redirect(tg))
		Game.sfx("slash", 0.0, 0.6)
		_hurt(tg, randi_range(8, 10))
		await get_tree().create_timer(0.4).timeout
	elif e.id.begins_with("rongeroc"):
		var tg: Dictionary = alive_h[randi() % alive_h.size()]
		if randf() < 0.2:
			await _show_banner("Rongeroc  ·  Mâchoires de pierre", 0.0)
			await _melee(e, _redirect(tg))
			Game.sfx("stone", -2.0, 1.3)
			_hurt(tg, randi_range(12, 14))
		else:
			await _show_banner("Rongeroc  ·  Griffes", 0.0)
			await _melee(e, _redirect(tg))
			_hurt(tg, randi_range(8, 11))
		await get_tree().create_timer(0.5).timeout
	elif e.id.begins_with("cauche"):
		var tg: Dictionary = alive_h[0]
		if randf() < 0.35:
			await _show_banner("Cauchemerle  ·  Étincelle noire", 0.0)
			fx.bolt(e.actor.position + Vector2(0, -60), tg.actor.position + Vector2(0, -90), Color("b08cff"))
			Game.sfx("zap", -6.0, 0.6)
			await get_tree().create_timer(0.3).timeout
			_hurt(tg, randi_range(7, 9))
		else:
			await _show_banner("Cauchemerle  ·  Coup de bec", 0.0)
			await _melee(e, tg)
			_hurt(tg, randi_range(5, 7))
		await get_tree().create_timer(0.5).timeout
	else:
		var tg: Dictionary = _pick_target(alive_h)
		if randf() < 0.3:
			await _show_banner("Spectre de brume  ·  Voile glacé", 0.0)
			fx.wave(e.actor.position + Vector2(0, -120), _redirect(tg).actor.position + Vector2(0, -90))
			Game.sfx("heal", -6.0, 0.5)
			await get_tree().create_timer(0.5).timeout
			_hurt(tg, randi_range(4, 6))
			var real: Dictionary = _redirect(tg)
			if real.alive:
				real.atb = 0.0; ready_q.erase(real)
				_float_text(real.actor.position + Vector2(0, -_height(real) - 70), "Jauge gelée", Game.CYAN, 22)
			await get_tree().create_timer(0.6).timeout
		else:
			await _show_banner("Spectre de brume  ·  Griffe froide", 0.0)
			await _melee(e, _redirect(tg))
			_hurt(tg, randi_range(8, 11))
			await get_tree().create_timer(0.5).timeout

## Applique des dégâts à un héros (avec Garde et Défense).
func _hurt(tg: Dictionary, base: int) -> void:
	var h: Dictionary = _redirect(tg)
	if not h.alive: return
	if h.veil > 0:
		h.veil -= 1
		if randf() < 0.5:
			_float_text(h.actor.position + Vector2(0, -_height(h) * 0.6), "Esquive", Color("b9a6ff"), 30)
			Game.sfx("heal", -12.0, 1.6)
			return
	var res := BattleRules.damage_to_hero(h, base, h != tg)
	var note: String = res.note
	if h != tg:
		Game.sfx("stone", -4.0, 1.4)
	if res.use_rempart:
		h.rempart -= 1
	var d: int = res.dmg
	h.hp = BattleRules.hp_after(h.hp, d)
	commun = minf(100.0, commun + 4.0)
	Game.sfx("hit", 0.0, 0.8)
	_flash_actor(h.actor)
	shake = maxf(shake, 8.0)
	main.flash(Color(1, 0.2, 0.2, 0.18), 0.25)
	_float_text(h.actor.position + Vector2(0, -_height(h) * 0.6), str(d), Color("ff8080"), 40)
	if note != "":
		_float_text(h.actor.position + Vector2(0, -_height(h) * 0.6 - 44), note, Game.STONE, 22)
	if h.hp <= 0: _kill(h)
