class_name TestCase
extends RefCounted
## Base des tests (API inspirée de GUT : assert_eq, assert_true…).
## Chaque fichier tests/unit/test_*.gd hérite de cette classe ; chaque méthode test_*
## est un test (elle peut utiliser await). before_each / after_each encadrent chaque test.

var tree: SceneTree
var _failures: Array[String] = []
var asserts := 0


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func _record(ok: bool, what: String) -> void:
	asserts += 1
	if not ok:
		_failures.append(what)


func assert_true(cond: bool, what := "") -> void:
	_record(cond, "attendu vrai : %s" % what)


func assert_false(cond: bool, what := "") -> void:
	_record(not cond, "attendu faux : %s" % what)


func assert_eq(got: Variant, expected: Variant, what := "") -> void:
	var ok: bool = typeof(got) == typeof(expected) and got == expected
	_record(ok, "%s : obtenu <%s>, attendu <%s>" % [what, var_to_str(got), var_to_str(expected)])


func assert_ne(got: Variant, other: Variant, what := "") -> void:
	_record(not (typeof(got) == typeof(other) and got == other), "%s : ne devait pas valoir <%s>" % [what, var_to_str(other)])


func assert_between(got: float, lo: float, hi: float, what := "") -> void:
	_record(got >= lo and got <= hi, "%s : %s hors de [%s, %s]" % [what, got, lo, hi])


func assert_has(container: Variant, item: Variant, what := "") -> void:
	var ok := false
	if container is Dictionary or container is Array or container is String:
		ok = container.has(item) if not (container is String) else container.contains(str(item))
	_record(ok, "%s : <%s> absent" % [what, var_to_str(item)])


func fail(what: String) -> void:
	_record(false, what)


## Échecs du test en cours (lus puis vidés par le lanceur).
func take_failures() -> Array[String]:
	var f := _failures.duplicate()
	_failures.clear()
	return f
