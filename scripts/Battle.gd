extends Node2D
## Combat semi-actif à jauges : chaque combattant agit quand sa jauge est pleine.
## Pendant que tu choisis, les ennemis continuent (au ralenti).

var main
var args := {}

const FILL := 25.0          # points de jauge par seconde à vitesse 1
const MENU_SLOW := 0.3      # vitesse des ennemis pendant le choix

var fighters: Array = []
var heroes: Array = []
var enemies: Array = []
var state := "intro"         # intro, run, menu, target, anim, end
var ready_q: Array = []
var cur              # héros qui choisit
var cmds: Array = []
var cmd_i := 0
var targets: Array = []
var tgt_i := 0
var pending_cmd := ""
var t := 0.0
var shake := 0.0
var armor_hint_done := false

var world: Node2D
var fx: Fx
var glow: Fx
var ui: CanvasLayer
var rows := {}
var menu_panel: Panel
var menu_box: VBoxContainer
var menu_desc: Label
var banner: Label
var cursor: Label
var sky_mat: ShaderMaterial
var bg: Sprite2D
var flash_v := 0.0
var next_flash := 4.0
var fog_mat: ShaderMaterial

func _ready() -> void:
	_build_scene()
	_build_fighters()
	_build_ui()
	Game.music("music_battle", -6.0)
	Game.ambience(true)
	await get_tree().create_timer(0.4).timeout
	if args.get("encounter", "pont") == "centre":
		await _show_banner("L'Extracteur et la garde du centre vous barrent la route !", 1.8)
		_tip("Nouveau : Éclair chaîné frappe tous les ennemis. L'Extracteur craint la Foudre... et vole le Rêve.")
	elif args.get("encounter", "pont") == "mines":
		await _show_banner("Une meute de Rongerocs sort de la roche !", 1.8)
		_tip("Ilo rejoint le combat ! Leurs carapaces résistent aux coups : essaie Sables mouvants ou Orage invisible.")
	elif args.get("encounter", "pont") == "gardien":
		await _show_banner("Le Gardien du Rêve se lève devant vous !", 1.8)
		_tip("Sa carapace de rêve encaisse les coups et se reforme. Brisez-la avec une attaque combinée, puis frappez fort !")
	elif args.get("encounter", "pont") == "noyau":
		await _show_banner("Le Noyau de la Grande Foreuse s'éveille !", 1.8)
		_tip("Tant que les deux forets tournent, le Noyau est blindé et se surcharge. Détruisez les forets d'abord ! " + ("Nouveau : Rempart et Arc apaisant." if Game.flags.get("communion1", "bercer") == "bercer" else "Nouveau : Séisme et Tempête."))
	elif args.get("encounter", "pont") == "brume":
		await _show_banner("Les Spectres de la mer de brume encerclent le bateau !", 1.8)
		_tip("Les Spectres esquivent les coups mais craignent la Foudre. Nouveau : " + ("Berceuse d'Ilo." if Game.flags.get("communion2", "") == "bercer" else ("Marée noire d'Ilo." if Game.flags.get("communion2", "") == "eveiller" else "vos pouvoirs du rêve de la Tortue.")))
	elif args.get("encounter", "pont") == "orsane":
		await _show_banner("La Chancelière Orsane libère les trois Kevrês volés !", 1.8)
		_tip("Orsane change de Kevrê en perdant des PV : Foudre, puis Pierre (armure), puis Brume (esquive).")
	elif args.get("encounter", "pont") == "cauchemar":
		await _show_banner("Le Cauchemar Commun se dresse entre vous et les titans !", 1.8)
		_tip("Niveau 3 ! Chaque action remplit la jauge du Rêve Commun. Pleine, elle déclenche l'attaque des trois héros.")
	elif args.get("encounter", "pont") == "village":
		await _show_banner("Des Cauchemerles surgissent des plumes !", 1.6)
		_tip("Ta jauge se remplit. Quand elle est pleine, choisis une action. Les ennemis aussi ont une jauge !")
	else:
		await _show_banner("Le Golem fou et le Spectre de brume attaquent !", 2.0)
		_tip("Quand la jauge d'un héros est pleine, choisis son action. Si les deux sont pleines en même temps : attaque combinée !")
	state = "run"

# ------------------------------------------------------------------ décor
func _build_scene() -> void:
	var back := CanvasLayer.new(); back.layer = -10; add_child(back)
	var sky := ColorRect.new(); sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky_mat = ShaderMaterial.new(); sky_mat.shader = load("res://shaders/sky.gdshader")
	sky.material = sky_mat; back.add_child(sky)
	world = Node2D.new(); add_child(world)
	var enc: String = args.get("encounter", "pont")
	var village: bool = enc != "pont"
	var far_id: String = {"village": "fond_village", "centre": "fond_capitale", "mines": "fond_mines", "gardien": "fond_reve", "noyau": "fond_effondrement", "brume": "fond_brume", "orsane": "fond_flotte", "cauchemar": "fond_reve_commun"}.get(enc, "fond_combat")
	var tile_id: String = {"village": "tuile_plume", "centre": "tuile_metal", "mines": "tuile_roche", "gardien": "tuile_reve", "noyau": "tuile_metal", "brume": "tuile_navire", "orsane": "tuile_navire", "cauchemar": "tuile_reve"}.get(enc, "")
	var tx := Game.tex(far_id)
	if tx:
		bg = Sprite2D.new(); bg.texture = tx; bg.centered = false
		var sc := (820.0 if village else 760.0) / tx.get_height()
		bg.scale = Vector2(sc, sc); bg.position = Vector2(640 - tx.get_width() * sc / 2.0, -120 if village else -40)
		world.add_child(bg)
	if village:
		var tile := Game.tex(tile_id)
		if tile:
			var deck := TextureRect.new(); deck.texture = tile
			deck.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; deck.stretch_mode = TextureRect.STRETCH_TILE
			var sc2 := 300.0 / tile.get_height()
			deck.scale = Vector2(sc2, sc2); deck.position = Vector2(-20, 548)
			deck.size = Vector2(1400 / sc2, tile.get_height())
			world.add_child(deck)
	var fog := ColorRect.new(); fog_mat = ShaderMaterial.new(); fog_mat.shader = load("res://shaders/fog.gdshader")
	fog_mat.set_shader_parameter("density", 0.45); fog_mat.set_shader_parameter("tint", Color(0.55, 0.4, 0.85))
	fog.material = fog_mat; fog.position = Vector2(600, 300); fog.size = Vector2(760, 300)
	world.add_child(fog)
	glow = Fx.new(); glow.z_index = 8
	var am := CanvasItemMaterial.new(); am.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = am; world.add_child(glow)
	fx = Fx.new(); fx.z_index = 9; world.add_child(fx)
	var fg := CanvasLayer.new(); fg.layer = 5; add_child(fg)
	var rain := Rain.new(); rain.alpha = 0.22; rain.count = 160; fg.add_child(rain)

var encounter := "pont"

