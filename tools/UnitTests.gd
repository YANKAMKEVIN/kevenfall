extends Node
## Tests unitaires de la logique pure (sauvegarde, aides manette).
## Lancement : godot --headless --path . -- --unit   (code de sortie 1 si un test échoue)

var fails := 0
var count := 0

func check(cond: bool, what: String) -> void:
	count += 1
	if cond:
		print("OK    ", what)
	else:
		fails += 1
		print("ECHEC ", what)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_test_format()
	_test_migration()
	_test_rejets()
	_test_fichier()
	_test_aides_manette()
	print("RESULTAT : %d test(s), %d échec(s)" % [count, fails])
	get_tree().quit(1 if fails > 0 else 0)

func _partie() -> Dictionary:
	return SaveData.make("Temple", 2, {"pont_a": true, "village_b": true}, true,
		{"communion1": "bercer", "communion2": "eveiller", "foudre2": true})

func _test_format() -> void:
	var d := _partie()
	check(d["version"] == SaveData.VERSION, "la sauvegarde porte la version courante")
	check(SaveData.is_valid(d), "une partie normale est valide")
	var back := SaveData.parse(SaveData.to_text(d))
	check(back == d, "aller-retour JSON sans perte (types compris)")
	check(back["shards_taken"] == ["pont_a", "village_b"], "éclats triés, stables d'une sauvegarde à l'autre")
	var f := {"communion1": "bercer"}
	var d2 := SaveData.make("Brume", 0, {}, false, f)
	f["communion1"] = "eveiller"
	check(d2["flags"]["communion1"] == "bercer", "la sauvegarde est une copie, pas une référence à l'état du jeu")

func _test_migration() -> void:
	var d := _partie()
	d["shards"] = 2.0  # ce que JSON relit pour un entier
	check(SaveData.migrate(d)["shards"] is int, "les entiers relus en flottants redeviennent entiers")
	var futur := _partie(); futur["version"] = SaveData.VERSION + 1
	check(SaveData.parse(SaveData.to_text(futur)).is_empty(), "une sauvegarde d'une version plus récente est refusée")
	var sans := _partie(); sans.erase("version")
	check(SaveData.parse(SaveData.to_text(sans)).is_empty(), "un fichier sans version est refusé")

func _test_rejets() -> void:
	check(SaveData.parse("").is_empty(), "fichier vide refusé")
	check(SaveData.parse("{pas du json").is_empty(), "JSON cassé refusé")
	check(SaveData.parse("[1, 2]").is_empty(), "JSON qui n'est pas un objet refusé")
	var d := _partie(); d["level"] = "Atlantide"
	check(not SaveData.is_valid(d), "chapitre inconnu refusé")
	d = _partie(); d["shards"] = 3
	check(not SaveData.is_valid(d), "nombre d'éclats incohérent refusé")
	d = _partie(); d["flags"]["communion1"] = "dormir"
	check(not SaveData.is_valid(d), "choix de communion inconnu refusé")
	d = _partie(); d["flags"]["triche"] = true
	check(not SaveData.is_valid(d), "drapeau inconnu refusé")
	d = _partie(); d["flags"]["heard_tortue"] = true
	check(SaveData.is_valid(d), "titan écouté (heard_…) accepté")
	for lvl in SaveData.LEVELS:
		check(ResourceLoader.exists("res://scripts/levels/%s.gd" % lvl), "le chapitre %s existe" % lvl)

func _test_fichier() -> void:
	var old_path := Game.save_path
	var old := [Game.shards, Game.shards_taken.duplicate(), Game.talked_soldate, Game.flags.duplicate()]
	Game.save_path = "user://test_sauvegarde.json"
	DirAccess.remove_absolute(Game.save_path)
	check(Game.load_game() == "", "pas de fichier : rien à reprendre")
	Game.shards = 1; Game.shards_taken = {"pont_a": true}; Game.talked_soldate = true
	Game.flags = {"communion1": "eveiller", "foudre2": true}
	check(Game.save_game("Reve"), "écriture de la sauvegarde")
	check(not FileAccess.file_exists(Game.save_path + ".tmp"), "pas de fichier temporaire laissé derrière")
	check(not Game.save_game("Atlantide"), "un chapitre inconnu n'est pas sauvegardé")
	Game.reset()
	check(Game.load_game() == "Reve", "reprise au bon chapitre")
	check(Game.shards == 1 and Game.shards_taken.has("pont_a") and Game.talked_soldate, "éclats et dialogue de la Soldate restaurés")
	check(Game.flags.get("communion1") == "eveiller", "choix de communion restauré (il décide de la fin)")
	var f := FileAccess.open(Game.save_path, FileAccess.WRITE); f.store_string("{abîmé"); f.close()
	check(Game.load_game() == "", "fichier abîmé : pas de plantage, rien à reprendre")
	DirAccess.remove_absolute(Game.save_path)
	Game.save_path = old_path
	Game.shards = old[0]; Game.shards_taken = old[1]; Game.talked_soldate = old[2]; Game.flags = old[3]

func _test_aides_manette() -> void:
	var was := Game.pad
	Game.pad = false
	check(Game.keys("Espace  sauter") == "Espace  sauter", "au clavier, l'aide reste en touches")
	Game.pad = true
	check(Game.keys("← →  marcher     Espace  sauter     E  parler     Échap  pause") == "Croix ◄ ►  marcher     A  sauter     X  parler     Start  pause", "à la manette, l'aide passe en boutons")
	check(Game.keys("Entrée pour continuer") == "A pour continuer", "« Entrée » devient « A »")
	Game.pad = was
