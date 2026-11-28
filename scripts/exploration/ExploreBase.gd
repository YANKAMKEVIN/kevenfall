extends Node2D
## Exploration, couche 1 : état, constantes, points d'extension des chapitres, construction
## du décor et de l'interface, météo, dialogue.
## Les couches suivantes héritent de celle-ci : ExploreMotion (déplacement, entrées),
## ExploreStory (outils de mise en scène), puis Exploration (assemblage, class_name).

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

var art_layer: CanvasLayer
var choice_active := false
var choice_i := 0
var _toasts := 0

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


# ---------------------------------------------------------------- dialogue
func say(lines: Array) -> void:
	var was := busy
	busy = true; vel.x = 0; player.walking = false
	await dialogue.play(lines)
	busy = was

func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

