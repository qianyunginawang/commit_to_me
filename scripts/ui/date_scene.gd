extends Control
## Plays one date: shows dialogue lines, choices, and opens code challenges.
## Expects Router.params["date_id"].
##
## Visual novel controls under the text: History (every line so far, also
## the mouse wheel), Auto (advances by itself) and Skip (races through lines
## until the next choice). Menu (top right, or Esc) pauses.

const CodeChallengeScene := preload("res://scenes/code_challenge.tscn")

@onready var portrait: Portrait = %Portrait
@onready var backdrop: Backdrop = %Backdrop
@onready var hud: Hud = %Hud
@onready var affection_panel: GlassPanel = %AffectionPanel
@onready var affection_bar: ProgressBar = %AffectionBar
@onready var affection_label: Label = %AffectionLabel
@onready var balance_label: Label = %BalanceLabel
@onready var name_row: HBoxContainer = %NameRow
@onready var text_label: RichTextLabel = %TextLabel
@onready var choices_box: VBoxContainer = %Choices
@onready var dialogue_box: Control = %DialogueBox
@onready var next_button: Button = %NextButton
@onready var heart_popup: Label = %HeartPopup
@onready var history_button: Button = %HistoryButton
@onready var auto_button: Button = %AutoButton
@onready var skip_button: Button = %SkipButton
@onready var menu_button: Button = %MenuButton
@onready var calendar_button: Button = %CalendarButton

## Skip shows each line for this long.
const SKIP_DELAY := 0.08

var player: DialoguePlayer
var character: Dictionary = {}
var _date_id: String = ""
var _line: Dictionary = {}
var _typing_tween: Tween
## Hints the player has revealed, per challenge id. Kept across retries, so
## giving up and trying again doesn't reset the hint cost.
var _hints_used: Dictionary = {}
## Every line shown so far, for History: {"speaker", "text", "choice"}.
var history: Array[Dictionary] = []
var _next_timer: Timer
## True once the current line has finished typing.
var _line_typed := false


func _ready() -> void:
	_date_id = Router.params.get("date_id", "")
	var date := GameData.get_date(_date_id)
	if date.is_empty():
		push_error("Unknown date '%s'" % _date_id)
		Router.goto(Router.MAP)
		return

	var location := _location()
	backdrop.show_place(location, GameState.slot)
	var place: String = GameData.location_label(location)
	hud.refresh(place)

	character = GameData.get_character(date.get("character", ""))
	# Story scenes (Quack, the whole cast) have no one character: the
	# portrait follows whoever is speaking instead.
	affection_panel.visible = not character.is_empty()
	portrait.visible = false
	if not character.is_empty():
		_show_speaker_portrait(character["id"])
		affection_panel.tab_text = "%s · Affection" % character.get("name", "")
	heart_popup.modulate.a = 0.0
	_next_timer = Timer.new()
	_next_timer.one_shot = true
	_next_timer.timeout.connect(_on_next_timer)
	add_child(_next_timer)
	history_button.pressed.connect(show_history)
	auto_button.toggled.connect(_on_auto_toggled)
	skip_button.toggled.connect(_on_skip_toggled)
	menu_button.pressed.connect(open_menu)
	calendar_button.pressed.connect(open_calendar)
	next_button.pressed.connect(_on_advance_pressed)
	# The name banner sits on the dialogue box's top edge, which moves up
	# when answers make the box taller.
	dialogue_box.resized.connect(_place_name_row)
	GameState.affection_changed.connect(_on_affection_changed)
	_update_affection()

	player = DialoguePlayer.new(date, GameState.player_name)
	player.line_started.connect(_show_line)
	player.challenge_requested.connect(_open_challenge)
	player.flag_set.connect(GameState.set_flag)
	player.finished.connect(_on_finished)
	player.start()


## Where this date happens: the location of the calendar event it's part of.
func _location() -> String:
	var event_id: String = Router.params.get("event_id", "")
	for event in GameData.calendar.get("events", []):
		if event.get("id") == event_id:
			return event.get("location", "")
	return ""


