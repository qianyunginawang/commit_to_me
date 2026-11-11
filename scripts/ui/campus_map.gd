extends Control
## The campus map: the home screen between dates. A holographic map of the
## campus buildings, each with a bubble for whoever is inside (or a "!" when a
## story scene is waiting). Click a building to list its rooms, then a room:
## an empty room shows its walk-in description, and a room with someone in it
## lists the lessons and scenes there. Pick one, then press Start.
##
## On orientation day the campus tour runs here (see Tour): Quack talks in a
## speech box under the map, the building he's showing is picked for you,
## the other buildings are locked, and there's no waiting until the tour ends.

@onready var map_view: CampusMapView = %MapView
@onready var hud: Hud = %Hud
@onready var place_name: Label = %PlaceName
@onready var place_blurb: Label = %PlaceBlurb
@onready var place_events: Label = %PlaceEvents
@onready var place_body: VBoxContainer = %PlaceBody
@onready var start_button: Button = %StartButton
@onready var wait_button: Button = %WaitButton
@onready var menu_button: Button = %MenuButton

const PANEL_WIDTH := 324.0

## The building whose rooms the panel lists.
var selected_building: String = ""
## The room shown in the panel, or "" when the panel lists the building's rooms.
var selected_location: String = ""
## What's picked in the panel: {"dialogue", "event_id", "kind"} with kind
## "lesson" or "scene", or {} if nothing can be picked.
var selected_item: Dictionary = {}
var _rows := ButtonGroup.new()
var _places: Dictionary = {}

## The campus tour: the stop Quack is showing ("" before the first refresh,
## "outro" for the goodbye), and which of his lines is on screen.
var _tour_stop: String = ""
var _tour_line := 0
var _quack_box: GlassPanel
var _quack_text: Label
var _quack_next: Button


func _ready() -> void:
	menu_button.pressed.connect(open_menu)
	%CalendarButton.pressed.connect(func(): add_child(CalendarView.new()))
	%AffectionButton.pressed.connect(open_affection)
	wait_button.pressed.connect(_on_wait)
	start_button.pressed.connect(_on_start)
	map_view.building_selected.connect(_on_building_pressed)
	_build_quack_box()
	refresh()


## The in-game menu (top right, or Esc).
func open_menu() -> void:
	if not has_node("PauseMenu") and not has_node("CalendarOverlay") and not has_node("AffectionOverlay"):
		add_child(PauseMenu.new())


## The affection summary pop-up (the AFFECTION button next to CALENDAR).
func open_affection() -> void:
	if not has_node("AffectionOverlay"):
		add_child(AffectionView.new())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		open_menu()


## Rebuilds everything for the current time.
func refresh() -> void:
	var places := who_is_where()
	if GameState.is_semester_over():
		wait_button.text = "See how it ends"
	else:
		wait_button.text = "Wait until tonight" if GameState.slot == "day" else "Wait until tomorrow"
	var touring := Tour.is_on()
	# No skipping time on the campus tour: meet everyone first.
	wait_button.visible = not Tour.blocks_waiting()
	if touring:
		hud.refresh("Campus tour")
	else:
		hud.refresh("Where to today?" if GameState.slot == "day" else "Where to tonight?")

	if touring:
		_sync_tour()
	elif not places.has(selected_location):
		selected_location = _first_place_with_people(places)
		selected_building = GameData.locations.get(selected_location, {}).get("building", "")
	_places = places
	map_view.set_compact(touring)
	map_view.show_buildings(who_is_in_buildings(places), selected_building)
	map_view.lock_all_but(selected_building if touring else null)
	_quack_box.visible = touring
	if touring:
		_show_quack_line()
	_show_panel()


## Building id -> {"looks": [one per person], "has_scene": bool}, from
## who_is_where().
static func who_is_in_buildings(places: Dictionary) -> Dictionary:
	var info := {}
	for loc in places:
		var building: String = GameData.locations.get(loc, {}).get("building", "")
		if building == "":
			continue
		if not info.has(building):
			info[building] = {"looks": [], "has_scene": false, "characters": []}
		for id in places[loc]["characters"]:
			if not id in info[building]["characters"]:
				info[building]["characters"].append(id)
				info[building]["looks"].append(Looks.speaker_look(id, GameState.slot))
		if not places[loc]["scenes"].is_empty():
			info[building]["has_scene"] = true
	return info


