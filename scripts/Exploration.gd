class_name Exploration
extends "res://scripts/exploration/ExploreStory.gd"
## Moteur d'exploration à défilement horizontal. Chaque niveau (scripts/levels/)
## hérite de cette classe et fournit sa configuration et ses événements
## (_config, _setup, _start, _talk_to, _tick, _on_zap, _extra_glows, _blocked_x).
## Le moteur est découpé en couches dans scripts/exploration/ ; ce fichier assemble le niveau.

# ---------------------------------------------------------------- construction
func _ready() -> void:
	cfg = _config()
	level_w = cfg.get("level_w", 4300.0)
	segments = cfg.get("segments", [[-200.0, level_w + 200.0]])
	platforms = cfg.get("platforms", [])
	base_tint = cfg.get("tint", base_tint)
	_build_background()
	tint = CanvasModulate.new(); tint.color = base_tint; add_child(tint)
	var deck := GroundDeck.new(); deck.ex = self; add_child(deck); deck_node = deck
	for p in cfg.get("props", []):
		_prop(p[0], p[1], p[2], p[3] if p.size() > 3 else 1)
	for n in cfg.get("npcs", []):
		var a := Actor.new().setup(n.tex, n.h, n.get("native", -1))
		a.position = Vector2(n.x, GROUND_Y); a.facing = n.get("face", -1); a.z_index = 2
		add_child(a); npcs[n.id] = a
	for o in cfg.get("objects", []):
		objects[o.id] = o
	for sd in cfg.get("shards", []):
		var sh := DreamShard.new(); sh.position = sd.pos; sh.z_index = 4
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