func _gui_input(event: InputEvent) -> void:
	if _modal_open() or not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		_on_advance_pressed()
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
		show_history()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if has_node("HistoryPanel") or has_node("PauseMenu"):
			_close_modal("HistoryPanel" if has_node("HistoryPanel") else "PauseMenu")
		elif not _modal_open():
			open_menu()
	elif (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_right")) and not _modal_open():
		get_viewport().set_input_as_handled()
		_on_advance_pressed()


## The right arrow does what Enter does. Caught before the answer buttons
## see it, so it picks the highlighted answer instead of moving focus.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right") and choices_box.visible and not _modal_open():
		get_viewport().set_input_as_handled()
		_on_advance_pressed()


func _on_advance_pressed() -> void:
	if _line.is_empty():
		return
	if choices_box.visible:
		_choose_highlighted()
		return
	# Clicking stops Skip, like in other visual novels.
	skip_button.set_pressed_no_signal(false)
	_next_timer.stop()
	if _is_typing():
		_finish_typing()
	elif not _line.has("choices") and not _line.get("ask_name", false):
		player.advance()


# --- Showing lines -------------------------------------------------------------

func _show_line(line: Dictionary) -> void:
	_line = line
	var speaker: String = line.get("speaker", "narrator")
	_show_name(speaker)
	if speaker != "narrator" and speaker != "player":
		_show_speaker_portrait(speaker)
	text_label.text = line.get("text", "")
	# The narrator speaks in a softer, italic voice.
	text_label.add_theme_color_override("default_color", UiStyle.TEXT_SOFT if speaker == "narrator" else UiStyle.TEXT)
	text_label.visible_ratio = 0.0
	_line_typed = false
	_clear_choices()

	var duration := maxf(text_label.get_total_character_count() / Settings.chars_per_second(), 0.05)
	if _typing_tween:
		_typing_tween.kill()
	_typing_tween = create_tween()
	_typing_tween.tween_property(text_label, "visible_ratio", 1.0, duration)
	_typing_tween.finished.connect(_on_line_typed)
	_add_history(speaker, line.get("text", ""))
	if skip_button.button_pressed:
		_finish_typing()


## The slanted name banner (and language tag) above the dialogue box.
func _show_name(speaker: String) -> void:
	for child in name_row.get_children():
		name_row.remove_child(child)
		child.queue_free()
	var look := Looks.speaker_look(speaker, GameState.slot)
	if look.is_empty():
		return   # the narrator has no banner
	name_row.add_child(UiStyle.banner(look.get("name", speaker),
		Color.from_string(look.get("banner_color", "#ff3d7f"), UiStyle.PINK),
		Color.from_string(look.get("banner_text_color", "#ffffff"), Color.WHITE), 34))
	if look.get("language", "") != "":
		var tag := UiStyle.chip(look["language"])
		tag.size_flags_vertical = Control.SIZE_SHRINK_END
		name_row.add_child(tag)


func _show_speaker_portrait(speaker: String) -> void:
	var look := Looks.speaker_look(speaker, GameState.slot)
	if look.is_empty():
		return
	portrait.show_look(look)
	portrait.get_node("PortraitFrame").visible = not portrait.is_cutout
	portrait.visible = true


func _is_typing() -> bool:
	return _typing_tween != null and _typing_tween.is_running()


func _finish_typing() -> void:
	_typing_tween.kill()
	text_label.visible_ratio = 1.0
	_on_line_typed()


func _on_line_typed() -> void:
	_line_typed = true
	if _line.get("ask_name", false):
		_show_name_input()
	elif _line.has("choices"):
		_show_choices(_line["choices"])
	_schedule_next()


## The answers, listed inside the dialogue box under the question. The first
## is highlighted; Up/Down or the mouse move the highlight, Enter, the right
## arrow, Next or a click picks it.
func _show_choices(choices: Array) -> void:
	_clear_choices()
	for i in choices.size():
		choices_box.add_child(_choice_button(i, choices[i].get("text", "...")))
	choices_box.visible = true
	choices_box.get_child(0).grab_focus()


func _choice_button(index: int, text: String) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"DialogueChoice"
	button.text = "%d.  %s" % [index + 1, text]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 34)
	button.pressed.connect(_on_choice.bind(index))
	button.mouse_entered.connect(button.grab_focus)
	return button


