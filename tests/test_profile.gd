extends TestCase
## The replay profile (scripts/autoload/profile.gd).

const ProfileScript := preload("res://scripts/autoload/profile.gd")

var _nodes: Array[Node] = []


func cleanup() -> void:
	super()
	for n in _nodes:
		if is_instance_valid(n):
			n.free()
	DirAccess.remove_absolute("user://test_profile.json")


func _profile() -> Node:
	var p: Node = ProfileScript.new()
	p.profile_path = "user://test_profile.json"
	_nodes.append(p)
	return p


func test_nothing_unlocked_at_first() -> void:
	var p := _profile()
	check(not p.is_polyglot_unlocked(), "no Polyglot yet")
	check(not p.is_secret_route_unlocked(), "no Ferris yet")
	check_eq(p.ending_count(), {"seen": 0, "total": 15})


func test_one_good_ending_unlocks_polyglot() -> void:
	var p := _profile()
	p.record_ending("python_ending_normal")
	check(not p.is_polyglot_unlocked(), "a normal ending isn't enough")
	p.record_ending("python_ending_good")
	check(p.is_polyglot_unlocked(), "a good ending unlocks Polyglot")
	check(not p.is_secret_route_unlocked(), "Ferris needs all four")


func test_all_four_good_endings_unlock_ferris() -> void:
	var p := _profile()
	for id in ["python", "javascript", "java", "cpp"]:
		p.record_ending("%s_ending_good" % id)
	check(p.is_secret_route_unlocked(), "all four good endings seen")


func test_endings_are_counted_once_and_saved() -> void:
	var p := _profile()
	p.record_ending("cpp_ending_bad")
	p.record_ending("cpp_ending_bad")
	check_eq(p.ending_count()["seen"], 1)
	var again := _profile()
	again.load_profile()
	check(again.has_seen("cpp_ending_bad"), "loaded from disk")


func test_new_game_keeps_the_profile() -> void:
	var p := _profile()
	p.record_ending("java_ending_good")
	GameState.new_game("Gee")
	check(p.has_seen("java_ending_good"), "a new game doesn't clear endings seen")
