extends TestCase
## Runs real code with whatever runtimes are available (bundled or installed).
## Tests for languages that aren't available are skipped, not failed.

const SOLUTIONS_DIR := "res://tests/solutions"


func test_every_challenge_starter_fails_and_solution_passes() -> void:
	var skipped: PackedStringArray = []
	for id in GameData.challenges:
		var challenge: Dictionary = GameData.get_challenge(id)
		var runner := GameData.make_runner(challenge["language"])
		if not runner.is_available():
			skipped.append(challenge["language"])
			continue
		var solution := _find_solution(id)
		check(solution != "", "no reference solution for %s in %s" % [id, SOLUTIONS_DIR])
		if solution == "":
			continue

		var good: Dictionary = await ChallengeGrader.grade(runner, solution, challenge)
		check(good["passed"], "%s: reference solution failed: %s" % [id, _why(good)])
		var starter: Dictionary = await ChallengeGrader.grade(runner, challenge.get("starter_code", ""), challenge)
		check(not starter["passed"], "%s: starter code should NOT pass on its own" % id)
	if not skipped.is_empty():
		skip("no runtime for " + ", ".join(skipped))


func test_timeout_stops_infinite_loop() -> void:
	var runner := GameData.make_runner("python")
	if not runner.is_available():
		skip("no python")
		return
	runner.timeout_ms = 1000
	var result: RunResult = await runner.run("while True:\n    pass\n")
	check_eq(result.status_name(), "TIMEOUT")


func test_runtime_error_reports_stderr() -> void:
	var runner := GameData.make_runner("python")
	if not runner.is_available():
		skip("no python")
		return
	var result: RunResult = await runner.run("raise ValueError('oops')\n")
	check_eq(result.status_name(), "RUNTIME_ERROR")
	check(result.stderr.contains("ValueError"), "stderr should contain the error, got: " + result.stderr)
	check(not result.stderr.contains("commit_to_me/"), "temp folder path should be hidden from players")


func test_compile_error() -> void:
	var runner := GameData.make_runner("cpp")
	if not runner.is_available():
		skip("no C++ compiler")
		return
	var result: RunResult = await runner.run("int main() { return oops; }\n")
	check_eq(result.status_name(), "COMPILE_ERROR")
	check(result.stderr.contains("oops"), "compiler message should be shown")


func test_missing_runtime_is_reported() -> void:
	var runner := ProcessCodeRunner.new("klingon", {
		"source_file": "main.kl",
		"run": {"system": "definitely-not-a-real-compiler", "args": ["{file}"]},
	})
	check(not runner.is_available(), "fake runtime should not be available")
	var result: RunResult = await runner.run("Qapla'")
	check_eq(result.status_name(), "RUNTIME_MISSING")


func _find_solution(challenge_id: String) -> String:
	for file in DirAccess.get_files_at(SOLUTIONS_DIR):
		if file.get_basename() == challenge_id:
			return FileAccess.get_file_as_string(SOLUTIONS_DIR.path_join(file))
	return ""


func _why(report: Dictionary) -> String:
	var f: Dictionary = report["first_failure"]
	if f.is_empty():
		return ""
	var r: RunResult = f["result"]
	return "%s expected=%s actual=%s stderr=%s" % [r.status_name(), f["expected"], f["actual"], r.stderr]
