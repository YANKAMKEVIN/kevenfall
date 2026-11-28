extends "res://tools/bot/BotBase.gd"
## Robot de parcours, couche 2 : actes I et II (chapitres 1 à 5).

func _act1() -> void:
	# --- Chapitre 1
	Game.reset()
	auto_dialogue = false
	main.goto("explore", {"level": "Village"})
	await _wait(6.5)
	await shot("02_intro")
	auto_dialogue = true
	await _until(func(): return _cur().get("busy") == false, 40)
	var v: Variant = _cur()
	await shot("03_village")
	v.player.position.x = 620; v.cam.reset_smoothing()
	await _wait(0.5)
	auto_dialogue = false
	v.talk("sauge")
	await _wait(1.5)
	await shot("04_mame_sauge")
	auto_dialogue = true
	await _until(func(): return v.busy == false, 30)
	# paratonnerres 1 et 2
	for x in [1320.0, 2580.0]:
		v.player.position = Vector2(x, 540); v.player.facing = 1; v.cam.reset_smoothing()
		await _wait(0.6)
		await press("zap")
		await _wait(0.25)
		if x == 1320.0: await shot("05_foudre_paratonnerre")
		await _wait(1.0)
	v.player.position = Vector2(2400, 365); v.cam.reset_smoothing()
	await _wait(2.0)
	await _until(func(): return v.busy == false, 20)
	v.player.position = Vector2(3150, 540); v.cam.reset_smoothing()
	await _wait(1.0)
	await shot("06_cauchemerles")
	v.player.position.x = 3300
	await _until(func(): return _cur().get("encounter") != null, 20)
	await _wait(3.0)
	await shot("07_combat_village")
	await _until(func(): return _cur().get("state") == "end", 90)
	await _wait(4.0)
	await shot("08_victoire_village")
	await press("ui_accept")
	await _until(func(): return _cur().get("level_w") != null, 20)
	await _wait(1.0)
	await _until(func(): return _cur().busy == false, 20)
	v = _cur()
	v.player.position = Vector2(4000, 540); v.player.facing = 1; v.cam.reset_smoothing()
	await _wait(0.6)
	await press("zap")
	await _wait(9.0)
	await shot("09_foreuse")
	var vid: int = v.get_instance_id()
	await _until(func(): return _cur().get_instance_id() != vid and _cur().get("guards") != null, 90)
	# --- Chapitre 2
	await _wait(1.0)
	await _until(func(): return _cur().busy == false, 30)
	var cv: Variant = _cur()
	cv.player.position.x = 600; cv.cam.reset_smoothing()
	await _wait(1.5)
	await shot("10_convoi")
	cv.player.position.x = 700; cv.crouching = true
	auto_dialogue = false
	# se faire attraper
	cv.player.position.x = cv.guards[0].actor.position.x + 120 * cv.guards[0].actor.facing
	await _until(func(): return cv.dialogue.active, 10)
	await _wait(1.2)
	await shot("11_attrape")
	auto_dialogue = true
	await _until(func(): return cv.busy == false, 30)
	cv.player.position.x = 3440; cv.cam.reset_smoothing()
	await _wait(3.0)
	await shot("12_feu_de_camp")
	var cvid: int = cv.get_instance_id()
	await _until(func(): return _cur().get_instance_id() != cvid, 90)
	# --- Chapitre 3
	await _wait(1.0)
	await _until(func(): return _cur().get("cutscene_done") != null and _cur().busy == false, 30)
	var p: Variant = _cur()
	p.player.position.x = 700; p.cam.reset_smoothing()
	p.talk("soldate")
	await _until(func(): return p.busy == false, 30)
	p.player.position.x = 3390
	await _until(func(): return _cur().get("encounter") != null, 90)
	await _wait(3.0)
	await shot("13_combat_pont")
	await _until(func(): return _cur().get("state") == "anim" and _cur().banner.text.contains("ONDE"), 120, true)
	await _wait(1.3)
	await shot("14_onde_de_choc")
	await _until(func(): return _cur().get("state") == "end", 180)
	await _wait(4.5)
	await shot("15_victoire")
	var b: Variant = _cur()
	print("BATTLE hp: ", b._f("gamin").hp, " / ", b._f("soldate").hp)
	await press("ui_accept")
	await _until(func(): return _cur().get("encounter") == null and _cur().has_method("_end_card"), 20)
	await _wait(14.0)
	await shot("16_fin")
	await press("ui_accept")
	await _until(func(): return _cur().get("read") != null, 60)

