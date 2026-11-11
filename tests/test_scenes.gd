extends TestCase

const CampusMap := preload("res://scripts/ui/campus_map.gd")
## Smoke tests: every screen loads and sets itself up without errors.


func test_main_menu_buttons() -> void:
	var scene := add_node(load(Router.MAIN_MENU).instantiate())
	var names: Array = scene.get_node("Buttons").get_children().map(func(b): return b.text)
	check_eq(names, ["CONTINUE GAME", "NEW GAME", "SETTINGS", "QUIT"])
	check(scene.get_node("%ContinueButton").disabled, "nothing to continue without a save")
	check_eq(scene.get_node("%NewGameButton").theme_type_variation, &"BrightButton")


func test_continue_lists_saves_newest_first() -> void:
	GameState.new_game("Old")
	GameState.start_new_save()
	GameState.save_game()
	GameState.new_game("New")
	GameState.start_new_save()
	GameState.save_game()
	var menu := add_node(load(Router.MAIN_MENU).instantiate())
	check(not menu.get_node("%ContinueButton").disabled, "continue works once there's a save")
	var page := add_node(load(Router.LOAD_GAME).instantiate())
	check_eq(page.list.get_child_count(), 2)
	var top: Button = page.list.get_child(0).get_child(0)
	check(_texts(top).has("New"), "the latest game is on top")
	check(_texts(top).has("LATEST"))
	check(_texts(top).has("WEEK 1 · SUNDAY · DAY"))
	check(_texts(page.list.get_child(1)).has("Old"))

	# Delete asks once more, then the save is gone.
	var delete: Button = top.get_parent().get_child(1)
	check_eq(delete.text, "DELETE")
	delete.pressed.emit()
	check_eq(delete.text, "SURE?")
	check_eq(GameState.list_saves().size(), 2, "not deleted until confirmed")
	delete.pressed.emit()
	check_eq(GameState.list_saves().size(), 1)
	check_eq(GameState.list_saves()[0]["player_name"], "Old")


func test_quack_asks_your_name_at_orientation() -> void:
	GameState.new_game("")
	GameState.start_new_save()
	Router.params = {"date_id": "orientation", "event_id": "orientation"}
	var scene := add_node(load(Router.DATE).instantiate())
	while scene.player.current_id != "name":
		scene._finish_typing()
		scene.player.advance()
	scene._finish_typing()
	var edit: LineEdit = scene.find_child("NameEdit", true, false)
	check(edit != null, "a name pop-up appears")
	scene._on_advance_pressed()
	check_eq(scene.player.current_id, "name", "clicking doesn't skip the question")
	scene._on_name_entered("  Ada ")
	check_eq(GameState.player_name, "Ada")
	check_eq(scene.player.current_id, "nice")
	check(scene.find_child("NameModal", true, false) == null, "the pop-up closes")
	check(scene.get_node("%TextLabel").text.contains("Ada!"), "Quack uses the new name")
	check_eq(GameState.list_saves()[0]["player_name"], "Ada", "the new save has the name")


func test_settings_page_changes_settings() -> void:
	var page := add_node(load(Router.SETTINGS).instantiate())
	check_eq(page.controls.keys(), ["master_volume", "music_volume", "voice_volume", "fullscreen", "text_speed", "auto_speed", "quack_hints"])
	var slow := Settings.chars_per_second()
	page.controls["text_speed"].value = 100
	check_eq(Settings.get_value("text_speed"), 1.0)
	check(Settings.chars_per_second() > slow, "faster text types faster")
	page.controls["quack_hints"].button_pressed = false
	check(not Settings.quack_hints(), "hints turned off")
	Settings.load_settings()
	check(not Settings.quack_hints(), "settings are saved")
	Settings.set_value("quack_hints", true)
	Settings.set_value("text_speed", Settings.DEFAULTS["text_speed"])


static func _texts(node: Node) -> Array:
	var texts := []
	for child in node.find_children("*", "Label", true, false):
		texts.append(child.text)
	return texts


func test_date_scene_starts_dialogue() -> void:
	Router.params = {"date_id": "g01_python", "event_id": "orientation"}
	var scene := add_node(load(Router.DATE).instantiate())
	check_eq(scene.player.current_id, "intro")
	check(scene.get_node("%TextLabel").text.contains("greenhouse"), "first line should be shown")
	check(not scene.has_node("%AffectionPanel"), "affection is only on the map's Affection button")
	check_eq(scene.get_node("%NameRow").get_child_count(), 0, "the narrator has no name banner")
	scene.player.advance()
	check_eq(scene.get_node("%NameRow").get_child(0).text, "MONTY", "Monty's name banner")
	check_eq(scene.get_node("%NameRow").get_child(1).text, "PYTHON", "and language tag")


