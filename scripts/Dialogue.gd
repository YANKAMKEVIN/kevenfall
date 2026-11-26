class_name Dialogue
extends CanvasLayer
## Boîte de dialogue avec portrait peint, nom et texte en machine à écrire.
## Usage : await dialogue.play([["gamin", "Salut !"], ["soldate", "..."]])

signal finished

const SPEAKERS := {
	"gamin": {"name": "Le Gamin", "portrait": "portrait_gamin", "col": Color("ffd35a"), "left": true},
	"soldate": {"name": "La Soldate", "portrait": "portrait_soldate", "col": Color("e07a9a"), "left": false},
	"brann": {"name": "Sergent Brann", "portrait": "sprite_brann", "col": Color("ffb36b"), "left": false},
	"tess": {"name": "Tess, ingénieure", "portrait": "sprite_tess", "col": Color("7fd8b0"), "left": false},
	"sauge": {"name": "Mamé Sauge", "portrait": "sprite_ancienne", "col": Color("9fe3ff"), "left": false},
	"garde": {"name": "Garde impérial", "portrait": "sprite_garde", "col": Color("c9a0ff"), "left": false},
	"villageois": {"name": "Villageois", "portrait": "", "col": Color("ffe0a0"), "left": false},
	"ilo": {"name": "Ilo", "portrait": "portrait_ilo", "col": Color("9fb8ff"), "left": false},
	"orsane": {"name": "Chancelière Orsane", "portrait": "portrait_orsane", "col": Color("d9a6ff"), "left": false},
	"rapport": {"name": "Rapport", "portrait": "", "col": Color("c9d6e8"), "left": true},
	"tortue": {"name": "La Tortue-Montagne", "portrait": "", "col": Color("7fe8c8"), "left": true},
	"oiseau": {"name": "L'Oiseau d'Orage", "portrait": "", "col": Color("ffd35a"), "left": true},
	"serpent": {"name": "Le Serpent des Marées", "portrait": "", "col": Color("b9a6ff"), "left": true},
	"annonce": {"name": "Haut-parleurs de l'Empire", "portrait": "", "col": Color("d9a6ff"), "left": true},
	"reve": {"name": "Souvenir de l'Oiseau", "portrait": "", "col": Color("5ee7ff"), "left": true},
	"": {"name": "", "portrait": "", "col": Color.WHITE, "left": true},
}

var root: Control
var panel: Panel
var name_lbl: Label
var text_lbl: RichTextLabel
var arrow: Label
var portrait: TextureRect
var lines: Array = []
var idx := 0
var typing := false
var active := false
var _t := 0.0
var _blip := 0

func _ready() -> void:
	layer = 50
	root = Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(root)
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size = Vector2(330, 330)
	root.add_child(portrait)
	panel = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.035, 0.1, 0.92)
	sb.border_color = Color(0.37, 0.9, 1.0, 0.55); sb.set_border_width_all(2)
	sb.set_corner_radius_all(14); sb.shadow_color = Color(0, 0, 0, 0.6); sb.shadow_size = 14
	sb.content_margin_left = 30; sb.content_margin_right = 30
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 60; panel.offset_right = -60; panel.offset_top = -200; panel.offset_bottom = -26
	root.add_child(panel)
	name_lbl = Game.label("", 26, Color.WHITE, Game.font_title, 8)
	name_lbl.position = Vector2(30, -22)
	panel.add_child(name_lbl)
	text_lbl = RichTextLabel.new()
	text_lbl.bbcode_enabled = true; text_lbl.scroll_active = false
	text_lbl.add_theme_font_override("normal_font", Game.font_body)
	text_lbl.add_theme_font_override("bold_font", Game.font_bold)
	text_lbl.add_theme_font_size_override("normal_font_size", 26)
	text_lbl.add_theme_font_size_override("bold_font_size", 26)
	var it := FontVariation.new(); it.base_font = Game.font_body.base_font
	it.variation_opentype = {"wght": 500}; it.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.2, 1), Vector2.ZERO)
	text_lbl.add_theme_font_override("italics_font", it)
	text_lbl.add_theme_font_size_override("italics_font_size", 26)
	text_lbl.add_theme_color_override("default_color", Color(0.94, 0.95, 1.0))
	text_lbl.position = Vector2(32, 30); text_lbl.size = Vector2(1060, 130)
	panel.add_child(text_lbl)
	arrow = Game.label("▼", 22, Game.CYAN)
	arrow.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT); arrow.position = Vector2(-50, -40)
	panel.add_child(arrow)
	root.visible = false

func play(new_lines: Array) -> void:
	lines = new_lines; idx = 0; active = true; root.visible = true
	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 0.2)
	_show_line()
	await finished

func _show_line() -> void:
	var l: Array = lines[idx]
	var sp: Dictionary = SPEAKERS.get(l[0], SPEAKERS[""])
	name_lbl.text = sp.name
	name_lbl.add_theme_color_override("font_color", sp.col)
	name_lbl.visible = sp.name != ""
	text_lbl.text = l[1]
	text_lbl.visible_ratio = 0.0
	if l[0] == "reve" or l[0] == "":
		text_lbl.text = "[i]" + l[1] + "[/i]" if l[0] == "reve" else l[1]
	var tex: Texture2D = Game.tex(sp.portrait) if sp.portrait != "" else null
	portrait.texture = tex
	portrait.visible = tex != null
	if tex:
		var vp := root.get_viewport_rect().size
		portrait.size = Vector2(330, 330)
		var tgt_x := 40.0 if sp.left else vp.x - 370.0
		portrait.flip_h = false
		portrait.position = Vector2(tgt_x + (-30.0 if sp.left else 30.0), vp.y - 200 - 300)
		portrait.modulate.a = 0.0
		var tw := create_tween().set_parallel()
		tw.tween_property(portrait, "position:x", tgt_x, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(portrait, "modulate:a", 1.0, 0.2)
		text_lbl.position.x = 32.0
	typing = true

func _process(delta: float) -> void:
	if not active: return
	_t += delta
	arrow.visible = not typing
	arrow.position.y = -40 + sin(_t * 6.0) * 4.0
	if typing:
		var total := text_lbl.get_total_character_count()
		var shown := text_lbl.visible_characters
		if shown < 0: shown = 0
		shown += 1 if Engine.get_frames_drawn() % 1 == 0 else 0
		text_lbl.visible_characters = mini(total, shown + 1)
		_blip += 1
		if _blip % 3 == 0: Game.sfx("blip", -18.0, randf_range(0.9, 1.15))
		if text_lbl.visible_characters >= total:
			typing = false

func _unhandled_input(e: InputEvent) -> void:
	if not active: return
	if e.is_action_pressed("interact") or e.is_action_pressed("ui_accept") or e.is_action_pressed("jump"):
		get_viewport().set_input_as_handled()
		if typing:
			text_lbl.visible_characters = -1; typing = false
			return
		idx += 1
		if idx >= lines.size():
			active = false
			var tw := create_tween(); tw.tween_property(root, "modulate:a", 0.0, 0.15)
			await tw.finished
			root.visible = false
			finished.emit()
		else:
			Game.sfx("select", -14.0)
			_show_line()
