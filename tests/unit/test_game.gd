extends TestCase
## Utilitaires de Game : aides manette, version, pause en arrière-plan.


func test_aides_clavier_et_manette() -> void:
	var was := Game.pad
	Game.pad = false
	assert_eq(Game.keys("Espace  sauter"), "Espace  sauter", "au clavier, l'aide reste en touches")
	Game.pad = true
	var aide := "← →  marcher     Espace  sauter     E  parler     Échap  pause"
	var attendu := "Croix ◄ ►  marcher     A  sauter     X  parler     Start  pause"
	assert_eq(Game.keys(aide), attendu, "à la manette, l'aide passe en boutons")
	assert_eq(Game.keys(aide), attendu, "même résultat une seconde fois (mémorisé)")
	assert_eq(Game.keys("Entrée pour continuer"), "A pour continuer", "« Entrée » devient « A »")
	Game.pad = was


func test_version() -> void:
	var v := Game.version()
	var parts := v.split(".")
	assert_eq(parts.size(), 3, "version au format majeur.mineur.correctif (%s)" % v)
	assert_true(Array(parts).all(func(x: String) -> bool: return x.is_valid_int()), "trois nombres")
	assert_ne(v, "0.0.0", "lue dans project.godot")


func test_pause_en_arriere_plan() -> void:
	var was := Game.bg_pause_enabled
	Game.bg_pause_enabled = true
	Game.set_background(true)
	assert_true(tree.paused, "fenêtre en arrière-plan : le jeu se met en pause")
	assert_true(AudioServer.is_bus_mute(0), "et se tait")
	Game.set_background(false)
	assert_false(tree.paused, "retour : le jeu reprend")
	assert_false(AudioServer.is_bus_mute(0), "le son revient")
	tree.paused = true  # une pause posée par quelqu'un d'autre
	Game.set_background(true)
	Game.set_background(false)
	assert_true(tree.paused, "une pause qui n'a pas été posée par l'arrière-plan n'est pas levée")
	tree.paused = false
	Game.bg_pause_enabled = was


func test_pas_de_pause_sans_fenetre() -> void:
	var was := Game.bg_pause_enabled
	Game.bg_pause_enabled = false
	Game.set_background(true)
	assert_false(tree.paused, "sans fenêtre (robot, tests), pas de pause")
	Game.bg_pause_enabled = was
