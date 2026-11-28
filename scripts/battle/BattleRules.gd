class_name BattleRules
extends RefCounted
## Règles du combat, sans scène ni animation : jauges, dégâts, esquives, phases, fin du combat.
## Les couches de scripts/battle/ s'en servent ; tests/unit/test_battle_rules.gd les vérifie.
## Un combattant est un Dictionary (voir BattleBase._add) : id, hero, hp, max_hp, alive,
## armor, was_armored, defend, rempart, phase…

const FILL := 25.0          # points de jauge par seconde à vitesse 1
const ATB_FULL := 100.0
const MENU_SLOW := 0.3      # vitesse des ennemis pendant le choix
const SLOWED := 0.5         # jauge des ennemis ralentis (Sables mouvants, Arc apaisant)

## Attaque simple de chaque héros : [min, max] avant bonus.
const ATTACK := {"gamin": [7, 9], "soldate": [12, 15], "ilo": [9, 11]}

const COMBOS := {
	"gamin+soldate": {"id": "onde", "name": "Onde de choc", "pair": "Foudre + Pierre", "cost": {"gamin": 3, "soldate": 2},
		"desc": "Frappe tous les ennemis et brise les armures."},
	"soldate+ilo": {"id": "sables", "name": "Sables mouvants", "pair": "Pierre + Brume", "cost": {"soldate": 2, "ilo": 3},
		"desc": "Frappe tous les ennemis et ralentit leurs jauges."},
	"gamin+ilo": {"id": "orage", "name": "Orage invisible", "pair": "Foudre + Brume", "cost": {"gamin": 3, "ilo": 3},
		"desc": "La foudre frappe depuis la brume : gros dégâts, impossible à esquiver, jauges vidées."},
}

## Ennemis dont l'armure résiste aussi à la Foudre (boss).
const BOSS_ARMOR: Array[String] = ["gardien", "noyau", "orsane"]

const OUTCOME_NONE := ""
const OUTCOME_VICTORY := "victoire"
const OUTCOME_DEFEAT := "defaite"


## Points de jauge gagnés pendant delta secondes.
## menu = un héros choisit son action (les ennemis ralentissent) ; slowed = ennemi ralenti.
static func atb_gain(spd: float, delta: float, menu: bool, slowed := false) -> float:
	var k := MENU_SLOW if menu else 1.0
	if slowed:
		k *= SLOWED
	return FILL * spd * delta * k


## Jauge après un pas de temps (plafonnée à pleine).
static func atb_after(atb: float, spd: float, delta: float, menu: bool, slowed := false) -> float:
	return minf(ATB_FULL, atb + atb_gain(spd, delta, menu, slowed))


## Bornes [min, max] de l'attaque simple d'un héros.
static func attack_range(hero_id: String) -> Array:
	return ATTACK.get(hero_id, [1, 1])


## Clé du tableau COMBOS pour deux héros (dans n'importe quel ordre), ou "".
static func combo_key(a: String, b: String) -> String:
	for k: String in COMBOS:
		if k == a + "+" + b or k == b + "+" + a:
			return k
	return ""


## Chance qu'un ennemi esquive une attaque de ce type.
static func dodge_chance(e: Dictionary, kind: String) -> float:
	if kind != "phys":
		return 0.0  # les Kevrês et les attaques combinées touchent toujours
	var id: String = e.id
	if id == "orsane" and e.get("phase", 0) == 2:
		return 0.35
	if id.begins_with("spectre"):
		return 0.4
	if id.begins_with("cauche"):
		return 0.15
	return 0.0


## Dégâts infligés à un ennemi (sans esquive) : {dmg, note, tone, armor_hint}.
## tone : "weak" (faiblesse), "resist" (armure) ou "" ; armor_hint : montrer l'aide sur les armures.
static func damage_to_enemy(e: Dictionary, base: int, kind: String) -> Dictionary:
	var dmg := float(base)
	var note := ""
	var tone := ""
	var hint := false
	var id: String = e.id
	if kind == "foudre":
		if id.begins_with("spectre"):
			dmg *= 1.5; note = "Faiblesse !"; tone = "weak"
		elif id == "extracteur" or id.begins_with("foret") or id == "noyau":
			dmg *= 1.3; note = "Court-circuit !"; tone = "weak"
		elif id == "golem":
			dmg *= 0.8
	var armored: bool = e.get("armor", false)
	if armored and kind in ["phys", "foudre"] and BOSS_ARMOR.has(id):
		dmg *= 0.5 if kind == "foudre" else 0.35; note = "Résiste"; tone = "resist"
	elif armored and kind == "phys":
		dmg *= 0.4; note = "Résiste"; tone = "resist"; hint = true
	elif e.get("was_armored", false) and kind == "phys":
		dmg *= 1.2
	return {"dmg": maxi(1, int(round(dmg))), "note": note, "tone": tone, "armor_hint": hint}


## Dégâts reçus par un héros : {dmg, note, use_rempart}.
## guarded = la Soldate encaisse à la place d'un allié (Garde).
static func damage_to_hero(h: Dictionary, base: int, guarded: bool) -> Dictionary:
	var dmg := float(base)
	var note := ""
	if guarded:
		dmg *= 0.6; note = "Garde"
	if h.get("defend", false):
		dmg *= 0.5
		if note == "": note = "Défense"
	var rempart := int(h.get("rempart", 0)) > 0
	if rempart:
		dmg *= 0.5; note = "Rempart"
	return {"dmg": maxi(1, int(round(dmg))), "note": note, "use_rempart": rempart}


## PV après des dégâts (jamais négatifs).
static func hp_after(hp: int, dmg: int) -> int:
	return maxi(0, hp - dmg)


## Phase d'Orsane selon ses PV : 0 Foudre, 1 Pierre (armure), 2 Brume (esquive).
static func orsane_phase(hp: int, max_hp: int) -> int:
	if hp < max_hp * 0.33:
		return 2
	if hp < max_hp * 0.66:
		return 1
	return 0


## Issue du combat : victoire si tous les ennemis sont tombés, défaite si tous les héros.
static func outcome(heroes: Array, enemies: Array) -> String:
	if not enemies.any(func(f: Dictionary) -> bool: return f.alive):
		return OUTCOME_VICTORY
	if not heroes.any(func(f: Dictionary) -> bool: return f.alive):
		return OUTCOME_DEFEAT
	return OUTCOME_NONE
