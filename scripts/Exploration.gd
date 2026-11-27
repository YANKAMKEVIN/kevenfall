class_name Exploration
extends Node2D
## Moteur d'exploration à défilement horizontal. Chaque niveau (scripts/levels/)
## hérite de cette classe et fournit sa configuration et ses événements.

const GROUND_Y := 540.0
const SPEED := 300.0
const JUMP_V := -770.0
const GRAVITY := 2100.0
const COYOTE := 0.1
const BUFFER := 0.13

var main: Main
var args := {}
var cfg := {}

var level_w := 4300.0
var segments: Array = []
var platforms: Array = []
var player: Actor
var vel := Vector2.ZERO
var on_ground := true
var coyote_t := 0.0
var buffer_t := 0.0
var last_safe := Vector2(260, GROUND_Y)
var cam: Camera2D
var npcs := {}
var shards_nodes := {}
var revelins: Array = []
var dialogue: Dialogue
var busy := false
var prompt: Label
var hud: CanvasLayer
var hud_shards: Label
var hint_lbl: Label
var hint_box: Control
var _hint_src := ""
var _hint_out := ""
var sky_mat: ShaderMaterial
var far: TextureRect
var flash_rect: ColorRect
var tint: CanvasModulate
var next_flash := 3.0
var flash_v := 0.0
var glow_layer: GlowLayer
var fx: Fx
var fog_mat: ShaderMaterial
var shake := 0.0
var paused := false
var pause_box: Control
var t := 0.0
var crouching := false
var can_zap := false
var zap_cd := 0.0
var base_tint := Color(0.78, 0.8, 1.0)
var follower: Actor
var objects := {}   # id -> {x, label}
var deck_node: Node2D

# ---------------------------------------------------------------- à surcharger
func _config() -> Dictionary: return {}
func _setup() -> void: pass
func _start() -> void: pass
func _talk_to(_id: String) -> void: pass
func _tick(_delta: float) -> void: pass
func _on_zap(_from: Vector2, _to: Vector2) -> void: pass
func _extra_glows(_g: GlowLayer, _tt: float) -> void: pass
func _blocked_x() -> float: return INF   # limite droite temporaire

# ---------------------------------------------------------------- construction
func _ready() -> void:
	cfg = _config()
	level_w = cfg.get("level_w", 4300.0)
	segments = cfg.get("segments", [[-200.0, level_w + 200.0]])
	platforms = cfg.get("platforms", [])
	base_tint = cfg.get("tint", base_tint)
	_build_background()
	tint = CanvasModulate.new(); tint.color = base_tint; add_child(tint)
	var deck := Deck.new(); deck.ex = self; add_child(deck); deck_node = deck
	for p in cfg.get("props", []):
		_prop(p[0], p[1], p[2], p[3] if p.size() > 3 else 1)
	for n in cfg.get("npcs", []):
		var a := Actor.new().setup(n.tex, n.h, n.get("native", -1))
		a.position = Vector2(n.x, GROUND_Y); a.facing = n.get("face", -1); a.z_index = 2
		add_child(a); npcs[n.id] = a
	for o in cfg.get("objects", []):
		objects[o.id] = o
	for sd in cfg.get("shards", []):
		var sh := Shard.new(); sh.position = sd.pos; sh.z_index = 4
		add_child(sh); shards_nodes[sd.id] = sh
		if Game.shards_taken.has(sd.id): sh.visible = false
	for i in cfg.get("revelins", 0):
		var r := Revelin.new()
		r.home = Vector2(randf_range(400, level_w - 200), randf_range(250, 460))
		r.position = r.home; r.z_index = 4
		add_child(r); revelins.append(r)
	_setup()
	glow_layer = GlowLayer.new(); glow_layer.ex = self; glow_layer.z_index = 5
	var gm := CanvasItemMaterial.new(); gm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow_layer.material = gm
	add_child(glow_layer)
	fx = Fx.new(); fx.z_index = 6; add_child(fx)
	if cfg.has("follower"):
		var fo: Dictionary = cfg.follower
		follower = Actor.new().setup(fo.tex, fo.h, fo.get("native", 1))
		follower.position = Vector2(cfg.get("start_x", 260.0) - 90.0, GROUND_Y); follower.z_index = 3
		add_child(follower)
	player = Actor.new().setup(cfg.get("player_tex", "sprite_gamin"), cfg.get("player_h", 140.0), cfg.get("player_native", 1))
	player.position = Vector2(cfg.get("start_x", 260.0), GROUND_Y); player.z_index = 3
	add_child(player)
	last_safe = player.position
	cam = Camera2D.new(); cam.limit_left = 0; cam.limit_right = int(level_w)
	cam.position_smoothing_enabled = true; cam.position_smoothing_speed = 6.0
	add_child(cam); cam.make_current()
	cam.global_position = Vector2(player.position.x, 380)
	var fg := CanvasLayer.new(); fg.layer = 10; add_child(fg)
	var rain := Rain.new(); rain.alpha = cfg.get("rain", 0.3); rain.count = int(220 * cfg.get("rain", 0.3) / 0.3)
	fg.add_child(rain)
	_build_hud()
	dialogue = Dialogue.new(); add_child(dialogue)
	Game.music(cfg.get("music", "music_explore"), -7.0)
	Game.ambience(cfg.get("rain", 0.3) > 0.0)
	busy = true
	if cfg.has("chapter") and not args.get("no_banner", false):
		await _area_banner(cfg.chapter[0], cfg.chapter[1])
	await _start()
	busy = false