func _build_fighters() -> void:
	encounter = args.get("encounter", "pont")
	var bonus := Game.shards * 6
	if encounter == "village":
		_add({"id": "gamin", "name": "Le Gamin", "hero": true, "hp": 64 + bonus, "pr": 12, "spd": 1.25,
			"tex": "sprite_gamin", "h": 175.0, "pos": Vector2(300, 545), "native": 1, "col": Game.GOLD})
		_add({"id": "cauche1", "name": "Cauchemerle", "hero": false, "hp": 34, "pr": 0, "spd": 0.75,
			"tex": "sprite_cauchemerle", "h": 110.0, "pos": Vector2(860, 545), "native": -1, "col": Color("b08cff")})
		_add({"id": "cauche2", "name": "Cauchemerle", "hero": false, "hp": 34, "pr": 0, "spd": 0.6,
			"tex": "sprite_cauchemerle", "h": 120.0, "pos": Vector2(1060, 535), "native": -1, "col": Color("b08cff")})
		_f("gamin").atb = 70.0; _f("cauche1").atb = 20.0; _f("cauche2").atb = 0.0
		_f("cauche2").actor.position.y = 535
		return
	if encounter in ["brume", "orsane", "cauchemar"]:
		var lv: int = {"brume": 0, "orsane": 1, "cauchemar": 2}[encounter]
		_add({"id": "soldate", "name": "La Soldate", "hero": true, "hp": 150 + 15 * lv, "pr": 12 + lv, "spd": 0.85,
			"tex": "sprite_soldate", "h": 225.0, "pos": Vector2(150, 555), "native": 1, "col": Color("e07a9a")})
		_add({"id": "gamin", "name": "Le Gamin", "hero": true, "hp": 90 + 10 * lv + bonus, "pr": 17 + lv, "spd": 1.25,
			"tex": "sprite_gamin", "h": 175.0, "pos": Vector2(290, 545), "native": 1, "col": Game.GOLD})
		_add({"id": "ilo", "name": "Ilo", "hero": true, "hp": 105 + 10 * lv, "pr": 15 + lv, "spd": 1.0,
			"tex": "sprite_ilo", "h": 230.0, "pos": Vector2(430, 552), "native": -1, "col": Color("9fb8ff")})
		if encounter == "cauchemar":
			_f("gamin").actor.modulate = Color(1.15, 1.15, 1.3, 0.75)
		if encounter == "brume":
			_add({"id": "spectre1", "name": "Spectre de brume", "hero": false, "hp": 70, "pr": 0, "spd": 0.8,
				"tex": "sprite_spectre", "h": 210.0, "pos": Vector2(780, 490), "native": -1, "col": Color("b08cff")})
			_add({"id": "spectre_ancien", "name": "Spectre ancien", "hero": false, "hp": 170, "pr": 0, "spd": 0.6,
				"tex": "sprite_spectre", "h": 300.0, "pos": Vector2(990, 500), "native": -1, "col": Color("8f6bff")})
			_add({"id": "spectre2", "name": "Spectre de brume", "hero": false, "hp": 70, "pr": 0, "spd": 0.7,
				"tex": "sprite_spectre", "h": 210.0, "pos": Vector2(1190, 490), "native": -1, "col": Color("b08cff")})
			_f("spectre_ancien").actor.modulate = Color(0.75, 0.7, 1.2)
			for id in ["spectre1", "spectre_ancien", "spectre2"]: _f(id).float = true
			_f("spectre1").atb = 30.0; _f("spectre2").atb = 10.0
		elif encounter == "orsane":
			_add({"id": "orsane", "name": "Chancelière Orsane", "hero": false, "hp": 360, "pr": 0, "spd": 0.62,
				"tex": "sprite_orsane_boss", "h": 300.0, "pos": Vector2(980, 560), "native": -1, "col": Color("d9a6ff")})
			_f("orsane").phase = 0
		else:
			_add({"id": "cauchemar", "name": "Le Cauchemar Commun", "hero": false, "hp": 480, "pr": 0, "spd": 0.55,
				"tex": "sprite_cauchemar", "h": 380.0, "pos": Vector2(980, 560), "native": -1, "col": Color("ff5e7a")})
		_f("gamin").atb = 60.0; _f("soldate").atb = 40.0; _f("ilo").atb = 50.0
		return
	if encounter == "gardien" or encounter == "noyau":
		_add({"id": "soldate", "name": "La Soldate", "hero": true, "hp": 140, "pr": 11, "spd": 0.85,
			"tex": "sprite_soldate", "h": 225.0, "pos": Vector2(150, 555), "native": 1, "col": Color("e07a9a")})
		_add({"id": "gamin", "name": "Le Gamin", "hero": true, "hp": 84 + bonus, "pr": 16, "spd": 1.25,
			"tex": "sprite_gamin", "h": 175.0, "pos": Vector2(290, 545), "native": 1, "col": Game.GOLD})
		_add({"id": "ilo", "name": "Ilo", "hero": true, "hp": 100, "pr": 14, "spd": 1.0,
			"tex": "sprite_ilo", "h": 230.0, "pos": Vector2(430, 552), "native": -1, "col": Color("9fb8ff")})
		if encounter == "gardien":
			_add({"id": "gardien", "name": "Gardien du Rêve", "hero": false, "hp": 260, "pr": 0, "spd": 0.5,
				"tex": "sprite_gardien", "h": 340.0, "pos": Vector2(960, 570), "native": -1, "col": Color("5ee7ff")})
			_f("gardien").armor = true
			_f("gamin").atb = 60.0; _f("soldate").atb = 40.0; _f("ilo").atb = 50.0; _f("gardien").atb = 0.0
		else:
			_add({"id": "foret0", "name": "Foret", "hero": false, "hp": 60, "pr": 0, "spd": 0.6,
				"tex": "sprite_noyau", "h": 120.0, "pos": Vector2(760, 470), "native": -1, "col": Color("ffb36b")})
			_add({"id": "noyau", "name": "Noyau de la Grande Foreuse", "hero": false, "hp": 280, "pr": 0, "spd": 0.45,
				"tex": "sprite_noyau", "h": 320.0, "pos": Vector2(990, 565), "native": -1, "col": Color("ff6b5e")})
			_add({"id": "foret1", "name": "Foret", "hero": false, "hp": 60, "pr": 0, "spd": 0.55,
				"tex": "sprite_noyau", "h": 120.0, "pos": Vector2(1190, 470), "native": -1, "col": Color("ffb36b")})
			_f("noyau").armor = true
			for id in ["foret0", "foret1"]:
				_f(id).float = true
				_f(id).actor.modulate = Color(1.2, 0.9, 0.8)
			_f("gamin").atb = 60.0; _f("soldate").atb = 40.0; _f("ilo").atb = 50.0
			_f("foret0").atb = 30.0; _f("foret1").atb = 10.0; _f("noyau").atb = 0.0
		return
	if encounter == "centre" or encounter == "mines":
		var three := encounter == "mines"
		_add({"id": "soldate", "name": "La Soldate", "hero": true, "hp": 130, "pr": 9, "spd": 0.85,
			"tex": "sprite_soldate", "h": 225.0, "pos": Vector2(150 if three else 200, 555), "native": 1, "col": Color("e07a9a")})
		_add({"id": "gamin", "name": "Le Gamin", "hero": true, "hp": 78 + bonus, "pr": 14, "spd": 1.25,
			"tex": "sprite_gamin", "h": 175.0, "pos": Vector2(290 if three else 330, 545), "native": 1, "col": Game.GOLD})
		if three:
			_add({"id": "ilo", "name": "Ilo", "hero": true, "hp": 95, "pr": 12, "spd": 1.0,
				"tex": "sprite_ilo", "h": 230.0, "pos": Vector2(430, 552), "native": -1, "col": Color("9fb8ff")})
			for i in 3:
				_add({"id": "rongeroc%d" % i, "name": "Rongeroc", "hero": false, "hp": 55, "pr": 0, "spd": 0.55 + i * 0.05,
					"tex": "sprite_rongeroc", "h": 120.0 + i * 10.0, "pos": Vector2(820 + i * 180, 552), "native": -1, "col": Color("c9a46a")})
				_f("rongeroc%d" % i).armor = true
				_f("rongeroc%d" % i).atb = 15.0 * i
			_f("gamin").atb = 60.0; _f("soldate").atb = 40.0; _f("ilo").atb = 55.0
		else:
			_add({"id": "garde1", "name": "Garde impérial", "hero": false, "hp": 60, "pr": 0, "spd": 0.62,
				"tex": "sprite_garde", "h": 205.0, "pos": Vector2(780, 552), "native": -1, "col": Color("c9a0ff")})
			_add({"id": "extracteur", "name": "L'Extracteur", "hero": false, "hp": 165, "pr": 0, "spd": 0.45,
				"tex": "sprite_extracteur", "h": 270.0, "pos": Vector2(990, 562), "native": -1, "col": Color("ff6b5e")})
			_add({"id": "garde2", "name": "Garde impérial", "hero": false, "hp": 60, "pr": 0, "spd": 0.55,
				"tex": "sprite_garde", "h": 205.0, "pos": Vector2(1190, 552), "native": -1, "col": Color("c9a0ff")})
			_f("gamin").atb = 60.0; _f("soldate").atb = 45.0; _f("garde1").atb = 20.0; _f("extracteur").atb = 0.0; _f("garde2").atb = 35.0
		return
	_add({"id": "gamin", "name": "Le Gamin", "hero": true, "hp": 64 + bonus, "pr": 12, "spd": 1.25,
		"tex": "sprite_gamin", "h": 175.0, "pos": Vector2(330, 545), "native": 1, "col": Game.GOLD})
	_add({"id": "soldate", "name": "La Soldate", "hero": true, "hp": 120, "pr": 8, "spd": 0.85,
		"tex": "sprite_soldate", "h": 225.0, "pos": Vector2(200, 555), "native": 1, "col": Color("e07a9a")})
	_add({"id": "golem", "name": "Golem de l'Empire", "hero": false, "hp": 150, "pr": 0, "spd": 0.42,
		"tex": "sprite_golem", "h": 300.0, "pos": Vector2(880, 560), "native": -1, "col": Color("ff6b5e")})
	_add({"id": "spectre", "name": "Spectre de brume", "hero": false, "hp": 80, "pr": 0, "spd": 0.8,
		"tex": "sprite_spectre", "h": 250.0, "pos": Vector2(1120, 500), "native": -1, "col": Color("b08cff")})
	var g = _f("golem"); g.armor = true; g.turns = 0
	_f("spectre").float = true
	_f("gamin").atb = 55.0; _f("soldate").atb = 30.0; _f("golem").atb = 10.0; _f("spectre").atb = 25.0

func _add(d: Dictionary) -> void:
	var f := {"h": d.h, "veil": 0, "rempart": 0, "overload": false, "slow": 0.0, "was_armored": false, "id": d.id, "name": d.name, "hero": d.hero, "hp": d.hp, "max_hp": d.hp, "pr": d.pr, "max_pr": d.pr,
		"spd": d.spd, "atb": 0.0, "alive": true, "defend": false, "guarded_by": null, "armor": false,
		"float": false, "charging": false, "turns": 0, "home": d.pos, "col": d.col}
	var a := Actor.new().setup(d.tex, d.h, d.native)
	a.position = d.pos; a.facing = 1 if d.hero else -1
	a.z_index = 2 if d.hero else 1
	world.add_child(a)
	f.actor = a
	fighters.append(f)
	(heroes if d.hero else enemies).append(f)

func _f(id: String) -> Dictionary:
	for f in fighters:
		if f.id == id: return f
	return {}

# ------------------------------------------------------------------ interface
func _panel_style(alpha := 0.9) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.035, 0.1, alpha)
	sb.border_color = Color(0.37, 0.9, 1.0, 0.45); sb.set_border_width_all(2)
	sb.set_corner_radius_all(12); sb.shadow_color = Color(0, 0, 0, 0.5); sb.shadow_size = 10
	return sb

func _build_ui() -> void:
	ui = CanvasLayer.new(); ui.layer = 20; add_child(ui)
	var party := Panel.new(); party.add_theme_stylebox_override("panel", _panel_style())
	party.size = Vector2(760, 16 + 44 * heroes.size())
	party.position = Vector2(24, 704 - party.size.y)
	ui.add_child(party)
	var y := 12
	for h in heroes:
		rows[h.id] = _hero_row(party, h, y); y += 44
	for e in enemies:
		rows[e.id] = _enemy_bar(e)
	if Game.flags.get("niv3", false) and heroes.size() == 3:
		commun_lbl = Game.label("✦ Rêve Commun", 20, Game.GOLD, Game.font_title, 8)
		commun_lbl.position = Vector2(28, party.position.y - 40); ui.add_child(commun_lbl)
		commun_bar = Bar.new(); commun_bar.position = Vector2(200, party.position.y - 28); commun_bar.size2 = Vector2(300, 10)
		commun_bar.col = Game.GOLD; commun_bar.gauge = true; ui.add_child(commun_bar)
	menu_panel = Panel.new(); menu_panel.add_theme_stylebox_override("panel", _panel_style(0.95))
	menu_panel.position = Vector2(800, 520); menu_panel.size = Vector2(456, 184); menu_panel.visible = false
	ui.add_child(menu_panel)
	menu_box = VBoxContainer.new(); menu_box.position = Vector2(22, 14); menu_box.size = Vector2(410, 120)
	menu_box.add_theme_constant_override("separation", 2)
	menu_panel.add_child(menu_box)
	menu_desc = Game.label("", 16, Color(0.75, 0.85, 1.0), Game.font_body)
	menu_desc.position = Vector2(22, 146); menu_desc.size = Vector2(420, 30)
	menu_panel.add_child(menu_desc)
	banner = Game.label("", 30, Color.WHITE, Game.font_title, 10)
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP); banner.position = Vector2(-600, 34); banner.size = Vector2(1200, 50)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; banner.modulate.a = 0.0
	ui.add_child(banner)
	cursor = Game.label("▼", 30, Game.GOLD, Game.font_bold, 8); cursor.visible = false
	ui.add_child(cursor)

func _hero_row(parent: Control, h: Dictionary, y: int) -> Dictionary:
	var name_l := Game.label(h.name, 22, h.col, Game.font_title, 6); name_l.position = Vector2(18, y); parent.add_child(name_l)
	var hp_l := Game.label("", 20, Color.WHITE, Game.font_bold, 6); hp_l.position = Vector2(200, y + 2); parent.add_child(hp_l)
	var bar := Bar.new(); bar.position = Vector2(200, y + 30); bar.size2 = Vector2(180, 6); bar.col = Color("6bea8c"); parent.add_child(bar)
	var pr_l := Game.label("", 20, Game.CYAN, Game.font_bold, 6); pr_l.position = Vector2(410, y + 2); parent.add_child(pr_l)
	var atb := Bar.new(); atb.position = Vector2(520, y + 12); atb.size2 = Vector2(220, 14); atb.col = Game.GOLD; atb.gauge = true
	parent.add_child(atb)
	return {"hp": hp_l, "bar": bar, "pr": pr_l, "atb": atb}

