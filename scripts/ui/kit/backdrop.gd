class_name Backdrop
extends Control
## The scene behind dialogue. Uses a background image when one exists
## (res://assets/backgrounds/<location>_<slot>.png, then <location>.png), and
## otherwise paints a simple sky and campus skyline for the time of day.

const BACKGROUNDS_DIR := "res://assets/backgrounds"

## Sky colors from top to horizon, per slot.
const SKIES := {
	"day": [Color("#4f86c6"), Color("#9cc9ec"), Color("#e8f1f4")],
	"dusk": [Color("#2e2d58"), Color("#8a5f8f"), Color("#ffd7a0")],
	"night": [Color("#070b1c"), Color("#16214a"), Color("#3a3f78")],
}
const SKYLINE := {"day": Color("#6d86a6"), "dusk": Color("#4d3f5f"), "night": Color("#0d1428")}
const GROUND := {"day": Color("#8a9aa8"), "dusk": Color("#6e5d72"), "night": Color("#1a2238")}
const WINDOWS := {"day": Color(1, 1, 1, 0.0), "dusk": Color("#ffd98a"), "night": Color("#ffd98a")}

var location := ""
var slot := "day"
var _image: TextureRect


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_image = TextureRect.new()
	_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_image)
	show_place(location, slot)


func show_place(p_location: String, p_slot: String) -> void:
	location = p_location
	slot = p_slot if SKIES.has(p_slot) else "day"
	var path := image_path(location, slot)
	if _image:
		_image.texture = load(path) if path != "" else null
		_image.visible = path != ""
	queue_redraw()


## The background image for this place and time, or "" if there isn't one yet.
static func image_path(p_location: String, p_slot: String) -> String:
	for file in ["%s_%s" % [p_location, p_slot], p_location]:
		var path := "%s/%s.png" % [BACKGROUNDS_DIR, file]
		if p_location != "" and ResourceLoader.exists(path):
			return path
	return ""


func _draw() -> void:
	if _image and _image.visible:
		return
	var w := size.x
	var h := size.y
	var horizon := h * 0.62
	var sky: Array = SKIES[slot]
	_vertical_gradient(Rect2(0, 0, w, horizon * 0.5), sky[0], sky[1])
	_vertical_gradient(Rect2(0, horizon * 0.5, w, horizon * 0.5), sky[1], sky[2])
	if slot == "dusk":
		draw_circle(Vector2(w * 0.24, horizon - 50), 150, Color("#ffe6b8", 0.2))
		draw_circle(Vector2(w * 0.24, horizon - 50), 60, Color("#fff0cc"))
	elif slot == "night":
		var rng := RandomNumberGenerator.new()
		rng.seed = 256
		for i in 60:
			var p := Vector2(rng.randf() * w, rng.randf() * horizon * 0.8)
			draw_circle(p, rng.randf_range(0.8, 1.8), Color(1, 1, 1, rng.randf_range(0.4, 0.9)))
	# A row of campus buildings on the horizon.
	var skyline := PackedVector2Array([Vector2(0, horizon)])
	var x := 0.0
	var heights := [60, 90, 48, 130, 76, 104, 56, 140, 84, 64, 112, 70]
	var i := 0
	while x < w:
		var bh: float = heights[i % heights.size()]
		var bw := 70.0 + float((i * 37) % 60)
		skyline.append(Vector2(x, horizon - bh))
		skyline.append(Vector2(x + bw, horizon - bh))
		if WINDOWS[slot].a > 0:
			for wy in range(int(horizon - bh + 14), int(horizon - 10), 24):
				for wx in range(int(x + 12), int(x + bw - 12), 22):
					if (wx + wy + i) % 3 != 0:
						draw_rect(Rect2(wx, wy, 7, 8), Color(WINDOWS[slot], 0.55))
		x += bw
		i += 1
	skyline.append(Vector2(w, horizon))
	draw_colored_polygon(skyline, SKYLINE[slot])
	_vertical_gradient(Rect2(0, horizon, w, h - horizon), GROUND[slot], GROUND[slot].darkened(0.35))
	draw_line(Vector2(0, horizon + 4), Vector2(w, horizon + 4), Color(0, 0, 0, 0.35), 6)
	# Darken the bottom so the dialogue box reads well.
	_vertical_gradient(Rect2(0, h - 240, w, 240), Color(0.04, 0.05, 0.09, 0), Color(0.04, 0.05, 0.09, 0.65))


func _vertical_gradient(rect: Rect2, top: Color, bottom: Color) -> void:
	draw_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))
