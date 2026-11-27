extends Node
## Outil de développement : joue tout l'acte I automatiquement et enregistre des captures.
## Lancement : godot --path . -- --shots=<dossier>

var out := "user://shots"
var main: Main
var auto_dialogue := true
var auto_battle := true
var log_lines: Array = []
var fails := 0           # attentes de progression qui n'ont jamais abouti (le jeu est bloqué)

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="): out = a.substr(8)
	DirAccess.make_dir_recursive_absolute(out)
	process_mode = Node.PROCESS_MODE_ALWAYS
	await _run()

func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/" + name + ".png")
	print("SHOT ", name)

func press(action: String) -> void:
	var e := InputEventAction.new(); e.action = action; e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	await get_tree().process_frame
	var e2 := InputEventAction.new(); e2.action = action; e2.pressed = false
	Input.parse_input_event(e2)
	await get_tree().process_frame

var _tick := 0.0
func _process(delta: float) -> void:
	_tick += delta
	if _tick < 0.25 or main == null: return
	_tick = 0.0
	var c: Variant = main.current
	if c == null: return
	if auto_dialogue and "dialogue" in c and c.dialogue and c.dialogue.active:
		press("interact")
	if auto_battle and "state" in c and c.get("encounter") != null:
		if c.state == "menu":
			var pick := 0
			for i in c.cmds.size():
				if c.cmds[i].id == "combo3" and c._can_use(c.cmds[i]): pick = i
			for i in c.cmds.size():
				if pick != 0: break
				if c.cmds[i].id in ["seisme", "rempart", "tempete", "arc"] and c._can_use(c.cmds[i]) and randf() < 0.6: pick = i
			for i in c.cmds.size():
				if pick != 0: break
				if c.cmds[i].id == "combo" and c._can_use(c.cmds[i]): pick = i; break
				if c.cmds[i].id in ["seisme", "tempete", "arc", "rempart", "chaine"] and c._can_use(c.cmds[i]) and pick == 0: pick = i
				if c.cmds[i].id in ["eclair", "garde"] and c._can_use(c.cmds[i]) and pick == 0: pick = i
			c.cmd_i = pick; c._menu_refresh()
			press("ui_accept")
		elif c.state == "target":
			press("ui_accept")

## soft = attente seulement utile pour une capture (ex. une attaque combinée que le robot
## ne déclenche pas toujours) : son échec ne fait pas échouer le test.
func _until(cond: Callable, timeout := 60.0, soft := false) -> bool:
	var tt := 0.0
	while tt < timeout:
		if cond.call(): return true
		await _wait(0.1); tt += 0.1
	if soft:
		print("TIMEOUT (capture seulement)")
	else:
		fails += 1
		print("ECHEC : attente de progression expirée (%d s) après la capture précédente" % int(timeout))
	return false

## Fin du test : code de sortie non nul si le jeu s'est bloqué (pour la CI).
func _finish() -> void:
	print("RESULTAT : %d échec(s)" % fails)
	print("done")
	get_tree().quit(1 if fails > 0 else 0)

func _stop_after(seg: String) -> bool:
	return ("--stop-after=" + seg) in OS.get_cmdline_user_args()

func _cur() -> Node: return main.current

func _run() -> void:
	await _wait(1.0)
	main = get_tree().root.get_node("Main") as Main
	await _wait(2.0)
	await shot("01_titre")
	var ua := OS.get_cmdline_user_args()
	if "--final" in ua:
		Game.reset()
		Game.flags["communion1"] = "bercer"; Game.flags["communion2"] = "eveiller"
		main.goto("explore", {"level": "ReveCommun"})
		await _act3b()
		_finish()
		return
	if "--act3" in ua:
		Game.reset()
		Game.flags["communion1"] = "bercer"
		main.goto("explore", {"level": "Brume"})
		await _act3()
		_finish()
		return
	if "--fin2" in ua:
		Game.reset()
		main.goto("explore", {"level": "Reve"})
	else:
		if "--act2" in ua:
			Game.reset()
			main.goto("explore", {"level": "Centre"})
		else:
			await _act1()
			if _stop_after("act1"): _finish(); return
		await _act2()
		if _stop_after("act2"): _finish(); return
	await _fin2()
	if _stop_after("fin2"): _finish(); return
	await _act3()
	_finish()

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
	await _until(func(): return _cur() != v and _cur().get("guards") != null, 90)
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
	await _until(func(): return _cur() != cv, 90)
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

