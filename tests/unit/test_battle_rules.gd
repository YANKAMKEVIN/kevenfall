extends TestCase
## Règles du combat (scripts/battle/BattleRules.gd) : jauges, dégâts, esquives, fin du combat.


func _enemy(id: String, extra := {}) -> Dictionary:
	var e := {"id": id, "hero": false, "hp": 100, "max_hp": 100, "alive": true, "armor": false, "was_armored": false}
	e.merge(extra, true)
	return e


func _hero(id: String, extra := {}) -> Dictionary:
	var h := {"id": id, "hero": true, "hp": 80, "max_hp": 80, "alive": true, "defend": false, "rempart": 0}
	h.merge(extra, true)
	return h


# ---------------------------------------------------------------- jauges et tours
func test_jauge_vitesse_normale() -> void:
	assert_eq(BattleRules.atb_gain(1.0, 1.0, false), 25.0, "25 points par seconde à vitesse 1")
	assert_eq(BattleRules.atb_gain(2.0, 0.5, false), 25.0, "vitesse 2 pendant une demi-seconde")


func test_jauge_ralentie_pendant_le_menu() -> void:
	assert_eq(BattleRules.atb_gain(1.0, 1.0, true), 25.0 * BattleRules.MENU_SLOW, "les ennemis ralentissent pendant le choix")
	assert_eq(BattleRules.atb_gain(1.0, 1.0, false, true), 12.5, "ennemi ralenti : moitié moins vite")
	assert_eq(BattleRules.atb_gain(1.0, 1.0, true, true), 25.0 * BattleRules.MENU_SLOW * 0.5, "les deux ralentissements se cumulent")


func test_jauge_plafonnee() -> void:
	assert_eq(BattleRules.atb_after(95.0, 1.0, 1.0, false), 100.0, "jamais plus de 100")
	assert_eq(BattleRules.atb_after(0.0, 1.0, 0.1, false), 2.5, "petit pas de temps")


func test_quatre_secondes_pour_un_tour() -> void:
	var atb := 0.0
	var frames := 0
	while atb < BattleRules.ATB_FULL and frames < 10000:
		atb = BattleRules.atb_after(atb, 1.0, 1.0 / 60.0, false)
		frames += 1
	assert_between(frames, 239, 241, "à vitesse 1, un tour toutes les 4 s (240 images à 60 i/s)")


# ---------------------------------------------------------------- attaques des héros
func test_attaque_simple_par_heros() -> void:
	assert_eq(BattleRules.attack_range("gamin"), [7, 9], "le Gamin frappe faiblement")
	assert_eq(BattleRules.attack_range("soldate"), [12, 15], "la Soldate frappe fort")
	assert_eq(BattleRules.attack_range("ilo"), [9, 11], "Ilo entre les deux")


func test_degats_simples() -> void:
	var r := BattleRules.damage_to_enemy(_enemy("cauchemerle"), 10, "phys")
	assert_eq(r.dmg, 10, "sans modificateur, les dégâts sont la base")
	assert_eq(r.note, "", "pas de note")


func test_faiblesse_a_la_foudre() -> void:
	var r := BattleRules.damage_to_enemy(_enemy("spectre0"), 20, "foudre")
	assert_eq(r.dmg, 30, "les Spectres prennent 150 % de la Foudre")
	assert_eq(r.tone, "weak", "affiché comme une faiblesse")
	assert_eq(BattleRules.damage_to_enemy(_enemy("extracteur"), 10, "foudre").dmg, 13, "court-circuit sur l'Extracteur")
	assert_eq(BattleRules.damage_to_enemy(_enemy("foret1"), 10, "foudre").dmg, 13, "court-circuit sur les forets")
	assert_eq(BattleRules.damage_to_enemy(_enemy("golem"), 10, "foudre").dmg, 8, "le Golem résiste un peu à la Foudre")


