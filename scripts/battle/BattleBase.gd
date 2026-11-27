extends Node2D
## Combat, couche 1 : état du combat, constantes, textes à l'écran, fin du combat (victoire, défaite).
## Les couches suivantes héritent de celle-ci : BattleStage, BattleHeroes, BattleEnemies, puis Battle.

var main: Main

var args := {}

const FILL := 25.0          # points de jauge par seconde à vitesse 1

const MENU_SLOW := 0.3      # vitesse des ennemis pendant le choix

var fighters: Array = []

var heroes: Array = []

var enemies: Array = []

var state := "intro"         # intro, run, menu, target, anim, end

var ready_q: Array = []

var cur: Variant = null  # héros qui choisit (Dictionary) ou null

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

var encounter := "pont"

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

func _height(f: Dictionary) -> float:
	return f.h

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

func _alive(list: Array) -> Array:
	return list.filter(func(f): return f.alive)

# ------------------------------------------------------------------ actions des héros
var pending := {}

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

func _pick_target(list: Array) -> Dictionary:
	for h in list:
		if h.id == "gamin" and randf() < 0.6: return h
	return list[randi() % list.size()]

func _redirect(tg: Dictionary) -> Dictionary:
	var gb: Variant = tg.guarded_by
	if gb != null and gb.alive: return gb
	return tg

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
	var cont := Game.label(Game.keys("Entrée pour continuer"), 20, Color(1, 1, 1, 0.7), Game.font_body, 6)
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
	var s := Game.label(Game.keys("Entrée pour réessayer le combat"), 24, Color.WHITE, Game.font_body, 6)
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
