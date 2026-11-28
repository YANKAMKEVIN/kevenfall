extends TestCase
## Progression des chapitres et choix menant aux trois fins (scripts/Story.gd).


func _src(level: String) -> String:
	return FileAccess.get_file_as_string("res://scripts/levels/%s.gd" % level)


func test_onze_chapitres_en_trois_actes() -> void:
	assert_eq(Story.CHAPTERS.size(), 11, "11 chapitres")
	var acts := {}
	for c in Story.CHAPTERS:
		acts[c.act] = acts.get(c.act, 0) + 1
	assert_eq(acts, {1: 3, 2: 4, 3: 4}, "acte I : 3 chapitres, acte II : 4, acte III : 4")
	for i in Story.CHAPTERS.size():
		assert_eq(Story.CHAPTERS[i].level, SaveData.LEVELS[i], "même ordre que la sauvegarde (%d)" % i)


func test_chapitre_suivant() -> void:
	assert_eq(Story.next_chapter("Village"), "Convoi", "1 -> 2")
	assert_eq(Story.next_chapter("Effondrement"), "Brume", "fin de l'acte II -> acte III")
	assert_eq(Story.next_chapter("ReveCommun"), "", "rien après le chapitre 11")
	assert_eq(Story.next_chapter("Atlantide"), "", "chapitre inconnu")
	assert_eq(Story.chapter_index("Temple"), 8, "le temple est le chapitre 9")


## Chaque chapitre mène bien au suivant : on lit les transitions dans le code des chapitres
## (et de la scène de fin de l'acte I, et des combats).
func test_les_chapitres_s_enchainent_dans_l_ordre() -> void:
	var re := RegEx.new()
	re.compile('main\\.goto\\("explore", \\{"level": "([A-Za-z]+)"\\}\\)')
	var battle_re := RegEx.new()
	battle_re.compile('main\\.goto\\("battle", \\{"encounter": "([a-z]+)"\\}\\)')
	var links := {}
	for c in Story.CHAPTERS:
		var src := _src(c.level)
		for m in re.search_all(src):
			links[c.level] = m.get_string(1)
		for m in battle_re.search_all(src):
			var enc := m.get_string(1)
			assert_true(Story.AFTER_BATTLE.has(enc), "%s : le combat « %s » a une suite" % [c.level, enc])
			var after: Dictionary = Story.AFTER_BATTLE.get(enc, {})
			if after.get("level") != "ending" and not after.get("resume", false):
				links[c.level] = after.level  # le combat lui-même fait passer au chapitre suivant
	var ending_src := FileAccess.get_file_as_string("res://scripts/Ending.gd")
	var m := re.search(ending_src)
	assert_true(m != null, "la fin de l'acte I mène quelque part")
	if m: links["Pont"] = m.get_string(1)
	for c in Story.CHAPTERS:
		var nxt := Story.next_chapter(c.level)
		if nxt == "":
			assert_false(links.has(c.level), "le dernier chapitre ne mène à aucun autre")
		else:
			assert_eq(links.get(c.level, "?"), nxt, "%s mène à %s" % [c.level, nxt])


func test_chaque_combat_revient_a_son_chapitre() -> void:
	for enc: String in Story.AFTER_BATTLE:
		var a: Dictionary = Story.AFTER_BATTLE[enc]
		if a.level == "ending":
			continue
		assert_true(Story.chapter_index(a.level) >= 0, "%s revient vers un vrai chapitre" % enc)
		if a.resume:
			assert_true(_src(a.level).contains('"encounter": "%s"' % enc), "le combat %s se déclenche dans %s" % [enc, a.level])


# ---------------------------------------------------------------- fins
func _flags(c1: String, c2: String, heard := 3) -> Dictionary:
	var f := {"communion1": c1, "communion2": c2}
	for i in heard:
		f["heard_" + Story.ECHOES[i]] = true
	return f


func test_titans_ecoutes() -> void:
	assert_eq(Story.heard_count({}), 0, "personne")
	assert_eq(Story.heard_count(_flags("bercer", "bercer", 2)), 2, "deux titans")
	assert_eq(Story.heard_count({"heard_echo_oiseau": false}), 0, "faux ne compte pas")


func test_accord_exige_ecoute_et_choix_mixtes() -> void:
	assert_true(Story.accord_available(_flags("bercer", "eveiller"), 3), "trois titans écoutés + choix mixtes")
	assert_true(Story.accord_available(_flags("eveiller", "bercer"), 3), "dans l'autre sens aussi")
	assert_false(Story.accord_available(_flags("bercer", "bercer"), 3), "toujours Bercer : pas d'Accord")
	assert_false(Story.accord_available(_flags("eveiller", "eveiller"), 3), "toujours Éveiller : pas d'Accord")
	assert_false(Story.accord_available(_flags("bercer", "eveiller"), 2), "un titan pas écouté : pas d'Accord")
	assert_eq(Story.final_option_count(_flags("bercer", "eveiller"), 3), 3, "trois options")
	assert_eq(Story.final_option_count(_flags("bercer", "bercer"), 3), 2, "deux options")


func test_les_trois_fins() -> void:
	var f := _flags("bercer", "eveiller")
	assert_eq(Story.ending_for(f, Story.FINAL_ACCORD), Story.ENDING_ACCORD, "l'Accord")
	assert_eq(Story.ending_for(f, Story.FINAL_BERCER), Story.ENDING_SOMMEIL, "Bercer + Éveiller + Bercer : le Long Sommeil")
	assert_eq(Story.ending_for(f, Story.FINAL_EVEILLER), Story.ENDING_REVEIL, "Bercer + Éveiller + Éveiller : le Réveil")
	assert_eq(Story.ending_for(_flags("bercer", "bercer"), Story.FINAL_EVEILLER), Story.ENDING_SOMMEIL, "majorité Bercer malgré le dernier choix")
	assert_eq(Story.ending_for(_flags("eveiller", "eveiller"), Story.FINAL_BERCER), Story.ENDING_REVEIL, "majorité Éveiller malgré le dernier choix")
	assert_eq(Story.final_communion(Story.FINAL_BERCER), "bercer", "communion3 = bercer")
	assert_eq(Story.final_communion(Story.FINAL_ACCORD), "", "l'Accord n'écrit pas communion3")


## Toutes les combinaisons de choix : chaque fin est atteignable, et l'Accord seulement
## quand il est proposé.
func test_toutes_les_combinaisons() -> void:
	var reached := {}
	for c1 in ["bercer", "eveiller"]:
		for c2 in ["bercer", "eveiller"]:
			for heard in 4:
				var f := _flags(c1, c2, heard)
				for choice in Story.final_option_count(f, heard):
					var e := Story.ending_for(f, choice)
					assert_has(Story.ENDINGS, e, "fin connue")
					reached[e] = true
					if e == Story.ENDING_ACCORD:
						assert_true(Story.accord_available(f, heard), "Accord seulement s'il est proposé")
	assert_eq(reached.size(), 3, "les trois fins sont atteignables")


func test_le_chapitre_final_utilise_les_regles() -> void:
	var src := _src("ReveCommun")
	assert_true(src.contains("Story.accord_available("), "le dernier choix suit Story.accord_available")
	assert_true(src.contains("Story.ending_for("), "la fin suit Story.ending_for")
	for e in Story.ENDINGS:
		assert_true(src.contains('"%s":' % e), "la fin %s est mise en scène" % e)