func _choose_highlighted() -> void:
	for i in choices_box.get_child_count():
		if choices_box.get_child(i).has_focus():
			_on_choice(i)
			return
	_on_choice(0)


func _place_name_row() -> void:
	name_row.position.y = dialogue_box.position.y - 32


## Quack asks the player's name: a pop-up in the middle of the screen over a
## dimmed scene. It blocks clicks, so the question can't be skipped.
func _show_name_input() -> void:
	var column := _make_modal("NameModal", "Quack asks", 520)
	var heading := Label.new()
	heading.text = "What's your name?"
	heading.theme_type_variation = &"Title"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var edit := LineEdit.new()
	edit.name = "NameEdit"
	edit.text = GameState.DEFAULT_PLAYER_NAME
	edit.placeholder_text = GameState.DEFAULT_PLAYER_NAME
	edit.max_length = 20
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(edit)
	var ok := Button.new()
	ok.name = "NameButton"
	ok.text = "THAT'S ME"
	ok.theme_type_variation = &"BrightButton"
	ok.custom_minimum_size = Vector2(200, 46)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(ok)

	ok.pressed.connect(func(): _on_name_entered(edit.text))
	edit.text_submitted.connect(_on_name_entered)
	edit.grab_focus()
	edit.select_all()


func _on_name_entered(text: String) -> void:
	_close_modal("NameModal")
	var player_name := text.strip_edges()
	GameState.player_name = player_name if player_name != "" else GameState.DEFAULT_PLAYER_NAME
	GameState.save_game()
	hud.refresh()
	player.set_player_name(GameState.player_name)
	_add_history("player", GameState.player_name, true)
	_line = {}
	player.advance()


func _on_choice(index: int) -> void:
	_add_history("player", _line["choices"][index].get("text", ""), true)
	_clear_choices()
	player.choose(index)


func _clear_choices() -> void:
	choices_box.visible = false
	for child in choices_box.get_children():
		choices_box.remove_child(child)
		child.queue_free()


# --- Code challenges -----------------------------------------------------------

func _open_challenge(challenge_id: String) -> void:
	_line = {}
	_next_timer.stop()
	skip_button.button_pressed = false
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
	heart_popup.text = ("+%d" % delta) if delta > 0 else ("%d" % delta)
	heart_popup.modulate = Color.WHITE if delta > 0 else Color(0.6, 0.6, 0.8, 1)
	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(heart_popup, "modulate:a", 0.0, 0.6)


func _update_affection() -> void:
	var id: String = character.get("id", "")
	var value := GameState.get_affection(id)
	affection_bar.value = value
	affection_label.text = "%s · %d" % [GameState.get_level(id)["title"].to_upper(), value]
	balance_label.visible = id == JayBalance.CHARACTER
	if balance_label.visible:
		balance_label.text = JayBalance.describe().to_upper()


func _on_finished() -> void:
	# Scenes without a challenge (story scenes, endings) are done once watched.
	if GameData.dialogue_challenge(_date_id) == "":
		GameState.mark_date_complete(_date_id)
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


# --- Auto and Skip -------------------------------------------------------------

func _on_auto_toggled(on: bool) -> void:
	if on:
		skip_button.set_pressed_no_signal(false)
	_schedule_next()


func _on_skip_toggled(on: bool) -> void:
	if on:
		auto_button.set_pressed_no_signal(false)
		if _is_typing():
			_finish_typing()
			return
	_schedule_next()


## After a line finishes typing, Auto and Skip move on by themselves. Both
## wait at choices, Quack's questions and lessons; Skip also turns off there.
func _schedule_next() -> void:
	_next_timer.stop()
	# (Not _is_typing(): the tween still counts as running while its
	# finished signal calls _on_line_typed.)
	if _line.is_empty() or not _line_typed:
		return
	if _line.has("choices") or _line.get("ask_name", false):
		skip_button.set_pressed_no_signal(false)
		return
	if skip_button.button_pressed:
		_next_timer.start(SKIP_DELAY)
	elif auto_button.button_pressed:
		_next_timer.start(Settings.auto_delay(text_label.get_total_character_count()))