func _build_background() -> void:
	var bg := CanvasLayer.new(); bg.layer = -10; add_child(bg)
	var sky := ColorRect.new(); sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky_mat = ShaderMaterial.new(); sky_mat.shader = load("res://shaders/sky.gdshader")
	sky.material = sky_mat; bg.add_child(sky)
	var ftex := Game.tex(cfg.get("far", "fond_lointain"))
	if ftex:
		far = TextureRect.new(); far.texture = ftex
		far.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		far.stretch_mode = TextureRect.STRETCH_SCALE
		var fh: float = cfg.get("far_h", 810.0)
		far.size = Vector2(maxf(1440.0, fh * ftex.get_width() / ftex.get_height()), fh); far.position = Vector2(0, cfg.get("far_y", -40.0))
		far.modulate = cfg.get("far_mod", Color.WHITE)
		bg.add_child(far)
	var fog := ColorRect.new(); fog_mat = ShaderMaterial.new(); fog_mat.shader = load("res://shaders/fog.gdshader")
	fog_mat.set_shader_parameter("density", cfg.get("fog", 0.35))
	fog_mat.set_shader_parameter("tint", cfg.get("fog_col", Color(0.45, 0.4, 0.8)))
	fog.material = fog_mat; fog.position = Vector2(0, 420); fog.size = Vector2(1280, 320)
	bg.add_child(fog)
	flash_rect = ColorRect.new(); flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color(0.75, 0.8, 1.0, 0.0); flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var am := CanvasItemMaterial.new(); am.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	flash_rect.material = am
	bg.add_child(flash_rect)

func _prop(id: String, x: float, h: float, z := 1, y_off := 4.0) -> Sprite2D:
	var tx := Game.tex(id)
	if not tx: return null
	var s := Sprite2D.new(); s.texture = tx
	var sc: float = h / tx.get_height()
	s.scale = Vector2(sc, sc); s.offset = Vector2(0, -tx.get_height() / 2.0)
	s.position = Vector2(x, GROUND_Y + y_off); s.z_index = z
	add_child(s)
	return s

