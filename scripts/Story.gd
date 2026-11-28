class_name Story
extends RefCounted
## Règles du récit, sans scène : ordre des chapitres et choix qui mènent aux trois fins.
## Utilisé par les chapitres (scripts/levels/) et testé par tests/unit/test_story.gd.

## Les 11 chapitres, dans l'ordre (nom du script de scripts/levels/, acte, titre).
const CHAPTERS: Array[Dictionary] = [
	{"level": "Village", "act": 1, "title": "Le village des Plumes"},
	{"level": "Convoi", "act": 1, "title": "Le convoi"},
	{"level": "Pont", "act": 1, "title": "Le Pont de l'Oiseau"},
	{"level": "Centre", "act": 2, "title": "Le centre d'extraction"},
	{"level": "Mines", "act": 2, "title": "Les mines profondes"},
	{"level": "Reve", "act": 2, "title": "Le rêve de la Tortue"},
	{"level": "Effondrement", "act": 2, "title": "La Grande Foreuse"},
	{"level": "Brume", "act": 3, "title": "La mer de brume"},
	{"level": "Temple", "act": 3, "title": "Le dernier temple"},
	{"level": "Flotte", "act": 3, "title": "La flotte d'Orsane"},
	{"level": "ReveCommun", "act": 3, "title": "Le Rêve Commun"},
]

## Après la victoire d'un combat : chapitre où l'on revient (après le combat) ou, pour le
## combat du pont, la scène de fin de l'acte I ("ending"). "resume" = on reprend le chapitre
## là où le combat l'avait interrompu (sans bannière de chapitre).
const AFTER_BATTLE := {
	"village": {"level": "Village", "resume": true},
	"pont": {"level": "ending", "resume": false},
	"centre": {"level": "Mines", "resume": false},
	"mines": {"level": "Mines", "resume": true},
	"gardien": {"level": "Reve", "resume": true},
	"noyau": {"level": "Effondrement", "resume": true},
	"brume": {"level": "Brume", "resume": true},
	"orsane": {"level": "Flotte", "resume": true},
	"cauchemar": {"level": "ReveCommun", "resume": true},
}

## Les trois titans à écouter dans le Rêve Commun (objets du chapitre 11).
const ECHOES: Array[String] = ["echo_oiseau", "echo_tortue", "echo_serpent"]

## Les trois fins.
const ENDING_SOMMEIL := "sommeil"
const ENDING_REVEIL := "reveil"
const ENDING_ACCORD := "accord"
const ENDINGS: Array[String] = [ENDING_SOMMEIL, ENDING_REVEIL, ENDING_ACCORD]

## Indices des options du dernier choix (l'Accord n'apparaît que s'il est permis).
const FINAL_BERCER := 0
const FINAL_EVEILLER := 1
const FINAL_ACCORD := 2


## Position (0 à 10) d'un chapitre, ou -1 s'il n'existe pas.
static func chapter_index(level: String) -> int:
	for i in CHAPTERS.size():
		if CHAPTERS[i]["level"] == level:
			return i
	return -1


## Chapitre suivant, ou "" après le dernier (ou pour un chapitre inconnu).
static func next_chapter(level: String) -> String:
	var i := chapter_index(level)
	if i < 0 or i + 1 >= CHAPTERS.size():
		return ""
	return CHAPTERS[i + 1]["level"]


## Nombre de titans écoutés, d'après les drapeaux heard_echo_*.
static func heard_count(flags: Dictionary) -> int:
	var n := 0
	for k in ECHOES:
		if flags.get("heard_" + k, false):
			n += 1
	return n


## Les deux communions (Tortue, Serpent) n'ont pas reçu la même réponse.
static func mixed(flags: Dictionary) -> bool:
	return flags.get("communion1", "") != flags.get("communion2", "")


## La troisième voie (l'Accord) : avoir écouté les trois titans et ne pas avoir
## toujours choisi pareil.
static func accord_available(flags: Dictionary, heard: int) -> bool:
	return heard >= ECHOES.size() and mixed(flags)


## Nombre d'options proposées au dernier choix.
static func final_option_count(flags: Dictionary, heard: int) -> int:
	return 3 if accord_available(flags, heard) else 2


## Réponse du dernier choix (option choisie) -> valeur de communion3, ou "" pour l'Accord.
static func final_communion(choice: int) -> String:
	if choice == FINAL_ACCORD:
		return ""
	return "bercer" if choice == FINAL_BERCER else "eveiller"


## Fin atteinte : l'Accord si choisi, sinon la majorité des trois réponses
## (Tortue, Serpent, Oiseau) : surtout Bercer -> le Long Sommeil, sinon le Réveil.
static func ending_for(flags: Dictionary, choice: int) -> String:
	if choice == FINAL_ACCORD:
		return ENDING_ACCORD
	var answers := [flags.get("communion1", ""), flags.get("communion2", ""), final_communion(choice)]
	var b := answers.count("bercer")
	return ENDING_SOMMEIL if b >= 2 else ENDING_REVEIL
