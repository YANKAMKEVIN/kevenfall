extends Control
## Écran titre.

var main
var args := {}
var sky: ColorRect
var sky_mat: ShaderMaterial
var bg: TextureRect
var logo: Label
var items: Array[Label] = []
var sel := 0
var menu_box: VBoxContainer
var entries: Array = []
const MAIN_MENU := ["Nouvelle partie", "Chapitres", "Quitter"]
const MAIN_MENU_SAVE := ["Continuer", "Nouvelle partie", "Chapitres", "Quitter"]
const CHAPTERS := ["I · 1  Le village des Plumes", "I · 2  Le convoi", "I · 3  Le Pont de l'Oiseau", "II · 4  Le centre d'extraction", "II · 5  Les mines profondes", "II · 6  Le rêve de la Tortue", "II · 7  La Grande Foreuse", "III · 8  La mer de brume", "III · 9  Le dernier temple", "III · 10  La flotte d'Orsane", "III · 11  Le Rêve Commun", "Retour"]
var t := 0.0
var next_flash := 2.0
var hint: Label
var ready_input := false

func _ready() -> void:
	size = get_viewport_rect().size
	get_viewport().size_changed.connect(_on_resize)
	sky = ColorRect.new(); sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky_mat = ShaderMaterial.new(); sky_mat.shader = load("res://shaders/sky.gdshader")
	sky.material = sky_mat; add_child(sky)
	var art := Game.tex("titre")
	if art:
		bg = TextureRect.new(); bg.texture = art
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(bg)
	var vignette := _vignette(); add_child(vignette)
	var rain := Rain.new(); rain.alpha = 0.25; add_child(rain)
	logo = Game.label("KEVENFALL", 120, Game.GOLD, Game.font_title, 0)
	logo.add_theme_constant_override("outline_size", 18)
	logo.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.12, 0.9))
	logo.add_theme_color_override("font_shadow_color", Color(0.37, 0.9, 1.0, 0.55))
	logo.add_theme_constant_override("shadow_offset_x", 0)
	logo.add_theme_constant_override("shadow_offset_y", 0)
	logo.add_theme_constant_override("shadow_outline_size", 34)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.set_anchors_preset(Control.PRESET_CENTER_TOP); logo.position = Vector2(-460, 70); logo.size = Vector2(920, 160)
	add_child(logo)
	var sub := Game.label("L'Oiseau d'Orage  ·  La Tortue-Montagne", 30, Color(0.85, 0.92, 1.0), Game.font_title, 8)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.set_anchors_preset(Control.PRESET_CENTER_TOP); sub.position = Vector2(-460, 225); sub.size = Vector2(920, 40)
	add_child(sub)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	box.position = Vector2(-350, -230); box.size = Vector2(700, 150)
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	menu_box = box
	_set_menu(_main_menu())
	hint = Game.label(Game.keys("↑ ↓ pour choisir  ·  Entrée pour valider"), 18, Color(0.8, 0.85, 1.0, 0.7), Game.font_body, 6)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM); hint.position = Vector2(-300, -60); hint.size = Vector2(600, 30)
	add_child(hint)
	var ver := Game.label("Kevenfall · v0.5", 14, Color(1, 1, 1, 0.4))
	ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT); ver.position = Vector2(-260, -30)
	add_child(ver)
	Game.music("music_explore", -6.0)
	Game.ambience(true)
	_refresh()
	await get_tree().create_timer(0.6).timeout
	ready_input = true

func _on_resize() -> void:
	size = get_viewport_rect().size

func _vignette() -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0)); g.set_color(1, Color(0.01, 0.0, 0.05, 0.85))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.45); gt.fill_to = Vector2(1.15, 0.45); gt.width = 256; gt.height = 256
	var r := TextureRect.new(); r.texture = gt; r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func _set_menu(list: Array) -> void:
	for c in items: c.queue_free()
	items.clear(); entries = list; sel = 0
	for e in list:
		var l := Game.label(e, 34 if list.size() <= 4 else (26 if list.size() <= 6 else 19), Color.WHITE, Game.font_bold, 10)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		menu_box.add_child(l); items.append(l)
	menu_box.position.y = -230 if list.size() <= 3 else (-370 if list.size() <= 8 else -455)
	menu_box.add_theme_constant_override("separation", 10 if list.size() <= 8 else 1)
	if is_inside_tree(): _refresh()

func _refresh() -> void:
	for i in items.size():
		items[i].text = ("◆  %s  ◆" if i == sel else "%s") % entries[i]
		items[i].add_theme_color_override("font_color", Game.GOLD if i == sel else Color(1, 1, 1, 0.75))

func _process(delta: float) -> void:
	t += delta
	logo.modulate = Color(1, 1, 1, 1).lerp(Color(1.2, 1.2, 1.3), 0.5 + 0.5 * sin(t * 2.0))
	next_flash -= delta
	var f: float = sky_mat.get_shader_parameter("flash") if sky_mat.get_shader_parameter("flash") != null else 0.0
	sky_mat.set_shader_parameter("flash", max(0.0, f - delta * 2.5))
	if bg: bg.modulate = Color(1, 1, 1).lerp(Color(1.6, 1.6, 1.9), clampf(f, 0.0, 1.0) * 0.5)
	if next_flash <= 0.0:
		next_flash = randf_range(4.0, 9.0)
		sky_mat.set_shader_parameter("flash", 1.0)
		Game.sfx("thunder", -10.0, randf_range(0.85, 1.1))

func _main_menu() -> Array:
	return MAIN_MENU_SAVE if not Game.read_save().is_empty() else MAIN_MENU

func _unhandled_input(e: InputEvent) -> void:
	if not ready_input: return
	if e.is_action_pressed("ui_down"):
		sel = (sel + 1) % items.size(); Game.sfx("select", -6.0); _refresh()
	elif e.is_action_pressed("ui_up"):
		sel = (sel - 1 + items.size()) % items.size(); Game.sfx("select", -6.0); _refresh()
	elif e.is_action_pressed("ui_cancel") and entries == CHAPTERS:
		Game.sfx("cancel", -6.0); _set_menu(_main_menu())
	elif e.is_action_pressed("ui_accept") or e.is_action_pressed("interact"):
		Game.sfx("confirm", -4.0)
		var choice: String = entries[sel]
		if choice == "Chapitres":
			_set_menu(CHAPTERS); return
		if choice == "Retour":
			_set_menu(_main_menu()); return
		if choice == "Quitter":
			get_tree().quit(); return
		if choice == "Continuer":
			var at := Game.load_game()
			if at != "":
				ready_input = false
				main.goto("explore", {"level": at}); return
		ready_input = false
		Game.reset()
		var lvl := "Village"
		if choice.begins_with("I · 2"): lvl = "Convoi"
		elif choice.begins_with("I · 3"): lvl = "Pont"
		elif choice.begins_with("II · 4"): lvl = "Centre"
		elif choice.begins_with("II · 5"): lvl = "Mines"
		elif choice.begins_with("II · 6"): lvl = "Reve"
		elif choice.begins_with("II · 7"): lvl = "Effondrement"
		elif choice.begins_with("III · 8"): lvl = "Brume"
		elif choice.begins_with("III · 9"): lvl = "Temple"
		elif choice.begins_with("III · 10"): lvl = "Flotte"
		elif choice.begins_with("III · 11"): lvl = "ReveCommun"
		# Nouvelle partie : on écrase la sauvegarde. Chapitres : simple rejeu, la sauvegarde
		# n'est réécrite qu'au chapitre suivant.
		main.goto("explore", {"level": lvl, "nosave": choice != "Nouvelle partie"})
