class_name ProcessCodeRunner
extends CodeRunner
## Runs player code as a separate process on this computer.
##
## For each run it:
##   1. makes a fresh temp folder (the "sandbox"),
##   2. writes the player's code into it,
##   3. compiles it if the language needs that (C++, Java),
##   4. runs it with a time limit and an output limit,
##   5. deletes the temp folder.
##
## Which programs it calls comes from res://data/languages.json.
## It prefers the runtime bundled with the game (runtimes/<platform>/...,
## downloaded by tools/fetch_runtimes.py). In debug builds (running from the
## editor) it falls back to whatever is installed on the computer, so you can
## develop without bundling anything.
##
## NOTE: this is "sandboxed" only in the sense of a throwaway folder plus
## limits. It is NOT a security sandbox. That's fine for a single-player game
## where you only run your own code, but don't run untrusted code with it.

const RUNTIMES_DIR_NAME := "runtimes"

var language_id: String
## One entry from languages.json.
var config: Dictionary
## Max time for the compile step, in milliseconds (compilers are slow to start).
var compile_timeout_ms: int = 20000
## Stop the program if stdout + stderr gets bigger than this.
var max_output_bytes: int = 64 * 1024
## Set false to never use runtimes installed on the computer.
var allow_system_fallback: bool = OS.is_debug_build()
## Keep the temp folder after running (useful for debugging the runner).
var keep_sandbox: bool = false


func _init(p_language_id: String = "", p_config: Dictionary = {}) -> void:
	language_id = p_language_id
	config = p_config
	compile_timeout_ms = int(config.get("compile_timeout_ms", compile_timeout_ms))


## True if every program this language needs comes from the game's own
## runtimes folder (not from something installed on the computer).
func uses_bundled_runtime() -> bool:
	if config.is_empty():
		return false
	for step in ["compile", "run"]:
		if not config.has(step):
			continue
		var step_cfg: Dictionary = config[step]
		if step_cfg.get("program", "") == "{exe}":
			continue
		if _bundled_path(step_cfg).is_empty():
			return false
	return true


func is_available() -> bool:
	if config.is_empty():
		return false
	for step in ["compile", "run"]:
		if config.has(step) and _resolve_program(config[step]).is_empty():
			return false
	return true


func unavailable_reason() -> String:
	if config.is_empty():
		return "No settings for language '%s' in languages.json." % language_id
	for step in ["compile", "run"]:
		if config.has(step) and _resolve_program(config[step]).is_empty():
			var step_cfg: Dictionary = config[step]
			return "Couldn't find %s. Run tools/fetch_runtimes.py to put it in %s, or install '%s' on this computer (see runtimes/README.md)." % [
				config.get("display_name", language_id),
				runtimes_dir(),
				step_cfg.get("system", "?"),
			]
	return ""


func run(source: String, stdin_text: String = "") -> RunResult:
	if not is_available():
		return RunResult.make(RunResult.Status.RUNTIME_MISSING, "", unavailable_reason())

	var sandbox := _make_sandbox()
	if sandbox.is_empty():
		return RunResult.make(RunResult.Status.INTERNAL_ERROR, "", "Couldn't create a temp folder.")

	var source_path := sandbox.path_join(config.get("source_file", "main.txt"))
	var f := FileAccess.open(source_path, FileAccess.WRITE)
	if f == null:
		_cleanup(sandbox)
		return RunResult.make(RunResult.Status.INTERNAL_ERROR, "", "Couldn't write code file: %s" % error_string(FileAccess.get_open_error()))
	f.store_string(source)
	f.close()

	var vars := {
		"file": source_path,
		"dir": sandbox,
		"exe": sandbox.path_join("main.exe" if OS.get_name() == "Windows" else "main"),
	}
	var started := Time.get_ticks_msec()
	var result: RunResult

	if config.has("compile"):
		var compile: RunResult = await _run_step(config["compile"], vars, "", compile_timeout_ms)
		if not compile.is_success():
			if compile.status in [RunResult.Status.OK, RunResult.Status.RUNTIME_ERROR]:
				compile.status = RunResult.Status.COMPILE_ERROR
			# Compilers sometimes write errors to stdout; show both.
			compile.stderr = (compile.stdout + "\n" + compile.stderr).strip_edges()
			compile.stdout = ""
			result = compile

	if result == null:
		result = await _run_step(config["run"], vars, stdin_text, timeout_ms)
		if result.status == RunResult.Status.OK and result.exit_code != 0:
			result.status = RunResult.Status.RUNTIME_ERROR

	result.duration_ms = Time.get_ticks_msec() - started
	result.stderr = _scrub_paths(result.stderr, sandbox)
	if not keep_sandbox:
		_cleanup(sandbox)
	return result


# --- Locating runtimes -------------------------------------------------------

## "windows", "macos" or "linux". The "bundled" paths in languages.json are
## keyed by this.
static func os_key() -> String:
	match OS.get_name():
		"Windows":
			return "windows"
		"macOS":
			return "macos"
		_:
			return "linux"


## Name of the runtimes subfolder for this computer, e.g. "macos-arm64" or
## "windows-x86_64". Matches the platform names in tools/fetch_runtimes.py.
static func platform_key() -> String:
	var arch := Engine.get_architecture_name()
	if arch in ["arm64", "aarch64"]:
		arch = "arm64"
	return "%s-%s" % [os_key(), arch]