func _build_hud() -> void:
	hud = CanvasLayer.new(); hud.layer = 20; add_child(hud)
	var top := HBoxContainer.new(); top.position = Vector2(28, 22); hud.add_child(top)
	var ic := Label.new(); ic.text = "◆"; ic.add_theme_color_override("font_color", Game.CYAN)
	ic.add_theme_font_size_override("font_size", 26); top.add_child(ic)
	hud_shards = Game.label("", 22, Color.WHITE, Game.font_bold, 8); top.add_child(hud_shards)
	top.visible = cfg.has("shards")
	var hb := PanelContainer.new()
	var hsb := StyleBoxFlat.new(); hsb.bg_color = Color(0.03, 0.03, 0.08, 0.6); hsb.set_corner_radius_all(8)
	hsb.content_margin_left = 14; hsb.content_margin_right = 14; hsb.content_margin_top = 4; hsb.content_margin_bottom = 4
	hb.add_theme_stylebox_override("panel", hsb)
	hb.position = Vector2(24, 676)
	hint_lbl = Game.label(cfg.get("hint", "← →  marcher     Espace  sauter     E  parler     Échap  pause"), 17, Color(1, 1, 1, 0.8), Game.font_body, 4)
	hb.add_child(hint_lbl)
	hud.add_child(hb)
	hint_box = hb
	prompt = Game.label("", 20, Game.GOLD, Game.font_bold, 8)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; prompt.size = Vector2(240, 30)
	prompt.visible = false; hud.add_child(prompt)
	pause_box = _make_pause(); hud.add_child(pause_box)
	_update_hud()

func _make_pause() -> Control:
	var c := ColorRect.new(); c.color = Color(0.02, 0.02, 0.06, 0.75)
	c.set_anchors_preset(Control.PRESET_FULL_RECT); c.visible = false
	var l := Game.label("PAUSE", 64, Game.GOLD, Game.font_title, 12)
	l.set_anchors_preset(Control.PRESET_CENTER); l.position = Vector2(-150, -120); l.size = Vector2(300, 80)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(l)
	var s := Game.label("Échap : reprendre     Q : revenir au titre", 22, Color.WHITE, Game.font_body, 6)
	s.set_anchors_preset(Control.PRESET_CENTER); s.position = Vector2(-300, 0); s.size = Vector2(600, 40)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(s)
	c.set_meta("aide", s)
	return c

func _update_hud() -> void:
	hud_shards.text = "  Éclats de rêve  %d / %d" % [Game.shards, Game.SHARDS_TOTAL]

# ---------------------------------------------------------------- boucle
func _physics_process(delta: float) -> void:
	t += delta
	_weather(delta)
	if paused: return
	var dir := 0.0
	crouching = false
	if not busy:
		dir = Input.get_axis("move_left", "move_right")
		crouching = on_ground and Input.is_action_pressed("crouch")
		if crouching: dir = 0.0
	var spd: float = SPEED * cfg.get("speed_mul", 1.0)
	vel.x = move_toward(vel.x, dir * spd, 2600.0 * delta)
	if dir != 0.0: player.facing = 1 if dir > 0 else -1
	# saut : tolérance au bord (coyote) + mémoire de l'appui + hauteur variable
	coyote_t = COYOTE if on_ground else maxf(0.0, coyote_t - delta)
	buffer_t = maxf(0.0, buffer_t - delta)
	if not busy and Input.is_action_just_pressed("jump"): buffer_t = BUFFER
	if buffer_t > 0.0 and coyote_t > 0.0 and not busy:
		vel.y = JUMP_V; on_ground = false; coyote_t = 0.0; buffer_t = 0.0
		Game.sfx("select", -16.0, 0.6)
	if vel.y < 0.0 and not Input.is_action_pressed("jump"):
		vel.y += GRAVITY * 1.6 * delta
	vel.y += GRAVITY * delta
	vel.y = minf(vel.y, 1400.0)
	var prev_y := player.position.y
	player.position += vel * delta
	player.position.x = clampf(player.position.x, 40.0, minf(level_w - 40.0, _blocked_x()))
	on_ground = false
	if vel.y >= 0.0:
		var x := player.position.x
		for s in segments:
			if x > s[0] and x < s[1] and prev_y <= GROUND_Y + 1.0 and player.position.y >= GROUND_Y:
				player.position.y = GROUND_Y; vel.y = 0.0; on_ground = true
				last_safe = Vector2(clampf(x, s[0] + 60.0, s[1] - 60.0), GROUND_Y)
		for p in platforms:
			if x > p.position.x - 12 and x < p.end.x + 12 and prev_y <= p.position.y + 1.0 and player.position.y >= p.position.y:
				player.position.y = p.position.y; vel.y = 0.0; on_ground = true
	if follower and not busy:
		var tx := player.position.x - player.facing * 95.0
		var d := tx - follower.position.x
		if absf(d) > 40.0:
			follower.position.x += signf(d) * minf(absf(d) * 3.0, SPEED * 1.1) * delta
			follower.facing = 1 if d > 0 else -1
			follower.walking = true
		else:
			follower.walking = false
			follower.facing = player.facing
	player.walking = on_ground and absf(vel.x) > 20.0
	player.airborne = not on_ground
	player.crouch = crouching
	if player.position.y > 1000.0:
		_respawn()
	cam.global_position = Vector2(player.position.x + player.facing * 80.0, cfg.get("cam_y", 380.0)) + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	shake = move_toward(shake, 0.0, delta * 30.0)
	if far:
		var span := far.size.x - 1290.0
		far.position.x = -clampf(cam.get_screen_center_position().x / maxf(1.0, level_w) , 0.0, 1.0) * minf(span, 260.0)
	zap_cd = maxf(0.0, zap_cd - delta)
	if not busy:
		_check_shards()
		_tick(delta)
	_update_prompt()

