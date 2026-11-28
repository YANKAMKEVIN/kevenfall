extends Node
## Robot de parcours, couche 1 : outils (attendre, appuyer, capturer), pilote automatique
## des dialogues et des combats, et contrôles de fin de partie (chapitres traversés,
## sauvegarde relue à chaque chapitre, fin atteinte).
## Couches : BotBase -> BotActs12 (actes I et II) -> tools/AutoShots.gd (fin de l'acte II, acte III).

## Chapitre de départ selon l'option de lancement, et dernier chapitre selon --stop-after=.
const START := {"--act2": "Centre", "--fin2": "Reve", "--act3": "Brume", "--final": "ReveCommun"}
const STOP := {"act1": "Pont", "act2": "Mines", "fin2": "Effondrement", "act3a": "Flotte"}
const SAVE_PATH := "user://parcours_sauvegarde.json"  # jamais la vraie sauvegarde du joueur

var out := "user://shots"
var main: Main
var auto_dialogue := true
var auto_battle := true
var fails := 0           # attentes de progression qui n'ont jamais abouti (le jeu est bloqué)
var visited: Array[String] = []   # chapitres traversés, dans l'ordre
var ending_seen := ""             # fin réellement jouée par le chapitre 11

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="): out = a.substr(8)
	DirAccess.make_dir_recursive_absolute(out)
	Game.save_path = SAVE_PATH
	Game.delete_save()
	process_mode = Node.PROCESS_MODE_ALWAYS
	await _run()

func _run() -> void:
	pass  # le scénario (tools/AutoShots.gd)

func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

## Capture d'écran (ignorée sans rendu : --headless).
func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOT ", name, " (sans rendu)")
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/" + name + ".png")
	print("SHOT ", name)

func press(action: String) -> void:
	var e := InputEventAction.new(); e.action = action; e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	await get_tree().process_frame
	var e2 := InputEventAction.new(); e2.action = action; e2.pressed = false
	Input.parse_input_event(e2)
	await get_tree().process_frame


var _tick := 0.0
func _process(delta: float) -> void:
	_tick += delta
	if _tick < 0.25 or main == null: return
	_tick = 0.0
	var c: Variant = main.current
	if c == null: return
	_track_chapter(c)
	if auto_dialogue and "dialogue" in c and c.dialogue and c.dialogue.active:
		press("interact")
	if auto_battle and "state" in c and c.get("encounter") != null:
		if c.state == "menu":
			var pick := 0
			for i in c.cmds.size():
				if c.cmds[i].id == "combo3" and c._can_use(c.cmds[i]): pick = i
			for i in c.cmds.size():
				if pick != 0: break
				if c.cmds[i].id in ["seisme", "rempart", "tempete", "arc"] and c._can_use(c.cmds[i]) and randf() < 0.6: pick = i
			for i in c.cmds.size():
				if pick != 0: break
				if c.cmds[i].id == "combo" and c._can_use(c.cmds[i]): pick = i; break
				if c.cmds[i].id in ["seisme", "tempete", "arc", "rempart", "chaine"] and c._can_use(c.cmds[i]) and pick == 0: pick = i
				if c.cmds[i].id in ["eclair", "garde"] and c._can_use(c.cmds[i]) and pick == 0: pick = i
			c.cmd_i = pick; c._menu_refresh()
			press("ui_accept")
		elif c.state == "target":
			press("ui_accept")

## Note chaque nouveau chapitre et vérifie que la sauvegarde automatique s'y relit.
func _track_chapter(c: Node) -> void:
	if not (c is Exploration): return
	var lvl: String = c.get_script().resource_path.get_file().get_basename()
	if not visited.is_empty() and visited[-1] == lvl: return
	if visited.has(lvl): return  # retour au chapitre après un combat
	visited.append(lvl)
	var saved: String = Game.read_save().get("level", "")
	print("CHAPITRE %d/11 : %s (sauvegarde relue : %s)" % [Story.chapter_index(lvl) + 1, lvl, saved])
	if saved != lvl:
		fails += 1
		print("ECHEC : la sauvegarde du chapitre %s ne se relit pas" % lvl)

## soft = attente seulement utile pour une capture (ex. une attaque combinée que le robot
## ne déclenche pas toujours) : son échec ne fait pas échouer le test.
func _until(cond: Callable, timeout := 60.0, soft := false) -> bool:
	var tt := 0.0
	while tt < timeout:
		if cond.call(): return true
		await _wait(0.1); tt += 0.1
	if soft:
		print("TIMEOUT (capture seulement)")
	else:
		fails += 1
		print("ECHEC : attente de progression expirée (%d s) après la capture précédente" % int(timeout))
	return false


## Fin du test : code de sortie non nul si le jeu s'est bloqué, si un chapitre attendu
## n'a pas été traversé, ou si la fin jouée n'est pas celle visée (pour la CI).
func _finish() -> void:
	var ua := OS.get_cmdline_user_args()
	var first := "Village"
	for k: String in START:
		if k in ua: first = START[k]
	var last := "ReveCommun"
	for k: String in STOP:
		if _stop_after(k): last = STOP[k]
	for i in range(Story.chapter_index(first), Story.chapter_index(last) + 1):
		var lvl: String = Story.CHAPTERS[i].level
		if not visited.has(lvl):
			fails += 1
			print("ECHEC : chapitre %s jamais atteint" % lvl)
	if last == "ReveCommun":
		print("FIN atteinte : %s (visée : %s)" % [ending_seen, _arg_fin()])
		if ending_seen != _arg_fin():
			fails += 1
			print("ECHEC : fin jouée « %s » au lieu de « %s »" % [ending_seen, _arg_fin()])
	print("RESULTAT : %d chapitre(s) traversé(s), %d échec(s)" % [visited.size(), fails])
	print("done")
	Game.delete_save()
	get_tree().quit(1 if fails > 0 else 0)

func _arg_fin() -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fin="): return a.substr(6)
	return Story.ENDING_ACCORD

func _stop_after(seg: String) -> bool:
	return ("--stop-after=" + seg) in OS.get_cmdline_user_args()

func _cur() -> Node: return main.current
