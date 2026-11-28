extends Node
## Lance les tests de tests/unit/ (fichiers test_*.gd, méthodes test_*).
## godot --headless --path . -- --unit            tous les tests
## godot --headless --path . -- --unit=save,story les fichiers dont le nom contient un des motifs
## Code de sortie 1 si un test échoue (ou si un fichier de test ne se charge pas).

const DIR := "res://tests/unit/"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame  # laisse l'autoload Game finir son _ready
	var code := await run_all(_filters())
	get_tree().quit(code)


func _filters() -> PackedStringArray:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--unit="):
			return a.substr(7).split(",", false)
	return PackedStringArray()


static func test_files(filters: PackedStringArray) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(DIR):
		if not (f.begins_with("test_") and f.ends_with(".gd")):
			continue
		if not filters.is_empty() and not Array(filters).any(func(m: String) -> bool: return f.contains(m)):
			continue
		out.append(DIR + f)
	out.sort()
	return out


func run_all(filters: PackedStringArray) -> int:
	var files := test_files(filters)
	var tests := 0
	var asserts := 0
	var failed: Array[String] = []
	var t0 := Time.get_ticks_msec()
	if files.is_empty():
		print("ECHEC aucun fichier de test trouvé")
		return 1
	for path in files:
		var script: Variant = load(path)
		if not (script is GDScript) or not (script as GDScript).can_instantiate():
			failed.append(path + " : script illisible")
			print("ECHEC ", path, " : le fichier ne se charge pas")
			continue
		var tc: Object = (script as GDScript).new()
		if not (tc is TestCase):
			failed.append(path + " : n'hérite pas de TestCase")
			continue
		var case := tc as TestCase
		case.tree = get_tree()
		print("== ", path.get_file())
		for m in case.get_method_list():
			var name: String = m.name
			if not name.begins_with("test_"):
				continue
			tests += 1
			case.before_each()
			await case.call(name)
			case.after_each()
			var errs := case.take_failures()
			if errs.is_empty():
				print("OK    ", name)
			else:
				for e in errs:
					print("ECHEC ", name, " : ", e)
				failed.append("%s::%s" % [path.get_file(), name])
		asserts += case.asserts
	print("RESULTAT : %d test(s), %d assertion(s), %d échec(s) en %d ms" % [tests, asserts, failed.size(), Time.get_ticks_msec() - t0])
	for f in failed:
		print("  - ", f)
	return 1 if not failed.is_empty() or tests == 0 else 0
