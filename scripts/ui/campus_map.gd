extends Control
## The campus map: the home screen between dates. Shows the date and time,
## every campus location grouped by area, and who is where right now. Pick a
## location to see who's there and the lessons they can do with you.
##
## There's no map art yet, so locations are a list of buttons. A location is
## only clickable while something is happening there.

const CharacterCardScene := preload("res://scenes/character_card.tscn")

@onready var time_label: Label = %TimeLabel
@onready var events_label: Label = %EventsLabel
@onready var wait_button: Button = %WaitButton
@onready var menu_button: Button = %MenuButton
@onready var affection_list: VBoxContainer = %AffectionList
@onready var locations_box: VBoxContainer = %Locations
@onready var place_name: Label = %PlaceName
@onready var place_events: Label = %PlaceEvents
@onready var place_cards: HBoxContainer = %PlaceCards

## The location shown on the right.
var selected_location: String = ""


func _ready() -> void:
	menu_button.pressed.connect(func(): Router.goto(Router.MAIN_MENU))
	wait_button.pressed.connect(_on_wait)
	refresh()


## Rebuilds everything for the current time.
func refresh() -> void:
	time_label.text = Calendar.describe_now()
	var places := who_is_where()
	var names: PackedStringArray = []
	for loc in places:
		names.append_array(PackedStringArray(places[loc]["events"]))
	events_label.text = ("Happening now: " + ", ".join(names)) if not names.is_empty() else "Nothing special is happening right now."
	if GameState.is_semester_over():
		wait_button.text = "See how it ends"
	else:
		wait_button.text = "Wait until tonight" if GameState.slot == "day" else "Wait until tomorrow"

	if not places.has(selected_location):
		selected_location = _first_place_with_people(places)
	_build_location_list(places)
	_show_location(selected_location, places)
	_build_affection_list()


## Location id -> {"characters": [ids], "events": [event names]} for every
## location where something is happening right now. A character at two
## events at once (a story event and their usual one) is only at the event
## Calendar picks, and an event whose characters are all elsewhere is left out.
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


func _first_place_with_people(places: Dictionary) -> String:
	for loc in GameData.locations:
		if places.has(loc) and not places[loc]["characters"].is_empty():
			return loc
	for loc in GameData.locations:
		if places.has(loc):
			return loc
	return ""


func _build_location_list(places: Dictionary) -> void:
	for child in locations_box.get_children():
		locations_box.remove_child(child)
		child.queue_free()
	var area := ""
	for loc in GameData.locations:
		var info: Dictionary = GameData.locations[loc]
		if info.get("area", "") != area:
			area = info.get("area", "")
			var header := Label.new()
			header.text = area
			header.add_theme_color_override("font_color", Color(1, 0.36, 0.54))
			locations_box.add_child(header)
		var button := Button.new()
		button.name = loc
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = info.get("name", loc)
		if places.has(loc):
			var who: PackedStringArray = []
			for id in places[loc]["characters"]:
				who.append(GameData.get_character(id).get("name", id))
			if not who.is_empty():
				button.text += "  ·  " + ", ".join(who)
		button.disabled = not places.has(loc)
		button.toggle_mode = true
		button.button_pressed = loc == selected_location
		button.pressed.connect(_on_location_pressed.bind(loc))
		locations_box.add_child(button)


func _on_location_pressed(loc: String) -> void:
	selected_location = loc
	refresh()


func _show_location(loc: String, places: Dictionary) -> void:
	for child in place_cards.get_children():
		place_cards.remove_child(child)
		child.queue_free()
	if loc == "":
		place_name.text = "Nobody's around right now"
		place_events.text = "Wait until later, or come back another day."
		return
	var info: Dictionary = GameData.locations.get(loc, {})
	place_name.text = info.get("name", loc)
	var place: Dictionary = places.get(loc, {"characters": [], "events": [], "scenes": []})
	place_events.text = ", ".join(PackedStringArray(place["events"]))
	if place["characters"].is_empty() and place["scenes"].is_empty():
		place_events.text += "\nNobody to meet here right now."
	for scene in place["scenes"]:
		var button := Button.new()
		button.name = scene["dialogue"]
		button.text = "Watch: " + scene["event"].get("name", "")
		button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		button.pressed.connect(_on_date_requested.bind("", scene["dialogue"], scene["event"]["id"]))
		place_cards.add_child(button)
	var crowded: bool = place["characters"].size() > 2
	for id in place["characters"]:
		var card := CharacterCardScene.instantiate()
		card.setup(GameData.get_character(id))
		if crowded:
			# Smaller cards so four fit side by side (orientation, festivals).
			card.custom_minimum_size.x = 0
			card.get_node("%Portrait").custom_minimum_size.y = 120
			card.get_node("%TaglineLabel").visible = false
		card.date_requested.connect(_on_date_requested)
		place_cards.add_child(card)


func _build_affection_list() -> void:
	for child in affection_list.get_children():
		affection_list.remove_child(child)
		child.queue_free()
	for id in GameData.character_ids():
		var label := Label.new()
		label.text = "%s: %s (%d)" % [GameData.get_character(id).get("name", id), GameState.get_level(id)["title"], GameState.get_affection(id)]
		if id == JayBalance.CHARACTER:
			label.text += "  ·  " + JayBalance.describe()
			if not JayBalance.is_balanced():
				label.add_theme_color_override("font_color", Color(1, 0.6, 0.4))
				label.tooltip_text = "Jay's sides are out of balance. Spend time with the other side."
		affection_list.add_child(label)


func _on_wait() -> void:
	if GameState.is_semester_over():
		Router.goto(Router.ENDINGS)
		return
	GameState.advance_time()
	GameState.save_game()
	refresh()


func _on_date_requested(_character_id: String, date_id: String, event_id: String) -> void:
	Router.goto(Router.DATE, {"date_id": date_id, "event_id": event_id})
