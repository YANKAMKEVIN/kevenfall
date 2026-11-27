class_name SaveData
extends RefCounted
## Format de la sauvegarde, versionné. Logique pure (aucun nœud, aucune scène) :
## testée par tools/UnitTests.gd.
##
## Règle : toute modification du format incrémente VERSION et ajoute une étape à
## migrate(). Une sauvegarde plus récente que le jeu est refusée plutôt qu'écrasée.

const VERSION := 1

## Chapitres où l'on peut reprendre, dans l'ordre du jeu.
const LEVELS: Array[String] = ["Village", "Convoi", "Pont", "Centre", "Mines", "Reve",
	"Effondrement", "Brume", "Temple", "Flotte", "ReveCommun"]

## Clés de drapeaux connues et leur type, pour rejeter une sauvegarde abîmée.
const FLAG_TYPES := {
	"communion1": TYPE_STRING, "communion2": TYPE_STRING, "communion3": TYPE_STRING,
	"foudre2": TYPE_BOOL, "niv3": TYPE_BOOL, "sauge_talk": TYPE_BOOL, "swarm_done": TYPE_BOOL,
}
const CHOICES: Array[String] = ["bercer", "eveiller", "accord"]


## Photographie de la partie au début d'un chapitre.
static func make(level: String, shards: int, shards_taken: Dictionary, talked_soldate: bool, flags: Dictionary) -> Dictionary:
	var taken: Array[String] = []
	for k in shards_taken.keys():
		taken.append(str(k))
	taken.sort()
	return {
		"version": VERSION,
		"level": level,
		"shards": shards,
		"shards_taken": taken,
		"talked_soldate": talked_soldate,
		"flags": flags.duplicate(true),
	}


## Texte JSON -> sauvegarde valide à la version courante, ou {} si illisible,
## abîmée ou venant d'une version plus récente du jeu.
static func parse(text: String) -> Dictionary:
	var json := JSON.new()  # (JSON.parse_string écrirait une erreur moteur pour un fichier abîmé)
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	var raw: Dictionary = json.data
	var d: Dictionary = migrate(raw)
	return d if is_valid(d) else {}


## Amène une sauvegarde d'une version antérieure à VERSION.
static func migrate(d: Dictionary) -> Dictionary:
	var out := d.duplicate(true)
	var v = out.get("version", null)
	if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
		return {}  # pas de version : ce n'est pas une sauvegarde de Kevenfall
	var version := int(v)
	if version > VERSION or version < 1:
		return {}
	# Étapes futures, à chaîner ici :
	# if version == 1: out = _v1_to_v2(out); version = 2
	out["version"] = version
	# JSON relit les entiers en flottants : on les remet en entiers.
	if out.has("shards"):
		out["shards"] = int(out["shards"])
	return out


static func is_valid(d: Dictionary) -> bool:
	if d.is_empty() or int(d.get("version", 0)) != VERSION:
		return false
	if not (d.get("level") is String) or not LEVELS.has(d["level"]):
		return false
	if typeof(d.get("shards")) != TYPE_INT or d["shards"] < 0 or d["shards"] > 13:
		return false
	if not (d.get("shards_taken") is Array) or d["shards_taken"].size() != d["shards"]:
		return false
	if typeof(d.get("talked_soldate")) != TYPE_BOOL:
		return false
	if not (d.get("flags") is Dictionary):
		return false
	for k in d["flags"]:
		if str(k).begins_with("heard_"):  # titans écoutés dans le Rêve Commun (heard_oiseau…)
			if typeof(d["flags"][k]) != TYPE_BOOL:
				return false
			continue
		if not FLAG_TYPES.has(k) or typeof(d["flags"][k]) != FLAG_TYPES[k]:
			return false
		if FLAG_TYPES[k] == TYPE_STRING and not CHOICES.has(d["flags"][k]):
			return false
	return true


static func to_text(d: Dictionary) -> String:
	return JSON.stringify(d, "  ", true)
