extends TestCase
## Sauvegarde sur disque (Game.save_game / load_game) : écriture atomique, secours,
## fichiers absents, abîmés ou impossibles à écrire.

const PATH := "user://test_sauvegarde.json"
var _old_path := ""
var _old_state := []


func before_each() -> void:
	_old_path = Game.save_path
	_old_state = [Game.shards, Game.shards_taken.duplicate(), Game.talked_soldate, Game.flags.duplicate(true)]
	Game.save_path = PATH
	Game.delete_save()
	Game.reset()


func after_each() -> void:
	Game.delete_save()
	Game.save_path = _old_path
	Game.shards = _old_state[0]; Game.shards_taken = _old_state[1]
	Game.talked_soldate = _old_state[2]; Game.flags = _old_state[3]


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _partie_en_cours() -> void:
	Game.shards = 1; Game.shards_taken = {"pont_a": true}; Game.talked_soldate = true
	Game.flags = {"communion1": "eveiller", "foudre2": true, "rod0": true, "crystal3": true}


func test_pas_de_fichier() -> void:
	assert_eq(Game.load_game(), "", "pas de fichier : rien à reprendre")
	assert_true(Game.read_save().is_empty(), "pas de sauvegarde lisible")


func test_ecriture_et_reprise() -> void:
	_partie_en_cours()
	assert_true(Game.save_game("Reve"), "écriture de la sauvegarde")
	assert_false(FileAccess.file_exists(PATH + ".tmp"), "pas de fichier temporaire laissé derrière")
	Game.reset()
	assert_eq(Game.load_game(), "Reve", "reprise au bon chapitre")
	assert_eq(Game.shards, 1, "éclats restaurés")
	assert_true(Game.shards_taken.has("pont_a"), "éclat ramassé restauré")
	assert_true(Game.talked_soldate, "dialogue de la Soldate restauré")
	assert_eq(Game.flags.get("communion1"), "eveiller", "choix de communion restauré (il décide de la fin)")
	assert_eq(Game.flags.get("crystal3"), true, "progression des mines restaurée")
	assert_eq(Game.read_save().get("game_version"), Game.version(), "version du jeu écrite")


## Régression : avant la v2, les drapeaux rod*/crystal* rendaient la sauvegarde illisible.
func test_sauvegarde_apres_le_village_reste_lisible() -> void:
	Game.flags = {"sauge_talk": true, "rod0": true, "rod1": true, "rod2": true, "swarm_done": true}
	assert_true(Game.save_game("Convoi"), "sauvegarde au début du chapitre 2")
	Game.reset()
	assert_eq(Game.load_game(), "Convoi", "« Continuer » reprend au chapitre 2")


func test_chapitre_inconnu_non_sauvegarde() -> void:
	assert_false(Game.save_game("Atlantide"), "un chapitre inconnu n'est pas sauvegardé")
	assert_false(FileAccess.file_exists(PATH), "aucun fichier écrit")


func test_drapeau_inconnu_ecarte() -> void:
	_partie_en_cours()
	Game.flags["drapeau_de_test"] = 42
	assert_true(Game.save_game("Temple"), "la sauvegarde est écrite malgré un drapeau inconnu")
	Game.reset()
	assert_eq(Game.load_game(), "Temple", "et elle se relit")
	assert_false(Game.flags.has("drapeau_de_test"), "le drapeau inconnu a été écarté")


func test_fichier_abime_sans_secours() -> void:
	_write(PATH, "{abîmé")
	assert_eq(Game.load_game(), "", "fichier abîmé : pas de plantage, rien à reprendre")


func test_fichier_abime_avec_secours() -> void:
	_partie_en_cours()
	assert_true(Game.save_game("Brume"), "première sauvegarde")
	assert_true(Game.save_game("Temple"), "deuxième sauvegarde (la première passe en secours)")
	assert_true(FileAccess.file_exists(Game.backup_path()), "secours présent")
	_write(PATH, "{coupure en pleine écri")
	Game.reset()
	assert_eq(Game.load_game(), "Brume", "fichier principal abîmé : reprise sur le secours")


func test_secours_garde_une_bonne_sauvegarde() -> void:
	_write(PATH, "pas une sauvegarde")
	_partie_en_cours()
	assert_true(Game.save_game("Flotte"), "écriture par-dessus un fichier abîmé")
	assert_false(FileAccess.file_exists(Game.backup_path()), "un fichier abîmé n'écrase pas le secours")


func test_fichier_d_une_version_future() -> void:
	var d := SaveData.make("Pont", 0, {}, false, {})
	d["version"] = SaveData.VERSION + 5
	_write(PATH, SaveData.to_text(d))
	assert_eq(Game.load_game(), "", "sauvegarde d'un jeu plus récent ignorée")
	assert_true(FileAccess.file_exists(PATH), "et jamais effacée")


func test_fichier_v1_sur_disque() -> void:
	_write(PATH, JSON.stringify({"version": 1, "level": "Centre", "shards": 0, "shards_taken": [],
		"talked_soldate": true, "flags": {"foudre2": true}}))
	assert_eq(Game.load_game(), "Centre", "une sauvegarde v1 se recharge après migration")


func test_dossier_impossible_a_ecrire() -> void:
	Game.save_path = "user://dossier_absent_%d/sauvegarde.json" % randi()
	_partie_en_cours()
	assert_false(Game.save_game("Pont"), "écriture impossible : échec signalé, pas de plantage")
	assert_eq(Game.load_game(), "", "rien à reprendre")


func test_effacer() -> void:
	_partie_en_cours()
	Game.save_game("Pont"); Game.save_game("Centre")
	Game.delete_save()
	assert_false(FileAccess.file_exists(PATH) or FileAccess.file_exists(Game.backup_path()), "sauvegarde et secours effacés")
