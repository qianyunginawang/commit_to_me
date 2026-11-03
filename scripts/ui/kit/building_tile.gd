class_name BuildingTile
extends Button
## One building on the campus map: a glowing block with the building's name,
## how many rooms it has, and a bubble for each love interest inside (a gold
## "!" bubble when only a story scene is there). Pink when selected or busy.

var building_id := ""
var title := ""
var room_count := 0
var selected := false:
	set(value):
		selected = value
		queue_redraw()

var _looks: Array = []
var _has_scene := false
var _bubbles: HBoxContainer


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_bubbles = HBoxContainer.new()
	_bubbles.name = "Bubbles"
	_bubbles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubbles.add_theme_constant_override("separation", 2)
	add_child(_bubbles)


## Who's inside (Looks.speaker_look() dictionaries) and whether a scene waits.
func show_people(looks: Array, has_scene: bool) -> void:
	_looks = looks
	_has_scene = has_scene
	for child in _bubbles.get_children():
		_bubbles.remove_child(child)
		child.queue_free()
	var faces: Array = looks.map(func(l): return [l])
	if has_scene:
		faces.append([])
	for look in faces:
		var pin := PortraitPin.new()
		pin.radius = CampusMapView.BUBBLE_RADIUS
		pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pin.setup("", look, look.is_empty())
		_bubbles.add_child(pin)
	_bubbles.position = Vector2(8, size.y - (CampusMapView.BUBBLE_RADIUS * 2 + 8) - 6)
	var names: PackedStringArray = []
	for look in looks:
		names.append(look.get("name", ""))
	tooltip_text = title if names.is_empty() else "%s: %s" % [title, ", ".join(names)]
	queue_redraw()


## How many people are shown (for tests).
func people_count() -> int:
	return _looks.size()


func has_scene() -> bool:
	return _has_scene


func _draw() -> void:
	var busy := not _looks.is_empty() or _has_scene
	var edge := UiStyle.PINK if selected else (UiStyle.CYAN_PALE if busy else UiStyle.CYAN)
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(edge, 0.16 if selected else (0.1 if busy else 0.05)))
	draw_rect(rect, Color(edge, 0.95 if selected or busy else 0.45), false, 2.0 if selected else 1.5)
	# A slanted corner, like the glass frames.
	draw_colored_polygon(PackedVector2Array([Vector2(size.x - 18, 0), Vector2(size.x, 0), Vector2(size.x, 18)]),
		Color(edge, 0.9 if selected or busy else 0.5))
	var font := UiStyle.display_font()
	# Shrink long names to fit on one line.
	var font_size := 22
	while font_size > 14 and font.get_string_size(title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > size.x - 34:
		font_size -= 1
	draw_string(font, Vector2(12, 32), title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
		UiStyle.TEXT if selected or busy else UiStyle.TEXT_SOFT)
	draw_string(UiStyle.label_font(2), Vector2(12, 52), "%d ROOMS" % room_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
		UiStyle.TEXT_MUTED)
	if has_focus():
		draw_rect(rect.grow(3), UiStyle.GOLD, false, 1.5)
