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
