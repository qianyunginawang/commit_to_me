class_name PortraitPin
extends Button
## A round bubble showing who's somewhere: the first person's face in a
## circle, a "+N" badge for more, or a gold "!" when only a story scene is
## there. Glows pink when selected. The campus map puts these on buildings.

const RADIUS := 27.0

## The face circle's radius. Set before adding the pin.
var radius := RADIUS:
	set(value):
		radius = value
		custom_minimum_size = Vector2(radius * 2 + 8, radius * 2 + 8)
		size = custom_minimum_size
		queue_redraw()

var location_id := ""
var looks: Array = []      # Looks.speaker_look() dictionaries, one per person
var has_scene := false
var selected := false:
	set(value):
		selected = value
		queue_redraw()

var _texture: Texture2D


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	radius = RADIUS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func setup(p_location_id: String, p_looks: Array, p_has_scene: bool) -> void:
	location_id = p_location_id
	looks = p_looks
	has_scene = p_has_scene
	_texture = null
	if not looks.is_empty():
		var path: String = looks[0].get("portrait", "")
		if path != "" and ResourceLoader.exists(path):
			_texture = load(path)
	tooltip_text = GameData.locations.get(location_id, {}).get("name", location_id)
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var ring := UiStyle.PINK if selected else UiStyle.CYAN
	draw_circle(c, radius + 7, Color(ring, 0.25 if selected else 0.15))
	draw_circle(c, radius + 3, ring)
	draw_circle(c, radius + 1, UiStyle.TEXT)
	if looks.is_empty():
		draw_circle(c, radius, Color("#3a2f12"))
		var font := UiStyle.display_font()
		var fs := int(radius * 1.3)
		draw_string(font, c + Vector2(-fs * 0.17, fs * 0.36), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiStyle.GOLD)
	else:
		var look: Dictionary = looks[0]
		var bg := Color.from_string(look.get("card_color", "#16284a"), UiStyle.NAVY_2)
		draw_circle(c, radius, bg)
		if _texture:
			_draw_face(c)
		else:
			var font := UiStyle.display_font()
			var letter: String = look.get("name", "?").left(1)
			var fs := int(radius * 1.2)
			var w := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(font, c + Vector2(-w / 2.0, fs * 0.37), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
				Color.from_string(look.get("banner_color", "#ffffff"), Color.WHITE))
	if looks.size() > 1:
		var badge := c + Vector2(radius - 2, radius - 6)
		draw_circle(badge, 11, UiStyle.PINK)
		var font := UiStyle.label_font(0)
		var text := "+%d" % (looks.size() - 1)
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, badge + Vector2(-w / 2.0, 4.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiStyle.TEXT)
	if has_focus():
		draw_arc(c, radius + 9, 0, TAU, 48, UiStyle.GOLD, 2.0, true)


## The top middle of the portrait (the face), clipped to a circle.
func _draw_face(c: Vector2) -> void:
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	var tex_size := _texture.get_size()
	# A square from the top of a 3:4 portrait, a little in from the sides.
	var crop := minf(tex_size.x * 0.62, tex_size.y)
	var crop_pos := Vector2((tex_size.x - crop) / 2.0, tex_size.y * 0.06)
	for i in 40:
		var a := TAU * i / 40.0
		var unit := Vector2(cos(a), sin(a))
		points.append(c + unit * radius)
		uvs.append((crop_pos + (unit * 0.5 + Vector2(0.5, 0.5)) * crop) / tex_size)
	draw_colored_polygon(points, Color.WHITE, uvs, _texture)