## Folder with the bundled runtimes for this platform.
##   - Editor: <project>/runtimes/<platform>
##   - Exported game: <game folder>/runtimes/<platform>, or on macOS also
##     MyGame.app/Contents/Resources/runtimes/<platform> (inside the app).
static func runtimes_dir() -> String:
	var bases: PackedStringArray = []
	if OS.has_feature("editor"):
		bases.append(ProjectSettings.globalize_path("res://"))
	else:
		var exe_dir := OS.get_executable_path().get_base_dir()
		bases.append(exe_dir)
		if OS.get_name() == "macOS":
			bases.append(exe_dir.path_join("../Resources").simplify_path())
			bases.append(exe_dir.path_join("../../..").simplify_path())  # next to the .app
	for base in bases:
		var dir := base.path_join(RUNTIMES_DIR_NAME).path_join(platform_key())
		if DirAccess.dir_exists_absolute(dir):
			return dir
	return bases[0].path_join(RUNTIMES_DIR_NAME).path_join(platform_key())


## Absolute path of the bundled program for a step, or "" if not bundled.
static func _bundled_path(step: Dictionary) -> String:
	var bundled = step.get("bundled", {})
	if bundled is Dictionary and bundled.has(os_key()):
		var path := runtimes_dir().path_join(bundled[os_key()])
		if FileAccess.file_exists(path):
			return path
	return ""


## Returns the absolute path of the program for a compile/run step,
## or "" if it can't be found.
func _resolve_program(step: Dictionary) -> String:
	var bundled := _bundled_path(step)
	if not bundled.is_empty():
		return bundled
	var program: String = step.get("program", "")
	if program == "{exe}":
		return program  # The compiled program; it exists once compiling worked.
	if allow_system_fallback and step.has("system"):
		return find_on_path(step["system"])
	return ""


## Looks for a command on the computer's PATH, like `which` does.
static func find_on_path(command: String) -> String:
	var is_windows := OS.get_name() == "Windows"
	var separator := ";" if is_windows else ":"
	var names: Array[String] = [command]
	if is_windows and command.get_extension() == "":
		names = [command + ".exe", command + ".cmd", command + ".bat"]
	for dir in OS.get_environment("PATH").split(separator, false):
		for n in names:
			var candidate := dir.path_join(n)
			if FileAccess.file_exists(candidate):
				return candidate
	return ""


# --- Running a single process ------------------------------------------------

func _run_step(step: Dictionary, vars: Dictionary, stdin_text: String, limit_ms: int) -> RunResult:
	var program := _resolve_program(step)
	if program == "{exe}":
		program = vars["exe"]
	# A bundled tool can need different arguments than the usual system one
	# (e.g. "zig c++ ..." instead of "g++ ...").
	var arg_list: Array = step.get("args", [])
	if step.has("bundled_args") and program == _bundled_path(step):
		arg_list = step["bundled_args"]
	var args: PackedStringArray = []
	for a in arg_list:
		args.append(String(a).format(vars))
	return await _exec(program, args, stdin_text, limit_ms)


func _exec(program: String, args: PackedStringArray, stdin_text: String, limit_ms: int) -> RunResult:
	var proc := OS.execute_with_pipe(program, args, false)
	if proc.is_empty():
		return RunResult.make(RunResult.Status.INTERNAL_ERROR, "", "Couldn't start %s" % program)

	var pid: int = proc["pid"]
	var stdio: FileAccess = proc["stdio"]
	var stderr_pipe: FileAccess = proc.get("stderr")
	if not stdin_text.is_empty():
		stdio.store_string(stdin_text)
		stdio.flush()

	var out := PackedByteArray()
	var err := PackedByteArray()
	var status := RunResult.Status.OK
	var started := Time.get_ticks_msec()
	var tree := Engine.get_main_loop() as SceneTree

	while true:
		var got := _drain(stdio, out) + _drain(stderr_pipe, err)
		if out.size() + err.size() > max_output_bytes:
			status = RunResult.Status.OUTPUT_LIMIT
			break
		if not OS.is_process_running(pid):
			if got == 0:
				break  # Exited and nothing left to read.
			continue
		if Time.get_ticks_msec() - started > limit_ms:
			status = RunResult.Status.TIMEOUT
			break
		if got == 0:
			# Let the game keep drawing frames while we wait.
			if tree:
				await tree.process_frame
			else:
				OS.delay_msec(5)

	var exit_code := 0
	if status == RunResult.Status.OK:
		exit_code = OS.get_process_exit_code(pid)
	else:
		OS.kill(pid)
	stdio.close()
	if stderr_pipe:
		stderr_pipe.close()

	return RunResult.make(status, out.get_string_from_utf8(), err.get_string_from_utf8(), exit_code)


static func _drain(pipe: FileAccess, into: PackedByteArray) -> int:
	if pipe == null:
		return 0
	var chunk := pipe.get_buffer(4096)
	into.append_array(chunk)
	return chunk.size()


# --- Temp folders ------------------------------------------------------------

func _make_sandbox() -> String:
	var dir := OS.get_temp_dir().path_join("commit_to_me").path_join(
		"%s_%d_%d" % [language_id, Time.get_ticks_usec(), randi() % 100000])
	if DirAccess.make_dir_recursive_absolute(dir) != OK:
		return ""
	return dir


## Removes the temp folder path from error messages so they read like
## "main.py, line 3" instead of a long, scary path.
static func _scrub_paths(text: String, sandbox: String) -> String:
	return text.replace(sandbox + "/", "").replace(sandbox + "\\", "").replace(sandbox, ".")


static func _cleanup(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	d.include_hidden = true
	for sub in d.get_directories():
		_cleanup(dir.path_join(sub))
	for file in d.get_files():
		d.remove(file)
	DirAccess.remove_absolute(dir)