## Location id -> {"characters": [ids], "events": [event names], "scenes":
## [{event, dialogue}]} for every location where something is happening right
## now. A character at two events at once (a story event and their usual one)
## is only at the event Calendar picks, and an event whose characters are all
## elsewhere is left out.
static func who_is_where(state: Node = null, data: Node = null) -> Dictionary:
	var places := {}
	var gd: Node = data if data != null else GameData
	var placed := {}
	for id in gd.character_ids():
		var here := Calendar.opportunity_for(id, state, data)
		if not here.is_empty():
			placed[id] = here["event"]["id"]
	for event in Calendar.events_now(state, data):
		var who: Array = event.get("characters", []).filter(func(c): return placed.get(c) == event["id"])
		if who.is_empty() and not event.get("characters", []).is_empty():
			continue
		var scene := Story.scene_for(event, state, data)
		# Scenes play at the event's location; each person stands at their
		# own stop (the campus tour), which is usually the same room.
		var loc: String = event.get("location", "")
		if scene != "":
			_add_place(places, loc, event.get("name", ""))
			places[loc]["scenes"].append({"event": event, "dialogue": scene})
		for id in who:
			var stop := Calendar.location_for(event, id)
			_add_place(places, stop, event.get("name", ""))
			places[stop]["characters"].append(id)
		if who.is_empty() and scene == "":
			_add_place(places, loc, event.get("name", ""))
	return places


static func _add_place(places: Dictionary, loc: String, event_name: String) -> void:
	if not places.has(loc):
		places[loc] = {"characters": [], "events": [], "scenes": []}
	if not event_name in places[loc]["events"]:
		places[loc]["events"].append(event_name)


## Everything the player can pick at a place, in panel order: story scenes
## first, then each person's lessons (special chapter first). Locked
## chapters aren't shown.
## Each item: {kind: "scene" | "lesson", text, tag, dialogue, event_id,
## character}.
static func place_items(place: Dictionary, state: Node = null, data: Node = null) -> Array[Dictionary]:
	var gd: Node = data if data != null else GameData
	var items: Array[Dictionary] = []
	for scene in place.get("scenes", []):
		items.append({"kind": "scene", "text": scene["event"].get("name", ""), "tag": "SCENE",
			"dialogue": scene["dialogue"], "event_id": scene["event"]["id"]})
	for id in place.get("characters", []):
		var here := Calendar.opportunity_for(id, state, data)
		var who: String = gd.get_character(id).get("name", id)
		for lesson in here.get("lessons", []):
			var special: bool = lesson.has("chapter")
			var text := "%s · Ch. %d: %s" % [who, int(lesson["chapter"]), lesson.get("title", "")] if special \
				else "%s · %s" % [who, lesson.get("title", "")]
			items.append({"kind": "lesson", "text": text, "tag": "NEW" if special else "OPEN",
				"dialogue": lesson["dialogue"], "event_id": here["event"]["id"], "character": id})
	return items


## The room the panel opens on: a story scene first, then someone to meet.
func _first_place_with_people(places: Dictionary) -> String:
	for loc in GameData.locations:
		if places.has(loc) and not places[loc]["scenes"].is_empty():
			return loc
	for loc in GameData.locations:
		if places.has(loc) and not places[loc]["characters"].is_empty():
			return loc
	for loc in GameData.locations:
		if places.has(loc):
			return loc
	return ""


func _on_building_pressed(building: String) -> void:
	if not Tour.can_pick(building):
		return
	selected_building = building
	selected_location = ""
	map_view.show_buildings(who_is_in_buildings(_places), selected_building)
	_show_panel()


func _on_room_pressed(loc: String) -> void:
	selected_location = loc
	_show_panel()


func _on_back() -> void:
	if selected_location == "":
		return
	selected_location = ""
	_show_panel()


