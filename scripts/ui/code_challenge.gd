extends Control
## The coding mini-game shown during a date. Shows the task, a code editor,
## and runs the player's code against the challenge's tests.
##
## Emits finished(passed) when the player continues or gives up. Read
## hints_used afterwards to see how many of Quack's hints were revealed.

signal finished(passed: bool)

@onready var title_label: Label = %ChallengeTitle
@onready var language_label: Label = %LanguageLabel
@onready var prompt_label: RichTextLabel = %PromptLabel
@onready var hint_button: Button = %HintButton
@onready var hint_label: Label = %HintLabel
@onready var reward_label: Label = %RewardLabel
@onready var editor: CodeEdit = %Editor
@onready var run_button: Button = %RunButton
@onready var reset_button: Button = %ResetButton
@onready var give_up_button: Button = %GiveUpButton
@onready var continue_button: Button = %ContinueButton
@onready var status_label: Label = %StatusLabel
@onready var output_label: RichTextLabel = %OutputLabel

var challenge: Dictionary = {}
var character: Dictionary = {}
var runner: CodeRunner
## How many of the challenge's hints the player has revealed.
var hints_used := 0
## False when replaying a lesson that's already complete (no affection).
var first_time := true
var _hints: Array = []
var _passed := false


## Call before adding to the scene tree. [param p_runner] is optional:
## pass one in (e.g. a FakeCodeRunner) to skip the real language runtime.
## [param p_hints_used] is how many hints were already revealed on an earlier
## try. [param p_first_time] is false if the lesson is already complete.
func setup(p_challenge: Dictionary, p_character: Dictionary = {}, p_runner: CodeRunner = null, p_hints_used: int = 0, p_first_time: bool = true) -> void:
	challenge = p_challenge
	character = p_character
	runner = p_runner
	hints_used = p_hints_used
	first_time = p_first_time


func _ready() -> void:
	var language_id: String = challenge.get("language", "")
	var language: Dictionary = GameData.languages.get(language_id, {})
	if runner == null:
		runner = GameData.make_runner(language_id)

	title_label.text = challenge.get("title", "Coding challenge")
	language_label.text = language.get("display_name", language_id)
	prompt_label.text = challenge.get("prompt", "")
	_hints = GameData.get_hints(challenge)
	hints_used = clampi(hints_used, 0, _hints.size())
	hint_button.visible = not _hints.is_empty()
	_update_hints()
	editor.text = challenge.get("starter_code", "")
	editor.syntax_highlighter = _make_highlighter(language)
	continue_button.visible = false

	hint_button.pressed.connect(_on_hint)
	run_button.pressed.connect(_on_run)
	reset_button.pressed.connect(func(): editor.text = challenge.get("starter_code", ""))
	give_up_button.pressed.connect(func(): finished.emit(false))
	continue_button.pressed.connect(func(): finished.emit(_passed))

	if not runner.is_available():
		_set_status("Heads up: " + runner.unavailable_reason(), Color.ORANGE)
	else:
		_set_status("Write your code, then press Run.", Color.WHITE)
	editor.grab_focus()


## Reveals Quack's next hint. Each one lowers the affection this lesson is worth.
func _on_hint() -> void:
	if hints_used < _hints.size():
		hints_used += 1
		_update_hints()


func _update_hints() -> void:
	var shown: PackedStringArray = []
	for i in hints_used:
		shown.append("Quack, hint %d: %s" % [i + 1, _hints[i]])
	hint_label.text = "\n\n".join(shown)
	hint_label.visible = hints_used > 0
	if hints_used >= _hints.size():
		hint_button.text = "No more hints"
		hint_button.disabled = true
	elif first_time:
		hint_button.text = "Ask Quack for a hint (-%d <3)" % GameState.HINT_COST
	else:
		hint_button.text = "Ask Quack for a hint"
	if first_time:
		reward_label.text = "Pass to earn +%d <3" % GameState.lesson_affection(hints_used)
	else:
		reward_label.text = "Already completed, so there's no affection this time."


func _on_run() -> void:
	run_button.disabled = true
	_set_status("Running...", Color.LIGHT_GRAY)
	output_label.text = ""

	var report: Dictionary = await ChallengeGrader.grade(runner, editor.text, challenge)
	run_button.disabled = false
	_show_report(report)


func _show_report(report: Dictionary) -> void:
	var date_name: String = character.get("name", "Your date")
	if report["passed"]:
		_passed = true
		_set_status("All tests passed! %s looks impressed." % date_name, Color.LIGHT_GREEN)
		var first: Dictionary = report["tests"][0]
		output_label.text = first["actual"]
		continue_button.visible = true
		continue_button.grab_focus()
		run_button.disabled = true
		give_up_button.visible = false
		return

	var fail: Dictionary = report["first_failure"]
	var result: RunResult = fail["result"]
	_set_status(result.describe() if not result.is_success() else "Not quite. Compare your output with what was expected.", Color.SALMON)

	var lines: PackedStringArray = []
	if not result.is_success() and result.stderr.strip_edges() != "":
		lines.append("[b]Error output:[/b]")
		lines.append(_escape(result.stderr.strip_edges()))
	else:
		if fail["stdin"] != "":
			lines.append("[b]Input:[/b]\n" + _escape(fail["stdin"].strip_edges()))
		lines.append("[b]Expected:[/b]\n" + _escape(fail["expected"]))
		lines.append("[b]Your output:[/b]\n" + (_escape(fail["actual"]) if fail["actual"] != "" else "[i](nothing printed)[/i]"))
	output_label.text = "\n".join(lines)


func _set_status(text: String, color: Color) -> void:
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)


## Stops player output like "[b]" from being treated as formatting.
static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


static func _make_highlighter(language: Dictionary) -> CodeHighlighter:
	var h := CodeHighlighter.new()
	h.number_color = Color("#b5cea8")
	h.symbol_color = Color("#d4d4d4")
	h.function_color = Color("#dcdcaa")
	h.member_variable_color = Color("#9cdcfe")
	for k in language.get("keywords", []):
		h.add_keyword_color(k, Color("#ff7ab2"))
	h.add_color_region("\"", "\"", Color("#ce9178"))
	h.add_color_region("'", "'", Color("#ce9178"))
	h.add_color_region("`", "`", Color("#ce9178"))
	h.add_color_region(language.get("line_comment", "//"), "", Color("#6a9955"), true)
	return h