func _weather(delta: float) -> void:
	next_flash -= delta
	if next_flash <= 0.0:
		next_flash = randf_range(5.0, 11.0) * cfg.get("flash_every", 1.0)
		flash_v = cfg.get("flash_power", 1.0)
		get_tree().create_timer(randf_range(0.3, 1.2)).timeout.connect(Game.sfx.bind("thunder", -9.0, randf_range(0.8, 1.1)))
	flash_v = move_toward(flash_v, 0.0, delta * 3.0)
	var f := flash_v * (0.6 + 0.4 * sin(t * 60.0))
	sky_mat.set_shader_parameter("flash", f)
	flash_rect.color.a = f * 0.35
	tint.color = base_tint.lerp(Color(1.1, 1.1, 1.25), f * 0.5)

func _respawn() -> void:
	busy = true
	main.flash(Color(0, 0, 0, 1), 0.6)
	player.position = last_safe + Vector2(0, -2); vel = Vector2.ZERO
	await get_tree().create_timer(0.3).timeout
	busy = false

func _nearest_npc() -> String:
	for k in objects:
		var o: Dictionary = objects[k]
		if o.get("off", false): continue
		if absf(o.x - player.position.x) < 80.0 and absf(player.position.y - GROUND_Y) < 60:
			return k
	for k in npcs:
		if not npcs[k].visible or npcs[k].get_meta("mute", false): continue
		if absf(npcs[k].position.x - player.position.x) < 95.0 and absf(npcs[k].position.y - player.position.y) < 60:
			return k
	return ""

## Aide du bas : suit le clavier ou la manette, et se cache sous les dialogues (elle passait à moitié dessous).
func _refresh_hint() -> void:
	if hint_lbl == null:
		return
	if hint_lbl.text != _hint_out:
		_hint_src = hint_lbl.text
	_hint_out = Game.keys(_hint_src)
	hint_lbl.text = _hint_out
	hint_box.visible = not dialogue.active