func _enemy_bar(e: Dictionary) -> Dictionary:
	var box := Control.new(); ui.add_child(box)
	var n := Game.label(e.name, 17, Color.WHITE, Game.font_bold, 6); box.add_child(n)
	var bar := Bar.new(); bar.position = Vector2(0, 26); bar.size2 = Vector2(170, 7); bar.col = e.col; box.add_child(bar)
	var atb := Bar.new(); atb.position = Vector2(0, 37); atb.size2 = Vector2(170, 4); atb.col = Color(1, 1, 1, 0.7); atb.gauge = true; box.add_child(atb)
	var st := Game.label("", 14, Game.CYAN, Game.font_bold, 6); st.position = Vector2(0, 44); box.add_child(st)
	return {"box": box, "bar": bar, "atb": atb, "st": st}

func _refresh_ui() -> void:
	if commun_bar:
		commun_bar.v = commun / 100.0; commun_bar.full = commun >= 100.0
		commun_lbl.add_theme_color_override("font_color", Game.GOLD.lerp(Game.CYAN, 0.5 + 0.5 * sin(t * 5)) if commun >= 100.0 else Game.GOLD)
	for h in heroes:
		var r: Dictionary = rows[h.id]
		r.hp.text = "PV %d / %d" % [h.hp, h.max_hp]
		r.hp.add_theme_color_override("font_color", Color("ff7a7a") if h.hp < h.max_hp * 0.3 else Color.WHITE)
		r.bar.v = float(h.hp) / h.max_hp
		r.pr.text = "Rêve %d" % h.pr
		r.atb.v = h.atb / 100.0
		r.atb.full = h.atb >= 100.0 and h.alive
	for e in enemies:
		var r: Dictionary = rows[e.id]
		r.box.visible = e.alive
		var sp: Vector2 = e.actor.position + Vector2(-85, -_height(e) - 60)
		r.box.position = sp
		r.bar.v = float(e.hp) / e.max_hp
		r.atb.v = e.atb / 100.0
		var tags := []
		if e.armor: tags.append({"gardien": "Carapace de rêve", "noyau": "Blindage"}.get(e.id, "Armure de roc"))
		if e.charging: tags.append("Se charge !")
		r.st.text = "  ·  ".join(tags)
		r.st.add_theme_color_override("font_color", Color("ff8a6a") if e.charging else Game.CYAN)

func _height(f: Dictionary) -> float:
	return f.h

# ------------------------------------------------------------------ boucle
func _process(delta: float) -> void:
	t += delta
	_weather(delta)
	world.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	shake = move_toward(shake, 0.0, delta * 40.0)
	for f in enemies:
		if f.alive and f.id != "golem" and f.id != "noyau": f.actor.bob = sin(t * (2.0 if f.id.begins_with("spectre") or f.id == "cauchemar" else 5.0) + f.home.x) * (12.0 if f.id.begins_with("spectre") or f.id == "cauchemar" else 6.0)
	if state == "run" or state == "menu" or state == "target":
		var slow := 1.0 if state == "run" else MENU_SLOW
		for f in fighters:
			if not f.alive: continue
			if f.hero:
				if f.atb >= 100.0 or (state != "run" and f == cur): continue
				f.atb = minf(100.0, f.atb + FILL * f.spd * delta * slow)
				if f.atb >= 100.0:
					ready_q.append(f); Game.sfx("ready", -10.0)
			else:
				var sm := 0.5 if f.slow > 0.0 else 1.0
				f.slow = maxf(0.0, f.slow - delta)
				f.atb = minf(100.0, f.atb + FILL * f.spd * delta * slow * sm)
				if f.atb >= 100.0:
					_enemy_turn(f)
					break
		if state == "run" and ready_q.size() > 0:
			_open_menu(ready_q[0])
		elif state == "menu" and cur and _ready_sig() != menu_sig:
			var keep := cmd_i
			_open_menu(cur)
			cmd_i = mini(keep, cmds.size() - 1); _menu_refresh()
	_refresh_ui()
	_update_cursor()

func _weather(delta: float) -> void:
	next_flash -= delta
	if next_flash <= 0.0:
		next_flash = randf_range(6.0, 12.0); flash_v = 1.0
		Game.sfx("thunder", -14.0, randf_range(0.8, 1.1))
	flash_v = move_toward(flash_v, 0.0, delta * 3.0)
	if bg: bg.modulate = Color(0.85, 0.85, 0.95).lerp(Color(1.3, 1.3, 1.5), flash_v * 0.6)

func _update_cursor() -> void:
	cursor.visible = false
	if state == "menu" and cur:
		cursor.visible = true
		cursor.position = cur.actor.get_global_transform_with_canvas().origin + Vector2(-12, -_height(cur) - 45 + sin(t * 6) * 5)
		cursor.add_theme_color_override("font_color", Game.GOLD)
	elif state == "target" and targets.size() > 0:
		var tg: Dictionary = targets[tgt_i]
		cursor.visible = true
		cursor.position = tg.actor.get_global_transform_with_canvas().origin + Vector2(-12, -_height(tg) - 100 + sin(t * 6) * 5)
		cursor.add_theme_color_override("font_color", Game.CYAN)

# ------------------------------------------------------------------ menu
const COMBOS := {
	"gamin+soldate": {"id": "onde", "name": "Onde de choc", "pair": "Foudre + Pierre", "cost": {"gamin": 3, "soldate": 2},
		"desc": "Frappe tous les ennemis et brise les armures."},
	"soldate+ilo": {"id": "sables", "name": "Sables mouvants", "pair": "Pierre + Brume", "cost": {"soldate": 2, "ilo": 3},
		"desc": "Frappe tous les ennemis et ralentit leurs jauges."},
	"gamin+ilo": {"id": "orage", "name": "Orage invisible", "pair": "Foudre + Brume", "cost": {"gamin": 3, "ilo": 3},
		"desc": "La foudre frappe depuis la brume : gros dégâts, impossible à esquiver, jauges vidées."},
}

func _combo_key(a: String, b: String) -> String:
	for k in COMBOS:
		if k == a + "+" + b or k == b + "+" + a: return k
	return ""

var menu_sig := 0
var commun := 0.0
var commun_bar: Bar
var commun_lbl: Label
func _ready_sig() -> int:
	var n := 0
	for p in heroes:
		if p != cur and p.alive and p.atb >= 100.0: n += 1
	return n

func _open_menu(h: Dictionary) -> void:
	cur = h; state = "menu"; cmd_i = 0
	menu_sig = _ready_sig()
	cmds = []
	cmds.append({"id": "attack", "label": "Attaque", "desc": "Un coup simple. Les carapaces et armures l'encaissent."})
	match h.id:
		"gamin":
			cmds.append({"id": "eclair", "label": "Kevrê · Éclair   (3 Rêve)", "cost": 3, "desc": "La Foudre. Gros dégâts sur une cible, très efficace contre les spectres et les machines."})
			if Game.flags.get("foudre2", false):
				cmds.append({"id": "chaine", "label": "Kevrê · Éclair chaîné   (5 Rêve)", "cost": 5, "desc": "Foudre niveau 2 : l'éclair rebondit sur tous les ennemis."})
			match Game.flags.get("communion1", ""):
				"bercer": cmds.append({"id": "arc", "label": "Bercer · Arc apaisant" + _lv3() + "   (4 Rêve)", "cost": 4, "desc": "Une foudre douce : dégâts sur une cible, et toutes les jauges ennemies ralentissent."})
				"eveiller": cmds.append({"id": "tempete", "label": "Éveiller · Tempête" + _lv3() + "   (5 Rêve)", "cost": 5, "desc": "Énormes dégâts sur une cible. Risque de surcharge : le Gamin perd son prochain tour."})
		"soldate":
			cmds.append({"id": "garde", "label": "Kevrê · Garde   (2 Rêve)", "cost": 2, "desc": "La Pierre. Elle encaisse à la place d'un allié jusqu'à son prochain tour."})
			match Game.flags.get("communion1", ""):
				"bercer": cmds.append({"id": "rempart", "label": "Bercer · Rempart" + _lv3() + "   (4 Rêve)", "cost": 4, "desc": "Pierre niveau 2 : un bouclier sur toute l'équipe, qui divise par deux les deux prochains coups et soigne un peu."})
				"eveiller": cmds.append({"id": "seisme", "label": "Éveiller · Séisme" + _lv3() + "   (5 Rêve)", "cost": 5, "desc": "Pierre niveau 2 : la terre frappe tous les ennemis et brise les armures."})
		"ilo":
			cmds.append({"id": "voile", "label": "Kevrê · Voile   (3 Rêve)", "cost": 3, "desc": "La Brume. Toute l'équipe esquive plus facilement pendant un moment."})
			match Game.flags.get("communion2", ""):
				"bercer": cmds.append({"id": "berceuse", "label": "Bercer · Berceuse" + _lv3() + "   (4 Rêve)", "cost": 4, "desc": "Brume niveau 2 : soigne toute l'équipe et endort les jauges ennemies."})
				"eveiller": cmds.append({"id": "maree", "label": "Éveiller · Marée noire" + _lv3() + "   (5 Rêve)", "cost": 5, "desc": "Brume niveau 2 : vole la jauge des ennemis et la donne à l'équipe."})
	for p in heroes:
		if p == h or not p.alive or p.atb < 100.0: continue
		var k := _combo_key(h.id, p.id)
		if k == "": continue
		var c: Dictionary = COMBOS[k]
		cmds.append({"id": "combo", "combo": k, "partner": p, "label": "★ %s  (%s)" % [c.name, c.pair], "desc": "Attaque combinée : " + c.desc})
	if Game.flags.get("niv3", false) and heroes.size() == 3 and commun >= 100.0 and _alive(heroes).size() == 3:
		cmds.append({"id": "combo3", "label": "✦ RÊVE COMMUN  (Foudre + Pierre + Brume)", "desc": "La jauge commune est pleine : les rêves des trois titans frappent ensemble."})
	cmds.append({"id": "defend", "label": "Défense", "desc": "Réduit les dégâts de moitié et regagne 3 points de Rêve."})
	for c in menu_box.get_children(): c.queue_free()
	for c in cmds:
		var l := Game.label(c.label, 21 if cmds.size() > 4 else 22, Color.WHITE, Game.font_bold, 4)
		menu_box.add_child(l)
		c.node = l
	menu_panel.size.y = 70 + 30 * cmds.size()
	menu_panel.position.y = 704 - menu_panel.size.y
	menu_desc.position.y = menu_panel.size.y - 38
	menu_panel.visible = true
	menu_panel.modulate.a = 0.0
	create_tween().tween_property(menu_panel, "modulate:a", 1.0, 0.12)
	_menu_refresh()

func _lv3() -> String:
	return " III" if Game.flags.get("niv3", false) else ""

func _m3() -> float:
	return 1.4 if Game.flags.get("niv3", false) else 1.0

