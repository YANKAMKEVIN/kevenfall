extends Node
## État global de la tranche + sons + utilitaires visuels.

const GOLD := Color("ffd35a")
const CYAN := Color("5ee7ff")
const INK := Color("0b0a1f")
const PLUM := Color("3a1f4f")
const STONE := Color("c9a46a")

const SHARDS_TOTAL := 13
var shards := 0          # éclats de rêve trouvés (bonus de PV max au combat)
var shards_taken := {}   # id -> true
var talked_soldate := false
var flags := {}
var music_player: AudioStreamPlayer
var amb_player: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _cache := {}
var font_title: FontVariation
var font_body: FontVariation
var pad := false         # vrai quand la dernière touche venait d'une manette : les aides affichent les boutons
var font_bold: FontVariation
var glow_tex: GradientTexture2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new(); add_child(music_player)
	amb_player = AudioStreamPlayer.new(); add_child(amb_player)
	for i in 8:
		var p := AudioStreamPlayer.new(); add_child(p); _sfx.append(p)
	var cin: FontFile = load("res://fonts/Cinzel.ttf")
	var nun: FontFile = load("res://fonts/Nunito.ttf")
	font_title = FontVariation.new(); font_title.base_font = cin
	font_title.variation_opentype = {"wght": 800}
	font_body = FontVariation.new(); font_body.base_font = nun
	font_body.variation_opentype = {"wght": 500}
	font_bold = FontVariation.new(); font_bold.base_font = nun
	font_bold.variation_opentype = {"wght": 800}
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1)); g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35, Color(1, 1, 1, 0.45))
	glow_tex = GradientTexture2D.new()
	glow_tex.gradient = g; glow_tex.width = 128; glow_tex.height = 128
	glow_tex.fill = GradientTexture2D.FILL_RADIAL
	glow_tex.fill_from = Vector2(0.5, 0.5); glow_tex.fill_to = Vector2(1.0, 0.5)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots") or a == "--parcours":
			_start_tool("res://tools/AutoShots.gd")
		if a == "--unit" or a.begins_with("--unit="):
			_start_tool("res://tests/TestRunner.gd")

## Outils lancés en ligne de commande (robot, tests) : un script qui ne se charge pas
## termine le programme en échec au lieu de le laisser tourner sans fin.
func _start_tool(path: String) -> void:
	var s: Variant = load(path)
	if s is GDScript and (s as GDScript).can_instantiate():
		add_child((s as GDScript).new())
	else:
		printerr("ECHEC : %s ne se charge pas" % path)
		get_tree().quit.call_deferred(1)

# ------------------------------------------------------------------ arrière-plan
# Fenêtre, onglet ou appli en arrière-plan : le jeu se met en pause (plus de calcul ni de
# rendu inutiles, la batterie est épargnée, et le joueur ne perd pas un combat en son absence).
# Seule une pause posée ici est levée au retour : une pause du jeu lui-même n'est pas touchée.
var bg_paused := false
var bg_pause_enabled := DisplayServer.get_name() != "headless"  # tests et robot : pas de fenêtre

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			set_background(true)
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			set_background(false)

func set_background(away: bool) -> void:
	if not is_inside_tree() or not bg_pause_enabled:
		return
	var tree := get_tree()
	if away and not tree.paused:
		tree.paused = true; bg_paused = true
		AudioServer.set_bus_mute(0, true)
	elif not away and bg_paused:
		tree.paused = false; bg_paused = false
		AudioServer.set_bus_mute(0, false)

## Numéro de version (project.godot, application/config/version).
func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))

func reset() -> void:
	shards = 0; shards_taken = {}; talked_soldate = false; flags = {}

# ------------------------------------------------------------------ sauvegarde
# Une seule sauvegarde, écrite au début de chaque chapitre (format : SaveData).
# La sauvegarde précédente est gardée en secours (.bak) : si le fichier principal est
# abîmé (coupure, disque plein, édition à la main), la partie reprend au chapitre d'avant.
var save_path := "user://sauvegarde.json"

func backup_path() -> String:
	return save_path + ".bak"

func save_game(level: String) -> bool:
	if not SaveData.LEVELS.has(level):
		return false
	var d := SaveData.make(level, shards, shards_taken, talked_soldate, _savable_flags(), version())
	if not SaveData.is_valid(d):
		push_warning("Sauvegarde refusée (état incohérent) : %s" % SaveData.to_text(d))
		return false
	# écriture dans un fichier temporaire puis renommage : une coupure ne laisse jamais un fichier à moitié écrit
	var tmp := save_path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false  # user:// indisponible (lecture seule, disque plein) : le jeu continue sans sauvegarde
	f.store_string(SaveData.to_text(d))
	var write_ok := f.get_error() == OK
	f.close()
	if not write_ok:
		DirAccess.remove_absolute(tmp)
		return false
	if not _read_file(save_path).is_empty():
		DirAccess.remove_absolute(backup_path())
		DirAccess.rename_absolute(save_path, backup_path())
	return DirAccess.rename_absolute(tmp, save_path) == OK