func _fin2() -> void:
	# --- Chapitre 6 : le rêve de la Tortue
	await _until(func(): return _cur().get("lantern_nodes") != null, 90)
	await _wait(1.0)
	await _until(func(): return _cur().busy == false, 60)
	var r: Variant = _cur()
	r.player.position.x = 700; r.cam.reset_smoothing()
	await _wait(1.2)
	await shot("29_reve")
	for i in 3:
		var x: float = r.LANTERNS[i]
		r.player.position = Vector2(x - 180, 540); r.player.facing = 1; r.cam.reset_smoothing()
		await _wait(0.6)
		await press("zap")
		await _wait(0.4)
		if i == 0:
			r.player.position = Vector2(x - 80, 540); r.cam.reset_smoothing()
			await _wait(1.4)
			await shot("30_chemin_reve")
		await _wait(1.6)
	r.player.position = Vector2(3850, 540); r.cam.reset_smoothing()
	await _wait(0.5)
	r.player.position.x = 4000
	await _until(func(): return r.dialogue.active, 20)
	auto_dialogue = false
	await _wait(2.0)
	await shot("31_gardien")
	auto_dialogue = true
	await _until(func(): return _cur().get("encounter") != null, 60)
	await _wait(3.0)
	await shot("32_combat_gardien")
	await _until(func(): return _cur().get("state") == "end", 300)
	await _wait(4.0)
	await shot("33_victoire_gardien")
	await press("ui_accept")
	await _until(func(): return _cur().get("lantern_nodes") != null, 30)
	r = _cur()
	await _until(func(): return r.choice_active, 120)
	await _wait(1.2)
	await shot("34_choix")
	if "--eveiller" in OS.get_cmdline_user_args():
		await press("ui_right"); await _wait(0.4)
	await press("ui_accept")
	await _until(func(): return r.dialogue.active and r.dialogue.lines.size() > 1 and r.dialogue.lines[1][0] == "oiseau", 90)
	auto_dialogue = false
	await _wait(2.5)
	await shot("35_vision")
	auto_dialogue = true
	# --- Chapitre 7 : la Grande Foreuse
	await _until(func(): return _cur().get("debris") != null, 120)
	await _wait(1.0)
	await _until(func(): return _cur().busy == false, 60)
	var e: Variant = _cur()
	e.player.position.x = 1100; e.player.facing = 1; e.cam.reset_smoothing()
	e.next_debris = 0.0
	await _wait(0.75)
	await shot("36_effondrement")
	e.player.position.x = 2000; e.cam.reset_smoothing()
	await _until(func(): return e.dialogue.active, 10)
	auto_dialogue = false
	await _wait(1.5)
	await shot("37_tess")
	auto_dialogue = true
	await _until(func(): return e.busy == false and e.tess_done, 60)
	e.player.position = Vector2(4080, 540); e.cam.reset_smoothing()
	await _until(func(): return _cur().get("encounter") != null, 60)
	await _wait(3.0)
	await shot("38_combat_noyau")
	await _until(func(): return _cur().get("state") == "anim" and (_cur().banner.text.contains("Séisme") or _cur().banner.text.contains("Rempart") or _cur().banner.text.contains("★")), 150)
	await _wait(0.9)
	await shot("39_pierre2")
	await _until(func(): return _cur().get("state") == "end", 300)
	await _wait(4.0)
	await shot("40_victoire_noyau")
	print("BATTLE noyau hp: ", _cur()._f("soldate").hp, " ", _cur()._f("gamin").hp, " ", _cur()._f("ilo").hp)
	await press("ui_accept")
	await _until(func(): return _cur().get("debris") != null and _cur().art_layer != null and _cur().dialogue.active, 60)
	auto_dialogue = false
	await _wait(2.5)
	await shot("41_tortue_leve")
	auto_dialogue = true
	await _wait(30.0)
	await shot("42_fin_acte2")
	await press("ui_accept")