func _can_use(c: Dictionary) -> bool:
	if c.has("cost") and cur.pr < c.cost: return false
	if c.id == "combo3":
		return commun >= 100.0
	if c.has("combo"):
		var costs: Dictionary = COMBOS[c.combo].cost
		for id in costs:
			if _f(id).pr < costs[id]: return false
	return true

func _menu_refresh() -> void:
	for i in cmds.size():
		var c: Dictionary = cmds[i]
		var ok := _can_use(c)
		var col := Color.WHITE if ok else Color(1, 1, 1, 0.35)
		if c.has("combo") and ok: col = Game.GOLD.lerp(Game.CYAN, 0.5 + 0.5 * sin(t * 5))
		if i == cmd_i:
			c.node.text = "▸ " + c.label
			c.node.add_theme_color_override("font_color", Game.GOLD if ok else Color(1, 0.8, 0.5, 0.5))
		else:
			c.node.text = "   " + c.label
			c.node.add_theme_color_override("font_color", col)
	var d: String = cmds[cmd_i].desc
	if not _can_use(cmds[cmd_i]): d = "Pas assez de Rêve."
	menu_desc.text = d

func _unhandled_input(e: InputEvent) -> void:
	if state == "menu":
		if e.is_action_pressed("ui_down"):
			cmd_i = (cmd_i + 1) % cmds.size(); Game.sfx("select", -8.0); _menu_refresh()
		elif e.is_action_pressed("ui_up"):
			cmd_i = (cmd_i - 1 + cmds.size()) % cmds.size(); Game.sfx("select", -8.0); _menu_refresh()
		elif e.is_action_pressed("ui_accept") or e.is_action_pressed("interact"):
			var c: Dictionary = cmds[cmd_i]
			if not _can_use(c):
				Game.sfx("cancel", -6.0); return
			Game.sfx("confirm", -6.0)
			pending_cmd = c.id
			pending = c
			match c.id:
				"attack", "eclair", "arc", "tempete":
					_start_target(_alive(enemies))
				"garde":
					_start_target(_alive(heroes).filter(func(x): return x != cur))
				_:
					_execute(pending_cmd, null)
	elif state == "target":
		if e.is_action_pressed("ui_right") or e.is_action_pressed("ui_down"):
			tgt_i = (tgt_i + 1) % targets.size(); Game.sfx("select", -8.0)
		elif e.is_action_pressed("ui_left") or e.is_action_pressed("ui_up"):
			tgt_i = (tgt_i - 1 + targets.size()) % targets.size(); Game.sfx("select", -8.0)
		elif e.is_action_pressed("ui_accept") or e.is_action_pressed("interact"):
			Game.sfx("confirm", -6.0)
			_execute(pending_cmd, targets[tgt_i])
		elif e.is_action_pressed("ui_cancel") or e.is_action_pressed("pause"):
			Game.sfx("cancel", -6.0); state = "menu"; menu_panel.visible = true

func _start_target(list: Array) -> void:
	if list.is_empty():
		list = [cur]
	targets = list; tgt_i = 0
	if pending_cmd in ["eclair", "tempete", "arc"]:
		for i in targets.size():
			if targets[i].id in ["spectre", "extracteur", "gardien", "spectre_ancien"]: tgt_i = i
		for i in targets.size():
			if targets[i].id.begins_with("foret"): tgt_i = i; break
	if pending_cmd == "garde":
		for i in targets.size():
			if targets[i].id == "gamin": tgt_i = i
	state = "target"; menu_panel.visible = false

func _alive(list: Array) -> Array:
	return list.filter(func(f): return f.alive)

# ------------------------------------------------------------------ actions des héros
var pending := {}

