class_name FakeCodeRunner
extends CodeRunner
## A runner that doesn't run anything. It returns canned results.
## Handy for tests and for building UI without any runtimes installed.

## Result returned for every call when no responder is set.
var canned_result: RunResult = RunResult.make(RunResult.Status.OK, "")
## Optional Callable(source: String, stdin: String) -> RunResult.
var responder: Callable
var calls: Array[Dictionary] = []


func run(source: String, stdin_text: String = "") -> RunResult:
	calls.append({"source": source, "stdin": stdin_text})
	if responder.is_valid():
		return responder.call(source, stdin_text)
	return canned_result


func is_available() -> bool:
	return true