# --- The panel ---------------------------------------------------------------------

func _show_panel() -> void:
	if selected_location == "" and selected_building != "":
		_show_building(selected_building, _places)
	else:
		_show_location(selected_location, _places)


func _clear_body() -> void:
	for child in place_body.get_children():
		place_body.remove_child(child)
		child.queue_free()
	selected_item = {}


## A building's room list. Each room says who's there, if anyone.
func _show_building(building: String, places: Dictionary) -> void:
	_clear_body()
	var info := GameData.get_building(building)
	UiStyle.style_banner(place_name, info.get("name", building), UiStyle.CYAN, UiStyle.INK, 32, PANEL_WIDTH)
	place_blurb.text = info.get("blurb", "")
	place_events.visible = false
	place_body.add_child(UiStyle.caption("Rooms"))
	for loc in GameData.rooms_in(building):
		place_body.add_child(_room_row(loc, places.get(loc, {})))
	_update_start_button()


## One room in a building's list: its name, then who's there, a scene, or
## (for flavor rooms) "Explore".
func _room_row(loc: String, place: Dictionary) -> Button:
	var info: Dictionary = GameData.locations.get(loc, {})
	var button := Button.new()
	button.theme_type_variation = &"ListRow"
	button.custom_minimum_size = Vector2(0, 38)
	button.name = loc
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14
	row.offset_right = -12
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	var busy: bool = not place.get("characters", []).is_empty() or not place.get("scenes", []).is_empty()
	var label := Label.new()
	label.text = info.get("name", loc)
	label.add_theme_font_override("font", UiStyle.body_font(700 if busy else 600))
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", UiStyle.TEXT if busy else UiStyle.TEXT_SOFT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	row.add_child(label)
	var tags: Array[Label] = []
	for id in place.get("characters", []):
		var look := Looks.speaker_look(id, GameState.slot)
		tags.append(UiStyle.chip(look.get("name", id), UiStyle.PINK, UiStyle.TEXT, 10))
	if not place.get("scenes", []).is_empty():
		tags.append(UiStyle.chip("Scene", UiStyle.GOLD, UiStyle.INK, 10))
	if tags.is_empty() and info.get("flavor", false):
		tags.append(UiStyle.caption("Explore", UiStyle.TEXT_DIM, 10))
	if loc == _tour_room():
		# Quack points at this room.
		tags.append(UiStyle.chip("Go in", UiStyle.GOLD, UiStyle.INK, 10))
		button.name = loc
		button.add_theme_stylebox_override("normal", UiStyle.glass_box(6, UiStyle.GOLD))
	for tag in tags:
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tag)
	button.add_child(row)
	button.tooltip_text = info.get("name", loc)
	button.pressed.connect(_on_room_pressed.bind(loc))
	return button


func _show_location(loc: String, places: Dictionary) -> void:
	_clear_body()
	if loc == "":
		UiStyle.style_banner(place_name, "Nobody's around", UiStyle.NAVY_2, UiStyle.TEXT, 30, PANEL_WIDTH)
		place_blurb.text = "Wait until later, or come back another day."
		place_events.visible = false
		_update_start_button()
		return
	var info: Dictionary = GameData.locations.get(loc, {})
	var building: Dictionary = GameData.get_building(info.get("building", ""))
	if not building.is_empty():
		var back := Button.new()
		back.name = "BackButton"
		back.flat = true
		back.alignment = HORIZONTAL_ALIGNMENT_LEFT
		back.text = "‹  " + building.get("name", "").to_upper()
		back.add_theme_font_override("font", UiStyle.label_font(2))
		back.add_theme_font_size_override("font_size", 12)
		back.add_theme_color_override("font_color", UiStyle.CYAN)
		back.pressed.connect(_on_back)
		place_body.add_child(back)
	UiStyle.style_banner(place_name, info.get("name", loc), UiStyle.PINK, UiStyle.TEXT, 32, PANEL_WIDTH)
	place_blurb.text = info.get("blurb", "")
	var place: Dictionary = places.get(loc, {"characters": [], "events": [], "scenes": []})
	place_events.text = " · ".join(PackedStringArray(place["events"])).to_upper()
	place_events.visible = place_events.text != ""

	if not place["characters"].is_empty():
		place_body.add_child(UiStyle.caption("Here now"))
		var compact: bool = place["characters"].size() > 2
		for id in place["characters"]:
			place_body.add_child(_person_row(id, compact))

	var items := place_items(place)
	if not items.is_empty():
		place_body.add_child(UiStyle.caption("Lessons here" if place["scenes"].is_empty() else "Things to do"))
		for item in items:
			place_body.add_child(_item_row(item))
	elif info.get("flavor", false):
		place_body.add_child(UiStyle.caption("You look around for a bit"))
	elif place["characters"].is_empty():
		place_body.add_child(UiStyle.caption("Nobody to meet here right now"))
	else:
		place_body.add_child(UiStyle.caption("Nothing new to learn here yet"))

	# Pick the first thing that can be done.
	for row in place_body.get_children():
		if row is Button and row.toggle_mode and not row.disabled:
			row.button_pressed = true
			row.pressed.emit()
			break
	_update_start_button()


