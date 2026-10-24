class_name ChallengeGrader
extends RefCounted
## Checks a player's code against a challenge's test cases.
##
## A challenge (see res://data/challenges/) has a list of tests like:
##     {"stdin": "Gee\n", "expected_stdout": "Hi Gee!"}
## The player passes when every test's output matches.


## Runs every test and returns:
##   {
##     "passed": bool,
##     "tests": [ {"passed": bool, "stdin": String, "expected": String,
##                 "actual": String, "result": RunResult}, ... ],
##     "first_failure": Dictionary   # empty if everything passed
##   }
static func grade(runner: CodeRunner, source: String, challenge: Dictionary) -> Dictionary:
	var report := {"passed": true, "tests": [], "first_failure": {}}
	var tests: Array = challenge.get("tests", [])
	if tests.is_empty():
		tests = [{"stdin": "", "expected_stdout": ""}]

	for t in tests:
		var stdin_text: String = t.get("stdin", "")
		var expected: String = t.get("expected_stdout", "")
		var result: RunResult = await runner.run(source, stdin_text)
		var ok := result.is_success() and outputs_match(expected, result.stdout)
		var entry := {
			"passed": ok,
			"stdin": stdin_text,
			"expected": normalize(expected),
			"actual": normalize(result.stdout),
			"result": result,
		}
		report["tests"].append(entry)
		if not ok:
			report["passed"] = false
			if report["first_failure"].is_empty():
				report["first_failure"] = entry
			# Infra problems (missing runtime, compile error) fail every test
			# the same way, so don't bother running the rest.
			if result.status in [RunResult.Status.RUNTIME_MISSING, RunResult.Status.COMPILE_ERROR, RunResult.Status.INTERNAL_ERROR]:
				break
	return report


static func outputs_match(expected: String, actual: String) -> bool:
	return normalize(expected) == normalize(actual)


## Makes output comparison forgiving about invisible differences:
## Windows line endings, trailing spaces, and trailing blank lines.
static func normalize(text: String) -> String:
	var lines := text.replace("\r\n", "\n").replace("\r", "\n").split("\n")
	var cleaned: PackedStringArray = []
	for line in lines:
		cleaned.append(line.strip_edges(false, true))
	return "\n".join(cleaned).strip_edges(false, true)
