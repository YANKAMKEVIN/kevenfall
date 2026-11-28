extends "res://scripts/battle/BattleBase.gd"
## Combat, couche 2 : décor, combattants, interface (barres, menu des commandes, curseur de cible).

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
	var g: Dictionary = _f("golem"); g.armor = true; g.turns = 0
	_f("spectre").float = true
	_f("gamin").atb = 55.0; _f("soldate").atb = 30.0; _f("golem").atb = 10.0; _f("spectre").atb = 25.0

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

## Appelée à chaque image : les textes ne sont reformatés (et les thèmes touchés) que
## quand la valeur affichée change, pour ne pas allouer de chaînes ni relancer la mise en page à chaque image.
func _refresh_ui() -> void:
	if commun_bar:
		commun_bar.v = commun / 100.0; commun_bar.full = commun >= 100.0
		if commun >= 100.0:
			commun_lbl.add_theme_color_override("font_color", Game.GOLD.lerp(Game.CYAN, 0.5 + 0.5 * sin(t * 5)))
		elif commun_lbl.get_meta("pulse", true):
			commun_lbl.add_theme_color_override("font_color", Game.GOLD)
		commun_lbl.set_meta("pulse", commun >= 100.0)
	for h in heroes:
		var r: Dictionary = rows[h.id]
		var low: bool = h.hp < h.max_hp * 0.3
		if r.get("shown_hp", -1) != h.hp:
			r.shown_hp = h.hp
			r.hp.text = "PV %d / %d" % [h.hp, h.max_hp]
		if r.get("shown_low", null) != low:
			r.shown_low = low
			r.hp.add_theme_color_override("font_color", Color("ff7a7a") if low else Color.WHITE)
		r.bar.v = float(h.hp) / h.max_hp
		if r.get("shown_pr", -1) != h.pr:
			r.shown_pr = h.pr
			r.pr.text = "Rêve %d" % h.pr
		r.atb.v = h.atb / 100.0
		r.atb.full = h.atb >= 100.0 and h.alive
	for e in enemies:
		var r: Dictionary = rows[e.id]
		r.box.visible = e.alive
		r.box.position = e.actor.position + Vector2(-85, -_height(e) - 60)
		r.bar.v = float(e.hp) / e.max_hp
		r.atb.v = e.atb / 100.0
		var st: int = (1 if e.armor else 0) | (2 if e.charging else 0)
		if r.get("shown_st", -1) == st: continue
		r.shown_st = st
		var tags := []
		if e.armor: tags.append({"gardien": "Carapace de rêve", "noyau": "Blindage"}.get(e.id, "Armure de roc"))
		if e.charging: tags.append("Se charge !")
		r.st.text = "  ·  ".join(tags)
		r.st.add_theme_color_override("font_color", Color("ff8a6a") if e.charging else Game.CYAN)

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
		_cursor_color(Game.GOLD)
	elif state == "target" and targets.size() > 0:
		var tg: Dictionary = targets[tgt_i]
		cursor.visible = true
		cursor.position = tg.actor.get_global_transform_with_canvas().origin + Vector2(-12, -_height(tg) - 100 + sin(t * 6) * 5)
		_cursor_color(Game.CYAN)

func _cursor_color(c: Color) -> void:
	if cursor.get_meta("col", Color.BLACK) != c:
		cursor.set_meta("col", c)
		cursor.add_theme_color_override("font_color", c)

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
