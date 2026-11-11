extends Control
## The coding mini-game shown during a lesson: the task on the left, a code
## editor and console on the right, and Quack's hints, Reset and Run along the
## bottom. Runs the player's code against the challenge's tests.
##
## Emits finished(passed) when the player continues or gives up. Read
## hints_used afterwards to see how many of Quack's hints were revealed.
## (Affection isn't shown here: the lesson is about the code.)

signal finished(passed: bool)

# Colors from the "Coding Challenge Screen" design canvas.
const C_FRAME := Color("#0e1426")
const C_FRAME_EDGE := Color("#2e4a6b")
const C_BAR := Color("#121a31")
const C_BAR_EDGE := Color("#243052")
const C_CARD := Color("#151d36")
const C_CARD_EDGE := Color("#263256")
const C_EDITOR := Color("#0a0f1e")
const C_TAB_STRIP := Color("#111830")
const C_CONSOLE := Color("#070b16")
const C_CONSOLE_BAR := Color("#0f1529")
const C_CONSOLE_EDGE := Color("#1e2848")
const C_TEXT := Color("#e8ecf7")
const C_TEXT_SOFT := Color("#c9d1e6")
const C_MUTED := Color("#9aa6c4")
const C_DIM := Color("#7d88a8")
const C_LINE_NO := Color("#4e5a7c")
const C_CYAN := Color("#7fd6ea")
const C_CYAN_DARK := Color("#5ab3c8")
const C_INK := Color("#06202a")
const C_GREEN := Color("#b6f2c8")
const C_PINK := Color("#ff9fb0")
const C_ORANGE := Color("#ffc58a")
const C_GOLD := Color("#ffd66b")

const KEYWORD_COLOR := Color("#ff7aae")
const TYPE_COLOR := Color("#c79bff")
const STRING_COLOR := Color("#ffc58a")
const COMMENT_COLOR := Color("#7fa87f")
const NUMBER_COLOR := Color("#8beab0")
const FUNCTION_COLOR := Color("#7fd6ea")

## Short tag on the editor's file tab.
const FILE_BADGES := {"python": "PY", "typescript": "TS", "javascript": "JS", "java": "JAVA", "cpp": "C++"}
const BADGE_COLORS := {"python": "#ffd66b", "typescript": "#6fa8ff", "javascript": "#f3e15a", "java": "#ff9c6b", "cpp": "#8fb8ff"}
## Type names colored apart from keywords.
const TYPE_NAMES := {
	"python": ["int", "str", "float", "bool", "list", "dict", "set", "tuple", "type"],
	"typescript": ["string", "number", "boolean", "void", "any", "unknown", "never"],
	"javascript": [],
	"java": ["String", "int", "double", "boolean", "char", "long", "void", "Integer"],
	"cpp": ["int", "double", "bool", "char", "void", "auto", "string", "long", "float"],
}

@onready var frame: PanelContainer = %Frame
@onready var title_label: Label = %ChallengeTitle
@onready var lesson_label: Label = %LessonLabel
@onready var language_label: Label = %LanguageLabel
@onready var prompt_box: VBoxContainer = %PromptBox
@onready var hint_card: PanelContainer = %HintCard
@onready var hint_button: Button = %HintButton
@onready var hint_label: Label = %HintLabel
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
## False when replaying a lesson that's already complete.
var first_time := true
## "Lesson 1 · Printing to the console", shown above the title.
var lesson_text := ""
var _hints: Array = []
var _passed := false
var _running := false


## Call before adding to the scene tree. [param p_runner] is optional:
## pass one in (e.g. a FakeCodeRunner) to skip the real language runtime.
## [param p_hints_used] is how many hints were already revealed on an earlier
## try. [param p_first_time] is false if the lesson is already complete.
## [param p_lesson_text] is the small line above the title.
func setup(p_challenge: Dictionary, p_character: Dictionary = {}, p_runner: CodeRunner = null, p_hints_used: int = 0, p_first_time: bool = true, p_lesson_text: String = "") -> void:
	challenge = p_challenge
	character = p_character
	runner = p_runner
	hints_used = p_hints_used
	first_time = p_first_time
	lesson_text = p_lesson_text


