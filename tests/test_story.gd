extends TestCase
## Story flags, the hidden Polyglot choice and the Polyglot route
## (scripts/progress/story.gd).

const GameStateScript := preload("res://scripts/autoload/game_state.gd")
const ProfileScript := preload("res://scripts/autoload/profile.gd")
const GameDataScript := preload("res://scripts/autoload/game_data.gd")
const CampusMap := preload("res://scripts/ui/campus_map.gd")

var _nodes: Array[Node] = []


func cleanup() -> void:
	super()
	for n in _nodes:
		if is_instance_valid(n):
			n.free()
	DirAccess.remove_absolute("user://test_profile.json")
	DirAccess.remove_absolute("user://test_save.json")


func _state(week: int = 4, day: int = 6, slot: String = "night", affection: int = 0) -> Node:
	var gs: Node = GameStateScript.new()
	gs.save_path = "user://test_save.json"
	gs.week = week
	gs.day = day
	gs.slot = slot
	for id in GameData.character_ids():
		gs.affection[id] = affection
	_nodes.append(gs)
	return gs


func _profile(good_ending: bool) -> Node:
	var p: Node = ProfileScript.new()
	p.profile_path = "user://test_profile.json"
	if good_ending:
		p.record_ending("python_ending_good")
	_nodes.append(p)
	return p


func _quack_event() -> Dictionary:
	for event in GameData.calendar["events"]:
		if event["id"] == "quack_check_in":
			return event
	return {}


func test_polyglot_choice_needs_a_good_ending_and_everyone_at_20() -> void:
	var event := _quack_event()
	check_eq(Story.scene_for(event, _state(4, 6, "night", 20), null, _profile(false)), "quack_check_in",
		"no good ending seen yet:")
	check_eq(Story.scene_for(event, _state(4, 6, "night", 20), null, _profile(true)), "quack_check_in_polyglot")
	var low := _state(4, 6, "night", 20)
	low.affection["cpp"] = 19
	check_eq(Story.scene_for(event, low, null, _profile(true)), "quack_check_in", "Ciel at 19:")


func test_watched_scene_does_not_play_again() -> void:
	var gs := _state()
	gs.mark_date_complete("quack_check_in")
	check_eq(Story.scene_for(_quack_event(), gs, null, _profile(false)), "")


func test_choice_sets_the_flag_and_it_is_saved() -> void:
	var gs := _state()
	var p := DialoguePlayer.new(GameData.get_date("quack_check_in_polyglot"), "Gee")
	p.flag_set.connect(gs.set_flag)
	p.start()
	p.advance()
	p.advance()
	p.choose(0)
	check(gs.has_flag("polyglot"), "picking 'Why choose just one language?' sets polyglot")
	gs.save_game()
	var again := _state()
	again.load_game()
	check(again.has_flag("polyglot"), "the flag survives save and load")
	again.new_game("Gee")
	check(not again.has_flag("polyglot"), "a new game clears flags")


func test_polyglot_events_only_happen_on_the_route() -> void:
	var gs := _state(5, 0, "day")
	var ids := func(): return Calendar.events_now(gs).map(func(e): return e["id"])
	check(not ids.call().has("polyglot_rivalry"), "off the route")
	gs.set_flag("polyglot")
	check(ids.call().has("polyglot_rivalry"), "on the route")


func test_map_offers_the_quack_scene() -> void:
	var places := CampusMap.who_is_where(_state())
	check(places.has("babbage_hall"), "Quack's check-in is at Babbage Hall")
	var scenes: Array = places.get("babbage_hall", {}).get("scenes", [])
	check_eq(scenes.map(func(s): return s["dialogue"]), ["quack_check_in"])


## Real content, with every special chapter "written" so finals can be passed.
func _data() -> Node:
	var gd: Node = GameDataScript.new()
	for key in ["characters", "dates", "challenges", "curriculum", "lessons", "routes"]:
		gd.set(key, GameData.get(key).duplicate(true))
	for key in ["languages", "locations", "calendar", "endings"]:
		gd.set(key, GameData.get(key))
	for character_id in gd.routes:
		for chapter in gd.routes[character_id]["chapters"]:
			chapter["dialogue"] = "test_" + chapter["id"]
	_nodes.append(gd)
	return gd


func test_polyglot_ending_good_and_bad() -> void:
	var gd := _data()
	var gs := _state(14, 6, "night", 80)
	check_eq(Endings.polyglot_ending(gs, gd).get("id"), "polyglot_ending_bad", "finals not passed:")
	for id in gd.character_ids():
		var chapters: Array = gd.special_chapters(id)
		gs.mark_date_complete(chapters[-1]["dialogue"])
	check_eq(Endings.polyglot_ending(gs, gd).get("id"), "polyglot_ending_good")
	gs.affection["java"] = 79
	check_eq(Endings.polyglot_ending(gs, gd).get("id"), "polyglot_ending_bad", "Julian at 79:")
