class_name SaveData
extends RefCounted
## Format de la sauvegarde, versionné. Logique pure (aucun nœud, aucune scène) :
## testée par tests/unit/test_save_data.gd.
##
## Règle : toute modification du format incrémente VERSION et ajoute une étape à
## migrate(). Une sauvegarde plus récente que le jeu est refusée plutôt qu'écrasée.
##
## Historique du format :
## - v1 : chapitre, éclats, dialogue de la Soldate, drapeaux.
## - v2 : drapeaux de progression interne aux chapitres acceptés (rod0..2 au village,
##   crystal0..4 dans les mines : en v1 ils rendaient la sauvegarde illisible dès le
##   chapitre 2), version du jeu qui a écrit le fichier (game_version).

const VERSION := 2

## Taille maximale d'un fichier de sauvegarde lu (une vraie sauvegarde fait < 1 Ko).
const MAX_BYTES := 64 * 1024

## Chapitres où l'on peut reprendre, dans l'ordre du jeu.
const LEVELS: Array[String] = ["Village", "Convoi", "Pont", "Centre", "Mines", "Reve",
	"Effondrement", "Brume", "Temple", "Flotte", "ReveCommun"]

## Clés de drapeaux connues et leur type, pour rejeter une sauvegarde abîmée.
const FLAG_TYPES := {
	"communion1": TYPE_STRING, "communion2": TYPE_STRING, "communion3": TYPE_STRING,
	"foudre2": TYPE_BOOL, "niv3": TYPE_BOOL, "sauge_talk": TYPE_BOOL, "swarm_done": TYPE_BOOL,
}
## Drapeaux numérotés (préfixe -> nombre d'éléments) : paratonnerres du village, cristaux des mines.
const INDEXED_FLAGS := {"rod": 3, "crystal": 5}
## Titans écoutés dans le Rêve Commun (heard_echo_oiseau…).
const HEARD_PREFIX := "heard_"
const CHOICES: Array[String] = ["bercer", "eveiller", "accord"]
const SHARDS_MAX := 13


## Photographie de la partie au début d'un chapitre.
static func make(level: String, shards: int, shards_taken: Dictionary, talked_soldate: bool, flags: Dictionary, game_version := "") -> Dictionary:
	var taken: Array[String] = []
	for k: Variant in shards_taken.keys():
		taken.append(str(k))
	taken.sort()
	return {
		"version": VERSION,
		"game_version": game_version,
		"level": level,
		"shards": shards,
		"shards_taken": taken,
		"talked_soldate": talked_soldate,
		"flags": flags.duplicate(true),
	}


## Texte JSON -> sauvegarde valide à la version courante, ou {} si illisible,
## abîmée ou venant d'une version plus récente du jeu.
static func parse(text: String) -> Dictionary:
	if text.length() > MAX_BYTES:
		return {}
	var json := JSON.new()  # (JSON.parse_string écrirait une erreur moteur pour un fichier abîmé)
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	var raw: Dictionary = json.data
	var d: Dictionary = migrate(raw)
	return d if is_valid(d) else {}


## Amène une sauvegarde d'une version antérieure à VERSION ({} si impossible).
static func migrate(d: Dictionary) -> Dictionary:
	var out := d.duplicate(true)
	var v: Variant = out.get("version", null)
	if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
		return {}  # pas de version : ce n'est pas une sauvegarde de Kevenfall
	if typeof(v) == TYPE_FLOAT and float(v) != floorf(float(v)):
		return {}
	var version := int(v)
	if version > VERSION or version < 1:
		return {}
	if version == 1:
		out = _v1_to_v2(out); version = 2
	# Étapes futures, à chaîner ici : if version == 2: out = _v2_to_v3(out); version = 3
	out["version"] = version
	# JSON relit les entiers en flottants : on les remet en entiers (seulement s'ils sont entiers).
	var s: Variant = out.get("shards")
	if typeof(s) == TYPE_FLOAT and float(s) == floorf(float(s)):
		out["shards"] = int(s)
	return out


## v1 -> v2 : la v1 n'enregistrait pas la version du jeu. Les drapeaux numérotés
## (rod*, crystal*) écrits par la v1 deviennent lisibles sans transformation.
static func _v1_to_v2(d: Dictionary) -> Dictionary:
	d["game_version"] = ""
	return d


static func is_valid(d: Dictionary) -> bool:
	if d.is_empty() or typeof(d.get("version")) != TYPE_INT or d["version"] != VERSION:
		return false
	if not (d.get("game_version") is String):
		return false
	if not (d.get("level") is String) or not LEVELS.has(d["level"]):
		return false
	if typeof(d.get("shards")) != TYPE_INT or d["shards"] < 0 or d["shards"] > SHARDS_MAX:
		return false
	if not (d.get("shards_taken") is Array) or d["shards_taken"].size() != d["shards"]:
		return false
	var seen := {}
	for id: Variant in d["shards_taken"]:
		if not (id is String) or id == "" or seen.has(id):
			return false
		seen[id] = true
	if typeof(d.get("talked_soldate")) != TYPE_BOOL:
		return false
	if not (d.get("flags") is Dictionary):
		return false
	for k: Variant in d["flags"]:
		if not is_flag_valid(str(k), d["flags"][k]):
			return false
	return true


## Un drapeau (clé et valeur) a-t-il sa place dans une sauvegarde ?
static func is_flag_valid(k: String, value: Variant) -> bool:
	if k.begins_with(HEARD_PREFIX):
		return k.length() > HEARD_PREFIX.length() and typeof(value) == TYPE_BOOL
	for prefix: String in INDEXED_FLAGS:
		if k.begins_with(prefix) and k.substr(prefix.length()).is_valid_int():
			var i := k.substr(prefix.length()).to_int()
			return i >= 0 and i < int(INDEXED_FLAGS[prefix]) and typeof(value) == TYPE_BOOL
	if not FLAG_TYPES.has(k) or typeof(value) != FLAG_TYPES[k]:
		return false
	if FLAG_TYPES[k] == TYPE_STRING and not CHOICES.has(value):
		return false
	return true


static func to_text(d: Dictionary) -> String:
	return JSON.stringify(d, "  ", true)