func test_story_scene_shows_whoever_speaks() -> void:
	GameState.new_game("Gee")
	Router.params = {"date_id": "orientation", "event_id": "orientation"}
	var scene := add_node(load(Router.DATE).instantiate())
	for i in 4:  # four narrator lines, then Quack
		scene.player.advance()
	check_eq(scene.get_node("%NameRow").get_child(0).text, "QUACK")
	for i in 6:  # the name question, then four more lines
		scene.player.advance()
	check_eq(scene.get_node("%Choices").get_child_count(), 0, "choices wait for the line to finish typing")
	scene._finish_typing()
	check_eq(scene.get_node("%Choices").get_child_count(), 4, "Why did you pick CS?")
	check(scene.get_node("%Choices").get_parent().get_parent().get_parent() == scene.get_node("%DialogueBox"),
		"the answers are inside the dialogue box")
	check(scene.get_node("%Choices").get_child(0).has_focus(), "the first answer starts highlighted")
	scene.get_node("%Choices").get_child(1).grab_focus()
	scene.get_node("%NextButton").pressed.emit()
	check_eq(scene.player.current_id, "money", "Next picks the highlighted answer:")
	check(not scene.get_node("%Choices").visible, "the answers go away")


func test_history_auto_skip_and_menu() -> void:
	GameState.new_game("Gee")
	Router.params = {"date_id": "orientation", "event_id": "orientation"}
	var scene := add_node(load(Router.DATE).instantiate())
	check_eq(scene.get_node("%Hud")._place_label.text, "QUAD LAWN, MAIN QUAD", "the place is on the info card:")

	# Skip races through lines and stops at Quack's question.
	scene.get_node("%SkipButton").button_pressed = true
	while scene.player.current_id != "name":
		scene._on_next_timer()
	scene._schedule_next()
	check(not scene.get_node("%SkipButton").button_pressed, "skip stops at the question")
	check_eq(scene.history.size(), 6, "four narrator lines, Quack's hello, then the question:")
	check_eq(scene.history[4]["speaker"], "Quack")
	scene._on_name_entered("Ada")
	check_eq(scene.history[6], {"speaker": "Ada", "text": "Ada", "choice": true})

	# Auto waits for the line to finish typing, then moves on.
	scene.get_node("%AutoButton").button_pressed = true
	check(scene._next_timer.is_stopped(), "still typing")
	await scene._typing_tween.finished
	check(not scene._next_timer.is_stopped(), "auto is waiting to advance")
	scene.get_node("%AutoButton").button_pressed = false

	scene.show_history()
	check_eq(scene.get_node("HistoryPanel").find_child("Lines", true, false).get_child_count(), scene.history.size())
	scene._close_modal("HistoryPanel")

	scene.open_menu()
	check(scene.has_node("PauseMenu"), "the menu opens")
	var labels: Array = scene.get_node("PauseMenu").find_children("*", "Button", true, false).map(func(b): return b.text)
	check_eq(labels, ["RESUME", "HISTORY", "SETTINGS", "QUIT TO TITLE"])
	check(scene._modal_open(), "clicks don't reach the scene")
	check(scene.get_tree().paused, "the scene freezes while the menu is up")
	var menu: PauseMenu = scene.get_node("PauseMenu")
	menu.open_settings()
	menu.get_node("SettingsOverlay").go_back()
	check(not menu.has_node("SettingsOverlay"), "settings closes back to the menu")
	check(scene.has_node("PauseMenu"))
	menu.ask_quit()
	check(menu.is_asking_quit(), "quitting asks first")
	var quit_labels: Array = menu.find_children("*", "Button", true, false).map(func(b): return b.text)
	check_eq(quit_labels, ["CANCEL", "QUIT"])
	menu.show_buttons()
	check(not menu.is_asking_quit(), "cancel goes back to the menu")
	menu.close()
	check(not scene._modal_open(), "resume closes the menu")
	check(not scene.get_tree().paused, "and everything carries on")