## A person at this location: a framed portrait, their name, and the event.
func _person_row(id: String, compact: bool) -> Control:
	var look := Looks.speaker_look(id, GameState.slot)
	var row := HBoxContainer.new()
	row.name = id
	row.add_theme_constant_override("separation", 12)
	var thumb: Portrait = preload("res://scenes/portrait.tscn").instantiate()
	thumb.custom_minimum_size = Vector2(46, 52) if compact else Vector2(64, 72)
	row.add_child(thumb)
	thumb.show_look(look)
	thumb.get_node("%Initial").add_theme_font_size_override("font_size", 30 if compact else 40)
	var frame := Panel.new()
	frame.theme_type_variation = &"PortraitFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.add_child(frame)
	var text := VBoxContainer.new()
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_theme_constant_override("separation", 4)
	var name_label := Label.new()
	name_label.text = look.get("name", id).to_upper()
	name_label.add_theme_font_override("font", UiStyle.display_font())
	name_label.add_theme_font_size_override("font_size", 20 if compact else 26)
	text.add_child(name_label)
	# The event is already named above, so the chip shows the language.
	var chip := UiStyle.chip(look.get("language", ""), UiStyle.SLOT_COLORS.get(GameState.slot, UiStyle.GOLD), UiStyle.INK, 10)
	text.add_child(chip)
	row.add_child(text)
	return row


## One thing to do, as a row you can pick.
func _item_row(item: Dictionary) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"ListRow"
	button.toggle_mode = true
	button.button_group = _rows
	button.custom_minimum_size = Vector2(0, 38)
	button.name = item["dialogue"]
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14
	row.offset_right = -12
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = item["text"]
	label.add_theme_font_override("font", UiStyle.body_font(700))
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", UiStyle.TEXT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	row.add_child(label)
	var tag: Label
	match item["kind"]:
		"scene":
			tag = UiStyle.chip("Scene", UiStyle.GOLD, UiStyle.INK, 10)
		_:
			tag = UiStyle.chip("New", UiStyle.PINK, UiStyle.TEXT, 10) if item["tag"] == "NEW" \
				else UiStyle.caption("Open", UiStyle.CYAN, 10)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tag)
	button.add_child(row)
	button.tooltip_text = item["text"]
	button.pressed.connect(func():
		selected_item = {"kind": item["kind"], "dialogue": item["dialogue"], "event_id": item["event_id"]}
		_update_start_button())
	return button


func _update_start_button() -> void:
	start_button.disabled = selected_item.is_empty() and selected_location == ""
	match selected_item.get("kind", ""):
		"scene":
			start_button.text = "Watch scene"
		"lesson":
			start_button.text = "Start lesson"
		_:
			# An empty room: the button takes you back to the building's rooms.
			start_button.text = "Back to map" if selected_location != "" else "Pick a room"


func _on_start() -> void:
	if selected_item.is_empty():
		_on_back()
	else:
		Router.goto(Router.DATE, {"date_id": selected_item["dialogue"], "event_id": selected_item["event_id"]})


