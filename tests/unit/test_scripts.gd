extends TestCase
## Hygiène du code : tous les scripts se chargent sans erreur, aucun ne dépasse 400 lignes.

const ROOTS: Array[String] = ["res://scripts", "res://tools", "res://tests"]
const MAX_LINES := 400


func _scripts(dir: String, out: Array[String]) -> Array[String]:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for d in DirAccess.get_directories_at(dir):
		_scripts(dir + "/" + d, out)
	return out


func _all() -> Array[String]:
	var out: Array[String] = []
	for r in ROOTS:
		_scripts(r, out)
	return out


func test_tous_les_scripts_se_chargent() -> void:
	var files := _all()
	assert_true(files.size() >= 40, "scripts trouvés (%d)" % files.size())
	for p in files:
		var s: Variant = load(p)
		assert_true(s is GDScript and (s as GDScript).can_instantiate(), "%s se charge sans erreur" % p)


func test_taille_des_fichiers() -> void:
	for p in _all():
		var n := FileAccess.get_file_as_string(p).count("\n")
		assert_true(n <= MAX_LINES, "%s : %d lignes (max %d)" % [p, n, MAX_LINES])


func test_chapitres_du_titre() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/Title.gd")
	for c in Story.CHAPTERS:
		assert_true(src.contains('lvl = "%s"' % c.level) or c.level == "Village", "le menu Chapitres propose %s" % c.level)