func test_calendar_marks_special_events() -> void:
	GameState.new_game("Gee")
	var club_fair := CalendarView.special_events(5)   # week 1, Friday
	check_eq(club_fair.map(func(e): return e["id"]), ["club_fair"])
	check(CalendarView.special_events(1).is_empty(), "an ordinary Tuesday")
	check_eq(CalendarView._events_on(0).map(func(e): return e["id"]), ["orientation", "orientation_night"],
		"orientation day lists no weekly events:")
	check(CalendarView._events_on(7).any(func(e): return e["id"] == "gardening_club"),
		"the next Sunday does")
	check(not CalendarView.special_events(28).any(func(e): return e["id"] == "polyglot_rivalry"),
		"hidden route events stay hidden")
	Router.params = {"date_id": "orientation", "event_id": "orientation"}
	var scene := add_node(load(Router.DATE).instantiate())
	scene.get_node("%CalendarButton").pressed.emit()
	var calendar: CalendarView = scene.get_node("CalendarOverlay")
	check(calendar != null and scene._modal_open(), "the calendar opens over the scene")
	check_eq(calendar._title.text, "SEPTEMBER 2030")
	check(_texts(calendar._grid.get_node("Day6")).has("Club fair"), "Sep 6 shows the club fair")
	calendar.show_month(1)
	check_eq(calendar._title.text, "OCTOBER 2030")
	calendar.show_month(-1)
	calendar.show_month(-1)
	check_eq(calendar._title.text, "SEPTEMBER 2030", "no months before the semester")
	calendar.close()
	check(not scene.has_node("CalendarOverlay"))


func test_jay_looks_different_at_night() -> void:
	GameState.new_game("Gee")
	check_eq(Looks.speaker_look("javascript", "day")["language"], "TypeScript")
	check_eq(Looks.speaker_look("javascript", "night")["language"], "JavaScript")
	check_eq(Looks.speaker_look("javascript", "night")["banner_color"], "#f3e15a")
	check_eq(Looks.speaker_look("player")["name"], "Gee")
	check(Looks.speaker_look("narrator").is_empty(), "the narrator has no look")


func test_code_challenge_with_fake_runner() -> void:
	var overlay = load("res://scenes/code_challenge.tscn").instantiate()
	var runner := FakeCodeRunner.new()
	runner.responder = func(_src, _stdin): return RunResult.make(RunResult.Status.OK, "Hello, world!")
	overlay.setup(GameData.get_challenge("g01_python"), GameData.get_character("python"), runner)
	add_node(overlay)
	var results: Array = []
	overlay.finished.connect(func(passed): results.append(passed))
	await overlay._on_run()
	check(overlay.get_node("%ContinueButton").visible, "continue should appear after passing")
	overlay.get_node("%ContinueButton").pressed.emit()
	check_eq(results, [true])


func test_hints_are_revealed_one_at_a_time() -> void:
	var overlay = load("res://scenes/code_challenge.tscn").instantiate()
	overlay.setup(GameData.get_challenge("g01_python"), GameData.get_character("python"), FakeCodeRunner.new())
	add_node(overlay)
	var button: Button = overlay.get_node("%HintButton")
	var label: Label = overlay.get_node("%HintLabel")
	var reward: Label = overlay.get_node("%RewardLabel")
	check(not label.visible, "no hints shown at first")
	check(reward.text.contains("+6"), "reward starts at +6: " + reward.text)
	button.pressed.emit()
	check_eq(overlay.hints_used, 1)
	check(label.visible and label.text.contains("hint 1") and not label.text.contains("hint 2"), "only hint 1 shown: " + label.text)
	check(reward.text.contains("+4"), "reward drops to +4: " + reward.text)
	button.pressed.emit()
	check_eq(overlay.hints_used, 2)
	check(label.text.contains("hint 2"), "hint 2 shown")
	check(button.disabled, "no third hint")
	check(reward.text.contains("+2"), "reward drops to +2: " + reward.text)
	button.pressed.emit()
	check_eq(overlay.hints_used, 2)


func test_hints_carry_over_to_a_retry() -> void:
	var overlay = load("res://scenes/code_challenge.tscn").instantiate()
	overlay.setup(GameData.get_challenge("g01_python"), {}, FakeCodeRunner.new(), 1)
	add_node(overlay)
	check(overlay.get_node("%HintLabel").text.contains("hint 1"), "hint 1 stays revealed")
	check(overlay.get_node("%RewardLabel").text.contains("+4"), "reward stays at +4")


func test_new_game_opens_with_orientation() -> void:
	var menu_script: GDScript = load("res://scripts/ui/main_menu.gd")
	check(not GameData.get_date(menu_script.OPENING_SCENE).is_empty(), "the opening scene exists")
	var event: Dictionary = GameData.calendar["events"].filter(func(e): return e["id"] == menu_script.OPENING_EVENT)[0]
	check(event.get("takes_no_time", false), "watching it takes no time")
	GameState.new_game("Gee")
	var scene := add_node(load(Router.MAP).instantiate())
	check_eq(scene.selected_item.get("dialogue"), "orientation",
		"if the player leaves it early, the map offers it first")
	check_eq(scene.get_node("%StartButton").text, "Watch scene")