func _ready() -> void:
	var language_id: String = challenge.get("language", "")
	var language: Dictionary = GameData.languages.get(language_id, {})
	if runner == null:
		runner = GameData.make_runner(language_id)

	_style()
	title_label.text = challenge.get("title", "Coding challenge")
	lesson_label.text = (lesson_text if lesson_text != "" else "Coding challenge").to_upper()
	language_label.text = language.get("display_name", language_id)
	%FileName.text = language.get("source_file", "main.txt")
	%FileBadge.text = FILE_BADGES.get(language_id, "")
	%FileBadge.add_theme_color_override("font_color", Color(BADGE_COLORS.get(language_id, "#6fa8ff")))
	_build_prompt(challenge.get("prompt", ""))
	_hints = GameData.get_hints(challenge)
	hints_used = clampi(hints_used, 0, _hints.size())
	hint_button.visible = not _hints.is_empty() and Settings.quack_hints()
	_update_hints()
	editor.text = challenge.get("starter_code", "")
	editor.syntax_highlighter = _make_highlighter(language, language_id)
	editor.set_caret_line(editor.get_line_count() - 1)
	editor.set_caret_column(editor.get_line(editor.get_line_count() - 1).length())

	hint_button.pressed.connect(_on_hint)
	run_button.pressed.connect(_on_run)
	reset_button.pressed.connect(_on_reset)
	give_up_button.pressed.connect(func(): finished.emit(false))
	continue_button.pressed.connect(func(): finished.emit(_passed))

	_show_idle()
	editor.grab_focus()


## Ctrl+Enter (Cmd+Enter on a Mac) runs the code from inside the editor.
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode in [KEY_ENTER, KEY_KP_ENTER] and (key.ctrl_pressed or key.meta_pressed):
		get_viewport().set_input_as_handled()
		if _passed:
			continue_button.pressed.emit()
		elif not _running:
			_on_run()


## Reveals Quack's next hint.
func _on_hint() -> void:
	if hints_used < _hints.size():
		hints_used += 1
		_update_hints()


func _update_hints() -> void:
	var shown: PackedStringArray = []
	for i in hints_used:
		shown.append("Hint %d: %s" % [i + 1, _hints[i]])
	hint_label.text = "\n\n".join(shown)
	hint_label.visible = hints_used > 0
	hint_card.visible = hints_used > 0
	if hints_used >= _hints.size():
		hint_button.text = "No more hints"
		hint_button.disabled = true
	elif hints_used > 0:
		hint_button.text = "Ask Quack for another hint"
	else:
		hint_button.text = "Ask Quack for a hint"


func _on_reset() -> void:
	editor.text = challenge.get("starter_code", "")
	editor.grab_focus()


func _on_run() -> void:
	_running = true
	run_button.disabled = true
	_set_status("Running...", C_MUTED)
	output_label.text = "[color=#%s]Running your code...[/color]" % C_DIM.to_html(false)

	var report: Dictionary = await ChallengeGrader.grade(runner, editor.text, challenge)
	_running = false
	run_button.disabled = false
	_show_report(report)


func _show_idle() -> void:
	_set_status("Not run yet", C_MUTED)
	if not runner.is_available():
		output_label.text = "[color=#%s]Heads up: %s[/color]" % [C_ORANGE.to_html(false), _escape(runner.unavailable_reason())]
	else:
		output_label.text = "[color=#%s]Write your code, then press Run. Output appears here.[/color]" % C_DIM.to_html(false)


func _show_report(report: Dictionary) -> void:
	if report["passed"]:
		_passed = true
		_set_status("Passed", Color("#8beab0"), Color("#123526"))
		var first: Dictionary = report["tests"][0]
		var date_name: String = character.get("name", "")
		var lines := _console_lines(first["actual"], C_GREEN)
		if date_name != "":
			lines.append("[color=#%s]All tests passed! %s looks impressed.[/color]" % [C_MUTED.to_html(false), date_name])
		output_label.text = "\n".join(lines)
		run_button.visible = false
		reset_button.visible = false
		give_up_button.visible = false
		hint_button.visible = false
		continue_button.text = "Continue with %s" % date_name if date_name != "" else "Continue"
		continue_button.visible = true
		continue_button.grab_focus()
		return

	var fail: Dictionary = report["first_failure"]
	var result: RunResult = fail["result"]
	var lines: PackedStringArray = []
	if not result.is_success():
		_set_status("Error", C_PINK, Color("#3a1621"))
		lines.append("[color=#%s]%s[/color]" % [C_PINK.to_html(false), _escape(result.describe())])
		if result.stderr.strip_edges() != "":
			lines.append("[color=#%s]%s[/color]" % [C_MUTED.to_html(false), _escape(result.stderr.strip_edges())])
	else:
		_set_status("Output doesn't match", C_PINK, Color("#3a1621"))
		if fail["stdin"] != "":
			lines.append("[color=#%s]Input: %s[/color]" % [C_MUTED.to_html(false), _escape(fail["stdin"].strip_edges())])
		if fail["actual"] == "":
			lines.append("[color=#%s]> (no output)[/color]" % C_MUTED.to_html(false))
		else:
			lines.append_array(_console_lines(fail["actual"], C_TEXT_SOFT))
		lines.append("[color=#%s]Expected: %s[/color]" % [C_PINK.to_html(false), _escape(fail["expected"]).replace("\n", "\n          ")])
	output_label.text = "\n".join(lines)


