extends Control
## The campus map: the home screen between dates. A holographic map of campus
## with a pin wherever someone is (or a story scene is waiting). Pick a pin to
## see who's there and what you can do with them, pick a lesson or scene in
## the panel, then press Start.

@onready var map_view: CampusMapView = %MapView
@onready var hud: Hud = %Hud
@onready var place_name: Label = %PlaceName
@onready var place_blurb: Label = %PlaceBlurb
@onready var place_events: Label = %PlaceEvents
@onready var place_body: VBoxContainer = %PlaceBody
@onready var start_button: Button = %StartButton
@onready var affection_strip: GlassPanel = %AffectionStrip
@onready var affection_list: HBoxContainer = %AffectionList
@onready var wait_button: Button = %WaitButton
@onready var menu_button: Button = %MenuButton

const PANEL_WIDTH := 324.0

## The location shown in the panel.
var selected_location: String = ""
## What's picked in the panel: {"dialogue", "event_id", "kind"} with kind
## "lesson" or "scene", or {} if nothing can be picked.
var selected_item: Dictionary = {}
var _rows := ButtonGroup.new()


func _ready() -> void:
	menu_button.pressed.connect(func(): Router.goto(Router.MAIN_MENU))
	%CalendarButton.pressed.connect(func(): add_child(CalendarView.new()))
	wait_button.pressed.connect(_on_wait)
	start_button.pressed.connect(_on_start)
	map_view.location_selected.connect(_on_location_pressed)
	var strip_box := UiStyle.glass_box(10)
	strip_box.content_margin_left = 18
	strip_box.content_margin_right = 18
	strip_box.content_margin_top = 16
	strip_box.content_margin_bottom = 6
	affection_strip.add_theme_stylebox_override("panel", strip_box)
	refresh()


## Rebuilds everything for the current time.
func refresh() -> void:
	var places := who_is_where()
	if GameState.is_semester_over():
		wait_button.text = "See how it ends"
	else:
		wait_button.text = "Wait until tonight" if GameState.slot == "day" else "Wait until tomorrow"
	hud.refresh("Where to today?" if GameState.slot == "day" else "Where to tonight?")

	if not places.has(selected_location):
		selected_location = _first_place_with_people(places)
	var pins := {}
	for loc in places:
		var looks: Array = []
		for id in places[loc]["characters"]:
			looks.append(Looks.speaker_look(id, GameState.slot))
		pins[loc] = {"looks": looks, "has_scene": not places[loc]["scenes"].is_empty()}
	map_view.show_places(pins, selected_location)
	_show_location(selected_location, places)
	_build_affection_list()


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
		var loc: String = event.get("location", "")
		if not places.has(loc):
			places[loc] = {"characters": [], "events": [], "scenes": []}
		places[loc]["events"].append(event.get("name", ""))
		places[loc]["characters"].append_array(who)
		var scene := Story.scene_for(event, state, data)
		if scene != "":
			places[loc]["scenes"].append({"event": event, "dialogue": scene})
	return places


## Everything the player can pick at a place, in panel order: story scenes
## first, then each person's lessons (special chapter first), then each
## person's next special chapter if it's still locked.
## Each item: {kind: "scene" | "lesson" | "locked", text, tag, dialogue,
## event_id, character, missing}.
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
		var next := Unlocks.next_special_chapter(id, state, data)
		if next.has("dialogue") and not Unlocks.is_chapter_unlocked(next["id"], state, data):
			items.append({"kind": "locked", "text": "%s · Ch. %d: %s" % [who, int(next["chapter"]), next.get("title", "")],
				"tag": "LOCKED", "character": id, "missing": Unlocks.missing_for_chapter(next["id"], state, data)})
	return items


func _first_place_with_people(places: Dictionary) -> String:
	for loc in GameData.locations:
		if places.has(loc) and not places[loc]["characters"].is_empty():
			return loc
	for loc in GameData.locations:
		if places.has(loc):
			return loc
	return ""


func _on_location_pressed(loc: String) -> void:
	selected_location = loc
	refresh()


# --- The location panel ----------------------------------------------------------

