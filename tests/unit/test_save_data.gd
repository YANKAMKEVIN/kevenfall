extends TestCase
## Format de la sauvegarde (scripts/SaveData.gd) : logique pure, sans fichier.


func _partie() -> Dictionary:
	return SaveData.make("Temple", 2, {"pont_a": true, "village_b": true}, true,
		{"communion1": "bercer", "communion2": "eveiller", "foudre2": true}, "1.2.0")


func _v1() -> Dictionary:
	return {"version": 1, "level": "Mines", "shards": 1.0, "shards_taken": ["village_a"],
		"talked_soldate": false, "flags": {"foudre2": true, "rod0": true, "rod1": true, "rod2": true}}


func test_format_courant() -> void:
	var d := _partie()
	assert_eq(d["version"], SaveData.VERSION, "la sauvegarde porte la version courante")
	assert_eq(d["game_version"], "1.2.0", "version du jeu enregistrée")
	assert_true(SaveData.is_valid(d), "une partie normale est valide")


func test_aller_retour_json() -> void:
	var d := _partie()
	var back := SaveData.parse(SaveData.to_text(d))
	assert_eq(back, d, "aller-retour JSON sans perte (types compris)")
	assert_eq(back["shards"], 2, "les éclats restent un entier")
	assert_eq(back["shards_taken"], ["pont_a", "village_b"], "éclats triés, stables d'une sauvegarde à l'autre")


func test_copie_et_non_reference() -> void:
	var f := {"communion1": "bercer"}
	var d := SaveData.make("Brume", 0, {}, false, f)
	f["communion1"] = "eveiller"
	assert_eq(d["flags"]["communion1"], "bercer", "la sauvegarde est une copie de l'état du jeu")


func test_migration_v1_vers_v2() -> void:
	var m := SaveData.migrate(_v1())
	assert_eq(m["version"], 2, "v1 amenée à la v2")
	assert_eq(m["game_version"], "", "version du jeu inconnue pour une v1")
	assert_eq(m["shards"], 1, "entier relu en flottant redevenu entier")
	assert_true(SaveData.is_valid(m), "une v1 migrée est valide")
	var back := SaveData.parse(JSON.stringify(_v1()))
	assert_eq(back.get("level"), "Mines", "une sauvegarde v1 se recharge")
	assert_eq(back["flags"].get("rod2"), true, "drapeaux des paratonnerres conservés")


func test_migration_ne_modifie_pas_l_original() -> void:
	var v1 := _v1()
	SaveData.migrate(v1)
	assert_false(v1.has("game_version"), "migrate travaille sur une copie")


func test_versions_refusees() -> void:
	var futur := _partie(); futur["version"] = SaveData.VERSION + 1
	assert_true(SaveData.parse(SaveData.to_text(futur)).is_empty(), "version plus récente refusée")
	var sans := _partie(); sans.erase("version")
	assert_true(SaveData.parse(SaveData.to_text(sans)).is_empty(), "fichier sans version refusé")
	var zero := _partie(); zero["version"] = 0
	assert_true(SaveData.parse(SaveData.to_text(zero)).is_empty(), "version 0 refusée")
	var texte := _partie(); texte["version"] = "2"
	assert_true(SaveData.parse(SaveData.to_text(texte)).is_empty(), "version en texte refusée")
	var demi := _partie(); demi["version"] = 1.5
	assert_true(SaveData.migrate(demi).is_empty(), "version non entière refusée")


func test_fichiers_illisibles() -> void:
	assert_true(SaveData.parse("").is_empty(), "fichier vide")
	assert_true(SaveData.parse("{pas du json").is_empty(), "JSON cassé")
	assert_true(SaveData.parse("[1, 2]").is_empty(), "JSON qui n'est pas un objet")
	assert_true(SaveData.parse("null").is_empty(), "null")
	assert_true(SaveData.parse(SaveData.to_text(_partie()).substr(0, 40)).is_empty(), "fichier tronqué")
	assert_true(SaveData.parse("{}" + " ".repeat(SaveData.MAX_BYTES)).is_empty(), "fichier démesuré")