func _arg_fin() -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fin="): return a.substr(6)
	return "accord"

func _act3() -> void:
	# --- Chapitre 8 : la mer de brume
	await _until(func(): return _cur().get("wisps") != null, 90)
	auto_dialogue = false
	await _wait(5.0)
	await shot("43_acte3")
	auto_dialogue = true
	await _until(func(): return _cur().busy == false, 90)
	var b: Variant = _cur()
	b.player.position.x = 650; b.cam.reset_smoothing()
	await _wait(1.0)
	await shot("44_mer_de_brume")
	b.player.position = Vector2(900, 540); b.player.facing = 1; b.cam.reset_smoothing()
	await _wait(0.3)
	await press("zap")
	await _wait(0.25)
	await shot("45_foudre_spectre")
	for w in b.wisps:
		w.alive = false; w.a.visible = false
	b.player.position = Vector2(3900, 540); b.cam.reset_smoothing()
	await _wait(0.5)
	b.player.position.x = 4020
	await _until(func(): return _cur().get("encounter") != null, 60)
	await _wait(3.0)
	await shot("46_combat_brume")
	await _until(func(): return _cur().get("state") == "end", 300)
	await _wait(4.0)
	await press("ui_accept")
	# --- Chapitre 9 : le dernier temple
	await _until(func(): return _cur().get("revealed") != null, 90)
	await _wait(1.0)
	await _until(func(): return _cur().busy == false, 60)
	var t3: Variant = _cur()
	t3.player.position.x = 1850; t3.cam.reset_smoothing()
	await _wait(1.0)
	await shot("47_temple")
	for k in ["f1", "f2", "f3"]:
		var o: Variant = null
		for ob in t3.cfg.objects:
			if ob.id == k: o = ob
		t3.player.position.x = o.x - 50; t3.cam.reset_smoothing()
		await _wait(0.3)
		if k == "f2": auto_dialogue = false
		t3.talk(k)
		if k == "f2":
			await _wait(1.5)
			await shot("48_fresque")
			auto_dialogue = true
		await _until(func(): return t3.busy == false and not t3.dialogue.active, 40)
	t3.player.position.x = 3560; t3.cam.reset_smoothing()
	await _wait(0.3)
	t3.talk("cloche")
	await _until(func(): return t3.art_layer != null and t3.dialogue.active, 120)
	auto_dialogue = false
	await _wait(2.5)
	await shot("49_serpent")
	auto_dialogue = true
	await _until(func(): return t3.choice_active, 60)
	await _wait(1.2)
	await shot("50_choix_serpent")
	var fin := _arg_fin()
	if fin == "accord" or fin == "reveil":
		await press("ui_right"); await _wait(0.4)
	await press("ui_accept")
	await _until(func(): return t3.dialogue.active and t3.dialogue.lines.size() > 3 and t3.dialogue.lines[0][1].begins_with("Capitaine... Je peux"), 120)
	auto_dialogue = false
	await _wait(1.0)
	for i in 3:
		await press("interact"); await _wait(1.2)
	await shot("51_aveu")
	auto_dialogue = true
	# --- Chapitre 10 : la flotte
	await _until(func(): return _cur().has_method("_hit_shot"), 120)
	await _wait(1.0)
	await _until(func(): return _cur().busy == false, 60)
	var f: Variant = _cur()
	f.player.position.x = 1150; f.player.facing = 1; f.cam.reset_smoothing()
	f.next_shot = 0.0
	await _wait(0.8)
	await shot("52_flotte")
	f.player.position = Vector2(3940, 540); f.cam.reset_smoothing()
	f.shots.clear()
	await _wait(0.2)
	f.player.position.x = 3970
	await _until(func(): return f.dialogue.active, 30)
	auto_dialogue = false
	await _wait(1.5)
	await shot("53_orsane")
	auto_dialogue = true
	await _until(func(): return _cur().get("encounter") != null, 90)
	await _wait(3.0)
	await shot("54_combat_orsane")
	await _until(func(): return _cur().get("state") == "end", 400)
	await _wait(4.0)
	await shot("55_victoire_orsane")
	print("BATTLE orsane hp: ", _cur()._f("soldate").hp, " ", _cur()._f("gamin").hp, " ", _cur()._f("ilo").hp)
	await press("ui_accept")
	await _until(func(): return _cur().get("shots") != null and _cur().dialogue.active and _cur().dialogue.lines[0][1].begins_with("Capitaine... mes"), 120)
	auto_dialogue = false
	await _wait(1.5)
	await shot("56_gamin_s_efface")
	auto_dialogue = true
	if _stop_after("act3a"): return  # la CI joue le chapitre 11 dans un lot à part (--final)
	await _act3b()