# --- Campus tour ---------------------------------------------------------------------

## Follows the tour: when Quack moves on to a new stop, his building is
## picked, its room list is shown, and he starts from his first line.
func _sync_tour() -> void:
	Tour.catch_up_time()
	var stop := Tour.current_stop()
	var key: String = stop.get("building", "outro")
	if key == _tour_stop:
		return
	_tour_stop = key
	_tour_line = 0
	if not stop.is_empty():
		selected_building = stop["building"]
		selected_location = ""


## Quack's lines for the current stop, or his goodbye.
func _tour_lines() -> Array:
	if _tour_stop == "outro":
		return GameData.tour.get("outro", [])
	return Tour.current_stop().get("lines", [])


## The room Quack is pointing at, once he's done introducing the building.
func _tour_room() -> String:
	if not Tour.is_on() or _tour_line < _tour_lines().size():
		return ""
	return Tour.current_stop().get("room", "")


func _show_quack_line() -> void:
	var lines := _tour_lines()
	var stop := Tour.current_stop()
	var text := ""
	if _tour_line < lines.size():
		text = lines[_tour_line]
	else:
		text = stop.get("room_line", "")
	_quack_text.text = text.replace("{player}", GameState.player_name)
	var last := _tour_line >= lines.size() - 1
	var waiting_for_date: bool = stop.get("character", "") != "" and _tour_line >= lines.size()
	_quack_next.visible = not waiting_for_date
	if not last:
		_quack_next.text = "NEXT"
	elif _tour_stop == "outro":
		_quack_next.text = "LET'S GO"
	elif stop.get("character", "") != "":
		_quack_next.text = "NEXT"
	else:
		_quack_next.text = "NEXT STOP"


## Quack's button: his next line, or on to the next stop.
func _on_quack_next() -> void:
	var lines := _tour_lines()
	var stop := Tour.current_stop()
	if _tour_line < lines.size() - 1:
		_tour_line += 1
		_show_quack_line()
		return
	if stop.get("character", "") != "" and _tour_line < lines.size():
		# Point at the room, and wait for the player to go in.
		_tour_line = lines.size()
		_show_quack_line()
		if selected_location == "":
			_show_panel()
		return
	Tour.next()
	GameState.save_game()
	refresh()


func _build_quack_box() -> void:
	_quack_box = GlassPanel.new()
	_quack_box.name = "QuackBox"
	_quack_box.tab_text = "Quack"
	add_child(_quack_box)
	# Under the compact map, the same width as the map.
	var top := map_view.offset_top + CampusMapView.AREA.end.y - CampusMapView.COMPACT_CUT + 16
	_quack_box.position = Vector2(CampusMapView.AREA.position.x, top)
	_quack_box.size = Vector2(CampusMapView.AREA.size.x, 706 - top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_quack_box.add_child(row)
	var thumb: Portrait = preload("res://scenes/portrait.tscn").instantiate()
	thumb.custom_minimum_size = Vector2(52, 52)
	row.add_child(thumb)
	thumb.show_look(Looks.speaker_look("quack"))
	thumb.get_node("%Initial").add_theme_font_size_override("font_size", 28)
	var frame := Panel.new()
	frame.theme_type_variation = &"PortraitFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.add_child(frame)
	_quack_text = Label.new()
	_quack_text.name = "QuackText"
	_quack_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quack_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quack_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_quack_text.add_theme_font_size_override("font_size", 15)
	_quack_text.add_theme_color_override("font_color", UiStyle.TEXT_SOFT)
	row.add_child(_quack_text)
	_quack_next = Button.new()
	_quack_next.name = "QuackNext"
	_quack_next.theme_type_variation = &"BrightButton"
	_quack_next.custom_minimum_size = Vector2(130, 40)
	_quack_next.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_quack_next.pressed.connect(_on_quack_next)
	row.add_child(_quack_next)
	_quack_box.visible = false


func _on_wait() -> void:
	if GameState.is_semester_over():
		Router.goto(Router.ENDINGS)
		return
	GameState.advance_time()
	GameState.save_game()
	refresh()