## Program output with a "> " in front of each line.
func _console_lines(text: String, color: Color) -> PackedStringArray:
	var out: PackedStringArray = []
	for line in text.split("\n"):
		out.append("[color=#%s]> %s[/color]" % [color.to_html(false), _escape(line)])
	return out


## The pill in the console's top right: "Not run yet", "Passed"...
func _set_status(text: String, color: Color, bg: Color = Color.TRANSPARENT) -> void:
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(999)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	status_label.add_theme_stylebox_override("normal", box)


# --- The task -----------------------------------------------------------------------

## Splits the prompt into paragraphs. A paragraph that is exactly a test's
## expected output goes in an output box; names like print() get code chips.
func _build_prompt(prompt: String) -> void:
	for child in prompt_box.get_children():
		child.queue_free()
	var expected: Array[String] = []
	for test in challenge.get("tests", []):
		expected.append(String(test.get("expected_stdout", "")).strip_edges())
	for paragraph in prompt.split("\n\n"):
		paragraph = paragraph.strip_edges()
		if paragraph == "":
			continue
		if paragraph in expected:
			prompt_box.add_child(_output_box(paragraph))
		else:
			prompt_box.add_child(_prompt_text(paragraph))


func _prompt_text(text: String) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.selection_enabled = true
	label.add_theme_font_override("normal_font", UiStyle.body_font(500))
	label.add_theme_font_override("mono_font", UiStyle.mono_font())
	label.add_theme_font_size_override("normal_font_size", 16)
	label.add_theme_font_size_override("mono_font_size", 14)
	label.add_theme_color_override("default_color", C_TEXT)
	label.add_theme_constant_override("line_separation", 6)
	label.text = _code_chips(_escape(text))
	return label


## Marks code like print(), console.log(), std::cout and << in a sentence.
static func _code_chips(text: String) -> String:
	var regex := RegEx.create_from_string("(std::\\w+|#include|<<|\\b[A-Za-z_][\\w.]*\\(\\))")
	return regex.sub(text, "[bgcolor=#0b1122][color=#ffc58a][code] $1 [/code][/color][/bgcolor]", true)


func _output_box(text: String) -> PanelContainer:
	var box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = C_CONSOLE
	style.border_color = Color("#34446e")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	box.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.add_theme_font_override("font", UiStyle.mono_font())
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", C_GREEN)
	box.add_child(label)
	return box


# --- Look -----------------------------------------------------------------------------

