extends SceneTree
## Runs every tests/test_*.gd file and exits with code 1 if anything failed.
##
##   godot --headless --path . --import          # first time only
##   godot --headless --path . -s tests/run_tests.gd
##
## Each test file extends TestCase and has methods named test_something().

const TESTS_DIR := "res://tests"


func _initialize() -> void:
	_run_all()


func _run_all() -> void:
	# Wait one frame so autoloads (GameData, GameState...) finish _ready().
	await process_frame
	var total := 0
	var failed := 0
	var files := DirAccess.get_files_at(TESTS_DIR)
	for file in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		var script: GDScript = load(TESTS_DIR.path_join(file))
		for method in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			var test: TestCase = script.new()
			test.tree = self
			total += 1
			await test.call(method_name)
			test.cleanup()
			if test.failures.is_empty():
				print("  PASS  %s.%s%s" % [file.get_basename(), method_name, test.note])
			else:
				failed += 1
				print("  FAIL  %s.%s" % [file.get_basename(), method_name])
				for f in test.failures:
					print("          - " + f)
	print("\n%d tests, %d failed" % [total, failed])
	quit(1 if failed > 0 else 0)