func test_menu_freezes_the_scene() -> void:
	GameState.new_game("Gee")
	Router.params = {"date_id": "orientation", "event_id": "orientation"}
	var scene := add_node(load(Router.DATE).instantiate())
	var text: RichTextLabel = scene.text_label
	scene.open_menu()
	var typed := text.visible_ratio
	await scene.get_tree().create_timer(0.3, true).timeout
	check_eq(text.visible_ratio, typed, "the text stops typing")
	scene.get_node("PauseMenu").close()
	await scene.get_tree().create_timer(0.3).timeout
	check(text.visible_ratio > typed, "and carries on after Resume")


func test_map_menu_is_the_pause_menu() -> void:
	GameState.new_game("Gee")
	var scene := add_node(load(Router.MAP).instantiate())
	scene.get_node("%MenuButton").pressed.emit()
	var menu: PauseMenu = scene.get_node_or_null("PauseMenu")
	check(menu != null, "the menu opens over the map")
	var labels: Array = menu.find_children("*", "Button", true, false).map(func(b): return b.text)
	check_eq(labels, ["RESUME", "SETTINGS", "QUIT TO TITLE"])
	menu.close()
	check(not scene.has_node("PauseMenu"))


func test_campus_tour_on_the_map() -> void:
	GameState.new_game("Gee")
	GameState.mark_date_complete("orientation")
	var scene := add_node(load(Router.MAP).instantiate())
	var view: CampusMapView = scene.get_node("%MapView")
	var quack: Control = scene.get_node("QuackBox")
	var next: Button = quack.find_child("QuackNext", true, false)
	check_eq(scene.get_node("%Hud")._time_label.text, "WEEK 1/14  ·  SUNDAY", "shows the week and day:")
	check(quack.visible, "Quack talks during the tour")
	check(not scene.get_node("%WaitButton").visible, "no waiting during the tour")
	check(not scene.has_node("AffectionStrip"), "no affection bars on the map")
	# Stop 1: the quad. Its rooms are listed, every other building is locked.
	check_eq(scene.selected_building, "main_quad_area")
	check_eq(scene.selected_location, "", "the room list is showing")
	check(not view.get_tile("main_quad_area").locked, "the quad can be picked")
	check(view.get_tile("gardens").locked and view.get_tile("turing").locked, "the others are locked")
	view.building_selected.emit("turing")
	check_eq(scene.selected_building, "main_quad_area", "a locked building can't be picked")
	check_eq(view.get_tile("knuth_hall").people_count(), 0, "Ciel isn't in yet")
	while next.text != "NEXT STOP":
		next.pressed.emit()
	next.pressed.emit()
	# Stop 2: the gardens, with Monty in the greenhouse.
	check_eq(scene.selected_building, "gardens", "Quack moves on")
	check(view.get_tile("main_quad_area").locked, "the quad is locked now")
	for i in GameData.tour["stops"][1]["lines"].size():
		next.pressed.emit()
	check(not next.visible, "Quack waits for you to go in")
	check(quack.find_child("QuackText", true, false).text.contains("Greenhouse"), "and points at the room")
	check(_texts(scene.get_node("%PlaceBody").get_node("greenhouse")).has("GO IN"), "the room is marked")
	scene.get_node("%PlaceBody").get_node("greenhouse").pressed.emit()
	check_eq(scene.selected_item.get("dialogue"), "g01_python", "Monty's lesson is ready")
	# The lesson is done: back on the map, Quack is at the next stop.
	GameState.complete_lesson("g01_python", "python", 0)
	scene = add_node(load(Router.MAP).instantiate())
	check_eq(scene.selected_building, "babbage", "on to the dorm")


func test_whole_tour_ends_with_ciel_after_dark() -> void:
	GameState.new_game("Gee")
	GameState.mark_date_complete("orientation")
	var lessons := {"python": "g01_python", "javascript": "g01_typescript", "java": "g01_java", "cpp": "g01_cpp"}
	var visited: Array[String] = []
	for i in 30:
		if not Tour.is_on():
			break
		var stop := Tour.current_stop()
		if stop.has("character"):
			Tour.catch_up_time()
			check(not Calendar.opportunity_for(stop["character"]).is_empty(), "%s is there" % stop["character"])
			GameState.complete_lesson(lessons[stop["character"]], stop["character"], 0)
		else:
			Tour.next()
		if not stop.is_empty():
			visited.append(stop["building"])
		Tour.catch_up_time()
	check_eq(visited, ["main_quad_area", "gardens", "babbage", "commons", "student_union", "turing", "oracle_hall",
		"library", "knuth_hall"], "the stops in order:")
	check(not Tour.is_on(), "the tour is over")
	check_eq([GameState.week, GameState.day, GameState.slot], [1, 0, "night"], "it's Sunday night:")
	check(Tour.can_pick("athletics"), "every building is open again")