func _execute(cmd: String, target) -> void:
	state = "anim"; menu_panel.visible = false
	var h: Dictionary = cur
	ready_q.erase(h)
	h.defend = false
	for o in heroes:
		if o.guarded_by == h: o.guarded_by = null
	match cmd:
		"attack":
			await _show_banner(h.name + "  ·  Attaque", 0.0)
			await _melee(h, target)
			var dmg: int = {"gamin": randi_range(7, 9), "soldate": randi_range(12, 15), "ilo": randi_range(9, 11)}[h.id] + h.get("atk_bonus", 0)
			await _hit(target, dmg, "phys")
		"eclair":
			h.pr -= 3
			await _show_banner("Le Gamin  ·  Kevrê de la Foudre : Éclair", 0.0)
			await _bolt(target)
			await _hit(target, randi_range(16, 20), "foudre")
		"chaine":
			h.pr -= 5
			await _show_banner("Le Gamin  ·  Foudre niveau 2 : Éclair chaîné", 0.0)
			var list := _alive(enemies)
			var prev: Vector2 = h.actor.position + Vector2(30, -100)
			Game.sfx("zap", 0.0, 0.9)
			for e in list:
				var p: Vector2 = e.actor.position + Vector2(0, -_height(e) * 0.5)
				fx.bolt(prev, p, Game.GOLD); fx.bolt(prev, p, Game.CYAN)
				fx.sparks(p, Game.GOLD, 16); glow.burst(p, Color(1, 0.85, 0.4, 0.8), 180.0)
				prev = p
				await get_tree().create_timer(0.12).timeout
			flash_v = 1.0; shake = 12.0
			main.flash(Color(1.0, 0.95, 0.7, 0.4), 0.3)
			for e in list:
				_hit(e, randi_range(11, 14), "foudre")
			await get_tree().create_timer(0.7).timeout
		"garde":
			h.pr -= 2
			await _show_banner("La Soldate  ·  Kevrê de la Pierre : Garde", 0.0)
			target.guarded_by = h
			Game.sfx("stone", -6.0, 1.3)
			fx.ring(target.actor.position + Vector2(0, -80), Color(1.0, 0.75, 0.35), 120.0, 0.6)
			_float_text(target.actor.position + Vector2(0, -_height(target) - 30), "Protégé", Game.STONE)
			await get_tree().create_timer(0.6).timeout
		"arc":
			h.pr -= 4
			await _show_banner("Le Gamin  ·  Bercer : Arc apaisant", 0.0)
			await _bolt(target)
			await _hit(target, int(randi_range(12, 14) * _m3()), "foudre")
			for e in _alive(enemies):
				e.slow = 10.0
				fx.ring(e.actor.position + Vector2(0, -_height(e) * 0.5), Color(0.6, 0.9, 1.0), 120.0, 0.9)
				_float_text(e.actor.position + Vector2(0, -_height(e) - 70), "Apaisé", Color("9fe3ff"), 22)
			await get_tree().create_timer(0.5).timeout
		"tempete":
			h.pr -= 5
			await _show_banner("Le Gamin  ·  Éveiller : Tempête", 0.0)
			world.modulate = Color(0.7, 0.7, 0.9)
			for k in 3:
				await _bolt(target)
			world.modulate = Color.WHITE
			await _hit(target, int(randi_range(30, 36) * _m3()), "foudre")
			if randf() < 0.35:
				h.overload = true
				_float_text(h.actor.position + Vector2(0, -_height(h) - 40), "Surcharge !", Color("ff8a6a"), 28)
				fx.sparks(h.actor.position + Vector2(0, -90), Game.GOLD, 30)
				await get_tree().create_timer(0.5).timeout
		"rempart":
			h.pr -= 4
			await _show_banner("La Soldate  ·  Bercer : Rempart", 0.0)
			Game.sfx("stone", 0.0, 0.8); shake = 10.0
			for o in _alive(heroes):
				o.rempart = 3 if Game.flags.get("niv3", false) else 2
				o.hp = mini(o.max_hp, o.hp + int(10 * _m3()))
				fx.ring(o.actor.position + Vector2(0, -90), Color(1.0, 0.8, 0.45), 130.0, 0.8)
				glow.burst(o.actor.position + Vector2(0, -90), Color(1.0, 0.75, 0.35, 0.6), 170.0)
				_float_text(o.actor.position + Vector2(0, -_height(o) - 30), "Rempart  +10", Game.STONE, 24)
			await get_tree().create_timer(0.8).timeout
		"seisme":
			h.pr -= 5
			await _show_banner("La Soldate  ·  Éveiller : Séisme", 0.0)
			var tw := create_tween(); tw.tween_property(h.actor, "position:y", h.home.y - 90, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(h.actor, "position:y", h.home.y, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			await tw.finished
			Game.sfx("stone", 6.0, 0.6); shake = 30.0
			main.flash(Color(1.0, 0.75, 0.4, 0.5), 0.4)
			fx.shockwave(Vector2(h.actor.position.x + 80, 555))
			for e in _alive(enemies):
				fx.rocks(e.actor.position)
			await get_tree().create_timer(0.4).timeout
			for e in _alive(enemies):
				_hit(e, int(randi_range(15, 18) * _m3()), "seisme")
				_break_armor(e)
			await get_tree().create_timer(0.8).timeout
		"berceuse":
			h.pr -= 4
			await _show_banner("Ilo  ·  Bercer : Berceuse", 0.0)
			Game.sfx("heal", 0.0, 0.6)
			for o in _alive(heroes):
				var hl := int(15 * _m3())
				o.hp = mini(o.max_hp, o.hp + hl)
				glow.burst(o.actor.position + Vector2(0, -90), Color(0.5, 0.95, 0.9, 0.6), 170.0)
				_float_text(o.actor.position + Vector2(0, -_height(o) - 30), "+%d" % hl, Color("6bea8c"), 30)
			for e in _alive(enemies):
				e.atb = maxf(0.0, e.atb - 35.0)
				fx.wave(h.actor.position + Vector2(20, -150), e.actor.position + Vector2(0, -_height(e) * 0.5))
				_float_text(e.actor.position + Vector2(0, -_height(e) - 70), "Endormi", Color("9fe3ff"), 22)
			await get_tree().create_timer(0.9).timeout
		"maree":
			h.pr -= 5
			await _show_banner("Ilo  ·  Éveiller : Marée noire", 0.0)
			Game.sfx("heal", -2.0, 0.3); shake = 12.0
			world.modulate = Color(0.55, 0.5, 0.75)
			var stolen := 0.0
			for e in _alive(enemies):
				stolen += minf(e.atb, 60.0)
				e.atb = maxf(0.0, e.atb - 60.0)
				fx.wave(e.actor.position + Vector2(0, -_height(e) * 0.5), h.actor.position + Vector2(0, -120))
				_hit(e, int(randi_range(8, 10) * _m3()), "combo")
			await get_tree().create_timer(0.5).timeout
			world.modulate = Color.WHITE
			for o in _alive(heroes):
				if o == h: continue
				o.atb = minf(100.0, o.atb + 25.0 + stolen * 0.2)
				if o.atb >= 100.0 and not ready_q.has(o): ready_q.append(o)
				_float_text(o.actor.position + Vector2(0, -_height(o) - 30), "Jauge +", Color("b9a6ff"), 24)
			await get_tree().create_timer(0.6).timeout
		"combo3":
			await _combo3()
		"voile":
			h.pr -= 3
			await _show_banner("Ilo  ·  Kevrê de la Brume : Voile", 0.0)
			Game.sfx("heal", -4.0, 0.7)
			for o in _alive(heroes):
				o.veil = 3
				glow.burst(o.actor.position + Vector2(0, -90), Color(0.6, 0.5, 1.0, 0.6), 160.0)
				fx.ring(o.actor.position + Vector2(0, -90), Color(0.7, 0.6, 1.0), 110.0, 0.8)
				_float_text(o.actor.position + Vector2(0, -_height(o) - 30), "Voile", Color("b9a6ff"), 24)
			await get_tree().create_timer(0.8).timeout
		"defend":
			h.defend = true
			h.pr = mini(h.max_pr, h.pr + 3)
			_float_text(h.actor.position + Vector2(0, -_height(h) - 30), "Défense  +3 Rêve", Game.CYAN)
			Game.sfx("heal", -10.0, 1.4)
			await get_tree().create_timer(0.6).timeout
		"combo":
			await _combo(pending.combo, h, pending.partner)
	if cmd != "combo3":
		h.atb = 0.0
		commun = minf(100.0, commun + 9.0)
	if h.get("overload", false):
		h.overload = false; h.atb = -70.0
	if cmd != "combo" and cmd != "combo3":
		h.pr = mini(h.max_pr, h.pr + 1)
	_hide_banner()
	await _check_end()
	if state != "end": state = "run"

func _melee(h: Dictionary, target: Dictionary) -> void:
	var a: Actor = h.actor
	var home: Vector2 = h.home
	var dest: Vector2 = target.actor.position + Vector2(-110 if h.hero else 110, 0)
	dest.y = home.y
	a.walking = true
	var tw := create_tween(); tw.tween_property(a, "position", dest, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished
	a.walking = false
	Game.sfx("slash", -2.0, randf_range(0.9, 1.1))
	fx.slash(target.actor.position + Vector2(0, -_height(target) * 0.55), h.hero)
	var tw2 := create_tween(); tw2.tween_interval(0.12)
	tw2.tween_property(a, "position", home, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(0.1).timeout

func _bolt(target: Dictionary) -> void:
	var g: Dictionary = _f("gamin")
	var tw := create_tween(); tw.tween_property(g.actor, "position:y", g.home.y - 30, 0.15)
	tw.tween_property(g.actor, "position:y", g.home.y, 0.2)
	await get_tree().create_timer(0.15).timeout
	Game.sfx("zap", 0.0)
	var p: Vector2 = target.actor.position + Vector2(0, -_height(target) * 0.5)
	fx.bolt(Vector2(p.x + randf_range(-60, 60), -40), p, Game.GOLD)
	fx.bolt(Vector2(p.x + randf_range(-60, 60), -40), p, Game.CYAN)
	fx.sparks(p, Game.GOLD, 26)
	glow.burst(p, Color(1.0, 0.85, 0.4, 0.9), 260.0)
	main.flash(Color(1.0, 0.95, 0.7, 0.45), 0.3)
	flash_v = 1.0; shake = 10.0
	await get_tree().create_timer(0.2).timeout

func _bolt_at(target: Dictionary) -> void:
	Game.sfx("zap", 0.0, 0.8)
	var p: Vector2 = target.actor.position + Vector2(0, -_height(target) * 0.5)
	fx.bolt(Vector2(p.x + randf_range(-60, 60), -40), p, Game.GOLD)
	fx.bolt(Vector2(p.x + randf_range(-60, 60), -40), p, Color("d9a6ff"))
	fx.sparks(p, Game.GOLD, 20)
	glow.burst(p, Color(1.0, 0.8, 0.4, 0.8), 200.0)
	main.flash(Color(1.0, 0.9, 0.7, 0.35), 0.3)
	flash_v = 1.0; shake = 10.0
	await get_tree().create_timer(0.25).timeout

func _combo(key: String, a: Dictionary, b: Dictionary) -> void:
	var c: Dictionary = COMBOS[key]
	ready_q.erase(a); ready_q.erase(b)
	for id in c.cost: _f(id).pr -= c.cost[id]
	await _show_banner("★  %s  ★   %s" % [c.name.to_upper(), c.pair], 0.0)
	main.flash(Color(1, 1, 1, 0.5), 0.4)
	match c.id:
		"onde": await _combo_onde()
		"sables": await _combo_sables()
		"orage": await _combo_orage()
	for e in _alive(enemies):
		if e.id in ["gardien", "orsane"]: _break_armor(e)
	a.atb = 0.0; b.atb = 0.0

func _combo3() -> void:
	var g: Dictionary = _f("gamin"); var s: Dictionary = _f("soldate"); var i: Dictionary = _f("ilo")
	commun = 0.0
	for h in heroes:
		ready_q.erase(h)
	await _show_banner("✦  RÊVE COMMUN  ✦   Foudre + Pierre + Brume", 0.0)
	main.flash(Color(1, 1, 1, 0.7), 0.6)
	Game.sfx("thunder", 2.0, 0.7)
	var tw := create_tween().set_parallel()
	for h in [g, s, i]:
		tw.tween_property(h.actor, "position:y", h.home.y - 120, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	for h in [g, s, i]:
		glow.burst(h.actor.position + Vector2(0, -100), h.col, 260.0)
		fx.ring(h.actor.position + Vector2(0, -100), h.col, 160.0, 1.0)
	await get_tree().create_timer(0.4).timeout
	world.modulate = Color(0.6, 0.6, 0.85)
	for k in 4:
		for e in _alive(enemies):
			var p: Vector2 = e.actor.position + Vector2(randf_range(-40, 40), -_height(e) * randf_range(0.3, 0.7))
			fx.bolt(Vector2(p.x + randf_range(-300, 300), -40), p, [Game.GOLD, Game.CYAN, Color("ffb3c8"), Color("b9a6ff")][k])
			fx.rocks(e.actor.position)
		Game.sfx("zap", 0.0, 0.7 + k * 0.1); Game.sfx("stone", 0.0, 0.6)
		shake = 24.0; flash_v = 1.0
		await get_tree().create_timer(0.18).timeout
	world.modulate = Color.WHITE
	main.flash(Color(1, 0.95, 0.8, 0.8), 0.6)
	fx.shockwave(Vector2(640, 555))
	glow.burst(Vector2(900, 400), Color(1, 0.9, 0.6, 0.8), 600.0)
	for e in _alive(enemies):
		_hit(e, randi_range(62, 72), "combo")
		_break_armor(e)
	var tw2 := create_tween().set_parallel()
	for h in [g, s, i]:
		tw2.tween_property(h.actor, "position:y", h.home.y, 0.4)
		h.atb = 0.0
	await get_tree().create_timer(1.0).timeout

func _break_armor(e: Dictionary) -> void:
	if not e.armor or not e.alive: return
	if e.id == "noyau" and (_f("foret0").alive or _f("foret1").alive):
		_float_text(e.actor.position + Vector2(0, -_height(e) - 70), "Blindage tenu par les forets", Color(0.8, 0.8, 0.85), 22)
		return
	e.armor = false; e.was_armored = true
	Game.sfx("stone", 0.0, 1.2)
	fx.sparks(e.actor.position + Vector2(0, -_height(e) * 0.5), Game.GOLD, 30)
	_float_text(e.actor.position + Vector2(0, -_height(e) - 70), "Armure brisée !", Game.GOLD, 30)

func _combo_onde() -> void:
	var g: Dictionary = _f("gamin"); var s: Dictionary = _f("soldate")
	var tw := create_tween().set_parallel()
	tw.tween_property(g.actor, "position:y", g.home.y - 150, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(s.actor, "position:x", s.home.x + 120, 0.25)
	await tw.finished
	Game.sfx("zap", 0.0, 0.8)
	glow.burst(g.actor.position + Vector2(0, -90), Color(1.0, 0.85, 0.35, 0.9), 200.0)
	fx.sparks(g.actor.position + Vector2(0, -90), Game.GOLD, 30)
	await get_tree().create_timer(0.25).timeout
	var tw2 := create_tween(); tw2.tween_property(g.actor, "position:y", g.home.y, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw2.finished
	Game.sfx("stone", 4.0, 0.8); Game.sfx("thunder", -2.0, 1.2)
	shake = 26.0; flash_v = 1.0
	main.flash(Color(1.0, 0.9, 0.6, 0.6), 0.5)
	fx.shockwave(Vector2(s.actor.position.x + 60, 555))
	glow.burst(Vector2(700, 520), Color(1.0, 0.7, 0.3, 0.7), 420.0)
	for e in _alive(enemies):
		fx.bolt(Vector2(e.actor.position.x, -40), e.actor.position + Vector2(0, -_height(e) * 0.5), Game.CYAN)
	await get_tree().create_timer(0.35).timeout
	for e in _alive(enemies):
		_hit(e, randi_range(24, 28), "combo")
		_break_armor(e)
		if e.id.begins_with("spectre"):
			e.atb = 0.0
			_float_text(e.actor.position + Vector2(0, -_height(e) - 70), "Jauge vidée", Game.CYAN, 22)
	var tw3 := create_tween(); tw3.tween_property(s.actor, "position:x", s.home.x, 0.4)
	await get_tree().create_timer(0.9).timeout

func _combo_sables() -> void:
	var s: Dictionary = _f("soldate"); var i: Dictionary = _f("ilo")
	var tw := create_tween().set_parallel()
	tw.tween_property(s.actor, "position:x", s.home.x + 100, 0.25)
	tw.tween_property(i.actor, "position:y", i.home.y - 40, 0.3)
	await tw.finished
	Game.sfx("stone", 2.0, 0.6); Game.sfx("heal", -2.0, 0.5)
	shake = 18.0
	for e in _alive(enemies):
		fx.ring(e.actor.position + Vector2(0, -10), Color(0.85, 0.7, 0.45), 140.0, 0.9)
		glow.burst(e.actor.position + Vector2(0, -20), Color(0.6, 0.45, 0.9, 0.7), 220.0)
		var sink := create_tween(); sink.tween_property(e.actor, "position:y", e.home.y + 25, 0.3)
		sink.tween_property(e.actor, "position:y", e.home.y, 0.6)
	await get_tree().create_timer(0.4).timeout
	for e in _alive(enemies):
		_hit(e, randi_range(15, 18), "combo")
		e.slow = 9.0
		_float_text(e.actor.position + Vector2(0, -_height(e) - 70), "Ralenti", Color("d9b98a"), 24)
	var tw2 := create_tween().set_parallel()
	tw2.tween_property(s.actor, "position:x", s.home.x, 0.4); tw2.tween_property(i.actor, "position:y", i.home.y, 0.4)
	await get_tree().create_timer(0.9).timeout

func _combo_orage() -> void:
	var g: Dictionary = _f("gamin"); var i: Dictionary = _f("ilo")
	Game.sfx("heal", -2.0, 0.4)
	for k in 3:
		glow.burst(Vector2(randf_range(700, 1150), randf_range(300, 480)), Color(0.55, 0.45, 0.95, 0.6), 300.0)
	world.modulate = Color(0.6, 0.55, 0.85)
	await get_tree().create_timer(0.5).timeout
	for k in 3:
		for e in _alive(enemies):
			var p: Vector2 = e.actor.position + Vector2(randf_range(-30, 30), -_height(e) * randf_range(0.3, 0.7))
			fx.bolt(Vector2(p.x + randf_range(-200, 200), randf_range(250, 420)), p, Game.CYAN if k % 2 else Game.GOLD)
		Game.sfx("zap", -2.0, 0.8 + k * 0.15)
		flash_v = 1.0; shake = 14.0
		await get_tree().create_timer(0.15).timeout
	world.modulate = Color.WHITE
	main.flash(Color(0.8, 0.85, 1.0, 0.6), 0.4)
	for e in _alive(enemies):
		_hit(e, randi_range(20, 24), "orage")
		e.atb = 0.0
		_float_text(e.actor.position + Vector2(0, -_height(e) - 70), "Jauge vidée", Game.CYAN, 22)
	await get_tree().create_timer(0.9).timeout

## Applique des dégâts à un ennemi.
func _hit(e: Dictionary, base: int, kind: String) -> void:
	if not e.alive: return
	var dmg := float(base)
	var note := ""
	var col := Color.WHITE
	var dodge := 0.0
	if kind == "phys":
		dodge = 0.4 if e.id.begins_with("spectre") else (0.15 if e.id.begins_with("cauche") else 0.0)
		if e.id == "orsane" and e.get("phase", 0) == 2: dodge = 0.35
	if dodge > 0.0 and randf() < dodge:
		_float_text(e.actor.position + Vector2(0, -_height(e) * 0.6), "Esquive", Color(0.75, 0.75, 0.9), 30)
		Game.sfx("cancel", -10.0, 0.7)
		var tw := create_tween(); tw.tween_property(e.actor, "position:x", e.home.x + 50, 0.12)
		tw.tween_property(e.actor, "position:x", e.home.x, 0.25)
		await get_tree().create_timer(0.5).timeout
		return
	if kind == "foudre":
		if e.id.begins_with("spectre"): dmg *= 1.5; note = "Faiblesse !"; col = Game.GOLD
		elif e.id == "extracteur" or e.id.begins_with("foret") or e.id == "noyau": dmg *= 1.3; note = "Court-circuit !"; col = Game.GOLD
		elif e.id == "golem": dmg *= 0.8
	if e.armor and kind in ["phys", "foudre"] and e.id in ["gardien", "noyau", "orsane"]:
		dmg *= 0.5 if kind == "foudre" else 0.35; note = "Résiste"; col = Color(0.7, 0.7, 0.75)
	elif e.armor and kind == "phys":
		dmg *= 0.4; note = "Résiste"; col = Color(0.7, 0.7, 0.75)
		if not armor_hint_done:
			armor_hint_done = true
			_tip("Cette carapace encaisse les coups. Utilise les Kevrês ou une attaque combinée pour la briser !")
	elif e.get("was_armored", false) and kind == "phys":
		dmg *= 1.2
	var d := maxi(1, int(round(dmg)))
	e.hp = maxi(0, e.hp - d)
	Game.sfx("hit", -2.0, randf_range(0.85, 1.15))
	_flash_actor(e.actor)
	var kb := create_tween(); kb.tween_property(e.actor, "position:x", e.home.x + 18, 0.06)
	kb.tween_property(e.actor, "position:x", e.home.x, 0.2)
	shake = maxf(shake, 6.0)
	_float_text(e.actor.position + Vector2(randf_range(-20, 20), -_height(e) * 0.6), str(d), col, 44)
	if note != "":
		_float_text(e.actor.position + Vector2(0, -_height(e) * 0.6 - 46), note, col, 22)
	if e.id == "orsane" and e.hp > 0:
		_orsane_phase(e)
	if e.hp <= 0:
		_kill(e)
	await get_tree().create_timer(0.55).timeout

func _orsane_phase(e: Dictionary) -> void:
	var want := 0
	if e.hp < e.max_hp * 0.33: want = 2
	elif e.hp < e.max_hp * 0.66: want = 1
	if want <= e.phase: return
	e.phase = want
	if want == 1:
		e.armor = true
		_float_text(e.actor.position + Vector2(0, -_height(e) - 90), "Pierre volée : armure !", Color("ffb3a0"), 30)
		Game.sfx("stone", 2.0, 0.7); shake = 16.0
		e.actor.modulate = Color(1.2, 0.95, 0.85)
		_tip("Orsane utilise la Pierre volée : son armure encaisse les coups. Séisme, Onde de choc ou une attaque combinée la brisent.")
	else:
		e.armor = false
		_float_text(e.actor.position + Vector2(0, -_height(e) - 90), "Brume volée : elle esquive !", Color("b9a6ff"), 30)
		Game.sfx("heal", 0.0, 0.4)
		e.actor.modulate = Color(0.85, 0.85, 1.2, 0.85)
		_tip("Orsane se cache dans la Brume volée : les attaques simples ratent souvent. Les Kevrês et les attaques combinées touchent toujours.")

func _kill(f: Dictionary) -> void:
	f.alive = false; f.atb = 0.0
	ready_q.erase(f)
	if f.hero:
		_float_text(f.actor.position + Vector2(0, -_height(f) - 20), "K.O.", Color("ff7a7a"), 34)
		var tw := create_tween(); tw.tween_property(f.actor, "modulate", Color(0.4, 0.4, 0.5, 0.6), 0.5)
		tw.parallel().tween_property(f.actor, "rotation", -0.3 * f.actor.facing, 0.5)
		return
	if f.id.begins_with("foret"):
		var n: Dictionary = _f("noyau")
		if n.alive and not _f("foret0").alive and not _f("foret1").alive and n.armor:
			n.armor = false; n.was_armored = true
			_float_text(n.actor.position + Vector2(0, -_height(n) - 70), "Blindage tombé !", Game.GOLD, 32)
			Game.sfx("stone", 2.0, 0.8); shake = 18.0
	Game.sfx("stone" if f.id == "golem" else "zap", 0.0, 0.6)
	fx.sparks(f.actor.position + Vector2(0, -_height(f) * 0.5), f.col, 50)
	glow.burst(f.actor.position + Vector2(0, -_height(f) * 0.5), f.col, 300.0)
	var tw := create_tween().set_parallel()
	tw.tween_property(f.actor, "modulate", Color(3, 3, 3, 0), 0.9)
	tw.tween_property(f.actor, "scale", Vector2(1.15, 0.85), 0.9)

func _flash_actor(a: Actor) -> void:
	var tw := create_tween()
	tw.tween_property(a, "modulate", Color(3, 3, 3), 0.04)
	tw.tween_property(a, "modulate", Color(1, 1, 1), 0.2)

# ------------------------------------------------------------------ ennemis
func _enemy_turn(e: Dictionary) -> void:
	var prev := state
	state = "anim"
	menu_panel.visible = false
	await _enemy_act(e)
	e.atb = 0.0
	_hide_banner()
	await _check_end()
	if state == "end": return
	if prev == "menu" or prev == "target":
		if cur and cur.alive and cur.atb >= 100.0:
			_open_menu(cur)
		else:
			state = "run"
	else:
		state = "run"

func _enemy_act(e: Dictionary) -> void:
	var alive_h := _alive(heroes)
	if alive_h.is_empty(): return
	e.turns += 1
	if e.id == "golem":
		if e.charging:
			e.charging = false
			await _show_banner("Golem de l'Empire  ·  Éboulement !", 0.0)
			Game.sfx("stone", 4.0, 0.7); shake = 22.0
			for h in alive_h:
				fx.rocks(h.actor.position)
			await get_tree().create_timer(0.45).timeout
			for h in alive_h:
				_hurt(h, randi_range(13, 16))
			await get_tree().create_timer(0.7).timeout
		elif e.turns % 3 == 0:
			e.charging = true
			await _show_banner("Le Golem accumule une énergie instable...", 0.0)
			Game.sfx("stone", -6.0, 0.5)
			glow.burst(e.actor.position + Vector2(0, -150), Color(1.0, 0.3, 0.2, 0.8), 260.0)
			_float_text(e.actor.position + Vector2(0, -_height(e) - 40), "Défendez-vous !", Color("ff8a6a"), 24)
			await get_tree().create_timer(1.0).timeout
		else:
			var tg: Dictionary = _pick_target(alive_h)
			await _show_banner("Golem de l'Empire  ·  Coup de roc", 0.0)
			await _melee(e, _redirect(tg))
			Game.sfx("stone", 0.0, 1.1)
			_hurt(tg, randi_range(13, 16))
			await get_tree().create_timer(0.6).timeout
	elif e.id.begins_with("garde"):
		var tg: Dictionary = _pick_target(alive_h)
		if randf() < 0.25:
			await _show_banner("Garde impérial  ·  Lanterne aveuglante", 0.0)
			glow.burst(_redirect(tg).actor.position + Vector2(0, -100), Color(1.0, 0.85, 0.4, 0.9), 220.0)
			main.flash(Color(1, 0.9, 0.6, 0.35), 0.3)
			await get_tree().create_timer(0.3).timeout
			_hurt(tg, randi_range(4, 5))
			var real: Dictionary = _redirect(tg)
			if real.alive:
				real.atb = maxf(0.0, real.atb - 50.0); ready_q.erase(real)
				_float_text(real.actor.position + Vector2(0, -_height(real) - 70), "Ébloui", Game.GOLD, 22)
		else:
			await _show_banner("Garde impérial  ·  Coup de lance", 0.0)
			await _melee(e, _redirect(tg))
			_hurt(tg, randi_range(9, 12))
		await get_tree().create_timer(0.5).timeout
	elif e.id == "extracteur":
		if e.turns % 3 == 0:
			var tg: Dictionary = _f("gamin") if _f("gamin").alive else alive_h[0]
			await _show_banner("L'Extracteur  ·  Extraction !", 0.0)
			var real: Dictionary = _redirect(tg)
			fx.wave(e.actor.position + Vector2(-60, -150), real.actor.position + Vector2(0, -90))
			fx.wave(e.actor.position + Vector2(-60, -130), real.actor.position + Vector2(0, -70))
			Game.sfx("zap", -2.0, 0.5); Game.sfx("heal", -4.0, 0.4)
			await get_tree().create_timer(0.6).timeout
			_hurt(tg, randi_range(9, 11))
			if real.alive:
				var lost := mini(real.pr, 4)
				real.pr -= lost
				_float_text(real.actor.position + Vector2(0, -_height(real) - 70), "-%d Rêve" % lost, Game.CYAN, 24)
			e.hp = mini(e.max_hp, e.hp + 14)
			glow.burst(e.actor.position + Vector2(0, -140), Color(0.3, 0.9, 1.0, 0.8), 240.0)
			_float_text(e.actor.position + Vector2(0, -_height(e) - 40), "+14", Color("6bea8c"), 30)
			await get_tree().create_timer(0.7).timeout
		else:
			var tg: Dictionary = _pick_target(alive_h)
			await _show_banner("L'Extracteur  ·  Aiguilles", 0.0)
			await _melee(e, _redirect(tg))
			_hurt(tg, randi_range(11, 14))
			await get_tree().create_timer(0.5).timeout
	elif e.id == "orsane":
		var tg: Dictionary = _pick_target(alive_h)
		if e.phase == 0:
			if e.turns % 3 == 0:
				await _show_banner("Orsane  ·  Foudre volée : Tempête de l'Empire", 0.0)
				for h in alive_h:
					fx.bolt(Vector2(h.actor.position.x + randf_range(-80, 80), -40), h.actor.position + Vector2(0, -90), Game.GOLD)
				Game.sfx("zap", 2.0, 0.7); shake = 18.0; main.flash(Color(1, 0.9, 0.5, 0.4), 0.3)
				await get_tree().create_timer(0.3).timeout
				for h in alive_h: _hurt(h, randi_range(11, 14))
			else:
				await _show_banner("Orsane  ·  Foudre volée : Éclair", 0.0)
				await _bolt_at(_redirect(tg))
				_hurt(tg, randi_range(15, 18))
		elif e.phase == 1:
			if e.turns % 3 == 0:
				await _show_banner("Orsane  ·  Pierre volée : Écrasement", 0.0)
				Game.sfx("stone", 4.0, 0.6); shake = 24.0
				for h in alive_h: fx.rocks(h.actor.position)
				await get_tree().create_timer(0.45).timeout
				for h in alive_h: _hurt(h, randi_range(13, 16))
			else:
				await _show_banner("Orsane  ·  Gantelet de pierre", 0.0)
				await _melee(e, _redirect(tg))
				Game.sfx("stone", 0.0, 1.0)
				_hurt(tg, randi_range(16, 19))
		else:
			if e.turns % 2 == 0:
				await _show_banner("Orsane  ·  Brume volée : Extraction", 0.0)
				var real: Dictionary = _redirect(tg)
				fx.wave(e.actor.position + Vector2(-60, -150), real.actor.position + Vector2(0, -90))
				Game.sfx("heal", -2.0, 0.4)
				await get_tree().create_timer(0.5).timeout
				_hurt(tg, randi_range(12, 15))
				if real.alive:
					var lost := mini(real.pr, 4); real.pr -= lost
					_float_text(real.actor.position + Vector2(0, -_height(real) - 70), "-%d Rêve" % lost, Game.CYAN, 24)
				e.hp = mini(e.max_hp, e.hp + 12)
				_float_text(e.actor.position + Vector2(0, -_height(e) - 40), "+12", Color("6bea8c"), 28)
			else:
				await _show_banner("Orsane  ·  Lame de brume", 0.0)
				await _melee(e, _redirect(tg))
				_hurt(tg, randi_range(14, 17))
		await get_tree().create_timer(0.5).timeout
	elif e.id == "cauchemar":
		var ph: int = e.turns % 4
		if ph == 0:
			await _show_banner("Cauchemar Commun  ·  Cri des trois titans", 0.0)
			Game.sfx("thunder", 2.0, 0.5); Game.sfx("stone", 2.0, 0.5); shake = 26.0
			main.flash(Color(1, 0.2, 0.35, 0.5), 0.5)
			glow.burst(e.actor.position + Vector2(0, -200), Color(1.0, 0.25, 0.4, 0.9), 480.0)
			await get_tree().create_timer(0.4).timeout
			for h in alive_h: _hurt(h, randi_range(15, 18))
		elif ph == 2:
			await _show_banner("Cauchemar Commun  ·  Extraction", 0.0)
			for h in alive_h:
				fx.wave(e.actor.position + Vector2(-60, -200), h.actor.position + Vector2(0, -90))
			Game.sfx("heal", -2.0, 0.3)
			await get_tree().create_timer(0.5).timeout
			for h in alive_h:
				_hurt(h, randi_range(7, 9))
				var real: Dictionary = _redirect(h)
				if real.alive: real.pr = maxi(0, real.pr - 3)
			e.hp = mini(e.max_hp, e.hp + 20)
			_float_text(e.actor.position + Vector2(0, -_height(e) - 40), "+20", Color("6bea8c"), 30)
		else:
			var tg: Dictionary = _pick_target(alive_h)
			await _show_banner("Cauchemar Commun  ·  Griffe d'ombre", 0.0)
			await _melee(e, _redirect(tg))
			Game.sfx("slash", 0.0, 0.5)
			_hurt(tg, randi_range(17, 21))
		await get_tree().create_timer(0.5).timeout
	elif e.id == "gardien":
		var phase: int = e.turns % 4
		if phase == 1:
			await _show_banner("Gardien du Rêve  ·  Berceuse de pierre", 0.0)
			Game.sfx("heal", -2.0, 0.35)
			glow.burst(e.actor.position + Vector2(0, -180), Color(0.4, 0.9, 1.0, 0.8), 380.0)
			await get_tree().create_timer(0.5).timeout
			for h in alive_h:
				fx.wave(e.actor.position + Vector2(-60, -200), h.actor.position + Vector2(0, -90))
				_hurt(h, randi_range(4, 6))
				if h.alive and h.veil <= 0:
					h.atb = maxf(0.0, h.atb - 45.0); ready_q.erase(h)
					_float_text(h.actor.position + Vector2(0, -_height(h) - 70), "Somnolent", Color("9fe3ff"), 22)
			if not e.armor:
				e.armor = true
				_float_text(e.actor.position + Vector2(0, -_height(e) - 70), "La carapace se reforme", Game.CYAN, 24)
			await get_tree().create_timer(0.7).timeout
		elif phase == 0:
			await _show_banner("Gardien du Rêve  ·  Marée de rêve", 0.0)
			Game.sfx("stone", 2.0, 0.5); shake = 20.0
			main.flash(Color(0.4, 0.9, 1.0, 0.4), 0.4)
			for h in alive_h:
				fx.rocks(h.actor.position)
			await get_tree().create_timer(0.45).timeout
			for h in alive_h:
				_hurt(h, randi_range(10, 13))
			await get_tree().create_timer(0.7).timeout
		else:
			var tg: Dictionary = _pick_target(alive_h)
			await _show_banner("Gardien du Rêve  ·  Main de pierre", 0.0)
			await _melee(e, _redirect(tg))
			Game.sfx("stone", 0.0, 0.9)
			_hurt(tg, randi_range(14, 17))
			await get_tree().create_timer(0.5).timeout
	elif e.id == "noyau":
		var forets: int = _alive(enemies).filter(func(x): return x.id.begins_with("foret")).size()
		if e.turns % 3 == 0:
			await _show_banner("Noyau  ·  Surcharge de Kevrês !", 0.0)
			glow.burst(e.actor.position + Vector2(0, -160), Color(1.0, 0.3, 0.2, 0.9), 420.0)
			Game.sfx("zap", 2.0, 0.5); Game.sfx("thunder", -2.0, 0.8)
			await get_tree().create_timer(0.4).timeout
			for h in alive_h:
				fx.bolt(e.actor.position + Vector2(-40, -170), h.actor.position + Vector2(0, -90), Color("ff6b5e"))
			shake = 20.0; main.flash(Color(1, 0.3, 0.2, 0.4), 0.4)
			await get_tree().create_timer(0.2).timeout
			for h in alive_h:
				_hurt(h, randi_range(13, 16) if forets > 0 else randi_range(9, 11))
			await get_tree().create_timer(0.7).timeout
		else:
			var tg: Dictionary = _pick_target(alive_h)
			await _show_banner("Noyau  ·  Pointe de forage", 0.0)
			await _melee(e, _redirect(tg))
			Game.sfx("stone", 0.0, 1.3)
			_hurt(tg, randi_range(12, 15))
			await get_tree().create_timer(0.5).timeout
	elif e.id.begins_with("foret"):
		var tg: Dictionary = alive_h[randi() % alive_h.size()]
		await _show_banner("Foret  ·  Vrille", 0.0)
		await _melee(e, _redirect(tg))
		Game.sfx("slash", 0.0, 0.6)
		_hurt(tg, randi_range(8, 10))
		await get_tree().create_timer(0.4).timeout
	elif e.id.begins_with("rongeroc"):
		var tg: Dictionary = alive_h[randi() % alive_h.size()]
		if randf() < 0.2:
			await _show_banner("Rongeroc  ·  Mâchoires de pierre", 0.0)
			await _melee(e, _redirect(tg))
			Game.sfx("stone", -2.0, 1.3)
			_hurt(tg, randi_range(12, 14))
		else:
			await _show_banner("Rongeroc  ·  Griffes", 0.0)
			await _melee(e, _redirect(tg))
			_hurt(tg, randi_range(8, 11))
		await get_tree().create_timer(0.5).timeout
	elif e.id.begins_with("cauche"):
		var tg: Dictionary = alive_h[0]
		if randf() < 0.35:
			await _show_banner("Cauchemerle  ·  Étincelle noire", 0.0)
			fx.bolt(e.actor.position + Vector2(0, -60), tg.actor.position + Vector2(0, -90), Color("b08cff"))
			Game.sfx("zap", -6.0, 0.6)
			await get_tree().create_timer(0.3).timeout
			_hurt(tg, randi_range(7, 9))
		else:
			await _show_banner("Cauchemerle  ·  Coup de bec", 0.0)
			await _melee(e, tg)
			_hurt(tg, randi_range(5, 7))
		await get_tree().create_timer(0.5).timeout
	else:
		var tg: Dictionary = _pick_target(alive_h)
		if randf() < 0.3:
			await _show_banner("Spectre de brume  ·  Voile glacé", 0.0)
			fx.wave(e.actor.position + Vector2(0, -120), _redirect(tg).actor.position + Vector2(0, -90))
			Game.sfx("heal", -6.0, 0.5)
			await get_tree().create_timer(0.5).timeout
			_hurt(tg, randi_range(4, 6))
			var real: Dictionary = _redirect(tg)
			if real.alive:
				real.atb = 0.0; ready_q.erase(real)
				_float_text(real.actor.position + Vector2(0, -_height(real) - 70), "Jauge gelée", Game.CYAN, 22)
			await get_tree().create_timer(0.6).timeout
		else:
			await _show_banner("Spectre de brume  ·  Griffe froide", 0.0)
			await _melee(e, _redirect(tg))
			_hurt(tg, randi_range(8, 11))
			await get_tree().create_timer(0.5).timeout

func _pick_target(list: Array) -> Dictionary:
	for h in list:
		if h.id == "gamin" and randf() < 0.6: return h
	return list[randi() % list.size()]

func _redirect(tg: Dictionary) -> Dictionary:
	var gb = tg.guarded_by
	if gb != null and gb.alive: return gb
	return tg

## Applique des dégâts à un héros (avec Garde et Défense).
func _hurt(tg: Dictionary, base: int) -> void:
	var h: Dictionary = _redirect(tg)
	if not h.alive: return
	if h.veil > 0:
		h.veil -= 1
		if randf() < 0.5:
			_float_text(h.actor.position + Vector2(0, -_height(h) * 0.6), "Esquive", Color("b9a6ff"), 30)
			Game.sfx("heal", -12.0, 1.6)
			return
	var dmg := float(base)
	var note := ""
	if h != tg:
		dmg *= 0.6; note = "Garde"
		Game.sfx("stone", -4.0, 1.4)
	if h.defend: dmg *= 0.5; note = "Défense" if note == "" else note
	if h.rempart > 0:
		h.rempart -= 1; dmg *= 0.5; note = "Rempart"
	var d := maxi(1, int(round(dmg)))
	h.hp = maxi(0, h.hp - d)
	commun = minf(100.0, commun + 4.0)
	Game.sfx("hit", 0.0, 0.8)
	_flash_actor(h.actor)
	shake = maxf(shake, 8.0)
	main.flash(Color(1, 0.2, 0.2, 0.18), 0.25)
	_float_text(h.actor.position + Vector2(0, -_height(h) * 0.6), str(d), Color("ff8080"), 40)
	if note != "":
		_float_text(h.actor.position + Vector2(0, -_height(h) * 0.6 - 44), note, Game.STONE, 22)
	if h.hp <= 0: _kill(h)

# ------------------------------------------------------------------ fin
func _check_end() -> void:
	if state == "end": return
	if _alive(enemies).is_empty():
		state = "end"
		await get_tree().create_timer(0.8).timeout
		await _victory()
	elif _alive(heroes).is_empty():
		state = "end"
		await get_tree().create_timer(0.8).timeout
		await _defeat()

func _victory() -> void:
	if encounter == "pont": Game.flags["foudre2"] = true
	Game.music("")
	Game.sfx("victory", -2.0)
	for h in heroes:
		if h.alive:
			var tw := create_tween(); tw.tween_property(h.actor, "position:y", h.home.y - 40, 0.2)
			tw.tween_property(h.actor, "position:y", h.home.y, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	var layer := CanvasLayer.new(); layer.layer = 40; add_child(layer)
	var dim := ColorRect.new(); dim.color = Color(0.02, 0.02, 0.06, 0.0); dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	create_tween().tween_property(dim, "color:a", 0.6, 0.6)
	var v := Game.label("VICTOIRE", 96, Game.GOLD, Game.font_title, 16)
	v.set_anchors_preset(Control.PRESET_CENTER_TOP); v.position = Vector2(-500, 110); v.size = Vector2(1000, 120)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.scale = Vector2(1.4, 1.4); v.pivot_offset = Vector2(500, 60)
	v.add_theme_color_override("font_shadow_color", Color(1, 0.8, 0.3, 0.5)); v.add_theme_constant_override("shadow_outline_size", 30)
	layer.add_child(v)
	var tw := create_tween(); tw.tween_property(v, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var box := VBoxContainer.new(); box.position = Vector2(340, 280); box.size = Vector2(600, 300)
	box.add_theme_constant_override("separation", 12); layer.add_child(box)
	var lines := [
		["⚡  La Foudre du Gamin atteint le niveau 2", Game.GOLD],
		["◆  La Pierre de la Soldate devient jouable", Game.STONE],
		["★  Première attaque combinée : Onde de choc", Game.CYAN],
		["Le lien entre le Gamin et la Soldate se renforce.", Color(0.85, 0.88, 1.0)],
	]
	if encounter == "centre":
		lines = [
			["La Soldate a choisi son camp.", Game.STONE],
			["Elle est désormais déserteuse. L'Empire les traque tous les deux.", Color(0.85, 0.88, 1.0)],
		]
	elif encounter == "mines":
		lines = [
			["≋  Ilo, le Prêtre des Marées, rejoint l'équipe", Color("9fb8ff")],
			["≋  Nouveau Kevrê jouable : la Brume (Voile)", Color("b9a6ff")],
			["★  Attaques combinées : Sables mouvants, Orage invisible", Game.CYAN],
		]
	elif encounter == "brume":
		lines = [
			["Les Spectres se dissipent dans la brume.", Color("b9a6ff")],
			["Au loin, les lanternes du dernier temple s'allument.", Color(0.85, 0.88, 1.0)],
		]
	elif encounter == "orsane":
		lines = [
			["Orsane est vaincue. Les trois Kevrês volés se brisent.", Game.GOLD],
			["Mais l'extraction a déjà commencé...", Color(0.85, 0.88, 1.0)],
		]
	elif encounter == "cauchemar":
		lines = [
			["✦  Le Cauchemar Commun se dissout dans la lumière.", Game.GOLD],
			["Les trois titans peuvent enfin vous entendre.", Color(0.85, 0.88, 1.0)],
		]
	elif encounter == "gardien":
		lines = [
			["Le Gardien s'incline. Le rêve de la Tortue s'ouvre.", Game.CYAN],
			["L'œil de la Tortue vous regarde...", Color(0.85, 0.88, 1.0)],
		]
	elif encounter == "noyau":
		lines = [
			["Le Noyau de la Grande Foreuse est détruit.", Game.GOLD],
			["Mais la Tortue, elle, s'est déjà réveillée...", Color(0.85, 0.88, 1.0)],
		]
	elif encounter == "village":
		lines = [
			["⚡  Le Gamin maîtrise la Foudre (niveau 1)", Game.GOLD],
			["Les Cauchemerles retournent dans les rêves de l'Oiseau.", Color(0.85, 0.88, 1.0)],
		]
	await get_tree().create_timer(0.7).timeout
	for l in lines:
		var lb := Game.label(l[0], 28 if l[1] != Color(0.85, 0.88, 1.0) else 22, l[1], Game.font_bold, 8)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; lb.modulate.a = 0.0
		box.add_child(lb)
		create_tween().tween_property(lb, "modulate:a", 1.0, 0.4)
		Game.sfx("pickup", -10.0, 1.0 + box.get_child_count() * 0.1)
		await get_tree().create_timer(0.6).timeout
	var cont := Game.label("Entrée pour continuer", 20, Color(1, 1, 1, 0.7), Game.font_body, 6)
	cont.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; box.add_child(cont)
	await _wait_accept()
	if encounter == "village":
		main.goto("explore", {"level": "Village", "after_battle": true, "no_banner": true})
	elif encounter == "centre":
		main.goto("explore", {"level": "Mines"})
	elif encounter == "mines":
		main.goto("explore", {"level": "Mines", "after_battle": true, "no_banner": true})
	elif encounter == "gardien":
		main.goto("explore", {"level": "Reve", "after_battle": true, "no_banner": true})
	elif encounter == "noyau":
		main.goto("explore", {"level": "Effondrement", "after_battle": true, "no_banner": true})
	elif encounter == "brume":
		main.goto("explore", {"level": "Brume", "after_battle": true, "no_banner": true})
	elif encounter == "orsane":
		main.goto("explore", {"level": "Flotte", "after_battle": true, "no_banner": true})
	elif encounter == "cauchemar":
		main.goto("explore", {"level": "ReveCommun", "after_battle": true, "no_banner": true})
	else:
		main.goto("ending")

func _defeat() -> void:
	Game.music("")
	var layer := CanvasLayer.new(); layer.layer = 40; add_child(layer)
	var dim := ColorRect.new(); dim.color = Color(0.02, 0.0, 0.05, 0.0); dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	create_tween().tween_property(dim, "color:a", 0.8, 1.0)
	var v := Game.label("Le rêve vacille...", 64, Color("b08cff"), Game.font_title, 12)
	v.set_anchors_preset(Control.PRESET_CENTER); v.position = Vector2(-500, -100); v.size = Vector2(1000, 90)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; layer.add_child(v)
	var s := Game.label("Entrée pour réessayer le combat", 24, Color.WHITE, Game.font_body, 6)
	s.set_anchors_preset(Control.PRESET_CENTER); s.position = Vector2(-300, 10); s.size = Vector2(600, 40)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; layer.add_child(s)
	await get_tree().create_timer(1.0).timeout
	await _wait_accept()
	main.goto("battle", args)

func _wait_accept() -> void:
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact"):
			Game.sfx("confirm", -6.0)
			return

# ------------------------------------------------------------------ textes
func _show_banner(text: String, hold: float) -> void:
	banner.text = text
	banner.modulate.a = 0.0
	var tw := create_tween(); tw.tween_property(banner, "modulate:a", 1.0, 0.15)
	await tw.finished
	if hold > 0.0:
		await get_tree().create_timer(hold).timeout
		_hide_banner()

func _hide_banner() -> void:
	create_tween().tween_property(banner, "modulate:a", 0.0, 0.3)

func _tip(text: String) -> void:
	var p := Panel.new(); p.add_theme_stylebox_override("panel", _panel_style(0.85))
	p.position = Vector2(340, 96); p.size = Vector2(600, 64)
	var l := Game.label(text, 17, Color(0.9, 0.95, 1.0), Game.font_body)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.position = Vector2(16, 8); l.size = Vector2(568, 50)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l); ui.add_child(p)
	p.modulate.a = 0.0
	var tw := create_tween(); tw.tween_property(p, "modulate:a", 1.0, 0.3)
	tw.tween_interval(5.0); tw.tween_property(p, "modulate:a", 0.0, 0.6); tw.tween_callback(p.queue_free)

func _float_text(pos: Vector2, text: String, col: Color, size := 30) -> void:
	var l := Game.label(text, size, col, Game.font_title if text.is_valid_int() else Game.font_bold, 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(300, size + 10)
	l.position = pos - Vector2(150, 0)
	l.z_index = 20
	world.add_child(l)
	l.pivot_offset = Vector2(150, size / 2.0)
	l.scale = Vector2(1.5, 1.5)
	var tw := create_tween().set_parallel()
	tw.tween_property(l, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", pos.y - 50, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(l, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(l.queue_free)

# ------------------------------------------------------------------ classes d'effets
class Bar extends Control:
	var v := 1.0
	var shown := 1.0
	var size2 := Vector2(100, 8)
	var col := Color.WHITE
	var gauge := false
	var full := false
	func _process(d: float) -> void:
		shown = move_toward(shown, v, d * (3.0 if gauge else 0.8))
		if not gauge and shown < v: shown = v
		queue_redraw()
	func _draw() -> void:
		draw_rect(Rect2(Vector2(-2, -2), size2 + Vector2(4, 4)), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(Vector2.ZERO, size2), Color(1, 1, 1, 0.08))
		if not gauge and shown > v:
			draw_rect(Rect2(Vector2.ZERO, Vector2(size2.x * shown, size2.y)), Color(1, 0.4, 0.3, 0.8))
		var fill := v if not gauge else shown
		var c := col
		if full:
			var k := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 90.0)
			c = col.lerp(Color(1, 1, 1), k * 0.6)
		draw_rect(Rect2(Vector2.ZERO, Vector2(size2.x * clampf(fill, 0, 1), size2.y)), c)
		draw_rect(Rect2(Vector2.ZERO, Vector2(size2.x * clampf(fill, 0, 1), size2.y * 0.35)), Color(1, 1, 1, 0.25))

