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
	check_eq(Calendar.date_for(1, 0), "Sunday, September 1")
	check_eq(Calendar.date_for(7, 1), "Monday, October 14", "Ciel's birthday:")
	check_eq(Calendar.date_for(14, 3), "Wednesday, December 4", "Jay's birthday:")


func test_time_moves_day_then_night_then_next_day() -> void:
	var gs := _state(1, 6, "day")
	gs.advance_time()
	check_eq([gs.week, gs.day, gs.slot], [1, 6, "night"])
	gs.advance_time()
	check_eq([gs.week, gs.day, gs.slot], [2, 0, "day"], "Saturday night -> Sunday of next week:")


func test_semester_ends_after_week_14() -> void:
	var gs := _state(14, 6, "night")
	check(not gs.is_semester_over(), "still week 14")
	gs.advance_time()
	check(gs.is_semester_over(), "over after week 14 Saturday night")
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
	check(_event_ids(_state(1, 0, "day")).has("orientation"), "orientation on week 1 Sunday")
	check(_event_ids(_state(3, 4, "night")).has("tutoring_shift"), "Monty tutors Thursday nights")
	check(_event_ids(_state(3, 6, "night")).has("hackathon_night"), "hackathon on weekend nights")
	check(not _event_ids(_state(3, 5, "night")).has("hackathon_night"), "no hackathon on Friday")
	check(_event_ids(_state(7, 1, "night")).has("ciel_birthday"), "Ciel's birthday")


func test_everyone_is_at_orientation() -> void:
	for who in [["python", "day", "orientation"], ["javascript", "day", "orientation"], ["java", "day", "orientation"],
			["cpp", "night", "orientation_night"]]:
		var gs := _state(1, 0, who[1])
		gs.mark_date_complete("orientation")
		var here := Calendar.opportunity_for(who[0], gs)
		check_eq(here.get("event", {}).get("id"), who[2], "%s on the tour:" % who[0])
		check(not here.get("lessons", []).is_empty(), "%s has a lesson on the tour" % who[0])
	check(Calendar.opportunity_for("cpp", _state(1, 0, "day")).is_empty(), "Ciel only shows up after dark")


func test_tour_stops_are_in_their_own_rooms() -> void:
	var tour: Dictionary = Calendar.events_now(_state(1, 0, "day"))[0]
	check_eq(tour["id"], "orientation")
	check_eq(Calendar.location_for(tour, "python"), "greenhouse", "Monty in the greenhouse:")
	check_eq(Calendar.location_for(tour, "javascript"), "ta_office", "Jay in the TA office:")
	check_eq(Calendar.location_for(tour, "java"), "council_room", "Julian in the council room:")
	check_eq(Calendar.location_for(tour, "quack"), "main_quad", "anyone else is at the event's location:")
	var night: Dictionary = Calendar.events_now(_state(1, 0, "night"))[0]
	check_eq(Calendar.location_for(night, "cpp"), "hopper_lab", "Ciel in Hopper Lab:")


func test_no_weekly_events_on_orientation_day() -> void:
	check_eq(_event_ids(_state(1, 0, "day")), ["orientation"], "only orientation by day:")
	check_eq(_event_ids(_state(1, 0, "night")), ["orientation_night"], "only Ciel's tour stop that night:")
	check(_event_ids(_state(2, 0, "day")).has("gardening_club"), "the next Sunday is back to normal")
	check(_event_ids(_state(2, 0, "night")).has("hackathon_night"), "and so is its night")
	check(not Calendar.is_recurring_cancelled(1, 1), "Monday of week 1 is a normal day")


func test_characters_are_only_around_at_their_events() -> void:
	var gs := _state(1, 2, "day")   # Tuesday daytime: Jay's office hours and Julian's coffee society
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
	var day := Calendar.opportunity_for("javascript", _state(1, 2, "day"))
	check_eq(day["lessons"].map(func(l): return l["language"]), ["typescript"])
	var night := Calendar.opportunity_for("javascript", _state(4, 6, "night"))
	check_eq(night["event"]["id"], "hackathon_night")
	check_eq(night["lessons"].map(func(l): return l["language"]), ["javascript"])


func test_club_fair_scene_comes_before_its_lessons() -> void:
	var gs := _state(1, 5, "day")   # week 1, Friday
	gs.complete_lesson("g01_python", "python", 0)
	check_eq(_event_ids(gs)[0], "club_fair", "the club fair comes before everyone's usual Friday:")
	var here := Calendar.opportunity_for("python", gs)
	check_eq(here["event"]["id"], "club_fair")
	check_eq(Story.scene_for(here["event"], gs), "club_fair", "the introductions are waiting")
	check_eq(here["lessons"], [] as Array[Dictionary], "no lessons until the scene is watched")
	gs.mark_date_complete("club_fair")
	check_eq(Calendar.opportunity_for("python", gs)["lessons"].map(func(l): return l["dialogue"]), ["g02_python"])
	check_eq(Calendar.opportunity_for("javascript", gs)["lessons"].map(func(l): return l["dialogue"]),
		["g01_typescript", "g02_typescript"], "Day Jay: Comments, or Printing if you haven't done it with Jay yet:")


func test_watching_an_event_scene_takes_no_time() -> void:
	check(not Calendar.uses_time("club_fair", "club_fair"), "the club fair scene is free")
	check(Calendar.uses_time("club_fair", "g02_python"), "a lesson at the club fair uses the slot")
	check(not Calendar.uses_time("orientation", "g01_python"), "the campus tour takes no time")
	check(Calendar.uses_time("tutoring_shift", "g02_python"), "a normal lesson uses the slot")
	check(Calendar.uses_time("", "g02_python"), "no event: uses the slot")