func _act2() -> void:
	# --- Chapitre 4 : le centre d'extraction
	await _until(func(): return _cur().get("read") != null, 30)
	auto_dialogue = false
	await _wait(5.0)
	await shot("17_acte2")
	auto_dialogue = true
	await _until(func(): return _cur().busy == false, 60)
	var c: Variant = _cur()
	c.player.position.x = 700; c.cam.reset_smoothing()
	await _wait(1.5)
	await shot("18_centre")
	for k in ["r1", "r2", "r3"]:
		var o: Variant = null
		for ob in c.cfg.objects:
			if ob.id == k: o = ob
		c.player.position.x = o.x - 60; c.cam.reset_smoothing()
		await _wait(0.4)
		if k == "r2": auto_dialogue = false
		c.talk(k)
		if k == "r2":
			await _wait(1.5)
			await shot("19_rapport")
			auto_dialogue = true
		if k != "r3": await _until(func(): return c.busy == false and not c.dialogue.active, 40)
	# Orsane se déclenche après le 3e rapport
	await _until(func(): return c.dialogue.active and c.dialogue.lines.size() > 0 and c.dialogue.lines[0][0] == "orsane", 90)
	auto_dialogue = false
	await _wait(1.5)
	await shot("20_orsane")
	auto_dialogue = true
	await _until(func(): return c.orsane_done and c.busy == false, 90)
	c.player.position.x = 3820
	await _until(func(): return _cur().get("encounter") != null, 90)
	await _wait(3.0)
	await shot("21_combat_extracteur")
	await _until(func(): return _cur().get("state") == "end", 240)
	await _wait(4.0)
	await shot("22_victoire_centre")
	await press("ui_accept")
	# --- Chapitre 5 : les mines
	await _until(func(): return _cur().get("crystal_nodes") != null, 30)
	await _wait(1.0)
	await _until(func(): return _cur().busy == false, 60)
	var m: Variant = _cur()
	m.player.position.x = 500; m.cam.reset_smoothing()
	await _wait(1.0)
	await shot("23_mines_sombres")
	for i in m.CRYSTALS.size():
		var x: float = m.CRYSTALS[i]
		m.player.position = Vector2(x - 200, 540); m.player.facing = 1
		if x > 2000 and x < 2900: m.player.position = Vector2(2100, 540)
		m.cam.reset_smoothing()
		await _wait(0.5)
		await press("zap")
		await _wait(0.3)
		if i == 2: await shot("24_foudre_cristal")
		await _wait(1.0)
	m.player.position = Vector2(3500, 540); m.cam.reset_smoothing()
	await _wait(1.5)
	await shot("25_mines_eclairees")
	m.player.position.x = 3850
	await _until(func(): return m.dialogue.active, 20)
	auto_dialogue = false
	await _wait(1.5)
	await shot("26_ilo")
	auto_dialogue = true
	await _until(func(): return _cur().get("encounter") != null, 90)
	await _until(func(): return _cur().get("state") == "anim" and _cur().banner.text.contains("★"), 120, true)
	await _wait(1.2)
	await shot("27_combo_orage")
	await _until(func(): return _cur().get("state") == "end", 240)
	await _wait(4.0)
	await shot("28_victoire_mines")
	await press("ui_accept")