func _act3b() -> void:
	var fin := _arg_fin()
	# --- Chapitre 11 : le Rêve Commun
	await _until(func(): return _cur().get("heard") != null, 120)
	await _wait(1.0)
	await _until(func(): return _cur().busy == false, 90)
	var r: Variant = _cur()
	r.player.position.x = 700; r.cam.reset_smoothing()
	await _wait(1.0)
	await shot("57_reve_commun")
	for k in ["echo_oiseau", "echo_tortue", "echo_serpent"]:
		r.player.position.x = r.ECHOES[k] - 50; r.cam.reset_smoothing()
		await _wait(0.3)
		if k == "echo_tortue": auto_dialogue = false
		r.talk(k)
		if k == "echo_tortue":
			await _wait(1.5)
			await shot("58_echo_tortue")
			auto_dialogue = true
		await _until(func(): return r.busy == false and not r.dialogue.active, 40)
	r.player.position = Vector2(3950, 540); r.cam.reset_smoothing()
	await _wait(0.3)
	r.player.position.x = 4020
	await _until(func(): return r.dialogue.active, 20)
	auto_dialogue = false
	await _wait(1.5)
	await shot("59_cauchemar")
	auto_dialogue = true
	await _until(func(): return _cur().get("encounter") != null, 60)
	await _wait(3.0)
	await shot("60_combat_final")
	await _until(func(): return _cur().get("state") == "anim" and _cur().banner.text.contains("RÊVE COMMUN"), 200)
	await _wait(1.3)
	await shot("61_reve_commun_attaque")
	await _until(func(): return _cur().get("state") == "end", 400)
	await _wait(4.0)
	await shot("62_victoire_finale")
	print("BATTLE cauchemar hp: ", _cur()._f("soldate").hp, " ", _cur()._f("gamin").hp, " ", _cur()._f("ilo").hp)
	await press("ui_accept")
	await _until(func(): return _cur().get("heard") != null and _cur().choice_active, 120)
	r = _cur()
	await _wait(1.2)
	await shot("63_choix_final")
	if fin == "reveil":
		await press("ui_right"); await _wait(0.3)
	elif fin == "accord":
		await press("ui_right"); await _wait(0.3); await press("ui_right"); await _wait(0.3)
	await press("ui_accept")
	await _until(func(): return r.art_layer != null and r.dialogue.active, 120)
	auto_dialogue = false
	await _wait(2.5)
	await shot("64_fin_" + fin)
	auto_dialogue = true
	await _wait(40.0)
	await shot("65_generique_" + fin)