func test_armure() -> void:
	var r := BattleRules.damage_to_enemy(_enemy("rongeroc0", {"armor": true}), 10, "phys")
	assert_eq(r.dmg, 4, "une carapace divise les coups par 2,5")
	assert_true(r.armor_hint, "l'aide sur les armures est proposée")
	assert_eq(BattleRules.damage_to_enemy(_enemy("rongeroc0", {"armor": true}), 10, "combo").dmg, 10, "les attaques combinées ignorent l'armure")
	var boss := BattleRules.damage_to_enemy(_enemy("gardien", {"armor": true}), 20, "phys")
	assert_eq(boss.dmg, 7, "carapace de boss : 35 % des coups")
	assert_false(boss.armor_hint, "pas d'aide générique sur un boss")
	assert_eq(BattleRules.damage_to_enemy(_enemy("noyau", {"armor": true}), 20, "foudre").dmg, 13, "Noyau blindé : court-circuit puis moitié")


func test_armure_brisee() -> void:
	assert_eq(BattleRules.damage_to_enemy(_enemy("gardien", {"was_armored": true}), 10, "phys").dmg, 12, "armure brisée : +20 % aux coups")


func test_degats_minimum_un() -> void:
	assert_eq(BattleRules.damage_to_enemy(_enemy("gardien", {"armor": true}), 1, "phys").dmg, 1, "toujours au moins 1")


func test_esquive() -> void:
	assert_eq(BattleRules.dodge_chance(_enemy("spectre1"), "phys"), 0.4, "les Spectres esquivent souvent")
	assert_eq(BattleRules.dodge_chance(_enemy("cauchemerle0"), "phys"), 0.15, "les Cauchemerles un peu")
	assert_eq(BattleRules.dodge_chance(_enemy("spectre1"), "foudre"), 0.0, "la Foudre touche toujours")
	assert_eq(BattleRules.dodge_chance(_enemy("orsane", {"phase": 2}), "phys"), 0.35, "Orsane esquive en phase Brume")
	assert_eq(BattleRules.dodge_chance(_enemy("orsane", {"phase": 1}), "phys"), 0.0, "pas avant")
	assert_eq(BattleRules.dodge_chance(_enemy("golem"), "phys"), 0.0, "le Golem n'esquive pas")


func test_phases_d_orsane() -> void:
	assert_eq(BattleRules.orsane_phase(300, 300), 0, "pleine vie : Foudre")
	assert_eq(BattleRules.orsane_phase(190, 300), 1, "sous 66 % : Pierre")
	assert_eq(BattleRules.orsane_phase(90, 300), 2, "sous 33 % : Brume")


func test_combos() -> void:
	assert_eq(BattleRules.combo_key("soldate", "gamin"), "gamin+soldate", "ordre indifférent")
	assert_eq(BattleRules.combo_key("ilo", "soldate"), "soldate+ilo", "Sables mouvants")
	assert_eq(BattleRules.combo_key("gamin", "gamin"), "", "pas de combo seul")
	for k: String in BattleRules.COMBOS:
		var c: Dictionary = BattleRules.COMBOS[k]
		assert_eq(c.cost.size(), 2, "%s coûte du Rêve aux deux héros" % c.name)


# ---------------------------------------------------------------- dégâts reçus
func test_degats_recus() -> void:
	var r := BattleRules.damage_to_hero(_hero("gamin"), 10, false)
	assert_eq(r.dmg, 10, "sans protection")
	assert_false(r.use_rempart, "pas de Rempart utilisé")


func test_garde_defense_rempart() -> void:
	assert_eq(BattleRules.damage_to_hero(_hero("soldate"), 10, true).dmg, 6, "la Garde encaisse 60 %")
	assert_eq(BattleRules.damage_to_hero(_hero("gamin", {"defend": true}), 10, false).note, "Défense", "Défense notée")
	assert_eq(BattleRules.damage_to_hero(_hero("gamin", {"defend": true}), 10, false).dmg, 5, "Défense : moitié")
	var r := BattleRules.damage_to_hero(_hero("ilo", {"rempart": 2}), 16, false)
	assert_eq(r.dmg, 8, "Rempart : moitié")
	assert_true(r.use_rempart, "une charge de Rempart consommée")
	var all := BattleRules.damage_to_hero(_hero("soldate", {"defend": true, "rempart": 1}), 20, true)
	assert_eq(all.dmg, 3, "Garde, Défense et Rempart se cumulent (20 × 0,6 × 0,5 × 0,5)")
	assert_eq(BattleRules.damage_to_hero(_hero("soldate", {"defend": true, "rempart": 1}), 1, true).dmg, 1, "au moins 1")


