class_name CodeRunner
extends RefCounted
## Base class for anything that can run a player's code.
##
## The game only talks to this interface, so the way code actually gets run
## (local process, bundled runtime, a web service, a fake for tests) can be
## swapped without touching any UI or dialogue code.
##
## Usage (run() is async, so always await it):
##     var result: RunResult = await runner.run(source_code, "input text\n")

## Max wall-clock time for the player's program, in milliseconds.
var timeout_ms: int = 5000


## Runs [param source] with [param stdin_text] fed to standard input.
## Subclasses must override this.
func run(_source: String, _stdin_text: String = "") -> RunResult:
	push_error("CodeRunner.run() is not implemented by %s" % get_script().resource_path)
	return RunResult.make(RunResult.Status.INTERNAL_ERROR, "", "Runner not implemented")


## Returns true if this runner can actually run code right now
## (e.g. the interpreter exists). Used to show a friendly message early.
func is_available() -> bool:
	return false


## Human readable reason why is_available() is false.
func unavailable_reason() -> String:
	return ""
