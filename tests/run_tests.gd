extends SceneTree
## Runs every tests/test_*.gd file and exits with code 1 if anything failed.
##
##   godot --headless --path . --import          # first time only
##   godot --headless --path . -s tests/run_tests.gd
##
## Each test file extends TestCase and has methods named test_something().

const TESTS_DIR := "res://tests"
## Tests save here instead of the player's real saves and settings.
const TEST_SAVES := "user://test_saves"
const TEST_SETTINGS := "user://test_settings.cfg"


func _initialize() -> void:
	_run_all()


func _run_all() -> void:
	# Wait one frame so autoloads (GameData, GameState...) finish _ready().
	await process_frame
	_clear_test_files()
	var game_state := root.get_node("/root/GameState")
	game_state.saves_dir = TEST_SAVES
	root.get_node("/root/Settings").settings_path = TEST_SETTINGS
	var total := 0
	var failed := 0
	var files := DirAccess.get_files_at(TESTS_DIR)
	for file in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")) or file == "test_case.gd":
			continue
		# A file that doesn't compile loads as a script with no methods, so its
		# tests would silently not run. Count it as a failure instead.
		var script: GDScript = load(TESTS_DIR.path_join(file))
		if script == null or not script.can_instantiate():
			total += 1
			failed += 1
			print("  FAIL  %s doesn't compile (see the error above)" % file)
			continue
		var ran := 0
		for method in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			var test: TestCase = script.new()
			test.tree = self
			game_state.save_path = ""
			total += 1
			ran += 1
			await test.call(method_name)
			test.cleanup()
			if test.failures.is_empty():
				print("  PASS  %s.%s%s" % [file.get_basename(), method_name, test.note])
			else:
				failed += 1
				print("  FAIL  %s.%s" % [file.get_basename(), method_name])
				for f in test.failures:
					print("          - " + f)
		if ran == 0:
			total += 1
			failed += 1
			print("  FAIL  %s has no test_ methods" % file)
	_clear_test_files()
	print("\n%d tests, %d failed" % [total, failed])
	quit(1 if failed > 0 else 0)


func _clear_test_files() -> void:
	DirAccess.remove_absolute(TEST_SETTINGS)
	if not DirAccess.dir_exists_absolute(TEST_SAVES):
		return
	for file in DirAccess.get_files_at(TEST_SAVES):
		DirAccess.remove_absolute(TEST_SAVES.path_join(file))
	DirAccess.remove_absolute(TEST_SAVES)
