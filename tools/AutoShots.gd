extends "res://tools/bot/BotActs12.gd"
## Robot de parcours : joue le jeu tout seul, du titre jusqu'à une des trois fins, en
## vérifiant que chaque chapitre est traversé (et sa sauvegarde relisible) et que la fin
## jouée est celle visée. Les dialogues et les combats sont joués automatiquement.
##
## godot --headless --path . --fixed-fps 60 -- --parcours [options]   (sans rendu, ~1 min)
## godot --path . -- --shots=<dossier> [options]                      (avec captures d'écran)
## Options : --act2 | --fin2 | --act3 | --final (départ), --stop-after=act1|act2|fin2|act3a,
## --eveiller (Éveiller à la Tortue), --fin=accord|sommeil|reveil (fin visée, accord par défaut).

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
	ending_seen = r.ending_reached
	auto_dialogue = false
	await _wait(2.5)
	await shot("64_fin_" + fin)
	auto_dialogue = true
	await _wait(40.0)
	await shot("65_generique_" + fin)
