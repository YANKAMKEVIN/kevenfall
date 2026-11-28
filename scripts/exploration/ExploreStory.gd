extends "res://scripts/exploration/ExploreMotion.gd"
## Exploration, couche 3 : outils de mise en scène des chapitres (marche scriptée, cartons,
## bannière de chapitre, carte de fin, illustrations, choix, messages).

func walk_to(a: Actor, x: float, speed := 220.0) -> void:
	a.facing = 1 if x > a.position.x else -1
	a.walking = true
	var tw := create_tween(); tw.tween_property(a, "position:x", x, absf(x - a.position.x) / speed)
	await tw.finished
	a.walking = false

func title_cards(texts: Array) -> void:
	var cards := CanvasLayer.new(); cards.layer = 60; add_child(cards)
	var bgc := ColorRect.new(); bgc.color = Color(0.01, 0.01, 0.04); bgc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cards.add_child(bgc)
	var l := Game.label("", 30, Color(0.9, 0.93, 1.0), Game.font_title, 6)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cards.add_child(l)
	for s in texts:
		l.text = s; l.modulate.a = 0.0
		var tw := create_tween(); tw.tween_property(l, "modulate:a", 1.0, 0.8)
		tw.tween_interval(2.2); tw.tween_property(l, "modulate:a", 0.0, 0.6)
		await tw.finished
	var tw2 := create_tween(); tw2.tween_property(bgc, "color:a", 0.0, 1.2)
	await tw2.finished
	cards.queue_free()

func _area_banner(small: String, big: String) -> void:
	var c := CanvasLayer.new(); c.layer = 30; add_child(c)
	var a := Game.label(small, 22, Game.CYAN, Game.font_title, 6)
	var b := Game.label(big, 54, Game.GOLD, Game.font_title, 12)
	for lb in [a, b]:
		lb.set_anchors_preset(Control.PRESET_CENTER_TOP); lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.size = Vector2(1000, 70); lb.position = Vector2(-500, 130 if lb == a else 160)
		lb.modulate.a = 0.0; c.add_child(lb)
	var tw := create_tween().set_parallel()
	tw.tween_property(a, "modulate:a", 1.0, 0.8); tw.tween_property(b, "modulate:a", 1.0, 0.8)
	tw.chain().tween_interval(1.8)
	tw.chain().tween_property(b, "modulate:a", 0.0, 0.8)
	tw.parallel().tween_property(a, "modulate:a", 0.0, 0.8)
	await tw.finished
	c.queue_free()

func end_card(big: String, sub: String, lines: Array, back_to_title := true) -> void:
	var c := CanvasLayer.new(); c.layer = 60; add_child(c)
	var root := Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); c.add_child(root)
	root.modulate.a = 0.0
	var black := ColorRect.new(); black.color = Color(0.01, 0.01, 0.04); black.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(black)
	var art := Game.tex("titre")
	if art:
		var r := TextureRect.new(); r.texture = art; r.set_anchors_preset(Control.PRESET_FULL_RECT)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		r.modulate = Color(0.5, 0.5, 0.62); root.add_child(r)
	var box := VBoxContainer.new(); box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER; box.add_theme_constant_override("separation", 14)
	root.add_child(box)
	var items := [[big, 84, Game.GOLD, Game.font_title], [sub, 30, Color(0.9, 0.93, 1.0), Game.font_title], [" ", 10, Color.WHITE, Game.font_body]]
	for l in lines: items.append([l, 22, Game.CYAN, Game.font_body])
	items.append([" ", 10, Color.WHITE, Game.font_body])
	items.append(["Entrée pour continuer", 20, Color(1, 1, 1, 0.75), Game.font_body])
	for it in items:
		var lb := Game.label(it[0], it[1], it[2], it[3], 10)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(lb)
	var tw := create_tween(); tw.tween_property(root, "modulate:a", 1.0, 1.5)
	await tw.finished
	Game.sfx("victory", -8.0)
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact"):
			break
	if back_to_title: main.goto("title")

## Illustration plein écran (vision, cinématique), avec dialogue par-dessus.
func show_art(id: String, lines: Array, keep := false) -> void:
	if art_layer == null:
		art_layer = CanvasLayer.new(); art_layer.layer = 25; add_child(art_layer)
	for c in art_layer.get_children(): c.queue_free()
	var root := Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); art_layer.add_child(root)
	var black := ColorRect.new(); black.color = Color(0.01, 0.01, 0.04); black.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(black)
	var tex := Game.tex(id)
	var r: TextureRect
	if tex:
		r = TextureRect.new(); r.texture = tex; r.set_anchors_preset(Control.PRESET_FULL_RECT)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		r.pivot_offset = Vector2(640, 360)
		root.add_child(r)
		var zoom := create_tween(); zoom.tween_property(r, "scale", Vector2(1.08, 1.08), 14.0)
	root.modulate.a = 0.0
	var tw := create_tween(); tw.tween_property(root, "modulate:a", 1.0, 1.2)
	await tw.finished
	if lines.size() > 0:
		await say(lines)
	else:
		await wait(3.0)
	if not keep:
		var tw2 := create_tween(); tw2.tween_property(root, "modulate:a", 0.0, 1.0)
		await tw2.finished
		root.queue_free()