func test_pv_jamais_negatifs() -> void:
	assert_eq(BattleRules.hp_after(5, 12), 0, "PV plancher à 0")
	assert_eq(BattleRules.hp_after(50, 12), 38, "soustraction simple")


# ---------------------------------------------------------------- fin du combat
func test_issue_du_combat() -> void:
	var heroes := [_hero("gamin"), _hero("soldate")]
	var enemies := [_enemy("golem"), _enemy("spectre0")]
	assert_eq(BattleRules.outcome(heroes, enemies), BattleRules.OUTCOME_NONE, "tout le monde debout : on continue")
	enemies[0].alive = false
	assert_eq(BattleRules.outcome(heroes, enemies), BattleRules.OUTCOME_NONE, "un ennemi restant : on continue")
	enemies[1].alive = false
	assert_eq(BattleRules.outcome(heroes, enemies), BattleRules.OUTCOME_VICTORY, "tous les ennemis tombés : victoire")
	enemies[1].alive = true
	heroes[0].alive = false; heroes[1].alive = false
	assert_eq(BattleRules.outcome(heroes, enemies), BattleRules.OUTCOME_DEFEAT, "tous les héros K.O. : défaite")
	enemies[1].alive = false
	assert_eq(BattleRules.outcome(heroes, enemies), BattleRules.OUTCOME_VICTORY, "les deux à la fois : la victoire l'emporte (comme avant)")


## Duel joué avec les règles seules : le Gamin attaque à chaque jauge pleine, la Cauchemerle aussi.
## Renvoie [issue, nombre de tours du Gamin].
func _duel() -> Array:
	var g := _hero("gamin", {"hp": 60, "max_hp": 60, "atb": 0.0, "spd": 1.2})
	var e := _enemy("cauchemerle0", {"hp": 40, "max_hp": 40, "atb": 0.0, "spd": 0.8})
	var turns := 0
	var t := 0.0
	var dt := 1.0 / 60.0
	while BattleRules.outcome([g], [e]) == BattleRules.OUTCOME_NONE and t < 300.0:
		t += dt
		g.atb = BattleRules.atb_after(g.atb, g.spd, dt, false)
		e.atb = BattleRules.atb_after(e.atb, e.spd, dt, false)
		if g.atb >= BattleRules.ATB_FULL:
			g.atb = 0.0; turns += 1
			var r: Array = BattleRules.attack_range("gamin")
			if randf() >= BattleRules.dodge_chance(e, "phys"):
				e.hp = BattleRules.hp_after(e.hp, BattleRules.damage_to_enemy(e, randi_range(r[0], r[1]), "phys").dmg)
				e.alive = e.hp > 0
		if e.alive and e.atb >= BattleRules.ATB_FULL:
			e.atb = 0.0
			g.hp = BattleRules.hp_after(g.hp, BattleRules.damage_to_hero(g, randi_range(4, 5), false).dmg)
			g.alive = g.hp > 0
	return [BattleRules.outcome([g], [e]), turns]


func test_duels_simules() -> void:
	seed(7)
	var wins := 0
	var total_turns := 0
	for i in 200:
		var r := _duel()
		if r[0] == BattleRules.OUTCOME_VICTORY: wins += 1
		total_turns += r[1]
	assert_eq(wins, 200, "le Gamin gagne toujours ce duel d'initiation")
	assert_between(total_turns / 200.0, 5.0, 8.0, "en 5 à 8 tours en moyenne")
