extends "res://scripts/battle/BattleEnemies.gd"
## Combat semi-actif à jauges : chaque combattant agit quand sa jauge est pleine.
## Pendant que tu choisis, les ennemis continuent (au ralenti).
## Les règles et l'interface du combat sont réparties en couches dans scripts/battle/.

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

# ------------------------------------------------------------------ boucle
func _process(delta: float) -> void:
	t += delta
	_weather(delta)
	world.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	shake = move_toward(shake, 0.0, delta * 40.0)
	for f in enemies:
		if f.alive and f.id != "golem" and f.id != "noyau": f.actor.bob = sin(t * (2.0 if f.id.begins_with("spectre") or f.id == "cauchemar" else 5.0) + f.home.x) * (12.0 if f.id.begins_with("spectre") or f.id == "cauchemar" else 6.0)
	if state == "run" or state == "menu" or state == "target":
		var menu := state != "run"
		for f in fighters:
			if not f.alive: continue
			if f.hero:
				if f.atb >= 100.0 or (menu and f == cur): continue
				f.atb = BattleRules.atb_after(f.atb, f.spd, delta, menu)
				if f.atb >= 100.0:
					ready_q.append(f); Game.sfx("ready", -10.0)
			else:
				var slowed: bool = f.slow > 0.0
				f.slow = maxf(0.0, f.slow - delta)
				f.atb = BattleRules.atb_after(f.atb, f.spd, delta, menu, slowed)
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
