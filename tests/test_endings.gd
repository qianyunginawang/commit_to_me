extends TestCase
## Ending rules (scripts/progress/endings.gd) and the endings screen.

const GameStateScript := preload("res://scripts/autoload/game_state.gd")
const GameDataScript := preload("res://scripts/autoload/game_data.gd")

var _nodes: Array[Node] = []


func cleanup() -> void:
	super()
	for n in _nodes:
		if is_instance_valid(n):
			n.free()


func _state(affection: Dictionary = {}) -> Node:
	var gs: Node = GameStateScript.new()
	gs.save_path = "user://test_save.json"
	for id in affection:
		gs.affection[id] = affection[id]
	_nodes.append(gs)
	return gs


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


func test_good_needs_80_and_the_final() -> void:
	var gd := _data()
	var gs := _state({"python": 85})
	check_eq(Endings.ending_kind("python", gs, gd), "normal", "80+ without the final:")
	gs.mark_date_complete("test_python_ch6")
	check_eq(Endings.ending_kind("python", gs, gd), "good")
	check_eq(Endings.ending_for("python", gs, gd).get("id"), "python_ending_good")


func test_normal_and_bad_thresholds() -> void:
	var gd := _data()
	check_eq(Endings.ending_kind("cpp", _state({"cpp": 50}), gd), "normal")
	check_eq(Endings.ending_kind("cpp", _state({"cpp": 49}), gd), "bad")
	check_eq(Endings.ending_for("java", _state({"java": 10}), gd).get("title"), "Bad ending: NullPointerException")


func test_jay_needs_balance_for_good() -> void:
	var gd := _data()
	var gs := _state({"javascript": 90})
	gs.mark_date_complete("test_javascript_ch7")   # dusk: day 1, night 1
	check_eq(Endings.ending_kind("javascript", gs, gd), "good")
	for ch in [1, 3, 5]:                            # three night chapters
		gs.mark_date_complete("test_javascript_ch%d" % ch)
	check_eq(Endings.ending_kind("javascript", gs, gd), "normal_night", "out of balance:")


func test_jay_normal_follows_the_bigger_side() -> void:
	var gd := _data()
	var gs := _state({"javascript": 60})
	check_eq(Endings.ending_kind("javascript", gs, gd), "normal_day", "tie goes to day:")
	gs.mark_date_complete("test_javascript_ch1")   # night
	check_eq(Endings.ending_kind("javascript", gs, gd), "normal_night")


func test_ending_choice_and_result_screens() -> void:
	GameState.new_game("Gee")
	var tie := add_node(load(Router.ENDINGS).instantiate())
	check_eq(tie.get_node("%Choices").get_child_count(), 4, "all tied at 0, so the player picks")
	GameState.affection = {"python": 40, "cpp": 70}
	var top := add_node(load(Router.ENDINGS).instantiate())
	check_eq(top.get_node("%Choices").get_child_count(), 1, "highest affection wins")
	check(top.get_node("%Choices").has_node("cpp"), "Ciel has the most affection")
	GameState.ending_id = "cpp_ending_bad"
	var result := add_node(load(Router.ENDINGS).instantiate())
	check_eq(result.get_node("%TitleLabel").text, "Bad ending: Segmentation fault")
	GameState.new_game("Gee")


func test_ending_is_saved() -> void:
	var gs := _state()
	gs.ending_id = "java_ending_good"
	var copy := _state()
	copy.from_dict(gs.to_dict())
	check_eq(copy.ending_id, "java_ending_good")


func test_route_goes_to_highest_affection() -> void:
	check_eq(Endings.route_characters(_state({"python": 30, "java": 55, "cpp": 10})), ["java"] as Array[String])
	check_eq(Endings.route_characters(_state({"python": 55, "java": 55})), ["python", "java"] as Array[String])