func _update_prompt() -> void:
	_refresh_hint()
	var k := "" if busy else _nearest_npc()
	prompt.visible = k != ""
	if prompt.visible and objects.has(k):
		var sp2 := get_viewport().get_canvas_transform() * Vector2(objects[k].x, GROUND_Y - objects[k].get("h", 200.0))
		prompt.position = sp2 - Vector2(120, 0) + Vector2(0, sin(t * 4.0) * 4.0)
		prompt.text = Game.keys("E · " + objects[k].get("label", "Examiner"))
	elif prompt.visible:
		var a: Actor = npcs[k]
		var top := a.sprite.texture.get_height() * a.base_scale if a.sprite and a.sprite.texture else 160.0
		var sp := get_viewport().get_canvas_transform() * (a.position + Vector2(0, -top - 40))
		prompt.position = sp - Vector2(120, 0) + Vector2(0, sin(t * 4.0) * 4.0)
		prompt.text = Game.keys("E · Parler")

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("pause") and not dialogue.active:
		paused = not paused; pause_box.visible = paused
		pause_box.get_meta("aide").text = Game.keys("Échap : reprendre     Q : revenir au titre")
		Game.sfx("select", -8.0)
		return
	if paused:
		# Q au clavier, B à la manette (sinon impossible de quitter sans clavier)
		if (e is InputEventKey and e.pressed and e.physical_keycode == KEY_Q) or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_B):
			paused = false; main.goto("title")
		return
	if busy or dialogue.active: return
	if e.is_action_pressed("interact"):
		var k := _nearest_npc()
		if k != "":
			get_viewport().set_input_as_handled()
			talk(k)
	elif e.is_action_pressed("zap") and can_zap and zap_cd <= 0.0:
		zap_cd = 0.45
		var from := player.position + Vector2(player.facing * 30.0, -80)
		var to := from + Vector2(player.facing * 330.0, randf_range(-10, 30))
		Game.sfx("zap", -4.0, randf_range(1.0, 1.2))
		fx.bolt(from, to, Game.GOLD); fx.bolt(from, to, Game.CYAN)
		fx.sparks(to, Game.GOLD, 12)
		fx.burst(to, Color(1, 0.85, 0.4, 0.7), 90)
		flash_v = maxf(flash_v, 0.3)
		_on_zap(from, to)

func talk(k: String) -> void:
	busy = true
	vel = Vector2.ZERO; player.walking = false
	if npcs.has(k):
		var a: Actor = npcs[k]
		player.facing = 1 if a.position.x > player.position.x else -1
		a.facing = -player.facing
	await _talk_to(k)
	busy = false

# ---------------------------------------------------------------- outils de récit
func say(lines: Array) -> void:
	var was := busy
	busy = true; vel.x = 0; player.walking = false
	await dialogue.play(lines)
	busy = was

func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

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
var art_layer: CanvasLayer
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
var choice_active := false
var choice_i := 0
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

var _toasts := 0
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

func _check_shards() -> void:
	for sd in cfg.get("shards", []):
		if Game.shards_taken.has(sd.id): continue
		var n: Node2D = shards_nodes[sd.id]
		if player.position.distance_to(n.position + Vector2(0, 50)) < 70.0:
			Game.shards_taken[sd.id] = true
			Game.shards += 1
			_update_hud()
			Game.sfx("pickup", -4.0)
			main.flash(Color(0.37, 0.9, 1.0, 0.5), 0.6)
			n.collect()
			await say([["reve", sd.text], ["", "Éclat de rêve obtenu.  [color=#5ee7ff]+6 PV max[/color] pour le Gamin dans les combats."]])

# ---------------------------------------------------------------- sous-objets
class Deck extends Node2D:
	## Le sol (tuile peinte répétée) et les plateformes flottantes.
	var ex: Exploration
	func _draw() -> void:
		var tile: Texture2D = Game.tex(ex.cfg.get("tile", "tuile_pont"))
		var h: float = ex.cfg.get("tile_h", 300.0)
		var top: float = ex.cfg.get("tile_top", 0.0)
		for s in ex.segments:
			var x0: float = s[0]; var x1: float = s[1]
			if tile:
				var sc := h / tile.get_height()
				var w := tile.get_width() * sc
				var y := GROUND_Y - h * top
				var x := x0
				while x < x1:
					var seg_w := minf(w, x1 - x)
					draw_texture_rect_region(tile, Rect2(x, y, seg_w, h), Rect2(0, 0, seg_w / sc, tile.get_height()))
					x += w
			else:
				draw_rect(Rect2(x0, GROUND_Y, x1 - x0, 46), Color(0.55, 0.52, 0.62))
		for p in ex.platforms:
			_platform(p)

	func _platform(p: Rect2) -> void:
		var c := Color(0.62, 0.58, 0.7)
		var pts := PackedVector2Array([p.position + Vector2(-6, 0), Vector2(p.end.x + 6, p.position.y),
			Vector2(p.end.x - 6, p.position.y + 20), Vector2(p.position.x + p.size.x * 0.6, p.position.y + 44),
			Vector2(p.position.x + 10, p.position.y + 22)])
		draw_colored_polygon(pts, Color(0.32, 0.28, 0.42))
		draw_rect(Rect2(p.position + Vector2(-6, 0), Vector2(p.size.x + 12, 7)), c)
		draw_line(p.position + Vector2(8, 3), Vector2(p.end.x - 8, p.position.y + 3), Color(1, 0.83, 0.35, 0.7), 2.0)

