extends TestCase
## Time and the semester calendar (scripts/progress/calendar.gd).

const GameStateScript := preload("res://scripts/autoload/game_state.gd")

var _nodes: Array[Node] = []


func _state(week: int = 1, day: int = 0, slot: String = "day") -> Node:
	var gs: Node = GameStateScript.new()
	gs.save_path = "user://test_save.json"
	gs.week = week
	gs.day = day
	gs.slot = slot
	_nodes.append(gs)
	return gs


func cleanup() -> void:
	super()
	for n in _nodes:
		if is_instance_valid(n):
			n.free()


func _event_ids(gs: Node) -> Array:
	return Calendar.events_now(gs).map(func(e): return e["id"])


func test_dates_match_the_real_calendar() -> void:
	check_eq(Calendar.date_for(1, 0), "Monday, August 31")
	check_eq(Calendar.date_for(7, 2), "Wednesday, October 14", "Ciel's birthday:")
	check_eq(Calendar.date_for(14, 4), "Friday, December 4", "Jay's birthday:")


func test_time_moves_day_then_night_then_next_day() -> void:
	var gs := _state(1, 6, "day")
	gs.advance_time()
	check_eq([gs.week, gs.day, gs.slot], [1, 6, "night"])
	gs.advance_time()
	check_eq([gs.week, gs.day, gs.slot], [2, 0, "day"], "Sunday night -> Monday of next week:")


func test_semester_ends_after_week_14() -> void:
	var gs := _state(14, 6, "night")
	check(not gs.is_semester_over(), "still week 14")
	gs.advance_time()
	check(gs.is_semester_over(), "over after week 14 Sunday night")
	check_eq(Calendar.events_now(gs), [] as Array[Dictionary])
	gs.advance_time()
	check_eq(gs.week, 15, "time stops moving")


func test_time_is_saved() -> void:
	var gs := _state(5, 3, "night")
	var copy := _state()
	copy.from_dict(gs.to_dict())
	check_eq([copy.week, copy.day, copy.slot], [5, 3, "night"])
	gs.new_game("Gee")
	check_eq([gs.week, gs.day, gs.slot], [1, 0, "day"], "new game starts at orientation:")


func test_recurring_and_story_events() -> void:
	check(_event_ids(_state(1, 0, "day")).has("orientation"), "orientation on week 1 Monday")
	check(_event_ids(_state(3, 3, "night")).has("tutoring_shift"), "Monty tutors Thursday nights")
	check(_event_ids(_state(3, 5, "night")).has("hackathon_night"), "hackathon on weekend nights")
	check(not _event_ids(_state(3, 4, "night")).has("hackathon_night"), "no hackathon on Friday")
	check(_event_ids(_state(7, 2, "night")).has("ciel_birthday"), "Ciel's birthday")


func test_everyone_is_at_orientation() -> void:
	var gs := _state(1, 0, "day")
	for id in ["python", "javascript", "java", "cpp"]:
		var here := Calendar.opportunity_for(id, gs)
		check_eq(here.get("event", {}).get("id"), "orientation", "%s at orientation:" % id)
		check(not here.get("lessons", []).is_empty(), "%s has a lesson at orientation" % id)


func test_characters_are_only_around_at_their_events() -> void:
	var gs := _state(1, 1, "day")   # Tuesday daytime: Jay's office hours and Julian's coffee society
	check(not Calendar.opportunity_for("javascript", gs).is_empty(), "Jay holds office hours")
	check(not Calendar.opportunity_for("java", gs).is_empty(), "Julian is at the coffee society")
	check(Calendar.opportunity_for("python", gs).is_empty(), "Monty isn't around")
	check(Calendar.opportunity_for("cpp", gs).is_empty(), "Ciel isn't around")


func test_two_characters_are_around_every_slot() -> void:
	for day in 7:
		for slot in ["day", "night"]:
			var gs := _state(3, day, slot)
			var around := ["python", "javascript", "java", "cpp"].filter(func(c): return not Calendar.opportunity_for(c, gs).is_empty())
			check_eq(around.size(), 2, "%s %s:" % [Calendar.DAY_KEYS[day], slot])


func test_jay_teaches_typescript_by_day_and_javascript_by_night() -> void:
	var day := Calendar.opportunity_for("javascript", _state(1, 1, "day"))
	check_eq(day["lessons"].map(func(l): return l["language"]), ["typescript"])
	var night := Calendar.opportunity_for("javascript", _state(4, 5, "night"))
	check_eq(night["event"]["id"], "hackathon_night")
	check_eq(night["lessons"].map(func(l): return l["language"]), ["javascript"])
