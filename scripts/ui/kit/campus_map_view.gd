class_name CampusMapView
extends Control
## The holographic campus map: a glowing grid with one tile per building
## (data/buildings.json, laid out by "cell" on a 4 by 3 grid). Each tile shows
## a bubble for every love interest in one of its rooms, plus a gold "!" when a
## story scene is waiting there. Click a tile to pick the building.

signal building_selected(building_id: String)

## Where the grid goes, in this control's coordinates (left of the panel,
## under the HUD card).
const AREA := Rect2(16, 108, 868, 512)
## How much shorter the grid gets in compact mode, to make room for Quack's
## speech box during the campus tour.
const COMPACT_CUT := 54.0
const COLUMNS := 4
const ROWS := 3
const GAP := 14.0
const BUBBLE_RADIUS := 19.0

## Building id -> {"looks": [...], "has_scene": bool} for buildings where
## something is happening.
var buildings_info: Dictionary = {}
var selected := ""
## The grid's current rectangle: AREA, or shorter in compact mode.
var area := AREA
var _tiles: Dictionary = {}


## Shows who is where. info maps building id -> {"looks", "has_scene"}.
func show_buildings(info: Dictionary, p_selected: String) -> void:
	buildings_info = info
	selected = p_selected
	if _tiles.is_empty():
		_build_tiles()
	for id in _tiles:
		var tile: BuildingTile = _tiles[id]
		tile.selected = id == selected
		var here: Dictionary = info.get(id, {})
		tile.show_people(here.get("looks", []), here.get("has_scene", false))
	queue_redraw()


func get_tile(building_id: String) -> BuildingTile:
	return _tiles.get(building_id)


## Locks every building except [param open] (the campus tour), or unlocks
## them all when [param open] is null.
func lock_all_but(open: Variant) -> void:
	for id in _tiles:
		_tiles[id].locked = open != null and id != open


## A shorter map, leaving room for Quack's speech box underneath.
func set_compact(on: bool) -> void:
	var new_area := Rect2(AREA.position, AREA.size - Vector2(0, COMPACT_CUT if on else 0.0))
	if new_area == area:
		return
	area = new_area
	for building in GameData.buildings:
		var tile: BuildingTile = _tiles.get(building["id"])
		if tile:
			var rect := cell_rect(building.get("cell", [0, 0]), int(building.get("span", 1)), area)
			tile.position = rect.position
			tile.size = rect.size
			tile.show_people(tile._looks, tile._has_scene)
	queue_redraw()


## The rectangle a building covers on the map.
static func cell_rect(cell: Array, span: int, grid: Rect2 = AREA) -> Rect2:
	var w := (grid.size.x - GAP * (COLUMNS - 1)) / COLUMNS
	var h := (grid.size.y - GAP * (ROWS - 1)) / ROWS
	var pos := grid.position + Vector2(int(cell[0]) * (w + GAP), int(cell[1]) * (h + GAP))
	return Rect2(pos, Vector2(w * span + GAP * (span - 1), h))


func _build_tiles() -> void:
	for building in GameData.buildings:
		var tile := BuildingTile.new()
		tile.name = building["id"]
		tile.building_id = building["id"]
		tile.title = building.get("name", building["id"])
		tile.room_count = GameData.rooms_in(building["id"]).size()
		var rect := cell_rect(building.get("cell", [0, 0]), int(building.get("span", 1)), area)
		tile.position = rect.position
		tile.size = rect.size
		tile.pressed.connect(func(): building_selected.emit(tile.building_id))
		add_child(tile)
		_tiles[building["id"]] = tile


func _draw() -> void:
	# A soft glow in the middle of campus, then a faint grid.
	var middle := area.get_center()
	for i in 6:
		draw_circle(middle, 460 - i * 70, Color(0.11, 0.24, 0.4, 0.12))
	var grid := Color(UiStyle.CYAN, 0.07)
	for x in range(0, int(size.x), 32):
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid, 1)
	for y in range(0, int(size.y), 32):
		draw_line(Vector2(0, y), Vector2(size.x, y), grid, 1)
	# Paths in the gaps between buildings.
	var path := Color(UiStyle.CYAN_PALE, 0.3)
	var w := (area.size.x - GAP * (COLUMNS - 1)) / COLUMNS
	var h := (area.size.y - GAP * (ROWS - 1)) / ROWS
	var owner := _cell_owners()
	for r in ROWS:
		for c in range(1, COLUMNS):
			if owner.get(Vector2i(c - 1, r), "") == owner.get(Vector2i(c, r), "") and owner.has(Vector2i(c, r)):
				continue
			var x := area.position.x + c * (w + GAP) - GAP / 2.0
			var y := area.position.y + r * (h + GAP)
			draw_line(Vector2(x, y - GAP / 2.0), Vector2(x, y + h + GAP / 2.0), path, 2)
	for r in range(1, ROWS):
		var y := area.position.y + r * (h + GAP) - GAP / 2.0
		draw_line(Vector2(area.position.x - 6, y), Vector2(area.end.x + 6, y), path, 2)


## Grid cell -> building id.
func _cell_owners() -> Dictionary:
	var owners := {}
	for building in GameData.buildings:
		var cell: Array = building.get("cell", [0, 0])
		for i in int(building.get("span", 1)):
			owners[Vector2i(int(cell[0]) + i, int(cell[1]))] = building["id"]
	return owners
