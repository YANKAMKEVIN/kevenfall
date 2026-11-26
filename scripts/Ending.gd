extends Node2D
## Après le combat : la Soldate retire les entraves, la capitale en vue, carte de fin.

var main
var args := {}
var dialogue: Dialogue
var bg: Sprite2D

func _ready() -> void:
	var back := CanvasLayer.new(); back.layer = -10; add_child(back)
	var tx := Game.tex("fond_lointain")
	if tx:
		bg = Sprite2D.new(); bg.texture = tx; bg.centered = false
		var sc := 900.0 / tx.get_height()
		bg.scale = Vector2(sc, sc); bg.position = Vector2(-60, -120)
		back.add_child(bg)
		create_tween().tween_property(bg, "position:x", -300.0, 40.0)
	var tile := Game.tex("tuile_pont")
	if tile:
		var deck := TextureRect.new(); deck.texture = tile
		deck.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; deck.stretch_mode = TextureRect.STRETCH_TILE
		var sc2 := 0.55
		deck.scale = Vector2(sc2, sc2)
		deck.position = Vector2(-20, 600); deck.size = Vector2(1400 / sc2, tile.get_height())
		add_child(deck)
	var g := Actor.new().setup("sprite_gamin", 170, 1); g.position = Vector2(600, 604); g.facing = 1; add_child(g)
	var s := Actor.new().setup("sprite_soldate", 215, 1); s.position = Vector2(460, 606); s.facing = 1; add_child(s)
	var fg := CanvasLayer.new(); fg.layer = 5; add_child(fg)
	var rain := Rain.new(); rain.alpha = 0.12; rain.count = 90; fg.add_child(rain)
	dialogue = Dialogue.new(); add_child(dialogue)
	Game.music("music_explore", -8.0)
	await get_tree().create_timer(1.0).timeout
	await dialogue.play([
		["soldate", "... Tu tiens debout ?"],
		["gamin", "Tu t'es mise entre le Golem et moi. Tu n'étais pas obligée."],
		["soldate", "Et toi, tu as tenu le Spectre à distance. On est quittes."],
		["soldate", "Tends l'autre poignet."],
		["gamin", "Tu... me libères ?"],
		["soldate", "Non. Je t'enlève tes entraves. Ce n'est pas la même chose."],
	])
	Game.sfx("stone", -8.0, 1.6)
	main.flash(Color(1, 0.85, 0.4, 0.4), 0.5)
	await get_tree().create_timer(0.8).timeout
	await dialogue.play([
		["soldate", "Regarde, là-bas. Sur le dos de la Tortue. La capitale."],
		["gamin", "Elle brille comme un rêve."],
		["soldate", "Pas pour tout le monde."],
	])
	await _end_card()

func _end_card() -> void:
	var c := CanvasLayer.new(); c.layer = 60; add_child(c)
	var art := Game.tex("titre")
	var root := Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); c.add_child(root)
	root.modulate.a = 0.0
	var black := ColorRect.new(); black.color = Color(0.01, 0.01, 0.04); black.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(black)
	if art:
		var r := TextureRect.new(); r.texture = art; r.set_anchors_preset(Control.PRESET_FULL_RECT)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		r.modulate = Color(0.55, 0.55, 0.65); root.add_child(r)
	var box := VBoxContainer.new(); box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER; box.add_theme_constant_override("separation", 14)
	root.add_child(box)
	var items := [
		["KEVENFALL", 84, Game.GOLD, Game.font_title],
		["Fin de l'acte I  ·  L'Oiseau d'Orage", 30, Color(0.9, 0.93, 1.0), Game.font_title],
		[" ", 10, Color.WHITE, Game.font_body],
		["Acte II : la Tortue-Montagne", 26, Game.CYAN, Game.font_title],
		[" ", 10, Color.WHITE, Game.font_body],
		["Éclats de rêve trouvés : %d" % Game.shards, 22, Color.WHITE, Game.font_bold],
		["Entrée pour continuer vers l'acte II", 20, Color(1, 1, 1, 0.75), Game.font_body],
	]
	for it in items:
		var l := Game.label(it[0], it[1], it[2], it[3], 10)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(l)
	var tw := create_tween(); tw.tween_property(root, "modulate:a", 1.0, 1.5)
	await tw.finished
	Game.sfx("victory", -8.0)
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact"):
			break
	main.goto("explore", {"level": "Centre"})