func _style() -> void:
	frame.add_theme_stylebox_override("panel", _box(C_FRAME, C_FRAME_EDGE, 14, 1))
	%Header.add_theme_stylebox_override("panel", _bar(C_BAR, C_BAR_EDGE, false, 24, 16, 13))
	%Footer.add_theme_stylebox_override("panel", _bar(C_BAR, C_BAR_EDGE, true, 24, 14, 0, 13))
	%TaskCard.add_theme_stylebox_override("panel", _box(C_CARD, C_CARD_EDGE, 12, 1, 22, 20))
	%HintCard.add_theme_stylebox_override("panel", _box(Color("#1f1c3d"), Color("#5a4f92"), 12, 1, 18, 14))
	%EditorCard.add_theme_stylebox_override("panel", _box(C_EDITOR, C_CARD_EDGE, 12, 1, 1, 1))
	%ConsoleCard.add_theme_stylebox_override("panel", _box(C_CONSOLE, C_CARD_EDGE, 12, 1, 1, 1))
	%TabStrip.add_theme_stylebox_override("panel", _bar(C_TAB_STRIP, C_BAR_EDGE, false, 0, 0, 11))
	%ConsoleBar.add_theme_stylebox_override("panel", _bar(C_CONSOLE_BAR, C_CONSOLE_EDGE, false, 16, 10, 11))
	var tab := StyleBoxFlat.new()
	tab.bg_color = C_EDITOR
	tab.border_color = C_BAR_EDGE
	tab.border_width_right = 1
	tab.content_margin_left = 16
	tab.content_margin_right = 16
	tab.content_margin_top = 10
	tab.content_margin_bottom = 10
	%FileTab.add_theme_stylebox_override("panel", tab)
	# A cyan line on top of the open tab.
	%FileTab.draw.connect(func(): %FileTab.draw_rect(Rect2(0, 0, %FileTab.size.x, 2), C_CYAN))

	# Header
	_font(language_label, UiStyle.label_font(1), 13, Color("#ff9cc2"))
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color("#2a1730")
	pill.border_color = Color("#5a2a4c")
	pill.set_border_width_all(1)
	pill.set_corner_radius_all(999)
	pill.content_margin_left = 12
	pill.content_margin_right = 12
	pill.content_margin_top = 5
	pill.content_margin_bottom = 5
	language_label.add_theme_stylebox_override("normal", pill)
	_font(lesson_label, UiStyle.label_font(2), 12, C_MUTED)
	_font(title_label, UiStyle.label_font(0), 26, C_TEXT)
	_button(give_up_button, Color.TRANSPARENT, Color("#5a2a3c"), C_PINK)

	# Task and hints
	_font(%TaskHeading, UiStyle.label_font(3), 12, C_CYAN)
	_font(%HintHeading, UiStyle.label_font(3), 12, C_GOLD)
	_font(hint_label, UiStyle.body_font(500), 15, Color("#e8e4ff"))

	# Editor
	_font(%FileBadge, UiStyle.mono_font(), 13, Color("#6fa8ff"))
	_font(%FileName, UiStyle.mono_font(), 13, C_TEXT)
	_font(%EditorCaption, UiStyle.body_font(500), 12, C_MUTED)
	var caption_margin := StyleBoxEmpty.new()
	caption_margin.content_margin_right = 16
	%EditorCaption.add_theme_stylebox_override("normal", caption_margin)
	var edit_box := StyleBoxFlat.new()
	edit_box.bg_color = C_EDITOR
	edit_box.content_margin_top = 14
	edit_box.content_margin_bottom = 14
	edit_box.content_margin_right = 16
	edit_box.corner_radius_bottom_left = 11
	edit_box.corner_radius_bottom_right = 11
	editor.add_theme_stylebox_override("normal", edit_box)
	editor.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	editor.add_theme_font_override("font", UiStyle.mono_font())
	editor.add_theme_font_size_override("font_size", 16)
	editor.add_theme_constant_override("line_spacing", 9)
	editor.add_theme_color_override("font_color", C_TEXT)
	editor.add_theme_color_override("caret_color", C_CYAN)
	editor.add_theme_color_override("current_line_color", Color("#141c36"))
	editor.add_theme_color_override("line_number_color", C_LINE_NO)
	editor.add_theme_color_override("selection_color", Color("#2e4a6b"))
	editor.add_theme_color_override("brace_mismatch_color", C_PINK)
	editor.add_theme_color_override("word_highlighted_color", Color(C_CYAN, 0.12))
	editor.add_theme_constant_override("caret_width", 2)
	editor.caret_blink = true

	# Console
	%ConsoleIcon.texture = Icons.get_icon("terminal", C_MUTED, 14)
	_font(%ConsoleTitle, UiStyle.label_font(3), 12, C_MUTED)
	_font(status_label, UiStyle.label_font(1), 12, C_MUTED)
	output_label.add_theme_font_override("normal_font", UiStyle.mono_font())
	output_label.add_theme_font_override("mono_font", UiStyle.mono_font())
	output_label.add_theme_font_size_override("normal_font_size", 14)
	output_label.add_theme_constant_override("line_separation", 3)
	var out_box := StyleBoxEmpty.new()
	out_box.content_margin_left = 16
	out_box.content_margin_right = 16
	out_box.content_margin_top = 12
	out_box.content_margin_bottom = 12
	output_label.add_theme_stylebox_override("normal", out_box)

	_thin_scrollbar(%TaskCard.get_node("Scroll").get_v_scroll_bar())
	_thin_scrollbar(output_label.get_v_scroll_bar())
	_thin_scrollbar(editor.get_v_scroll_bar())

	# Footer
	_button(hint_button, Color("#2b2650"), Color("#5a4f92"), Color("#e8e4ff"), Icons.get_icon("bulb", C_GOLD, 18))
	_button(reset_button, Color("#18213d"), Color("#34446e"), C_TEXT_SOFT, Icons.get_icon("reset", C_TEXT_SOFT, 16))
	_button(run_button, C_CYAN, C_CYAN, C_INK, Icons.get_icon("play", C_INK, 14), true)
	_button(continue_button, C_CYAN, C_CYAN, C_INK, Icons.get_icon("arrow", C_INK, 16), true)
	continue_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# Room on the right of Run for the shortcut chip.
	var chip: Label = %ShortcutChip
	chip.text = ("⌘ ↵" if OS.get_name() == "macOS" else "Ctrl ↵")
	_font(chip, UiStyle.mono_font(), 12, C_INK)
	var chip_box := StyleBoxFlat.new()
	chip_box.bg_color = C_CYAN_DARK
	chip_box.set_corner_radius_all(4)
	chip.add_theme_stylebox_override("normal", chip_box)
	var chip_width := chip.get_theme_font("font").get_string_size(chip.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 12
	chip.offset_left = -18 - chip_width
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box: StyleBox = run_button.get_theme_stylebox(state)
		if box is StyleBoxFlat:
			box.content_margin_right = 22 + chip_width + 10


func _button(button: Button, bg: Color, edge: Color, fg: Color, icon: Texture2D = null, primary: bool = false) -> void:
	button.add_theme_font_override("font", UiStyle.label_font(1))
	button.add_theme_font_size_override("font_size", 15 if primary else 14)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, fg)
	button.add_theme_color_override("font_disabled_color", Color(fg, 0.45))
	button.add_theme_color_override("icon_disabled_color", Color(1, 1, 1, 0.45))
	var normal := _box(bg, edge, 8, 0 if primary else 1, 22 if primary else 16, 0)
	var hover := _box(bg.lightened(0.12) if bg.a > 0 else Color(edge, 0.25), edge.lightened(0.2), 8, 0 if primary else 1, 22 if primary else 16, 0)
	var pressed := _box(bg.darkened(0.12) if bg.a > 0 else Color(edge, 0.4), edge, 8, 0 if primary else 1, 22 if primary else 16, 0)
	var disabled := _box(Color(bg, bg.a * 0.5), Color(edge, 0.5), 8, 0 if primary else 1, 22 if primary else 16, 0)
	var focus := _box(Color.TRANSPARENT, Color(C_CYAN, 0.9), 8, 2, 0, 0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover_pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_constant_override("h_separation", 8)
	if icon != null:
		button.icon = icon


static func _thin_scrollbar(bar: ScrollBar) -> void:
	var track := StyleBoxEmpty.new()
	track.content_margin_left = 6
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color("#34446e")
	grabber.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("grabber", grabber)
	var hover := grabber.duplicate()
	hover.bg_color = Color("#4e5a7c")
	bar.add_theme_stylebox_override("grabber_highlight", hover)
	bar.add_theme_stylebox_override("grabber_pressed", hover)


static func _font(label: Control, font: Font, size: int, color: Color) -> void:
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)


