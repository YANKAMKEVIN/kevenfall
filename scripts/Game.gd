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
		if a.begins_with("--shots"):
			add_child(load("res://tools/AutoShots.gd").new())

func reset() -> void:
	shards = 0; shards_taken = {}; talked_soldate = false; flags = {}

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
func keys(s: String) -> String:
	if not pad:
		return s
	for pair in [["← →", "Croix ◄ ►"], ["Espace", "A"], ["X  Foudre", "B  Foudre"], ["E  ", "X  "], ["E · ", "X · "],
			["↓  se cacher", "Croix ▼  se cacher"], ["Échap  pause", "Start  pause"], ["Échap : reprendre", "Start : reprendre"], ["Q : revenir", "B : revenir"], ["Entrée", "A"], ["↑ ↓", "Croix ▲ ▼"]]:
		s = s.replace(pair[0], pair[1])
	return s