class GlowLayer extends Node2D:
	## Halos additifs.
	var ex: Exploration
	func _process(_d: float) -> void: queue_redraw()
	func _draw() -> void:
		var tt := Time.get_ticks_msec() / 1000.0
		var fl := 0.85 + 0.15 * sin(tt * 13.0) * sin(tt * 7.3)
		for g in ex.cfg.get("glows", []):
			Game.draw_glow(self, g[0], g[1] * fl, g[2])
		for sd in ex.cfg.get("shards", []):
			if not Game.shards_taken.has(sd.id):
				Game.draw_glow(self, sd.pos, 60 + 8 * sin(tt * 3.0), Color(0.37, 0.9, 1.0, 0.5))
		for r in ex.revelins:
			Game.draw_glow(self, r.position, 34, Color(0.5, 0.95, 1.0, 0.35))
		if ex.player:
			Game.draw_glow(self, ex.player.position + Vector2(18, -70), 40 + 10 * sin(tt * 9.0), Color(1.0, 0.85, 0.35, 0.25 if ex.can_zap else 0.12))
		ex._extra_glows(self, tt)

class Shard extends Node2D:
	var t := randf() * 5.0
	func _process(d: float) -> void:
		t += d; queue_redraw()
	func collect() -> void:
		var tw := create_tween().set_parallel()
		tw.tween_property(self, "scale", Vector2(2.5, 2.5), 0.5)
		tw.tween_property(self, "modulate:a", 0.0, 0.5)
	func _draw() -> void:
		var y := sin(t * 2.5) * 6.0
		var s := 1.0 + 0.08 * sin(t * 5.0)
		var pts := PackedVector2Array([Vector2(0, -22) * s, Vector2(12, 0) * s, Vector2(0, 22) * s, Vector2(-12, 0) * s])
		for i in pts.size(): pts[i] = pts[i].rotated(sin(t) * 0.2) + Vector2(0, y)
		draw_colored_polygon(pts, Color(0.55, 0.95, 1.0))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1, 1, 1, 0.9), 2.0)
		draw_line(Vector2(0, -22 + y), Vector2(0, 22 + y), Color(1, 1, 1, 0.6), 1.5)

class Revelin extends Node2D:
	var home := Vector2.ZERO
	var t := randf() * 10.0
	var spr: Sprite2D
	var flee := Vector2.ZERO
	func _ready() -> void:
		var tx: Texture2D = Game.tex("revelin")
		if tx:
			spr = Sprite2D.new(); spr.texture = tx; spr.scale = Vector2(0.32, 0.32); add_child(spr)
	func _process(d: float) -> void:
		t += d
		var ex := get_parent() as Exploration
		if ex.player and ex.player.position.distance_to(position + Vector2(0, 60)) < 90.0:
			flee = (position - ex.player.position + Vector2(0, -60)).normalized() * 260.0
		flee = flee.move_toward(Vector2.ZERO, d * 200.0)
		home += flee * d
		var target := home + Vector2(sin(t * 0.7) * 60.0, sin(t * 1.9) * 18.0)
		var dx := target.x - position.x
		position = position.lerp(target, clampf(d * 2.0, 0, 1))
		if spr:
			spr.flip_h = dx < 0
			spr.scale.y = 0.32 * (0.85 + 0.15 * absf(sin(t * 9.0)))