func hide_art() -> void:
	if art_layer == null: return
	for c in art_layer.get_children():
		var tw := create_tween(); tw.tween_property(c, "modulate:a", 0.0, 1.0); tw.tween_callback(c.queue_free)
	await wait(1.0)

## Choix entre plusieurs options (← → ou ↑ ↓ puis Entrée). Renvoie l'indice choisi.
func choose(question: String, options: Array) -> int:
	choice_active = true; choice_i = 0
	var c := CanvasLayer.new(); c.layer = 55; add_child(c)
	var dim := ColorRect.new(); dim.color = Color(0.0, 0.0, 0.05, 0.0); dim.set_anchors_preset(Control.PRESET_FULL_RECT); c.add_child(dim)
	create_tween().tween_property(dim, "color:a", 0.55, 0.5)
	var q := Game.label(question, 34, Color(0.92, 0.95, 1.0), Game.font_title, 10)
	q.set_anchors_preset(Control.PRESET_CENTER_TOP); q.position = Vector2(-560, 120); q.size = Vector2(1120, 60)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; c.add_child(q)
	var cards: Array = []
	var w := 420.0 if options.size() <= 2 else 370.0
	var gap := 60.0 if options.size() <= 2 else 30.0
	var x0 := 640.0 - (options.size() * w + (options.size() - 1) * gap) / 2.0
	for i in options.size():
		var o: Dictionary = options[i]
		var p := Panel.new()
		var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.04, 0.035, 0.1, 0.92)
		sb.border_color = o.col; sb.set_border_width_all(2); sb.set_corner_radius_all(14)
		sb.shadow_color = Color(o.col.r, o.col.g, o.col.b, 0.4); sb.shadow_size = 0
		p.add_theme_stylebox_override("panel", sb)
		p.position = Vector2(x0 + i * (w + gap), 230); p.size = Vector2(w, 300)
		p.pivot_offset = p.size / 2.0
		c.add_child(p)
		var t1 := Game.label(o.title, 40, o.col, Game.font_title, 10)
		t1.position = Vector2(0, 24); t1.size = Vector2(w, 50); t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; p.add_child(t1)
		var t2 := Game.label(o.text, 19, Color(0.88, 0.92, 1.0), Game.font_body, 4)
		t2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t2.custom_minimum_size = Vector2(w - 52, 0)
		t2.position = Vector2(26, 90); t2.size = Vector2(w - 52, 200)
		t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; p.add_child(t2)
		cards.append({"p": p, "sb": sb})
	var hint := Game.label("← →  choisir     Entrée  confirmer", 18, Color(1, 1, 1, 0.7), Game.font_body, 6)
	hint.set_anchors_preset(Control.PRESET_CENTER_TOP); hint.position = Vector2(-300, 560); hint.size = Vector2(600, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; c.add_child(hint)
	await wait(0.4)
	while true:
		for i in cards.size():
			var on := i == choice_i
			cards[i].sb.shadow_size = 18 if on else 0
			cards[i].sb.set_border_width_all(4 if on else 2)
			cards[i].p.scale = cards[i].p.scale.lerp(Vector2(1.05, 1.05) if on else Vector2(0.95, 0.95), 0.25)
			cards[i].p.modulate = Color.WHITE if on else Color(0.7, 0.7, 0.8)
		await get_tree().process_frame
		if Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("move_right"):
			choice_i = (choice_i + 1) % options.size(); Game.sfx("select", -8.0)
		elif Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("move_left"):
			choice_i = (choice_i - 1 + options.size()) % options.size(); Game.sfx("select", -8.0)
		elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact"):
			break
	Game.sfx("confirm", -4.0)
	main.flash(Color(options[choice_i].col.r, options[choice_i].col.g, options[choice_i].col.b, 0.6), 0.6)
	var tw := create_tween(); tw.tween_property(c, "offset:y", 0.0, 0.01)
	for ch in c.get_children():
		if ch is CanvasItem: create_tween().tween_property(ch, "modulate:a", 0.0, 0.5)
	await wait(0.55)
	c.queue_free()
	choice_active = false
	return choice_i

func toast(text: String, col := Color.WHITE) -> void:
	var l := Game.label(text, 24, col, Game.font_bold, 8)
	l.set_anchors_preset(Control.PRESET_CENTER_TOP); l.position = Vector2(-450, 90 + 40 * _toasts); l.size = Vector2(900, 40)
	_toasts += 1
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.modulate.a = 0.0
	# bandeau sombre : le texte doré restait illisible sur les décors clairs (Rêve Commun, effondrement)
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.03, 0.03, 0.08, 0.62); sb.set_corner_radius_all(10)
	sb.content_margin_left = 16; sb.content_margin_right = 16; sb.content_margin_top = 4; sb.content_margin_bottom = 6
	l.add_theme_stylebox_override("normal", sb)
	hud.add_child(l)
	# le temps de lecture suit la longueur du message (2,4 s minimum)
	var tw := create_tween(); tw.tween_property(l, "modulate:a", 1.0, 0.25); tw.tween_interval(maxf(2.4, text.length() / 16.0))
	tw.tween_property(l, "modulate:a", 0.0, 0.5); tw.tween_callback(l.queue_free); tw.tween_callback(_toast_done)

func _toast_done() -> void:
	_toasts = maxi(0, _toasts - 1)