## Drapeaux à sauvegarder : un drapeau inconnu du format est écarté (avec un avertissement)
## au lieu de rendre toute la sauvegarde illisible.
func _savable_flags() -> Dictionary:
	var out := {}
	for k: Variant in flags:
		if SaveData.is_flag_valid(str(k), flags[k]):
			out[k] = flags[k]
		else:
			push_warning("Drapeau non sauvegardé (inconnu du format) : %s" % str(k))
	return out

func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null or f.get_length() > SaveData.MAX_BYTES:
		return {}
	return SaveData.parse(f.get_as_text())

## Sauvegarde lisible, ou {} s'il n'y en a pas (ou si elle et son secours sont abîmés).
func read_save() -> Dictionary:
	var d := _read_file(save_path)
	return d if not d.is_empty() else _read_file(backup_path())

## Efface la sauvegarde et son secours.
func delete_save() -> void:
	for p in [save_path, backup_path(), save_path + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

## Recharge la partie ; renvoie le chapitre où reprendre, ou "" si impossible.
func load_game() -> String:
	var d := read_save()
	if d.is_empty():
		return ""
	shards = d["shards"]
	shards_taken = {}
	for k: String in d["shards_taken"]:
		shards_taken[k] = true
	talked_soldate = d["talked_soldate"]
	flags = d["flags"].duplicate(true)
	return d["level"]

func tex(id: String) -> Texture2D:
	if _cache.has(id): return _cache[id]
	var path := "res://art/%s.png" % id
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_cache[id] = t
	return t

func _stream(name: String, loop := false) -> AudioStream:
	var key := "snd_" + name
	if _cache.has(key): return _cache[key]
	var s: AudioStreamWAV = load("res://audio/%s.wav" % name)
	if loop and s:
		s = s.duplicate()
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = s.data.size() / 2
	_cache[key] = s
	return s

func sfx(name: String, vol_db := 0.0, pitch := 1.0) -> void:
	for p in _sfx:
		if not p.playing:
			p.stream = _stream(name); p.volume_db = vol_db; p.pitch_scale = pitch; p.play(); return
	_sfx[0].stream = _stream(name); _sfx[0].volume_db = vol_db; _sfx[0].play()

func music(name: String, vol_db := -8.0) -> void:
	if name == "":
		var tw := create_tween(); tw.tween_property(music_player, "volume_db", -60.0, 1.0)
		tw.tween_callback(music_player.stop); return
	var s := _stream(name, true)
	if music_player.stream == s and music_player.playing: return
	music_player.stream = s; music_player.volume_db = -40.0; music_player.play()
	create_tween().tween_property(music_player, "volume_db", vol_db, 1.5)

func ambience(on: bool) -> void:
	if on:
		if amb_player.playing: return
		amb_player.stream = _stream("rain_loop", true); amb_player.volume_db = -14.0; amb_player.play()
	else:
		amb_player.stop()

## Dessine un halo additif (à appeler depuis un CanvasItem en mode blend add).
func draw_glow(ci: CanvasItem, pos: Vector2, radius: float, col: Color) -> void:
	ci.draw_texture_rect(glow_tex, Rect2(pos - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, col)

func label(text: String, size: int, col := Color.WHITE, font: Font = null, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if font else font_body)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	return l


func _input(e: InputEvent) -> void:
	if e is InputEventJoypadButton and e.pressed:
		pad = true
	elif e is InputEventJoypadMotion and absf(e.axis_value) > 0.5:
		pad = true
	elif (e is InputEventKey and e.pressed) or e is InputEventMouseButton:
		pad = false

## Traduit une aide écrite pour le clavier en boutons de manette (si on joue à la manette).
## Le résultat est mémorisé : l'aide est relue à chaque image, sans refaire les remplacements.
var _pad_keys := {}
func keys(s: String) -> String:
	if not pad:
		return s
	var known: Variant = _pad_keys.get(s)
	if known != null:
		return known
	var src := s
	for pair in [["← →", "Croix ◄ ►"], ["Espace", "A"], ["X  Foudre", "B  Foudre"], ["E  ", "X  "], ["E · ", "X · "],
			["↓  se cacher", "Croix ▼  se cacher"], ["Échap  pause", "Start  pause"], ["Échap : reprendre", "Start : reprendre"], ["Q : revenir", "B : revenir"], ["Entrée", "A"], ["↑ ↓", "Croix ▲ ▼"]]:
		s = s.replace(pair[0], pair[1])
	if _pad_keys.size() > 256:
		_pad_keys.clear()
	_pad_keys[src] = s
	return s
