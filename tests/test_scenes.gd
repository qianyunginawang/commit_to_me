extends TestCase
## Smoke tests: every screen loads and sets itself up without errors.


func test_main_menu_loads() -> void:
	var scene := add_node(load(Router.MAIN_MENU).instantiate())
	check(scene.get_node("%NewGameButton") != null)


func test_hub_shows_four_cards() -> void:
	var scene := add_node(load(Router.HUB).instantiate())
	check_eq(scene.get_node("%Cards").get_child_count(), 4)


func test_date_scene_starts_dialogue() -> void:
	Router.params = {"date_id": "python_date_1"}
	var scene := add_node(load(Router.DATE).instantiate())
	check_eq(scene.player.current_id, "intro")
	check(scene.get_node("%TextLabel").text.contains("coffee"), "first line should be shown")


func test_code_challenge_with_fake_runner() -> void:
	var overlay = load("res://scenes/code_challenge.tscn").instantiate()
	var runner := FakeCodeRunner.new()
	runner.responder = func(_src, stdin): return RunResult.make(RunResult.Status.OK, "Hi Monty, I'm %s!" % stdin.strip_edges())
	overlay.setup(GameData.get_challenge("python_hello"), GameData.get_character("python"), runner)
	add_node(overlay)
	var results: Array = []
	overlay.finished.connect(func(passed): results.append(passed))
	await overlay._on_run()
	check(overlay.get_node("%ContinueButton").visible, "continue should appear after passing")
	overlay.get_node("%ContinueButton").pressed.emit()
	check_eq(results, [true])