func test_affection_summary_opens_from_the_map() -> void:
	GameState.new_game("Gee")
	GameState.mark_date_complete("orientation")
	GameState.complete_lesson("g01_python", "python", 0)
	var scene := add_node(load(Router.MAP).instantiate())
	scene.get_node("%AffectionButton").pressed.emit()
	var view: AffectionView = scene.get_node("AffectionOverlay")
	check(view != null, "the summary opens")
	for id in ["python", "javascript", "java", "cpp"]:
		check(view.find_child(id, true, false) != null, "%s has a row" % id)
	check(view.find_child("python", true, false).find_child("Score", true, false).text.contains("6 / 100"),
		"Monty's lesson counts")
	check(view.find_child("Balance", true, false).text.contains("DAY 0 · NIGHT 0"), "Jay's balance is shown")
	scene.open_menu()
	check(not scene.has_node("PauseMenu"), "the menu waits until the summary closes")
	view.find_child("CloseButton", true, false).pressed.emit()
	check(not scene.has_node("AffectionOverlay"), "it closes")


func test_waiting_moves_time_and_people_move_around() -> void:
	GameState.new_game("Gee")
	var scene := add_node(load(Router.MAP).instantiate())
	check(not scene.get_node("%WaitButton").visible, "the tour comes first")
	GameState.set_flag(Tour.DONE_FLAG)
	scene.refresh()
	check(scene.get_node("%WaitButton").visible, "after the tour, time can move on")
	scene.get_node("%WaitButton").pressed.emit()   # Sunday night
	check_eq(GameState.slot, "night")
	var view: CampusMapView = scene.get_node("%MapView")
	for building in GameData.buildings:
		check_eq(view.get_tile(building["id"]).people_count(), 1 if building["id"] == "knuth_hall" else 0,
			"orientation night: only Ciel, at %s:" % building["id"])
	GameState.day = 6   # skip ahead to Saturday night
	scene.refresh()
	check(view.get_tile("student_union").people_count() > 0, "Jay's hackathon night")
	check_eq(view.get_tile("oracle_hall").people_count(), 1, "Julian's council office hours")
	view.get_tile("oracle_hall").pressed.emit()
	check_eq(scene.selected_building, "oracle_hall")
	check_eq(scene.selected_location, "", "the panel lists the rooms")
	check(view.get_tile("oracle_hall").selected, "the building lights up")
	var body: Node = scene.get_node("%PlaceBody")
	for room in GameData.rooms_in("oracle_hall"):
		check(body.has_node(room), "%s is listed" % room)
	body.get_node("council_room").pressed.emit()
	check_eq(scene.selected_location, "council_room")
	body = scene.get_node("%PlaceBody")
	check(body.has_node("java") and not body.has_node("javascript"), "only Julian is here")


func test_empty_room_shows_its_description_and_goes_back() -> void:
	GameState.new_game("Gee")
	GameState.mark_date_complete("orientation")
	GameState.set_flag(Tour.DONE_FLAG)
	var scene := add_node(load(Router.MAP).instantiate())
	scene.get_node("%MapView").get_tile("athletics").pressed.emit()
	scene.get_node("%PlaceBody").get_node("pool").pressed.emit()
	check_eq(scene.selected_location, "pool")
	check_eq(scene.get_node("%PlaceBlurb").text, GameData.locations["pool"]["blurb"], "the walk-in text")
	check(scene.selected_item.is_empty(), "nothing to start in a flavor room")
	var start: Button = scene.get_node("%StartButton")
	check_eq(start.text, "Back to map")
	start.pressed.emit()
	check_eq(scene.selected_location, "", "back to the building's rooms")
	check(scene.get_node("%PlaceBody").has_node("pool"), "the room list is back")


func test_locked_chapters_are_not_listed() -> void:
	GameState.new_game("Gee")
	GameState.mark_date_complete("orientation")
	var items := CampusMap.place_items({"characters": ["python"], "scenes": []})
	check_eq(items.map(func(i): return i["dialogue"]), ["g01_python"], "only the open lesson, no locked chapter 1:")
	GameState.new_game("Gee")