func _show_location(loc: String, places: Dictionary) -> void:
	for child in place_body.get_children():
		place_body.remove_child(child)
		child.queue_free()
	selected_item = {}
	if loc == "":
		UiStyle.style_banner(place_name, "Nobody's around", UiStyle.NAVY_2, UiStyle.TEXT, 30, PANEL_WIDTH)
		place_blurb.text = "Wait until later, or come back another day."
		place_events.visible = false
		_update_start_button()
		return
	var info: Dictionary = GameData.locations.get(loc, {})
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
	elif place["characters"].is_empty():
		place_body.add_child(UiStyle.caption("Nobody to meet here right now"))
	else:
		place_body.add_child(UiStyle.caption("Nothing new to learn here yet"))

	# Pick the first thing that can be done.
	for row in place_body.get_children():
		if row is Button and not row.disabled:
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


## One thing to do (or a locked chapter) as a row you can pick.
func _item_row(item: Dictionary) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"ListRow"
	button.toggle_mode = true
	button.button_group = _rows
	button.custom_minimum_size = Vector2(0, 38)
	button.name = item.get("dialogue", "locked_" + item.get("character", ""))
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14
	row.offset_right = -12
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = item["text"]
	label.add_theme_font_override("font", UiStyle.body_font(700 if item["kind"] != "locked" else 600))
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", UiStyle.TEXT_DIM if item["kind"] == "locked" else UiStyle.TEXT)
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
		"locked":
			tag = UiStyle.caption("Locked", UiStyle.TEXT_DIM, 10)
		_:
			tag = UiStyle.chip("New", UiStyle.PINK, UiStyle.TEXT, 10) if item["tag"] == "NEW" \
				else UiStyle.caption("Open", UiStyle.CYAN, 10)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tag)
	button.add_child(row)
	button.tooltip_text = item["text"]
	if item["kind"] == "locked":
		button.disabled = true
		button.tooltip_text += "\nStill needed: " + ", ".join(PackedStringArray(item["missing"].map(_describe_requirement)))
	else:
		button.pressed.connect(func():
			selected_item = {"kind": item["kind"], "dialogue": item["dialogue"], "event_id": item["event_id"]}
			_update_start_button())
	return button


func _describe_requirement(id: String) -> String:
	var subject: Dictionary = GameData.get_subject(id)
	if not subject.is_empty():
		return subject.get("title", id)
	return GameData.get_special_chapter(id).get("title", id)


func _update_start_button() -> void:
	start_button.disabled = selected_item.is_empty()
	match selected_item.get("kind", ""):
		"scene":
			start_button.text = "Watch scene"
		"lesson":
			start_button.text = "Start lesson"
		_:
			start_button.text = "Start"


func _on_start() -> void:
	if not selected_item.is_empty():
		Router.goto(Router.DATE, {"date_id": selected_item["dialogue"], "event_id": selected_item["event_id"]})


# --- Affection strip ----------------------------------------------------------------

func _build_affection_list() -> void:
	for child in affection_list.get_children():
		affection_list.remove_child(child)
		child.queue_free()
	for id in GameData.character_ids():
		var entry := VBoxContainer.new()
		entry.name = id
		entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry.add_theme_constant_override("separation", 3)
		var value := GameState.get_affection(id)
		var text := "%s · %d" % [GameData.get_character(id).get("name", id), value]
		var label := UiStyle.caption(text, UiStyle.TEXT, 11)
		if id == JayBalance.CHARACTER:
			label.text += "  ·  " + JayBalance.describe().to_upper()
			if not JayBalance.is_balanced():
				label.add_theme_color_override("font_color", UiStyle.DUSK)
				label.tooltip_text = "Jay's sides are out of balance. Spend time with the other side."
				label.mouse_filter = Control.MOUSE_FILTER_PASS
		entry.add_child(label)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 6)
		bar.max_value = GameState.MAX_AFFECTION
		bar.value = value
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		entry.add_child(bar)
		affection_list.add_child(entry)


func _on_wait() -> void:
	if GameState.is_semester_over():
		Router.goto(Router.ENDINGS)
		return
	GameState.advance_time()
	GameState.save_game()
	refresh()