func _on_next_timer() -> void:
	if _modal_open():
		_next_timer.start(0.3)   # paused while a menu is open
		return
	if _line.is_empty() or _line.has("choices") or _line.get("ask_name", false):
		return
	player.advance()


# --- History -------------------------------------------------------------------

func _add_history(speaker: String, text: String, choice: bool = false) -> void:
	var who := ""
	if speaker == "player":
		who = GameState.player_name
	elif speaker != "narrator":
		who = Looks.speaker_look(speaker, GameState.slot).get("name", speaker)
	history.append({"speaker": who, "text": text, "choice": choice})


## A scrolling list of every line so far, newest at the bottom.
func show_history() -> void:
	if _modal_open():
		return
	var column := _make_modal("HistoryPanel", "History", 820)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "Lines"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)
	for entry in history:
		list.add_child(_history_entry(entry))
	var close := Button.new()
	close.text = "CLOSE"
	close.custom_minimum_size = Vector2(160, 42)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_close_modal.bind("HistoryPanel"))
	column.add_child(close)
	close.grab_focus()
	await get_tree().process_frame
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


func _history_entry(entry: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	if entry["speaker"] != "":
		box.add_child(UiStyle.caption(entry["speaker"].to_upper(),
			UiStyle.PINK if entry["choice"] else UiStyle.CYAN_PALE, 12))
	var text := Label.new()
	text.text = ("▸ " if entry["choice"] else "") + entry["text"]
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 17)
	text.add_theme_color_override("font_color",
		UiStyle.TEXT_SOFT if entry["speaker"] == "" else UiStyle.TEXT)
	box.add_child(text)
	return box


# --- Menu ----------------------------------------------------------------------

## The pause menu: resume, history, settings, or go back to the title screen.
func open_menu() -> void:
	if _modal_open():
		return
	var column := _make_modal("PauseMenu", "Paused", 340)
	var buttons := [
		["RESUME", &"BrightButton", _close_modal.bind("PauseMenu")],
		["HISTORY", &"", func(): _close_modal("PauseMenu"); show_history()],
		["SETTINGS", &"", _open_settings],
		["QUIT TO TITLE", &"PinkButton", _quit_to_title],
	]
	for b in buttons:
		var button := Button.new()
		button.text = b[0]
		button.theme_type_variation = b[1]
		button.custom_minimum_size = Vector2(0, 46)
		button.pressed.connect(b[2])
		column.add_child(button)
	column.get_child(0).grab_focus()


func open_calendar() -> void:
	if not _modal_open():
		add_child(CalendarView.new())


func _open_settings() -> void:
	var settings: Control = load(Router.SETTINGS).instantiate()
	settings.name = "SettingsOverlay"
	add_child(settings)


func _quit_to_title() -> void:
	GameState.save_game()
	Router.goto(Router.MAIN_MENU)


# --- Pop-ups -------------------------------------------------------------------

## A pop-up in the middle of the screen over the dimmed scene. It blocks
## clicks to the scene. Returns the column to put its content in.
func _make_modal(modal_name: String, tab: String, width: float) -> VBoxContainer:
	var modal := ColorRect.new()
	modal.name = modal_name
	modal.color = Color(UiStyle.SHADOW, 0.6)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var card := GlassPanel.new()
	card.tab_text = tab
	card.custom_minimum_size = Vector2(width, 0)
	modal.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	return column


func _close_modal(modal_name: String) -> void:
	var modal := get_node_or_null(modal_name)
	if modal:
		remove_child(modal)
		modal.queue_free()


func _modal_open() -> bool:
	for modal_name in ["NameModal", "HistoryPanel", "PauseMenu", "SettingsOverlay", "CalendarOverlay"]:
		if has_node(modal_name):
			return true
	return false
