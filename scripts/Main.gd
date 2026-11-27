extends Node
class_name Main
## Enchaîne les écrans : titre -> exploration -> combat -> fin.

var current: Node
var fade: ColorRect
var fade_layer: CanvasLayer

func _ready() -> void:
	fade_layer = CanvasLayer.new(); fade_layer.layer = 100; add_child(fade_layer)
	fade = ColorRect.new(); fade.color = Color(0.01, 0.01, 0.04, 1.0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade)
	goto("title")

func goto(screen: String, args := {}) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.45 if current else 0.0)
	await tw.finished
	if current:
		current.queue_free(); current = null
	await get_tree().process_frame
	var scr: Script
	match screen:
		"title": scr = load("res://scripts/Title.gd")
		"explore":
			scr = load("res://scripts/levels/%s.gd" % args.get("level", "Pont"))
			if not args.get("nosave", false):
				Game.save_game(args.get("level", "Pont"))  # sauvegarde automatique au début du chapitre
		"battle": scr = load("res://scripts/Battle.gd")
		"ending": scr = load("res://scripts/Ending.gd")
	current = scr.new()
	if "args" in current: current.args = args
	current.main = self
	add_child(current)
	move_child(current, 0)
	var tw2 := create_tween()
	tw2.tween_property(fade, "color:a", 0.0, 0.8)

func flash(col: Color, dur := 0.35) -> void:
	var r := ColorRect.new(); r.color = col
	r.set_anchors_preset(Control.PRESET_FULL_RECT); r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(r)
	var tw := create_tween(); tw.tween_property(r, "color:a", 0.0, dur); tw.tween_callback(r.queue_free)
