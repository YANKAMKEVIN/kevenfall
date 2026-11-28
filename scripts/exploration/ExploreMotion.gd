extends "res://scripts/exploration/ExploreBase.gd"
## Exploration, couche 2 : déplacement du joueur (saut, plateformes, compagnon), caméra,
## interactions (parler, Foudre, pause) et éclats de rêve.

var _prompt_k := ""   # dernier objet ou personnage montré par l'invite (évite de refaire le texte à chaque image)
var _prompt_pad := false

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
	if not prompt.visible:
		_prompt_k = ""
		return
	var anchor: Vector2
	if objects.has(k):
		anchor = Vector2(objects[k].x, GROUND_Y - objects[k].get("h", 200.0))
	else:
		var a: Actor = npcs[k]
		var top := a.sprite.texture.get_height() * a.base_scale if a.sprite and a.sprite.texture else 160.0
		anchor = a.position + Vector2(0, -top - 40)
	prompt.position = get_viewport().get_canvas_transform() * anchor - Vector2(120, 0) + Vector2(0, sin(t * 4.0) * 4.0)
	if k != _prompt_k or Game.pad != _prompt_pad:
		_prompt_k = k; _prompt_pad = Game.pad
		prompt.text = Game.keys("E · " + objects[k].get("label", "Examiner")) if objects.has(k) else Game.keys("E · Parler")

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

