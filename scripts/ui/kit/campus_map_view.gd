class_name CampusMapView
extends Control
## The holographic campus map: a glowing grid, the campus buildings (drawn
## around their locations), and a pin wherever something is happening.
## Positions come from "map" ([x, y]) and "building" in data/locations.json.

signal location_selected(location_id: String)

## Space around a building's locations, and room on top for its name.
const BUILDING_PAD := Vector2(48, 40)
const BUILDING_LABEL_ROOM := 16.0
const DOT := 4.0

## Location id -> {"looks": [...], "has_scene": bool} for active places.
var places: Dictionary = {}
var selected := ""
var _pins: Dictionary = {}


## Shows who is where. places_info maps location id -> {"looks", "has_scene"}.
func show_places(places_info: Dictionary, p_selected: String) -> void:
	places = places_info
	selected = p_selected
	for pin in _pins.values():
		remove_child(pin)
		pin.queue_free()
	_pins.clear()
	for loc in places:
		var info: Dictionary = GameData.locations.get(loc, {})
		if not info.has("map"):
			continue
		var pin := PortraitPin.new()
		pin.name = loc
		pin.setup(loc, places[loc]["looks"], places[loc]["has_scene"])
		pin.selected = loc == selected
		pin.position = _point(info) - pin.size / 2.0
		pin.pressed.connect(func(): location_selected.emit(loc))
		add_child(pin)
		_pins[loc] = pin
	queue_redraw()


func get_pin(loc: String) -> PortraitPin:
	return _pins.get(loc)


func _point(info: Dictionary) -> Vector2:
	var p: Array = info.get("map", [0, 0])
	return Vector2(p[0], p[1])


func _draw() -> void:
	_draw_ground()
	_draw_paths()
	_draw_buildings()
	_draw_locations()


func _draw_ground() -> void:
	# A soft glow in the middle of campus, then a faint grid.
	for i in 6:
		draw_circle(Vector2(470, 360), 460 - i * 70, Color(0.11, 0.24, 0.4, 0.12))
	var grid := Color(UiStyle.CYAN, 0.07)
	for x in range(0, int(size.x), 32):
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid, 1)
	for y in range(0, int(size.y), 32):
		draw_line(Vector2(0, y), Vector2(size.x, y), grid, 1)


func _draw_paths() -> void:
	var path := Color(UiStyle.CYAN_PALE, 0.45)
	var glow := Color(UiStyle.CYAN_PALE, 0.08)
	var main := _curve(Vector2(20, 330), Vector2(300, 300), Vector2(620, 370), Vector2(880, 322))
	var cross := _curve(Vector2(470, 110), Vector2(455, 260), Vector2(485, 480), Vector2(470, 640))
	for line in [main, cross]:
		draw_polyline(line, glow, 16, true)
		draw_polyline(line, path, 2, true)
	for line in [_curve(Vector2(130, 330), Vector2(140, 380), Vector2(135, 400), Vector2(130, 440)),
			_curve(Vector2(600, 345), Vector2(620, 420), Vector2(700, 470), Vector2(790, 500))]:
		_dashed(line, path)


func _draw_buildings() -> void:
	var buildings := {}
	for loc in GameData.locations:
		var info: Dictionary = GameData.locations[loc]
		var building: String = info.get("building", "")
		if building == "" or not info.has("map"):
			continue
		var p := _point(info)
		var rect: Rect2 = buildings.get(building, Rect2(p, Vector2.ZERO))
		buildings[building] = rect.expand(p)
	var font := UiStyle.label_font(2)
	for building in buildings:
		var rect: Rect2 = buildings[building].grow_individual(BUILDING_PAD.x, BUILDING_PAD.y + BUILDING_LABEL_ROOM, BUILDING_PAD.x, BUILDING_PAD.y)
		var active := false
		for loc in places:
			if GameData.locations.get(loc, {}).get("building", "") == building:
				active = true
		var edge := UiStyle.PINK if active else UiStyle.CYAN
		draw_rect(rect, Color(edge, 0.1 if active else 0.06))
		draw_rect(rect, Color(edge, 0.85 if active else 0.5), false, 1.5)
		draw_string(font, rect.position + Vector2(10, 18), building.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
			UiStyle.TEXT if active else UiStyle.TEXT_SOFT)


func _draw_locations() -> void:
	var font := UiStyle.label_font(1)
	for loc in GameData.locations:
		var info: Dictionary = GameData.locations[loc]
		if not info.has("map"):
			continue
		var p := _point(info)
		var short: String = info.get("short", info.get("name", loc)).to_upper()
		if places.has(loc):
			# The pin covers the spot; put the name under it.
			_label(font, p + Vector2(0, 42), short, UiStyle.PINK if loc == selected else UiStyle.TEXT, 11, true)
		else:
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -DOT), p + Vector2(DOT, 0), p + Vector2(0, DOT), p + Vector2(-DOT, 0)]),
				Color(UiStyle.CYAN, 0.55))
			if info.get("building", "") == "":
				_label(font, p + Vector2(0, 18), short, Color(UiStyle.TEXT_MUTED, 0.75), 10, false)


func _label(font: Font, center: Vector2, text: String, color: Color, font_size: int, backed: bool) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin := center - Vector2(w / 2.0, 0)
	if backed:
		draw_rect(Rect2(origin + Vector2(-6, -font_size - 1), Vector2(w + 12, font_size + 7)), Color(UiStyle.NAVY, 0.85))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _curve(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 25:
		var t := i / 24.0
		points.append(a.bezier_interpolate(b, c, d, t))
	return points


func _dashed(points: PackedVector2Array, color: Color) -> void:
	for i in range(0, points.size() - 1, 2):
		draw_line(points[i], points[i + 1], color, 2, true)
