class_name RunResult
extends RefCounted
## The outcome of running a player's code once.

enum Status {
	OK,               ## Program ran and exited (check exit_code for success).
	COMPILE_ERROR,    ## Compiler rejected the code (C++, Java).
	RUNTIME_ERROR,    ## Program crashed or exited with a non-zero code.
	TIMEOUT,          ## Program took too long and was stopped.
	OUTPUT_LIMIT,     ## Program printed too much and was stopped.
	RUNTIME_MISSING,  ## No interpreter/compiler found for this language.
	INTERNAL_ERROR,   ## Something went wrong on the game's side.
}

var status: Status = Status.OK
var stdout: String = ""
var stderr: String = ""
var exit_code: int = 0
var duration_ms: int = 0


static func make(p_status: Status, p_stdout := "", p_stderr := "", p_exit_code := 0) -> RunResult:
	var r := RunResult.new()
	r.status = p_status
	r.stdout = p_stdout
	r.stderr = p_stderr
	r.exit_code = p_exit_code
	return r


func is_success() -> bool:
	return status == Status.OK and exit_code == 0


func status_name() -> String:
	return Status.keys()[status]


## A short, player-facing explanation of what happened.
func describe() -> String:
	match status:
		Status.OK:
			return "Ran successfully." if exit_code == 0 else "Program exited with code %d." % exit_code
		Status.COMPILE_ERROR:
			return "Compile error."
		Status.RUNTIME_ERROR:
			return "Your program crashed (exit code %d)." % exit_code
		Status.TIMEOUT:
			return "Time limit reached. Is there an infinite loop?"
		Status.OUTPUT_LIMIT:
			return "Your program printed way too much output, so it was stopped."
		Status.RUNTIME_MISSING:
			return "This language's runtime isn't installed yet."
		_:
			return "Something went wrong running your code."