static func _box(bg: Color, edge: Color, radius: int, border: int, pad_x: int = 0, pad_y: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = edge
	box.set_border_width_all(border)
	box.set_corner_radius_all(radius)
	box.content_margin_left = pad_x
	box.content_margin_right = pad_x
	box.content_margin_top = pad_y
	box.content_margin_bottom = pad_y
	box.anti_aliasing = true
	return box


## A strip with a line on its top or bottom edge (header, footer, tab bars).
static func _bar(bg: Color, edge: Color, line_on_top: bool, pad_x: int, pad_y: int, round_top: int = 0, round_bottom: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = edge
	if line_on_top:
		box.border_width_top = 1
	else:
		box.border_width_bottom = 1
	box.corner_radius_top_left = round_top
	box.corner_radius_top_right = round_top
	box.corner_radius_bottom_left = round_bottom
	box.corner_radius_bottom_right = round_bottom
	box.anti_aliasing = true
	box.content_margin_left = pad_x
	box.content_margin_right = pad_x
	box.content_margin_top = pad_y
	box.content_margin_bottom = pad_y
	return box


## Stops player output like "[b]" from being treated as formatting.
static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


static func _make_highlighter(language: Dictionary, language_id: String = "") -> CodeHighlighter:
	var h := CodeHighlighter.new()
	h.number_color = NUMBER_COLOR
	h.symbol_color = C_MUTED
	h.function_color = FUNCTION_COLOR
	h.member_variable_color = C_TEXT
	for k in language.get("keywords", []):
		h.add_keyword_color(k, KEYWORD_COLOR)
	for t in TYPE_NAMES.get(language_id, []):
		h.add_keyword_color(t, TYPE_COLOR)
	h.add_color_region("\"", "\"", STRING_COLOR)
	h.add_color_region("'", "'", STRING_COLOR)
	h.add_color_region("`", "`", STRING_COLOR)
	h.add_color_region(language.get("line_comment", "//"), "", COMMENT_COLOR, true)
	return h