func test_champs_incoherents() -> void:
	var cas := {
		"chapitre inconnu": func(d: Dictionary) -> void: d["level"] = "Atlantide",
		"chapitre absent": func(d: Dictionary) -> void: d.erase("level"),
		"nombre d'éclats incohérent": func(d: Dictionary) -> void: d["shards"] = 3,
		"éclats négatifs": func(d: Dictionary) -> void: d["shards"] = -1,
		"trop d'éclats": func(d: Dictionary) -> void: d["shards"] = 14,
		"éclat en double": func(d: Dictionary) -> void: d["shards_taken"] = ["pont_a", "pont_a"],
		"éclat qui n'est pas un texte": func(d: Dictionary) -> void: d["shards_taken"] = ["pont_a", 3],
		"dialogue de la Soldate non booléen": func(d: Dictionary) -> void: d["talked_soldate"] = "oui",
		"drapeaux qui ne sont pas un objet": func(d: Dictionary) -> void: d["flags"] = [],
		"version du jeu non textuelle": func(d: Dictionary) -> void: d["game_version"] = 3,
		"choix de communion inconnu": func(d: Dictionary) -> void: d["flags"]["communion1"] = "dormir",
		"drapeau inconnu": func(d: Dictionary) -> void: d["flags"]["triche"] = true,
		"drapeau mal typé": func(d: Dictionary) -> void: d["flags"]["foudre2"] = "oui",
		"paratonnerre hors limites": func(d: Dictionary) -> void: d["flags"]["rod3"] = true,
		"cristal hors limites": func(d: Dictionary) -> void: d["flags"]["crystal5"] = true,
		"cristal non booléen": func(d: Dictionary) -> void: d["flags"]["crystal0"] = 1,
		"titan écouté non booléen": func(d: Dictionary) -> void: d["flags"]["heard_echo_oiseau"] = "oui",
		"préfixe heard_ seul": func(d: Dictionary) -> void: d["flags"]["heard_"] = true,
	}
	for what: String in cas:
		var d := _partie()
		(cas[what] as Callable).call(d)
		assert_false(SaveData.is_valid(d), what)


func test_drapeaux_acceptes() -> void:
	for k in ["rod0", "rod2", "crystal0", "crystal4", "heard_echo_tortue", "sauge_talk", "swarm_done", "niv3"]:
		assert_true(SaveData.is_flag_valid(k, true), "drapeau %s accepté" % k)
	assert_true(SaveData.is_flag_valid("communion3", "accord"), "communion3 = accord accepté")


## Le bug de la v1 : un drapeau posé par un chapitre et inconnu du format rendait la sauvegarde
## illisible (« Continuer » disparaissait dès le chapitre 2). Chaque drapeau écrit par un
## chapitre doit donc être connu du format.
func test_tous_les_drapeaux_des_chapitres_sont_sauvegardables() -> void:
	var re := RegEx.new()
	re.compile('Game\\.flags\\["([a-z0-9_]+)(%d)?"(?: % \\w+)?( \\+ k)?\\]\\s*=[^=]')
	var found := 0
	for f in DirAccess.get_files_at("res://scripts/levels/"):
		if not f.ends_with(".gd"):
			continue
		var src := FileAccess.get_file_as_string("res://scripts/levels/" + f)
		for m in re.search_all(src):
			found += 1
			var key := m.get_string(1)
			if m.get_string(2) != "":
				key += "0"
			if m.get_string(3) != "":
				key += "echo_oiseau"
			var value: Variant = true
			if key.begins_with("communion"): value = "bercer"
			assert_true(SaveData.is_flag_valid(key, value), "%s : drapeau « %s » connu du format" % [f, key])
	assert_true(found >= 15, "drapeaux trouvés dans les chapitres (%d)" % found)


func test_chapitres_de_reprise() -> void:
	assert_eq(SaveData.LEVELS.size(), 11, "11 chapitres")
	for lvl in SaveData.LEVELS:
		assert_true(ResourceLoader.exists("res://scripts/levels/%s.gd" % lvl), "le chapitre %s existe" % lvl)
