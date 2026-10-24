extends TestCase


func test_normalize_ignores_invisible_differences() -> void:
	check(ChallengeGrader.outputs_match("a\nb", "a  \r\nb\n\n"), "trailing spaces / CRLF / blank lines")
	check(not ChallengeGrader.outputs_match("a b", "a  b"), "spaces inside a line still matter")


func test_grade_with_fake_runner() -> void:
	var runner := FakeCodeRunner.new()
	runner.responder = func(_src, stdin): return RunResult.make(RunResult.Status.OK, "Hi " + stdin.strip_edges())
	var challenge := {"tests": [{"stdin": "A\n", "expected_stdout": "Hi A"}, {"stdin": "B\n", "expected_stdout": "Hi B"}]}
	var report: Dictionary = await ChallengeGrader.grade(runner, "code", challenge)
	check(report["passed"], "should pass")
	check_eq(runner.calls.size(), 2)

	challenge["tests"][0]["expected_stdout"] = "Bye A"
	challenge["tests"][1]["expected_stdout"] = "Bye B"
	report = await ChallengeGrader.grade(runner, "code", challenge)
	check(not report["passed"], "should fail")
	check_eq(report["first_failure"]["actual"], "Hi A", "first failure should be the first failing test:")


func test_runtime_missing_stops_early() -> void:
	var runner := FakeCodeRunner.new()
	runner.canned_result = RunResult.make(RunResult.Status.RUNTIME_MISSING)
	var challenge := {"tests": [{"expected_stdout": "x"}, {"expected_stdout": "y"}]}
	var report: Dictionary = await ChallengeGrader.grade(runner, "", challenge)
	check(not report["passed"])
	check_eq(runner.calls.size(), 1, "should stop after the first infra failure:")
