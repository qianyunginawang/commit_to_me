extends Control
## Plays one date: shows dialogue lines, choices, and opens code challenges.
## Expects Router.params["date_id"].

const CodeChallengeScene := preload("res://scenes/code_challenge.tscn")
const CHARS_PER_SECOND := 45.0

@onready var portrait: Portrait = %Portrait
@onready var title_label: Label = %TitleLabel
@onready var affection_bar: ProgressBar = %AffectionBar
@onready var affection_label: Label = %AffectionLabel
@onready var speaker_label: Label = %SpeakerLabel
@onready var text_label: RichTextLabel = %TextLabel
@onready var choices_box: VBoxContainer = %Choices
@onready var continue_hint: Label = %ContinueHint
@onready var heart_popup: Label = %HeartPopup
@onready var leave_button: Button = %LeaveButton

var player: DialoguePlayer
var character: Dictionary = {}
var _date_id: String = ""
var _line: Dictionary = {}
var _typing_tween: Tween
## Hints the player has revealed, per challenge id. Kept across retries, so
## giving up and trying again doesn't reset the hint cost.
var _hints_used: Dictionary = {}


func _ready() -> void:
	_date_id = Router.params.get("date_id", "")
	var date := GameData.get_date(_date_id)
	if date.is_empty():
		push_error("Unknown date '%s'" % _date_id)
		Router.goto(Router.MAP)
		return

	character = GameData.get_character(date.get("character", ""))
	title_label.text = "%s with %s" % [date.get("title", "A date"), character.get("name", "?")]
	portrait.show_character(character)
	heart_popup.modulate.a = 0.0
	leave_button.pressed.connect(_leave)
	GameState.affection_changed.connect(_on_affection_changed)
	_update_affection()

	player = DialoguePlayer.new(date, GameState.player_name)
	player.line_started.connect(_show_line)
	player.challenge_requested.connect(_open_challenge)
	player.finished.connect(_on_finished)
	player.start()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_advance_pressed()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_advance_pressed()


func _on_advance_pressed() -> void:
	if _line.is_empty():
		return
	if _is_typing():
		_finish_typing()
	elif not _line.has("choices"):
		player.advance()


# --- Showing lines -------------------------------------------------------------

func _show_line(line: Dictionary) -> void:
	_line = line
	speaker_label.text = _speaker_name(line.get("speaker", "narrator"))
	text_label.text = line.get("text", "")
	text_label.visible_ratio = 0.0
	_clear_choices()
	continue_hint.visible = false

	var duration := maxf(text_label.get_total_character_count() / CHARS_PER_SECOND, 0.05)
	if _typing_tween:
		_typing_tween.kill()
	_typing_tween = create_tween()
	_typing_tween.tween_property(text_label, "visible_ratio", 1.0, duration)
	_typing_tween.finished.connect(_on_line_typed)


func _is_typing() -> bool:
	return _typing_tween != null and _typing_tween.is_running()


func _finish_typing() -> void:
	_typing_tween.kill()
	text_label.visible_ratio = 1.0
	_on_line_typed()


func _on_line_typed() -> void:
	if _line.has("choices"):
		_show_choices(_line["choices"])
	else:
		continue_hint.visible = true


func _show_choices(choices: Array) -> void:
	_clear_choices()
	for i in choices.size():
		var button := Button.new()
		button.text = choices[i].get("text", "...")
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_choice.bind(i))
		choices_box.add_child(button)
	choices_box.get_child(0).grab_focus()


func _on_choice(index: int) -> void:
	_clear_choices()
	player.choose(index)


func _clear_choices() -> void:
	for child in choices_box.get_children():
		child.queue_free()


func _speaker_name(speaker: String) -> String:
	match speaker:
		"narrator":
			return ""
		"player":
			return GameState.player_name
		_:
			return GameData.get_character(speaker).get("name", speaker)


# --- Code challenges -----------------------------------------------------------

func _open_challenge(challenge_id: String) -> void:
	_line = {}
	var overlay := CodeChallengeScene.instantiate()
	var first_time := not GameState.is_date_complete(_date_id)
	overlay.setup(GameData.get_challenge(challenge_id), character, null, _hints_used.get(challenge_id, 0), first_time)
	add_child(overlay)
	var passed: bool = await overlay.finished
	_hints_used[challenge_id] = overlay.hints_used
	overlay.queue_free()
	if passed:
		GameState.complete_lesson(_date_id, character.get("id", ""), overlay.hints_used)
	player.complete_challenge(passed)


# --- Affection -----------------------------------------------------------------

func _on_affection_changed(character_id: String, _value: int, delta: int) -> void:
	if character_id != character.get("id"):
		return
	_update_affection()
	heart_popup.text = ("<3 +%d" % delta) if delta > 0 else ("</3 %d" % delta)
	heart_popup.modulate = Color(1, 0.4, 0.6, 1) if delta > 0 else Color(0.6, 0.6, 0.8, 1)
	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(heart_popup, "modulate:a", 0.0, 0.6)


func _update_affection() -> void:
	var id: String = character.get("id", "")
	affection_bar.value = GameState.get_affection(id)
	affection_label.text = GameState.get_level(id)["title"]


func _on_finished() -> void:
	_leave()


## Going on a date uses up the current time slot, unless the event it was
## part of takes no time (the campus tour).
func _leave() -> void:
	var event_id: String = Router.params.get("event_id", "")
	var takes_no_time := false
	for event in GameData.calendar.get("events", []):
		if event.get("id") == event_id:
			takes_no_time = event.get("takes_no_time", false)
	if not takes_no_time:
		GameState.advance_time()
	GameState.save_game()
	Router.goto(Router.params.get("return_to", Router.MAP))
